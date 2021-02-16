extends Control

var v2_TileSize: Vector2 = Vector2(32, 32)
var v2_InventoryDimensions: Vector2 = Vector2(8, 8)
var cr_InventoryPanel: ColorRect
var sp_InventoryGrids: Sprite
var a2_Inventory: Area2D

var dct_InventoryItemSlots: Dictionary
var dct_InventoryItems: Dictionary
var bl_IsItemSelected: bool = false
var ctrl_SelectedItem: Control
var bl_IsDraggingItem: bool = false
var v2_CursorItemDragOffset: Vector2 = Vector2(-8, -8)
var col_InvalidColor: Color = Color(1, 0.36, 0.36, 1)
var arr_OverlappingWithItems: Array
var v2_ItemPrevPosition: Vector2
var bl_IsSelectedItemInsideInventory: bool
var btn_AddItem: Button

func _ready():
	cr_InventoryPanel = $cr_InventoryPanel
	cr_InventoryPanel.rect_size = Vector2(v2_TileSize.x * v2_InventoryDimensions.x, v2_TileSize.y * v2_InventoryDimensions.y)
	
	sp_InventoryGrids = $sp_InventoryGrids
	sp_InventoryGrids.region_enabled = true
	sp_InventoryGrids.region_rect = Rect2( 0, 0, v2_InventoryDimensions.x * v2_TileSize.x, v2_InventoryDimensions.y * v2_TileSize.y )
	
	a2_Inventory = $sp_InventoryGrids/a2_Inventory
	
	a2_Inventory.connect("area_entered", self, "item_inside_inventory")
	a2_Inventory.connect("area_exited", self, "item_goes_outside_inventory")
	
	for ctrl_Item in get_tree().get_nodes_in_group("item"):
		add_signal_connections(ctrl_Item)

	btn_AddItem = $btn_AddItem
	btn_AddItem.connect("button_up", self, "add_loot_item")

func add_signal_connections(ctrl_Item: Control):
	ctrl_Item.connect("gui_input", self, "cursor_in_item", [ctrl_Item])
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
			bl_IsDraggingItem = true
			
	if event.is_action_released("select_item"):
		ctrl_SelectedItem.get_node("Sprite").set_z_index(0)
		if arr_OverlappingWithItems.size() > 0:
			ctrl_SelectedItem.rect_position = v2_ItemPrevPosition
			ctrl_SelectedItem.get_node("Sprite").modulate = Color(1, 1, 1, 1)
		else:
			if bl_IsSelectedItemInsideInventory: 
				if !add_item_to_inventory(ctrl_SelectedItem):
					ctrl_SelectedItem.rect_position = v2_ItemPrevPosition
			
		bl_IsItemSelected = false
		bl_IsDraggingItem = false
		ctrl_SelectedItem = null
		
func _process(delta):
	if bl_IsDraggingItem:
		ctrl_SelectedItem.rect_position = (self.get_global_mouse_position() + v2_CursorItemDragOffset).snapped(Vector2(32,32))

func overlapping_with_other_item(area: Area2D, ctrl_Item: Control):
	if area.get_parent().get_parent() == ctrl_SelectedItem:
		return
	
	if area == a2_Inventory:
		return
		
	arr_OverlappingWithItems.append(ctrl_Item)
	
	ctrl_SelectedItem.get_node("Sprite").modulate = col_InvalidColor
	
func not_overlapping_with_other_item(area: Area2D, ctrl_Item: Control):
	if area.get_parent().get_parent() == ctrl_SelectedItem:
		return
	
	if area == a2_Inventory:
		return
		
	arr_OverlappingWithItems.erase(ctrl_Item)

	if arr_OverlappingWithItems.size() == 0 and bl_IsItemSelected:
		ctrl_SelectedItem.get_node("Sprite").modulate = Color(1, 1, 1, 1)

func item_inside_inventory(area: Area2D):
	bl_IsSelectedItemInsideInventory = true
	
func item_goes_outside_inventory(area: Area2D):
	bl_IsSelectedItemInsideInventory = false

func add_item_to_inventory(ctrl_Item: Control) -> bool:
	var v2_slotID: Vector2 = ctrl_Item.rect_position / v2_TileSize
	var v2_ItemSlotSize: Vector2 = ctrl_Item.rect_size / v2_TileSize
	
	var v2_ItemMaxSlotID: Vector2 = v2_slotID + v2_ItemSlotSize - Vector2(1, 1)
	var v2_InventorySlotBounds: Vector2 = v2_InventoryDimensions - Vector2(1, 1)
	
	if v2_ItemMaxSlotID.x > v2_InventorySlotBounds.x:
		return false
		
	if v2_ItemMaxSlotID.y > v2_InventorySlotBounds.y:
		return false
		
	if dct_InventoryItems.has(ctrl_Item):
		remove_item_in_inventory(ctrl_Item)
	
	for y_ctr in range(v2_ItemSlotSize.y):
		for x_ctr in range(v2_ItemSlotSize.x):
			dct_InventoryItemSlots[Vector2(v2_slotID.x + x_ctr, v2_slotID.y + y_ctr)] = ctrl_Item
			
	dct_InventoryItems[ctrl_Item] = v2_slotID
	return true

func remove_item_in_inventory(ctrl_Item: Control):
	var v2_slotID: Vector2 = ctrl_Item.rect_position / v2_TileSize
	var v2_ItemSlotSize: Vector2 = ctrl_Item.rect_size / v2_TileSize
	
	for y_ctr in range(v2_ItemSlotSize.y):
		for x_ctr in range(v2_ItemSlotSize.x):
			if dct_InventoryItemSlots.has(Vector2(v2_slotID.x + x_ctr, v2_slotID.y + y_ctr)):
				dct_InventoryItemSlots.erase(Vector2(v2_slotID.x + x_ctr, v2_slotID.y + y_ctr))

	if dct_InventoryItems.has(ctrl_Item):
		dct_InventoryItems.erase(ctrl_Item)

func add_loot_item():
	var files = []
	var dir = Directory.new()
	dir.open("res://Prefabs/")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	dir.list_dir_end()
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var str_ItemToLoad: String = files[rng.randi_range(0, files.size()-1)]
	
	var pksc_Item: PackedScene = load("res://Prefabs/" + str_ItemToLoad)
	var ctrl_Item: Control = pksc_Item.instance()
	ctrl_Item.rect_position = Vector2(500, 100)
	add_signal_connections(ctrl_Item)
	
	self.call_deferred("add_child", ctrl_Item)
