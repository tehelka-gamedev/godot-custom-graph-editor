class_name CustomLineEdit
extends LineEdit

## Emitted when the text is finished to be modified, so either focus_exited or text_submitted
## Only emitted when the text actually changed !
signal text_updated(new_text: String)

# @export var notify_update_if_no_change: bool = false

var _last_text: String = ""

func _ready():
    context_menu_enabled = true
    # shortcut_keys_enabled = false # cannot delete just some of them...

    var menu : PopupMenu = get_menu()

    menu.item_count = 8

    menu.remove_item(menu.get_item_index(MENU_EMOJI_AND_SYMBOL))
    # remove separators
    menu.remove_item(0) 
    menu.remove_item(3)

    focus_exited.connect(_on_focus_exited)
    text_submitted.connect(_on_text_submitted)

func set_text_no_signal(new_text: String):
    text = new_text
    _last_text = new_text

func _on_focus_exited() -> void:
    if text != _last_text:
        _last_text = text
        self.text_updated.emit(text)

func _on_text_submitted(new_text: String) -> void:
    if new_text != _last_text:
        _last_text = new_text
        self.text_updated.emit(new_text)