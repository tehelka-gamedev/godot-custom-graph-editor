class_name CGECompositeCommand
extends CGECommand
## CGECompositeCommand
##
## Groups several commands into one undoable command. Either all or none are applied. If one fails during the command, the previous one are undone.

var _commands: Array[CGECommand] = []

func _init(graph_ed: CGEGraphEditor, commands: Array[CGECommand]) -> void:
    super(graph_ed)
    _commands = commands

func execute() -> bool:
    # Track commands applied to undo them if one of them end to fail
    var applied: Array[CGECommand] = []

    for c in _commands:
        c._graph_editor = _graph_editor
        c._graph = _graph

        if c.execute():
            applied.append(c)
        else:
            for i in range(applied.size() - 1, -1, -1):
                applied[i].undo()
            return false
    return true

func undo() -> void:
    for i in range(_commands.size() - 1, -1, -1):
        _commands[i].undo()

func _to_string():
    return "CGECompositeCommand(%d)" % _commands.size()