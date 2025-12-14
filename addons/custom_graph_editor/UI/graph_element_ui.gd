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
## Override [method _on_graph_element_updated] instead to add custom UI update logic.
func set_graph_element(elem: CGEGraphElement) -> void:
    graph_element = elem
    _on_graph_element_updated()


## Called when the graph element data has been set or updated.
## Override this method in subclasses to update UI elements (labels, colors, etc) based on the graph element's data.
## This is called both when the element is initially set and after deserialization.
func _on_graph_element_updated() -> void:
    pass  # Override in subclasses


## Get the ID of the graph element this UI represents. This is a shortcut for [code]graph_element.id[/code].
## It is recommended to use this method in case the way IDs are handled changes in the future.
func get_id() -> int:
    return graph_element.id if graph_element != null else null


## Serialize the graph element UI into a Dictionary. See also [method CGEGraphElement.serialize].
func serialize() -> Dictionary:
    var data: Dictionary = graph_element.serialize()

    data["position"] = var_to_str(position)

    return data


## Deserialize only present fields but no error if a field is not present, allowing to "paste" only part of information into an element.
## See also [method CGEGraphElement.deserialize].
func deserialize(data: Dictionary) -> void:
    graph_element.deserialize(data)
    if data.has("position"):
        position = str_to_var(data["position"]) # TODO: maybe do not str_to_var here, potentially unsafe...

    # Update UI to reflect the deserialized data
    _on_graph_element_updated()
