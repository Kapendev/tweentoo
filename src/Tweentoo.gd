tool
class_name Tweentoo
extends Tween

"""
Author: AlexandrosKap
License: MIT
Description: A simple tween script that makes it easy to move, rotate and scale Node2D, Control or Spatial nodes.

# How to use
1. Add a Tweentoo to a Node2D/Control/Spatial.
2. Add Node2D/Control/Spatial nodes to the Tweentoo.
3. Set autostart to true and play the scene or call tween_prs().

# Main methods
1. tween_property(py_name, initial_val, final_val)
2. tween_property_with_node(py_name, initial_node: Node, final_node)
3. tween_property_with_child(py_name, initial_cid, final_cid)
4. tween_position_with_curve(curve)
5. tween_prs()

# Extra
You can also change the modulate and self_modulate property of Node2D/Control nodes.
If autostart is true and the first child is a Path2D/Path with a curve resource, tween_position_with_curve() will run.
To repeat a tween, just set the repeat property to true.
"""

# todo: Test it mooooore.

const ARC_RADIUS := 8.0
const ARC_POINT_COUNT := 32
const LINE_COLOR := Color.deepskyblue
const LINE_WIDTH := 2.0
const LINE_ANTIALIASED := true

enum TransitionType {LINEAR = 0, CUBIC = 7, CIRC = 8, ELASTIC = 6, BOUNCE = 9, BACK = 10}
enum EaseType {IN_OUT = 2, OUT_IN = 3, IN = 0, OUT = 1}

export var autostart := false # Will call tween_prs() or tween_position_with_curve() when the node is created.
export var backwards := false # tween_prs() or tween_position_with_curve() will play backwards.
export var pingpong := false # tween_prs() or tween_position_with_curve() will go back to the start position.
export var update_position := true
export var update_rotation := true
export var update_scale := true

export(TransitionType) var default_transition := TransitionType.LINEAR
export(EaseType) var default_easing := EaseType.IN_OUT
export var default_duration := 1.0
export(Array, TransitionType) var array_transition := []
export(Array, EaseType) var array_easing := []
export(Array, float) var array_duration := []

var update_global_delay := true # Calling multiple tweens will create a sequence of tweens if true. See tween_prs().
var __global_delay := 0.0 # Don't change this.
var __parent: Node # Don't change this.


func _ready() -> void:
	__parent = get_parent()
	if !Engine.editor_hint:
		# warning-ignore:return_value_discarded
		connect("tween_all_completed", self, "_on_Tweentoo_tween_all_completed")
		if autostart and get_child_count() > 0:
			var start_node := get_child(0)
			if start_node is Path2D or start_node is Path:
				if start_node.curve != null:
					tween_position_with_curve(start_node.curve)
			else:
				tween_prs()
	elif __parent is CanvasItem:
		# warning-ignore:return_value_discarded
		__parent.connect("draw", self, "_on_Parent_draw")


func _on_Tweentoo_tween_all_completed() -> void:
	reset_global_delay()


func _on_Parent_draw() -> void:
	var canvas: CanvasItem = get_parent()
	var points := PoolVector2Array()
	canvas.draw_set_transform_matrix(canvas.get_global_transform().affine_inverse()) # https://github.com/godotengine/godot/issues/5428#issuecomment-228633583
	for n in get_children():
		if n is Path2D and n.curve != null:
			for p in n.curve.get_baked_points():
				points.append(p)
		elif n is Node2D:
			points.append(n.position)
		elif n is Control:
			points.append(n.rect_position)
	if points.size() > 0:
		canvas.draw_arc(points[points.size() - 1], ARC_RADIUS, 0.0, PI * 2.0, ARC_POINT_COUNT, LINE_COLOR, LINE_WIDTH, LINE_ANTIALIASED)
	if points.size() > 1:
		canvas.draw_polyline(points, LINE_COLOR, LINE_WIDTH, LINE_ANTIALIASED)


func reset_global_delay() -> void:
	__global_delay = 0


# Tween parent property from initial_val to final_val.
func tween_property(py_name: String, initial_val, final_val, duration := default_duration, transition := default_transition, easing := default_easing, delay := 0.0, can_error := true) -> void:
	var parent_py = __parent.get(py_name)
	if parent_py != null and typeof(initial_val) == typeof(final_val) and typeof(initial_val) == typeof(parent_py):
		# warning-ignore:return_value_discarded
		interpolate_property(__parent, py_name, initial_val, final_val, duration, transition, easing, delay + __global_delay)
		# warning-ignore:return_value_discarded
		start()
		if update_global_delay:
			__global_delay += duration + delay
	elif can_error:
		if parent_py == null:
			printerr(name, ": Can't get property \"", py_name, "\" from ", __parent.name, ".")
		elif typeof(parent_py) != typeof(initial_val) or typeof(parent_py) != typeof(final_val):
			printerr(name, ": Wrong tween value for property \"", py_name, "\" from ", __parent.name, ".")


