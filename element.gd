## 元素基础组件
## 代表石头、剪刀、布中的一个元素，支持占位图绘制、隐藏/揭示、选中高亮等功能。
## 用于玩家决斗栏、敌人决斗栏、玩家备用栏中的每一个格子。
class_name Element
extends Control

# ---- 枚举 ----
## 元素类型：石头=0, 剪刀=1, 布=2, 空=-1
enum ElementType { NONE = -1, ROCK = 0, SCISSORS = 1, PAPER = 2 }

# ---- 常量：占位图配色 ----
const ELEMENT_COLORS: Dictionary = {
	ElementType.ROCK: Color(0.55, 0.55, 0.6),       # 灰色 - 石头
	ElementType.SCISSORS: Color(0.9, 0.75, 0.2),    # 黄色 - 剪刀
	ElementType.PAPER: Color(0.3, 0.5, 0.85),       # 蓝色 - 布
}

const ELEMENT_LABELS: Dictionary = {
	ElementType.ROCK: "R",
	ElementType.SCISSORS: "S",
	ElementType.PAPER: "P",
}

const ELEMENT_NAMES: Dictionary = {
	ElementType.ROCK: "石头",
	ElementType.SCISSORS: "剪刀",
	ElementType.PAPER: "布",
}

# ---- 元素尺寸 ----
const SLOT_SIZE: float = 100.0

# ---- 属性 ----
var element_type: int = ElementType.NONE   ## 当前元素类型
var is_hidden: bool = false                ## 是否隐藏（敌方元素显示"?"）
var is_selected: bool = false              ## 是否被选中（备用栏高亮态）

# ---- 信号 ----
## 元素被点击时发射，传递自身引用
signal clicked(element: Element)

# ---- 生命周期 ----
func _ready() -> void:
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	size = Vector2(SLOT_SIZE, SLOT_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP

# ---- 公开方法 ----

## 设置元素类型并刷新显示
func set_element(type: int) -> void:
	element_type = type
	is_hidden = false
	queue_redraw()

## 获取当前元素类型
func get_element_type() -> int:
	return element_type

## 清空元素，恢复为空位
func clear() -> void:
	element_type = ElementType.NONE
	is_hidden = false
	is_selected = false
	queue_redraw()

## 设置为隐藏状态（显示"?"）
func show_hidden() -> void:
	is_hidden = true
	queue_redraw()

## 揭示实际元素
func reveal() -> void:
	is_hidden = false
	queue_redraw()

## 设置选中状态
func set_selected(selected: bool) -> void:
	is_selected = selected
	queue_redraw()

# ---- 绘制 ----
func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	if element_type == ElementType.NONE:
		# 空位：虚线边框风格（用浅灰底色+深灰边框模拟）
		draw_rect(rect, Color(0.15, 0.15, 0.18), true)
		draw_rect(rect, Color(0.35, 0.35, 0.4), false, 2.0)
		_draw_centered_text("_", Color(0.4, 0.4, 0.45), 28)
		return

	if is_hidden:
		# 隐藏态：深灰色 + "?"
		draw_rect(rect, Color(0.2, 0.2, 0.25), true)
		draw_rect(rect, Color(0.4, 0.4, 0.45), false, 2.0)
		_draw_centered_text("?", Color(0.8, 0.8, 0.8), 36)
		return

	# 正常显示元素
	var bg_color: Color = ELEMENT_COLORS.get(element_type, Color.WHITE)
	draw_rect(rect, bg_color, true)

	# 边框：选中时白色粗框，否则暗色细框
	if is_selected:
		draw_rect(rect, Color.WHITE, false, 4.0)
	else:
		draw_rect(rect, bg_color.darkened(0.3), false, 2.0)

	# 绘制类型文字标签
	var label: String = ELEMENT_LABELS.get(element_type, "?")
	_draw_centered_text(label, Color.WHITE, 36)

## 在控件中央绘制文本
func _draw_centered_text(text: String, color: Color, font_size: int = 32) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	# 计算居中位置（y轴需要补偿baseline偏移）
	var pos := Vector2(
		(size.x - text_size.x) / 2.0,
		(size.y + text_size.y * 0.65) / 2.0
	)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)

# ---- 输入处理 ----
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(self)
