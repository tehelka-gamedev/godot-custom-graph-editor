extends GutTest
## Tests for CGEGraph class


var graph: CGEGraph


func before_each():
    CGEGraph.NEXT_NODE_ID = 0
    graph = CGEGraph.new()


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
    pass


## Removing a node that is not in the graph should fail
func test_remove_node_missing_fails():
    pass


## remove_node should emit node_deleted with the removed node's id
func test_remove_node_emits_signal():
    pass


## Removing a node should also remove any links connected to it
func test_remove_node_cascades_to_links():
    pass


# ============================================================================
# Link Creation
# ============================================================================

## Create a link between two existing nodes
func test_create_link():
    pass


## Try to create a link to/from a node that does not exist
func test_create_link_missing_node_fails():
    pass


## Try to create a second link between two nodes that are already connected
func test_create_link_already_connected_fails():
    pass


## Try to create a link with an id < -1
func test_create_link_invalid_id_fails():
    pass


## create_link should emit link_created with start/end/link ids
func test_create_link_emits_signal():
    pass


# ============================================================================
# Link Removal
# ============================================================================

## Remove an existing link
func test_remove_link():
    pass


## Removing a link whose nodes are not in the graph should fail
func test_remove_link_with_unknown_nodes_fails():
    pass


## remove_link should emit link_deleted with the removed link's id
func test_remove_link_emits_signal():
    pass


# ============================================================================
# Serialize / Deserialize
# ============================================================================

## An empty graph should serialize to empty "nodes"/"links" dictionaries
func test_serialize_empty_graph():
    pass


## Serialized data should contain every created node and link
func test_serialize_includes_nodes_and_links():
    pass


## Serializing a graph then deserializing into a fresh CGEGraph should reproduce
## the same nodes, links, and connections
func test_serialize_then_deserialize():
    pass


## deserialize should sync the id counter so new auto ids do not collide with loaded ones
func test_deserialize_syncs_id_counter():
    pass
