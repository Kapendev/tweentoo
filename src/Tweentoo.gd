class_name Tweentoo
extends Tween

# Author: AlexandrosKap
# License: MIT
# Description: A simple tween script for moving, rotating and scaling Node2D or Spatial nodes.
# How to use:
# 1) Add a Tweentoo to a Node2D/Spatial.
# 2) Add Node2D/Spatial nodes to the Tweentoo.
# 3) Play the scene or call change().
# Extra: You can also change the modulate and self_modulate property of Node2D nodes.

signal tweentoo_completed
signal tweentoo_started

enum TransitionType {LINEAR = 0, CUBIC = 7, CIRC = 8, ELASTIC = 6, BOUNCE = 9, BACK = 10}
enum EaseType {IN_OUT = 2, OUT_IN = 3, IN = 0, OUT = 1}

export var reversed_change := false setget set_reversed_change
export var can_start := true
export var can_loop := true
export var update_position := true
export var update_rotation := true
export var update_scale := true

export(TransitionType) var transition := TransitionType.LINEAR
export(EaseType) var easing := EaseType.IN_OUT
export(float, 0, 172800) var duration := 1.0
export(Array, float) var duration_array := []

var current_child := -1
var current_duration := 0
var is_2D := true
var is_changing := false

func _ready() -> void:
	# warning-ignore:return_value_discarded
	connect("tween_all_completed", self, "_on_Tweentoo_tween_all_completed")
	var parent := get_parent()
	if !parent is Node2D:
		is_2D = false
	if !is_2D and !parent is Spatial:
		printerr(name, ": ", parent.name, " is not a Node2D or a Spatial.")
		queue_free()
	elif can_start:
		change()

func next_child() -> int:
	var result := current_child
	if !reversed_change:
		result += 1
	else:
		result -= 1
	if result >= get_child_count():
		return 0
	elif result < 0:
		return get_child_count() - 1
	return result

func next_duration() -> int:
	var result := current_duration
	if !reversed_change:
		result += 1
	else:
		result -= 1
	if result >= duration_array.size():
		return 0
	elif result < 0:
		return duration_array.size() - 1
	return result

func change() -> void:
	is_changing = true
	if get_child_count() != 0:
		if is_2D:
			var pnode : Node2D = get_parent()
			var cnode : Node2D = get_child(next_child())
			if update_position:
				# warning-ignore:return_value_discarded
				interpolate_property(pnode, "position", pnode.position, cnode.position, duration if duration_array.empty() else duration_array[current_duration], transition, easing)
			if update_rotation:
				# warning-ignore:return_value_discarded
				interpolate_property(pnode, "rotation", pnode.rotation, cnode.rotation, duration if duration_array.empty() else duration_array[current_duration], transition, easing)
			if update_scale:
				# warning-ignore:return_value_discarded
				interpolate_property(pnode, "scale", pnode.scale, cnode.scale, duration if duration_array.empty() else duration_array[current_duration], transition, easing)
			if pnode.modulate != cnode.modulate:
				# warning-ignore:return_value_discarded
				interpolate_property(pnode, "modulate", pnode.modulate, cnode.modulate, duration if duration_array.empty() else duration_array[current_duration], transition, easing)
			if pnode.self_modulate != cnode.self_modulate:
				# warning-ignore:return_value_discarded
				interpolate_property(pnode, "self_modulate", pnode.self_modulate, cnode.self_modulate, duration if duration_array.empty() else duration_array[current_duration], transition, easing)
		else:
			var pnode : Spatial = get_parent()
			var cnode : Spatial = get_child(next_child())
			if update_position:
				# warning-ignore:return_value_discarded
				interpolate_property(pnode, "translation", pnode.translation, cnode.translation, duration if duration_array.empty() else duration_array[current_duration], transition, easing)
			if update_rotation:
				# warning-ignore:return_value_discarded
				interpolate_property(pnode, "rotation_degrees", pnode.rotation_degrees, cnode.rotation_degrees, duration if duration_array.empty() else duration_array[current_duration], transition, easing)
			if update_scale:
				# warning-ignore:return_value_discarded
				interpolate_property(pnode, "scale", pnode.scale, cnode.scale, duration if duration_array.empty() else duration_array[current_duration], transition, easing)
		# warning-ignore:return_value_discarded
		start()

func start_state() -> void:
	current_child = -1
	current_duration = 0

func set_reversed_change(value : bool) -> void:
	reversed_change = value
	# warning-ignore:return_value_discarded
	remove_all()
	if is_changing:
		change()

func _on_Tweentoo_tween_all_completed() -> void:
	is_changing = false
	current_child = next_child()
	if !duration_array.empty():
		current_duration = next_duration()
	
	if current_child == get_child_count() - 1:
		if !reversed_change:
			emit_signal("tweentoo_completed")
		else:
			emit_signal("tweentoo_started")
	elif current_child == 0:
		if !reversed_change:
			emit_signal("tweentoo_started")
		else:
			emit_signal("tweentoo_completed")
	
	if can_loop:
		change()
	else:
		if !reversed_change and current_child != get_child_count() - 1:
			change()
		elif reversed_change and current_child != 0:
			change()
