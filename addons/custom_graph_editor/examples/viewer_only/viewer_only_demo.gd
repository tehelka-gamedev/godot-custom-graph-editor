@tool
extends Control
## Demo scene using [CGEGraphViewer] standalone, with no [CGEGraphEditor] at all.
##
## Builds a small hardcoded [CGEGraph] in code and hands it to the viewer: this is to display that there can be no editor, just navigation (for in-game usage).

@onready var _viewer: CGEGraphViewer = %Viewer


func _ready() -> void:
    var graph: CGEGraph = CGEGraph.new()

    var node_a: CGEGraphNode = graph.create_node()
    var node_b: CGEGraphNode = graph.create_node()
    var node_c: CGEGraphNode = graph.create_node()
    var node_d: CGEGraphNode = graph.create_node()

    _viewer.load_graph(graph)

    # CGEGraphNode has no position field (it's in the UI part), so we position them by hand for
    # this demo.
    _viewer.get_graph_node(node_a.id).position = Vector2(-200, -80)
    _viewer.get_graph_node(node_b.id).position = Vector2(120, -80)
    _viewer.get_graph_node(node_c.id).position = Vector2(120, 100)
    _viewer.get_graph_node(node_d.id).position = Vector2(-200, 100)

    graph.create_link(node_a.id, node_b.id)
    graph.create_link(node_b.id, node_c.id)
    graph.create_link(node_c.id, node_d.id)
    graph.create_link(node_d.id, node_a.id)
    graph.create_link(node_a.id, node_c.id)
