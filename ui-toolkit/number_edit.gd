class_name NumberEdit
extends LineEdit
## Provides a LineEdit control specialized for editing numbers. Provides a value property typed as
## a float, disallows entry of non-numeric characters in the field, allows the field to be 
## restricted as to the number of decimal places, and allows dragging on the field to change the 
## value.

signal value_changed(new_value: float)

@onready var slider: ColorRect = $Slider
@onready var cursor: ColorRect = $Slider/Cursor

var value: float = 0.0:
	set(v):
		if decimals > 1:
			v = int(v * 10.0 * decimals) / (10.0 * decimals)
		elif decimals == 0:
			v = roundf(v)

		value = clampf(v, minimum, maximum)	
		value_changed.emit(value)
		_position_cursor()


var cursor_visible: bool = false

@export var minimum: float = -INF:
	set(v):
		if decimals > 1:
			v = int(v * 10.0 * decimals) / (10.0 * decimals)
		elif decimals == 0:
			v = roundf(v)
		
		minimum = v
		_check_cursor_visibility()
		
		
@export var maximum: float = INF:
	set(v):
		if decimals > 1:
			v = int(v * 10.0 * decimals) / (10.0 * decimals)
		elif decimals == 0:
			v = roundf(v)
		
		maximum = v
		_check_cursor_visibility()
		
		
@export var step: float = 0.1
@export var decimals: int = -1:
	set(d):
		decimals = d

var window_height: int = 800
var window_width: int = 600
var start_value: float
var start_position: float
var last_position: float
var sliding: bool
var from_lower_bound: bool
var from_upper_bound: bool

func _ready() -> void:
	text_changed.connect(_position_cursor)


func _on_resized():
	if not is_node_ready(): 
		await ready

	slider.position.y = size.y - slider.size.y
	slider.size.x = size.x
	_position_cursor()
	var vpt_size = get_viewport_rect()
	window_height = vpt_size.size.y
	window_width = vpt_size.size.x


func _check_cursor_visibility() -> void:
	if not is_node_ready(): 
		await ready
	
	cursor_visible = abs(minimum) != INF and abs(maximum) != INF
	slider.visible = cursor_visible


func _position_cursor():
	if not is_node_ready(): 
		await ready

	if value < minimum:
		cursor.position.x = 0
		return
	if value > maximum:
		cursor.position.x = cursor.size.x - slider.size.x
		return
	
	var offset: float = (value - minimum) / (maximum - minimum)
	cursor.position.x = lerpf(0, slider.size.x - cursor.size.x, offset)


func _on_value_changed() -> void:
	_position_cursor()


func _on_text_submitted(new_text):
	await get_tree().process_frame
	release_focus()


func _on_text_changed(new_text: String):
	if not is_node_ready(): 
		await ready
	
	if not new_text.is_valid_float():
		if new_text == "":
			new_text = "0"
			
	var cp := caret_column
		
	value = new_text.to_float()
	text = new_text
	await get_tree().process_frame
	caret_column = cp


func _gui_input(event):
	if !$Slider.visible or !sliding and !editable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if event.double_click:
				await get_tree().process_frame
				select_all()
			else:
				last_position = event.position.x
				start_position = last_position
				start_value = value
				sliding = true
				from_lower_bound = value <= minimum
				from_upper_bound = value >= maximum
				editable = false
				selecting_enabled = false
		else:
			sliding = false
			editable = true
			selecting_enabled = true
	elif sliding and event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		last_position = event.position.x
		var delta : float = last_position-start_position
		var current_step = step
		if event.ctrl_pressed:
			delta *= 0.2
		elif event.shift_pressed:
			delta *= 5.0
		if event.alt_pressed:
			current_step *= 0.01
		var v : float = start_value+sign(delta)*pow(abs(delta)*0.005, 2)*abs(maximum - minimum)
		if current_step != 0:
			v = minimum+floor((v - minimum)/current_step)*current_step
		if !from_lower_bound and v < minimum:
			v = minimum
		if !from_upper_bound and v > maximum:
			v = maximum
		value = v
		text = String.num(value)
		accept_event()
		
