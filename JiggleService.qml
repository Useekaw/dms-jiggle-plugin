pragma Singleton

import QtQuick
import Quickshell.Io
import qs.Services

// Single source of truth for the jiggle process. Declared as a qmldir
// singleton so every JiggleWidget instance (one per monitor/bar) shares the
// same state instead of each spawning its own background script.
//
// Each start() spawns a fresh Process object rather than reusing one across
// restarts: QProcess can't reliably be re-started while a previous SIGTERM
// is still in flight, and re-arming a single shared Process caused the old
// instance's async onExited to land after the new run had begun, wiping the
// just-set state back to zero. runToken guards state resets against that
// same class of stale-exit race; exactly one place (each instance's own
// "exited" handler) ever destroys it, so killTimer only ever escalates the
// signal strength, never the object lifetime — avoids double-destroy /
// dangling-reference races between the two cleanup paths.
QtObject {
    id: root

    readonly property string pluginId: "jiggle"

    readonly property string defaultEvemuScript: PluginService.pluginDirectory + "/jiggle/scripts/evemu-jiggle.sh"
    readonly property string defaultYdotoolScript: PluginService.pluginDirectory + "/jiggle/scripts/ydotool-jiggle.sh"

    property string scriptVariant: PluginService.loadPluginData(pluginId, "scriptVariant", "evemu")
    property string customScriptPath: PluginService.loadPluginData(pluginId, "customScriptPath", "")

    readonly property string scriptPath: {
        if (scriptVariant === "custom")
            return customScriptPath;
        if (scriptVariant === "ydotool")
            return defaultYdotoolScript;
        return defaultEvemuScript;
    }

    readonly property bool active: currentProc !== null && currentProc.running
    property bool indefinite: false
    property int endEpochSecs: 0
    property int remainingSecs: 0
    property int remainingPadWidth: 2

    property var currentProc: null
    property int runToken: 0

    function start(minutes) {
        if (!scriptPath) {
            console.warn("JiggleService: no script configured");
            return;
        }

        runToken++;
        const myToken = runToken;
        _retireCurrent();

        indefinite = minutes <= 0;
        remainingSecs = indefinite ? 0 : minutes * 60;
        endEpochSecs = indefinite ? 0 : Math.floor(Date.now() / 1000) + minutes * 60;
        remainingPadWidth = indefinite ? 2 : Math.max(1, String(minutes).length);

        const p = procComponent.createObject(root, {
            command: [scriptPath]
        });
        p.exited.connect(function (exitCode, exitStatus) {
            if (myToken === root.runToken) {
                root.indefinite = false;
                root.endEpochSecs = 0;
                root.remainingSecs = 0;
                root.currentProc = null;
            }
            if (killTimer.target === p) {
                killTimer.stop();
                killTimer.target = null;
            }
            p.destroy();
        });
        currentProc = p;
        p.running = true;
    }

    function stop() {
        runToken++;
        _retireCurrent();
        indefinite = false;
        endEpochSecs = 0;
        remainingSecs = 0;
    }

    // Sends the current process on its way out without waiting for it to
    // actually exit - start() can spawn the replacement immediately. Object
    // lifetime is still owned solely by that process's own exited handler.
    function _retireCurrent() {
        if (!currentProc)
            return;
        const p = currentProc;
        currentProc = null;
        if (!p.running)
            return;

        p.running = false;
        if (killTimer.target && killTimer.target !== p && killTimer.target.running)
            killTimer.target.signal(9);
        killTimer.target = p;
        killTimer.restart();
    }

    property Connections _settingsSync: Connections {
        target: PluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId !== root.pluginId)
                return;
            root.scriptVariant = PluginService.loadPluginData(root.pluginId, "scriptVariant", "evemu");
            root.customScriptPath = PluginService.loadPluginData(root.pluginId, "customScriptPath", "");
        }
    }

    property Timer killTimer: Timer {
        interval: 2000
        property var target: null
        onTriggered: {
            if (target && target.running)
                target.signal(9);
            target = null;
        }
    }

    property Timer tickTimer: Timer {
        interval: 1000
        repeat: true
        running: root.active && !root.indefinite
        onTriggered: {
            const now = Math.floor(Date.now() / 1000);
            root.remainingSecs = Math.max(0, root.endEpochSecs - now);
            if (root.remainingSecs <= 0)
                root.stop();
        }
    }

    property Component procComponent: Component {
        Process {
            stderr: StdioCollector {
                onStreamFinished: {
                    if (text.trim())
                        console.warn("JiggleService stderr:", text.trim());
                }
            }
        }
    }
}
