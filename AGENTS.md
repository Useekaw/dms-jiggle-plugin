# AGENTS.md

Guidance for AI agents working in this repository.

## Project

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS)
plugin (`jiggle`) that adds a mouse-jiggler widget to the DankBar. Runtime is
QML only (no external tooling/build step) plus bash scripts in `scripts/`
that do the actual cursor movement. See `README.md` for architecture and
user-facing docs.

## Layout

```text
plugin.json          Plugin manifest (id, capabilities, entry points)
qmldir                Declares the two qmldir singletons below
JiggleService.qml     Singleton: owns the Process, start/stop/duration state
JiggleI18n.qml         Singleton: en/de string table
JiggleWidget.qml       Bar pill + popout UI (PluginComponent)
JiggleSettings.qml     Settings UI (PluginSettings)
scripts/                Bundled jiggle script variants (evemu, ydotool)
```

## Conventions

- Commits follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat`, `fix`, `chore`, `docs`, ...).
- No build step. QML files are loaded directly by DMS/Quickshell; keep them
  syntactically valid on every commit.
- German and English strings in `JiggleI18n.qml` must stay in sync — every
  key in `en` needs a matching key in `de` and vice versa.

## Local development

Symlink (or clone directly into) the DMS plugin directory:

```bash
ln -s "$(pwd)" ~/.config/DankMaterialShell/plugins/jiggle
dms ipc call plugin-scan scan
dms ipc call plugins enable jiggle
```

Reload after editing `JiggleWidget.qml` or `JiggleSettings.qml`:

```bash
dms ipc call plugins reload jiggle
```

**`JiggleService.qml` and `JiggleI18n.qml` are `qmldir` singletons.** DMS
caches singletons per QML engine instance; `plugins reload` does not
re-instantiate them, so changes there silently keep running the old code
until a full `dms restart`. This has caused real, hard-to-spot bugs during
development (a fix looked applied, reload succeeded with no errors, but the
old singleton was still live) — always restart, not just reload, after
touching either of those two files, and say so explicitly when reporting a
fix as verified.

Check for orphaned script processes before and after a restart:

```bash
pgrep -af "evemu-jiggle.sh|ydotool-jiggle.sh"
```

## Sizing gotcha in bar pill widgets

DMS's `BasePill` sizes the space it reserves in the bar from the loaded
delegate's `implicitWidth`/`implicitHeight`, **not** from `width`/`height`.
Binding `width:` on a pill's root item changes how it renders but not how
much space the bar reserves for it, which shows up as jitter or clipping
when the content's size changes at runtime (e.g. a countdown label
appearing/disappearing). Set `implicitWidth`/`implicitHeight` instead, and
let `Item`'s default `width: implicitWidth` binding do the rest — this is
also how DMS's own built-in bar widgets (`RamMonitor.qml`, `Weather.qml`,
etc.) do it.

## Testing

No test suite. Before committing:

```bash
bash -n scripts/*.sh
shellcheck -S warning scripts/*.sh   # if installed
python3 -c "import json; json.load(open('plugin.json'))"
```

QML changes can't be meaningfully lint-checked outside a real DMS
checkout (`qmllint` needs `qs.*` import paths from the DMS source tree to
resolve anything), so the practical verification loop is: reload/restart a
running DMS instance and check `journalctl --user -u dms.service` for QML
warnings/errors after loading the plugin.

## Reference

- [DMS plugin system docs](https://github.com/AvengeMedia/DankMaterialShell/blob/master/quickshell/PLUGINS/README.md)
- [Plugin manifest schema](https://github.com/AvengeMedia/DankMaterialShell/blob/master/quickshell/PLUGINS/plugin-schema.json)
- [DMS plugin registry](https://plugins.danklinux.com/)
