import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "jiggle"

    StyledText {
        width: parent.width
        text: JiggleI18n.t("settingsIntro")
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SelectionSetting {
        settingKey: "scriptVariant"
        label: JiggleI18n.t("scriptVariantLabel")
        description: JiggleI18n.t("scriptVariantDescription")
        options: [
            { label: JiggleI18n.t("variantEvemu"), value: "evemu" },
            { label: JiggleI18n.t("variantYdotool"), value: "ydotool" },
            { label: JiggleI18n.t("variantCustom"), value: "custom" }
        ]
        defaultValue: "evemu"
    }

    StringSetting {
        settingKey: "customScriptPath"
        label: JiggleI18n.t("customPathLabel")
        description: JiggleI18n.t("customPathDescription")
        placeholder: "/home/usee/.local/bin/jiggle.sh"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "durationPresetsMinutes"
        label: JiggleI18n.t("durationsLabel")
        description: JiggleI18n.t("durationsDescription")
        placeholder: "10,30,60,180,360"
        defaultValue: "10,30,60,180,360"
    }
}
