@tool
class_name CGEGraphEditor
extends Control
## Custom graph editor control.
##
## This class implements a custom graph editor with nodes and links. This is the main entry point
## for making your own graph-based tools in Godot using this addon.[br]
##
## Graph visualisation is handled with [CGEGraphViewer] (see [member _viewer]). This class adds all the "editor" part (selection, undo/redo, clipboard, toolbar/inspector, file serialization, ...)


### Signals

## Emitted when a node is selected.
signal graph_element_selected(node: CGEGraphNodeUI)
## Emitted when a node is deselected.
signal node_deselected(node)
## Emitted when the selection changed
signal selection_changed(new_selection: Array[CGEGraphElementUI])


### Enums

enum CGEState {
    DEFAULT,
    DRAGGING,
    CONNECTING,
    DRAG_BOX_SELECTING,
}


### Constants

## Minimum distance needed to consider a drag-box and not just a clic
const MIN_DRAG_DISTANCE = 10.0


### Exports

@export_category("Nodes reference")
## Graph UI node (scene) used in the editor
@export var graph_node_ui_scene := preload("res://addons/custom_graph_editor/UI/graph_node_ui.tscn")
## Graph UI link (scene) used in the editor
@export var graph_link_ui_scene := preload("res://addons/custom_graph_editor/UI/graph_link_ui.tscn")
## Script defining graph nodes (logic) in the graph. Must inherit CGEGraphNode
@export var node_class: GDScript = preload("res://addons/custom_graph_editor/logic/graph_node.gd")
## Script defining graph link (logic) in the graph. Must inherit CGEGraphLink
@export var link_class: GDScript = preload("res://addons/custom_graph_editor/logic/graph_link.gd")

### Regular variables

## [CGEGraph] graph logic instance. Holds the graph data. Delegates to the embedded [CGEGraphViewer].
var graph: CGEGraph:
    get: return _viewer.graph
    set(value): _viewer.graph = value

## Current file path of the graph being edited. Empty if not saved yet.
var current_file_path: String = ""
## Whether the current file has unsaved changes. Notifies the _toolbar when changed.
var file_is_modified: bool = false:
    set(value):
        if value != file_is_modified:
            file_is_modified = value
            _toolbar.set_file_modified(value)

## Keep the collection of selected nodes
var _selection: Array[CGEGraphElementUI] = []

## File dialog for loading/saving graphs. See [method _save_to_file] and [method load_from_file].
var _file_dialog: FileDialog = null

## Current editor state (see [enum CGEState])
var _state: CGEState = CGEState.DEFAULT
## Drag start position IN SCREEN SPACE
var _drag_start_position: Vector2 = Vector2.ZERO
## Drag end position IN SCREEN SPACE
var _drag_end_position: Vector2 = Vector2.ZERO
## Initial position of dragged nodes before starting to drag (to reset it if drag is cancelled)
var _drag_nodes_start_positions: Array[Vector2] = []


## Drag box selection start IN SCREEN SPACE
var _drag_box_start: Vector2 = Vector2.ZERO
## Drag box selection end IN SCREEN SPACE
var _drag_box_end: Vector2 = Vector2.ZERO


## Clipboard for copy/paste operations (see [CGEClipboard])
var _editor_clipboard: CGEClipboard = CGEClipboard.new()

## Command history for undo/redo functionality (see [CGECommandHistory])
var _command_history: CGECommandHistory = CGECommandHistory.new()


###  Virtual methods for child classes to override

## Called when a graph element (node or link) is selected.
## Override this in child classes to customize selection behavior.
func _on_graph_element_selected(element: CGEGraphElementUI) -> void:
    pass


## Called when a graph element is deselected.
## Override this in child classes to customize deselection behavior.
func _on_graph_element_deselected(element: CGEGraphElementUI) -> void:
    pass


## Called when the selection is cleared.
## Override this in child classes to customize behavior when selection is cleared.
func _on_selection_cleared() -> void:
    if _inspector_panel:
        _inspector_panel.clear()


# Embedded viewer (pan/zoom, node/link UI). See [CGEGraphViewer].
@onready var _viewer: CGEGraphViewer = %Viewer
# Toolbar reference (see [CGEToolBar])
@onready var _toolbar: CGEToolBar = %CGEToolBar
# Inspector panel reference (see [CGEInspectorPanel])
@onready var _inspector_panel: CGEInspectorPanel = %InspectorPanel

