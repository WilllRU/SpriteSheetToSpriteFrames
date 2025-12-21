@tool
extends Control


@onready var sprite_input : LineEdit = $VBoxContainer/SpriteSheet/LineEdit
@onready var data_input : LineEdit = $VBoxContainer/JsonData/LineEdit
@onready var export_input : LineEdit = $VBoxContainer/TabContainer/Create/ExportPath/LineEdit
@onready var export_name_input : LineEdit = $VBoxContainer/TabContainer/Create/ExportName/LineEdit
@onready var resource_input: LineEdit = $VBoxContainer/TabContainer/Append/ResourcePath/LineEdit

@onready var tab_container : TabContainer = $VBoxContainer/TabContainer

@onready var info_prompt : RichTextLabel = $VBoxContainer/RichTextLabel

@onready var append_button : Button = $VBoxContainer/AppendButton
@onready var convert_button : Button = $VBoxContainer/ConvertButton


@onready var overwrite_existing : CheckBox = $VBoxContainer/TabContainer/Append/CheckBox

@onready var ignore_fps : CheckBox = $VBoxContainer/ExportOptions/CheckBox
@onready var override_fps : SpinBox = $VBoxContainer/ExportOptions/SpinBox


func _ready() -> void:
	# Inputs
	sprite_input.text_submitted.connect(check_input)
	data_input.text_submitted.connect(check_input)
	export_input.text_submitted.connect(check_input)
	resource_input.text_submitted.connect(check_input)
	
	tab_container.tab_changed.connect(switch_tab)
	
	# Buttons
	convert_button.pressed.connect(convert_sheet_to_sprite_frames)
	append_button.pressed.connect(append_to_sprite_frames)
	
	# Options
	ignore_fps.toggled.connect(override_fps.set_editable)
	
	switch_tab(tab_container.current_tab)
	override_fps.set_editable(ignore_fps.button_pressed)

func switch_tab(tab : int) -> void:
	check_input()
	if tab == 0:
		convert_button.show()
		append_button.hide()
	if tab == 1:
		convert_button.hide()
		append_button.show()

func check_input(_path : String = "") -> void:
	#var sprite_path : String = sprite_input.text.get_base_dir()
	#var data_path : String = data_input.text.get_base_dir()
	var export_path : String = export_input.text.get_base_dir()
	var export_dir : DirAccess = DirAccess.open(export_path)
	
	var error_count : int = 0
	convert_button.disabled = false
	append_button.disabled = false
	
	info_prompt.text = ""
	
	if tab_container.current_tab == 0:
		if export_input.text.is_empty():
			error_count += 1
		
		if not export_input.text.is_empty() and export_dir == null:
			info_prompt.append_text("Can't export to path. Directory: \"%s\" does not exist\n" % export_path)
			error_count += 1
	else:
		if resource_input.text.is_empty():
			error_count += 1
		
		if not resource_input.text.is_empty() and not ResourceLoader.exists(resource_input.text, "SpriteFrames"):
			info_prompt.append_text("Could not find SpriteFrame Resource in directory: \"%s\"\n" % resource_input)
			error_count += 1
	
	if not FileAccess.file_exists(sprite_input.text) and not sprite_input.text.is_empty():
		info_prompt.append_text("Path: \"%s\" is not an existing file path\n" % sprite_input.text)
		error_count += 1
	
	if not FileAccess.file_exists(data_input.text) and not data_input.text.is_empty():
		info_prompt.append_text("Path: \"%s\" is not an existing file path\n" % data_input.text)
		error_count += 1
	
	
	if data_input.text.is_empty():
		error_count += 1
	if sprite_input.text.is_empty():
		error_count += 1
	
	if error_count > 0:
		convert_button.disabled = true
		append_button.disabled = true
		return

#region Convert SpriteSheet and Data to Resource

func convert_sheet_to_sprite_frames() -> void:
	var json_file : FileAccess = FileAccess.open(data_input.text, FileAccess.READ)
	var json_data : Dictionary = JSON.parse_string(json_file.get_as_text())
	
	var sprite_sheet : Texture = load(sprite_input.text)
	if sprite_sheet == null:
		info_prompt.parse_bbcode("COULD NOT LOAD TEXTURE!")
		return
	
	var sprite_frames : SpriteFrames = create_sprite_frames(json_data, sprite_sheet)
	
	sprite_frames.resource_name = data_input.text.get_file().get_slice(".", 0)
	if export_name_input.text.is_valid_filename():
		sprite_frames.resource_name = export_name_input.text
	
	ResourceSaver.save(sprite_frames, export_input.text.get_base_dir() + "/" + sprite_frames.resource_name + ".tres")
	info_prompt.append_text("\nSpriteFrame Resource: \"%s\" Created\n" % sprite_frames.resource_name)

func dict_to_rect2i(dict : Dictionary) -> Rect2i:
	return Rect2i(dict.get("x", 0), dict.get("y", 0), dict.get("w", 0), dict.get("h", 0))

