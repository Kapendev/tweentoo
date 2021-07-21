# Tweentoo
A simple tween script that makes it easy to move, rotate and scale Node2D, Control or Spatial nodes.<br/>
You can watch a video about Tweentoo here: https://youtu.be/79pTFbRVaZI

![Tweentoo Image](https://img.itch.zone/aW1hZ2UvMTEwMDExOC82MzQ0OTYwLnBuZw==/original/U4SfjI.png)

---

# How to use
1. Add a Tweentoo to a Node2D/Control/Spatial.
2. Add Node2D/Control/Spatial nodes to the Tweentoo.
3. Set autostart to true and play the scene or call tween_prs().

---

# Main methods
- tween_property(py_name, initial_val, final_val)
- tween_property_with_node(py_name, initial_node: Node, final_node)
- tween_property_with_child(py_name, initial_cid, final_cid)
- tween_position_with_curve(curve)
- tween_prs()

---

# Extra
You can also change the modulate and self_modulate property of Node2D/Control nodes.<br/>
If autostart is true and the first child is a Path2D/Path with a curve resource, tween_position_with_curve() will run.<br/>
To repeat a tween, just set the repeat property to true.<br/>