## Given a path to a .gegraph, returns a deserialized CGEGraph
## allowing to have just node and connectivity info and scrap out
## all the editor specific data.[br]
##
## [param path]: Path to the .gegraph file[br]
## [param node_script]: GDScript class for nodes (must inherit from CGEGraphNode)[br]
## [param link_script]: GDScript class for links (must inherit from CGEGraphLink)[br]
static func deserialize_graph_runtime(path: String, node_script: GDScript, link_script: GDScript) -> CGEGraph:
    return CGEGraphViewer.deserialize_graph_runtime(path, node_script, link_script)


func _ready():
    # Forward parameters to the viewer
    _viewer.graph_node_ui_scene = graph_node_ui_scene
    _viewer.graph_link_ui_scene = graph_link_ui_scene
    _viewer.node_class = node_class
    _viewer.link_class = link_class

    graph.node_class = node_class
    graph.link_class = link_class
    _viewer.load_graph(graph)

    _viewer.node_ui_created.connect(node_created)
    _viewer.node_ui_removed.connect(func(node_id: int, node_ui: CGEGraphNodeUI): _selection.erase(node_ui))
    _viewer.link_requested.connect(_on_new_link_requested)

    if _toolbar:
        _connect_toolbar_signals()

    _command_history.clear_all()

    if _inspector_panel:
        selection_changed.connect(_inspector_panel._on_selection_changed)
        _inspector_panel.execute_command_requested.connect(_on_inspector_command_requested)


# Redraw the editor each frame for simplicity
func _process(delta: float) -> void:
    queue_redraw()


# Draw the drag-box selection rectangle if needed
func _draw() -> void:
    # Draw drag-box selection rectangle
    if is_drag_box_selecting():
        var box_rect = _get_drag_box_rect()
        # Draw semi-transparent fill
        draw_rect(box_rect, Color(0.3, 0.5, 0.8, 0.2))
        # Draw solid border
        draw_rect(box_rect, Color(0.3, 0.5, 0.8, 0.8), false, 2.0)


######## PUBLIC METHODS ########

## Returns whether the editor is currently in dragging state.
func is_dragging() -> bool:
    return _state == CGEState.DRAGGING


## Returns whether the editor is currently in connecting state.
func is_connecting() -> bool:
    return _state == CGEState.CONNECTING


## Returns whether the editor is currently in drag-box selecting state.
func is_drag_box_selecting() -> bool:
    return _state == CGEState.DRAG_BOX_SELECTING


## Select the given graph element (node or link) in the editor. Does nothing if the element is already selected.
func select_graph_element(node: CGEGraphElementUI):
    if node in _selection:
        return
    else:
        # Bring node to front when selected (only for nodes, not links)
        if node is CGEGraphNodeUI:
            node.move_to_front()

        # Select the node
        _selection.append(node)
        node.set_selected(true)
        _on_graph_element_selected(node)
        graph_element_selected.emit(node)
        selection_changed.emit(_selection)


## Deselect the given graph element (node or link) in the editor. Does nothing if the element is not selected.
func deselect_graph_element(node: CGEGraphElementUI):
    if node not in _selection:
        return

    _selection.erase(node)
    node.set_selected(false)
    _on_graph_element_deselected(node)
    node_deselected.emit(node)
    selection_changed.emit(_selection)


## Clear the current selection. Calls [method _on_selection_cleared] that can be overridden in child classes for additional behavior.
func clear_selection():
    # do not use deselect_graph_element here,
    for node in _selection:
        node.set_selected(false)
        node_deselected.emit(node)
    _selection.clear()
    _on_selection_cleared()
    selection_changed.emit(_selection)


# Name not ideal considering the other one _on_node_created.
## Used to override on child class (and still get the created node)
func node_created(node_id: int, new_node: CGEGraphNodeUI) -> void:
    pass


## Execute a [CGECommand] and add it to the command history for undo/redo.
func execute_command(cmd: CGECommand) -> void:
    if cmd.execute():
        _command_history.push(cmd)


## Undo the last executed command.
func undo() -> void:
    var cmd: CGECommand = _command_history.pop()
    if cmd != null:
        cmd.undo()