func create_sprite_frames(data : Dictionary, sprite_sheet : Texture) -> SpriteFrames:
	var sprite_frames_resource : SpriteFrames = SpriteFrames.new()
	
	var frames_data : Dictionary = data.get("frames", {})
	if frames_data.is_empty():
		info_prompt.parse_bbcode("COULD NOT FIND ANY FRAME DATA")
		return
	var tag_name : StringName = ""
	var frame_rate : float = 10
	
	for k in frames_data.keys():
		assert(k as String)
		var frame_name : String = k.get_slice("#", 1)
		var tag_index : int = 0
		var cur_tag_name : StringName = frame_name.replace(".aseprite", "")
		
		print(cur_tag_name)
		var string_index : float = 0.0
		# Used to get the value of the frame from the tag
		for n in cur_tag_name.length() - 1:
			var str_section : String = cur_tag_name.right(n + 1)
			if not str_section.is_valid_int():
				break
			if str_section.contains(" "):
				break
			
			string_index += 1
		
		if string_index > 0:
			tag_index = cur_tag_name.right(string_index).to_int()
			cur_tag_name = cur_tag_name.left(-string_index)
		cur_tag_name = cur_tag_name.to_upper()
		
		var frame_dict : Dictionary = frames_data.get(k, {})
		var frame_ms : float = frame_dict.get("duration", 100.0)
		var frame_speed : float = roundf(1000.0 / frame_ms)
		
		var frame_duration : float = 1.0
		
		
		if tag_name != cur_tag_name:
			tag_name = cur_tag_name
			
			frame_rate = frame_speed
			if ignore_fps.button_pressed:
				frame_rate = override_fps.value
			
			print(frame_rate, " FPS for: ", tag_name)
			
			sprite_frames_resource.add_animation(cur_tag_name)
			sprite_frames_resource.set_animation_speed(cur_tag_name, frame_rate)
		
		var atlas_rect : Rect2i = dict_to_rect2i(frame_dict.get("frame", {}))
		var atlas_texture : AtlasTexture = AtlasTexture.new()
		atlas_texture.atlas = sprite_sheet
		atlas_texture.region = atlas_rect
		
		
		if not ignore_fps.button_pressed:
			frame_duration = frame_speed/frame_rate
		
		sprite_frames_resource.add_frame(tag_name, atlas_texture, frame_duration)
	
	sprite_frames_resource.remove_animation("default")
	return sprite_frames_resource

#endregion

#region Append to SpriteFrames Resource
func append_to_sprite_frames() -> void:
	
	var json_file : FileAccess = FileAccess.open(data_input.text, FileAccess.READ)
	var json_data : Dictionary = JSON.parse_string(json_file.get_as_text())
	
	var sprite_sheet : Texture = load(sprite_input.text)
	if sprite_sheet == null:
		info_prompt.parse_bbcode("COULD NOT LOAD TEXTURE!")
		return
	
	var sprite_frames_og : SpriteFrames = load(resource_input.text)
	var sprite_frames : SpriteFrames = update_sprite_frames(json_data, sprite_sheet, sprite_frames_og)
	
	var res_name : String = resource_input.text.get_file()
	print(res_name)
	
	sprite_frames.resource_name = res_name.get_slice(".", 0)
	
	ResourceSaver.save(sprite_frames, resource_input.text.get_base_dir()+"/" + sprite_frames.resource_name + ".tres")
	info_prompt.append_text("\nSpriteFrame Resource: \"%s\" Created\n" % sprite_frames.resource_name)

func update_sprite_frames(data : Dictionary, sprite_sheet : Texture, sprite_frames_res : SpriteFrames) -> SpriteFrames:
	var frames_data : Dictionary = data.get("frames", {})
	if frames_data.is_empty():
		info_prompt.parse_bbcode("COULD NOT FIND ANY FRAME DATA")
		return
	var tag_name : StringName = ""
	var frame_rate : float = 10
	
	for k in frames_data.keys():
		assert(k as String)
		var frame_name : String = k.get_slice("#", 1)
		var tag_index : int = 0
		var cur_tag_name : StringName = frame_name.replace(".aseprite", "")
		
		print(cur_tag_name)
		var string_index : float = 0.0
		# Used to get the value of the frame from the tag
		for n in cur_tag_name.length() - 1:
			var str_section : String = cur_tag_name.right(n + 1)
			if not str_section.is_valid_int():
				break
			if str_section.contains(" "):
				break
			
			string_index += 1
		
		if string_index > 0:
			tag_index = cur_tag_name.right(string_index).to_int()
			cur_tag_name = cur_tag_name.left(-string_index)
		cur_tag_name = cur_tag_name.strip_edges()
		cur_tag_name = cur_tag_name.to_upper()
		
		var frame_dict : Dictionary = frames_data.get(k, {})
		var frame_ms : float = frame_dict.get("duration", 100.0)
		var frame_speed : float = roundf(1000.0 / frame_ms)
		
		var frame_duration : float = 1.0
		
		
		if tag_name != cur_tag_name:
			tag_name = cur_tag_name
			
			frame_rate = frame_speed
			if ignore_fps.button_pressed:
				frame_rate = override_fps.value
			
			print(frame_rate, " FPS for: ", tag_name)
			
			var add_anim : bool = false
			
			var anims : PackedStringArray = sprite_frames_res.get_animation_names()
			if anims.has(cur_tag_name):
				if overwrite_existing.button_pressed:
					sprite_frames_res.remove_animation(cur_tag_name)
					add_anim = true
			else: 
				add_anim = true
			
			if add_anim:
				sprite_frames_res.add_animation(cur_tag_name)
				sprite_frames_res.set_animation_speed(cur_tag_name, frame_rate)
			
		var atlas_rect : Rect2i = dict_to_rect2i(frame_dict.get("frame", {}))
		var atlas_texture : AtlasTexture = AtlasTexture.new()
		atlas_texture.atlas = sprite_sheet
		atlas_texture.region = atlas_rect
		
		
		if not ignore_fps.button_pressed:
			frame_duration = frame_speed/frame_rate
		
		sprite_frames_res.add_frame(tag_name, atlas_texture, frame_duration)
	
	
	return sprite_frames_res
#endregion
