class_name CGEDuplicateSelectionCommand
extends CGECommand
## Command to duplicate the current selection in the graph editor.
##
## This command duplicates the currently selected nodes and links in the graph editor,
## creating copies of them and selecting the newly created elements.

## Reference to the CGEPasteClipboardCommand to undo the duplicate
var _paste_clipboard_command : CGEPasteClipboardCommand = null


func _init(graph_ed: CGEGraphEditor) -> void:
    super(graph_ed)


## Duplicate the current selection
func execute() -> bool:
    var clipboard := CGEClipboard.new()
    _graph_editor._copy_selection(clipboard)
    _paste_clipboard_command = _graph_editor._paste_selection(clipboard)

    return _paste_clipboard_command != null


## Undo the duplication
func undo() -> void:
    if _paste_clipboard_command:
        _paste_clipboard_command.undo()