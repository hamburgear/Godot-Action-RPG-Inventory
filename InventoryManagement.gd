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

	$btn_AddLongAxe.connect("button_up", self, "add_loot_item", ["LongAxe"])
	$btn_AddShield.connect("button_up", self, "add_loot_item", ["Shield"])
	$btn_AddShortAxe.connect("button_up", self, "add_loot_item", ["ShortAxe"])
	$btn_AddBuckler.connect("button_up", self, "add_loot_item", ["Buckler"])
	$btn_AddHammer.connect("button_up", self, "add_loot_item", ["Hammer"])
	$btn_AddSword.connect("button_up", self, "add_loot_item", ["Sword"])
	$btn_AddBow.connect("button_up", self, "add_loot_item", ["Bow"])
	$btn_AddDagger.connect("button_up", self, "add_loot_item", ["Dagger"])
		
	$btn_SortInventory.connect("button_up", self, "initiate_sort_inventory")

func add_signal_connections(ctrl_Item: Control):
	ctrl_Item.connect("gui_input", self, "cursor_in_item", [ctrl_Item])
	ctrl_Item.get_node("Sprite/Area2D").connect("area_entered", self, "overlapping_with_other_item", [ctrl_Item])
	ctrl_Item.get_node("Sprite/Area2D").connect("area_exited", self, "not_overlapping_with_other_item", [ctrl_Item])

func remove_signal_connections(ctrl_Item: Control):
	if ctrl_Item.is_connected("gui_input", self, "cursor_in_item"):
		ctrl_Item.disconnect("gui_input", self, "cursor_in_item")
	
	if ctrl_Item.get_node("Sprite/Area2D").is_connected("area_entered", self, "overlapping_with_other_item"):
		ctrl_Item.get_node("Sprite/Area2D").disconnect("area_entered", self, "overlapping_with_other_item")
		
	if ctrl_Item.get_node("Sprite/Area2D").is_connected("area_exited", self, "not_overlapping_with_other_item"):
		ctrl_Item.get_node("Sprite/Area2D").disconnect("area_exited", self, "not_overlapping_with_other_item")

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
	
	if ctrl_SelectedItem:
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

func add_loot_item(str_ItemName: String):
	var lb_ItemQty: Label = $ctrl_Quantities.get_node("lb_" + str_ItemName + "/lb_Qty")
	lb_ItemQty.text = str(int(lb_ItemQty.text) + 1)
	
	var lb_TotalQty: Label = $ctrl_Quantities.get_node("lb_TotalItems/lb_Qty")
	lb_TotalQty.text = str(int(lb_TotalQty.text) + 1)
	
	var pksc_Item: PackedScene = load("res://Prefabs/" + str_ItemName + ".tscn")
	var ctrl_Item: Control = pksc_Item.instance()
	ctrl_Item.rect_position = Vector2(500, 100)
	add_signal_connections(ctrl_Item)
	
	self.call_deferred("add_child", ctrl_Item)

func height_priority_size_sorter(a, b):
	# Same Y, greater X
	if a[1].y == b[1].y and a[1].x > b[1].x:
			return true
			
	# Greater Y, disregard X
	if a[1].y > b[1].y:
		return true

	return false
	
func width_priority_size_sorter(a, b):
	# Same Y, greater X
	if a[1].y == b[1].y and a[1].x > b[1].x:
			return true
			

	# Greater X, disregard Y
	if a[1].x > b[1].x:
		return true
		
	return false

func initiate_sort_inventory():
	if dct_InventoryItems.size() == 0:
		return
	
	for ctrl_Item in dct_InventoryItems:
		remove_signal_connections(ctrl_Item)
	
	var arr_InventoryItems: Array
	#Convert dictionary to array
	for item in dct_InventoryItems:
		var v2_ItemSlotSize: Vector2 = item.rect_size / v2_TileSize
		arr_InventoryItems.append([item, v2_ItemSlotSize])
		
	arr_InventoryItems.sort_custom(self, "height_priority_size_sorter")
	if sort_inventory(arr_InventoryItems):
		arr_InventoryItems.sort_custom(self, "width_priority_size_sorter")
		sort_inventory(arr_InventoryItems)
	
	for ctrl_Item in dct_InventoryItems:
		add_signal_connections(ctrl_Item)

func sort_inventory(arr_InventoryItems: Array):
	dct_InventoryItemSlots.clear()
	
	var arr_InventoryBlankSlots: Array
	
	for col_ctr in v2_InventoryDimensions.x:
		for row_ctr in v2_InventoryDimensions.y:
			arr_InventoryBlankSlots.append(Vector2(col_ctr, row_ctr))
	
	dct_InventoryItemSlots.clear()
	var ctrl_PrevItem: Control = arr_InventoryItems[0][0]
	var i_ItemCtr: int = 0
	var bl_IsSlotAvailable: bool
	for item in arr_InventoryItems:
		if i_ItemCtr > 0:
			ctrl_PrevItem = arr_InventoryItems[i_ItemCtr-1][0]
		var ctrl_Item: Control = item[0]
		var v2_ItemSlotSize: Vector2 = item[1]
		
		var arr_AssignedSlots: Array
		
		for v2_BlankSlot in arr_InventoryBlankSlots:
			bl_IsSlotAvailable = true
			var v2_UpperLeftSlotID: Vector2
			
			#Generate Item Length and Width IDs
			var arr_ItemDimensionIDs: Array
			for i_WidthCtr in v2_ItemSlotSize.x:
				for i_LengthCtr in v2_ItemSlotSize.y:
					if i_WidthCtr == 0 and i_LengthCtr == 0:
						v2_UpperLeftSlotID = v2_BlankSlot
					arr_ItemDimensionIDs.append(Vector2(i_WidthCtr, i_LengthCtr))
			
			for v2_DimensionID in arr_ItemDimensionIDs:
				var v2_SlotID: Vector2 = v2_BlankSlot + v2_DimensionID
				
				if v2_SlotID.y >= v2_InventoryDimensions.y:
					bl_IsSlotAvailable = false
					arr_AssignedSlots.clear()
					break
				if v2_SlotID.x >= v2_InventoryDimensions.x:
					bl_IsSlotAvailable = false
					arr_AssignedSlots.clear()
					break
					
				if arr_InventoryBlankSlots.find(v2_SlotID) != -1:
					arr_AssignedSlots.append(v2_SlotID)
				else:
					bl_IsSlotAvailable = false
					arr_AssignedSlots.clear()
					break
		
			if bl_IsSlotAvailable:
				for v2_AssignedSlotID in arr_AssignedSlots:
					arr_InventoryBlankSlots.erase(v2_AssignedSlotID)
					dct_InventoryItemSlots[v2_AssignedSlotID] = ctrl_Item
				arr_AssignedSlots.clear()
				ctrl_Item.rect_position = v2_UpperLeftSlotID * v2_TileSize
				break
		i_ItemCtr+=1
		if i_ItemCtr == arr_InventoryItems.size():
			if !bl_IsSlotAvailable:
				return false
			return true
		
		
