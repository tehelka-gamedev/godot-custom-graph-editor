@tool
class_name TravelPath
extends CGEGraphLink
## Represents a travel path between two locations in the world map.
##
## This custom link stores the travel cost between locations.

## The cost to travel this path (distance, time, or resources)
var travel_cost: int = 1


## Serialize the link data including the travel cost
func serialize() -> Dictionary:
    var data: Dictionary = super()
    data["travel_cost"] = travel_cost
    return data


## Deserialize the link data including the travel cost if present
func deserialize(data: Dictionary) -> void:
    super(data)
    if data.has("travel_cost"):
        travel_cost = int(data["travel_cost"])


## String representation for debugging
func _to_string() -> String:
    return "TravelPath(id:%d, %d->%d, cost:%d)" % [id, start_node_id, end_node_id, travel_cost]
