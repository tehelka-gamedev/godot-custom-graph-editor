@tool
class_name CGEInspectorPanel
extends PanelContainer
## Inspector panel control.
##
## This class implements an inspector panel with editable properties.


signal execute_command_requested(cmd: CGECommand)

## Scene used to display a property
@export var property_row_scene: PackedScene = preload("res://addons/custom_graph_editor/UI/inspector/property_row.tscn")

# Reference to currently inspected UI element
var _current_selection: Array[CGEGraphElementUI] = []

# Mapping "property_name" -> CGEPropertyRow
var _property_rows: Dictionary[String, CGEPropertyRow] = {}

# Specs of properties to create the correct rows
var _property_specs: Dictionary[String, PropertySpec] = {}

# Ids of custom controls added by the user (action buttons for instance)
# key (id) ->  bool (unused value) to act like a set
var _custom_controls_id: Dictionary[String, bool] = {}


@onready var _properties_container: VBoxContainer = %PropertiesVBoxContainer
@onready var _placeholder_label: Label = %PlaceholderLabel


func _ready() -> void:
    _refresh_visibility()


## Add a property to the inspector panel. If no setter is given, the field will be read-only.
## Build the row if first occurence of this property, otherwise just records setters and getters to update the property of selected nodes when needed.
func add_property(property_name: String, getter: Callable, setter: Callable = Callable()):
    var spec: PropertySpec = _property_specs.get(property_name)
    if spec != null:
        # Spec already found (multi-selection)
        spec.add_element(getter, setter)
        return
    
    spec = PropertySpec.new(property_name, getter, setter)
    _property_specs[property_name] = spec

    # -- First call to this property, build the row

    # Try the getter to get the type of value
    var current_value = getter.call()
    var value_type: int = typeof(current_value)

    var prop_row: CGEPropertyRow = property_row_scene.instantiate()

    var is_read_only: bool = spec.read_only

    _properties_container.add_child(prop_row)
    prop_row.setup(property_name, current_value, value_type, is_read_only)

    _property_rows[property_name] = prop_row

    if not is_read_only:
        prop_row.value_changed.connect(_on_property_value_changed.bind(property_name))


## Add an enum property. If no setter is given, the field will be a string read-only property.
func add_enum_property(property_name: String, enum_values: Array, getter: Callable, setter: Callable = Callable()) -> void:
    if not setter.is_valid():
        # Read-only: just use regular property (will display as string)
        add_property(property_name, getter)
        return

    var spec: PropertySpec = _property_specs.get(property_name)
    if spec != null:
        # Spec already found (multi-selection)
        spec.add_element(getter, setter)
        return
    
    spec = PropertySpec.new(property_name, getter, setter)
    _property_specs[property_name] = spec

    # -- First call to this property, build the row

    var current_value: Variant = getter.call()
    var prop_row: CGEPropertyRow = property_row_scene.instantiate()

    _properties_container.add_child(prop_row)
    prop_row.setup_enum(property_name, current_value, enum_values)

    _property_rows[property_name] = prop_row
    prop_row.value_changed.connect(_on_property_value_changed.bind(property_name))


## Add a range property. If no setter is given, the field will be a int/float read-only property.
func add_range_property(property_name: String, min_value: float, max_value: float, step: float, getter: Callable, setter: Callable = Callable(), is_int: bool = false) -> void:
    if not setter.is_valid():
        # Read-only: just use regular property (will display as int/float)
        add_property(property_name, getter)
        return

    var spec: PropertySpec = _property_specs.get(property_name)
    if spec != null:
        # Spec already found (multi-selection)
        spec.add_element(getter, setter)
        return
    
    spec = PropertySpec.new(property_name, getter, setter)
    _property_specs[property_name] = spec

    # -- First call to this property, build the row

    var current_value: float = getter.call()
    var prop_row: CGEPropertyRow = property_row_scene.instantiate()

    _properties_container.add_child(prop_row)
    prop_row.setup_range(property_name, current_value, min_value, max_value, step, is_int)

    _property_rows[property_name] = prop_row
    prop_row.value_changed.connect(_on_property_value_changed.bind(property_name))


## Add a flag property (multiple checkboxes). If no setter is given, the flags will be read-only.
func add_flags_property(property_name: String, flag_names: Array[String], getter: Callable, setter: Callable = Callable()) -> void:
    var spec: PropertySpec = _property_specs.get(property_name)
    if spec != null:
        # Spec already found (multi-selection)
        spec.add_element(getter, setter)
        return
    
    spec = PropertySpec.new(property_name, getter, setter)
    _property_specs[property_name] = spec

    # -- First call to this property, build the row

    var current_value: int = getter.call()
    var prop_row: CGEPropertyRow = property_row_scene.instantiate()
    var is_read_only: bool = not setter.is_valid()

    _properties_container.add_child(prop_row)
    prop_row.setup_flags(property_name, current_value, flag_names, is_read_only)

    _property_rows[property_name] = prop_row

    if not is_read_only:
        prop_row.value_changed.connect(_on_property_value_changed.bind(property_name))


