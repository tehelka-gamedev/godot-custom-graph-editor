@tool
class_name InteractiveNodeUI
extends CGEGraphNodeUI
## Node UI with hover/selected visual states, used by the interactive_viewer example.

const NORMAL_BORDER_COLOR := Color(0.55, 0.55, 0.6)
const HOVER_BORDER_COLOR := Color(0.4, 0.75, 1.0)
const SELECTED_BORDER_COLOR := Color(1.0, 0.85, 0.3)
const BACKGROUND_COLOR := Color(0.16, 0.16, 0.2)

var hovered: bool = false

var display_name: String = "":
    set(value):
        display_name = value
        if _label:
            _label.text = value

var info_text: String = ""

@onready var _label: Label = %Label


func _ready() -> void:
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    _label.text = display_name


func _on_mouse_entered() -> void:
    hovered = true
    queue_redraw()


func _on_mouse_exited() -> void:
    hovered = false
    queue_redraw()


func _draw() -> void:
    var border_color: Color = NORMAL_BORDER_COLOR
    var border_width: float = 2.0

    if hovered:
        border_color = HOVER_BORDER_COLOR
        border_width = 3.0

    if selected:
        border_color = SELECTED_BORDER_COLOR
        border_width = 4.0

    draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR, true)
    draw_rect(Rect2(Vector2.ZERO, size), border_color, false, border_width)
