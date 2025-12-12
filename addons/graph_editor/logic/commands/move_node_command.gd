class_name CGEMoveNodeCommand
extends CGECommand
## Command to move a node to a new position.
##
## This command moves a specified node to a new position in the custom graph editor.

## Reference to the node to move
var _node_ref: CGEGraphNodeUI = null
## Old position
var _old_position: Vector2 = Vector2.ZERO
## New position
var _new_position: Vector2 = Vector2.ZERO


func _init(graph_ed: CGEGraphEditor, node_ref: CGEGraphNodeUI, pos: Vector2) -> void:
    super(graph_ed)
    _node_ref = node_ref

    if node_ref == null:
        push_error("Trying to create a CGEMoveNodeCommand with a null node ref, forbidden")
        return

    _old_position = node_ref.position
    _new_position = pos


## Move the node to the new position
func execute() -> bool:
    _cache_selection()
    _node_ref.position = _new_position
    return true

## Move the node back to the old position
func undo() -> void:
    _node_ref.position = _old_position
    _restore_selection()