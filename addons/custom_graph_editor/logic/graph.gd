class_name CGEGraph
extends RefCounted
## Represents a graph structure for the custom graph editor.
##
## This class manages nodes and links within a graph. 

## Emitted when a node is created
signal node_created(node_id: int)
## Emitted when a node is deleted
signal node_deleted(node_id: int)
## Emitted when a link is created
signal link_created(start_node_id: int, end_node_id: int, link_id: int)
## Emitted when a link is deleted
signal link_deleted(link_id: int)

## ID counter for nodes and links id.
## Not optimal way to handle IDs, but works for now...
static var NEXT_NODE_ID = 0

## Class used for nodes. Override this with your own node class if needed.
var node_class: GDScript = preload("res://addons/custom_graph_editor/logic/graph_node.gd")
## Class used for links. Override this with your own link class if needed.
var link_class: GDScript = preload("res://addons/custom_graph_editor/logic/graph_link.gd")

## Type of the graph (directed or undirected). See [constant CGEEnum.GraphType]
var graph_type: CGEEnum.GraphType = CGEEnum.GraphType.DIRECTED

# The graph data structures is with 3 dictionaries. This is not optimal at all but it was the most practical for a first implementation.
## Graph, stored as an adjacency matrix.
## Each element is an array of other CGEGraphElements that the node at given id is connected to
var _graph: Dictionary[int, Array] = {}
## Node id mapping to CGEGraphNode instances
var _nodes: Dictionary[int, CGEGraphNode] = {}
## Link id mapping to CGEGraphLink instances
var _links: Dictionary[int, CGEGraphLink] = {}


## Get a node by ID. If the node does not exist, returns null with an error.
func get_node(id: int) -> CGEGraphNode:
    if not _graph.has(id):
        push_error("Tried to get a node with id '%d' but it is not there." % [id] )
        return null

    return _nodes[id]


## Get a link by ID. If the link does not exist, returns null with an error.
func get_link(id: int) -> CGEGraphLink:
    if not _links.has(id):
        push_error("Tried to get a link with id '%d' but it is not there." % [id] )
        return null

    return _links[id]


## Returns a list of all node IDs in the graph.
func get_all_node_ids() -> Array[int]:
    return _nodes.keys()


## Create a new node in the graph. If node_id is -1 (default), a new unique ID will be generated.
## If the node_id is already taken, returns null with an error. Otherwise, returns the created CGEGraphNode.
func create_node(node_id: int = -1) -> CGEGraphNode:
    # id must be >= 0 and != -1
    if node_id < -1: 
        push_error("Tried to create a node with id '%d' but it is invalid. It should be -1 for auto chose or >= 0" % [node_id])
        return null
    
    if _graph.has(node_id):
        push_error("Tried to create node with id '%d' but this id is already taken." % [node_id] )
        return null
    
    if node_id == -1:
        node_id = _get_new_id()

    var new_node = node_class.new(node_id)

    _graph[node_id] = []
    _nodes[node_id] = new_node

    node_created.emit(node_id)

    return new_node


## Create a link between two nodes in the graph. If link_id is -1 (default), a new unique ID will be generated.
## If the link cannot be created (nodes do not exist or are already connected), returns null with an error. Otherwise, returns the created CGEGraphLink.[br]
## [b]Note:[/b] Adding a link to already connected nodes will fail for now, although it might make sense. This will probably be allowed in future versions.
func create_link(start_node_id: int, end_node_id: int, link_id: int = -1) -> CGEGraphLink:
    # id must be >= 0 and != -1
    if link_id < -1: 
        push_error("Tried to create a link with id '%d' but it is invalid. It should be -1 for auto chose or >= 0" % [link_id])
        return null

    if not _graph.has(start_node_id) or not _graph.has(end_node_id):
        push_error("Tried to connect '%s' to '%s' but one of them is not even in the graph. Something is wrong" % [start_node_id, end_node_id] )
        return null

    if are_connected(start_node_id, end_node_id):
        push_error("ALREADY CONNECTED")
        return null

    if link_id == -1:
        link_id = _get_new_id()

    var new_link = link_class.new(link_id, start_node_id, end_node_id)

    _graph[start_node_id].push_back(end_node_id)
    _links[link_id] = new_link

    if graph_type == CGEEnum.GraphType.UNDIRECTED:
        # need testing...
        _graph[end_node_id].push_back(start_node_id)
        var reversed_link_id = _get_new_id()
        var reversed_link = link_class.new(reversed_link_id, end_node_id, start_node_id)
        _links[reversed_link_id] = reversed_link

    link_created.emit(start_node_id, end_node_id, link_id)

    return new_link


## Remove an element (node or link) from the graph. Defined as an alias to remove_node or remove_link, but you might just call those directly.
func remove_element(element: CGEGraphElement) -> bool:
    if element is CGEGraphNode:
        return remove_node(element.id)
    if element is CGEGraphLink:
        return remove_link(element as CGEGraphLink)
    
    push_error("Tried to remove an CGEGraphElement '%s' that is neither a CGEGraph node nor a CGEGraphLink (got type '%s'). Something is wrong." % [element, typeof(element)] )
    return false


