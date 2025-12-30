# Rumor Map Example

An Outer Wilds-inspired knowledge graph example demonstrating how to create an exploration/mystery tracking system.

## Overview

This example shows how to build a "ship log" style rumor/clue tracking system where:
- Nodes represent locations, characters, mysteries, artifacts, or events
- Undiscovered nodes show as "?" until revealed
- Each node can have an image and multiple text clues
- Nodes are color-coded by category
- Links show relationships between different pieces of information

## Features Demonstrated

- **Discovery system** - Nodes toggle between unknown ("?") and discovered states
- **Category-based coloring** - Visual distinction between different types of information
- **Image display** - Optional images for discovered nodes
- **Clue tracking** - Each node maintains a list of text clues (viewable in future expansion)
- **Custom inspector** - Edit rumor properties including name, category, discovery state, and image path

## File Structure

- `rumor_node.gd` - Logic class for rumor/clue entries
- `rumor_node_ui.gd` - Visual representation with discovery states
- `rumor_node_ui.tscn` - UI scene showing name, image/unknown icon, and clue count
- `rumor_link.gd` - Connection between rumors with optional relationship notes
- `rumor_link_ui.gd` - Visual representation of connections
- `rumor_graph_editor.tscn` - Main editor scene (open this to try the example)

## Categories

Each rumor can be categorized as:
- **LOCATION** (Blue) - Places to explore
- **CHARACTER** (Orange) - NPCs and entities
- **MYSTERY** (Purple) - Unsolved questions
- **ARTIFACT** (Green) - Important objects
- **EVENT** (Yellow) - Temporal or story events

## How to Use

1. Open `rumor_graph_editor.tscn`
2. Add nodes using the toolbar button
3. Select a node to edit its properties in the inspector:
   - Set the rumor name
   - Toggle "Discovered" to reveal/hide it
   - Choose a category (changes the border color)
   - Set an image path (shown when discovered)
4. Connect nodes by right-click dragging between them
5. Save/load your knowledge graph using File menu

## Future Enhancements

Ideas for extending this example:
- Clue editor panel to add/remove individual clues
- Auto-discovery system based on game events
- Search/filter functionality
- Zoom to related nodes
- Different link types (requires, leads to, contradicts, etc.)
- Export to in-game readable format

## Inspiration

This example is inspired by Outer Wilds' brilliant ship log system, which masterfully turns knowledge discovery into a core game mechanic.
