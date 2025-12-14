@tool
class_name LocationNode
extends CGEGraphNode
## Represents a location in a world map graph.
##
## This custom node stores a location name for world/map navigation systems.

## The name of this location
var location_name: String = "Location"


## Serialize the node data including the location name
func serialize() -> Dictionary:
    var data: Dictionary = super()
    data["location_name"] = location_name
    return data


## Deserialize the node data including the location name if present
func deserialize(data: Dictionary) -> void:
    super(data)
    if data.has("location_name"):
        location_name = data["location_name"]


## String representation for debugging
func _to_string() -> String:
    return "LocationNode(id:%d, name:'%s')" % [id, location_name]
