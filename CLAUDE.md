# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Spawn Chaos** is a Godot 4 game project (uses `gd_scene format=3` / Godot 4.x scene format). The project is in its early stages with a single `Main` scene (`Node2D` root).

## Engine & Language

- **Engine:** Godot 4.x
- **Scene format:** `.tscn` (text-based Godot scene files)
- **Project config:** `project.godot` (Godot's INI-style project configuration)
- **Scripting:** GDScript (`.gd` files) — Godot's primary scripting language

## Running the Project

Open the project in the Godot 4 editor by opening `project.godot`, or run from command line:

```bash
# Run the project (requires Godot 4 in PATH)
godot --path .
```

## Key Files

- `project.godot` — Project settings and configuration (entry point for Godot editor)
- `main.tscn` — Main scene (currently the root scene)
