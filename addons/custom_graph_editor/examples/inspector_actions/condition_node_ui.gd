@tool
class_name ConditionNodeUI
extends CGEGraphNodeUI
## Visual representation of a ConditionNode.
##
## This demonstrates how the inspector is setup with custom constrols (action buttons and a label).

## Expression applied by the "Apply preset: blocked" button.
const PRESET_BLOCKED_EXPRESSION: String = "state == BLOCKED"

@export var background_color: Color = Color(0.22, 0.32, 0.40, 0.95)

@onready var name_label: Label = %NameLabel
@onready var summary_label: Label = %SummaryLabel


func _ready() -> void:
    custom_minimum_size = Vector2(170, 84)
    _refresh_labels()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), background_color, true)

    var border_color: Color = Color(0.85, 0.85, 0.85, 1.0) if selected else Color(0.5, 0.5, 0.5, 1.0)
    var border_width: float = 3.0 if selected else 1.5
    draw_rect(Rect2(Vector2.ZERO, size), border_color, false, border_width)


func _update_ui_from_data() -> void:
    _refresh_labels()


func _refresh_labels() -> void:
    var condition_node: ConditionNode = graph_element as ConditionNode
    if condition_node == null:
        return
    if name_label:
        name_label.text = "%s" % [condition_node.node_name]
    if summary_label:
        var expression: String = condition_node.condition_expression
        summary_label.text = expression if not expression.is_empty() else "<no condition>"


func _setup_inspector(inspector: CGEInspectorPanel) -> void:
    var condition_node: ConditionNode = graph_element as ConditionNode

    # A regular row editable
    inspector.add_property(
        "Name",
        func(): return condition_node.node_name,
        func(value: String) -> bool:
            if value.strip_edges().is_empty():
                return false
            condition_node.node_name = value
            _refresh_labels()
            return true
    )

    # We want to be able to edit condition of single nodes selected only
    if inspector.get_selection().size() == 1:
        inspector.add_action_button(
            "edit_condition",
            "Edit condition...",
            func(selection: Array): _open_condition_editor(inspector, selection),
            {
                "label": "Condition",
                "tooltip": "Open the condition editor for this node",
            }
        )

    # Whatever the number of selected nodes, however, we want to be able to apply a preset (another action button)
    inspector.add_action_button(
        "apply_preset_blocked",
        "Apply preset: blocked",
        func(selection: Array): _apply_preset(inspector, selection, PRESET_BLOCKED_EXPRESSION),
        {
            "label": "Preset",
            "tooltip": "Set every selected node's condition to \"%s\"" % PRESET_BLOCKED_EXPRESSION,
        }
    )

    # Some note control to display in the inspector
    var note: RichTextLabel = RichTextLabel.new()
    note.bbcode_enabled = true
    note.fit_content = true
    note.custom_minimum_size = Vector2(0, 44)
    note.text = "[i]Edit the full expression with the button above.\nPresets apply to every selected node.[/i]"
    inspector.add_custom_control("condition_help", note, "Help")


## Action callbacks
## These are the actions called by the actions buttons in the inspector


## Opens a small editor window
func _open_condition_editor(inspector: CGEInspectorPanel, selection: Array) -> void:
    if selection.is_empty():
        return
    var element_ui: CGEGraphElementUI = selection[0]
    if not is_instance_valid(element_ui):
        return
    var node: ConditionNode = element_ui.graph_element as ConditionNode
    if node == null:
        return

    var dialog: AcceptDialog = AcceptDialog.new()
    dialog.title = "Edit condition: %s" % node.node_name
    dialog.min_size = Vector2i(440, 280)
    dialog.ok_button_text = "Apply"

    var text_editor := TextEdit.new()
    text_editor.text = node.condition_expression
    text_editor.placeholder_text = "e.g. player.gold >= 100 and not quest.completed"
    text_editor.custom_minimum_size = Vector2(420, 200)
    dialog.add_child(text_editor)

    dialog.confirmed.connect(
        func() -> void:
            _commit_condition(inspector, element_ui.get_id(), node.condition_expression, text_editor.text),
        CONNECT_ONE_SHOT
    )
    
    # Make sure the dialog is queue_free
    dialog.visibility_changed.connect(
        func() -> void:
            if not dialog.visible:
                dialog.queue_free()
    )

    inspector.add_child(dialog)
    dialog.popup_centered()


## Helper to set a condition to the undo/redo system
func _commit_condition(inspector: CGEInspectorPanel, element_id: int, old_expression: String, new_expression: String) -> void:
    if old_expression == new_expression:
        return
    inspector.submit_command(SetConditionCommand.new(element_id, old_expression, new_expression))


## Applies `preset_expression` to every selected node
func _apply_preset(inspector: CGEInspectorPanel, selection: Array, preset_expression: String) -> void:
    var commands: Array[CGECommand] = []
    for element_ui in selection:
        if not is_instance_valid(element_ui):
            continue
        var node: ConditionNode = element_ui.graph_element as ConditionNode
        if node == null or node.condition_expression == preset_expression:
            continue
        commands.append(SetConditionCommand.new(
            element_ui.get_id(),
            node.condition_expression,
            preset_expression
        ))

    if commands.is_empty():
        return
    if commands.size() == 1:
        inspector.submit_command(commands[0])
    else:
        # _graph_editor is injected by the editor.
        inspector.submit_command(CGECompositeCommand.new(null, commands))


## Custom command
## Ideally it's in another file, but for this example I've put it here

## Sets a ConditionNode's condition_expression.
class SetConditionCommand extends CGECommand:
    var _element_id: int
    var _old_expression: String
    var _new_expression: String


    func _init(element_id: int, old_expression: String, new_expression: String) -> void:
        _element_id = element_id
        _old_expression = old_expression
        _new_expression = new_expression


    func execute() -> bool:
        return _apply(_new_expression)


    func undo() -> void:
        _apply(_old_expression)


    func _apply(expression: String) -> bool:
        var element_ui: CGEGraphElementUI = _graph_editor.get_graph_element(_element_id)
        if element_ui == null:
            push_warning("SetConditionCommand: element %d not found" % _element_id)
            return false
        var node: ConditionNode = element_ui.graph_element as ConditionNode
        if node == null:
            return false
        node.condition_expression = expression
        element_ui._update_ui_from_data()
        return true


    func _to_string() -> String:
        return "SetConditionCommand(id:%d)" % _element_id
