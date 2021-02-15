extends Control

var arr_Items: Array
var is_item_selected: bool = false
var selected_item: Control
var is_dragging_item: bool = false
var cursor_item_drag_offset: Vector2 = Vector2(-8, -8)
#var canvas_layer: CanvasLayer

func _ready():
#	canvas_layer = $CanvasLayer
	#Get Items from Group
	arr_Items = get_tree().get_nodes_in_group("item")
	
	for item in arr_Items:
		item.connect("gui_input", self, "cursor_in_item", [item])
	

func cursor_in_item(event: InputEvent, item: Control):
	if event.is_action_pressed("select_item"):
		is_item_selected = true
		selected_item = item
#		if self.has_node(selected_item.pat):
#			self.remove_child(selected_item)
			
#		if !canvas_layer.has_node(selected_item):
#			canvas_layer.add_child(selected_item)
	
	if event is InputEventMouseMotion:
		if is_item_selected:
			is_dragging_item = true
			
			
	if event.is_action_released("select_item"):
		print("zx")
		is_item_selected = false
		selected_item = null
		is_dragging_item = false
		
func _process(delta):
	if is_dragging_item:
		selected_item.rect_position = self.get_global_mouse_position() + cursor_item_drag_offset
