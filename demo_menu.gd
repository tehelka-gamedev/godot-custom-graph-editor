extends Control
## Demo menu scene for Custom Graph Editor examples
##
## This scene provides a simple menu to navigate between different
## graph editor examples. Press ESC in any example to return here.


var _current_editor_showed: Control = null

@onready var _demo_selector_container: Container = %DemoSelectorContainer
@onready var _minimal_example_button: Button = %MinimalButton
@onready var _location_map_example_button: Button = %LocationMapButton
@onready var _inspector_action_example_button: Button = %InspectorActionButton
@onready var _viewer_only_example_button: Button = %ViewerOnlyButton
@onready var _pretty_viewer_example_button: Button = %PrettyViewerButton
@onready var _interactive_viewer_example_button: Button = %InteractiveViewerButton
@onready var _demo_mode_panel: Container = %DemoModeESCPanel
@onready var _minimal_graph_editor_scene: PackedScene = preload("res://addons/custom_graph_editor/examples/minimal/minimal_graph_editor.tscn")
@onready var _location_map_graph_editor_scene: PackedScene = preload("res://addons/custom_graph_editor/examples/location_map/location_map_editor.tscn")
@onready var _inspector_action_graph_editor_scene: PackedScene = preload("res://addons/custom_graph_editor/examples/inspector_actions/inspector_actions_editor.tscn")
@onready var _viewer_only_demo_scene: PackedScene = preload("res://addons/custom_graph_editor/examples/viewer_only/viewer_only_demo.tscn")
@onready var _pretty_viewer_demo_scene: PackedScene = preload("res://addons/custom_graph_editor/examples/pretty_viewer/pretty_viewer_demo.tscn")
@onready var _interactive_viewer_demo_scene: PackedScene = preload("res://addons/custom_graph_editor/examples/interactive_viewer/interactive_viewer_demo.tscn")


func _ready() -> void:
    _minimal_example_button.pressed.connect(_on_minimal_button_pressed)
    _location_map_example_button.pressed.connect(_on_location_map_button_pressed)
    _inspector_action_example_button.pressed.connect(_on_inspector_action_button_pressed)
    _viewer_only_example_button.pressed.connect(_on_viewer_only_button_pressed)
    _pretty_viewer_example_button.pressed.connect(_on_pretty_viewer_button_pressed)
    _interactive_viewer_example_button.pressed.connect(_on_interactive_viewer_button_pressed)
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


func _on_minimal_button_pressed() -> void:
    demo_editor(_minimal_graph_editor_scene)


func _on_location_map_button_pressed() -> void:
    demo_editor(_location_map_graph_editor_scene)


func _on_inspector_action_button_pressed() -> void:
    demo_editor(_inspector_action_graph_editor_scene)


func _on_viewer_only_button_pressed() -> void:
    demo_editor(_viewer_only_demo_scene)


func _on_pretty_viewer_button_pressed() -> void:
    demo_editor(_pretty_viewer_demo_scene)


func _on_interactive_viewer_button_pressed() -> void:
    demo_editor(_interactive_viewer_demo_scene)


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
