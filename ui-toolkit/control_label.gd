@tool
class_name ControlLabel
extends HBoxContainer
## A control that provides a left- or right-aligned label for its child. While in the editor, any
## attempt to add a child that does not inherit from Control will fail and result in an error.

enum LABEL_ALIGNMENT {
	LEFT,
	RIGHT
}

var control: Control
@onready var label_control = $Label

@export var label: String = "Label":
	set(l):
		label = l
		if label_control != null:
			label_control.text = label

@export_range(.1, 2.0, .1) var label_scaling: float = 1.0:
	set(v):
		label_scaling = v
		if not label_control == null:
			label_control.size_flags_stretch_ratio = v
	get:
		return label_scaling

@export var label_align: LABEL_ALIGNMENT = LABEL_ALIGNMENT.LEFT:
	set(v):
		label_align = v
		_on_change_alignment()

func _ready() -> void:
	if not label_control == null:
		label_control.size_flags_stretch_ratio = label_scaling
		label_control.text = label

func _on_change_alignment() -> void:
	match label_align:
		LABEL_ALIGNMENT.LEFT:
			move_child($Label, 0)
		LABEL_ALIGNMENT.RIGHT:
			move_child($Label, get_child_count() - 1)


func _on_child_entered_tree(node):
	if not is_node_ready() or not Engine.is_editor_hint():
		return
	
	if not node is Control:
		await get_tree().process_frame
		push_error("WARNING: removed new child node; children of LabeledControl must inherit from Control")
		remove_child(node)
		return
	
	if control != null:
		remove_child(control)
		
	control = node as Control
	control.size_flags_horizontal |= Control.SIZE_EXPAND


func _on_child_exiting_tree(node):
	if not Engine.is_editor_hint():
		return
	
	if control == node:
		control = null
	
