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
				"x": -95.7999877929688,
				"y": 139.799987792969
			},
			"start_node_id": 0,
			"travel_cost": 1
		},
		"4": {
			"end_node_id": 2,
			"id": 4,
			"position": {
				"x": -95.7999877929688,
				"y": 139.799987792969
			},
			"start_node_id": 0,
			"travel_cost": 5
		},
		"5": {
			"end_node_id": 1,
			"id": 5,
			"position": {
				"x": 156.200012207031,
				"y": -11.2000122070313
			},
			"start_node_id": 2,
			"travel_cost": 5
		},
		"6": {
			"end_node_id": 0,
			"id": 6,
			"position": {
				"x": 156.200012207031,
				"y": -11.2000122070313
			},
			"start_node_id": 2,
			"travel_cost": 5
		},
		"11": {
			"end_node_id": 7,
			"id": 11,
			"position": {
				"x": 188.200012207031,
				"y": 122.799987792969
			},
			"start_node_id": 1,
			"travel_cost": 1
		},
		"12": {
			"end_node_id": 1,
			"id": 12,
			"position": {
				"x": 156.200012207031,
				"y": 261.799987792969
			},
			"start_node_id": 7,
			"travel_cost": 1
		}
	},
	"nodes": {
		"0": {
			"danger_level": 1,
			"features": 1,
			"id": 0,
			"location_name": "Farm",
			"location_type": 1,
			"position": {
				"x": -173.799987792969,
				"y": 109.799987792969
			}
		},
		"1": {
			"danger_level": 1,
			"features": 15,
			"id": 1,
			"location_name": "Great Town",
			"location_type": 0,
			"position": {
				"x": 110.200012207031,
				"y": 92.7999877929688
			}
		},
		"2": {
			"danger_level": 7,
			"features": 4,
			"id": 2,
			"location_name": "Dragon's Lair",
			"location_type": 2,
			"position": {
				"x": 78.2000122070313,
				"y": -41.2000122070313
			}
		},
		"7": {
			"danger_level": 4,
			"features": 4,
			"id": 7,
			"location_name": "Dark Forest",
			"location_type": 3,
			"position": {
				"x": 78.2000122070313,
				"y": 231.799987792969
			}
		}
	}
}