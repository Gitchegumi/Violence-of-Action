extends Node

# Basic logging singleton

func info(message: String):
	print("[INFO] ", message)

func error(message: String):
	printerr("[ERROR] ", message)
