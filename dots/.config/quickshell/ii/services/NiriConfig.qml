pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.common
import qs.modules.common.functions

/**
 * Configs Niri compositor settings.
 * Replaces HyprlandConfig for Niri.
 */
Singleton {
    id: root

    signal reloaded()

    readonly property string configPath: `${Directories.config}/niri/config.kdl`
    readonly property string userConfigPath: `${Directories.config}/niri/user-config.kdl`

    // Execute a niri msg action
    function action(actionName, ...args) {
        const cmd = ["niri", "msg", "action", actionName, ...args];
        Quickshell.execDetached(cmd);
    }

    // Set keyboard layout
    function setKeyboardLayout(layout) {
        // Niri uses xkb settings in config, runtime changes need niri msg
        Quickshell.execDetached(["niri", "msg", "action", "switch-layout", layout]);
    }

    // Focus workspace
    function focusWorkspace(id) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(id)]);
    }

    // Move window to workspace
    function moveToWorkspace(id) {
        Quickshell.execDetached(["niri", "msg", "action", "move-column-to-workspace", String(id)]);
    }

    // Toggle floating
    function toggleFloating() {
        Quickshell.execDetached(["niri", "msg", "action", "toggle-window-floating"]);
    }

    // Close window
    function closeWindow() {
        Quickshell.execDetached(["niri", "msg", "action", "close-window"]);
    }

    // Screenshot
    function screenshotRegion() {
        Quickshell.execDetached(["niri", "msg", "action", "screenshot"]);
    }

    function screenshotScreen() {
        Quickshell.execDetached(["niri", "msg", "action", "screenshot-screen"]);
    }

    function screenshotWindow() {
        Quickshell.execDetached(["niri", "msg", "action", "screenshot-window"]);
    }

    // Reload config
    function reloadConfig() {
        Quickshell.execDetached(["niri", "msg", "action", "reload-config"]);
        root.reloaded();
    }

    // Power off monitors
    function powerOffMonitors() {
        Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
    }

    // Toggle overview
    function toggleOverview() {
        Quickshell.execDetached(["niri", "msg", "action", "toggle-overview"]);
    }

    // General dispatch function (similar to Hyprland.dispatch)
    function dispatch(command) {
        Quickshell.execDetached(["niri", "msg", "action", command]);
    }
}
