extends Control
## Demo menu scene for Custom Graph Editor examples
##
## This scene provides a simple menu to navigate between different
## graph editor examples. Press ESC in any example to return here.


var _current_editor_showed: Control = null

@onready var _demo_selector_container: Container = %DemoSelectorContainer
@onready var _demo_mode_panel: Container = %DemoModeESCPanel


func _ready() -> void:
    for demo_button in find_children("*", "DemoButton", true, false):
        (demo_button as DemoButton).launch_requested.connect(demo_editor)
    _demo_mode_panel.visible = false


# Scenes are loaded as child to be able to return with ESC and not add any code to the example scenes
func _unhandled_input(event: InputEvent) -> void:
    if _current_editor_showed == null:
        return

    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        # "return" to menu
        _current_editor_showed.queue_free()
        _demo_selector_container.visible = true
        _demo_mode_panel.visible = false


# Show
func demo_editor(scene: PackedScene) -> void:
    if _current_editor_showed != null:
        _current_editor_showed.queue_free()

    _demo_selector_container.visible = false
    _demo_mode_panel.visible = true

    var editor: Control = scene.instantiate()
    _current_editor_showed = editor
    add_child(_current_editor_showed)
    _demo_mode_panel.move_to_front()
