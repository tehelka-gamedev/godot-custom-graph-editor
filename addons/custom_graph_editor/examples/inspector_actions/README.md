# Inspector Action Example

An example to show how to add action buttons and arbitrary controls to the inspector, on top of the regular property rows.

## What's included
- A graph editor scene (`inspector_actions_editor.tscn`) which loads an hardcoded graph when launched
- Condition Node Logic (`condition_node.gd`)
  - Extends `CGEGraphNode` with a free-text `condition_expression` (plus a `node_name`).
- Condition Node UI (`condition_node_ui.gd`), which is the UI part of condition nodes. They have custom actions in the inspector. Their `_setup_inspector()` demonstrates the `CGEInspectorPanel` action:
    - `add_action_button(id, text, on_pressed, opts)` displays a button, only shown if one (and only one) node is selected, that opens the con
    - `add_custom_control(id, control, label)`: an arbitrary `Control` (here a short help note).

**Note:** the `on_pressed` callback receives the selection snapshot taken when the button was built. If you keep a reference to elements for later use, be wary of this.
