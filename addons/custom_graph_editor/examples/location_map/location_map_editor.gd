@tool
class_name LocationMapEditor
extends CGEGraphEditor
## Extended graph editor with an inspector panel for editing location and path properties.
##
## This example demonstrates how to extend the base graph editor to add custom UI elements
## like an inspector panel for editing node and link metadata.

## Graph loaded on start
const DEFAULT_GRAPH_PATH: String = "graph_example/example_graph.gegraph"

func _ready() -> void:
    super()

    var file_path_to_load: String = get_script().get_path().get_base_dir() + "/" + DEFAULT_GRAPH_PATH

    # If the demo file exists, load it, otherwise (for web, for instance) load an hardcoded graph as backup
    if FileAccess.file_exists(file_path_to_load):
        load_from_file(get_script().get_path().get_base_dir() + "/" + DEFAULT_GRAPH_PATH)
    else:
        deserialize(DEMO_GRAPH_BACKUP_WEB)
        _command_history.clear_all()

    clear_selection()


## Override to handle deselection
func clear_selection() -> void:
    super()



var DEMO_GRAPH_BACKUP_WEB: Dictionary = {
    "links": {
        "3": {
            "end_node_id": 1,
            "id": 3,
            "position": {
                "x": -137.799987792969,
                "y": 127.799987792969
            },
            "start_node_id": 0,
            "travel_cost": 1
        },
        "4": {
            "end_node_id": 2,
            "id": 4,
            "position": {
                "x": -137.799987792969,
                "y": 127.799987792969
            },
            "start_node_id": 0,
            "travel_cost": 5
        },
        "5": {
            "end_node_id": 1,
            "id": 5,
            "position": {
                "x": 94.2000122070313,
                "y": 10.7999877929688
            },
            "start_node_id": 2,
            "travel_cost": 5
        },
        "6": {
            "end_node_id": 0,
            "id": 6,
            "position": {
                "x": 94.2000122070313,
                "y": 10.7999877929688
            },
            "start_node_id": 2,
            "travel_cost": 5
        }
    },
    "nodes": {
        "0": {
            "id": 0,
            "location_name": "Farm",
            "position": {
                "x": -197.799987792969,
                "y": 97.7999877929688
            }
        },
        "1": {
            "id": 1,
            "location_name": "River",
            "position": {
                "x": 69.2000122070313,
                "y": 136.799987792969
            }
        },
        "2": {
            "id": 2,
            "location_name": "Mountains",
            "position": {
                "x": 34.2000122070313,
                "y": -19.2000122070313
            }
        }
    }
}
