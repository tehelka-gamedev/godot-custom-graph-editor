class_name CGEAddNodeCommand
extends CGECommand
## Command to add a single node to the graph.
##
## This command allows adding a single node to the graph (without specifying its position).

## ID of the created node
var _node_id: int = -1


func _init(graph_ed: CGEGraphEditor, node_id: int = -1) -> void:
    super(graph_ed)
    _node_id = node_id

## Create the node and select it
func execute() -> bool:
    _cache_selection()

    var new_node: CGEGraphNode = _graph.create_node(_node_id)
    _node_id = new_node.id # keep the maybe-changed node id

    # Select the newly created node
    _graph_editor.clear_selection()
    var node_ui: CGEGraphNodeUI = _graph_editor.get_graph_node(_node_id)
    if node_ui != null:
        _graph_editor.select_graph_element(node_ui)

    return true

## Remove the created node
func undo() -> void:
    _graph.remove_node(_node_id)
    _restore_selection()