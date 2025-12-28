@tool
class_name CGEGraphElementUI
extends Control
## Graph Element for the GraphEditor(GE)
##
## Input is handled by the graph editor, so graph elements do not handle mouse input
## Classes inherinting CGEGraphElement will need to override _draw() method

## Reference to the graph element this UI represents. See [CGEGraphElement]
var graph_element: CGEGraphElement = null : set = set_graph_element
## Whether this element is selected in the graph editor or not. Allows to change visual aspect when selected if needed.[br]
## See [method set_selected] and [method is_selected].
var selected: bool = false


func _init():
    # Input is handled by the graph editor
    focus_mode = Control.FOCUS_NONE
    mouse_filter = Control.MOUSE_FILTER_PASS


## Set whether this element is selected or not.
func set_selected(value:bool) -> void:
    if selected != value:
        selected = value
        queue_redraw()


## Return whether this element is selected or not. See [member selected].
func is_selected() -> bool:
    return selected


## Set the graph element this UI represents.
## This is the property setter for [member graph_element].
## Override [method _update_ui_from_data] to define how the UI updates when logic data changes.
func set_graph_element(elem: CGEGraphElement) -> void:
    graph_element = elem
    _update_ui_from_data()


## Called when the graph element data has been set or updated.
## Override this method in subclasses to update UI elements (labels, colors, etc) based on the graph element's data.
## This is called both when the element is initially set and after deserialization.
func _update_ui_from_data() -> void:
    pass  # Override in subclasses


## Get the ID of the graph element this UI represents. This is a shortcut for [code]graph_element.id[/code].
## It is recommended to use this method in case the way IDs are handled changes in the future.
func get_id() -> int:
    return graph_element.id if graph_element != null else null


## Serialize the graph element UI into a Dictionary. See also [method CGEGraphElement.serialize].
func serialize() -> Dictionary:
    var data: Dictionary = graph_element.serialize()

    data["position"] = {"x": position.x, "y": position.y}

    return data


## Deserialize only present fields but no error if a field is not present, allowing to "paste" only part of information into an element.
## See also [method CGEGraphElement.deserialize].
func deserialize(data: Dictionary) -> void:
    graph_element.deserialize(data)
    if data.has("position"):
        var pos = data["position"] 
        position = Vector2(float(pos["x"]), float(pos["y"]))


    # Update UI to reflect the deserialized data
    _update_ui_from_data()


## To be overriden
## Allow adding properties to the inspector to see and edit.
func _setup_inspector(inspector: CGEInspectorPanel) -> void:
    pass