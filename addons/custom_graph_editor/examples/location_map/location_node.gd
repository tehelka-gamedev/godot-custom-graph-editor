@tool
class_name LocationNode
extends CGEGraphNode
## Represents a location in a world map graph.
##
## This custom node stores a location name for world/map navigation systems and other metadata.

## Location types
enum Type {
    TOWN,
    VILLAGE,
    DUNGEON,
    FOREST
}

## Feature flags for locations
enum Feature {
    SHOP = 1 << 0,
    INN = 1 << 1,
    QUEST = 1 << 2,
    BLACKSMITH = 1 << 3,
}

const DANGER_LEVEL_MIN: int = 0
const DANGER_LEVEL_MAX: int = 10

## The name of this location
var location_name: String = "Location"
## The type of this location
var location_type: Type = Type.TOWN
## Danger level (0-10)
var danger_level: int = 0
## Location features as bitflags (int because it can hold multiple Feature flags OR'd together)
var features: int = 0


## Serialize the node data including the location name
func serialize() -> Dictionary:
    var data: Dictionary = super()
    data["location_name"] = location_name
    data["location_type"] = location_type
    data["danger_level"] = danger_level
    data["features"] = features
    return data


## Deserialize the node data (if the metadata are present)
func deserialize(data: Dictionary) -> void:
    super(data)
    if data.has("location_name"):
        location_name = data["location_name"]
    if data.has("location_type"):
        location_type = data["location_type"]
    if data.has("danger_level"):
        danger_level = data["danger_level"]
    if data.has("features"):
        features = data["features"]


## String representation for debugging
func _to_string() -> String:
    return "LocationNode(id:%d, name:'%s')" % [id, location_name]
