@tool
class_name InspectorActionsEditor
extends CGEGraphEditor
## Extended graph editor with an inspector panel with a custom button
##
## This example demonstrates how to extend the inspector with a custom button 

## Hardcoded graph, loaded on start
const STARTER_GRAPH: Dictionary = {
    "nodes": {
        "0": {
            "id": 0,
            "node_name": "Gate",
            "condition_expression": "player.has_item(\"key\")",
            "position": {"x": - 270.0, "y": - 30.0},
        },
        "1": {
            "id": 1,
            "node_name": "Bridge",
            "condition_expression": "",
            "position": {"x": 170.0, "y": - 30.0},
        },
        "2": {
            "id": 2,
            "node_name": "Vault",
            "condition_expression": "",
            "position": {"x": - 80.0, "y": 120.0},
        },
    },
    "links": {},
}


func _ready() -> void:
    super()

    deserialize(STARTER_GRAPH)
    _command_history.clear_all()
    clear_selection()
