@tool
class_name CGEToolBar
extends PanelContainer
## A tool bar for the Custom Graph Editor.
## 
## This is the tool bar used in the Graph Editor. It contains pop-up menus for "File" and "Edit" basic operations,
## as well as an "Add Node" button for testing.[br]
## Connect to the various signals to handle user requests.

## Emitted when the "Add Node" button is pressed
signal add_node_requested

# "File" signals
## Emitted when the user requests to save the current graph
signal save_requested
## Emitted when the user requests to save the current graph under a new name
signal save_as_requested
## Emitted when the user requests to load a graph
signal load_requested

# "Edit" signals
## Emitted when the user requests an undo
signal undo_requested
## Emitted when the user requests a redo
signal redo_requested
## Emitted when the user requests a cut   
signal cut_requested
## Emitted when the user requests a copy
signal copy_requested
## Emitted when the user requests a paste
signal paste_requested
## Emitted when the user requests a duplicate
signal duplicate_requested
## Emitted when the user requests a delete
signal delete_requested

## Pop-up menu for "File" operations
@onready var file_popup_menu: PopupMenu = %FilePopupMenu
## Pop-up menu for "Edit" operations    
@onready var edit_popup_menu: PopupMenu = %EditPopupMenu
## "Add Node" button for testing
@onready var add_node_button: Button = %NewNodeButton # Mainly here for testing, might be removed later
## Label showing the current modified file name
@onready var filename_label: Label = %FilenameLabel


func _ready() -> void:
    _init_tool_bar()


## Disable undo
func disable_undo(should_disable: bool) -> void:
    edit_popup_menu.set_item_disabled(0, should_disable)


## Disable redo
func disable_redo(should_disable: bool) -> void:
    edit_popup_menu.set_item_disabled(1, should_disable)


## Set the current modified file name
func set_filename_label(filename: String):
    filename_label.text = filename


## Mark the current file as modified or not (*)
func set_file_modified(value: bool) -> void:
    if value:
        filename_label.text = "%s(*)" % [filename_label.text]
    else:
        filename_label.text = filename_label.text.trim_suffix("(*)")


## Initialize the tool bar by add-in popup-menu items, their shortcuts and connect signals.[br]
## Override this function to customize the tool bar with more items.
func _init_tool_bar() -> void:
    # Clear existing items (important for @tool scripts with multiple instances)
    file_popup_menu.clear()
    edit_popup_menu.clear()

    # Disconnect previous signals if any (to avoid duplicate connections)
    if add_node_button.pressed.is_connected(add_node_requested.emit):
        add_node_button.pressed.disconnect(add_node_requested.emit)
    if file_popup_menu.index_pressed.is_connected(_on_file_item_pressed):
        file_popup_menu.index_pressed.disconnect(_on_file_item_pressed)
    if edit_popup_menu.index_pressed.is_connected(_on_edit_item_pressed):
        edit_popup_menu.index_pressed.disconnect(_on_edit_item_pressed)

    add_node_button.pressed.connect(add_node_requested.emit)

    ## File
    file_popup_menu.add_item("Save")
    _set_item_shortcut(file_popup_menu, 0, KEY_S, true)
    file_popup_menu.add_item("Save As")
    _set_item_shortcut(file_popup_menu, 1, KEY_S, true, true)
    file_popup_menu.add_item("Load")
    _set_item_shortcut(file_popup_menu, 2, KEY_L, true)

    file_popup_menu.index_pressed.connect(_on_file_item_pressed)

    ## Edit
    edit_popup_menu.add_item("Undo")
    _set_item_shortcut(edit_popup_menu, 0, KEY_Z, true)
    edit_popup_menu.add_item("Redo")
    _set_item_shortcut(edit_popup_menu, 1, KEY_Y, true)
    edit_popup_menu.add_item("Cut")
    _set_item_shortcut(edit_popup_menu, 2, KEY_X, true)
    edit_popup_menu.add_item("Copy")
    _set_item_shortcut(edit_popup_menu, 3, KEY_C, true)
    edit_popup_menu.add_item("Paste")
    _set_item_shortcut(edit_popup_menu, 4, KEY_V, true)
    edit_popup_menu.add_item("Duplicate")
    _set_item_shortcut(edit_popup_menu, 5, KEY_D, true)
    edit_popup_menu.add_item("Delete")
    _set_item_shortcut(edit_popup_menu, 6, KEY_DELETE, false)
    
    edit_popup_menu.index_pressed.connect(_on_edit_item_pressed)


## Utility function to add a shortcut to a pop-up menu in one line
func _set_item_shortcut(popup_menu: PopupMenu, index: int, key: Key, ctrl_pressed: bool = false, shift_pressed: bool = false) -> void:
    var shortcut: Shortcut = Shortcut.new()
    var key_event = InputEventKey.new()
    key_event.keycode = key
    key_event.ctrl_pressed = ctrl_pressed
    key_event.shift_pressed = shift_pressed
    if ctrl_pressed:
        key_event.command_or_control_autoremap = true # Swaps Ctrl for Command on Mac.
    shortcut.events = [key_event]

    popup_menu.set_item_shortcut(index, shortcut)


## Called when an item in "File" is pressed (or the shortcut is used). The indexes must match the one defined in _init_tool_bar()
func _on_file_item_pressed(index: int) -> void:
    match index:
        0: save_requested.emit()
        1: save_as_requested.emit()
        2: load_requested.emit()
        _:
            push_error("Unknown index '%d'" % [index])
    

## Called when an item in "Edit" is pressed (or the shortcut is used). The indexes must match the one defined in _init_tool_bar()
func _on_edit_item_pressed(index: int) -> void:
    match index:
        0: undo_requested.emit()
        1: redo_requested.emit()
        2: cut_requested.emit()
        3: copy_requested.emit()
        4: paste_requested.emit()
        5: duplicate_requested.emit()
        6: delete_requested.emit()
        _:
            push_error("Unknown index '%d'" % [index])
