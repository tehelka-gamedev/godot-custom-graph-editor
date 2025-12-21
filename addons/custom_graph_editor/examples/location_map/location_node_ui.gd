@tool
class_name LocationNodeUI
extends CGEGraphNodeUI
## Visual representation of a location node in the world map graph.
##
## This demonstrates customizing the node appearance for location nodes.

## Background color for the node (earthy green tone for locations)
@export var background_color: Color = Color(0.2, 0.5, 0.3, 0.9)

## Label to display the location name
@onready var location_label: Label = %LocationLabel

func _ready() -> void:
    custom_minimum_size = Vector2(120, 60)
    _update_location_label()


## Custom drawing: draw a colored background with rounded corners
func _draw() -> void:
    # Draw background
    draw_rect(Rect2(Vector2.ZERO, size), background_color, true)

    # Draw border (thicker and brighter if selected)
    var border_color: Color = Color(1.0, 0.9, 0.6, 1.0) if selected else Color(0.6, 0.6, 0.5, 1.0)
    var border_width: float = 3.0 if selected else 1.5
    draw_rect(Rect2(Vector2.ZERO, size), border_color, false, border_width)


## Called when the graph element is set or updated
## This is called both when creating new nodes and when loading from file
func _update_ui_from_data() -> void:
    _update_location_label()


## Update the label to show the location name
func _update_location_label() -> void:
    var location_node: LocationNode = graph_element as LocationNode
    if location_label and location_node:
        location_label.text = location_node.location_name


func _setup_inspector(inspector: CGEInspectorPanel) -> void:
    var location_node: LocationNode = graph_element as LocationNode

    # Basic string property
    inspector.add_property(
        "Location name",
        func(): return location_node.location_name,
        func(value: String) -> bool:
            if value.length() == 0:
                return false
            location_node.location_name = value
            _update_location_label()
            return true
    )

    # Enum property - demonstrates add_enum_property()
    # Inspector shows strings, but we store as enum internally
    var type_names: Array = LocationNode.Type.keys()
    inspector.add_enum_property(
        "Location type",
        type_names,
        func(): return type_names[location_node.location_type],
        func(value: String) -> bool:
            var index: int = type_names.find(value)
            if index != -1:
                location_node.location_type = index as LocationNode.Type
            return true
    )

    # Range property (int) - demonstrates add_range_property()
    inspector.add_range_property(
        "Danger level",
        0.0,  # min
        10.0,  # max
        1.0,  # step
        func(): return location_node.danger_level,
        func(value: int) -> bool:
            location_node.danger_level = value
            return true,
        true  # is_int
    )

    # Flags property - demonstrates add_flags_property()
    inspector.add_flags_property(
        "Features",
        ["Has Shop", "Has Inn", "Has Quest", "Has Blacksmith"],
        func(): return location_node.features,
        func(value: int) -> bool:
            location_node.features = value
            return true
    )
