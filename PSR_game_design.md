本文件为PSR 游戏整体设计思路

> **项目信息**: Godot 4.6 | GDScript | 窗口尺寸 1920×1080 | 竖屏布局 | 2D

---

# 1. 游戏逻辑

## 1.1 核心玩法
游戏主要玩法是一个对抗模式，由玩家对战敌人。
左侧代表玩家，右侧代表敌人。二者分别会有一个长度为5个格的"决斗栏"，"决斗栏"中每个元素都是石头、剪刀、布中的一种。每次游戏分为5个回合，每个回合玩家和敌人分别将"猜拳"，即将当前"决斗栏"中第一个元素相互比较并将其移出队列，遵从剪刀赢过布，布赢过石头，石头赢过剪刀的简单逻辑（元素相同时平局）。如此循环直到"决斗栏"中双方再无元素。每次玩家胜利，+1分，平局不加分，玩家输则-1分。初始分数为0，每个回合分数累计。
玩家额外有一个"元素备用栏"，其中初始有三个基本元素：剪刀、石头、布，这些元素可以重复使用。每回合玩家需要将这些元素拖拽到玩家"决斗栏"的5个格之一，组成玩家的决斗序列。敌人的决斗序列是随机生成的（每个格子都是剪刀、石头、布中的某一个）。

## 1.2 元素类型定义
使用枚举 `ElementType` 统一管理：
```
enum ElementType { ROCK = 0, SCISSORS = 1, PAPER = 2 }
```
- ROCK（石头）：胜 SCISSORS，负 PAPER
- SCISSORS（剪刀）：胜 PAPER，负 ROCK
- PAPER（布）：胜 ROCK，负 SCISSORS

胜负判定函数（伪代码）：
```
func compare(player: ElementType, enemy: ElementType) -> int:
	if player == enemy: return 0       # 平局
	if (player - enemy + 3) % 3 == 2:  # 胜利（ROCK>SCISSORS, SCISSORS>PAPER, PAPER>ROCK）
		return 1
	return -1                          # 失败
```

## 1.3 游戏状态机
游戏存在以下状态，使用枚举 `GameState` 管理：
```
enum GameState { IDLE, PREPARING, BATTLING, ROUND_RESULT, GAME_OVER }
```

状态流转：
```
IDLE（等待开始）
  ↓ 玩家点击"开始"按钮
PREPARING（准备阶段）
  | - 敌人决斗栏自动随机生成5个元素（元素内容对玩家隐藏，显示为"?"）
  | - 玩家从"元素备用栏"拖拽元素到"决斗栏"的5个格子
  | - 玩家决斗栏5个格子全部填满后，自动进入下一状态
  ↓
BATTLING（对战阶段）
  | - 从第1格到第5格，依次进行回合对决
  | - 每回合：双方最前方的元素飞向画面中间碰撞 → 判定胜负 → 显示结果
  | - 每回合之间有约1.5秒间隔（用于播放动画和特效）
  ↓ 5回合全部结束
GAME_OVER（结算阶段）
  | - 显示本局总分和累计分数
  | - 显示"再来一局"按钮
  ↓ 玩家点击"再来一局"
IDLE（回到等待状态，场景重置）
```

## 1.4 分数系统
- `round_score: int`：本局得分，每局开始时清零
- `total_score: int`：累计总分，跨局累计，游戏运行期间不清零
- 每回合结算：胜利 +1，平局 +0，失败 -1
- 本局结束时：`total_score += round_score`

## 1.5 拖拽机制详细说明
1. 玩家"元素备用栏"中有3个元素图标（石头、剪刀、布），它们是**拖拽源**，可以无限次使用（拖拽后不消失）
2. 玩家"决斗栏"中有5个**空格子**，它们是**放置目标（drop target）**
3. 拖拽流程：
   - 玩家按住备用栏中的某个元素 → 生成一个跟随鼠标的"拖拽副本"
   - 拖到决斗栏的空格子上松开 → 格子显示对应元素图标
   - 拖到非法区域松开 → 拖拽副本消失，无事发生
   - 已填充的格子可以再次被新元素覆盖（替换）
4. 当5个格子全部填充后，"开战"自动触发（或显示一个"确认"按钮让玩家确认）

---

# 2. 代码框架

