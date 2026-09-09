extends GutTest
## Tests for CGEGraph class


var graph: CGEGraph


func before_each():
    CGEGraph.NEXT_NODE_ID = 0
    graph = CGEGraph.new()
    # Link tests below assume a directed graph. Undirected graph_type is untested here, since I don't bother with it for now... :o)
    graph.graph_type = CGEEnum.GraphType.DIRECTED


func after_each():
    graph = null


func test_init():
    var current_nodes: Array[int] = graph.get_all_node_ids()
    assert_eq(current_nodes.size(), 0, "Default graph should be empty")


# ============================================================================
# Node Creation
# ============================================================================

## Create a node and ensure it's correctly created
func test_create_node():
    var node: CGEGraphNode = graph.create_node()
    assert_not_null(node, "Created node should not be null")
    var current_nodes: Array[int] = graph.get_all_node_ids()
    assert_eq(current_nodes.size(), 1)


## Try to create two nodes with the same id
func test_create_node_duplicate_id_fails():
    var nb_nodes: int = graph.get_all_node_ids().size()

    const node_id: int = 100
    var node: CGEGraphNode = graph.create_node(node_id)
    var node_duplicate: CGEGraphNode = graph.create_node(node_id) # this will push_error
    assert_push_error(1, "This test should have pushed a push_error")
    assert_not_null(node, "The first created node should not be null")
    assert_null(node_duplicate, "The duplicate node should not be created")
    assert_eq(graph.get_all_node_ids().size(), nb_nodes + 1, "Only one node should have been created when creating two nodes with the same ID.")


## Try to create a node with a negative id (< -1), -1 being default for "auto generate id"
func test_create_node_invalid_id_fails():
    var node: CGEGraphNode = graph.create_node(-10)
    assert_push_error(1, "This test should have pushed a push_error")
    assert_null(node, "The node should not be created")


## A node created with an explicit id must have this id
func test_create_node_explicit_id():
    const node_id: int = 100
    var node: CGEGraphNode = graph.create_node(node_id)
    var node_get_by_id: CGEGraphNode = graph.get_node(node_id)
    assert_not_null(node_get_by_id, "Getting a node by id after creating it with explicit id should not return null")
    assert_eq(node, node_get_by_id)
    assert_eq(node_get_by_id.id, node_id)


## create_node should emit node_created with the new node's id
func test_create_node_emits_signal():
    watch_signals(graph)
    var node: CGEGraphNode = graph.create_node()
    assert_signal_emitted_with_parameters(graph, "node_created", [node.id])


# ============================================================================
# Node Removal
# ============================================================================

## Remove an existing node
func test_remove_node():
    var node: CGEGraphNode = graph.create_node()

    var result: bool = graph.remove_node(node.id)

    assert_true(result, "remove_node should return true for an existing node")
    assert_eq(graph.get_all_node_ids().size(), 0)


## Removing a node that is not in the graph should fail
func test_remove_node_missing_fails():
    var result: bool = graph.remove_node(42)
    assert_push_error(1, "This test should have pushed a push_error")
    assert_false(result, "remove_node should return false for a non-existent node")


## remove_node should emit node_deleted with the removed node's id
func test_remove_node_emits_signal():
    var node: CGEGraphNode = graph.create_node()

    watch_signals(graph)
    graph.remove_node(node.id)

    assert_signal_emitted_with_parameters(graph, "node_deleted", [node.id])


## Removing a node should also remove any links connected to it
func test_remove_node_cascades_to_links():
    var node_a: CGEGraphNode = graph.create_node()
    var node_b: CGEGraphNode = graph.create_node()
    var link: CGEGraphLink = graph.create_link(node_a.id, node_b.id)

    graph.remove_node(node_a.id)
    var removed_link: CGEGraphLink = graph.get_link(link.id) # this will push_error
    assert_push_error(1, "This test should have pushed a push_error")
    assert_null(removed_link, "Link connected to the removed node should also be removed")


# ============================================================================
# Link Creation (directed graph only — see before_each)
# ============================================================================

## Create a link between two existing nodes
func test_create_link():
    var node_a: CGEGraphNode = graph.create_node()
    var node_b: CGEGraphNode = graph.create_node()

    var link: CGEGraphLink = graph.create_link(node_a.id, node_b.id)

    assert_not_null(link, "Created link should not be null")
    assert_eq(link.start_node_id, node_a.id)
    assert_eq(link.end_node_id, node_b.id)
    assert_true(graph.are_connected(node_a.id, node_b.id), "Nodes should be connected after linking")


## get_all_link_ids should list every created link's id
func test_get_all_link_ids():
    var node_a: CGEGraphNode = graph.create_node()
    var node_b: CGEGraphNode = graph.create_node()
    var link: CGEGraphLink = graph.create_link(node_a.id, node_b.id)

    assert_eq(graph.get_all_link_ids(), [link.id])