## Add a custom control to the inspector.
## id is a unique id to reference the control, and label is an optional text label that will be displayed alongside (on the left) of the control node.
## Note: the control is destroyed when the inspector is closed, so it should be rebuilt everytime when calling this method.
func add_custom_control(id: String, control: Control, label: String = "") -> void:
    if _custom_controls_id.has(id):
        # can happen with multi selection, so we just queue_free excess elements created
        # this pattern should be changed I guess, but it's ok for now...
        control.queue_free()
        return
    _custom_controls_id[id] = true

    var row: Control = null
    if label.is_empty():
        row = control
    else:
        row = HBoxContainer.new()
        var l: Label = Label.new()
        l.text = label
        control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(l)
        row.add_child(control)
    _properties_container.add_child(row)


## Helper to add an action button to the inspector
## [br] on_pressed is a Callable that takes the current selection: Array[CGEGraphElementUI] as input
## [br] Note: The selection is a snapshot of when the inspector opened so beware of iterating over it if you keep the reference in another window for instance.
## [br]
## options is an optional dict with more settings
## - "label": String, "tooltip": String, "disabled": bool
## If you have a lot of settings to define, maybe it's better to use [add_custom_control]
func add_action_button(id: String, text: String, on_pressed: Callable, options: Dictionary = {}) -> void:
    if _custom_controls_id.has(id):
        return # skip if already built
    
    var button: Button = Button.new()
    button.text = text
    if options.has("tooltip"):
        button.tooltip_text = options["tooltip"]
    button.disabled = options.get("disabled", false)
    var selection_snapshot: Array[CGEGraphElementUI] = _current_selection.duplicate()
    button.pressed.connect(func() -> void:
        on_pressed.call(selection_snapshot)
    )
    add_custom_control(id, button, options.get("label", ""))


## Used to submit command with custom action buttons
## Maybe should be outside of inspector panel and more general graph API ?
func submit_command(cmd: CGECommand) -> void:
    execute_command_requested.emit(cmd)


## A duplicate of the elements currently being inspected.
func get_selection() -> Array[CGEGraphElementUI]:
    return _current_selection.duplicate()


## Remove all properties from the inspector
func clear() -> void:
    _clear_properties()
    _current_selection.clear()


## Refresh a given property displayed to a new value, only of the element id match (called mainly during undo/redo)
func refresh_property(element_id: int, prop_name: String, value: Variant) -> void:
    if len(_current_selection) == 0:
        return

    # Focus on the first element selected always        
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

    if len(_current_selection) > 0 and _all_same_type(_current_selection):
        for c in _current_selection:
            c._setup_inspector(self)

    
    _refresh_visibility()


# Remove all properties from the inspector
func _clear_properties() -> void:
    for c in _properties_container.get_children():
        c.queue_free()
    _property_rows.clear()
    _property_specs.clear()
    _custom_controls_id.clear()
    _refresh_visibility()


# Called when the value of a property is changed, notify via a signal it happened to request to actually update the data
func _on_property_value_changed(new_value: Variant, property_name: String) -> void:
    var spec: PropertySpec = _property_specs.get(property_name)
    if spec == null:
        push_error("Tried to get property %s but the spec was not built. It should not happen!" % [property_name])
        return
    
    var commands: Array[CGECommand] = []

    for i in range(spec.getters.size()):
        var getter: Callable = spec.getters[i]
        var setter: Callable = spec.setters[i]

        var old_value: Variant = getter.call()

        if old_value == new_value:
            continue
            
        var command: CGESetPropertyCommand = CGESetPropertyCommand.new(
            null, # set by editor
            self,
            _current_selection[i].get_id(),
            property_name,
            setter,
            old_value,
            new_value
        )
        commands.append(command)

    if commands.is_empty():
        return

    if commands.size() == 1:
        execute_command_requested.emit(commands[0])
        return

    execute_command_requested.emit(
        CGECompositeCommand.new(null, # set by editor
        commands)
    )


# Refresh the inspector visibility depending on if there are properties to show or not
func _refresh_visibility() -> void:
    if len(_current_selection) == 0:
        visible = false
        return

    var has_same_type: bool = _all_same_type(_current_selection)

    var is_empty: bool = _property_rows.is_empty() and _custom_controls_id.is_empty()

    if is_empty and has_same_type:
        visible = false
        return


    # Show placeholder when mixed selection selection
    _placeholder_label.visible = not has_same_type
    _properties_container.visible = has_same_type

    visible = true


# Returns true if all elements in the selection are of the same type
# false otherwise
func _all_same_type(selection: Array[CGEGraphElementUI]) -> bool:
    if selection.is_empty():
        return false
    
    var first_type: Variant = selection[0].get_script()
    for element in selection:
        if element.get_script() != first_type:
            return false
    
    return true


# Spec of a property
class PropertySpec:
    var name: String
    var read_only: bool
    var getters: Array[Callable] = [] # aligned with _current_selection
    var setters: Array[Callable] = []

    func _init(property_name: String, getter: Callable, setter: Callable = Callable()) -> void:
        name = property_name
        read_only = not setter.is_valid()
        add_element(getter, setter)

    func add_element(getter: Callable, setter: Callable) -> void:
        getters.append(getter)
        setters.append(setter)

    func current_value() -> Variant:
        return getters[0].call()
