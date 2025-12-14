@tool
class_name CGEGraphNodeUI
extends CGEGraphElementUI
## UI representation of a graph node in the custom graph editor.
##
## This class handles the visual representation and interaction of a graph node within the graph editor.

## Emitted when the node is moved. Useful for linked elements to update their position.
signal moved


func _init():
    focus_mode = Control.FOCUS_NONE
    mouse_filter = Control.MOUSE_FILTER_PASS


## Override this to change the way the node is drawn when selected or not. By default, draws a border when selected.
func _draw():
    if selected:
        # draw a rectangle around the node
        var border_width = 2
        draw_rect(Rect2(Vector2.ZERO - Vector2(border_width, border_width), size + Vector2(border_width * 2, border_width * 2)), Color(0.6, 0.6, 0.6, 1), false, border_width)

    # Do nothing special if not selected.


## Serialize the node UI state to a dictionary. See [method CGEGraphElement.serialize].
func serialize() -> Dictionary:
    var data: Dictionary = super()
    return data


## Set the minimum size of the node UI.
func _get_minimum_size():
    return Vector2(50, 50)


## Get the center position of the node UI in local space.
func get_center() -> Vector2:
    return position + size/2
