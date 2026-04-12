pragma Singleton

import QtQuick
import qs.modules.common
import Quickshell
import Quickshell.Io

/**
 * Night light / blue light filter service for Niri.
 * Uses wlsunset or gammastep instead of hyprsunset.
 */
Singleton {
    id: root

    signal gammaChangeAttempt()

    readonly property real gammaLowerLimit: 25

    property string from: Config.options?.light?.night?.from ?? "19:00"
    property string to: Config.options?.light?.night?.to ?? "06:30"
    property bool automatic: Config.options?.light?.night?.automatic && (Config?.ready ?? true)
    property int colorTemperature: Config.options?.light?.night?.colorTemperature ?? 5000
    property int gamma: 100
    property bool shouldBeOn
    property bool firstEvaluation: true
    property bool temperatureActive: false

    property int fromHour: Number(from.split(":")[0])
    property int fromMinute: Number(from.split(":")[1])
    property int toHour: Number(to.split(":")[0])
    property int toMinute: Number(to.split(":")[1])

    property int clockHour: DateTime.clock.hours
    property int clockMinute: DateTime.clock.minutes

    property var manualActive
    property int manualActiveHour
    property int manualActiveMinute

    onClockMinuteChanged: reEvaluate()
    onAutomaticChanged: {
        root.manualActive = undefined;
        root.firstEvaluation = true;
        reEvaluate();
    }

    function inBetween(t, from, to) {
        if (from < to) {
            return (t >= from && t <= to);
        } else {
            return (t >= from || t <= to);
        }
    }

    function reEvaluate() {
        const t = clockHour * 60 + clockMinute;
        const from = fromHour * 60 + fromMinute;
        const to = toHour * 60 + toMinute;
        const manualActive = manualActiveHour * 60 + manualActiveMinute;

        if (root.manualActive !== undefined && (inBetween(from, manualActive, t) || inBetween(to, manualActive, t))) {
            root.manualActive = undefined;
        }
        root.shouldBeOn = inBetween(t, from, to);
        if (firstEvaluation) {
            firstEvaluation = false;
            root.ensureState();
        }
    }

    onShouldBeOnChanged: ensureState()

    function ensureState() {
        if (!root.automatic || root.manualActive !== undefined)
            return;
        if (root.shouldBeOn) {
            root.enableTemperature();
        } else {
            root.disableTemperature();
        }
    }

    function startWlsunset() {
        // Kill existing wlsunset process
        Quickshell.execDetached(["pkill", "wlsunset"]);
        // Start with manual mode (we control the temperature)
        Quickshell.execDetached(["bash", "-c", "pidof wlsunset || wlsunset -t 6500 -T 6500 &"]);
    }

    function load() {
        root.startWlsunset();
        root.ensureState();
    }

    Timer {
        id: updateNightLight
        interval: 100
        repeat: false
        onTriggered: {
            root.ensureState();
            root.setGamma(root.gamma);
        }
    }

    function enableTemperature() {
        root.temperatureActive = true;
        // Use wlsunset with specified temperature
        Quickshell.execDetached(["pkill", "wlsunset"]);
        Quickshell.execDetached(["wlsunset", "-t", String(root.colorTemperature), "-T", "6500"]);
    }

    function disableTemperature() {
        root.temperatureActive = false;
        // Reset to 6500K (no filter)
        Quickshell.execDetached(["pkill", "wlsunset"]);
        Quickshell.execDetached(["wlsunset", "-t", "6500", "-T", "6500"]);
    }

    function setGamma(gamma) {
        root.gamma = Math.max(root.gammaLowerLimit, Math.min(100, gamma));
        root.gammaChangeAttempt();
        // wlsunset doesn't support gamma adjustment directly
        // For gamma control, we'd need to use a different tool or adjust brightness
    }

    function toggleTemperature(active = undefined) {
        if (root.manualActive === undefined) {
            root.manualActive = root.temperatureActive;
            root.manualActiveHour = root.clockHour;
            root.manualActiveMinute = root.clockMinute;
        }

        root.manualActive = active !== undefined ? active : !root.manualActive;
        if (root.manualActive) {
            root.enableTemperature();
        } else {
            root.disableTemperature();
        }
    }

    // Change temp on config change
    Connections {
        target: Config.options?.light?.night
        function onColorTemperatureChanged() {
            if (!root.temperatureActive) return;
            root.enableTemperature();
        }
    }
}