## 2.1 文件结构
```
res://
├── main.gd              # 主场景脚本
├── main.tscn            # 主场景
├── enemy_line.gd        # 敌人决斗栏脚本
├── enemy_line.tscn      # 敌人决斗栏场景
├── player_line.gd       # 玩家决斗栏脚本
├── player_line.tscn     # 玩家决斗栏场景
├── player_backup.gd     # 玩家元素备用栏脚本
├── player_backup.tscn   # 玩家元素备用栏场景
├── element.gd           # 单个元素脚本
├── element.tscn         # 单个元素场景
├── art/                 # 美术资源（已有部分资源）
├── fonts/               # 字体资源
└── project.godot        # 项目配置
```

## 2.2 各模块职责与接口

### 2.2.1 element（元素 - 基础组件）
**场景结构**: `element.tscn`
```
Element (TextureRect)         # 根节点，显示元素图标
```

**脚本**: `element.gd`
- **属性**:
  - `element_type: ElementType` — 该元素的类型（ROCK/SCISSORS/PAPER）
  - `is_draggable: bool = false` — 是否可拖拽（备用栏中的元素为true）
  - `is_placeholder: bool = false` — 是否为决斗栏中的空位占位符
- **方法**:
  - `set_element(type: ElementType)` — 设置元素类型并更新对应贴图
  - `get_element() -> ElementType` — 获取当前元素类型
  - `clear()` — 清空元素，恢复为空位状态
  - `show_hidden()` — 显示为"?"（用于隐藏敌人元素）
  - `reveal()` — 揭示实际元素（对战时使用）
- **贴图映射**: 需要为石头/剪刀/布各准备一张图标（可先用简单色块或文字占位）
  - ROCK → 石头图标
  - SCISSORS → 剪刀图标
  - PAPER → 布图标
  - HIDDEN → "?"图标

### 2.2.2 player_backup（玩家元素备用栏）
**场景结构**: `player_backup.tscn`
```
PlayerBackup (HBoxContainer)       # 水平排列3个元素
  ├── RockElement (element.tscn)    # 石头，is_draggable=true
  ├── ScissorsElement (element.tscn)# 剪刀，is_draggable=true
  └── PaperElement (element.tscn)   # 布，is_draggable=true
```

**脚本**: `player_backup.gd`
- **职责**: 初始化3个可拖拽元素源；处理拖拽开始事件
- **信号**:
  - `element_drag_started(type: ElementType)` — 当玩家开始拖拽某个元素时发射
- **方法**:
  - `_ready()` — 初始化3个元素（ROCK, SCISSORS, PAPER），设为可拖拽
  - `set_interactive(enabled: bool)` — 启用/禁用拖拽交互（对战阶段禁用）

### 2.2.3 player_line（玩家决斗栏）
**场景结构**: `player_line.tscn`
```
PlayerLine (VBoxContainer)         # 垂直排列5个格子（从上到下为第1格到第5格）
  ├── Slot1 (element.tscn)         # is_placeholder=true
  ├── Slot2 (element.tscn)
  ├── Slot3 (element.tscn)
  ├── Slot4 (element.tscn)
  └── Slot5 (element.tscn)
```

**脚本**: `player_line.gd`
- **属性**:
  - `slots: Array[ElementType]` — 长度为5的数组，记录每个格子的元素类型，初始为空(-1)
- **信号**:
  - `all_slots_filled` — 当5个格子全部填满时发射
  - `slot_updated(index: int, type: ElementType)` — 某个格子被填充/更新时发射
- **方法**:
  - `place_element(slot_index: int, type: ElementType)` — 在指定格子放入元素
  - `get_element(slot_index: int) -> ElementType` — 获取指定格子的元素
  - `get_all_elements() -> Array[ElementType]` — 获取全部5个格子的元素序列
  - `is_full() -> bool` — 判断5个格子是否全部填满
  - `reset()` — 清空所有格子，恢复初始状态
  - `remove_first() -> ElementType` — 移除并返回第一个元素（对战时使用）
  - `set_interactive(enabled: bool)` — 启用/禁用放置交互

