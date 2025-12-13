class_name CGERemoveSelectionCommand
extends CGECommand
## Command to remove the current selection in the graph editor.
##
## This command removes the currently selected nodes and links in the graph editor. It acts as a
## composite command that uses CGERemoveNodesCommand and CGERemoveLinksCommand to perform the actual
## removal of nodes and links.

## IDs of nodes to remove
var _nodes_id: Array[int] = []
## IDs of links to remove
var _links_id: Array[int] = []
## Subcommands executed
var _subcommands: Array[CGECommand] = []


func _init(graph_ed: CGEGraphEditor, nodes_id: Array[int], links_id: Array[int]) -> void:
    super(graph_ed)
    
    # Add delete links first ! Less potential problems :o)
    if links_id.size() > 0:
        _subcommands.push_back(CGERemoveLinksCommand.new(graph_ed, links_id))
    
    if nodes_id.size() > 0:
        _subcommands.push_back(CGERemoveNodesCommand.new(graph_ed, nodes_id))


## Execute all Remove subcommands
func execute() -> bool:
    for cmd in _subcommands:
        cmd.execute()
    return true


## Undo all Remove subcommands in reverse order
func undo() -> void:
    for i in range(_subcommands.size()-1, -1, -1):
        _subcommands[i].undo()