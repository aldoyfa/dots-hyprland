pragma Singleton
pragma ComponentBehavior: Bound

// Local addition (not part of upstream end4-pC).
// Chromium-based browsers only export a ~150px cover over MPRIS. For browser players this
// asks scripts/hires-art/hires-art.sh for the full-size YouTube thumbnail and hands widgets
// that instead. Until (or unless) one is found, the player's own cover is used.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    // key -> "file://..." when found, "" when the lookup found nothing
    property var resolved: ({})
    property var pending: ({})

    readonly property string script: `${Directories.scriptPath}/hires-art/hires-art.sh`

    function isBrowser(player) {
        return /brave|chrom|edge|vivaldi|opera|firefox|plasma-browser-integration/i.test(player?.dbusName ?? "");
    }

    function keyOf(player) {
        return `${player?.trackTitle ?? ""}|${player?.trackArtist ?? ""}`;
    }

    // True for the tiny covers Chromium-based browsers export (their temp files in /tmp).
    // Widgets use this to show such a cover at its real size instead of enlarging it.
    function isSmall(artUrl) {
        return /^file:\/\/\/tmp\/\.(org\.chromium|com\.brave|com\.google|com\.microsoft|com\.vivaldi)/.test(String(artUrl ?? ""));
    }

    // Drop-in replacement for `player?.trackArtUrl ?? ""`
    function urlFor(player) {
        const original = player?.trackArtUrl ?? "";
        if (!player || !isBrowser(player)) return original;
        const title = player.trackTitle ?? "";
        if (title === "") return original;

        const key = keyOf(player);
        const hit = root.resolved[key];
        if (hit) return hit;
        if (hit === undefined && !root.pending[key]) {
            const artist = player.trackArtist ?? "";
            const pageUrl = String(player.metadata?.["xesam:url"] ?? "");
            Qt.callLater(() => root.request(key, title, artist, pageUrl));
        }
        return original;
    }

    function request(key, title, artist, pageUrl) {
        if (root.pending[key] || root.resolved[key] !== undefined) return;
        root.pending[key] = true;
        lookup.createObject(root, { key: key, command: [root.script, title, artist, pageUrl] });
    }

    function finish(key, path) {
        delete root.pending[key];
        const next = Object.assign({}, root.resolved);
        next[key] = path !== "" ? `file://${path}` : "";
        root.resolved = next; // reassign so bindings using urlFor() re-evaluate
    }

    Component {
        id: lookup
        Process {
            id: proc
            required property string key
            running: true
            stdout: StdioCollector { id: out }
            onExited: {
                root.finish(proc.key, out.text.trim());
                proc.destroy();
            }
        }
    }
}
