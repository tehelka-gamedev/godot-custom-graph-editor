extends GutTest

# Mock command for testing
class MockCommand extends CGECommand:
    var execute_called: int = 0
    var undo_called: int = 0
    var should_succeed: bool = true
    var name: String = ""

    func _init(graph_ed = null, cmd_name: String = "MockCommand"):
        # do not call super() because we have actually no graph here
        # super(graph_ed)
        name = cmd_name

    func execute() -> bool:
        execute_called += 1
        return should_succeed

    func undo() -> void:
        undo_called += 1


var history: CGECommandHistory


func before_each():
    history = CGECommandHistory.new()


func after_each():
    history = null


# ============================================================================
# Basic Push/Pop Tests
# ============================================================================

func test_initial_state():
    assert_true(history.is_empty(), "History should be empty initially")
    assert_false(history.can_redo(), "Should not be able to redo initially")


func test_push_command():
    var cmd = MockCommand.new()
    history.push(cmd)

    assert_false(history.is_empty(), "History should not be empty after push")


func test_pop_command():
    var cmd = MockCommand.new()
    history.push(cmd)

    var popped = history.pop()

    assert_eq(popped, cmd, "Should return the pushed command")
    assert_true(history.is_empty(), "History should be empty after pop")


func test_pop_empty_history():
    var result = history.pop()
    assert_null(result, "Pop on empty history should return null")


func test_multiple_push_pop():
    var cmd1 = MockCommand.new(null, "Cmd1")
    var cmd2 = MockCommand.new(null, "Cmd2")
    var cmd3 = MockCommand.new(null, "Cmd3")

    history.push(cmd1)
    history.push(cmd2)
    history.push(cmd3)

    assert_eq(history.pop(), cmd3, "Should pop in correct order")
    assert_eq(history.pop(), cmd2, "Should pop in correct order")
    assert_eq(history.pop(), cmd1, "Should pop in correct order")
    assert_true(history.is_empty(), "History should be empty")


# ============================================================================
# Version Tracking Tests
# ============================================================================

func test_initial_version():
    assert_eq(history._current_version, 0, "Initial version should be 0")
    assert_eq(history._saved_version, 0, "Initial saved version should be 0")


func test_push_increments_version():
    var cmd = MockCommand.new()
    history.push(cmd)

    assert_eq(history._current_version, 1, "Version should increment after push")


func test_pop_decrements_version():
    var cmd = MockCommand.new()
    history.push(cmd)
    history.pop()

    assert_eq(history._current_version, 0, "Version should decrement after pop")


func test_multiple_commands_version():
    history.push(MockCommand.new())
    history.push(MockCommand.new())
    history.push(MockCommand.new())

    assert_eq(history._current_version, 3, "Version should be 3 after 3 pushes")

    history.pop()
    assert_eq(history._current_version, 2, "Version should be 2 after 1 pop")


# ============================================================================
# Redo Tests
# ============================================================================

func test_can_redo_after_undo():
    var cmd = MockCommand.new()
    history.push(cmd)
    history.pop()

    assert_true(history.can_redo(), "Should be able to redo after undo")


func test_redo_executes_command():
    var cmd = MockCommand.new()
    history.push(cmd)
    history.pop()

    # CGECommandHistory doesn't call undo() - that's GraphEditor's job
    # We just verify redo() calls execute()

    history.redo()

    # Redo should execute the command
    assert_eq(cmd.execute_called, 1, "Execute should be called during redo")
    assert_false(history.is_empty(), "Command should be back in history after redo")


func test_redo_increments_version():
    var cmd = MockCommand.new()
    history.push(cmd)  # version = 1
    history.pop()      # version = 0
    history.redo()     # version = 1

    assert_eq(history._current_version, 1, "Redo should increment version")


func test_redo_on_empty_future():
    history.redo()  # Should not crash
    assert_true(history.is_empty(), "History should remain empty")


func test_multiple_redo():
    history.push(MockCommand.new())
    history.push(MockCommand.new())
    history.push(MockCommand.new())

    history.pop()
    history.pop()

    assert_true(history.can_redo(), "Should be able to redo")
    history.redo()
    assert_eq(history._current_version, 2, "Version should be 2 after first redo")

    assert_true(history.can_redo(), "Should still be able to redo")
    history.redo()
    assert_eq(history._current_version, 3, "Version should be 3 after second redo")


func test_push_clears_future():
    var cmd1 = MockCommand.new(null, "Cmd1")
    var cmd2 = MockCommand.new(null, "Cmd2")
    var cmd3 = MockCommand.new(null, "Cmd3")

    history.push(cmd1)  # version 1
    history.push(cmd2)  # version 2
    history.pop()       # version 1, cmd2 in future

    assert_true(history.can_redo(), "Should be able to redo before push")

    history.push(cmd3)  # version 2, should clear future

    assert_false(history.can_redo(), "Should NOT be able to redo after push (future should be cleared)")


func test_push_after_multiple_undos_clears_future():
    history.push(MockCommand.new(null, "A"))
    history.push(MockCommand.new(null, "B"))
    history.push(MockCommand.new(null, "C"))

    history.pop()  # Undo C
    history.pop()  # Undo B

    assert_true(history.can_redo(), "Should have 2 commands in future")

    history.push(MockCommand.new(null, "D"))

    assert_false(history.can_redo(), "Future should be cleared after new push")


# ============================================================================
# Save State Tracking Tests
# ============================================================================

