@tool
class_name LocationMapEditor
extends CGEGraphEditor
## Extended graph editor with an inspector panel for editing location and path properties.
##
## This example demonstrates how to extend the base graph editor to add custom UI elements
## like an inspector panel for editing node and link metadata.

## Graph loaded on start
const DEFAULT_GRAPH_PATH: String = "graph_example/example_graph.gegraph"

## Inspector panel container
@onready var inspector_panel: PanelContainer = %InspectorPanel

## Inspector content (for node properties)
@onready var node_inspector: VBoxContainer = %NodeInspector
@onready var node_name_label: Label = %NodeNameLabel
@onready var location_name_edit: LineEdit = %LocationNameEdit

## Inspector content (for link properties)
@onready var link_inspector: VBoxContainer = %LinkInspector
@onready var link_name_label: Label = %LinkNameLabel
@onready var travel_cost_edit: SpinBox = %TravelCostEdit

## Currently selected element being inspected
var _inspected_element: CGEGraphElementUI = null


func _ready() -> void:
    super()
    _hide_all_inspectors()

    # Connect to selection signals
    graph_element_selected.connect(_on_graph_element_selected)

    load_from_file(get_script().get_path().get_base_dir() + "/" + DEFAULT_GRAPH_PATH)
    clear_selection()


## Called when a graph element is selected
func _on_graph_element_selected(element: CGEGraphElementUI) -> void:
    _inspected_element = element
    _update_inspector()


## Update the inspector panel based on the selected element
func _update_inspector() -> void:
    if _inspected_element == null or not is_instance_valid(_inspected_element):
        _hide_all_inspectors()
        return

    # Check if element is still selected (might have been deselected)
    if not _selection.has(_inspected_element):
        _inspected_element = null
        _hide_all_inspectors()
        return

    # Show appropriate inspector based on element type
    if _inspected_element is LocationNodeUI:
        _show_node_inspector()
    elif _inspected_element is TravelPathUI:
        _show_link_inspector()
    else:
        _hide_all_inspectors()


## Show the node inspector and populate it with the selected node's data
func _show_node_inspector() -> void:
    _hide_all_inspectors()
    node_inspector.visible = true

    var node_ui: LocationNodeUI = _inspected_element as LocationNodeUI
    var location_node: LocationNode = node_ui.graph_element as LocationNode

    node_name_label.text = "Location (ID: %d)" % location_node.id
    location_name_edit.text = location_node.location_name

    # Disconnect previous signal if any
    if location_name_edit.text_submitted.is_connected(_on_location_name_changed):
        location_name_edit.text_submitted.disconnect(_on_location_name_changed)

    # Connect to update when the user changes the text
    location_name_edit.text_submitted.connect(_on_location_name_changed)


## Show the link inspector and populate it with the selected link's data
func _show_link_inspector() -> void:
    _hide_all_inspectors()
    link_inspector.visible = true

    var link_ui: TravelPathUI = _inspected_element as TravelPathUI
    var travel_path: TravelPath = link_ui.graph_element as TravelPath

    link_name_label.text = "Travel Path (ID: %d)" % travel_path.id
    travel_cost_edit.value = travel_path.travel_cost

    # Disconnect previous signal if any
    if travel_cost_edit.value_changed.is_connected(_on_travel_cost_changed):
        travel_cost_edit.value_changed.disconnect(_on_travel_cost_changed)

    # Connect to update when the user changes the value
    travel_cost_edit.value_changed.connect(_on_travel_cost_changed)


## Hide all inspector panels
func _hide_all_inspectors() -> void:
    if node_inspector:
        node_inspector.visible = false
    if link_inspector:
        link_inspector.visible = false


## Called when the location name is changed in the inspector
func _on_location_name_changed(new_name: String) -> void:
    if _inspected_element == null or not is_instance_valid(_inspected_element):
        return

    var node_ui: LocationNodeUI = _inspected_element as LocationNodeUI
    if node_ui:
        var location_node: LocationNode = node_ui.graph_element as LocationNode
        location_node.location_name = new_name
        node_ui._update_location_label()
        file_is_modified = true


## Called when the travel cost is changed in the inspector
func _on_travel_cost_changed(new_cost: float) -> void:
    if _inspected_element == null or not is_instance_valid(_inspected_element):
        return

    var link_ui: TravelPathUI = _inspected_element as TravelPathUI
    if link_ui:
        var travel_path: TravelPath = link_ui.graph_element as TravelPath
        travel_path.travel_cost = int(new_cost)
        link_ui._update_cost_label()
        file_is_modified = true


## Override to handle deselection
func clear_selection() -> void:
    super()
    _inspected_element = null
    _hide_all_inspectors()
