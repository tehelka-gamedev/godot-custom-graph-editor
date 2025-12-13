@tool
class_name CGEGrid
extends Control
## Grid for the custom graph editor.
##
## This class draws a grid in the background of the graph editor.


## Whether the grid starts at top-left or has a bit of offset
@export var offset: Vector2 = Vector2.ZERO : 
    set(value):
        offset = value
        queue_redraw()


## Pixel space between grid lines
@export var step_px: Vector2i = Vector2i(8, 8) :
    set(value):
        if value.x <= 0 or value.y <= 0:
            push_error("Grid step must be positive")
            return
        step_px = value
        queue_redraw()


## Number of (minor) lines between major lines
## Major lines are drawn with a different color for better visibility
@export var major_line_step: Vector2i = Vector2i(8, 8) :
    set(value):
        if value.x <= 0 or value.y <= 0:
            push_error("Major line step must be positive")
            return
        major_line_step = value
        queue_redraw()

## Zoom level of the grid
@export var zoom: float = 1.0 :
    set(value):
        if value <= 0:
            push_error("Zoom must be positive")
            return
        zoom = value
        queue_redraw()


@export_category("Colors")
## Color of major grid lines
@export var grid_major_color: Color = Color(1, 1, 1, 0.2) :
    set(value):
        grid_major_color = value
        queue_redraw()

## Color of minor grid lines
@export var grid_minor_color: Color = Color(1, 1, 1, 0.05) :
    set(value):
        grid_minor_color = value
        queue_redraw()


func _ready():
    # Ensure the grid is drawn when the scene is ready
    queue_redraw()


func _draw():
    # Arrays containing the points and colors for the grid lines, to draw them in one go
    var multi_line_vector_array: PackedVector2Array = PackedVector2Array()
    var multi_line_color_array: PackedColorArray = PackedColorArray()

    # Use Vector2 instead of Vector2i for better precision with non-integer zoom
    var screen_step_px: Vector2 = Vector2(step_px) * zoom

    # Calculate start position using modulo for consistent wrapping
    var start: Vector2 = Vector2(
        fposmod(offset.x, screen_step_px.x),
        fposmod(offset.y, screen_step_px.y)
    )
    var end: Vector2 = Vector2(
        size.x + start.x,
        size.y + start.y
    )
    var major_step_px: Vector2 = screen_step_px * Vector2(major_line_step)

    # Draw vertical lines
    var x: float = start.x
    while x < end.x:
        # Fixed: removed abs() which was causing incorrect major line detection with negative coordinates
        var color: Color = grid_major_color if is_zero_approx(fposmod(x - offset.x, major_step_px.x)) else grid_minor_color
        var start_line: Vector2 = Vector2(x, start.y)
        var end_line: Vector2 = Vector2(x, end.y)

        multi_line_vector_array.append(start_line)
        multi_line_vector_array.append(end_line)
        multi_line_color_array.append(color)

        x += screen_step_px.x


    # Draw horizontal lines
    var y: float = start.y
    while y < end.y:
        # Fixed: removed abs() which was causing incorrect major line detection with negative coordinates
        var color: Color = grid_major_color if is_zero_approx(fposmod(y - offset.y, major_step_px.y)) else grid_minor_color
        var start_line: Vector2 = Vector2(start.x, y)
        var end_line: Vector2 = Vector2(end.x, y)

        multi_line_vector_array.append(start_line)
        multi_line_vector_array.append(end_line)
        multi_line_color_array.append(color)

        y += screen_step_px.y

    draw_multiline_colors(multi_line_vector_array, multi_line_color_array, -1)