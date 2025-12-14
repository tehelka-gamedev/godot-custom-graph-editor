@tool
class_name CGEConnectionContainer
extends Control
## Container to manage connections (links) between nodes in the custom graph editor.
##
## This class handles the connection and preview of links between nodes in the graph editor. It also holds (as children)
## the CGEGraphLinkUI instances representing the links.


## Emitted when a link is requested between two nodes. This is emitted when the user finishes creating a connection.
signal request_link(start_node: CGEGraphNodeUI, end_node: CGEGraphNodeUI)

## Scene to use for creating link UI instances (for preview only)
## This is set by the graph editor to match its graph_link_ui_scene. Not ideal and the truth should be at one position. That may be improved
## in the future.
var link_ui_scene: PackedScene = preload("res://addons/custom_graph_editor/UI/graph_link_ui.tscn")

# References to the nodes involved in the current connection
var _connection_start_node: CGEGraphNodeUI = null
var _connection_end_node: CGEGraphNodeUI = null
# temp reference to the current connection being created
var _connection_temp: CGEGraphLinkUI = null

## Start connecting from a given node, with the mouse at the given world coordinates
func start_connecting(node: CGEGraphNodeUI, mouse_world_coord: Vector2) -> void:
    _connection_start_node = node

    _connection_temp = link_ui_scene.instantiate()
    add_child(_connection_temp)
    _connection_temp.start_node = node

    _connection_temp.points[-1] = mouse_world_coord - _connection_start_node.get_center()
    _connection_temp.queue_redraw()


## Stop connecting to a given node (can be null, in which case the connection is cancelled). If not null, emits [signal request_link]
## that the graph editor can listen to then ask the graph to create the link.
func stop_connecting(node_under_mouse: CGEGraphNodeUI) -> void:
    if node_under_mouse == null:
        cancel_connecting()
        return
    request_link.emit(_connection_start_node, node_under_mouse)

    cancel_connecting()


## Cancel the current connection in progress
func cancel_connecting() -> void:
    _connection_start_node = null
    _connection_end_node = null
    _connection_temp.queue_free() # remove the temporary created link


## Handle mouse motion while connecting (to update preview, snap to node if hovering over one)
func handle_mouse_motion_button_right(node_under_mouse: CGEGraphNodeUI, mouse_world_coord: Vector2) -> void:
    if node_under_mouse:
        # only used for preview here
        _connection_temp.link_to(_connection_start_node, node_under_mouse)
    else:
        _connection_temp.points[-1] = (mouse_world_coord - _connection_start_node.get_center())
        _connection_temp.queue_redraw()
