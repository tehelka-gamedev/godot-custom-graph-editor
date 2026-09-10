@tool
extends Control
## InteractiveViewer
##
##  A demo to display how to add interaction to the graph view.

## Node data are hardcoded here for simplicity of this example. Ideally you would encapsulate data into a custom [CGEGraphNode]
## or link that with a custom progression system in your project.
const NODE_DATA: Array = [
    {"name": "Town", "info": "A town. Nothing much happens here.", "locked": false},
    {"name": "Forest", "info": "A forest, with a lot of trees.", "locked": false},
    {"name": "Village", "info": "A village, smaller than the town.", "locked": false},
    {"name": "Cave", "info": "Legends say an ogre lives in there. Be careful.", "locked": true},
    {"name": "Ruins", "info": "Ancient ruins cursed by an evil wizard.", "locked": true},
]

const RING_RADIUS: float = 200.0
const PAN_DURATION: float = 0.5

@onready var _viewer: CGEGraphViewer = %Viewer
@onready var _info_panel: PanelContainer = %InfoPanel
@onready var _info_label: Label = %InfoLabel
@onready var _unlock_button: Button = %UnlockButton

var _locked_node_uis: Array[InteractiveNodeUI] = []
var _selected_node_ui: InteractiveNodeUI = null


func _ready() -> void:
    var graph: CGEGraph = CGEGraph.new()

    var nodes: Array[CGEGraphNode] = []
    for data in NODE_DATA:
        nodes.append(graph.create_node())

    _viewer.load_graph(graph)

    for i in range(nodes.size()):
        var angle: float = TAU * i / nodes.size() - PI / 2.0
        var node_ui: InteractiveNodeUI = _viewer.get_graph_node(nodes[i].id) as InteractiveNodeUI
        node_ui.position = Vector2(cos(angle), sin(angle)) * RING_RADIUS
        node_ui.display_name = NODE_DATA[i]["name"]
        node_ui.info_text = NODE_DATA[i]["info"]

        if NODE_DATA[i]["locked"]:
            node_ui.visible = false
            _locked_node_uis.append(node_ui)

    graph.create_link(nodes[0].id, nodes[1].id)
    graph.create_link(nodes[1].id, nodes[2].id)
    graph.create_link(nodes[2].id, nodes[0].id)
    graph.create_link(nodes[0].id, nodes[3].id)
    graph.create_link(nodes[1].id, nodes[4].id)

    await get_tree().process_frame
    _viewer.fit_to_view()

    _viewer.gui_input.connect(_on_viewer_gui_input)
    _unlock_button.pressed.connect(_on_unlock_button_pressed)
    _update_unlock_button()
    _info_panel.visible = false


func _on_viewer_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var hit: CGEGraphElementUI = _viewer.get_graph_element_under_mouse()
        if hit is InteractiveNodeUI:
            _select_node(hit as InteractiveNodeUI)
        else:
            _deselect_node()


func _select_node(node_ui: InteractiveNodeUI) -> void:
    if _selected_node_ui == node_ui:
        return
    _deselect_node()

    _selected_node_ui = node_ui
    node_ui.set_selected(true)

    _info_label.text = "%s\n\n%s" % [node_ui.display_name, node_ui.info_text]
    _info_panel.visible = true

    _animate_pan_to_node(node_ui)


func _animate_pan_to_node(node_ui: CGEGraphNodeUI) -> void:
    var tween: Tween = create_tween()
    tween.tween_property(_viewer, "scroll_position", _viewer.get_pan_position(node_ui), PAN_DURATION) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    await tween.finished


func _deselect_node() -> void:
    if _selected_node_ui == null:
        return
    _selected_node_ui.set_selected(false)
    _selected_node_ui = null
    _info_panel.visible = false


func _on_unlock_button_pressed() -> void:
    if _locked_node_uis.is_empty():
        return
    var node_ui: InteractiveNodeUI = _locked_node_uis.pop_front()
    _update_unlock_button()

    await _animate_pan_to_node(node_ui)
    node_ui.visible = true


func _update_unlock_button() -> void:
    var remaining: int = _locked_node_uis.size()
    _unlock_button.disabled = remaining == 0
    _unlock_button.text = "All unlocked" if remaining == 0 else "Unlock a location (%d left)" % remaining
