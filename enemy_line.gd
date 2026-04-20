## 敌人决斗栏
## 包含5个格子，每局游戏开始时随机生成元素序列。
## 横向排列，slot0在最左侧（靠近画面中央），便于碰撞动画。
## 元素默认隐藏（显示"?"），对战时逐个揭示。
class_name EnemyLine
extends HBoxContainer

# ---- 常量 ----
const SLOT_COUNT: int = 5

# ---- 属性 ----
var _slot_elements: Array[Element] = []   ## 5个格子的Element实例引用
var _slot_types: Array[int] = []          ## 5个格子的实际元素类型

# ---- 生命周期 ----
func _ready() -> void:
	add_theme_constant_override("separation", 12)
	alignment = BoxContainer.ALIGNMENT_CENTER
	# 显式设置容器最小尺寸确保可见（5*100 + 4*12 = 548 x 100）
	custom_minimum_size = Vector2(548, 100)
	# LTR布局（默认）：slot0在最左侧（靠近画面中央）
	# 容器本身不拦截鼠标事件
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 初始化5个空格子
	for i in range(SLOT_COUNT):
		var elem := Element.new()
		add_child(elem)
		elem.clear()
		# 敌人格子不需要点击交互
		elem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slot_elements.append(elem)
		_slot_types.append(Element.ElementType.NONE)

# ---- 公开方法 ----

## 随机生成5个元素，并以隐藏状态显示
func generate_random() -> void:
	var valid_types := [
		Element.ElementType.ROCK,
		Element.ElementType.SCISSORS,
		Element.ElementType.PAPER,
	]
	for i in range(SLOT_COUNT):
		var rand_type: int = valid_types[randi() % valid_types.size()]
		_slot_types[i] = rand_type
		_slot_elements[i].set_element(rand_type)
		_slot_elements[i].show_hidden()  # 隐藏显示为"?"

## 获取指定格子的实际元素类型
func get_element(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return Element.ElementType.NONE
	return _slot_types[slot_index]

## 获取全部格子的元素序列
func get_all_elements() -> Array[int]:
	return _slot_types.duplicate()

## 揭示指定格子的元素（对战时使用）
func reveal_element(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return
	_slot_elements[slot_index].reveal()

## 揭示所有元素
func reveal_all() -> void:
	for i in range(SLOT_COUNT):
		_slot_elements[i].reveal()

## 获取指定索引的Element节点引用（用于动画等）
func get_slot_element(index: int) -> Element:
	if index < 0 or index >= SLOT_COUNT:
		return null
	return _slot_elements[index]

## 重置所有格子为空
func reset() -> void:
	for i in range(SLOT_COUNT):
		_slot_types[i] = Element.ElementType.NONE
		_slot_elements[i].clear()
		_slot_elements[i].visible = true  # 恢复可见（碰撞动画会隐藏元素）
