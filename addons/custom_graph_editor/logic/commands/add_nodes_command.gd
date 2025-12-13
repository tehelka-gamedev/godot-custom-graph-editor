class_name CGEAddNodesCommand
extends CGECommand
## Command to add multiple nodes to the graph at once.
##
## This command allows adding multiple nodes to the graph at once, each at a specified position.

## UI positions for each node. The size of this array represents the number of nodes created.
var positions: Array[Vector2] = []

## Cached IDs of created nodes (for undo purposes)
var _created_node_ids: Array[int] = []


func _init(graph_ed: CGEGraphEditor, position_array: Array[Vector2]) -> void:
    super(graph_ed)

    positions = position_array.duplicate()


## Create nodes at specified positions
func execute() -> bool:
    if positions.is_empty():
        push_error("CGEAddNodesCommand: cannot execute command with no position given, no node will be created.")
        return false

    _created_node_ids.clear()

    _cache_selection()

    # Clear selection before creating new nodes
    _graph_editor.clear_selection()

    for pos in positions:
        # Create node in graph
        var new_node = _graph.create_node()
        if new_node == null:
            continue


        _created_node_ids.append(new_node.id)

        # Get UI node and set position
        var node_ui = _graph_editor.get_graph_node(new_node.id)
        if node_ui:
            node_ui.position = pos

    # Select all created nodes
    for node_id in _created_node_ids:
        var node_ui = _graph_editor.get_graph_node(node_id)
        if node_ui != null:
            _graph_editor.select_graph_element(node_ui)

    return not _created_node_ids.is_empty()


## Remove the created nodes
func undo() -> void:
    # Remove all created nodes
    for node_id in _created_node_ids:
        _graph_editor.graph.remove_node(node_id)
    _created_node_ids.clear()

    _restore_selection()


## Get the IDs of the created nodes by this command 
func get_created_nodes_id() -> Array[int]:
    return _created_node_ids