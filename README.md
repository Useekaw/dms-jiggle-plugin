# jiggle — Mouse Jiggler plugin for DankMaterialShell

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS)
DankBar widget that starts/stops a mouse-jiggle script, with configurable
duration presets and live status shown right on the bar icon.

Default duration presets: 10 / 30 / 60 / 180 / 360 minutes + Unlimited
(configurable). UI is English/German, follows the system locale.

## Architecture

- `JiggleService.qml` — `qmldir` singleton, owns the actual `Process`. Every
  widget instance (e.g. one per monitor) talks to the same singleton so a
  multi-bar setup doesn't spawn one jiggle process per bar. Each `start()`
  spawns a fresh `Process` instance instead of reusing one — a `runToken`
  guards against a late `onExited` from a just-superseded old instance
  wiping out freshly-set state (new duration).
- `JiggleI18n.qml` — `qmldir` singleton, English/German string table,
  language picked via `Qt.locale()`.
- `JiggleWidget.qml` — bar pill (icon + countdown) and popout (left click)
  with the duration buttons. Right-click on the icon is a shortcut: nothing
  running → start unlimited; something running → stop.
- `JiggleSettings.qml` — pick script variant, custom script path, and
  duration presets (Settings → Plugins → jiggle).
- `scripts/` — bundled script variants. The plugin itself doesn't pass any
  duration argument — it just runs the configured script and kills it after
  the chosen time (or on the Stop click) via SIGTERM, with a SIGKILL
  fallback after 2s if the script doesn't exit in time. Any script that
  exits cleanly on SIGTERM works here, including a fully custom one.

**Important when editing `JiggleService.qml` or `JiggleI18n.qml`:** both are
`qmldir` singletons. `dms ipc call plugins reload jiggle` only reloads the
widget/settings components — singletons stay loaded with their old code.
Use `dms restart` for singleton changes to actually take effect.

## Script variants

- `scripts/evemu-jiggle.sh` (default) — `sudo evemu-event` on the detected
  mouse event device. Needs passwordless sudo for `/usr/bin/evemu-event`.
- `scripts/ydotool-jiggle.sh` (alternative) — no sudo needed, but requires
  the `ydotool` package plus a running `ydotoold` service. Relative-move
  flags differ slightly between `ydotool` versions — check
  `ydotool mousemove --help` on your system before relying on it.

Custom script: pick "Custom script" in the plugin settings and enter an
absolute path. The only requirement is a clean exit on SIGTERM (no orphaned
`sudo` child process left behind).

## Installation

```bash
git clone git@github.com:Useekaw/dms-jiggle-plugin.git \
    ~/.config/DankMaterialShell/plugins/jiggle

dms ipc call plugin-scan scan
dms ipc call plugins enable jiggle
```

Then in DMS: Settings → Appearance → DankBar Layout → add the `jiggle`
widget to a section. `dms ipc call settings set barConfigs ...` does **not**
work for this — the IPC bridge explicitly rejects arrays/objects
(`Setting Objects and Arrays not supported`); only the GUI path (or editing
`settings.json` directly while DMS is stopped) can set `barConfigs`.

After further QML changes to the widget/settings files, a reload is enough
(see the singleton caveat above for `JiggleService.qml`/`JiggleI18n.qml`):

```bash
dms ipc call plugins reload jiggle
```

## Plugin registry

Built against the plugin manifest schema documented in DMS's
[`PLUGINS/plugin-schema.json`](https://github.com/AvengeMedia/DankMaterialShell/blob/master/quickshell/PLUGINS/plugin-schema.json),
so it should be installable via the [DMS plugin registry](https://plugins.danklinux.com/)
once listed there.

## Known limitation

State (active/remaining time) only lives in the running singleton — it does
not survive a DMS restart. For the desktop jiggle use case (session-length,
not days/weeks) that's an intentional trade-off against the complexity of
PID-file-based recovery.

## License

MIT, see [LICENSE](LICENSE).