## Remove a node
## If the node is not in the graph, returns false, otherwise true.
func remove_node(node_id: int) -> bool:
    if not _graph.has(node_id):
        push_error("Tried to remove  node '%s' to the graph but it is not in it." % [node_id] )
        return false

    var node: CGEGraphNode = _nodes[node_id]

    # Remove all links that where linked to it
    for idx in _links.keys():
        if _links[idx].is_linked_to(node):
            remove_link(_links[idx])

    _graph.erase(node.id)
    _nodes.erase(node.id)
    node_deleted.emit(node.id)

    return true


## Remove a link
## If the link is not in the graph, returns false, otherwise true.
func remove_link(link: CGEGraphLink) -> bool:
    if not _graph.has(link.start_node_id) or not _graph.has(link.end_node_id):
        return false
    
    _graph[link.start_node_id].erase(link.end_node_id)
    _links.erase(link.id)
    
    if graph_type == CGEEnum.GraphType.UNDIRECTED:
        _graph[link.end_node_id].erase(link.start_node_id)
        _links.erase(link.get_reversed_link())
    
    link_deleted.emit(link.id)
    
    return true


## Get all nodes linked from a given node
func get_nodes_linked_from(node_id: int) -> Array:
    return _graph[node_id]


## Given a node ID, get all links linked to it ([b]both incoming and outgoing[/b])
func get_links_linked_to(node_id: int) -> Array[CGEGraphLink]:
    var links_to_return: Array[CGEGraphLink] = []

    for link in _links.values():
        if link.is_linked_to(_nodes[node_id]):
            links_to_return.push_back(link)

    return links_to_return


## Given a node ID, get all links [u]starting[/u] from it
func get_links_from(node_id: int) -> Array[CGEGraphLink]:
    var links_to_return: Array[CGEGraphLink] = []

    for link in _links.values():
        if link.start_node_id == node_id:
            links_to_return.push_back(link)

    return links_to_return


## Check if two nodes are connected. If any of the nodes do not exist, returns false with an error.
func are_connected(start_node_id: int, end_node_id: int) -> bool:
    if not _graph.has(start_node_id):
        push_error("Tried to check if '%s' is connected to '%s' but '%s' is not even in the graph. Something is wrong" % [start_node_id, end_node_id, end_node_id] )
        return false
    
    var connected: bool = _graph[start_node_id].has(end_node_id)

    return connected


## Serialize the graph into a Dictionary with two sub-dictionaries at keys [code]"nodes"[/code] and [code]"links"[/code].
## Each sub-dictionary maps IDs to serialized data of nodes and links respectively.[br]
## See [method deserialize].
func serialize() -> Dictionary:
    var data: Dictionary = {}

    var nodes_data: Dictionary = {}
    for node_id in _nodes.keys():
        nodes_data[node_id] = _nodes[node_id].serialize()

    var links_data: Dictionary = {}
    for link_id in _links.keys():
        links_data[link_id] = _links[link_id].serialize()

    data["nodes"] = nodes_data
    data["links"] = links_data

    return data


## Deserialize the graph from a Dictionary with two sub-dictionaries at keys [code]"nodes"[/code] and [code]"links"[/code].[br]
## [b]A [member node_class] [u]and[/u] a [member link_class] must be set before calling this method.[/b][br]
## See [method serialize].
func deserialize(data: Dictionary) -> void:
    # node_class and link_class must be set BEFORE calling deserialize
    if node_class == null or link_class == null:
        push_error("node_class and link_class must be set before deserialize()")
        return

    # Recreate all nodes
    var nodes_data: Dictionary = data["nodes"]
    for node_id_str in nodes_data.keys():
        var node_id: int = int(node_id_str)
        var node = create_node(node_id)
        node.deserialize(nodes_data[node_id_str])

    # Recreate all links
    var links_data: Dictionary = data["links"]
    for link_id_str in links_data.keys():
        var link_id: int = int(link_id_str)
        var link_data = link_class.new(link_id)
        link_data.deserialize(links_data[link_id_str])
        create_link(link_data.start_node_id, link_data.end_node_id, link_data.id).deserialize(links_data[link_id_str])

    _sync_id_counter()


## Generate a new unique ID for a node or link
func _get_new_id() -> int:
    var val: int = NEXT_NODE_ID
    NEXT_NODE_ID += 1
    return val


## Put the NEXT_NODE_ID variable to the max used ID + 1
func _sync_id_counter() -> void:
    if _nodes.is_empty():
        NEXT_NODE_ID = 0
        return
    
    var max_node_id: int = _nodes.keys().max()
    var max_link_id: int = _links.keys().max() if not _links.is_empty() else -1
    NEXT_NODE_ID = max(max_node_id, max_link_id) + 1


## Remove all nodes and links in the graph.
func clear_all() -> void:
    for node_id in _nodes.keys():
        remove_node(node_id)
    
    for link_id in _links.keys():
        remove_link(_links[link_id])
    
    