# PSR - Godot 4.6 Game Project

## Identity & Language

See [AGENTS.md](AGENTS.md) for identity and language rules. Summary:
- Role: Senior game developer (Godot/GDScript primary, C++ secondary) + game designer
- Language: Chinese for explanations, English for technical terms, Chinese for code comments
- Style: Rigorous code logic with clear comments on key logic

## Project Context

- Engine: Godot 4.6, Forward Plus renderer
- Language: GDScript (primary)
- Resolution: 1920x1080, stretch mode: canvas_items
- Physics: Jolt Physics (3D)
- Main scene: `res://main.tscn`
- Game design docs: `PSR_game_design.md`, `PSR_game_addition_v1.1.md`

## Skills

This project has 6 Godot-specific skills in `skills/`. Activate them contextually:

### Core Skills (always consider)

- **godot-gdscript-patterns** (`skills/godot-gdscript-patterns/SKILL.md`)
  - When: Writing GDScript, implementing state machines, object pools, component systems, save/load, signals architecture
  - Provides: Production-grade patterns for Godot 4

- **godot-best-practices** (`skills/godot-best-practices/SKILL.md`)
  - When: Generating any GDScript code, reviewing code quality, naming conventions, type hints, node references
  - Provides: Coding standards aligned with official GDScript style guide

### Extension Skills (activate on demand)

- **godot-development** (`skills/godot-development/SKILL.md`)
  - When: Creating/modifying scenes, adding nodes, project structure, using MCP Godot tools
  - Provides: Scene building, node management, MCP tool automation

- **godot-ui** (`skills/godot-ui/SKILL.md`)
  - When: Creating menus, HUDs, inventories, dialogue systems, themes, Control nodes, responsive layout
  - Provides: UI patterns, theme system, accessibility, gamepad navigation

- **godot-optimization** (`skills/godot-optimization/SKILL.md`)
  - When: Performance issues, FPS drops, profiling, memory optimization, mobile/web optimization
  - Provides: Profiling workflow, bottleneck identification, optimization techniques

- **godot-asset-generator** (`skills/godot-asset-generator/SKILL.md`)
  - When: Generating 2D game sprites/tiles/icons via AI (DALL-E, Replicate, fal.ai), sprite sheet packing, Godot import config
  - Requires: Deno runtime + API keys (OPENAI_API_KEY / REPLICATE_API_TOKEN / FAL_KEY)

## Workflow

1. Before writing GDScript, always reference **godot-best-practices** for naming/typing/structure
2. For architecture decisions, reference **godot-gdscript-patterns** for proven patterns
3. Read the relevant SKILL.md in full when a skill is activated for the first time in a session
4. When using Godot MCP tools, follow **godot-development** workflow
