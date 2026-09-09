@tool
extends Control
## "PrettyViewer", a fancier standalone [CGEGraphViewer] demo
##
## 

const NODE_COUNT: int = 6
const RING_RADIUS: float = 220.0

const MARKER_SIZE: Vector2 = Vector2(16, 16)
const MARKER_SPEED: float = 220.0
const BOB_OFFSET: Vector2 = Vector2(0, 40)
const BOB_DURATION: float = 1.4

@onready var _viewer: CGEGraphViewer = %Viewer

var _marker: ColorRect = null
var _path: Array[CGEGraphNodeUI] = []
var _path_index: int = 0


func _ready() -> void:
    var graph: CGEGraph = CGEGraph.new()

    var nodes: Array[CGEGraphNode] = []
    for i in range(NODE_COUNT):
        nodes.append(graph.create_node())

    _viewer.load_graph(graph)

    for i in range(nodes.size()):
        var angle: float = TAU * i / nodes.size() - PI / 2.0
        _viewer.get_graph_node(nodes[i].id).position = Vector2(cos(angle), sin(angle)) * RING_RADIUS

    # Connect nodes in a ring
    for i in range(nodes.size()):
        graph.create_link(nodes[i].id, nodes[(i + 1) % nodes.size()].id)
    # + a reverse link and chord across the ring to break symmetry
    graph.create_link(nodes[1].id, nodes[0].id)
    graph.create_link(nodes[0].id, nodes[3].id)

    await get_tree().process_frame
    _viewer.fit_to_view()

    for node in nodes:
        _path.append(_viewer.get_graph_node(node.id))

    _marker = ColorRect.new()
    _marker.size = MARKER_SIZE
    _marker.color = Color(1.0, 0.8, 0.2)
    _marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _viewer.add_to_content(_marker)
    _marker.position = _path[0].get_center() - MARKER_SIZE / 2.0

    _animate_node_bob(_viewer.get_graph_node(nodes[3].id))


## Move the marker toward the current target node's center at a constant speed, following the graph.
func _process(delta: float) -> void:
    if _marker == null or _path.is_empty():
        return

    var target: CGEGraphNodeUI = _path[_path_index]
    var target_pos: Vector2 = target.get_center() - MARKER_SIZE / 2.0
    var to_target: Vector2 = target_pos - _marker.position
    var step: float = MARKER_SPEED * delta

    if to_target.length() <= step:
        _marker.position = target_pos
        _path_index = (_path_index + 1) % _path.size()
    else:
        _marker.position += to_target.normalized() * step


## Move a node up and down forever via a looping [Tween]
func _animate_node_bob(node_ui: CGEGraphNodeUI) -> void:
    var base_position: Vector2 = node_ui.position
    var tween: Tween = create_tween().set_loops()
    tween.tween_property(node_ui, "position", base_position + BOB_OFFSET, BOB_DURATION) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(node_ui, "position", base_position, BOB_DURATION) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
