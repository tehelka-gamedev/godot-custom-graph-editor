# Interactive Viewer Example

A demo focused on in-game interactivity.

## What's Included
- `interactive_node_ui.gd` / `interactive_node_ui.tscn`
    - Hover state via `mouse_entered` / `mouse_exited`, drawn as a colored border alongside the existing `selected` state
- `interactive_viewer_demo.gd` / `.tscn`
    - Clicking a node selects it and tween `scroll_position` toward it
    - An info panel shows placeholder text for the selected node
    - Some nodes start locked (`visible = false`) and can be unlocked to reveal them via an animation too.