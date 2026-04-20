## 主场景 - 游戏总控制器
## 负责：游戏状态机、猜拳判定、分数管理、UI控制、场景布局、碰撞动画。
## 协调 PlayerBackup、PlayerLine、EnemyLine 之间的交互。
extends Control

# ---- 游戏状态枚举 ----
enum GameState { IDLE, PREPARING, BATTLING, GAME_OVER }

# ---- 常量 ----
const ROUND_COUNT: int = 5          ## 每局回合数
const FLY_DURATION: float = 0.5     ## 元素飞行时间（秒）
const SHATTER_DURATION: float = 0.4 ## 粉碎特效持续时间（秒）
const ROUND_PAUSE: float = 0.6      ## 回合间等待时间（秒）
const CENTER_X: float = 960.0       ## 画面中央X坐标（碰撞点）
const CENTER_Y: float = 460.0       ## 碰撞动画Y坐标

# ---- 游戏状态 ----
var _game_state: int = GameState.IDLE
var _round_score: int = 0           ## 本局得分
var _total_score: int = 0           ## 累计总分
var _current_round: int = 0         ## 当前回合索引（0-4）

# ---- 子节点引用 ----
var _player_backup: PlayerBackup
var _player_line: PlayerLine
var _enemy_line: EnemyLine
var _score_label: Label
var _round_score_label: Label
var _start_button: Button
var _restart_button: Button
var _status_label: Label
var _round_info_label: Label

# ============================================================
#  生命周期
# ============================================================
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_create_background()
	_create_game_components()
	_create_ui()
	_connect_signals()
	_set_state(GameState.IDLE)

# ============================================================
#  场景构建
# ============================================================

func _create_background() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.12, 0.15)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

## 创建游戏核心组件
func _create_game_components() -> void:
	# ---- 玩家元素备用栏（左上区域） ----
	_player_backup = PlayerBackup.new()
	_player_backup.name = "PlayerBackup"
	_player_backup.position = Vector2(80, 80)
	add_child(_player_backup)

	var backup_title := Label.new()
	backup_title.text = "选择元素"
	backup_title.position = Vector2(80, 45)
	backup_title.add_theme_font_size_override("font_size", 22)
	backup_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	backup_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backup_title)

	# ---- 玩家决斗栏（左侧，横向排列，RTL使slot0靠右=靠近中央） ----
	# 5个100px格子 + 4*12px间距 = 548px 宽度
	# 位于左侧：从 x=80 到 x=628
	_player_line = PlayerLine.new()
	_player_line.name = "PlayerLine"
	_player_line.position = Vector2(80, 420)
	add_child(_player_line)

	var player_title := Label.new()
	player_title.text = "< 玩家 >"
	player_title.position = Vector2(280, 385)
	player_title.add_theme_font_size_override("font_size", 24)
	player_title.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	player_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_title)

	# ---- 敌人决斗栏（右侧，横向排列，LTR使slot0靠左=靠近中央） ----
	# 位于右侧：从 x=1292 到 x=1840
	_enemy_line = EnemyLine.new()
	_enemy_line.name = "EnemyLine"
	_enemy_line.position = Vector2(1292, 420)
	add_child(_enemy_line)

	var enemy_title := Label.new()
	enemy_title.text = "< 敌人 >"
	enemy_title.position = Vector2(1500, 385)
	enemy_title.add_theme_font_size_override("font_size", 24)
	enemy_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	enemy_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(enemy_title)

	# ---- VS 标志（中央） ----
	var vs_label := Label.new()
	vs_label.text = "VS"
	vs_label.position = Vector2(930, 420)
	vs_label.add_theme_font_size_override("font_size", 52)
	vs_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	vs_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vs_label)

## 创建UI元素
func _create_ui() -> void:
	# 状态提示（顶部中央）
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.position = Vector2(660, 20)
	_status_label.custom_minimum_size = Vector2(600, 40)
	_status_label.add_theme_font_size_override("font_size", 28)
	_status_label.add_theme_color_override("font_color", Color.WHITE)
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status_label)

	# 回合信息（中央）
	_round_info_label = Label.new()
	_round_info_label.name = "RoundInfoLabel"
	_round_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_info_label.position = Vector2(660, 560)
	_round_info_label.custom_minimum_size = Vector2(600, 40)
	_round_info_label.add_theme_font_size_override("font_size", 30)
	_round_info_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	_round_info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_round_info_label)

	# 累计分数（底部左侧）
	_score_label = Label.new()
	_score_label.name = "ScoreLabel"
	_score_label.text = "累计分数: 0"
	_score_label.position = Vector2(80, 1000)
	_score_label.add_theme_font_size_override("font_size", 26)
	_score_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_score_label)

	# 本局得分（底部）
	_round_score_label = Label.new()
	_round_score_label.name = "RoundScoreLabel"
	_round_score_label.text = "本局得分: 0"
	_round_score_label.position = Vector2(380, 1000)
	_round_score_label.add_theme_font_size_override("font_size", 26)
	_round_score_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	_round_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_round_score_label)

	# 开始按钮（底部中央）
	_start_button = Button.new()
	_start_button.name = "StartButton"
	_start_button.text = "开始游戏"
	_start_button.position = Vector2(860, 990)
	_start_button.custom_minimum_size = Vector2(200, 60)
	_start_button.add_theme_font_size_override("font_size", 24)
	add_child(_start_button)

	# 再来一局按钮（底部中央，默认隐藏）
	_restart_button = Button.new()
	_restart_button.name = "RestartButton"
	_restart_button.text = "再来一局"
	_restart_button.position = Vector2(860, 990)
	_restart_button.custom_minimum_size = Vector2(200, 60)
	_restart_button.add_theme_font_size_override("font_size", 24)
	_restart_button.visible = false
	add_child(_restart_button)

