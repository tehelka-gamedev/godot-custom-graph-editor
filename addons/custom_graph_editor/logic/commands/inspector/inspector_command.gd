@abstract class_name CGEInspectorCommand
extends CGECommand


var _inspector_panel: CGEInspectorPanel = null

func _init(graph_ed: CGEGraphEditor, inspector: CGEInspectorPanel) -> void:
    super(graph_ed)
    _inspector_panel = inspector


func _refresh_inspector_property(element_id: int, prop_name: String, value: Variant) -> void:
    if not _inspector_panel:
        return

    _inspector_panel.refresh_property(element_id, prop_name, value)