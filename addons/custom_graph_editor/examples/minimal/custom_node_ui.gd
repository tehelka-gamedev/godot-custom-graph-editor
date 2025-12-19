@tool
class_name MinimalCustomNodeUI
extends CGEGraphNodeUI
## Example custom node UI with simple visual customization.
##
## This demonstrates how to extend CGEGraphNodeUI to customize the appearance of your nodes.

## Label to display the node name
@onready var name_label: Label = %NameLabel

## Background color for the node
@export var background_color: Color = Color(0.2, 0.3, 0.5, 0.9)


## Called when the node is ready
func _ready() -> void:
    custom_minimum_size = Vector2(100, 60)
    _update_node_label()


## Custom drawing: draw a colored background
func _draw() -> void:
    # Draw background
    draw_rect(Rect2(Vector2.ZERO, size), background_color, true)

    # Draw border (thicker if selected)
    var border_color: Color = Color(0.8, 0.8, 0.8, 1.0) if selected else Color(0.5, 0.5, 0.5, 1.0)
    var border_width: float = 3.0 if selected else 1.5
    draw_rect(Rect2(Vector2.ZERO, size), border_color, false, border_width)


## Called when the graph element is set or updated
## This is called both when creating new nodes and when loading from file
func _update_ui_from_data() -> void:
    _update_node_label()


func _update_node_label() -> void:
    var custom_node: MinimalCustomNode = graph_element as MinimalCustomNode
    if name_label and custom_node:
        name_label.text = "%s %d" % [custom_node.node_name, graph_element.id]


