extends Node

var _player: Node
var _start_time: float = 0.0
var _events: Array = []
var _samples: Array = []
var _action_queue: Array = []
var _frame_count: int = 0
var _active_input: String = ""
var _input_release_frame: int = -1
var _config: Dictionary = {}
var _test_duration: float = 20.0

const SAMPLE_RATE: float = 10.0

func _ready() -> void:
	if not _load_config():
		push_error("Failed to load debug_config.json")
		get_tree().quit()
		return

	# Try to find the player/target node (movement game uses group, others use target_node)
	_player = null

	var player_group = _config.get("player_group", "")
	var target_node = _config.get("target_node", "")

	if player_group and player_group != "":
		_player = get_tree().get_first_node_in_group(player_group)
		if not _player:
			push_error("Player not found in group: %s" % player_group)
			get_tree().quit()
			return
	elif target_node and target_node != "":
		_player = get_tree().root.find_child(target_node, true, false)
		if not _player:
			push_error("Target node not found: %s" % target_node)
			get_tree().quit()
			return
	else:
		push_error("Neither 'player_group' nor 'target_node' is configured")
		get_tree().quit()
		return

	_test_duration = _config.get("test_duration_seconds", 20.0)
	_start_time = Time.get_ticks_msec() / 1000.0
	_schedule_actions()
	print("🧪 TEST AUTOPLAY STARTED - Duration: %ds\n" % int(_test_duration))

func _load_config() -> bool:
	var config_path = "res://debug_config.json"

	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		push_error("Cannot load debug_config.json")
		return false

	var json_string = file.get_as_text()
	var json = JSON.new()
	if json.parse(json_string) != OK:
		push_error("Invalid JSON in debug_config.json")
		return false

	_config = json.data
	if not _config:
		_config = {}

	# Validate: either player_group or target_node must be present
	var has_player_group = _config.has("player_group") and _config.player_group != ""
	var has_target_node = _config.has("target_node") and _config.target_node != ""

	if not has_player_group and not has_target_node:
		push_error("debug_config.json must have either 'player_group' or 'target_node'")
		return false

	if not _config.has("input_actions_to_fuzz"):
		_config.input_actions_to_fuzz = []

	if not _config.has("invariants"):
		_config.invariants = []

	return true

func _schedule_actions() -> void:
	var time: float = 0.0
	var input_actions = _config.get("input_actions_to_fuzz", [])

	if input_actions.is_empty():
		push_warning("No input_actions_to_fuzz configured; autoplay will do nothing")
		return

	var action_idx: int = 0

	while time < _test_duration:
		var action_name = input_actions[action_idx % input_actions.size()]
		_action_queue.append({"time": time, "action": action_name})
		time += randf_range(0.8, 1.5)
		action_idx += 1

func _physics_process(delta: float) -> void:
	if not _player:
		return

	var elapsed := (Time.get_ticks_msec() / 1000.0) - _start_time
	_frame_count += 1

	# Handle input release timing
	if _frame_count == _input_release_frame:
		if _active_input:
			Input.action_release(_active_input)
			_active_input = ""

	# Sample game state at fixed rate
	if _frame_count % int(60.0 / SAMPLE_RATE) == 0:
		_sample_state(elapsed)

	# Execute queued actions
	while _action_queue and _action_queue[0]["time"] <= elapsed:
		var action = _action_queue.pop_front()
		_execute_action(action["action"], elapsed)

	# End test when duration reached
	if elapsed >= _test_duration:
		_finish_test()
		get_tree().quit()

func _execute_action(action_name: String, elapsed: float) -> void:
	# Generic fuzz: just press the action, hold for a random short duration, release
	# No semantic gating (no "is_on_floor" checks, etc.)
	if Input.is_action_defined(action_name):
		Input.action_press(action_name)
		_active_input = action_name
		_input_release_frame = _frame_count + randi_range(1, 8)  # Hold 1-8 frames
		_log_event(action_name, {}, elapsed)
	else:
		push_warning("Action not defined: %s" % action_name)

