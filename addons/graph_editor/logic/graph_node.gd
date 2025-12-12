@tool
class_name CGEGraphNode
extends CGEGraphElement
## Represents a node in the custom graph editor.
##
## This class defines a node within the graph.


## String representation of the node
func _to_string() -> String:
    return "CGEGraphNode(id:%d)" % [id]


func serialize() -> Dictionary:
    return {
        "id": id
    }


func deserialize(data: Dictionary) -> void:
    if data.has("id"):
        id = data["id"]