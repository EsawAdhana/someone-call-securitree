# someone-call-securitree

A Godot 4 game project — "Someone Call Securitree".

## Overview

A 2D game built in Godot 4 with a main map, multiple levels and locations, character and morale systems, an audio manager, and an in-game pause menu. The repo includes the Godot project source plus a pre-built HTML5 export.

## Stack

- Godot 4 (GDScript)
- Forward+ renderer
- HTML5 export target

## Project layout

- `project.godot` — engine configuration and autoload managers
- `scenes/` — game scenes (`.tscn`)
- `scripts/` — gameplay scripts (`.gd`)
- `assets/`, `audio/` — game assets
- `*.html`, `*.js`, `*.pck`, `*.wasm` — HTML5 export artifacts
- `export_presets.cfg` — Godot export configuration

## Getting started

Open `project.godot` in Godot 4 to edit or run. To play the HTML5 build, serve the repo root over HTTP (Godot's web exports require a server, not `file://`) and open `index.html`.

```bash
python -m http.server
```

## Status

Game jam / coursework project.