func test_is_modified_initial():
    assert_false(history.is_modified(), "Should not be modified initially")


func test_is_modified_after_push():
    history.push(MockCommand.new())
    assert_true(history.is_modified(), "Should be modified after push")


func test_mark_saved():
    history.push(MockCommand.new())
    assert_true(history.is_modified(), "Should be modified before mark_saved")

    history.mark_saved()
    assert_false(history.is_modified(), "Should not be modified after mark_saved")


func test_is_modified_after_undo_to_save_point():
    history.push(MockCommand.new())
    history.mark_saved()  # Save at version 1

    history.push(MockCommand.new())  # version 2
    assert_true(history.is_modified(), "Should be modified after new command")

    history.pop()  # Back to version 1
    assert_false(history.is_modified(), "Should not be modified after undo to save point")


func test_is_modified_redo_away_from_save_point():
    history.push(MockCommand.new())
    history.mark_saved()  # Save at version 1

    history.push(MockCommand.new())  # version 2
    history.pop()  # version 1
    assert_false(history.is_modified(), "Should not be modified at save point")

    history.redo()  # version 2
    assert_true(history.is_modified(), "Should be modified after redo away from save point")


func test_complex_undo_redo():
    # Do A, B, C
    history.push(MockCommand.new(null, "A"))  # v1
    history.push(MockCommand.new(null, "B"))  # v2
    history.push(MockCommand.new(null, "C"))  # v3
    history.mark_saved()  # Save at v3

    assert_false(history.is_modified(), "Not modified right after save")

    # Undo to A
    history.pop()  # v2
    assert_true(history.is_modified(), "Modified after undo from save point")
    history.pop()  # v1
    assert_true(history.is_modified(), "Still modified")

    # Redo to C (back to save point)
    history.redo()  # v2
    history.redo()  # v3
    assert_false(history.is_modified(), "Not modified when back at save point")

    # Do D
    history.push(MockCommand.new(null, "D"))  # v4
    assert_true(history.is_modified(), "Modified after new command")


# ============================================================================
# Signal Tests
# ============================================================================

func test_history_changed_signal_on_push():
    var signal_watcher = watch_signals(history)

    history.push(MockCommand.new())

    assert_signal_emitted(history, "history_changed", "Should emit history_changed on push")


func test_history_changed_signal_on_pop():
    var signal_watcher = watch_signals(history)
    history.push(MockCommand.new())

    signal_watcher = watch_signals(history)  # Reset watcher
    history.pop()

    assert_signal_emitted(history, "history_changed", "Should emit history_changed on pop")


func test_future_changed_signal_on_pop():
    var signal_watcher = watch_signals(history)
    history.push(MockCommand.new())

    signal_watcher = watch_signals(history)  # Reset watcher
    history.pop()

    assert_signal_emitted(history, "future_changed", "Should emit future_changed on pop")


func test_signals_on_redo():
    var signal_watcher = watch_signals(history)
    history.push(MockCommand.new())
    history.pop()

    signal_watcher = watch_signals(history)  # Reset watcher
    history.redo()

    assert_signal_emitted(history, "history_changed", "Should emit history_changed on redo")
    assert_signal_emitted(history, "future_changed", "Should emit future_changed on redo")


func test_signals_on_clear_all():
    var signal_watcher = watch_signals(history)
    history.push(MockCommand.new())

    signal_watcher = watch_signals(history)  # Reset watcher
    history.clear_all()

    assert_signal_emitted(history, "history_changed", "Should emit history_changed on clear_all")
    assert_signal_emitted(history, "future_changed", "Should emit future_changed on clear_all")


# ============================================================================
# Clear All Tests
# ============================================================================

func test_clear_all_resets_history():
    history.push(MockCommand.new())
    history.push(MockCommand.new())

    history.clear_all()

    assert_true(history.is_empty(), "History should be empty after clear_all")


func test_clear_all_resets_future():
    history.push(MockCommand.new())
    history.pop()

    history.clear_all()

    assert_false(history.can_redo(), "Future should be cleared")


func test_clear_all_resets_versions():
    history.push(MockCommand.new())
    history.push(MockCommand.new())
    history.mark_saved()

    history.clear_all()

    assert_eq(history._current_version, 0, "Current version should be 0")
    assert_eq(history._saved_version, 0, "Saved version should be 0")
    assert_false(history.is_modified(), "Should not be modified after clear_all")


# ============================================================================
# Edge Cases
# ============================================================================

func test_failed_command_execute_on_redo():
    var cmd = MockCommand.new()
    cmd.should_succeed = false

    history.push(cmd)
    history.pop()

    var version_before = history._current_version
    history.redo()

    # Current implementation: redo() checks return value of execute()
    # If it fails (returns false), command is NOT added back to history
    assert_eq(history._current_version, version_before, "Version should not change if redo execute fails")
    assert_true(history.is_empty(), "Command should not be added to history if execute fails")


func test_alternating_push_pop():
    var cmd1 = MockCommand.new(null, "1")
    var cmd2 = MockCommand.new(null, "2")
    var cmd3 = MockCommand.new(null, "3")

    history.push(cmd1)
    assert_eq(history._current_version, 1)

    history.pop()
    assert_eq(history._current_version, 0)

    history.push(cmd2)
    assert_eq(history._current_version, 1)

    history.push(cmd3)
    assert_eq(history._current_version, 2)

    history.pop()
    assert_eq(history._current_version, 1)
