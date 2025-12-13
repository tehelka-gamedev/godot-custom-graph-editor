@tool
class_name CGEGraphLinkUI
extends CGEGraphElementUI
## UI representation of a link in the custom graph editor.
##
## This class handles the visual representation and interaction of a link between two nodes in the custom graph editor.

## Width of the link line (between 1 and 20 pixels)
@export_range(1, 20, 1, "or_greater", "suffix:px") var width:int = 3
## Color of the link when not selected
@export var color:Color = Color.WHITE
## Color of the link when hovered or selected (hover not implemented yet)
@export var hover_color: Color = Color.RED
## Whether the link line is antialiased
@export var antialiased:bool = true
## Texture used for the arrow at the end of the link (if any)
@export var arrow_texture: Texture2D = null

## Points of the link, expressed in the node's space (so (0,0) is on the node's origin)
## points[0] must always be [0;0] !
var points:Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]

## The starting node UI of the link
var start_node: CGEGraphNodeUI = null :
    set(value):
        if start_node != null:
            start_node.moved.disconnect(_on_start_node_moved)
        start_node = value
        position = start_node.get_center()
        start_node.moved.connect(_on_start_node_moved)
        queue_redraw()

## The ending node UI of the link.
var end_node: CGEGraphNodeUI = null :
    set(value):
        if end_node != null:
            end_node.moved.disconnect(_on_end_node_moved)
        end_node = value
        end_node.moved.connect(_on_end_node_moved)
        queue_redraw()

## Type of arrow to draw (see CGEEnum.GraphType). Only DIRECTED is supported for now.
var arrow_type: CGEEnum.GraphType = CGEEnum.GraphType.DIRECTED

## Offset for parallel links (perpendicular to link direction).
## Positive = offset to the right, negative = offset to the left
## Only applied when points.size() == 2 (no manual anchor points)
var parallel_link_offset: float = 0.0 :
    set(value):
        parallel_link_offset = value
        _refresh_points()


# Draw each frame. Maybe not needed, but it is easier this way.
func _process(_delta):
    queue_redraw()


# Draw the link + arrow
func _draw() -> void:
    if len(points) <= 1:
        return
    # Draw each pair of points
    var multi_line_vector_array:PackedVector2Array = PackedVector2Array()
    var multi_line_color_array: PackedColorArray = PackedColorArray()

    var color:Color = color if not selected else hover_color # I do not handle hover yet
    for i in range(len(points)-1):
        multi_line_vector_array.append(points[i])
        multi_line_vector_array.append(points[i+1])
        multi_line_color_array.append(color)
    # Uses draw_multiline_colors to be more efficient if there is a large number of points
    # I do not know if if it is more efficient to just call draw_line for just a few segments (probably?)
    # but it will not really matter here, and I will profile one day if it becomes a problem.
    draw_multiline_colors(multi_line_vector_array, multi_line_color_array, width, antialiased)

    _draw_arrow()


## Serialize the link UI into a Dictionary. See [method CGEGraphElementUI.serialize].
func serialize() -> Dictionary:
    var data: Dictionary = super()
    return data


## Deserialize the link UI from a Dictionary. See [method CGEGraphElementUI.deserialize].
func deserialize(data: Dictionary) -> void:
    super(data)


## Link/attach this link between two nodes
func link_to(from_node: CGEGraphNodeUI, to_node: CGEGraphNodeUI) -> void:
    # TODO: check if they are the same and allow it or not ?
    start_node = from_node
    end_node = to_node

    var link_start: Vector2 = start_node.get_center()
    var link_end: Vector2 = end_node.get_center()
    position = start_node.get_center()

    _refresh_points()


## Test if a [code]pos: Vector2[/code] is on the line.[br]
## [b]Note:[/b] [code]pos[/code] is expressed in world space.[br]
## Inspired from godot's source code.
func is_on_line(pos: Vector2) -> bool:
    var squared_width: float = width * width

    pos -= position

    for i in range(points.size() -1):
        var segment_start: Vector2 = points[i]
        var segment_end: Vector2 = points[i+1]
        var closest_point: Vector2 = Geometry2D.get_closest_point_to_segment(pos, segment_start, segment_end)

        # If the distance to the closest point is closer than the width, it's on the line
        if closest_point.distance_squared_to(pos) <= squared_width:
            return true

    return false

## Test if the link intersects with a rectangle.[br]
## [b]Note:[/b] the rectangle is expressed in world space.
func intersects_rect(rect: Rect2) -> bool:
    # Check each segment of the link
    for i in range(points.size() - 1):
        var segment_start: Vector2 = position + points[i]
        var segment_end: Vector2 = position + points[i + 1]

        # Check if either endpoint is inside the rectangle
        if rect.has_point(segment_start) or rect.has_point(segment_end):
            return true

        # Check if segment intersects any of the rectangle's edges
        var rect_edges = [
            [rect.position, Vector2(rect.end.x, rect.position.y)],  # Top
            [Vector2(rect.end.x, rect.position.y), rect.end],  # Right
            [rect.end, Vector2(rect.position.x, rect.end.y)],  # Bottom
            [Vector2(rect.position.x, rect.end.y), rect.position]  # Left
        ]

        for edge in rect_edges:
            var intersection = Geometry2D.segment_intersects_segment(segment_start, segment_end, edge[0], edge[1])
            if intersection != null:
                return true

    return false


