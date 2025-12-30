@tool
class_name RumorLink
extends CGEGraphLink
## Represents a connection between two rumors in the knowledge graph.

## Optional note about the relationship
var relationship_note: String = ""


func serialize() -> Dictionary:
    var data: Dictionary = super()
    data["relationship_note"] = relationship_note
    return data


func deserialize(data: Dictionary) -> void:
    super(data)
    if data.has("relationship_note"):
        relationship_note = data["relationship_note"]


func _to_string() -> String:
    return "RumorLink(id:%d, %d->%d)" % [id, start_node_id, end_node_id]
