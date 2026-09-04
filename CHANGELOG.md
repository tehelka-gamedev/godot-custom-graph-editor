# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0-beta] - 2026-09-05

### Added
- Multi-selection editing in the inspector panel
  - Editing a property now applies the change to every selected element of the same type as a single undo step (via `CGECompositeCommand`)
  - Selecting different node types disable the inspector
- `CGECompositeCommand` groups several commands into one atomically undoable command, rolling back children already processed if one fails
- `_setup_inspector()` can add custom controls: `add_action_button()` and `add_custom_control()`
  - `inspector.submit_command()` / `inspector.get_selection()` help building actions
  - A new example in `examples/inspector_actions/` showcase this new stuff

### Changed
- **BREAKING**: `_setup_inspector()` may now be called once per selected element instead of exactly once
  - Implementations must only call `inspector.add_*` methods and must not assume a single invocation or do one-time side effects
- The inspector `execute_command_requested` signal and `CGEGraphEditor._on_inspector_command_requested()` now take a `CGECommand` (previously `CGEInspectorCommand`), so the inspector can emit composite commands
    - Migration: if you connected a handler to `execute_command_requested`, widen its parameter type to `CGECommand`
- Range properties in the inspector no longer emit while the slider is being dragged; the value is committed once on drag end (no live preview during the drag however)

### Fixed
- Error spam from `CustomLineEdit`: its context menu is now trimmed each time it opens instead of once at `_ready()`, which no longer matches how Godot rebuilds the menu
- `_init` having non-optional parameters in `CGEGraphElement` and `CGEGraphLink`, to fix potential export problems


## [0.6.1-beta] - 2025-12-30
- Fixed crash in `CGEInspectorPanel` when modifying links attributes

## [0.6.0-beta] - 2025-12-29

### Added
- Built-in inspector panel for editing node and link properties
  - `CGEInspectorPanel` - Automatically displays and edits properties of selected elements
  - `CGEPropertyRow` - Individual property row with type-based controls
  - Users implement `_setup_inspector(inspector)` in custom UI classes (nodes and links) to define properties
    - Basic property types with auto-detected controls: string, int, float, bool, color, Vector2, Vector3
    - Specialized property methods for enhanced UI controls:
      - `add_enum_property()` - dropdown for selecting from predefined values
      - `add_range_property()` - horizontal slider + SpinBox combo for constrained numeric ranges
      - `add_flags_property()` - multiple checkboxes for bitfield/flag values
    - Properties can be read-only by not providing a setter
    - **Full undo/redo support**
    - Multiple selection placeholder message (multi-edit support planned for future)
- Inspector command system for undoable property changes
  - `CGEInspectorCommand` - Abstract base class for inspector-related commands
  - `CGESetPropertyCommand` - Command for property changes with validation and undo/redo support
- `CustomLineEdit` and `CustomTextEdit` controls that emit signals only when editing is complete (focus lost or Enter pressed)
- `get_graph_element(element_id)` helper method in `CGEGraphEditor` to retrieve nodes or links by ID without type checking
- `_to_string()` method for `CGECommand` to improve debugging

### Changed
- **BREAKING**: Renamed `_on_graph_element_updated()` to `_update_ui_from_data()` in `CGEGraphElementUI`
  - This method is now also called when individual properties change from the inspector, not just when the element is replaced
  - All example nodes/links UI classes have been updated
  - Migration: Simply rename `_on_graph_element_updated()` to `_update_ui_from_data()` in your custom UI classes
- Commands can now be created with `null` graph_editor reference (set later by the graph editor)
  - Enables inspector to create commands without direct reference to graph editor

### Removed
- Manual inspector implementation from `location_map` example.
  - Now uses built-in inspector system

## [0.5.0-beta] - 2025-12-18

### Added
- Initial beta release
- Core graph editor functionality
- Node and link management
- Undo/redo command system
- Serialization/deserialization
- Location map example

[Unreleased]: https://github.com/tehelka-gamedev/godot-custom-graph-editor/compare/v0.7.0-beta...HEAD
[0.7.0-beta]: https://github.com/tehelka-gamedev/godot-custom-graph-editor/compare/v0.6.1-beta...v0.7.0-beta
[0.6.1-beta]: https://github.com/tehelka-gamedev/godot-custom-graph-editor/compare/v0.6.0-beta...v0.6.1-beta
[0.6.0-beta]: https://github.com/tehelka-gamedev/godot-custom-graph-editor/compare/v0.5.0-beta...v0.6.0-beta
[0.5.0-beta]: https://github.com/tehelka-gamedev/godot-custom-graph-editor/releases/tag/v0.5.0-beta
