extends Node

# Thin logging facade over Godot's built-in logging functions.
#
# Note: Godot 4.5's native `Logger` class is NOT a call API — it is an abstract
# backend base class (virtuals `_log_message`/`_log_error`) that you subclass and
# register with `OS.add_logger()` to *receive* logs. The idiomatic way to *emit*
# logs is the engine globals used below (`print` / `push_warning` / `push_error`).
#
# Upgrade path (option C): make this script `extend Logger` and register it via
# `OS.add_logger()` to also capture engine output into a file or in-game console.

func info(message: String) -> void:
	print("[INFO] ", message)

func warn(message: String) -> void:
	push_warning(message)

func error(message: String) -> void:
	# push_error integrates with the debugger, the editor Errors panel, and any
	# custom Logger sink registered via OS.add_logger().
	push_error(message)

func debug(channel: String, message: String) -> void:
	# Debug logs are dev-only noise; suppress them in exported release builds.
	if OS.is_debug_build():
		print("[DEBUG][", channel, "] ", message)
