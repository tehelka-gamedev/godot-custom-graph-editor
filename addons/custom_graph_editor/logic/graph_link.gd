@tool
class_name CGEGraphLink
extends CGEGraphElement
## Represents a link between two nodes in the custom graph editor.
##
## This class defines a link that connects two nodes in the graph editor.

## ID of the start node
var start_node_id: int = -1
## ID of the end node
var end_node_id: int = -1


func _init(link_id:int, start_id: int = -1, end_id: int = -1):
    super(link_id)
    start_node_id = start_id
    end_node_id = end_id


## Check if the link is connected to the given node
func is_linked_to(node: CGEGraphNode) -> bool:
    return start_node_id == node.id or end_node_id == node.id


## Return a string representation of the link
func _to_string() -> String:
    return "#%d|%d -> %d" % [id, start_node_id, end_node_id]


## Serialize the link data into a dictionary
func serialize() -> Dictionary:
    return {
        "id": id,
        "start_node_id": start_node_id,
        "end_node_id": end_node_id
    }


func deserialize(data: Dictionary) -> void:
    if data.has("id"):
        id = data["id"]
    if data.has("start_node_id"):
        start_node_id = int(data["start_node_id"])
    if data.has("end_node_id"):
        end_node_id = int(data["end_node_id"])