func _connect_signals() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_player_backup.element_selected.connect(_on_element_selected)
	_player_line.slot_clicked.connect(_on_slot_clicked)
	_player_line.all_slots_filled.connect(_on_all_slots_filled)

# ============================================================
#  状态管理
# ============================================================

func _set_state(new_state: int) -> void:
	_game_state = new_state
	match new_state:
		GameState.IDLE:
			_status_label.text = "点击「开始游戏」"
			_round_info_label.text = ""
			_start_button.visible = true
			_restart_button.visible = false
			_player_backup.set_interactive(false)
			_player_line.set_interactive(false)

		GameState.PREPARING:
			_status_label.text = "选择元素放入决斗栏（%d/5）" % _player_line.get_filled_count()
			_round_info_label.text = ""
			_start_button.visible = false
			_restart_button.visible = false
			_player_backup.set_interactive(true)
			_player_line.set_interactive(true)

		GameState.BATTLING:
			_status_label.text = "对战中..."
			_start_button.visible = false
			_restart_button.visible = false
			_player_backup.set_interactive(false)
			_player_line.set_interactive(false)

		GameState.GAME_OVER:
			_total_score += _round_score
			_score_label.text = "累计分数: %d" % _total_score
			if _round_score > 0:
				_status_label.text = "本局胜利！得分: +%d" % _round_score
			elif _round_score < 0:
				_status_label.text = "本局失败... 得分: %d" % _round_score
			else:
				_status_label.text = "本局平局！得分: 0"
			_start_button.visible = false
			_restart_button.visible = true
			_player_backup.set_interactive(false)
			_player_line.set_interactive(false)

# ============================================================
#  信号回调
# ============================================================

func _on_start_pressed() -> void:
	_start_game()

func _on_restart_pressed() -> void:
	_reset_game()

func _on_element_selected(_type: int) -> void:
	pass

func _on_slot_clicked(index: int) -> void:
	if _game_state != GameState.PREPARING:
		return
	var selected_type := _player_backup.get_selected_type()
	if selected_type == Element.ElementType.NONE:
		return
	_player_line.place_element(index, selected_type)
	_status_label.text = "选择元素放入决斗栏（%d/5）" % _player_line.get_filled_count()

func _on_all_slots_filled() -> void:
	if _game_state == GameState.PREPARING:
		_start_battle()

# ============================================================
#  游戏流程
# ============================================================

func _start_game() -> void:
	_round_score = 0
	_current_round = 0
	_round_score_label.text = "本局得分: 0"
	_player_line.reset()
	_enemy_line.reset()
	_enemy_line.generate_random()
	_set_state(GameState.PREPARING)

func _start_battle() -> void:
	_set_state(GameState.BATTLING)
	_current_round = 0
	# 使用协程驱动逐回合对战
	_run_battle()

## 协程：逐回合执行对战，包含碰撞动画
func _run_battle() -> void:
	for round_idx in range(ROUND_COUNT):
		_current_round = round_idx
		_status_label.text = "对战中... 回合 %d/%d" % [round_idx + 1, ROUND_COUNT]

		# 揭示敌人当前回合的元素
		_enemy_line.reveal_element(round_idx)

		# 获取双方元素类型
		var player_type := _player_line.get_element(round_idx)
		var enemy_type := _enemy_line.get_element(round_idx)

		# 获取元素节点引用（用于确定起始位置）
		var player_elem := _player_line.get_slot_element(round_idx)
		var enemy_elem := _enemy_line.get_slot_element(round_idx)

		# ---- 播放碰撞飞行动画 ----
		await _play_collision(player_elem, enemy_elem, player_type, enemy_type)

		# ---- 猜拳判定 ----
		var result := _compare(player_type, enemy_type)
		_round_score += result

		# ---- 显示回合结果 ----
		_show_round_result(round_idx, player_type, enemy_type, result)

		# ---- 显示边缘闪光特效 ----
		await _play_border_flash(result)

		# 回合间短暂停顿
		await get_tree().create_timer(ROUND_PAUSE).timeout

	# 所有回合结束
	_set_state(GameState.GAME_OVER)