## Try to create a link to/from a node that does not exist
func test_create_link_missing_node_fails():
    var node_a: CGEGraphNode = graph.create_node()

    var link: CGEGraphLink = graph.create_link(node_a.id, 999)
    assert_push_error(1, "This test should have pushed a push_error")
    assert_null(link, "Link should not be created when one of the nodes does not exist")


## Try to create a second link between two nodes that are already connected
func test_create_link_already_connected_fails():
    var node_a: CGEGraphNode = graph.create_node()
    var node_b: CGEGraphNode = graph.create_node()
    graph.create_link(node_a.id, node_b.id)

    var second_link: CGEGraphLink = graph.create_link(node_a.id, node_b.id)
    assert_push_error(1, "This test should have pushed a push_error")
    assert_null(second_link, "Linking already-connected nodes should fail")


## Try to create a link with an id < -1
func test_create_link_invalid_id_fails():
    var node_a: CGEGraphNode = graph.create_node()
    var node_b: CGEGraphNode = graph.create_node()

    var link: CGEGraphLink = graph.create_link(node_a.id, node_b.id, -10)
    assert_push_error(1, "This test should have pushed a push_error")
    assert_null(link, "The link should not be created")


## create_link should emit link_created with start/end/link ids
func test_create_link_emits_signal():
    var node_a: CGEGraphNode = graph.create_node()
    var node_b: CGEGraphNode = graph.create_node()

    watch_signals(graph)
    var link: CGEGraphLink = graph.create_link(node_a.id, node_b.id)

    assert_signal_emitted_with_parameters(graph, "link_created", [node_a.id, node_b.id, link.id])


# ============================================================================
# Link Removal (directed graph only — see before_each)
# ============================================================================

## Remove an existing link
func test_remove_link():
    var node_a: CGEGraphNode = graph.create_node()
    var node_b: CGEGraphNode = graph.create_node()
    var link: CGEGraphLink = graph.create_link(node_a.id, node_b.id)

    var result: bool = graph.remove_link(link)

    assert_true(result, "remove_link should return true for an existing link")
    assert_false(graph.are_connected(node_a.id, node_b.id), "Nodes should no longer be connected")


## Removing a link whose nodes are not in the graph should fail
func test_remove_link_with_unknown_nodes_fails():
    var fake_link: CGEGraphLink = graph.link_class.new(99, 1, 2)

    var result: bool = graph.remove_link(fake_link)

    assert_false(result, "remove_link should return false when the link's nodes are not in the graph")


## remove_link should emit link_deleted with the removed link's id
func test_remove_link_emits_signal():
    var node_a: CGEGraphNode = graph.create_node()
    var node_b: CGEGraphNode = graph.create_node()
    var link: CGEGraphLink = graph.create_link(node_a.id, node_b.id)

    watch_signals(graph)
    graph.remove_link(link)

    assert_signal_emitted_with_parameters(graph, "link_deleted", [link.id])


# ============================================================================
# Serialize / Deserialize
# ============================================================================

## An empty graph should serialize to empty "nodes"/"links" dictionaries
func test_serialize_empty_graph():
    var data: Dictionary = graph.serialize()
    assert_eq(data, {"nodes": {}, "links": {}})


## Serialized data should contain every created node and link
func test_serialize_includes_nodes_and_links():
    var node_a: CGEGraphNode = graph.create_node()
    var node_b: CGEGraphNode = graph.create_node()
    var link: CGEGraphLink = graph.create_link(node_a.id, node_b.id)

    var data: Dictionary = graph.serialize()

    assert_true(data["nodes"].has(node_a.id), "Serialized data should include node_a")
    assert_true(data["nodes"].has(node_b.id), "Serialized data should include node_b")
    assert_true(data["links"].has(link.id), "Serialized data should include the link")


## Serializing a graph then deserializing into a fresh CGEGraph should reproduce
## the same nodes, links, and connections
func test_serialize_then_deserialize():
    var node_a: CGEGraphNode = graph.create_node()
    var node_b: CGEGraphNode = graph.create_node()
    var link: CGEGraphLink = graph.create_link(node_a.id, node_b.id)
    var data: Dictionary = graph.serialize()

    var new_graph: CGEGraph = CGEGraph.new()
    new_graph.deserialize(data)

    assert_eq(new_graph.get_all_node_ids().size(), 2)
    assert_not_null(new_graph.get_node(node_a.id))
    assert_not_null(new_graph.get_node(node_b.id))
    assert_not_null(new_graph.get_link(link.id))
    assert_true(new_graph.are_connected(node_a.id, node_b.id), "Nodes should be connected after round trip")


## deserialize should sync the id counter so new auto ids do not collide with loaded ones
func test_deserialize_syncs_id_counter():
    graph.create_node(10)
    var data: Dictionary = graph.serialize()

    var new_graph: CGEGraph = CGEGraph.new()
    new_graph.deserialize(data)

    var new_node: CGEGraphNode = new_graph.create_node()

    assert_eq(new_node.id, 11, "Auto-generated ids should continue past the max id loaded from deserialize")
