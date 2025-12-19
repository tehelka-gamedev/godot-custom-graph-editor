@tool
class_name CGEInspectorPanel
extends PanelContainer


@export var  property_row_scene: PackedScene = preload("res://addons/custom_graph_editor/UI/inspector/property_row.tscn")


# Reference to currently inspected UI element
var _current_element: CGEGraphElementUI = null

@onready var _properties_container: VBoxContainer = %PropertiesVBoxContainer


func add_property(property_name: String, getter: Callable, setter: Callable = Callable()):
    # Try the getter
    var current_value = getter.call()
    var value_type: int = typeof(current_value)

    var prop_row: CGEPropertyRow = property_row_scene.instantiate()

    var is_read_only: bool = not setter.is_valid()

    _properties_container.add_child(prop_row)
    prop_row.setup(property_name, current_value, value_type, is_read_only)

    if not is_read_only:
        prop_row.value_changed.connect(_on_property_value_changed.bind(property_name, getter, setter, prop_row))


func _on_element_selected(element_ui: CGEGraphElementUI) -> void:
    _clear_properties()
    _current_element = element_ui

    if _current_element == null:
        return

    _current_element._setup_inspector(self)


func _clear_properties() -> void:
    for c in _properties_container.get_children():
        c.queue_free()


func clear() -> void:
    _clear_properties()
    _current_element = null


func _on_property_value_changed(new_value: Variant, property_name: String, getter: Callable, setter: Callable, property_row: CGEPropertyRow) -> void:
    if _current_element == null:
        return
    
    var old_value: Variant = getter.call()

    if old_value == new_value:
        return
        
    # TODO use command instead
    print("Value is now %s" % [new_value])
    var accepted: bool = setter.call(new_value)

    if accepted:
        # Refresh the node visual
        _current_element._update_ui_from_data()
    else:
        print("rejected")
        property_row.set_value(old_value)