# Tween parent property from initial_val to final_val by using two nodes.
func tween_property_with_node(py_name: String, initial_node: Node, final_node: Node, duration := default_duration, transition := default_transition, easing := default_easing, delay := 0.0, can_error := true) -> void:
	var val0 = initial_node.get(py_name)
	var val1 = final_node.get(py_name)
	if typeof(val0) == typeof(val1) and typeof(val0) == typeof(__parent.get(py_name)):
		tween_property(py_name, val0, val1, duration, transition, easing, delay, can_error)
	elif can_error:
		printerr(name, ": Can't get property \"", py_name, "\" from ", initial_node.name, ", ", final_node.name, ".")


# Tween parent property from initial_val to final_val by using two child nodes.
func tween_property_with_child(py_name: String, initial_cid: int, final_cid: int, duration := default_duration, transition := default_transition, easing := default_easing, delay := 0.0, can_error := true) -> void:
	var child_count := get_child_count()
	if initial_cid < child_count and final_cid < child_count:
		tween_property_with_node(py_name, get_child(initial_cid), get_child(final_cid), duration, transition, easing, delay, can_error)
	elif can_error:
		printerr(name, ": Can't get child ", initial_cid, ", ", final_cid, ".")


# Tween parent position by using a curve resource.
func tween_position_with_curve(curve: Resource, local_backwards := backwards, local_pingpong := pingpong) -> void:
	if curve is Curve2D:
		var points: PoolVector2Array = curve.get_baked_points()
		for i in points.size():
			var current_i: int = i if !local_backwards else int(abs(i - points.size() + 1))
			if !local_backwards and current_i != points.size() - 1 or local_backwards and current_i != 0:
				tween_property("position", points[current_i], points[clamp(current_i + 1 if !local_backwards else current_i - 1, 0, points.size() - 1)], default_duration, TRANS_LINEAR, EASE_IN, 0.0, false)
				tween_property("rect_position", points[current_i], points[clamp(current_i + 1 if !local_backwards else current_i - 1, 0, points.size() - 1)], default_duration, TRANS_LINEAR, EASE_IN, 0.0, false)
	elif curve is Curve3D:
		var points: PoolVector3Array = curve.get_baked_points()
		for i in points.size():
			var current_i: int = i if !local_backwards else int(abs(i - points.size() + 1))
			if !local_backwards and current_i != points.size() - 1 or local_backwards and current_i != 0:
				tween_property("translation", points[current_i], points[clamp(current_i + 1 if !local_backwards else current_i - 1, 0, points.size() - 1)], default_duration, TRANS_LINEAR, EASE_IN, 0.0, false)
	if local_pingpong:
		tween_position_with_curve(curve, !local_backwards, false)


# Tween parent position, rotation and scale by using all the children. Will also tween modulate and self_modulate.
func tween_prs(local_backwards := backwards, local_pingpong := pingpong) -> void:
	update_global_delay = false
	var last_cid := get_child_count() - 1
	for cid in last_cid + 1:
		var current_cid: int = cid if !local_backwards else int(abs(cid - last_cid))
		var next_cid := int(clamp(current_cid + 1 if !local_backwards else current_cid - 1, 0, last_cid))
		var current_ducation := default_duration if array_duration.empty() else array_duration[clamp(current_cid if !local_backwards else current_cid - 1, 0, array_duration.size() - 1)]
		var current_transition := default_transition if array_transition.empty() else int(array_transition[clamp(current_cid if !local_backwards else current_cid - 1, 0, array_transition.size() - 1)])
		var current_easing := default_easing if array_easing.empty() else int(array_easing[clamp(current_cid if !local_backwards else current_cid - 1, 0, array_easing.size() - 1)])
		if !local_backwards and current_cid != last_cid or local_backwards and current_cid != 0 or last_cid == 0:
			__tween_prs_properties(current_cid, next_cid, current_ducation, current_transition, current_easing)
	update_global_delay = true
	if local_pingpong:
		tween_prs(!local_backwards, false)


# Don't use. The tweening part inside of tween_prs().
func __tween_prs_properties(current_cid: int, next_cid: int, current_ducation: float, current_transition: int, current_easing: int) -> void:
	if update_position:
		tween_property_with_child("position", current_cid, next_cid, current_ducation, current_transition, current_easing, 0.0, false)
		tween_property_with_child("rect_position", current_cid, next_cid, current_ducation, current_transition, current_easing, 0.0, false)
		tween_property_with_child("translation", current_cid, next_cid, current_ducation, current_transition, current_easing, 0.0, false)
	if update_rotation:
		tween_property_with_child("rotation", current_cid, next_cid, current_ducation, current_transition, current_easing, 0.0, false)
		tween_property_with_child("rect_rotation", current_cid, next_cid, current_ducation, current_transition, current_easing, 0.0, false)
	if update_scale:
		tween_property_with_child("scale", current_cid, next_cid, current_ducation, current_transition, current_easing, 0.0, false)
		tween_property_with_child("rect_scale", current_cid, next_cid, current_ducation, current_transition, current_easing, 0.0, false)
	tween_property_with_child("modulate", current_cid, next_cid, current_ducation, current_transition, current_easing, 0.0, false)
	tween_property_with_child("self_modulate", current_cid, next_cid, current_ducation, current_transition, current_easing, 0.0, false)
	__global_delay += current_ducation
