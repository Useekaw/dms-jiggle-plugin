import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property var durations: {
        const raw = (pluginData && pluginData.durationPresetsMinutes) || "10,30,60,180,360";
        const mins = raw.split(",").map(s => parseInt(s.trim(), 10)).filter(n => !isNaN(n) && n > 0);
        const list = mins.map(m => ({
            label: formatDurationLabel(m),
            minutes: m
        }));
        list.push({
            label: JiggleI18n.t("unlimited"),
            minutes: 0
        });
        return list;
    }

    function formatDurationLabel(m) {
        if (m % 60 === 0) {
            const h = m / 60;
            return h + (h === 1 ? JiggleI18n.t("hour") : JiggleI18n.t("hours"));
        }
        return m + JiggleI18n.t("minutes");
    }

    function formatRemaining() {
        if (!JiggleService.active)
            return "";
        if (JiggleService.indefinite)
            return "∞";
        const m = Math.floor(JiggleService.remainingSecs / 60);
        const s = JiggleService.remainingSecs % 60;
        const mStr = String(m).padStart(JiggleService.remainingPadWidth, "0");
        return mStr + ":" + (s < 10 ? "0" : "") + s;
    }

    function statusText() {
        if (!JiggleService.active)
            return JiggleI18n.t("inactive");
        if (JiggleService.indefinite)
            return JiggleI18n.t("activeUnlimited");
        const m = Math.floor(JiggleService.remainingSecs / 60);
        const s = JiggleService.remainingSecs % 60;
        const time = m + ":" + (s < 10 ? "0" : "") + s;
        return JiggleI18n.t("activeRemaining", {
            time: time
        });
    }

    pillRightClickAction: () => {
        if (JiggleService.active)
            JiggleService.stop();
        else
            JiggleService.start(0);
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: content.implicitWidth
            height: root.widgetThickness

            Row {
                id: content
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    name: "mouse"
                    size: root.iconSize
                    color: JiggleService.active ? Theme.primary : Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: root.formatRemaining()
                    visible: JiggleService.active
                    color: Theme.primary
                    font.family: Theme.monoFontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            width: root.widgetThickness
            implicitHeight: content.implicitHeight

            Column {
                id: content
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    name: "mouse"
                    size: root.iconSize
                    color: JiggleService.active ? Theme.primary : Theme.surfaceText
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: root.formatRemaining()
                    visible: JiggleService.active
                    color: Theme.primary
                    font.family: Theme.monoFontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: jigglePopout

            headerText: "Mouse Jiggler"
            detailsText: root.statusText()
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingXS

                Repeater {
                    model: root.durations

                    DankButton {
                        width: parent.width
                        text: modelData.label
                        iconName: "play_arrow"
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.surfaceText
                        onClicked: {
                            JiggleService.start(modelData.minutes);
                            jigglePopout.closePopout();
                        }
                    }
                }

                DankButton {
                    width: parent.width
                    visible: JiggleService.active
                    text: JiggleI18n.t("stop")
                    iconName: "stop"
                    backgroundColor: Theme.error
                    textColor: Theme.errorText
                    onClicked: {
                        JiggleService.stop();
                        jigglePopout.closePopout();
                    }
                }
            }
        }
    }

    popoutWidth: 320
    popoutHeight: 340
}
