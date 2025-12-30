@tool
class_name RumorNode
extends CGEGraphNode
## Represents a rumor/clue entry in the knowledge graph.
##
## Inspired by Outer Wilds' ship log system.

## Categories for rumors
enum Category {
    LOCATION,
    CHARACTER,
    MYSTERY,
    ARTIFACT,
    EVENT
}

## Name of the rumor/location
var rumor_name: String = "Unknown"

## Whether this rumor has been discovered yet
var discovered: bool = false

## Path to the image (shown when discovered)
var image_path: String = ""

## Category of this rumor
var category: Category = Category.MYSTERY

## List of clue texts discovered for this rumor
var clues: Array[String] = []


func serialize() -> Dictionary:
    var data: Dictionary = super()
    data["rumor_name"] = rumor_name
    data["discovered"] = discovered
    data["image_path"] = image_path
    data["category"] = category
    data["clues"] = clues.duplicate()
    return data


func deserialize(data: Dictionary) -> void:
    super(data)
    if data.has("rumor_name"):
        rumor_name = data["rumor_name"]
    if data.has("discovered"):
        discovered = data["discovered"]
    if data.has("image_path"):
        image_path = data["image_path"]
    if data.has("category"):
        category = data["category"]
    if data.has("clues"):
        clues = data["clues"].duplicate()


func _to_string() -> String:
    return "RumorNode(id:%d, name:'%s', discovered:%s, clues:%d)" % [id, rumor_name, discovered, clues.size()]
