@tool
class_name CGEGraphViewer
extends Control
## Standalone graph viewer: pan/zoom and node/link UI instantiation & tracking.
##
## Owns a [CGEGraph] reference and renders it (node/link UI, panning, zooming). It has no editor functionality (see [CGEGraphEditor] for an extension of that).
## Can be used standalone (e.g. a read-only in-game graph viewer).


### Signals

## Emitted after a node's UI has been instantiated and added to the tree.
signal node_ui_created(node_id: int, node_ui: CGEGraphNodeUI)
## Emitted just before a node's UI is freed.
signal node_ui_removed(node_id: int, node_ui: CGEGraphNodeUI)
## Emitted after a link's UI has been instantiated and added to the tree.
signal link_ui_created(start_node_id: int, end_node_id: int, link_id: int, link_ui: CGEGraphLinkUI)
## Emitted just before a link's UI is removed.
signal link_ui_removed(link_id: int, link_ui: CGEGraphLinkUI)
## Emitted when the user drags from one node to another to request a new link.
signal link_requested(start_node: CGEGraphNodeUI, end_node: CGEGraphNodeUI)


### Constants

## Pixels to offset parallel links
const OFFSET_DISTANCE = 15.0


### Exports

@export_category("Nodes reference")
## Graph UI node (scene) used to instantiate nodes
@export var graph_node_ui_scene := preload("res://addons/custom_graph_editor/UI/graph_node_ui.tscn")
## Graph UI link (scene) used to instantiate links
@export var graph_link_ui_scene := preload("res://addons/custom_graph_editor/UI/graph_link_ui.tscn")
## Script defining graph nodes (logic) in the graph. Must inherit CGEGraphNode
@export var node_class: GDScript = preload("res://addons/custom_graph_editor/logic/graph_node.gd")
## Script defining graph link (logic) in the graph. Must inherit CGEGraphLink
@export var link_class: GDScript = preload("res://addons/custom_graph_editor/logic/graph_link.gd")

@export_category("Viewer Settings")
## Current zoom amount
@export var zoom: float = 1.0
## Zoom increase/decrease value
@export var zoom_step: float = 0.2
## Max zoom amount
@export var max_zoom: float = 2.0
## Min zoom amount
@export var min_zoom: float = 0.5


### Regular variables

## [CGEGraph] graph logic instance currently displayed. Holds the graph data. See [method load_graph].
var graph: CGEGraph = CGEGraph.new()

## Graph nodes container
var _nodes = Control.new()
## Mapping of node IDs to their UI representation.
var _nodes_ref: Dictionary[int, CGEGraphNodeUI] = {}

## Graph connections container. See [CGEConnectionContainer].
var _connections: CGEConnectionContainer = CGEConnectionContainer.new()
## Mapping of link IDs to their UI representation.
var _links_ref: Dictionary[int, CGEGraphLinkUI] = {}

# Grid drawn in the background
@onready var _grid: CGEGrid = %Grid
# Content container holding nodes and connections
@onready var _content: Control = %Content
# References to scroll bars
@onready var _h_scroll_bar: HScrollBar = %HScrollBar
@onready var _v_scroll_bar: VScrollBar = %VScrollBar


