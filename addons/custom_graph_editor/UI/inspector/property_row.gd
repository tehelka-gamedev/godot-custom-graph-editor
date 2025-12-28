@tool
class_name CGEPropertyRow
extends HBoxContainer
## A row in an inspector panel.
##
## Represents a property row in the [CGEInspector] panel. It can have various forms (textbox, spinbox, checkbox, ...) depending on the property type.


signal value_changed(new_value: Variant)

@onready var _label: Label = %Label
var _control: Control = null
var _set_value_method: Callable = Callable()
var _read_only: bool = false


## Setup the row by creating a control of the appropriate type
func setup(display_name: String, value: Variant, value_type: int, read_only: bool) -> void:
    _setup_common(display_name, read_only)

    _control = _create_control_for_type(value_type, value)

    if _control == null:
        return
    
    _control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(_control)


func set_value(value: Variant) -> void:
    if not _set_value_method.is_valid():
        push_error("No set value method set !")
        return
    
    if _read_only:
        push_error("Tried to set_value but read_only, should not happen!")
        return
    
    _set_value_method.call(value)
    

## Special setup for enum values.
func setup_enum(display_name: String, current_value: Variant, enum_values: Array) -> void:
    const read_only: bool = false   # enums cannot be readonly, they are displayed as string instead is the user did not set a setter
    _setup_common(display_name, read_only)

    var option_button: OptionButton = OptionButton.new()
    option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    # Fill in enum values
    for i in range(enum_values.size()):
        option_button.add_item(str(enum_values[i]), i)

    # Set the current selection
    var current_index: int = enum_values.find(current_value)
    if current_index != -1:
        option_button.selected = current_index

    # Connect signal
    option_button.item_selected.connect(func(index: int): value_changed.emit(enum_values[index]))

    _set_value_method = func(value):
        var index: int = enum_values.find(value)
        if index != -1:
            option_button.selected = index

    _control = option_button
    add_child(_control)


## Special setup for range values, composed of a slider + a spinbox to set a value
func setup_range(display_name: String, current_value: float, min_value: float, max_value: float, step: float, is_int: bool) -> void:
    const  read_only: bool = false # range cannot be readonly, it is just a normal property int/float, if the user did not set a setter
    _setup_common(display_name, read_only)

    var container: HBoxContainer = HBoxContainer.new()
    container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    container.add_theme_constant_override("separation", 4)

    # Create slider
    var slider: HSlider = HSlider.new()
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.min_value = min_value
    slider.max_value = max_value
    slider.step = step
    slider.value = current_value
    slider.custom_minimum_size.x = 100

    # Create spinbox
    var spin: SpinBox = SpinBox.new()
    spin.custom_minimum_size.x = 60
    spin.value = current_value
    spin.min_value = min_value
    spin.max_value = max_value
    spin.step = step
    spin.rounded = is_int
    spin.allow_greater = false
    spin.allow_lesser = false

    # Synchronize slider and spinbox
    slider.value_changed.connect(func(new_value: float):
        spin.value = new_value
        if is_int:
            value_changed.emit(int(new_value))
        else:
            value_changed.emit(new_value)
    )

    spin.value_changed.connect(func(new_value: float):
        slider.value = new_value
        if is_int:
            value_changed.emit(int(new_value))
        else:
            value_changed.emit(new_value)
    )

    _set_value_method = func(value):
        slider.value = value
        spin.value = value

    container.add_child(slider)
    container.add_child(spin)

    _control = container
    add_child(_control)


## Special setup for flags values.
func setup_flags(display_name: String, current_value: int, flag_names: Array[String], read_only: bool) -> void:
    _setup_common(display_name, read_only)

    var container: VBoxContainer = VBoxContainer.new()
    container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var checkboxes: Array[CheckBox] = []

    for i in range(flag_names.size()):
        var checkbox: CheckBox = CheckBox.new()
        checkbox.text = flag_names[i]
        checkbox.button_pressed = bool(current_value & (1 << i))

        if not read_only:
            checkbox.toggled.connect(func(_pressed: bool):
                var new_value: int = 0
                for j in range(checkboxes.size()):
                    if checkboxes[j].button_pressed:
                        new_value |= (1 << j)
                value_changed.emit(new_value)
            )

        if read_only:
            checkbox.disabled = true

        container.add_child(checkbox)
        checkboxes.append(checkbox)

    _set_value_method = func(value: int):
        for j in range(checkboxes.size()):
            checkboxes[j].button_pressed = bool(value & (1 << j))

    _control = container
    add_child(_control)



