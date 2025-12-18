class_name CGEPasteClipboardCommand
extends CGECommand
## Command to paste elements from the clipboard into the graph editor.
##
## This command pastes nodes and links from the provided clipboard data into the graph editor,
## creating new elements based on the serialized elements data.

## Offset to apply to pasted nodes to avoid overlap
const offset: Vector2 = Vector2(50, 50)

## Copied nodes data
var nodes_data: Array[Dictionary] = []
## Copied links data
var links_data: Array[Dictionary] = []

## Created nodes IDs.[br]
## Links id are not needed, since we created only links linked to the nodes,
## so when we undo and remove the nodes, the links will be deleted
var created_nodes_ids: Array[int] = []

## Positions for the new nodes
var _nodes_position: Array[Vector2] = []
## Old nodes IDs to map links correctly
var _old_nodes_ids: Array[int] = []                                 


# Pre-compute positions and clean data we do not want to override
func _init(graph_ed: CGEGraphEditor, nodes_data_from_clipboard: Array[Dictionary], links_data_from_clipboard: Array[Dictionary] ) -> void:
    super(graph_ed)
    nodes_data = nodes_data_from_clipboard.duplicate_deep()
    links_data = links_data_from_clipboard.duplicate_deep()

    # Remove "id" key because we do not want to override the new ID
    for i in range(len(nodes_data)):
        var node_data: Dictionary = nodes_data[i]
        # Getting the key for id and position like this is not ideal, maybe make a getter instead ?
        _old_nodes_ids.append(int(node_data["id"]))
        node_data.erase("id")
        _nodes_position.append(Vector2(float(node_data["position"]["x"]), float(node_data["position"]["y"])) + offset) 
        # position is not needed anymore in the node_data, and we don't want it to overrride the position later when we deserialize, so we remove it
        node_data.erase("position")


## Paste the nodes and links into the graph
func execute() -> bool:
    if nodes_data.is_empty():
        return false
        
    var add_nodes_cmd := CGEAddNodesCommand.new(_graph_editor, _nodes_position)
    add_nodes_cmd.execute()

    created_nodes_ids = add_nodes_cmd.get_created_nodes_id()

    # old_id -> copied id mapping to recreate links
    var id_map: Dictionary[int, int] = {}

    for i in range(len(created_nodes_ids)):
        var node_id: int = created_nodes_ids[i]
        var node_ui: CGEGraphNodeUI = _graph_editor.get_graph_node(node_id)
        node_ui.deserialize(nodes_data[i])
        id_map[_old_nodes_ids[i]] = node_id

    # Recreate links
    # _old_nodes_ids[i] is copied to created_nodes_ids[i] so we will map to their equivalent
    for link_data in links_data:
        var old_start_id: int = link_data["start_node_id"]
        var old_end_id: int = link_data["end_node_id"]

        # ignore links with no start or ending copied
        if id_map.has(old_start_id) and id_map.has(old_end_id):
            var new_start_id: int = id_map[old_start_id]
            var new_end_id: int = id_map[old_end_id]
            var new_link := _graph.create_link(new_start_id, new_end_id)

            var clean_link_data: Dictionary = link_data.duplicate_deep()

            clean_link_data.erase("id")
            clean_link_data.erase("start_node_id")
            clean_link_data.erase("end_node_id")
            new_link.deserialize(clean_link_data)

    return not created_nodes_ids.is_empty()


## Remove the pasted nodes (links will be removed automatically by this operation)
func undo() -> void:
    var remove_node_command := CGERemoveNodesCommand.new(_graph_editor, created_nodes_ids)
    remove_node_command.execute()
