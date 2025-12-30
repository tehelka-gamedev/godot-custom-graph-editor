# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/tehelka-gamedev/godot-custom-graph-editor/compare/v0.6.0-beta...HEAD
[0.6.0-beta]: https://github.com/tehelka-gamedev/godot-custom-graph-editor/compare/v0.5.0-beta...v0.6.0-beta
[0.5.0-beta]: https://github.com/tehelka-gamedev/godot-custom-graph-editor/releases/tag/v0.5.0-beta
