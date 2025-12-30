@tool
class_name RumorNodeUI
extends CGEGraphNodeUI
## Visual representation of a rumor node in the knowledge graph.
##
## Shows "?" for undiscovered rumors, or an image when discovered.

## Category colors for visual distinction
const CATEGORY_COLORS: Dictionary = {
    RumorNode.Category.LOCATION: Color(0.4, 0.6, 0.8),    # Blue
    RumorNode.Category.CHARACTER: Color(0.8, 0.6, 0.4),   # Orange
    RumorNode.Category.MYSTERY: Color(0.7, 0.4, 0.7),     # Purple
    RumorNode.Category.ARTIFACT: Color(0.6, 0.8, 0.4),    # Green
    RumorNode.Category.EVENT: Color(0.9, 0.7, 0.3)        # Yellow
}

@onready var rumor_name_label: Label = %RumorNameLabel
@onready var image_display: TextureRect = %ImageDisplay
@onready var unknown_label: Label = %UnknownLabel
@onready var clue_count_label: Label = %ClueCountLabel


func _ready() -> void:
    custom_minimum_size = Vector2(150, 120)
    _update_display()


func _draw() -> void:
    var rumor_node: RumorNode = graph_element as RumorNode
    var bg_color: Color = Color(0.2, 0.2, 0.25) if rumor_node and rumor_node.discovered else Color(0.15, 0.15, 0.18)

    # Get category color
    var accent_color: Color = Color.GRAY
    if rumor_node:
        accent_color = CATEGORY_COLORS.get(rumor_node.category, Color.GRAY)

    # Draw background
    draw_rect(Rect2(Vector2.ZERO, size), bg_color, true)

    # Draw category-colored border
    var border_color: Color = accent_color if selected else accent_color.darkened(0.3)
    var border_width: float = 3.0 if selected else 2.0
    draw_rect(Rect2(Vector2.ZERO, size), border_color, false, border_width)


func _update_ui_from_data() -> void:
    _update_display()
    queue_redraw()


func _update_display() -> void:
    var rumor_node: RumorNode = graph_element as RumorNode
    if not rumor_node:
        return

    # Update name
    if rumor_name_label:
        rumor_name_label.text = rumor_node.rumor_name if rumor_node.discovered else "???"

    # Show/hide based on discovery state
    if unknown_label:
        unknown_label.visible = not rumor_node.discovered

    if image_display:
        image_display.visible = rumor_node.discovered
        if rumor_node.discovered and rumor_node.image_path != "":
            var texture: Texture2D = load(rumor_node.image_path) if ResourceLoader.exists(rumor_node.image_path) else null
            image_display.texture = texture

    # Update clue count
    if clue_count_label:
        if rumor_node.clues.size() > 0:
            clue_count_label.text = "%d clue%s" % [rumor_node.clues.size(), "s" if rumor_node.clues.size() > 1 else ""]
            clue_count_label.visible = true
        else:
            clue_count_label.visible = false


func _setup_inspector(inspector: CGEInspectorPanel) -> void:
    var rumor_node: RumorNode = graph_element as RumorNode

    # Rumor name
    inspector.add_property(
        "Rumor Name",
        func(): return rumor_node.rumor_name,
        func(value: String) -> bool:
            if value.length() == 0:
                return false
            rumor_node.rumor_name = value
            _update_display()
            return true
    )

    # Discovered state
    inspector.add_property(
        "Discovered",
        func(): return rumor_node.discovered,
        func(value: bool) -> bool:
            rumor_node.discovered = value
            _update_display()
            return true
    )

    # Category enum
    var category_names: Array = RumorNode.Category.keys()
    inspector.add_enum_property(
        "Category",
        category_names,
        func(): return category_names[rumor_node.category],
        func(value: String) -> bool:
            var index: int = category_names.find(value)
            if index != -1:
                rumor_node.category = index as RumorNode.Category
                queue_redraw()
            return true
    )

    # Image path
    inspector.add_property(
        "Image Path",
        func(): return rumor_node.image_path,
        func(value: String) -> bool:
            rumor_node.image_path = value
            _update_display()
            return true
    )

    # Clue count (read-only)
    inspector.add_property(
        "Clue Count",
        func(): return rumor_node.clues.size()
    )
