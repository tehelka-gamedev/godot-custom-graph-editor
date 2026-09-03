@tool
class_name ConditionNode
extends CGEGraphNode
## Represents a condition node in a graph.
##
## This custom node stores free-text "condition expression" (that could be used elsewhere in a condition system or whatever).

## Display name of the node.
var node_name: String = "Condition"
## Free-text condition expression (e.g player.has_item("key"))
var condition_expression: String = ""


## Serialize the node data including the custom properties
func serialize() -> Dictionary:
    var data: Dictionary = super()
    data["node_name"] = node_name
    data["condition_expression"] = condition_expression
    return data


## Deserialize the node data (if the metadata are present)
func deserialize(data: Dictionary) -> void:
    super(data)
    if data.has("node_name"):
        node_name = data["node_name"]
    if data.has("condition_expression"):
        condition_expression = data["condition_expression"]


## String representation for debugging
func _to_string() -> String:
    return "ConditionNode(id:%d, name:'%s')" % [id, node_name]