func _setup_common(display_name: String, read_only: bool) -> void:
    _label.text = display_name
    _read_only = read_only

    if _control:
        _control.queue_free()


func _create_control_for_type(value_type: int, default_value: Variant) -> Control:
    match value_type:
        TYPE_STRING:
            var control: CustomLineEdit = CustomLineEdit.new()
            control.set_text_no_signal(default_value)
            control.text_updated.connect(func(new_text: String): value_changed.emit(new_text))
            _set_value_method = func(value): control.set_text_no_signal(value)

            if _read_only:
                control.editable = false

            return control
        TYPE_INT:
            var control: SpinBox = _create_spin_box("", default_value, true)
            control.value_changed.connect(func(new_value: float): value_changed.emit(int(new_value)))
            _set_value_method = func(value): control.value = value
            return control
        TYPE_FLOAT:
            var control: SpinBox = _create_spin_box("", default_value)
            control.value_changed.connect(func(new_value: float): value_changed.emit(new_value))
            _set_value_method = func(value): control.value = value
            return control
        TYPE_BOOL:
            var control: CheckBox = CheckBox.new()
            control.button_pressed = default_value
            control.toggled.connect(func(pressed: bool): value_changed.emit(pressed))
            _set_value_method = func(value): control.button_pressed = value

            if _read_only:
                control.disabled = true

            return control
        TYPE_COLOR:
            var control: ColorPickerButton = ColorPickerButton.new()
            control.color = default_value
            control.edit_alpha = true
            control.color_changed.connect(func(new_color: Color): value_changed.emit(new_color))
            _set_value_method = func(value): control.color = value

            if _read_only:
                control.disabled = true

            return control
        TYPE_VECTOR2:
            var container: HBoxContainer = HBoxContainer.new()
            container.add_theme_constant_override("separation", 4)

            var x_spin: SpinBox = _create_spin_box("X:", default_value.x)
            var y_spin: SpinBox = _create_spin_box("Y:", default_value.y)

            container.add_child(x_spin)
            container.add_child(y_spin)

            var emit_vector2 := func(_value: float):
                value_changed.emit(Vector2(x_spin.value, y_spin.value))

            x_spin.value_changed.connect(emit_vector2)
            y_spin.value_changed.connect(emit_vector2)

            _set_value_method = func(value):
                x_spin.value = value.x
                y_spin.value = value.y

            return container
        TYPE_VECTOR3:
            var container: HBoxContainer = HBoxContainer.new()
            container.add_theme_constant_override("separation", 4)

            var x_spin: SpinBox = _create_spin_box("X:", default_value.x)
            var y_spin: SpinBox = _create_spin_box("Y:", default_value.y)
            var z_spin: SpinBox = _create_spin_box("Z:", default_value.z)

            container.add_child(x_spin)
            container.add_child(y_spin)
            container.add_child(z_spin)

            var emit_vector3 := func(_value: float):
                value_changed.emit(Vector3(x_spin.value, y_spin.value, z_spin.value))

            x_spin.value_changed.connect(emit_vector3)
            y_spin.value_changed.connect(emit_vector3)
            z_spin.value_changed.connect(emit_vector3)

            _set_value_method = func(value):
                x_spin.value = value.x
                y_spin.value = value.y
                z_spin.value = value.z

            return container
        _:
            push_error("CGEPropetyRow: unsupported type %d" % [value_type])
            return null


func _create_spin_box(prefix: String, initial_value: float, rounded: bool = false) -> SpinBox:
    var spin: SpinBox = SpinBox.new()
    spin.prefix = prefix
    spin.value = initial_value
    spin.step = 1.0 if rounded else 0.01
    spin.rounded = rounded
    spin.min_value = -999999.0
    spin.max_value = 999999.0
    spin.allow_greater = true
    spin.allow_lesser = true
    spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    if _read_only:
        spin.editable = false

    return spin