## Redo the last undone command.
func redo() -> void:
    _command_history.redo()


## Get the UI element for the given element ID, or null if not found.
func get_graph_element(element_id: int) -> CGEGraphElementUI:
    return _viewer.get_graph_element(element_id)


## Get the UI node for the given graph node ID, or null if not found.
func get_graph_node(node_id: int) -> CGEGraphNodeUI:
    return _viewer.get_graph_node(node_id)


## Get the UI link for the given graph link ID, or null if not found.
func get_graph_link(link_id: int) -> CGEGraphLinkUI:
    return _viewer.get_graph_link(link_id)


## Serialize the current graph to a Dictionary[String, Variant] for saving to file, in two sub-dictionaries: "nodes" and "links".[br]
## See [method CGEGraphNodeUI.serialize] and [method CGEGraphLinkUI.serialize] for more details on how nodes and links are serialized.
func serialize() -> Dictionary[String, Variant]:
    var data: Dictionary[String, Variant] = {}

    var nodes_data: Dictionary = {}
    for node_id in graph.get_all_node_ids():
        nodes_data[node_id] = get_graph_node(node_id).serialize()

    var links_data: Dictionary = {}
    for link_id in graph.get_all_link_ids():
        links_data[link_id] = get_graph_link(link_id).serialize()

    data["nodes"] = nodes_data
    data["links"] = links_data

    return data


## Deserialize the graph from a Dictionary[String, Variant], recreating all nodes and links. See [method serialize] for the expected format.
## [b]Note:[/b] [member node_class] and [member link_class] must be set before calling this method, as they are used to create the nodes and links.
func deserialize(data: Dictionary) -> void:
    graph.clear_all()

    # node_class and link_class are already set via @export in the editor
    # They must be set before calling deserialize
    graph.node_class = node_class
    graph.link_class = link_class

    # Recreate all nodes
    var nodes_data: Dictionary = data["nodes"]
    for node_id_str in nodes_data.keys():
        var node_id: int = int(node_id_str)
        CGEAddNodeCommand.new(
            self,
            int(node_id)
        ).execute()

        get_graph_node(node_id).deserialize(nodes_data[node_id_str])

    # Recreate all links
    var links_data: Dictionary = data["links"]
    for link_id_str in links_data.keys():
        var link_id: int = int(link_id_str)
        var link_data = link_class.new(link_id)
        link_data.deserialize(links_data[link_id_str])
        # Create the link (logic part)
        graph.create_link(link_data.start_node_id, link_data.end_node_id, link_data.id)
        # Update the link UI with deserialized data
        get_graph_link(link_id).deserialize(links_data[link_id_str])

    graph._sync_id_counter() # Should maybe call graph.deserialize first ?


## Save the graph to a file. Called when a file is chosen in the save file dialog.
func save_to_file(path: String) -> void:
    var data: Dictionary[String, Variant] = serialize()

    # Save to file with pretty formatting (tabs for readability and git diffs)
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    file.store_string(JSON.stringify(data, "\t"))
    file.close()

    current_file_path = path
    _toolbar.set_filename_label(path)
    _command_history.mark_saved() # this is the new checkpoint


