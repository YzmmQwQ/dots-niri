pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * Exposes the active Niri Xkb keyboard layout name and code for indicators.
 * Replaces HyprlandXkb for Niri.
 */
Singleton {
    id: root

    // You can read these
    property list<string> layoutCodes: []
    property var cachedLayoutCodes: ({})
    property string currentLayoutName: ""
    property string currentLayoutCode: ""

    // For the service
    property var baseLayoutFilePath: "/usr/share/X11/xkb/rules/base.lst"
    property bool needsLayoutRefresh: false

    onCurrentLayoutNameChanged: root.updateLayoutCode()

    function updateLayoutCode() {
        if (cachedLayoutCodes.hasOwnProperty(currentLayoutName)) {
            root.currentLayoutCode = cachedLayoutCodes[currentLayoutName];
        } else {
            getLayoutProc.running = true;
        }
    }

    // Get the layout code from the base.lst file
    Process {
        id: getLayoutProc
        command: ["cat", root.baseLayoutFilePath]

        stdout: StdioCollector {
            id: layoutCollector

            onStreamFinished: {
                const lines = layoutCollector.text.split("\n");
                const targetDescription = root.currentLayoutName;
                const foundLine = lines.find(line => {
                    if (!line.trim() || line.trim().startsWith('!'))
                        return false;

                    const matchLayout = line.match(/^\s*(\S+)\s+(.+)$/);
                    if (matchLayout && matchLayout[2] === targetDescription) {
                        root.cachedLayoutCodes[matchLayout[2]] = matchLayout[1];
                        root.currentLayoutCode = matchLayout[1];
                        return true;
                    }

                    const matchVariant = line.match(/^\s*(\S+)\s+(\S+)\s+(.+)$/);
                    if (matchVariant && matchVariant[3] === targetDescription) {
                        const complexLayout = matchVariant[2] + matchVariant[1];
                        root.cachedLayoutCodes[matchVariant[3]] = complexLayout;
                        root.currentLayoutCode = complexLayout;
                        return true;
                    }

                    return false;
                });
            }
        }
    }

    // Get keyboard info via niri msg (Niri doesn't have direct keyboard layout query)
    // We'll use setxkbmap or xkbcli as fallback
    Process {
        id: fetchLayoutsProc
        running: true
        command: ["bash", "-c", "setxkbmap -query | grep layout | awk '{print $2}'"]

        stdout: StdioCollector {
            id: layoutsCollector
            onStreamFinished: {
                const layoutString = layoutsCollector.text.trim();
                if (layoutString) {
                    root.layoutCodes = layoutString.split(",");
                    // Get current active layout
                    fetchCurrentLayout.running = true;
                }
            }
        }
    }

    Process {
        id: fetchCurrentLayout
        command: ["bash", "-c", "setxkbmap -query | grep variant | awk '{print $2}' || echo ''"]
        stdout: StdioCollector {
            id: currentLayoutCollector
            onStreamFinished: {
                const variant = currentLayoutCollector.text.trim();
                if (variant) {
                    root.currentLayoutName = variant;
                } else if (root.layoutCodes.length > 0) {
                    root.currentLayoutName = root.layoutCodes[0];
                }
            }
        }
    }

    // Listen for keyboard layout changes via Niri event stream
    // Note: Niri doesn't expose layout changes directly, so we poll or use xkb events
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            fetchCurrentLayout.running = true;
        }
    }
}
