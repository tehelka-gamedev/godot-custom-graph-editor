class_name CGERemoveNodesCommand
extends CGECommand
## Command to remove nodes from the graph.
##
## This command removes specified nodes from the graph.

## Cached data of deleted nodes
var deleted_nodes_data : Dictionary[int, Dictionary] = {}
## Cached links deleted
var links_deleted: Dictionary[int, CGEGraphLink] = {}

## IDs of nodes to remove
var _nodes_id: Array[int] = []


func _init(graph_ed: CGEGraphEditor, nodes_id: Array[int]) -> void:
    super(graph_ed)
    _nodes_id = nodes_id


## Remove the specified nodes
func execute() -> bool:
    deleted_nodes_data.clear()
    for node_id in _nodes_id:
        deleted_nodes_data[node_id] = _graph_editor.get_graph_node(node_id).serialize()
    
        # Save links
        for link in _graph.get_links_linked_to(node_id):
            links_deleted[link.id] = link
        
        _graph.remove_node(node_id)
    
    return true


## Recreate the removed nodes and links
func undo() -> void:
    for node_id in _nodes_id:
        var new_node: CGEGraphNode = _graph.create_node(node_id)
        _graph_editor.get_graph_node(node_id).deserialize(deleted_nodes_data[node_id])

    # Restore the links deleted too
    for link in links_deleted.values():
        _graph.create_link(link.start_node_id, link.end_node_id, link.id)

    # Restore selection (select the restored nodes)
    _graph_editor.clear_selection()
    for node_id in _nodes_id:
        var node_ui: CGEGraphNodeUI = _graph_editor.get_graph_node(node_id)
        if node_ui != null:
            _graph_editor.select_graph_element(node_ui)