### 2.2.4 enemy_line（敌人决斗栏）
**场景结构**: `enemy_line.tscn`
```
EnemyLine (VBoxContainer)         # 垂直排列5个格子
  ├── Slot1 (element.tscn)
  ├── Slot2 (element.tscn)
  ├── Slot3 (element.tscn)
  ├── Slot4 (element.tscn)
  └── Slot5 (element.tscn)
```

**脚本**: `enemy_line.gd`
- **属性**:
  - `slots: Array[ElementType]` — 长度为5的数组
- **方法**:
  - `generate_random()` — 为5个格子随机生成元素，并显示为"?"隐藏状态
  - `get_element(slot_index: int) -> ElementType` — 获取指定格子的元素
  - `get_all_elements() -> Array[ElementType]` — 获取全部5个格子的元素序列
  - `reveal_element(slot_index: int)` — 揭示指定格子的元素（对战回合时逐个揭示）
  - `remove_first() -> ElementType` — 移除并返回第一个元素
  - `reset()` — 清空所有格子

### 2.2.5 main（主场景 - 总控制器）
**场景结构**: `main.tscn`
```
Main (Control)                          # 根节点，全屏Control
  ├── Background (ColorRect)            # 背景
  ├── PlayerBackup (player_backup.tscn) # 左上方 - 玩家元素备用栏
  ├── PlayerLine (player_line.tscn)     # 左中 - 玩家决斗栏
  ├── EnemyLine (enemy_line.tscn)       # 右中 - 敌人决斗栏
  ├── CenterArea (Control)              # 中央区域 - 用于元素碰撞动画
  ├── UI (CanvasLayer)                  # UI层
  │   ├── ScoreLabel (Label)            # 显示累计分数
  │   ├── RoundScoreLabel (Label)       # 显示本局得分
  │   ├── StartButton (Button)          # 开始按钮
  │   └── RestartButton (Button)        # 再来一局按钮（默认隐藏）
  ├── EffectLayer (CanvasLayer)         # 特效层
  │   └── BorderEffect (ColorRect)      # 边缘颜色特效（默认透明）
  └── AudioPlayer (AudioStreamPlayer)   # 音效播放
```

**脚本**: `main.gd`
- **属性**:
  - `game_state: GameState` — 当前游戏状态
  - `round_score: int` — 本局分数
  - `total_score: int` — 累计总分
  - `current_round: int` — 当前回合索引（0-4）
- **方法**:
  - `_ready()` — 初始化，连接子节点信号，设置初始状态为IDLE
  - `start_game()` — 切换到PREPARING状态，敌人生成序列，启用玩家拖拽
  - `on_all_slots_filled()` — 连接player_line.all_slots_filled信号，开始对战
  - `start_battle()` — 切换到BATTLING状态，禁用拖拽，逐回合执行对决
  - `execute_round(round_index: int)` — 执行单个回合：取出双方元素→播放碰撞动画→判定→更新分数→显示特效
  - `compare(player_el: ElementType, enemy_el: ElementType) -> int` — 猜拳判定（返回1/0/-1）
  - `show_round_effect(result: int)` — 根据胜负显示边缘颜色特效
  - `play_collision_animation(p_el, e_el)` — 播放双方元素飞向中间碰撞的动画（使用Tween）
  - `end_game()` — 切换到GAME_OVER，计算总分，显示结算UI
  - `reset_game()` — 重置场景回到IDLE

---

# 3. 游戏画面与布局

## 3.1 整体布局（480×720竖屏）
```
┌──────────────────────────────┐ y=0
│  玩家"元素备用栏"             │ y≈50~120
│  [石头] [剪刀] [布]          │ (左上区域，水平排列)
│                              │
│                              │
│ 玩家决斗栏    敌人决斗栏      │ y≈180~550
│ [格1]         [格1]          │ (左中 vs 右中，垂直排列)
│ [格2]         [格2]          │
│ [格3]   ←碰撞→ [格3]         │ (中间为碰撞动画区)
│ [格4]         [格4]          │
│ [格5]         [格5]          │
│                              │
│──────────────────────────────│ y≈600
│  分数: 0    [开始游戏]       │ (底部UI区)
└──────────────────────────────┘ y=720
```

