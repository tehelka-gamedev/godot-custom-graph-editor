class_name CGETranslateSelectionCommand
extends CGECommand
## Command to translate (move) the selected nodes by an offset. 
##
## This command moves the specified nodes by a given offset in the custom graph editor.

## IDs of nodes to move
var _nodes_id: Array[int] = []
## Offset to apply to each node
var _offset: Vector2 = Vector2.ZERO


func _init(graph_ed: CGEGraphEditor, nodes_id: Array[int], offset: Vector2) -> void:
    super(graph_ed)
    _nodes_id = nodes_id
    _offset = offset


## Translate the specified nodes by the offset
func execute() -> bool:
    _cache_selection()

    for id in _nodes_id:
        var node: CGEGraphNodeUI = _graph_editor.get_graph_node(id)
        if node == null:
            push_error("Trying to move a node with id '%d' but it does not exist. Something is wrong" % [id])
            return false
        node.global_position += _offset
        # Hack for now, unsure if I want graphlink in this command
        if node is CGEGraphNodeUI:
            node.moved.emit()
    return true


## Translate the specified nodes back by the offset
func undo() -> void:
    for id in _nodes_id:
        var node: CGEGraphNodeUI = _graph_editor.get_graph_node(id)
        if node == null:
            push_error("Trying to move a node with id '%d' but it does not exist. Something is wrong" % [id])
            return
        node.global_position -= _offset
        # Hack for now, unsure if I want graphlink in this command
        if node is CGEGraphNodeUI:
            node.moved.emit()

    _restore_selection()
