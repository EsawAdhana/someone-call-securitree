# someone-call-securitree

A 2D game built in Godot 4. Main map with multiple levels and locations, plus character, morale, audio, and pause systems wired up as autoloaded singletons. The repo includes the Godot project source as well as a pre-built HTML5 export so you can play it in the browser.

Scenes live in `scenes/`, gameplay scripts in `scripts/`, art and audio in `assets/` and `audio/`. Engine config is in `project.godot`; export setup is in `export_presets.cfg`.

## Running it

Open `project.godot` in Godot 4 to edit or run the project. To play the HTML5 build, serve the repo root over HTTP (Godot web exports won't run from `file://`):

```bash
python -m http.server
```

Then open `index.html` in your browser.
