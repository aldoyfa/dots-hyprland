//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
// Display mode switcher (Super+P). Standalone so the end4-pC checkout stays untouched.
// Colours come from the same matugen palette the shell uses, so it follows the wallpaper.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string applyScript: home + "/.config/hypr/custom/scripts/display-mode.sh"

    // Material palette, with dark fallbacks until colors.json is read
    property var pal: ({})
    function c(key, fallback) { return pal[key] ?? fallback; }
    readonly property color colSurface: c("surface_container_low", "#191c20")
    readonly property color colTile: c("surface_container_high", "#272a2f")
    readonly property color colTileHover: c("surface_container_highest", "#32353a")
    readonly property color colOnSurface: c("on_surface", "#e1e2e8")
    readonly property color colSubtext: c("on_surface_variant", "#c3c6cf")
    readonly property color colPrimary: c("primary", "#a4c9fe")
    readonly property color colOnPrimary: c("on_primary", "#00315c")
    readonly property color colSecContainer: c("secondary_container", "#3c4758")
    readonly property color colOnSecContainer: c("on_secondary_container", "#d8e3f8")
    readonly property color colOutline: c("outline_variant", "#43474e")
    readonly property string fontMain: "Google Sans Flex"
    readonly property string fontIcons: "Material Symbols Rounded"

    // Monitor state
    property string internalName: "eDP-1"
    property string externalName: ""
    property string currentMode: "internal"
    property int selected: 0
    property bool shown: false
    readonly property bool hasExternal: externalName !== ""

    readonly property var modes: [
        { id: "internal", icon: "laptop_chromebook", label: "Laptop only", needsExternal: false },
        { id: "mirror", icon: "screen_share", label: "Duplicate", needsExternal: true },
        { id: "extend-right", icon: "dock_to_left", label: "Extend right", needsExternal: true },
        { id: "extend-left", icon: "dock_to_right", label: "Extend left", needsExternal: true },
        { id: "external", icon: "tv", label: "External only", needsExternal: true }
    ]

    function usable(i) { return hasExternal || !modes[i].needsExternal; }
    function step(dir) {
        let i = selected;
        for (let n = 0; n < modes.length; n++) {
            i = (i + dir + modes.length) % modes.length;
            if (usable(i)) break;
        }
        selected = i;
    }
    function apply(i) {
        if (!usable(i)) return;
        Quickshell.execDetached([applyScript, modes[i].id]);
        close();
    }
    function close() {
        shown = false;
        quitTimer.start();
    }

    Timer { id: quitTimer; interval: 180; onTriggered: Qt.quit() }

    FileView {
        path: root.home + "/.local/state/quickshell/user/generated/colors.json"
        onLoaded: {
            try { root.pal = JSON.parse(text()); } catch (e) {}
        }
    }

    Process {
        running: true
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = [];
                try { list = JSON.parse(text); } catch (e) {}
                const internal = list.find(m => /eDP|LVDS|DSI/i.test(m.name));
                const external = list.find(m => m !== internal);
                if (internal) root.internalName = internal.name;
                root.externalName = external ? external.name : "";
                let mode = "internal";
                if (external && !external.disabled) {
                    if (external.mirrorOf && external.mirrorOf !== "none") mode = "mirror";
                    else if (internal && internal.disabled) mode = "external";
                    else mode = (internal && external.x < internal.x) ? "extend-left" : "extend-right";
                }
                root.currentMode = mode;
                root.selected = Math.max(0, root.modes.findIndex(m => m.id === mode));
                root.shown = true;
            }
        }
    }

    // Pressing Super+P again while open moves to the next mode
    IpcHandler {
        target: "displaySwitcher"
        function next(): void { root.step(1); }
        function close(): void { root.close(); }
    }

    PanelWindow {
        id: win
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:displaySwitcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // Scrim, click outside to dismiss
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.35 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: content.implicitWidth + 48
            height: content.implicitHeight + 44
            radius: 30
            color: root.colSurface
            border.width: 1
            border.color: root.colOutline
            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.92
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) root.close();
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab || event.key === Qt.Key_L || event.key === Qt.Key_P) root.step(1);
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab || event.key === Qt.Key_H) root.step(-1);
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.apply(root.selected);
                else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) root.apply(event.key - Qt.Key_1);
                else return;
                event.accepted = true;
            }
            MouseArea { anchors.fill: parent } // swallow clicks on the card

            ColumnLayout {
                id: content
                anchors.centerIn: parent
                spacing: 18

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        implicitWidth: 40; implicitHeight: 40; radius: 20
                        color: root.colSecContainer
                        Text {
                            anchors.centerIn: parent
                            text: "desktop_windows"
                            font.family: root.fontIcons; font.pixelSize: 22
                            color: root.colOnSecContainer
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: "Display"
                            font.family: root.fontMain; font.pixelSize: 19; font.weight: Font.Medium
                            color: root.colOnSurface
                        }
                        Text {
                            text: root.hasExternal ? `${root.internalName}  +  ${root.externalName}` : "No external display detected"
                            font.family: root.fontMain; font.pixelSize: 13
                            color: root.colSubtext
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Super+P next  ·  Enter apply  ·  Esc close"
                        font.family: root.fontMain; font.pixelSize: 12
                        color: root.colSubtext
                        Layout.alignment: Qt.AlignBottom
                    }
                }

                RowLayout {
                    spacing: 10
                    Repeater {
                        model: root.modes
                        delegate: Rectangle {
                            id: tile
                            required property int index
                            required property var modelData
                            readonly property bool isSelected: root.selected === index
                            readonly property bool isCurrent: root.currentMode === modelData.id
                            readonly property bool enabledTile: root.usable(index)
                            implicitWidth: 138
                            implicitHeight: 128
                            radius: isSelected ? 36 : 22
                            color: isSelected ? root.colPrimary : (hover.containsMouse && enabledTile ? root.colTileHover : root.colTile)
                            opacity: enabledTile ? 1 : 0.38
                            Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 140 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: tile.modelData.icon
                                    font.family: root.fontIcons; font.pixelSize: 40
                                    color: tile.isSelected ? root.colOnPrimary : root.colOnSurface
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: tile.modelData.label
                                    font.family: root.fontMain; font.pixelSize: 14; font.weight: Font.Medium
                                    color: tile.isSelected ? root.colOnPrimary : root.colOnSurface
                                }
                            }
                            // "active now" dot
                            Rectangle {
                                visible: tile.isCurrent
                                anchors { top: parent.top; right: parent.right; margins: 14 }
                                width: 8; height: 8; radius: 4
                                color: tile.isSelected ? root.colOnPrimary : root.colPrimary
                            }
                            // number hint
                            Text {
                                anchors { top: parent.top; left: parent.left; margins: 12 }
                                text: tile.index + 1
                                font.family: root.fontMain; font.pixelSize: 11
                                color: tile.isSelected ? root.colOnPrimary : root.colSubtext
                                opacity: 0.8
                            }
                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: tile.enabledTile ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onEntered: if (tile.enabledTile) root.selected = tile.index
                                onClicked: root.apply(tile.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
