# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Built-in inspector panel for editing node and link properties
  - `CGEInspectorPanel` - Automatically displays and edits properties of selected elements
  - `CGEPropertyRow` - Individual property row with type-based controls
  - Users implement `_setup_inspector(inspector)` in custom UI classes (nodes and links) to define properties that are shown in the inspector
    - The type is automatically detected and adequate UI controls are generated
    - Available property types are string, int, float, bool, color, Vector2 and Vector3.
    - Properties can be read-only.

### Changed
- **BREAKING**: Renamed `_on_graph_element_updated()` to `_update_ui_from_data()` in `CGEGraphElementUI`
  - This method is now also called when individual properties change from the inspector, not just when the element is replaced. All nodes/links UI classes that overrided this method on the examples have been updated.
  - Migration: Simply rename `_on_graph_element_updated()` to `_update_ui_from_data()` in your custom UI classes.

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

[Unreleased]: https://github.com/tehelka-gamedev/godot-custom-graph-editor/compare/v0.5.0-beta...HEAD
[0.5.0-beta]: https://github.com/tehelka-gamedev/godot-custom-graph-editor/releases/tag/v0.5.0-beta
