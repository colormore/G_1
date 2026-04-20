## 玩家决斗栏
## 包含5个格子，玩家可以将备用栏中选中的元素点击放入对应格子。
## 横向排列，使用RTL布局使slot0在最右侧（靠近画面中央），便于碰撞动画。
## 当5个格子全部填满时发射 all_slots_filled 信号。
class_name PlayerLine
extends HBoxContainer

# ---- 常量 ----
const SLOT_COUNT: int = 5

# ---- 信号 ----
## 5个格子全部填满时发射
signal all_slots_filled
## 某个格子被点击时发射
signal slot_clicked(index: int)

# ---- 属性 ----
var _slot_elements: Array[Element] = []   ## 5个格子的Element实例引用
var _slot_types: Array[int] = []          ## 5个格子的元素类型（-1为空）
var _interactive: bool = false            ## 是否可交互

# ---- 生命周期 ----
func _ready() -> void:
	add_theme_constant_override("separation", 12)
	alignment = BoxContainer.ALIGNMENT_CENTER
	# 显式设置容器最小尺寸确保可见（5*100 + 4*12 = 548 x 100）
	custom_minimum_size = Vector2(548, 100)
	# 容器本身不拦截鼠标事件，让子元素直接接收
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 反向创建子节点：先添加slot4（视觉最左），最后添加slot0（视觉最右=靠近中央）
	# 这样 slot0 在画面最右侧，对战时最先与敌人碰撞
	_slot_elements.resize(SLOT_COUNT)
	_slot_types.resize(SLOT_COUNT)
	for i in range(SLOT_COUNT):
		_slot_types[i] = Element.ElementType.NONE

	for visual_idx in range(SLOT_COUNT):
		# visual_idx 0 = 最左侧 = 逻辑 slot4
		# visual_idx 4 = 最右侧 = 逻辑 slot0
		var logical_idx: int = SLOT_COUNT - 1 - visual_idx
		var elem := Element.new()
		add_child(elem)
		elem.clear()
		elem.clicked.connect(_on_slot_clicked.bind(logical_idx))
		_slot_elements[logical_idx] = elem

# ---- 公开方法 ----

## 在指定格子放入元素
func place_element(slot_index: int, type: int) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return
	_slot_types[slot_index] = type
	_slot_elements[slot_index].set_element(type)

	# 检查是否全部填满
	if is_full():
		all_slots_filled.emit()

## 获取指定格子的元素类型
func get_element(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return Element.ElementType.NONE
	return _slot_types[slot_index]

## 获取全部格子的元素序列
func get_all_elements() -> Array[int]:
	return _slot_types.duplicate()

## 判断是否全部格子都已填满
func is_full() -> bool:
	for type in _slot_types:
		if type == Element.ElementType.NONE:
			return false
	return true

## 获取已填充的格子数量
func get_filled_count() -> int:
	var count := 0
	for type in _slot_types:
		if type != Element.ElementType.NONE:
			count += 1
	return count

## 重置所有格子为空
func reset() -> void:
	for i in range(SLOT_COUNT):
		_slot_types[i] = Element.ElementType.NONE
		_slot_elements[i].clear()
		_slot_elements[i].visible = true  # 恢复可见（碰撞动画会隐藏元素）

## 获取指定索引的Element节点引用（用于动画等）
func get_slot_element(index: int) -> Element:
	if index < 0 or index >= SLOT_COUNT:
		return null
	return _slot_elements[index]

## 启用/禁用交互
func set_interactive(enabled: bool) -> void:
	_interactive = enabled
	for elem in _slot_elements:
		elem.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

# ---- 内部方法 ----

## 格子被点击的回调（接收信号传递的Element + bind的index）
func _on_slot_clicked(_element: Element, index: int) -> void:
	if not _interactive:
		return
	slot_clicked.emit(index)
