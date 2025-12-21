@tool
class_name CGEInspectorPanel
extends PanelContainer

signal execute_command_requested(cmd: CGEInspectorCommand)

@export var  property_row_scene: PackedScene = preload("res://addons/custom_graph_editor/UI/inspector/property_row.tscn")


# Reference to currently inspected UI element
var _current_element: CGEGraphElementUI = null

# Mapping "property_name" -> CGEPropertyRow
var _property_rows: Dictionary[String, CGEPropertyRow] = {}

@onready var _properties_container: VBoxContainer = %PropertiesVBoxContainer

func _ready() -> void:
    _refresh_visibility()


func add_property(property_name: String, getter: Callable, setter: Callable = Callable()):
    # Try the getter to get the type of value
    var current_value = getter.call()
    var value_type: int = typeof(current_value)

    var prop_row: CGEPropertyRow = property_row_scene.instantiate()

    var is_read_only: bool = not setter.is_valid()

    _properties_container.add_child(prop_row)
    prop_row.setup(property_name, current_value, value_type, is_read_only)

    _property_rows[property_name] = prop_row

    if not is_read_only:
        prop_row.value_changed.connect(_on_property_value_changed.bind(property_name, getter, setter))


func _on_element_selected(element_ui: CGEGraphElementUI) -> void:
    _clear_properties()
    _current_element = element_ui

    if _current_element != null:
        _current_element._setup_inspector(self)
    
    _refresh_visibility()


func _clear_properties() -> void:
    for c in _properties_container.get_children():
        c.queue_free()
    _property_rows.clear()
    _refresh_visibility()


func clear() -> void:
    _clear_properties()
    _current_element = null


func _on_property_value_changed(new_value: Variant, property_name: String, getter: Callable, setter: Callable) -> void:
    if _current_element == null:
        return
    
    var old_value: Variant = getter.call()

    if old_value == new_value:
        return
        
    var command: CGESetPropertyCommand = CGESetPropertyCommand.new(
        null, # set by editor
        self,
        _current_element.get_id(),
        property_name,
        setter,
        old_value,
        new_value
    )

    execute_command_requested.emit(command)


## TODO
func refresh_property(element_id: int, prop_name: String, value: Variant) -> void:
    if _current_element == null:
        return
    
    if _current_element.get_id() != element_id:
        return
    
    var prop: CGEPropertyRow = _property_rows.get(prop_name)

    if prop == null:
        push_error("Tried to refresh a property '%s' but it is not created, something is wrong!", prop_name)
        return
    
    prop.set_value(value)


# Refresh the inspector visibility depending on if there are properties to show or not
func _refresh_visibility() -> void:
    if _current_element == null:
        visible = false
        return
    
    if _property_rows.is_empty():
        visible = false
        return

    visible = true