## Given a path to a .gegraph, returns a deserialized CGEGraph
## allowing to have just node and connectivity info and scrap out
## all the editor specific data.[br]
##
## [param path]: Path to the .gegraph file[br]
## [param node_script]: GDScript class for nodes (must inherit from CGEGraphNode)[br]
## [param link_script]: GDScript class for links (must inherit from CGEGraphLink)[br]
static func deserialize_graph_runtime(path: String, node_script: GDScript, link_script: GDScript) -> CGEGraph:
    if not FileAccess.file_exists(path):
        push_error("Tried to deserialize a graph from '%s' but it does not exist!" % path)
        return null

    var file: FileAccess = FileAccess.open(path, FileAccess.READ)

    var json: JSON = JSON.new()
    var json_string: String = file.get_as_text()
    var parse_result := json.parse(json_string)

    if not parse_result == OK:
        push_error("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return null

    var data: Dictionary = json.data as Dictionary

    file.close()

    var new_graph: CGEGraph = CGEGraph.new()
    new_graph.node_class = node_script
    new_graph.link_class = link_script

    new_graph.deserialize(data)

    return new_graph


func _init():
    focus_mode = Control.FOCUS_ALL

    # Enforce mouse filter to ignore
    _nodes.name = "nodes"
    _nodes.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _connections.name = "connectionsHolder"
    _connections.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready():
    if _h_scroll_bar:
        _h_scroll_bar.value_changed.connect(_on_h_scroll_changed)
    if _v_scroll_bar:
        _v_scroll_bar.value_changed.connect(_on_v_scroll_changed)

    _content.add_child(_nodes)
    _content.add_child(_connections)
    queue_redraw()

    # Configure the connection container to use the same link UI scene as the viewer
    _connections.link_ui_scene = graph_link_ui_scene
    _connections.request_link.connect(func(start_node: CGEGraphNodeUI, end_node: CGEGraphNodeUI): link_requested.emit(start_node, end_node))

    # Update scrollbar page size when viewport is resized
    resized.connect(_update_scrollbar_pages)
    # Set initial page size and center the view
    _update_scrollbar_pages()
    _center_scrollbars()


## (Re)binds this viewer to display the given graph: unbinds any previously-bound graph (freeing its
## node/link UI), then connects to the new graph's signals and builds UI for every node/link already
## present in it. Safe to call once at startup (e.g. with an initially-empty graph) or later to swap
## graphs entirely (e.g. a runtime graph loaded via [method deserialize_graph_runtime]).
func load_graph(new_graph: CGEGraph) -> void:
    _unbind_current_graph()

    graph = new_graph
    graph.node_created.connect(_on_node_created)
    graph.node_deleted.connect(_on_node_deleted)
    graph.link_created.connect(_on_link_created)
    graph.link_deleted.connect(_on_link_deleted)

    for node_id in graph.get_all_node_ids():
        _on_node_created(node_id)
    for link_id in graph.get_all_link_ids():
        var link: CGEGraphLink = graph.get_link(link_id)
        _on_link_created(link.start_node_id, link.end_node_id, link_id)


func _unbind_current_graph() -> void:
    if graph == null:
        return
    if graph.node_created.is_connected(_on_node_created):
        graph.node_created.disconnect(_on_node_created)
        graph.node_deleted.disconnect(_on_node_deleted)
        graph.link_created.disconnect(_on_link_created)
        graph.link_deleted.disconnect(_on_link_deleted)
    for node_ui in get_all_node_uis():
        node_ui.queue_free()
    for link_ui in get_all_link_uis():
        link_ui.queue_free()
    _nodes_ref.clear()
    _links_ref.clear()


## Manage pan (middle-drag) and zoom (wheel / middle-double-click) input. Everything else bubbles
## unhandled to whichever Control embeds this viewer (e.g. [CGEGraphEditor]).
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        match event.button_index:
            MOUSE_BUTTON_WHEEL_UP:
                if has_focus():
                    _zoom_in(zoom_step)
                    accept_event()

            MOUSE_BUTTON_WHEEL_DOWN:
                if has_focus():
                    _zoom_out(zoom_step)
                    accept_event()

            MOUSE_BUTTON_MIDDLE:
                if event.double_click:
                    reset_zoom()
                    accept_event()

    elif event is InputEventMouseMotion:
        if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
            _h_scroll_bar.value -= event.relative.x
            _v_scroll_bar.value -= event.relative.y
            queue_redraw()
            accept_event()


######## PUBLIC METHODS ########

## Returns the mouse in the world coordinates.
## Since we do not move a camera but instead move the _content to simulate a panning,
## the mouse world position is actually computed from the _content node space.
func get_mouse_world_coordinates() -> Vector2:
    var mouse_screen_pos = get_global_mouse_position()
    var content_origin = _content.global_position
    return (mouse_screen_pos - content_origin) / zoom


## Returns the mouse position in screen coordinates. See also [method get_mouse_world_coordinates].
func get_mouse_screen_coordinates() -> Vector2:
    return _content.get_global_mouse_position()


## Returns the center of the screen in world coordinates. See also [method get_mouse_world_coordinates].
func get_screen_center_coordinates() -> Vector2:
    var screen_center_pos: Vector2 = global_position + size / 2
    var content_origin: Vector2 = _content.global_position
    return (screen_center_pos - content_origin) / zoom


## Converts a Rect2 in screen space (see [method get_mouse_screen_coordinates]) into world space.
func screen_rect_to_world_rect(rect: Rect2) -> Rect2:
    return Rect2(
        (rect.position - _content.global_position) / zoom,
        rect.size / zoom
    )


## Adjusts pan and zoom so every current node UI is inside in the viewport, with [param margin]
## pixels at each side. 
## You might want to call it after an [code]await get_tree().process_frame[/code] right after
## [method load_graph] if you call it from [code]_ready()[/code]).
func fit_to_view(margin: float = 40.0) -> void:
    var node_uis: Array[CGEGraphNodeUI] = get_all_node_uis()
    if node_uis.is_empty() or size.x <= 0.0 or size.y <= 0.0:
        return

    var bounds: Rect2 = Rect2(node_uis[0].position, node_uis[0].size)
    for node_ui in node_uis:
        bounds = bounds.merge(Rect2(node_ui.position, node_ui.size))
    bounds = bounds.grow(margin)

    if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
        return

    set_zoom(min(size.x / bounds.size.x, size.y / bounds.size.y))

    var bounds_center: Vector2 = bounds.position + bounds.size / 2.0
    _h_scroll_bar.value = bounds_center.x * zoom - size.x / 2.0
    _v_scroll_bar.value = bounds_center.y * zoom - size.y / 2.0


## Adds [param control] as a child of the viewer's content layer (the same space nodes and links
## live in), so it pans and zooms together with the graph.
func add_to_content(control: Control) -> void:
    _content.add_child(control)


## Set the zoom level of the viewer.
func set_zoom(value: float) -> void:
    var previous_zoom = zoom
    var previous_mouse_pos = get_mouse_world_coordinates()
    zoom = clamp(value, min_zoom, max_zoom)
    if previous_zoom != zoom:
        _grid.zoom = zoom
        _content.scale = Vector2(zoom, zoom)

        var offset: Vector2 = get_mouse_world_coordinates() - previous_mouse_pos

        # Adjust _content position to keep the mouse position stable
        # A bit clunky in the edge cases, but good enough for now
        _h_scroll_bar.value -= offset.x * zoom
        _v_scroll_bar.value -= offset.y * zoom

        queue_redraw()


## Reset the zoom level to 1.0
func reset_zoom() -> void:
    set_zoom(1.0)


## On zoom in action
func _zoom_in(amount: float) -> void:
    set_zoom(zoom + amount)


## On zoom out action
func _zoom_out(amount: float) -> void:
    set_zoom(zoom - amount)


## Returns the node UI under the mouse, or null if none.
func get_mouse_over_node() -> CanvasItem:
    var children = _nodes.get_children()
    # Iterate in reverse to check top-most nodes first (last child = highest z-order)
    for i in range(children.size() - 1, -1, -1):
        var node = children[i]
        if not node is Control:
            push_warning("Node %s is not a Control, is this normal?" % node.name)
            continue
        # use local position because we can pan the view
        if node.get_rect().has_point(_nodes.get_local_mouse_position()):
            return node
    return null


## Returns the connection UI under the mouse, or null if none.
func get_mouse_over_connection() -> CanvasItem:
    for connection in _connections.get_children():
        if not connection is CGEGraphLinkUI:
            push_error("Conection %s is not a CGEGraphLinkUI, something is wrong." % connection.name)
            continue
        var connection_link: CGEGraphLinkUI = connection
        if connection_link.is_on_line(_connections.get_local_mouse_position()):
            return connection_link
    return null


## Returns the graph element (node or link) UI under the mouse, or null if none.
## Nodes have priority over links.
func get_graph_element_under_mouse() -> CGEGraphElementUI:
    var hit_node: CGEGraphElementUI = get_mouse_over_node()
    # no node, try to get a connection
    if hit_node == null:
        hit_node = get_mouse_over_connection()

    return hit_node


## Get the UI element for the given element ID, or null if not found.
func get_graph_element(element_id: int) -> CGEGraphElementUI:
    var node: CGEGraphNodeUI = get_graph_node(element_id)
    if node:
        return node

    return get_graph_link(element_id)


## Get the UI node for the given graph node ID, or null if not found.
func get_graph_node(node_id: int) -> CGEGraphNodeUI:
    return _nodes_ref.get(node_id)


## Get the UI link for the given graph link ID, or null if not found.
func get_graph_link(link_id: int) -> CGEGraphLinkUI:
    return _links_ref.get(link_id)


## Returns every currently instantiated node UI.
func get_all_node_uis() -> Array[CGEGraphNodeUI]:
    return _nodes_ref.values()


## Returns every currently instantiated link UI.
func get_all_link_uis() -> Array[CGEGraphLinkUI]:
    return _links_ref.values()


## Start a stateless connection-drag preview from the given node.
func start_connection_preview(node: CGEGraphNodeUI) -> void:
    _connections.start_connecting(node, get_mouse_world_coordinates())


## Update the in-progress connection-drag preview.
func update_connection_preview(node_under_mouse: CGEGraphNodeUI) -> void:
    _connections.handle_mouse_motion_button_right(node_under_mouse, get_mouse_world_coordinates())


## Stop the in-progress connection-drag preview, requesting a link if [param node_under_mouse] is valid.
func stop_connection_preview(node_under_mouse: CGEGraphNodeUI) -> void:
    _connections.stop_connecting(node_under_mouse)


## Cancel the in-progress connection-drag preview.
func cancel_connection_preview() -> void:
    _connections.cancel_connecting()


######## PRIVATE METHODS ########

## Update scrollbar page sizes based on viewport size.
func _update_scrollbar_pages() -> void:
    if _h_scroll_bar:
        _h_scroll_bar.page = size.x * 0.8
    if _v_scroll_bar:
        _v_scroll_bar.page = size.y * 0.8


## Center the scrollbars so the view starts at origin (0, 0).
func _center_scrollbars() -> void:
    if _h_scroll_bar:
        _h_scroll_bar.value = - _h_scroll_bar.page / 2.0
    if _v_scroll_bar:
        _v_scroll_bar.value = - _v_scroll_bar.page / 2.0


## Called when the horizontal scroll bar value changes.
func _on_h_scroll_changed(value: float) -> void:
    # This is not ideal since we need to think about changing both variables. Maybe change this
    _content.position.x = - value
    _grid.offset.x = - value


## Called when the vertical scroll bar value changes.
func _on_v_scroll_changed(value: float) -> void:
    # This is not ideal since we need to think about changing both variables. Maybe change this
    _content.position.y = - value
    _grid.offset.y = - value


## Called when a new node is created in the graph. Responsible for creating the UI of the created logic-node.
func _on_node_created(node_id: int) -> void:
    var pos: Vector2 = get_screen_center_coordinates()

    var new_node: CGEGraphNodeUI = graph_node_ui_scene.instantiate()
    new_node.graph_element = graph.get_node(node_id)
    _nodes.add_child(new_node)
    new_node.position = pos
    _nodes_ref[node_id] = new_node

    node_ui_created.emit(node_id, new_node)


## Called when a node is deleted from the graph.
func _on_node_deleted(node_id: int) -> void:
    var node_ui: CGEGraphNodeUI = _nodes_ref[node_id]
    node_ui_removed.emit(node_id, node_ui)
    node_ui.queue_free()
    _nodes_ref.erase(node_id) # Remove from dictionary to avoid freed object references


## Called when a new link is created in the graph.
func _on_link_created(start_node_id: int, end_node_id: int, link_id: int) -> void:
    # Create the CGEGraphLinkUI node
    var new_link: CGEGraphLinkUI = graph_link_ui_scene.instantiate()
    new_link.graph_element = graph.get_link(link_id)
    _connections.add_child(new_link)

    new_link.link_to(get_graph_node(start_node_id), get_graph_node(end_node_id))

    _links_ref[link_id] = new_link

    # Update parallel link offsets for this node pair
    _update_parallel_link_offsets(start_node_id, end_node_id)

    link_ui_created.emit(start_node_id, end_node_id, link_id, new_link)


## Called when a link is deleted from the graph.
func _on_link_deleted(link_id: int) -> void:
    var link_to_delete: CGEGraphLinkUI = get_graph_link(link_id)
    if link_to_delete == null:
        push_error("Tried to delete link %d but it was not found.", link_id)
        return

    # Store node IDs before deleting
    var start_node_id = link_to_delete.start_node.get_id() if link_to_delete.start_node else -1
    var end_node_id = link_to_delete.end_node.get_id() if link_to_delete.end_node else -1

    _links_ref.erase(link_id)
    link_to_delete.queue_free()

    # Update parallel link offsets for this node pair
    if start_node_id >= 0 and end_node_id >= 0:
        _update_parallel_link_offsets(start_node_id, end_node_id)

    link_ui_removed.emit(link_id, link_to_delete)


## Update parallel link offsets for all links between two nodes.
## Since the graph forbids duplicate links (for now), there can only be max 2: A->B and B->A
func _update_parallel_link_offsets(node_a_id: int, node_b_id: int) -> void:
    # Get links from both nodes (more efficient than iterating all links)
    var link_a_to_b_id: int = -1
    var link_b_to_a_id: int = -1

    # Check links from node A
    for link in graph.get_links_from(node_a_id):
        if link.end_node_id == node_b_id:
            link_a_to_b_id = link.id
            break

    # Check links from node B
    for link in graph.get_links_from(node_b_id):
        if link.end_node_id == node_a_id:
            link_b_to_a_id = link.id
            break

    # Get UI links
    var link_a_to_b: CGEGraphLinkUI = get_graph_link(link_a_to_b_id) if link_a_to_b_id >= 0 else null
    var link_b_to_a: CGEGraphLinkUI = get_graph_link(link_b_to_a_id) if link_b_to_a_id >= 0 else null

    # Assign offsets if both links exist
    if link_a_to_b != null and link_b_to_a != null:
        # Two parallel links: offset in opposite directions
        link_a_to_b.parallel_link_offset = - OFFSET_DISTANCE
        link_b_to_a.parallel_link_offset = OFFSET_DISTANCE
    else:
        # Only one link: no offset needed
        if link_a_to_b != null:
            link_a_to_b.parallel_link_offset = 0.0
        if link_b_to_a != null:
            link_b_to_a.parallel_link_offset = 0.0
