pragma Singleton

import QtQuick

// Small de/en string table. English is the base/fallback; German is what
// this plugin was first written in. Only two languages and ~15 short
// strings total, so a couple of inline objects beat JSON bundle files + XHR
// loading for this scope.
QtObject {
    id: root

    readonly property string locale: {
        const name = (Qt.locale().name || "en_US").toString().toLowerCase();
        return name.indexOf("de") === 0 ? "de" : "en";
    }

    readonly property var en: ({
            unlimited: "Unlimited",
            hour: " hour",
            hours: " hours",
            minutes: " minutes",
            inactive: "Inactive",
            activeUnlimited: "Active – unlimited",
            activeRemaining: "Active – {time} left",
            stop: "Stop",
            settingsIntro: "Which script should move the cursor? Two variants ship in the plugin folder under scripts/; alternatively point at your own script.",
            scriptVariantLabel: "Script variant",
            scriptVariantDescription: "evemu needs sudo rights for evemu-event, ydotool needs a running ydotoold service.",
            variantEvemu: "evemu-event (sudo, default)",
            variantYdotool: "ydotool (no sudo, needs ydotoold)",
            variantCustom: "Custom script",
            customPathLabel: "Path to your own script",
            customPathDescription: "Only relevant for the \"Custom script\" variant. Absolute path, executable, should exit cleanly on SIGTERM.",
            durationsLabel: "Durations (minutes, comma-separated)",
            durationsDescription: "Buttons shown in the popout, in this order. \"Unlimited\" is always appended automatically."
        })

    readonly property var de: ({
            unlimited: "Unbegrenzt",
            hour: " Stunde",
            hours: " Stunden",
            minutes: " Minuten",
            inactive: "Inaktiv",
            activeUnlimited: "Aktiv – unbegrenzt",
            activeRemaining: "Aktiv – noch {time}",
            stop: "Stopp",
            settingsIntro: "Welches Skript soll den Cursor bewegen? Zwei Varianten liegen im Plugin-Ordner unter scripts/ bei; alternativ auf ein eigenes Skript zeigen.",
            scriptVariantLabel: "Skript-Variante",
            scriptVariantDescription: "evemu braucht sudo-Rechte auf evemu-event, ydotool braucht einen laufenden ydotoold-Dienst.",
            variantEvemu: "evemu-event (sudo, Standard)",
            variantYdotool: "ydotool (kein sudo, ydotoold nötig)",
            variantCustom: "Eigenes Skript",
            customPathLabel: "Pfad zum eigenen Skript",
            customPathDescription: "Nur relevant bei Variante \"Eigenes Skript\". Absoluter Pfad, ausführbar, sollte auf SIGTERM sauber beenden.",
            durationsLabel: "Zeitspannen (Minuten, kommagetrennt)",
            durationsDescription: "Buttons im Popout, in dieser Reihenfolge. \"Unbegrenzt\" wird immer automatisch zusätzlich angehängt."
        })

    function t(key, params) {
        const table = locale === "de" ? de : en;
        let text = table[key];
        if (text === undefined)
            text = en[key] !== undefined ? en[key] : key;
        if (!params)
            return text;
        for (const p in params) {
            text = text.replace("{" + p + "}", params[p]);
        }
        return text;
    }
}
