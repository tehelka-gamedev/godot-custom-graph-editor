@tool
class_name LocationNodeUI
extends CGEGraphNodeUI
## Visual representation of a location node in the world map graph.
##
## This demonstrates customizing the node appearance for location nodes.

## Icon textures for each location type
const TYPE_ICONS: Dictionary = {
    LocationNode.Type.TOWN: preload("res://addons/custom_graph_editor/examples/location_map/icons/town.svg"),
    LocationNode.Type.VILLAGE: preload("res://addons/custom_graph_editor/examples/location_map/icons/village.svg"),
    LocationNode.Type.DUNGEON: preload("res://addons/custom_graph_editor/examples/location_map/icons/dungeon.svg"),
    LocationNode.Type.FOREST: preload("res://addons/custom_graph_editor/examples/location_map/icons/forest.svg")
}

## Background color for the node (a gradient from lowest danger to highest danger)
@export var background_color: GradientTexture2D = null

## Label to display the location name
@onready var location_label: Label = %LocationLabel
@onready var type_icon: TextureRect = %TypeIcon

func _ready() -> void:
    custom_minimum_size = Vector2(120, 60)
    _update_location_label()


## Custom drawing: draw a colored background with rounded corners
func _draw() -> void:
    var drawing_color: Color = Color.RED

    if background_color != null and background_color.gradient != null:
        var location_node: LocationNode = graph_element as LocationNode
        # No graph element during _ready, so we need to check
        if location_node:
            var danger_level: int = location_node.danger_level
            # Normalize danger level (0-10) to 0.0-1.0 for gradient sampling
            var normalized_danger: float = float(danger_level) / float(LocationNode.DANGER_LEVEL_MAX)
            drawing_color = background_color.gradient.sample(normalized_danger)

    # Draw background
    draw_rect(Rect2(Vector2.ZERO, size), drawing_color, true)

    # Draw border (thicker and brighter if selected)
    var border_color: Color = Color(1.0, 0.9, 0.6, 1.0) if selected else Color(0.6, 0.6, 0.5, 1.0)
    var border_width: float = 3.0 if selected else 1.5
    draw_rect(Rect2(Vector2.ZERO, size), border_color, false, border_width)


## Called when the graph element is set or updated
## This is called both when creating new nodes and when loading from file
func _update_ui_from_data() -> void:
    _update_location_label()
    _update_type_icon()
    queue_redraw()


## Update the label to show the location name
func _update_location_label() -> void:
    var location_node: LocationNode = graph_element as LocationNode
    if location_label and location_node:
        location_label.text = location_node.location_name


## Update the icon based on location type
func _update_type_icon() -> void:
    var location_node: LocationNode = graph_element as LocationNode
    if type_icon and location_node:
        var icon_texture: Texture2D = TYPE_ICONS.get(location_node.location_type)
        type_icon.texture = icon_texture
        type_icon.visible = (icon_texture != null)


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
                _update_type_icon()  # Update icon when type changes
            return true
    )

    # Range property (int) - demonstrates add_range_property()
    inspector.add_range_property(
        "Danger level",
        LocationNode.DANGER_LEVEL_MIN,  # min
        LocationNode.DANGER_LEVEL_MAX,  # max
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
