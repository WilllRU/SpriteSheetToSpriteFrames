@tool
extends EditorPlugin

const CONVERTER_PATH : String = "res://addons/spritesheetconverter/SpriteSheetConvereter.tscn"

var dock

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	# Load the dock scene and instantiate it.
	dock = preload(CONVERTER_PATH).instantiate()
	# Add the loaded scene to the docks.
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	# Remove the dock.
	remove_control_from_docks(dock)
	# Erase the control from the memory.
	dock.free()
	pass
