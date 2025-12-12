# Minimal Graph Editor Example

This example demonstrates the basics of extending the Custom Graph Editor addon with custom nodes.

## What's Included
- Minimal graph editor scene: (`minimal_graph_editor.tscn`)
- Custom Node Logic (`custom_node.gd`)
    - Extends `CGEGraphNode` to add a simple `node_name` property
    - Shows how to serialize/deserialize custom data
    - Demonstrates adding custom properties to graph nodes
- Custom Node UI (`custom_node_ui.gd`)
    - Represents the visual aspect of the custom node in the graph editor
    - Extends `CGEGraphNodeUI` to customize node appearance
    - Custom background color and border
    - Label displaying the node name and its ID
