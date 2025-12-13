@tool
extends EditorPlugin


func _enter_tree():
    pass


func _exit_tree():
    pass


func _get_plugin_name():
    return "CustomGraphEditor"


func _get_plugin_icon():
    return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")