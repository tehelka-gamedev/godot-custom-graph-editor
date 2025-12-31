extends GutTest
## Tests for CGECompositeCommand.
##
## 


# Copy pasted from test_command_history. #TODO: refactor this!
class MockCommand extends CGECommand:
    var execute_called: int = 0
    var undo_called: int = 0
    var should_succeed: bool = true
    var tag: String = ""
    var log: Array = []

    func _init(cmd_tag: String = "cmd", shared_log: Array = [], succeed: bool = true) -> void:
        # do not call super() because we have actually no graph here
        # super(graph_ed)
        tag = cmd_tag
        log = shared_log
        should_succeed = succeed

    func execute() -> bool:
        execute_called += 1
        log.append("exec:" + tag)
        return should_succeed

    func undo() -> void:
        undo_called += 1
        log.append("undo:" + tag)


var call_log: Array = []


func before_each() -> void:
    call_log = []


func _make(tag: String, succeed: bool = true) -> MockCommand:
    return MockCommand.new(tag, call_log, succeed)


func _composite(commands: Array) -> CGECompositeCommand:
    var typed: Array[CGECommand] = []
    for c in commands:
        typed.append(c)
    return CGECompositeCommand.new(null, typed)


# ============================================================================
# Execute
# ============================================================================

func test_execute_runs_all_children_in_forward_order() -> void:
    var a: MockCommand = _make("a")
    var b: MockCommand = _make("b")
    var c: MockCommand = _make("c")
    var composite: CGECompositeCommand = _composite([a, b, c])

    var result: bool = composite.execute()

    assert_true(result, "execute() should return true when every child succeeds")
    assert_eq(a.execute_called, 1, "child a executed once")
    assert_eq(b.execute_called, 1, "child b executed once")
    assert_eq(c.execute_called, 1, "child c executed once")
    assert_eq(call_log, ["exec:a", "exec:b", "exec:c"], "children execute in order")


func test_execute_propagates_graph_context_to_children() -> void:
    var a := _make("a")
    var b := _make("b")
    var composite := _composite([a, b])

    # Simulates CGEGraphEditor._on_inspector_command_requested injecting context
    # into the outer command only.
    var graph := CGEGraph.new()
    composite._graph = graph

    composite.execute()

    assert_eq(a._graph, graph, "composite injects its _graph into each child")
    assert_eq(b._graph, graph, "composite injects its _graph into each child")


func test_empty_composite_is_a_successful_noop() -> void:
    var composite := _composite([])

    assert_true(composite.execute(), "an empty composite succeeds trivially")
    composite.undo() # must not crash

    assert_eq(call_log, [], "nothing ran")


# ============================================================================
# Undo
# ============================================================================

func test_undo_runs_children_in_reverse_order() -> void:
    var a: MockCommand = _make("a")
    var b: MockCommand = _make("b")
    var c: MockCommand = _make("c")
    var composite: CGECompositeCommand = _composite([a, b, c])
    composite.execute()
    call_log.clear()

    composite.undo()

    assert_eq(a.undo_called, 1, "child a undone once")
    assert_eq(b.undo_called, 1, "child b undone once")
    assert_eq(c.undo_called, 1, "child c undone once")
    assert_eq(call_log, ["undo:c", "undo:b", "undo:a"], "children undo in reverse order")


# ============================================================================
# Failure / rollback
# ============================================================================

func test_failing_child_rolls_back_applied_children_and_stops() -> void:
    var a := _make("a")
    var b := _make("b", false) # fails
    var c := _make("c")
    var composite := _composite([a, b, c])

    var result := composite.execute()

    assert_false(result, "execute() should return false when a child fails")
    assert_eq(c.execute_called, 0, "commands after the failing one are never executed")
    assert_eq(a.undo_called, 1, "the already-applied child is rolled back")
    assert_eq(b.undo_called, 0, "the failing child reported no change, so it is not undone")
    assert_eq(call_log, ["exec:a", "exec:b", "undo:a"])


func test_first_child_failure_executes_nothing_else_and_rolls_back_nothing() -> void:
    var a := _make("a", false)
    var b := _make("b")
    var composite := _composite([a, b])

    var result := composite.execute()

    assert_false(result, "execute() should return false")
    assert_eq(b.execute_called, 0, "later children are not executed")
    assert_eq(a.undo_called, 0, "nothing was applied, so nothing is rolled back")
    assert_eq(call_log, ["exec:a"])


func test_rollback_happens_in_reverse_order_of_application() -> void:
    var a := _make("a")
    var b := _make("b")
    var c := _make("c", false) # third child fails
    var composite := _composite([a, b, c])

    composite.execute()

    assert_eq(call_log, ["exec:a", "exec:b", "exec:c", "undo:b", "undo:a"],
        "applied children roll back last-applied-first")
