class_name CGESetPropertyCommand
extends CGEInspectorCommand
## Command to set a property value on a UI graph element
##
## This command is used by the inspector to make property changes undoable


## Changed UI element ID
var _element_id: int = -1
## Name of the property to change
var _property_name: String = ""
## Setter to change the property. It must return a bool indicating if the set was successful or not.
var _setter: Callable
## Value before executing the command
var _old_value: Variant
## Value requested to be set by this command
var _new_value: Variant


func _init(graph_ed: CGEGraphEditor, inspector: CGEInspectorPanel, elem_id: int, prop_name: String, setter: Callable, old_value: Variant, new_value: Variant) -> void:
    super(graph_ed, inspector)
    
    if not setter.is_valid():
        push_error("Tried to create a CGESetPropertyCommand '%s' with an invalid setter (%s)." % [prop_name, setter])
        return

    _element_id = elem_id
    _property_name = prop_name
    _setter = setter
    _old_value = old_value
    _new_value = new_value


## Set the new value
func execute() -> bool:
    return _apply_value(_new_value)


## Restore the old value
func undo() -> void:
    _apply_value(_old_value)


# Use the setter and refresh the UI
func _apply_value(value: Variant) -> bool:
    var accepted: bool = _setter.call(value)

    if not accepted:
        _refresh_inspector_property(_element_id, _property_name, _old_value)
        return false
    
    var element_ui: CGEGraphElementUI = _graph_editor.get_graph_element(_element_id)
    if element_ui != null:
        element_ui._update_ui_from_data()
        _refresh_inspector_property(_element_id, _property_name, value)
    else:
        push_error("Tried to set property '%s' on element with id %d but it was not found." % [_property_name, _element_id]) 

    return true


func _to_string():
    return "CGESetPropertyCommand()"