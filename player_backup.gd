## 玩家元素备用栏
## 显示石头、剪刀、布三个可选元素，玩家点击后选中某个元素类型。
## 选中的元素类型将用于放入玩家决斗栏。
class_name PlayerBackup
extends HBoxContainer

# ---- 信号 ----
## 玩家选中了某个元素类型
signal element_selected(type: int)

# ---- 属性 ----
var _elements: Array[Element] = []        ## 3个元素实例的引用
var _selected_type: int = Element.ElementType.NONE  ## 当前选中的元素类型
var _interactive: bool = false            ## 是否可交互

# ---- 生命周期 ----
func _ready() -> void:
	# 设置容器属性
	add_theme_constant_override("separation", 20)
	alignment = BoxContainer.ALIGNMENT_CENTER
	# 容器本身不拦截鼠标事件，让子元素直接接收
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 创建3个元素：石头、剪刀、布
	var types := [
		Element.ElementType.ROCK,
		Element.ElementType.SCISSORS,
		Element.ElementType.PAPER,
	]
	for type in types:
		var elem := Element.new()
		add_child(elem)
		elem.set_element(type)
		elem.clicked.connect(_on_element_clicked)
		_elements.append(elem)

# ---- 公开方法 ----

## 启用/禁用交互（对战阶段应禁用）
func set_interactive(enabled: bool) -> void:
	_interactive = enabled
	# 禁用时清除选中状态
	if not enabled:
		_clear_selection()
	# 控制鼠标过滤
	for elem in _elements:
		elem.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

## 获取当前选中的元素类型
func get_selected_type() -> int:
	return _selected_type

## 清除选中状态
func clear_selection() -> void:
	_clear_selection()

# ---- 内部方法 ----

## 元素被点击的回调
func _on_element_clicked(element: Element) -> void:
	if not _interactive:
		return

	var type := element.get_element_type()

	# 如果点击的是已选中的元素，取消选中
	if _selected_type == type:
		_clear_selection()
		return

	# 选中新元素
	_clear_selection()
	_selected_type = type
	element.set_selected(true)
	element_selected.emit(type)

## 清除所有选中状态
func _clear_selection() -> void:
	_selected_type = Element.ElementType.NONE
	for elem in _elements:
		elem.set_selected(false)
