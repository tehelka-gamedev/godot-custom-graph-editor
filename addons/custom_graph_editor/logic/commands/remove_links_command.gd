class_name CGERemoveLinksCommand
extends CGECommand
## Command to remove links from the graph.
##
## This command removes specified links from the graph.

## Cached links deleted (for undo purposes)
var links_deleted: Dictionary[int, CGEGraphLink] = {}

## IDs of links to remove
var _links_id: Array[int] = []

func _init(graph_ed: CGEGraphEditor, links_id: Array[int]) -> void:
    super(graph_ed)
    _links_id = links_id

## Remove the specified links
func execute() -> bool:

    for link_id in _links_id:
        var link: CGEGraphLink = _graph.get_link(link_id)
        links_deleted[link.id] = link
        
        _graph.remove_link(link)
    
    return true


## Recreate the removed links
func undo() -> void:
    # Restore the links deleted
    for link in links_deleted.values():
        _graph.create_link(link.start_node_id, link.end_node_id, link.id)

    # Restore selection (select the restored links)
    for link_id in _links_id:
        var link_ui: CGEGraphLinkUI = _graph_editor.get_graph_link(link_id)
        if link_ui != null:
            _graph_editor.select_graph_element(link_ui)
    