## Returns the link starting point in the nodes space. So it is always (0,0). Returns an error and Vector2.ZERO if there are no points.
func get_starting_point() -> Vector2:
    if len(points) == 0:
        push_error("Cannot get the starting point of a graph link '%s' because there are no points inside" % name)
        return Vector2.ZERO
    return points[0]


## Returns the link ending point in the nodes space. Returns an error and Vector2.ZERO if there are no points.
func get_ending_point() -> Vector2:
    if len(points) == 0:
        push_error("Cannot get the ending point of a graph link '%s' because there are no points inside" % name)
        return Vector2.ZERO
    return points[-1]


## Draw the arrow at the end of the link
func _draw_arrow() -> void:
    var color:Color = color if not selected else hover_color # I do not handle hover yet
    if arrow_texture != null and arrow_type == CGEEnum.GraphType.DIRECTED:
        var last_point: Vector2 = points[len(points)-1]
        var last_vector: Vector2 = points[len(points)-1] - points[len(points)-2]
        var draw_pos: Vector2 = -arrow_texture.get_size()/2
        # Rotate the next drawing by the angle of the last point
        draw_set_transform(last_point, atan2(last_vector.y, last_vector.x))
        draw_texture(arrow_texture, draw_pos, color)


## Called when the start node is moved.
## Assumes there are at least 2 points.
func _on_start_node_moved() -> void:
    var offset:Vector2 = position - start_node.position
    position = start_node.get_center()
    # points[0] is [0;0], only change other

    _on_node_moved(start_node)


## Called when the end node is moved
## assumes there are at least 2 points
func _on_end_node_moved() -> void:
    _on_node_moved(end_node)


## Called when any linked node is moved.
func _on_node_moved(node: CGEGraphNodeUI) -> void:
    if end_node == null:
        return

    _refresh_points()


## Recompute the points position based on the start_node and end_node position. Takes into account parallel link offset.
func _refresh_points() -> void:
    if start_node == null or end_node == null:
        print_debug("_refresh_points() with no start_node or no end_node. This case is not handled yet!")
        return

    var link_start: Vector2 = start_node.get_center()
    var link_end: Vector2 = end_node.get_center()

    # Apply parallel link offset only if there are no manual anchor points
    if points.size() == 2 and not is_zero_approx(parallel_link_offset):
        # Use a consistent direction for perpendicular calculation
        # Always use the direction from lower ID to higher ID node
        # This ensures bidirectional links offset in opposite directions
        var canonical_direction: Vector2
        if start_node.get_id() < end_node.get_id():
            canonical_direction = (link_end - link_start).normalized()
        else:
            canonical_direction = (link_start - link_end).normalized()

        var offset_vector: Vector2 = canonical_direction.orthogonal() * parallel_link_offset

        # Apply offset to both start and end
        link_start += offset_vector
        link_end += offset_vector

    points[0] = _get_closest_intersection_point_on_node(link_start, link_end, start_node) - start_node.get_center()
    points[-1] = _get_closest_intersection_point_on_node(link_start, link_end, end_node) - start_node.get_center()

    queue_redraw()


## String representation of the link UI
func _to_string() -> String:
    return "UI('%s')" % [ graph_element ]


## Given a link, returns the closest intersection point on the bounding box of a CGEGraphNodeUI
func _get_closest_intersection_point_on_node(link_start: Vector2, link_end: Vector2, node: CGEGraphNodeUI, debug_draw:bool = false) -> Vector2:
    var node_rect: Rect2 = node.get_rect()

    var best_point: Vector2 = link_end

    var top_left:= node_rect.position
    var top_right:= top_left + Vector2(node_rect.size.x, 0)
    var bottom_left:= top_left + Vector2(0, node_rect.size.y)
    var bottom_right:= node_rect.end

    
    var edges: Array[Vector2] = [
        top_left, top_right,
        top_left, bottom_left,
        top_right, bottom_right,
        bottom_left, bottom_right,
    ]

    for i in range(0, len(edges), 2):
        var intersection: Variant = Geometry2D.segment_intersects_segment(link_start, link_end, edges[i], edges[i+1])
        if intersection == null:
            if debug_draw:
                draw_line(edges[i]-position, edges[i+1]-position, Color.RED, 5)
            continue
        
        if debug_draw:
            draw_line(edges[i]-position, edges[i+1]-position, Color.BLUE, 5)

        if( link_start.distance_squared_to(intersection as Vector2) < link_start.distance_squared_to(best_point) ):
            best_point = intersection as Vector2
    
    if debug_draw:
        draw_circle(best_point - position, 3, Color.GREEN)

    return best_point
