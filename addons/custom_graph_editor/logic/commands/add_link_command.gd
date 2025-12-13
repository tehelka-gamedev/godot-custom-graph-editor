class_name CGEAddLinkCommand
extends CGECommand
## Command to add a link between two nodes in the custom graph editor.
##
## This command creates a link between two specified nodes in the graph editor. 
    
## ID of the start node
var _start_node_id: int
## ID of the end node
var _end_node_id: int
## ID of the created link to track for undo
var _link_id: int = -1


func _init(graph_ed: CGEGraphEditor, start_node_id: int, end_node_id: int) -> void:
    super(graph_ed)
    _start_node_id = start_node_id
    _end_node_id = end_node_id

## Execute the command to add the link
func execute() -> bool:
    var new_link: CGEGraphLink = _graph.create_link(_start_node_id, _end_node_id, _link_id)
    if new_link == null:
        return false

    _link_id = new_link.id  # Store the created link ID for undo
    return true

## Undo the command by removing the created link
func undo() -> void:
    var link: CGEGraphLink = _graph.get_link(_link_id)
    if link != null:
        _graph.remove_link(link)
