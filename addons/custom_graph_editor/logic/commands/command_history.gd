class_name CGECommandHistory
extends RefCounted
## Manages the history of commands for undo/redo functionality.
##
## This class manages the history of commands executed in the graph editor,
## allowing for undo and redo operations. It also keeps track of the current version
## of the graph to determine if it has been modified since the last save.

## Emitted when the history changes (a new command is pushed or popped) 
signal history_changed
## Emitted when the future changes (a command is redone)
signal future_changed

## Stack of executed commands
var _history: Array[CGECommand] = []
## Stack of undone commands (for redo)
var _future: Array[CGECommand] = []

## Current version number, to indicate if file is modified or not
var _current_version: int = 0
## Version number when last saved
var _saved_version: int = 0


## Push a new command to the history
func push(command: CGECommand) -> void:
    _history.append(command)
    _future.clear()
    _current_version += 1
    history_changed.emit()
    future_changed.emit()


## Redo the last undone command. Does nothing if there is no command to redo.
func redo() -> void:
    if _future.is_empty():
        return
    
    var cmd: CGECommand = _get_redo()
    if cmd.execute() == true:
        _history.append(cmd)
        _current_version += 1
        history_changed.emit()


## Remove the last command from the history and return it
func pop() -> CGECommand:
    var cmd: CGECommand = _history.pop_back()
    if cmd != null:
        _current_version -= 1
        _future.append(cmd)
        history_changed.emit()
        future_changed.emit()

    return cmd


## Emtpy the command history and future.
func clear_all() -> void:
    _history.clear()
    _future.clear()
    #  change the version before emitting, important otherwise is_modified might return the wrong value
    _current_version = 0
    _saved_version = 0
    history_changed.emit()
    future_changed.emit()


## Get the last undone command for redo and remove it from the future stack.
func _get_redo() -> CGECommand:
    var cmd: CGECommand = _future.pop_back()
    future_changed.emit()
    return cmd


## Tells if there is at least one command to undo
func can_redo() -> bool:
    return not _future.is_empty()


## Returns true if there is no command in the history
func is_empty() -> bool:
    return _history.is_empty()


## Mark the current state as saved. Useful to track modifications up to or since the last save.
func mark_saved() -> void:
    _saved_version = _current_version


## Tells if the file modified has been modified or not, given the current command history
func is_modified() -> bool:
    return _current_version != _saved_version