## 显示回合判定结果
func _show_round_result(round_idx: int, player_type: int, enemy_type: int, result: int) -> void:
	var player_name: String = Element.ELEMENT_NAMES.get(player_type, "?")
	var enemy_name: String = Element.ELEMENT_NAMES.get(enemy_type, "?")
	var result_text := ""
	match result:
		1:  result_text = "胜利！+1"
		-1: result_text = "失败 -1"
		0:  result_text = "平局"

	_round_info_label.text = "第%d回合: %s vs %s → %s" % [round_idx + 1, player_name, enemy_name, result_text]

	match result:
		1:  _round_info_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		-1: _round_info_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		0:  _round_info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	_round_score_label.text = "本局得分: %d" % _round_score

func _reset_game() -> void:
	_round_score = 0
	_current_round = 0
	_round_score_label.text = "本局得分: 0"
	_round_info_label.text = ""
	_player_line.reset()
	_enemy_line.reset()
	_player_backup.clear_selection()
	_set_state(GameState.IDLE)

# ============================================================
#  碰撞飞行动画
# ============================================================

## 播放双方元素飞向中央碰撞并粉碎的动画
func _play_collision(player_elem: Element, enemy_elem: Element,
		player_type: int, enemy_type: int) -> void:
	# 获取元素在全局坐标中的位置
	var p_global := player_elem.global_position
	var e_global := enemy_elem.global_position

	# 隐藏原始元素
	player_elem.visible = false
	enemy_elem.visible = false

	# 创建飞行副本（在主场景层级，不受容器约束）
	var p_copy := Element.new()
	p_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p_copy)
	p_copy.set_element(player_type)
	p_copy.global_position = p_global

	var e_copy := Element.new()
	e_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(e_copy)
	e_copy.set_element(enemy_type)
	e_copy.global_position = e_global

	# 碰撞目标位置（画面中央，双方在碰撞点左右各偏移半个元素宽度）
	var collision_point := Vector2(CENTER_X, CENTER_Y)
	var p_target := collision_point - Vector2(Element.SLOT_SIZE * 0.5, 0)
	var e_target := collision_point + Vector2(Element.SLOT_SIZE * 0.5, 0)

	# Tween飞行动画：双方同时飞向中央
	var tween := create_tween().set_parallel(true)
	tween.tween_property(p_copy, "global_position", p_target, FLY_DURATION)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(e_copy, "global_position", e_target, FLY_DURATION)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween.finished

	# ---- 碰撞粉碎效果 ----
	# 移除飞行副本
	p_copy.queue_free()
	e_copy.queue_free()

	# 在碰撞点生成粉碎粒子
	await _play_shatter_effect(collision_point)

## 播放粉碎粒子效果（用多个小方块向四周飞散模拟）
func _play_shatter_effect(center: Vector2) -> void:
	var particle_count := 16
	var particles: Array[ColorRect] = []

	# 创建粒子
	for i in range(particle_count):
		var p := ColorRect.new()
		p.size = Vector2(8, 8)
		p.color = Color(
			randf_range(0.6, 1.0),
			randf_range(0.4, 0.8),
			randf_range(0.2, 0.5),
			1.0
		)
		p.position = center - Vector2(4, 4)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		particles.append(p)

	# 粒子飞散动画
	var tween := create_tween().set_parallel(true)
	for i in range(particle_count):
		var angle := (TAU / particle_count) * i + randf_range(-0.3, 0.3)
		var dist := randf_range(60, 160)
		var target := center + Vector2(cos(angle), sin(angle)) * dist
		tween.tween_property(particles[i], "position", target, SHATTER_DURATION)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(particles[i], "modulate:a", 0.0, SHATTER_DURATION)\
			.set_ease(Tween.EASE_IN)
		# 粒子缩小
		tween.tween_property(particles[i], "scale", Vector2(0.2, 0.2), SHATTER_DURATION)
	await tween.finished

	# 清理粒子
	for p in particles:
		p.queue_free()

# ============================================================
#  边缘闪光特效
# ============================================================

## 根据胜负结果闪烁画面边缘颜色
func _play_border_flash(result: int) -> void:
	var color: Color
	match result:
		1:  color = Color(0.2, 0.9, 0.2, 0.25)   # 绿色 - 胜利
		-1: color = Color(0.9, 0.2, 0.2, 0.25)   # 红色 - 失败
		0:  color = Color(0.5, 0.5, 0.5, 0.2)     # 灰色 - 平局
		_:  return

	# 创建全屏半透明边框
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = color
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	# 淡入淡出
	flash.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 1.0, 0.15)
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	await tween.finished
	flash.queue_free()

# ============================================================
#  猜拳判定
# ============================================================

## 比较玩家和敌人的元素，返回：1=玩家胜, 0=平局, -1=玩家负
func _compare(player_type: int, enemy_type: int) -> int:
	if player_type == enemy_type:
		return 0
	# ROCK=0 胜 SCISSORS=1, SCISSORS=1 胜 PAPER=2, PAPER=2 胜 ROCK=0
	if (player_type - enemy_type + 3) % 3 == 2:
		return 1
	return -1
