@tool
class_name RumorLinkUI
extends CGEGraphLinkUI
## Visual representation of a connection between rumors.


func _setup_inspector(inspector: CGEInspectorPanel) -> void:
    var rumor_link: RumorLink = graph_element as RumorLink

    # Relationship note
    inspector.add_property(
        "Relationship",
        func(): return rumor_link.relationship_note,
        func(value: String) -> bool:
            rumor_link.relationship_note = value
            return true
    )
