@tool
class_name CGEInspectorPanel
extends PanelContainer
## Inspector panel control.
##
## This class implements an inspector panel with editable properties.


signal execute_command_requested(cmd: CGEInspectorCommand)

## Scene used to display a property
@export var property_row_scene: PackedScene = preload("res://addons/custom_graph_editor/UI/inspector/property_row.tscn")

# Reference to currently inspected UI element
var _current_selection: Array[CGEGraphElementUI] = []

# Mapping "property_name" -> CGEPropertyRow
var _property_rows: Dictionary[String, CGEPropertyRow] = {}

@onready var _properties_container: VBoxContainer = %PropertiesVBoxContainer
@onready var _placeholder_label: Label = %PlaceholderLabel


func _ready() -> void:
    _refresh_visibility()


## Add a property to the inspector panel. If no setter is given, the field will be read-only.
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


## Add an enum property. If no setter is given, the field will be a string read-only property.
func add_enum_property(property_name: String, enum_values: Array, getter: Callable, setter: Callable = Callable()) -> void:
    if not setter.is_valid():
        # Read-only: just use regular property (will display as string)
        add_property(property_name, getter)
        return

    var current_value: Variant = getter.call()
    var prop_row: CGEPropertyRow = property_row_scene.instantiate()

    _properties_container.add_child(prop_row)
    prop_row.setup_enum(property_name, current_value, enum_values)

    _property_rows[property_name] = prop_row
    prop_row.value_changed.connect(_on_property_value_changed.bind(property_name, getter, setter))


## Add a range property. If no setter is given, the field will be a int/float read-only property.
func add_range_property(property_name: String, min_value: float, max_value: float, step: float, getter: Callable, setter: Callable = Callable(), is_int: bool = false) -> void:
    if not setter.is_valid():
        # Read-only: just use regular property (will display as int/float)
        add_property(property_name, getter)
        return

    var current_value: float = getter.call()
    var prop_row: CGEPropertyRow = property_row_scene.instantiate()

    _properties_container.add_child(prop_row)
    prop_row.setup_range(property_name, current_value, min_value, max_value, step, is_int)

    _property_rows[property_name] = prop_row
    prop_row.value_changed.connect(_on_property_value_changed.bind(property_name, getter, setter))


## Add a flag property (multiple checkboxes). If no setter is given, the flags will be read-only.
func add_flags_property(property_name: String, flag_names: Array[String], getter: Callable, setter: Callable = Callable()) -> void:
    var current_value: int = getter.call()
    var prop_row: CGEPropertyRow = property_row_scene.instantiate()
    var is_read_only: bool = not setter.is_valid()

    _properties_container.add_child(prop_row)
    prop_row.setup_flags(property_name, current_value, flag_names, is_read_only)

    _property_rows[property_name] = prop_row

    if not is_read_only:
        prop_row.value_changed.connect(_on_property_value_changed.bind(property_name, getter, setter))


## Remove all properties from the inspector
func clear() -> void:
    _clear_properties()
    _current_selection.clear()


## Refresh a given property displayed to a new value, only of the element id match (called mainly during undo/redo)
func refresh_property(element_id: int, prop_name: String, value: Variant) -> void:
    if len(_current_selection) == 0:
        return
        
    # no handling of multiple selection yet
    if len(_current_selection) > 1:
        return
    

    var current_element: CGEGraphElementUI = _current_selection[0]
    if current_element.get_id() != element_id:
        return
    
    var prop: CGEPropertyRow = _property_rows.get(prop_name)

    if prop == null:
        push_error("Tried to refresh a property '%s' but it is not created, something is wrong!", prop_name)
        return
    
    prop.set_value(value)


# Called when an element is selected, update the properties to show and whether the inspector must be shown or not
func _on_selection_changed(new_selection: Array[CGEGraphElementUI]) -> void:
    _clear_properties()

    _current_selection = new_selection

    # no multiple selection yet
    if len(_current_selection) == 1:
        _current_selection[0]._setup_inspector(self)
    
    _refresh_visibility()


# Remove all properties from the inspector
func _clear_properties() -> void:
    for c in _properties_container.get_children():
        c.queue_free()
    _property_rows.clear()
    _refresh_visibility()


# Called when the value of a property is changed, notify via a signal it happened to request to actually update the data
func _on_property_value_changed(new_value: Variant, property_name: String, getter: Callable, setter: Callable) -> void:
    if len(_current_selection) == 0:
        return
        
    # no handling of multiple selection yet
    if len(_current_selection) > 1:
        return
    
    var old_value: Variant = getter.call()

    if old_value == new_value:
        return
        
    var command: CGESetPropertyCommand = CGESetPropertyCommand.new(
        null, # set by editor
        self,
        _current_selection[0].get_id(),
        property_name,
        setter,
        old_value,
        new_value
    )

    execute_command_requested.emit(command)


# Refresh the inspector visibility depending on if there are properties to show or not
func _refresh_visibility() -> void:
    if len(_current_selection) == 0:
        visible = false
        return

    var has_single_selection: bool = len(_current_selection) == 1

    if _property_rows.is_empty() and has_single_selection:
        visible = false
        return


    # Show placeholder when no single selection or no properties
    _placeholder_label.visible = not has_single_selection
    _properties_container.visible = has_single_selection

    visible = true