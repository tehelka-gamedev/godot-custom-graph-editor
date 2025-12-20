@abstract class_name CGECommand
extends RefCounted

var _graph_editor: CGEGraphEditor = null
var _graph: CGEGraph = null
var _previous_selected_node_ids: Array[int] = []
var _previous_selected_link_ids: Array[int] = []


func _init(graph_ed: CGEGraphEditor) -> void:
    _graph_editor = graph_ed
    _graph = _graph_editor.graph if _graph_editor else null


## Execute the command. Returns true if it should be added to history.
## Override this method to implement the command logic.
@abstract
func execute() -> bool


## Undo the command
## Override this method if it is undoable.
func undo() -> void:
    pass


## Cache the current selection state (both nodes and links)
func _cache_selection() -> void:
    _previous_selected_node_ids.clear()
    _previous_selected_link_ids.clear()
    for element in _graph_editor._selection:
        if element is CGEGraphNodeUI:
            _previous_selected_node_ids.append(element.get_id())
        elif element is CGEGraphLinkUI:
            _previous_selected_link_ids.append(element.get_id())


## Restore the cached selection state
func _restore_selection() -> void:
    _graph_editor.clear_selection()
    for node_id in _previous_selected_node_ids:
        var node_ui: CGEGraphNodeUI = _graph_editor.get_graph_node(node_id)
        if node_ui != null:
            _graph_editor.select_graph_element(node_ui)
    for link_id in _previous_selected_link_ids:
        var link_ui: CGEGraphLinkUI = _graph_editor.get_graph_link(link_id)
        if link_ui != null:
            _graph_editor.select_graph_element(link_ui)

func _to_string():
    return "CGECommand()"