## 3.2 布局参考坐标（可根据实际美术微调）
| 组件 | 位置/锚点说明 |
|------|--------------|
| PlayerBackup | 左上区域，约 position(30, 50)，3个元素水平排列，间距20px |
| PlayerLine | 左中区域，约 position(60, 180)，5个格子垂直排列，间距15px |
| EnemyLine | 右中区域，约 position(340, 180)，5个格子垂直排列，间距15px |
| CenterArea | 画面中央，约 position(200, 180)，宽80px，用于碰撞动画 |
| ScoreLabel | 底部左侧，约 position(30, 650) |
| StartButton | 底部中央，约 position(180, 640)，尺寸120×50 |

## 3.3 元素格子尺寸
- 每个元素格子（slot）: 约 **64×64 像素**
- 格子间距: 约 **15px**
- 备用栏元素: 同 64×64，间距约 20px

## 3.4 特效说明

### 3.4.1 回合碰撞动画
每回合对决时：
1. 玩家当前格子中的元素从左侧飞向画面中央（Tween，约0.4秒）
2. 敌人当前格子中的元素从右侧飞向画面中央（Tween，约0.4秒，同时进行）
3. 两个元素在中央碰撞 → 播放粉碎粒子特效（GPUParticles2D，约0.5秒）
4. 碰撞后两个元素消失

### 3.4.2 边缘颜色特效
- 胜利：画面四边呈现**绿色半透明边框**（Color(0, 1, 0, 0.3)），持续约0.8秒后淡出
- 失败：画面四边呈现**红色半透明边框**（Color(1, 0, 0, 0.3)），持续约0.8秒后淡出
- 平局：画面四边呈现**灰色半透明边框**（Color(0.5, 0.5, 0.5, 0.3)），持续约0.8秒后淡出
- 实现方式：使用一个全屏 `ColorRect`，通过 Tween 控制其 `modulate.a` 从0→目标→0

### 3.4.3 碰撞粒子特效
- 使用 `GPUParticles2D` 节点
- 粒子数量: 约20-30个
- 生命周期: 0.5秒
- 向四周扩散
- 颜色可根据胜负变化（胜绿/负红/平白）

---

# 4. 美术资源需求

## 4.1 需要的图标资源（首期可用简单占位图）
| 资源名 | 说明 | 建议尺寸 |
|--------|------|---------|
| `rock_icon.png` | 石头图标 | 64×64 |
| `scissors_icon.png` | 剪刀图标 | 64×64 |
| `paper_icon.png` | 布图标 | 64×64 |
| `hidden_icon.png` | 未揭示元素"?"图标 | 64×64 |
| `empty_slot.png` | 空格子背景 | 64×64 |

## 4.2 占位方案
在正式美术资源完成之前，可以通过代码绘制简单占位图：
- 石头：灰色圆形 + "R"文字
- 剪刀：黄色菱形 + "S"文字
- 布：蓝色方形 + "P"文字
- 隐藏：深灰色方形 + "?"文字
- 空位：浅灰色虚线边框

---

# 5. 信号通信架构
```
player_backup
  ├── element_drag_started(type) ──→ main（通知主场景拖拽开始）

player_line
  ├── all_slots_filled ──→ main.on_all_slots_filled()（触发对战）
  └── slot_updated(index, type) ──→ main（可选，用于UI更新）

main
  ├── StartButton.pressed ──→ main.start_game()
  ├── RestartButton.pressed ──→ main.reset_game()
  └── 内部Tween/Timer ──→ 控制回合节奏
```

---

# 6. 开发优先级与里程碑

## Phase 1：核心功能（最小可玩版本）
1. 实现 `element.tscn/gd`：元素类型、贴图切换（用占位图）
2. 实现 `enemy_line.tscn/gd`：随机生成5个元素
3. 实现 `player_line.tscn/gd`：5个空格子，支持点击放置元素（先用点击代替拖拽）
4. 实现 `player_backup.tscn/gd`：3个元素源，点击选中
5. 实现 `main.tscn/gd`：状态机、猜拳判定、分数系统、基本UI
6. 可以完整走通一局游戏流程

## Phase 2：交互优化
7. 将点击放置升级为拖拽放置
8. 添加碰撞飞行动画（Tween）
9. 添加边缘颜色特效
10. 添加粒子碰撞特效

## Phase 3：体验打磨
11. 替换正式美术资源
12. 添加音效
13. 添加过渡动画
14. UI美化