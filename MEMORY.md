# Memory

## Godot 4 GDScript Quirks Discovered

- **class_name resolution issues**: Godot 4.6 has circular dependency issues when scripts use `class_name` and reference each other. Solution: avoid `class_name`, use `preload()` for cross-script references and path-based `extends "res://path/to/script.gd"` for inheritance.
- **`:=` type inference failures**: `:=` cannot infer types from ternary expressions (`x if cond else y`), `.get()` calls, or nullable property access. Use explicit type declarations (`var x: float = ...`) for these cases.
- **`set_script()` at runtime**: Scripts can be attached to nodes at runtime via `set_script(preload(...))`. This works for manager nodes added in .tscn without a script.
- **Inner classes**: GDScript supports inner classes (`class Foo extends Node2D:`) within weapon scripts. Useful for missile projectiles, lightning effects, holy water pools.
- **Physics FPS**: Set `physics/common/physics_ticks_per_second=30` to match original Pyxel 30 FPS frame-counting logic.
- **Viewport scaling**: 256x224 with `window/stretch/mode="viewport"` and `textures/canvas_textures/default_texture_filter=0` gives pixel-perfect scaling.
- **macOS IMK messages**: Lines like `+[IMKClient subclass]: chose IMKClient_Modern` are benign macOS Japanese input method logs — not errors.
