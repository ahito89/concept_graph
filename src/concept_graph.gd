"""
The main class of this plugin. Add a ConceptGraph node to your scene and attach a template to this
node to start editing the graph from the bottom panel editor.
This node then travel through the ConceptGraphTemplate object to generate content on the fly every
time the associated graph is updated.
"""

tool
class_name ConceptGraph
extends Spatial


signal template_path_changed

export(String, FILE, "*.cgraph") var template := "" setget set_template
export var show_result_in_editor_tree := false setget set_show_result
export var paused := false


var _template: ConceptGraphTemplate
var _input_root: Node
var _output_root: Node


func _ready() -> void:
	if Engine.is_editor_hint():
		_input_root = _get_or_create_root("Input")
		_input_root.connect("input_changed", self, "_on_input_changed")
		_output_root = _get_or_create_root("Output")
		reload_template()
		generate()


func reload_template() -> void:
	if not _template:
		_template = ConceptGraphTemplate.new()
		add_child(_template)
	_template.load_from_file(template)


func clear_output() -> void:
	if not _output_root:
		_output_root = _get_or_create_root("Output")

	for c in _output_root.get_children():
		_output_root.remove_child(c)
		c.queue_free()


func generate(force_full_simulation := false) -> void:
	"""
	Ask the Template object to go through the node graph and process each nodes until the final
	result is complete.
	"""

	if not Engine.is_editor_hint() or paused:
		return

	clear_output()
	if force_full_simulation:
		_template.clear_simulation_cache()

	var result = _template.get_output()
	if not result:
		return

	if not result is Array:
		result = [result]

	for node in result:
		_output_root.add_child(node)
		node.set_owner(get_tree().get_edited_scene_root())
		_set_children_owner(node)


func _set_children_owner(node) -> void:
	for c in node.get_children():
		c.set_owner(get_tree().get_edited_scene_root())
		_set_children_owner(c)


func set_template(val) -> void:
	template = val
	emit_signal("template_path_changed", val)	# This signal is only useful for the editor view


func set_show_result(val) -> void:
	"""
	Decides whether to show the resulting nodes in the editor tree or keep it hidden (but still
	visible in the viewport)
	"""
	show_result_in_editor_tree = val
	return
	if not _output_root:
		_output_root = _get_or_create_root("Output")

	if val:
		_output_root.set_owner(get_tree().get_edited_scene_root())
	else:
		_output_root.set_owner(self)


func get_input(name: String) -> Node:
	if not _input_root:
		return null
	return _input_root.get_node(name)


func _get_or_create_root(name: String) -> Spatial:
	if has_node(name):
		return get_node(name) as Spatial

	#var root = Spatial.new()
	var root = ConceptGraphInputManager.new() if name == "Input" else Spatial.new()
	root.set_name(name)
	add_child(root)
	root.set_owner(get_tree().get_edited_scene_root())
	return root


func _on_input_changed(node) -> void:
	generate(true)