func _sample_state(elapsed: float) -> void:
	var sample = {
		"time": elapsed
	}

	var violations: Array = []

	# Sample all invariants
	var invariants = _config.get("invariants", [])
	for invariant in invariants:
		var property_path = invariant.get("property", "")
		var min_val = invariant.get("min", 0.0)
		var max_val = invariant.get("max", 100.0)

		var value = _get_property_value(property_path)
		if value != null:
			sample[property_path] = value

			if value < min_val or value > max_val:
				violations.append({
					"property": property_path,
					"value": value,
					"bounds": [min_val, max_val]
				})

	if violations.size() > 0:
		sample["violations"] = violations

	_samples.append(sample)

func _get_property_value(path: String) -> Variant:
	# Resolve dotted property paths (e.g. "position.x")
	var parts = path.split(".")
	var current = _player

	for part in parts:
		if current == null:
			return null

		if current.has_meta(part):
			current = current.get_meta(part)
		elif current is Dictionary and part in current:
			current = current[part]
		elif current.get(part) != null:
			current = current.get(part)
		else:
			return null

	return current

func _log_event(action_type: String, data: Dictionary, elapsed: float) -> void:
	var event = {
		"type": action_type,
		"time": elapsed,
		"data": data
	}
	_events.append(event)

func _finish_test() -> void:
	var duration := (Time.get_ticks_msec() / 1000.0) - _start_time
	var input_actions = _config.get("input_actions_to_fuzz", [])
	var action_counts = {}

	# Initialize counts
	for action in input_actions:
		action_counts[action] = 0

	# Count events
	for event in _events:
		if event["type"] in action_counts:
			action_counts[event["type"]] += 1

	# Count violations
	var violations_total = 0
	var invariants_checked = {}
	for sample in _samples:
		if sample.has("violations"):
			violations_total += sample["violations"].size()

		# Track which invariants had issues
		for invariant in _config.get("invariants", []):
			var prop = invariant.get("property", "")
			if prop not in invariants_checked:
				invariants_checked[prop] = {"violations": 0, "samples": 0}
			invariants_checked[prop]["samples"] += 1

	# Rebuild invariants_checked with violation counts
	for sample in _samples:
		if sample.has("violations"):
			for violation in sample["violations"]:
				if violation["property"] in invariants_checked:
					invariants_checked[violation["property"]]["violations"] += 1

	# Calculate average values for invariants
	var invariant_stats = {}
	for invariant in _config.get("invariants", []):
		var prop = invariant.get("property", "")
		var values = []
		for sample in _samples:
			if prop in sample:
				values.append(sample[prop])

		if values.size() > 0:
			var avg = 0.0
			var min_obs = values[0]
			var max_obs = values[0]
			for val in values:
				avg += val
				min_obs = min(min_obs, val)
				max_obs = max(max_obs, val)
			avg /= values.size()
			invariant_stats[prop] = {"average": avg, "min": min_obs, "max": max_obs}

	# Write to project directory
	var log_path = "res://.test_log.json"
	var file = FileAccess.open(log_path, FileAccess.WRITE)
	if file:
		var test_log = {
			"duration": duration,
			"actions_performed": action_counts,
			"samples": _samples.size(),
			"invariants": invariant_stats,
			"violations": violations_total,
			"events_logged": _events.size()
		}
		file.store_string(JSON.stringify(test_log))

	# Print summary
	print("\n" + "=".repeat(50))
	print("🧪 TEST RESULTS")
	print("=".repeat(50))
	print("Duration: %.2fs" % duration)
	print("\nActions Performed:")
	for action in input_actions:
		if action in action_counts:
			print("  %s: %d" % [action, action_counts[action]])
	var total = 0
	for count in action_counts.values():
		total += count
	print("  Total Actions: %d" % total)

	print("\nInvariants Checked:")
	for prop in invariant_stats.keys():
		var stats = invariant_stats[prop]
		print("  %s: min=%.2f, avg=%.2f, max=%.2f" % [prop, stats["min"], stats["average"], stats["max"]])

	print("\nViolations Found: %d" % violations_total)
	print("Events Logged: %d" % _events.size())
	print("=".repeat(50))

	if violations_total == 0:
		print("✅ No bugs detected!")
	else:
		print("❌ Found %d violation(s)!" % violations_total)

	print("✅ Test complete!")
