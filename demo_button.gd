class_name DemoButton
extends PanelContainer
## A button to launch a demo
##
## A button to launch a demo

signal launch_requested(demo_scene: PackedScene)

@export var demo_scene: PackedScene

@export var title: String = "":
    set(value):
        title = value
        if _title_label:
            _title_label.text = value

@export_multiline var description: String = "":
    set(value):
        description = value
        if _description_label:
            _description_label.text = value

@onready var _click_button: Button = %ClickButton
@onready var _title_label: Label = %Title
@onready var _description_label: Label = %Description


func _ready() -> void:
    _title_label.text = title
    _description_label.text = description
    _click_button.pressed.connect(func(): launch_requested.emit(demo_scene))
