@tool
class_name MinimalCustomNode
extends CGEGraphNode
## Example custom node with a simple additional "node_name" property.
##
## This demonstrates how to extend CGEGraphNode to add custom data to your nodes.

## The name of this node (custom property).
var node_name: String = "Node"


## Serialize the node data including the custom property
func serialize() -> Dictionary:
    var data: Dictionary = super()
    data["node_name"] = node_name
    return data


## Deserialize the node data including the custom property IF PRESENT
func deserialize(data: Dictionary) -> void:
    super(data)
    if data.has("node_name"):
        node_name = data["node_name"]


## String representation for debugging
func _to_string() -> String:
    return "MinimalCustomNode(id:%d, name:'%s')" % [id, node_name]