## Load the graph from a file. Called when a file is chosen in the load file dialog.
func load_from_file(path: String) -> void:
    if not FileAccess.file_exists(path):
        push_error("Tried to load graph for '%s' but it does not exist!" % path)
        return

    var file: FileAccess = FileAccess.open(path, FileAccess.READ)

    var json: JSON = JSON.new()
    var json_string: String = file.get_as_text()
    var parse_result := json.parse(json_string)


    if not parse_result == OK:
        push_error("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return

    var data: Dictionary = json.data as Dictionary
    deserialize(data)

    file.close()

    current_file_path = path
    file_is_modified = false
    _toolbar.set_filename_label(path)
    _command_history.clear_all()
    # no need to mark_saved() because clear_all does it


######## PRIVATE METHODS ########

## Refresh the toolbar undo/redo buttons based on command history state (enabled/disabled).
func _refresh_toolbar_undo_redo() -> void:
    if _toolbar == null:
        return

    _toolbar.disable_undo(_command_history.is_empty())
    _toolbar.disable_redo(_command_history.can_redo() == false)


## Connect to all toolbar signals. Override this method in child classes to connect additional signals to custom toolbars.[br]
## Make sure to call the parent method to keep the default connections too !
func _connect_toolbar_signals() -> void:
    _toolbar.add_node_requested.connect(_on_add_node_requested)
    _toolbar.save_requested.connect(_on_save_requested)
    _toolbar.save_as_requested.connect(_on_save_as_requested)
    _toolbar.load_requested.connect(_on_load_requested)

    _toolbar.undo_requested.connect(undo)
    _toolbar.redo_requested.connect(redo)
    _toolbar.copy_requested.connect(func(): _copy_selection(_editor_clipboard))
    _toolbar.cut_requested.connect(func(): _cut_selection(_editor_clipboard))
    _toolbar.paste_requested.connect(func(): _paste_selection(_editor_clipboard))
    _toolbar.duplicate_requested.connect(_duplicate_selection)
    _toolbar.delete_requested.connect(_delete_selection)

    _command_history.history_changed.connect(_refresh_toolbar_undo_redo)
    _command_history.future_changed.connect(_refresh_toolbar_undo_redo)

    _command_history.history_changed.connect(_update_modified_state)
    _command_history.future_changed.connect(_update_modified_state)
    _update_modified_state()

    _toolbar.set_filename_label(current_file_path)

    _refresh_toolbar_undo_redo()


## Manage mouse and keyboard inputs. Shortcuts are handled by the [CGEToolBar] toolbar.
## Except select all, that will be moved later to the toolbar.
## Pan and zoom are handled by the embedded [CGEGraphViewer] and never reach here.
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        match event.button_index:
            # Left clic selection
            MOUSE_BUTTON_LEFT:
                _handle_mouse_button_left(event)

            MOUSE_BUTTON_RIGHT:
                _handle_mouse_button_right(event)

    elif event is InputEventMouseMotion:
        _handle_mouse_motion(event)

    elif event is InputEventKey:
        if event.is_pressed():
            match event.keycode:
                KEY_ESCAPE:
                    if is_dragging():
                        cancel_dragging()
                    elif is_drag_box_selecting():
                        _cancel_drag_box_selection()
                    else:
                        clear_selection()

                KEY_A:
                    if event.ctrl_pressed:
                        _on_select_all()


## Called when the "Select All" action is triggered. Selects all nodes and connections in the graph. If all are already selected, deselects all instead.
func _on_select_all() -> void:
    # If all selected, deselect all
    var nb_selected: int = len(_selection)
    var all_nodes: Array[CGEGraphNodeUI] = _viewer.get_all_node_uis()
    var all_links: Array[CGEGraphLinkUI] = _viewer.get_all_link_uis()
    var total_graph_element: int = all_nodes.size() + all_links.size()

    if nb_selected == total_graph_element:
        clear_selection()
        return

    for graph_node in all_nodes:
        select_graph_element(graph_node)

    for graph_link in all_links:
        select_graph_element(graph_link)


## Start (move-)dragging the selected nodes.
func _start_dragging(position: Vector2) -> void:
    if _state == CGEState.DRAGGING:
        push_error("Already dragging, cannot start dragging again, something is wrong.")
        return

    _drag_start_position = position
    _drag_end_position = position
    # Keep the position of the nodes in the selection
    for node in _selection:
        if not node is CGEGraphElementUI:
            push_error("Node %s is not a CGEGraphElementUI, something is wrong." % node.name)
            continue
        _drag_nodes_start_positions.append(node.position)
    _state = CGEState.DRAGGING


## Validate the dragging of the selected nodes, creating a command for undo/redo.
func _validate_dragging() -> void:
    if _state != CGEState.DRAGGING:
        push_error("Cannot validate dragging, not in dragging state, something is wrong.")
        return

    var mouse_delta = (_drag_end_position - _drag_start_position) / _viewer.zoom

    var nodes_id: Array[int] = []
    for node in _selection:
        nodes_id.push_back(node.get_id())

    # manually add the command for undo, the dragging have already been made via editor
    # Not ideal, might fix it later.
    if not is_zero_approx(mouse_delta.length_squared()):
        var translate_selection_cmd := CGETranslateCommand.new(self, nodes_id, mouse_delta)
        translate_selection_cmd._cache_selection()
        _command_history.push(
            translate_selection_cmd
        )
        file_is_modified = true

    _stop_dragging()


## Stop dragging the selected nodes.
func _stop_dragging() -> void:
    if _state != CGEState.DRAGGING:
        push_error("Cannot stop dragging, not in dragging state, something is wrong.")
        return
    _state = CGEState.DEFAULT
    _drag_start_position = Vector2.ZERO
    _drag_end_position = Vector2.ZERO
    _drag_nodes_start_positions.clear()


## Cancel the dragging of the selected nodes, resetting their positions.
func cancel_dragging():
    if _state != CGEState.DRAGGING:
        push_error("Cannot cancel dragging, not in dragging state, something is wrong.")
        return
    # Reset the positions of the nodes in the selection
    for i in range(_selection.size()):
        var node = _selection[i]
        if not node is CGEGraphElementUI:
            push_error("Node %s is not a CGEGraphElementUI, something is wrong." % node.name)
            continue
        node.global_position = _drag_nodes_start_positions[i]
    _stop_dragging()


# Start drag-box selection from the given position.
func _start_drag_box_selection(position: Vector2) -> void:
    if _state == CGEState.DRAG_BOX_SELECTING:
        push_error("Already drag-box selecting, cannot start again, something is wrong.")
        return

    _drag_box_start = position
    _drag_box_end = position
    _state = CGEState.DRAG_BOX_SELECTING


# Validate the drag-box selection, selecting all nodes and links within the box (even partially). If add_to_selection is false, clears the current selection first.
func _validate_drag_box_selection(add_to_selection: bool) -> void:
    if _state != CGEState.DRAG_BOX_SELECTING:
        push_error("Cannot validate drag-box selection, not in drag-box selecting state, something is wrong.")
        return

    # Check if it was just a click (minimum drag distance)
    var drag_distance = (_drag_box_end - _drag_box_start).length()

    if drag_distance < MIN_DRAG_DISTANCE:
        # Just a click, clear selection if not adding
        if not add_to_selection:
            clear_selection()
        _stop_drag_box_selection()
        return

    # Get selection rectangle in world coordinates
    var box_rect_screen = _get_drag_box_rect()
    var box_rect_world = _viewer.screen_rect_to_world_rect(box_rect_screen)

    # Select all elements that intersect with the box
    if not add_to_selection:
        clear_selection()

    # Select nodes
    for node in _viewer.get_all_node_uis():
        var node_rect = Rect2(node.position, node.size)
        if box_rect_world.intersects(node_rect):
            select_graph_element(node)

    # Select links
    for link in _viewer.get_all_link_uis():
        if link.intersects_rect(box_rect_world):
            select_graph_element(link)

    _stop_drag_box_selection()


# Stop drag-box selection.
func _stop_drag_box_selection() -> void:
    if _state != CGEState.DRAG_BOX_SELECTING:
        push_error("Cannot stop drag-box selection, not in drag-box selecting state, something is wrong.")
        return
    _state = CGEState.DEFAULT
    _drag_box_start = Vector2.ZERO
    _drag_box_end = Vector2.ZERO


# Cancel the drag-box selection.
func _cancel_drag_box_selection() -> void:
    if _state != CGEState.DRAG_BOX_SELECTING:
        push_error("Cannot cancel drag-box selection, not in drag-box selecting state, something is wrong.")
        return
    _stop_drag_box_selection()


# Returns the drag box as a Rect2 in screen space.
func _get_drag_box_rect() -> Rect2:
    # Returns the drag box as a Rect2 in screen space
    var min_x = min(_drag_box_start.x, _drag_box_end.x)
    var min_y = min(_drag_box_start.y, _drag_box_end.y)
    var max_x = max(_drag_box_start.x, _drag_box_end.x)
    var max_y = max(_drag_box_start.y, _drag_box_end.y)
    return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


# Start connecting from the given node.
func _start_connecting(node: CGEGraphNodeUI) -> void:
    if _state == CGEState.CONNECTING:
        push_error("Already connecting, cannot start connecting again, something is wrong.")
        return

    _viewer.start_connection_preview(node)

    _state = CGEState.CONNECTING


# Stop connecting to the given node (or cancel if null).
func _stop_connecting(node_under_mouse: CGEGraphNodeUI) -> void:
    if _state != CGEState.CONNECTING:
        push_error("Cannot stop connecting, not in connecting state, something is wrong.")
        return

    if node_under_mouse == null:
        _cancel_connecting()
        return

    _viewer.stop_connection_preview(node_under_mouse)

    _state = CGEState.DEFAULT


# Cancel the connecting operation.
func _cancel_connecting() -> void:
    if _state != CGEState.CONNECTING:
        push_error("Cannot cancel connecting, not in connecting state, something is wrong.")
        return

    _viewer.cancel_connection_preview()

    _state = CGEState.DEFAULT

## Behavior on mouse button left (selecting, dragging, drag-box selecting)
func _handle_mouse_button_left(event: InputEventMouseButton):
    # Called when an event is an InputEventMouseButton with button_index MOUSE_BUTTON_LEFT
    var hit_node: CGEGraphElementUI = null

    if event.pressed:
        hit_node = _viewer.get_graph_element_under_mouse()

    if event.pressed:
        # clicked on a node
        if hit_node:
            # With shift, toggle selection
            if event.shift_pressed:
                if hit_node.is_selected():
                    deselect_graph_element(hit_node)
                else:
                    select_graph_element(hit_node)
            # Without shift, clear selection and select the node
            else:
                # If the node is already selected, do nothing
                # otherwise clear selection and select the node
                if not hit_node.is_selected():
                    clear_selection()
                    select_graph_element(hit_node)
            _start_dragging(_viewer.get_mouse_screen_coordinates())
            # else:
        else:
            # clicked on empty space, start drag-box selection
            _start_drag_box_selection(_viewer.get_mouse_screen_coordinates())
    # released
    else:
        var was_dragging = is_dragging()
        var was_drag_box_selecting = is_drag_box_selecting()

        if was_dragging:
            _validate_dragging()
        elif was_drag_box_selecting:
            _validate_drag_box_selection(event.shift_pressed)


## Behavior on mouse button right (connecting nodes)
func _handle_mouse_button_right(event: InputEventMouseButton) -> void:
    # Called when an event is an InputEventMouseButton with button_index MOUSE_BUTTON_RIGHT
    var hit_node: CGEGraphElementUI = null
    hit_node = _viewer.get_mouse_over_node()

    if event.pressed:
        if hit_node:
            _start_connecting(hit_node)
    else:
        if is_connecting():
            _stop_connecting(hit_node)


## Behavior on mouse motion (dragging, drag-box selecting, connecting). Panning is handled by the
## embedded [CGEGraphViewer] and never reaches here.
func _handle_mouse_motion(event: InputEventMouseMotion):
    # Called when an event is an InputEventMouseMotion
    match event.button_mask:
        MOUSE_BUTTON_LEFT:
            if is_dragging():
                _drag_end_position = _viewer.get_mouse_screen_coordinates()
                var mouse_delta = (_drag_end_position - _drag_start_position) / _viewer.zoom
                for i in range(_selection.size()):
                    var selected_node = _selection[i]
                    # for now, specifically do not move CGEGraphLinkUI
                    # I will see later if I need to abstract this to CGEGraphElementUI with for instance
                    # a canMove field, but I don't have the full picture yet
                    if selected_node is CGEGraphLinkUI:
                        continue
                    selected_node.position = _drag_nodes_start_positions[i] + mouse_delta
            elif is_drag_box_selecting():
                _drag_box_end = _viewer.get_mouse_screen_coordinates()
                queue_redraw() # Redraw to show the selection box

        MOUSE_BUTTON_RIGHT:
            if is_connecting():
                var hit_node: CGEGraphElementUI = null
                hit_node = _viewer.get_mouse_over_node()

                _viewer.update_connection_preview(hit_node)


## Called when a new link is requested between two nodes.
func _on_new_link_requested(start_node: CGEGraphNodeUI, end_node: CGEGraphNodeUI) -> void:
    var cmd: CGECommand = CGEAddLinkCommand.new(self, start_node.get_id(), end_node.get_id())
    execute_command(cmd)


## Called when the "Add Node" action is triggered from the toolbar.
func _on_add_node_requested() -> void:
    var cmd: CGECommand = CGEAddNodeCommand.new(
        self,
    )
    execute_command(cmd)


## Delete the current selection.
func _delete_selection() -> void:
    if _selection.is_empty():
        return

    var nodes_id: Array[int] = []
    var links_id: Array[int] = []
    for elem in _selection:
        if elem is CGEGraphNodeUI:
            nodes_id.push_back(elem.get_id())
        elif elem is CGEGraphLinkUI:
            links_id.push_back(elem.get_id())


    execute_command(CGERemoveSelectionCommand.new(self, nodes_id, links_id))

    _selection.clear()
    selection_changed.emit(_selection)


## Copy the current selection to the given clipboard.
func _copy_selection(clipboard: CGEClipboard) -> void:
    if _selection.is_empty():
        return

    clipboard.clear()

    var selected_nodes_ids: Array[int] = []

    # Copy nodes
    for element in _selection:
        if element is CGEGraphNodeUI:
            var node: CGEGraphNodeUI = element
            clipboard.add_node(node)
            selected_nodes_ids.append(node.get_id())

    # Copy links
    # Only keep the ones connected to two selected nodes
    for element in _selection:
        if element is CGEGraphLinkUI:
            var link: CGEGraphLinkUI = element
            if link.start_node.get_id() in selected_nodes_ids and link.end_node.get_id() in selected_nodes_ids:
                clipboard.add_link(link)


## Cut (copy and delete) the current selection to the given clipboard.
func _cut_selection(clipboard: CGEClipboard) -> void:
    if _selection.is_empty():
        return

    _copy_selection(clipboard)
    _delete_selection()


## Paste the given clipboard into the graph. Returns the paste command for undo/redo, or null if clipboard is empty.
func _paste_selection(clipboard: CGEClipboard) -> CGEPasteClipboardCommand:
    if clipboard.is_empty():
        return null

    var cmd := CGEPasteClipboardCommand.new(self, clipboard.nodes, clipboard.links)
    execute_command(cmd)
    return cmd


## Copy and paste without changing the current clipboard
func _duplicate_selection() -> void:
    if _selection.is_empty():
        return

    var cmd := CGEDuplicateSelectionCommand.new(self)
    execute_command(cmd)


##### TOOLBAR MAPPING #####
## Instantiate the file dialog for save/load operations.
func _instantiate_file_dialog() -> void:
    if _file_dialog != null:
        _file_dialog.queue_free()

    _file_dialog = FileDialog.new()
    add_child(_file_dialog)
    _file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    _file_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS

    const DEFAULT_FILE_NAME: String = "my_graph.gegraph"
    _file_dialog.current_file = DEFAULT_FILE_NAME

    _file_dialog.filters = PackedStringArray(["*.gegraph"])
    _file_dialog.current_dir = _file_dialog.current_dir + "tmp_save/"
    # _file_dialog.current_dir = OS.get_system_dir(OS.SystemDir.SYSTEM_DIR_DOCUMENTS)

    _file_dialog.canceled.connect(_file_dialog.queue_free, CONNECT_ONE_SHOT)

    _file_dialog.size = Vector2(720, 500)

## Called when the "Save" action is triggered from the toolbar. See also [method save_to_file].
func _on_save_requested() -> void:
    if current_file_path == "":
        _on_save_as_requested()
        return

    # Directly save to file, if modified
    if not file_is_modified:
        return

    save_to_file(current_file_path)


## Called when the "Save As" action is triggered from the toolbar. See [method _on_save_requested].
func _on_save_as_requested() -> void:
    _instantiate_file_dialog()
    _file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    _file_dialog.file_selected.connect(save_to_file, CONNECT_ONE_SHOT)

    _file_dialog.show()


## Called when the "Load" action is triggered from the toolbar. See also [method load_from_file].
func _on_load_requested() -> void:
    _instantiate_file_dialog()
    _file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    _file_dialog.file_selected.connect(load_from_file, CONNECT_ONE_SHOT)

    if current_file_path != "":
        _file_dialog.current_dir = current_file_path.get_base_dir()

    _file_dialog.show()


## Update the modified state based on the command history.
func _update_modified_state() -> void:
    file_is_modified = _command_history.is_modified()


###### INSPECTOR SPECIFIC METHODS

## Called when the inspector requests a command. Executes it (and fill the graph_editor info first)
func _on_inspector_command_requested(cmd: CGECommand) -> void:
    cmd._graph_editor = self
    cmd._graph = graph

    execute_command(cmd)
