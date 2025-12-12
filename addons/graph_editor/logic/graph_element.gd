@tool
@abstract class_name CGEGraphElement
extends RefCounted
## Graph Element for the GraphEditor(GE)
##
## Input is handled by the graph editor, so graph elements do not handle mouse input
## Classes inherinting CGEGraphElement will need to override _draw() method

## Unique ID of the graph element
var id: int = -1


func _init(elem_id: int) -> void:
    id = elem_id


## Return a string representation of the graph element
func _to_string() -> String:
    return "CGEGraphElement(id:%d)" % [id]


## Serialize the element data into a dictionary
@abstract
func serialize() -> Dictionary


## Deserialize data from a dictionary. Should only set properties present in the dictionary.
@abstract
func deserialize(data: Dictionary) -> void