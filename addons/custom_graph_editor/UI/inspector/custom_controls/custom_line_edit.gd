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

    # ontext menu is rebuilt every time it opens, so trim it on each popup
    get_menu().about_to_popup.connect(_on_context_menu_about_to_popup)

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


func _on_context_menu_about_to_popup() -> void:
    var menu: PopupMenu = get_menu()

    var unwanted_ids: Array[int] = [
        MENU_EMOJI_AND_SYMBOL,
    ]
    for id in unwanted_ids:
        var idx: int = menu.get_item_index(id)
        if idx != -1:
            menu.remove_item(idx)

    var i: int = menu.item_count - 1
    while i >= 0:
        if menu.is_item_separator(i):
            var prev_is_sep: bool = i == 0 or menu.is_item_separator(i - 1)
            var is_last: bool = i == menu.item_count - 1
            if prev_is_sep or is_last:
                menu.remove_item(i)
        i -= 1
