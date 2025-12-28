@tool
class_name TravelPathUI
extends CGEGraphLinkUI
## Visual representation of a travel path in the world map graph.
##
## This demonstrates customizing the link appearance for travel paths.

## Label to display the travel cost
@onready var cost_label: Label = %CostLabel


func _ready() -> void:
    # Customize the link color (brown/earthy for paths)
    color = Color(0.6, 0.5, 0.3, 1.0)
    hover_color = Color(1.0, 0.8, 0.4, 1.0)
    width = 4
    _update_cost_label()


## Custom drawing: call parent then draw the cost label
func _draw() -> void:
    super()
    _position_cost_label()


## Called when the graph element is set or updated
## This is called both when creating new links and when loading from file
func _update_ui_from_data() -> void:
    _update_cost_label()


## Update the label to show the travel cost
func _update_cost_label() -> void:
    var travel_path: TravelPath = graph_element as TravelPath
    if cost_label and travel_path:
        cost_label.text = str(travel_path.travel_cost)


## Position the cost label at the midpoint of the link
func _position_cost_label() -> void:
    if cost_label and points.size() >= 2:
        # Calculate midpoint
        var midpoint: Vector2 = Vector2.ZERO
        for point in points:
            midpoint += point
        midpoint /= points.size()

        # Position the label at the midpoint
        cost_label.position = midpoint - cost_label.size / 2


# Add travelel cost to the inspector
func _setup_inspector(inspector: CGEInspectorPanel) -> void:
    var travel_path: TravelPath = graph_element as TravelPath
    inspector.add_property(
        "Travel Cost",
        func(): return travel_path.travel_cost,
        func(value) -> bool:
            travel_path.travel_cost = value
            return true
    )
