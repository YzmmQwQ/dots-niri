pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * Provides access to Niri compositor data via IPC.
 * Replaces HyprlandData for Niri.
 */
Singleton {
    id: root

    // Window data
    property var windowList: []
    property var windowById: ({})
    property var focusedWindow: null

    // Workspace data
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var focusedWorkspace: null

    // Output/Monitor data
    property var outputs: []
    property var outputByName: ({})
    property var focusedOutput: null

    // Layer data
    property var layers: ({})

    // Convenience functions
    function toplevelsForWorkspace(workspaceId) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const win = root.windowById[toplevel.internalId];
            return win?.workspace_id === workspaceId;
        });
    }

    function windowsForWorkspace(workspaceId) {
        return root.windowList.filter(win => win.workspace_id === workspaceId);
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInWorkspace = root.windowList.filter(w => w.workspace_id === workspaceId);
        return windowsInWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.width ?? 0) * (maxWin?.height ?? 0);
            const winArea = (win?.width ?? 0) * (win?.height ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    // Update functions
    function updateWindows() {
        getWindows.running = true;
    }

    function updateWorkspaces() {
        getWorkspaces.running = true;
        getFocusedWorkspace.running = true;
    }

    function updateOutputs() {
        getOutputs.running = true;
    }

    function updateFocusedWindow() {
        getFocusedWindow.running = true;
    }

    function updateAll() {
        updateWindows();
        updateWorkspaces();
        updateOutputs();
        updateFocusedWindow();
    }

    Component.onCompleted: {
        updateAll();
        eventStream.running = true;
    }

    // Event stream for real-time updates
    Process {
        id: eventStream
        command: ["niri", "msg", "event-stream"]
        stdout: SplitParser {
            onRead: data => {
                root.handleEvent(data);
            }
        }
    }

    function handleEvent(data) {
        try {
            const event = JSON.parse(data);
            // Niri sends various events; update relevant data
            if (event.WorkspacesChanged || event.WindowsChanged || event.FocusChanged) {
                updateAll();
            }
        } catch (e) {
            // Non-JSON output, ignore
        }
    }

    // Process: Get all windows
    Process {
        id: getWindows
        command: ["niri", "msg", "--json", "windows"]
        stdout: StdioCollector {
            id: windowsCollector
            onStreamFinished: {
                try {
                    root.windowList = JSON.parse(windowsCollector.text);
                    let tempById = {};
                    for (const win of root.windowList) {
                        tempById[win.id] = win;
                    }
                    root.windowById = tempById;
                } catch (e) {
                    console.error("[NiriData] Error parsing windows:", e);
                }
            }
        }
    }

    // Process: Get focused window
    Process {
        id: getFocusedWindow
        command: ["niri", "msg", "--json", "focused-window"]
        stdout: StdioCollector {
            id: focusedWindowCollector
            onStreamFinished: {
                try {
                    const text = focusedWindowCollector.text.trim();
                    if (text && text !== "null") {
                        root.focusedWindow = JSON.parse(text);
                    } else {
                        root.focusedWindow = null;
                    }
                } catch (e) {
                    console.error("[NiriData] Error parsing focused window:", e);
                    root.focusedWindow = null;
                }
            }
        }
    }

    // Process: Get all workspaces
    Process {
        id: getWorkspaces
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                try {
                    const rawWorkspaces = JSON.parse(workspacesCollector.text);
                    root.workspaces = rawWorkspaces;
                    let tempById = {};
                    let ids = [];
                    for (const ws of rawWorkspaces) {
                        tempById[ws.id] = ws;
                        ids.push(ws.id);
                    }
                    root.workspaceById = tempById;
                    root.workspaceIds = ids;
                } catch (e) {
                    console.error("[NiriData] Error parsing workspaces:", e);
                }
            }
        }
    }

    // Process: Get focused workspace
    Process {
        id: getFocusedWorkspace
        command: ["niri", "msg", "--json", "focused-workspace"]
        stdout: StdioCollector {
            id: focusedWorkspaceCollector
            onStreamFinished: {
                try {
                    const text = focusedWorkspaceCollector.text.trim();
                    if (text && text !== "null") {
                        root.focusedWorkspace = JSON.parse(text);
                    } else {
                        root.focusedWorkspace = null;
                    }
                } catch (e) {
                    console.error("[NiriData] Error parsing focused workspace:", e);
                    root.focusedWorkspace = null;
                }
            }
        }
    }

    // Process: Get outputs
    Process {
        id: getOutputs
        command: ["niri", "msg", "--json", "outputs"]
        stdout: StdioCollector {
            id: outputsCollector
            onStreamFinished: {
                try {
                    root.outputs = JSON.parse(outputsCollector.text);
                    let tempByName = {};
                    for (const output of root.outputs) {
                        tempByName[output.name] = output;
                        if (output.is_focused) {
                            root.focusedOutput = output;
                        }
                    }
                    root.outputByName = tempByName;
                } catch (e) {
                    console.error("[NiriData] Error parsing outputs:", e);
                }
            }
        }
    }
}
