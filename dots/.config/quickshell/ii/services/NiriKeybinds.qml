pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * A service that provides access to Niri keybinds.
 * Parses KDL config files to extract keybind information.
 * Replaces HyprlandKeybinds for Niri.
 */
Singleton {
    id: root

    property string keybindParserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/niri/get_keybinds.py`)
    property string defaultKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/niri/keybinds.kdl`)
    property string userKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/niri/user-keybinds.kdl`)

    property var defaultKeybinds: {"children": []}
    property var userKeybinds: {"children": []}
    property var keybinds: ({
        children: [
            ...(defaultKeybinds.children ?? []),
            ...(userKeybinds.children ?? []),
        ]
    })

    function parseKdlKeybinds(content) {
        // Simple KDL parser for keybinds
        // KDL format: Mod+Key { action; }
        const keybinds = { children: [] };
        const lines = content.split('\n');
        let currentSection = null;

        for (const line of lines) {
            const trimmed = line.trim();

            // Skip comments and empty lines
            if (!trimmed || trimmed.startsWith('//')) continue;

            // Check for section header (comment like // === Section ===)
            if (trimmed.startsWith('// ===')) {
                const sectionName = trimmed.replace('// ===', '').replace('===', '').trim();
                if (sectionName) {
                    currentSection = { name: sectionName, children: [] };
                    keybinds.children.push(currentSection);
                }
                continue;
            }

            // Parse bind: Mod+Key { action }
            const bindMatch = trimmed.match(/^(\S+)\s*\{\s*(.+?)\s*\}$/);
            if (bindMatch) {
                const keys = bindMatch[1];
                const action = bindMatch[2];

                // Parse modifiers and key
                const parts = keys.split('+');
                const key = parts[parts.length - 1];
                const mods = parts.slice(0, -1);

                const entry = {
                    key: key,
                    mods: mods.join('+'),
                    action: action,
                    description: action // Use action as description for now
                };

                if (currentSection) {
                    currentSection.children.push(entry);
                } else {
                    keybinds.children.push(entry);
                }
            }
        }

        return keybinds;
    }

    Process {
        id: getDefaultKeybinds
        running: true
        command: ["cat", root.defaultKeybindConfigPath]

        stdout: StdioCollector {
            id: defaultCollector
            onStreamFinished: {
                try {
                    root.defaultKeybinds = root.parseKdlKeybinds(defaultCollector.text);
                    root.updateKeybinds();
                } catch (e) {
                    console.error("[NiriKeybinds] Error parsing default keybinds:", e);
                }
            }
        }
    }

    Process {
        id: getUserKeybinds
        running: true
        command: ["cat", root.userKeybindConfigPath]

        stdout: StdioCollector {
            id: userCollector
            onStreamFinished: {
                try {
                    root.userKeybinds = root.parseKdlKeybinds(userCollector.text);
                    root.updateKeybinds();
                } catch (e) {
                    // User keybinds file may not exist, that's okay
                    root.userKeybinds = { children: [] };
                    root.updateKeybinds();
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                root.userKeybinds = { children: [] };
                root.updateKeybinds();
            }
        }
    }

    function updateKeybinds() {
        root.keybinds = {
            children: [
                ...(root.defaultKeybinds.children ?? []),
                ...(root.userKeybinds.children ?? []),
            ]
        };
    }
}
