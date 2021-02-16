extends Control

var v2_TileSize: Vector2 = Vector2(32, 32)
var v2_InventoryDimensions: Vector2 = Vector2(8, 8)
var cr_InventoryPanel: ColorRect
var sp_InventoryGrids: Sprite

var dct_ItemSlots: Dictionary
var bl_IsItemSelected: bool = false
var ctrl_SelectedItem: Control
var bl_isDraggingItem: bool = false
var v2_CursorItemDragOffset: Vector2 = Vector2(-8, -8)
var col_OverlappingColor: Color = Color(1, 0.36, 0.36, 1)
var arr_OverlappingWithItems: Array
var v2_ItemPrevPosition: Vector2

func _ready():
	cr_InventoryPanel = $cr_InventoryPanel
	cr_InventoryPanel.rect_size = Vector2(v2_TileSize.x * v2_InventoryDimensions.x, v2_TileSize.y * v2_InventoryDimensions.y)
	
	
	sp_InventoryGrids = $sp_InventoryGrids
	sp_InventoryGrids.region_enabled = true
	sp_InventoryGrids.region_rect = Rect2( 0, 0, v2_InventoryDimensions.x * v2_TileSize.x, v2_InventoryDimensions.y * v2_TileSize.y )
	
	for ctrl_Item in get_tree().get_nodes_in_group("item"):
		ctrl_Item.connect("mouse_entered", self, "cursor_in_item", [ctrl_Item])
		ctrl_Item.get_node("Sprite/Area2D").connect("area_entered", self, "overlapping_with_other_item", [ctrl_Item])
		ctrl_Item.get_node("Sprite/Area2D").connect("area_exited", self, "not_overlapping_with_other_item", [ctrl_Item])

func cursor_in_item(event: InputEvent, ctrl_Item: Control):
	if event.is_action_pressed("select_item"):
		bl_IsItemSelected = true
		ctrl_SelectedItem = ctrl_Item
		ctrl_SelectedItem.get_node("Sprite").set_z_index(1000)
		v2_ItemPrevPosition = ctrl_SelectedItem.rect_position
	
	if event is InputEventMouseMotion:
		if bl_IsItemSelected:
			bl_isDraggingItem = true
			
	if event.is_action_released("select_item"):
		ctrl_SelectedItem.get_node("Sprite").set_z_index(0)
		if arr_OverlappingWithItems.size() > 0:
			ctrl_SelectedItem.rect_position = v2_ItemPrevPosition
			ctrl_SelectedItem.get_node("Sprite").modulate = Color(1, 1, 1, 1)
			
		bl_IsItemSelected = false
		bl_isDraggingItem = false
		ctrl_SelectedItem = null
		
func _process(delta):
	if bl_isDraggingItem:
		ctrl_SelectedItem.rect_position = (self.get_global_mouse_position() + v2_CursorItemDragOffset).snapped(Vector2(32,32))

func overlapping_with_other_item(area: Area2D, ctrl_Item: Control):
	arr_OverlappingWithItems.append(ctrl_Item)
	ctrl_SelectedItem.get_node("Sprite").modulate = col_OverlappingColor
	
func not_overlapping_with_other_item(area: Area2D, ctrl_Item: Control):
	arr_OverlappingWithItems.erase(ctrl_Item)
	if arr_OverlappingWithItems.size() == 0 and bl_IsItemSelected:
		ctrl_SelectedItem.get_node("Sprite").modulate = Color(1, 1, 1, 1)
