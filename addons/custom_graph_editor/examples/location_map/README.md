# Location Map Graph Editor Example

This example demonstrates creating a world map / location graph editor with custom metadata and an inspector panel for editing properties.

## What's Included
- A graph editor scene (`location_map_editor.tscn`) which loads an example graph (`graph_example/example_graph.gegraph`) when launched
- Custom Node Logic (`location_node.gd`) and its UI part (`location_node_ui.gd`)
    - Adds a `location_name` property to nodes and change the visual representation of nodes
- Custom Link Logic (`travel_path.gd`) and its UI part (`travel_path_ui.gd`)
    - Adds a `travel_cost` property to links and change the visual representation of links (display the cost on the link)
- An inspector panel to edit properties
