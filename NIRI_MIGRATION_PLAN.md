---
name: Niri Migration Plan
description: Complete plan for migrating illogical-impulse from Hyprland to Niri
type: project
---

# Hyprland to Niri 移植计划

## 概述

本文档详细说明了将 illogical-impulse 桌面配置从 Hyprland 移植到 Niri 的完整计划。

### 核心差异

| 特性 | Hyprland | Niri |
|------|----------|------|
| 布局模型 | Dwindle (二叉树平铺) | 可滚动列式平铺 |
| 配置格式 | Hyprlang (自定义) | KDL (文档语言) |
| IPC 命令 | `hyprctl` | `niri msg` |
| 工作区 | 每显示器多工作区 | 每显示器一个可滚动条带 |
| 特殊工作区 | scratchpad | 无直接等价物 |
| 模糊效果 | 内置 | 无内置，需 picom |

---

## Phase 1: Niri 基础配置 (预计 2-3 天)

### 1.1 配置文件结构

创建 `dots/.config/niri/config.kdl`:

```
dots/.config/niri/
├── config.kdl          # 主配置文件
├── keybinds.kdl        # 键位映射 (import)
├── window-rules.kdl    # 窗口规则 (import)
├── scripts/            # Niri 专用脚本
│   ├── workspace-action.sh
│   ├── screenshot.sh
│   └── ...
```

### 1.2 基础配置映射

#### 输入配置

**Hyprland** (`general.conf`):
```ini
input {
    kb_layout = us
    numlock_by_default = true
    repeat_delay = 250
    repeat_rate = 35
    touchpad {
        natural_scroll = yes
        disable_while_typing = true
        clickfinger_behavior = true
        scroll_factor = 0.7
    }
}
```

**Niri** (KDL):
```kdl
input {
    keyboard {
        xkb {
            layout "us"
        }
        numlock
        repeat-delay 250
        repeat-rate 35
    }
    touchpad {
        tap
        natural-scroll
        dwt
        clickfinger-behavior
        scroll-factor 0.7
    }
}
```

#### 布局配置

**Hyprland**:
```ini
general {
    gaps_in = 4
    gaps_out = 5
    border_size = 1
    col.active_border = rgba(0DB7D455)
    col.inactive_border = rgba(31313600)
}

decoration {
    rounding = 18
    blur { enabled = true; size = 10; }
    shadow { enabled = true; range = 20; }
}
```

**Niri**:
```kdl
layout {
    gaps 8

    center-focused-column "never"

    focus-ring {
        width 1
        active-color "#0DB7D4"
        inactive-color "#313136"
    }

    border {
        width 1
        active-color "#0DB7D4"
        inactive-color "#313136"
    }

    // 注意: Niri 无内置模糊，需要 picom 或忽略
}
```

### 1.3 键位映射移植

#### 格式差异

**Hyprland**:
```ini
bind = Super, Return, exec, $terminal
bind = Super, Q, killactive
bind = Super, Left, movefocus, l
```

**Niri**:
```kdl
binds {
    Mod+Return { spawn "kitty"; }
    Mod+Q { close-window; }
    Mod+Left { focus-column-left; }
}
```

#### 键位映射对照表

| 功能 | Hyprland | Niri |
|------|----------|------|
| 打开终端 | `Super+Return` | `Mod+Return { spawn "kitty"; }` |
| 关闭窗口 | `killactive` | `close-window` |
| 焦点左移 | `movefocus, l` | `focus-column-left` |
| 焦点右移 | `movefocus, r` | `focus-column-right` |
| 焦点上移 | `movefocus, u` | `focus-window-up` |
| 焦点下移 | `movefocus, d` | `focus-window-down` |
| 移动窗口左 | `movewindow, l` | `move-column-left` |
| 移动窗口右 | `movewindow, r` | `move-column-right` |
| 切换工作区 N | `workspace, N` | `focus-workspace N` |
| 移动到工作区 N | `movetoworkspace, N` | `move-column-to-workspace N` |
| 浮动/平铺 | `togglefloating` | `toggle-window-floating` |
| 最大化 | `fullscreen, 1` | `maximize-column` |
| 全屏 | `fullscreen, 0` | `fullscreen-window` |
| 锁屏 | `loginctl lock-session` | 同上 (使用 hyprlock/swaylock) |

#### Quickshell IPC 调用

Quickshell 部件通过 IPC 与合成器通信。需要创建兼容层：

**Hyprland 方式**:
```qml
Hyprland.dispatch("workspace 1")
Hyprland.dispatch("togglefloating")
```

**Niri 方式**:
```qml
Process { command: ["niri", "msg", "action", "focus-workspace", "1"] }
Process { command: ["niri", "msg", "action", "toggle-window-floating"] }
```

### 1.4 窗口规则移植

**Hyprland**:
```ini
windowrule = match:class ^(pavucontrol)$, float on
windowrule = match:class ^(pavucontrol)$, size (monitor_w*.45) (monitor_h*.45)
windowrule = match:class ^(pavucontrol)$, center on
```

**Niri**:
```kdl
window-rule {
    match app-id="pavucontrol"
    open-floating true
    default-floating-width 800
    default-floating-height 600
    // 注意: Niri 不支持相对大小，需要计算或使用固定值
}
```

### 1.5 层规则 (Layer Rules)

Quickshell 大量使用 layer-shell，Niri 支持但语法不同：

**Hyprland**:
```ini
layerrule = match:namespace quickshell:.*, blur on
layerrule = match:namespace quickshell:bar, animation slide
```

**Niri**:
```kdl
layer-rule {
    match namespace="quickshell:.*"
    blur on
}
// 注意: Niri 的动画支持有限
```

---

## Phase 2: 脚本移植 (预计 1-2 天)

### 2.1 IPC 命令对照

| 操作 | Hyprland | Niri |
|------|----------|------|
| 获取窗口列表 | `hyprctl clients -j` | `niri msg --json windows` |
| 获取显示器 | `hyprctl monitors -j` | `niri msg --json outputs` |
| 获取工作区 | `hyprctl workspaces -j` | `niri msg --json workspaces` |
| 活动工作区 | `hyprctl activeworkspace -j` | `niri msg --json focused-workspace` |
| 获取图层 | `hyprctl layers -j` | `niri msg --json layers` |
| 调度命令 | `hyprctl dispatch <cmd>` | `niri msg action <cmd>` |
| 事件流 | 监听 socket | `niri msg event-stream` |

### 2.2 需要修改的脚本

| 脚本 | 修改内容 |
|------|----------|
| `workspace_action.sh` | 替换 hyprctl 为 niri msg |
| `zoom.sh` | 使用 niri 的缩放命令或 wlr-randr |
| `snip_to_search.sh` | 移除 hyprctl 依赖，使用通用工具 |
| `screenshot` 相关 | 使用 grim/slurp 直接调用 |

### 2.3 工作区脚本示例

**原 Hyprland** (`workspace_action.sh`):
```bash
hyprctl dispatch workspace $1
hyprctl dispatch movetoworkspacesilent $1
```

**Niri 版本**:
```bash
niri msg action focus-workspace $1
niri msg action move-column-to-workspace $1
```

---

## Phase 3: Quickshell 部件移植 (预计 5-7 天)

### 3.1 受影响的文件 (79 个 QML 文件)

#### 核心服务文件 (必须重写)

| 文件 | 功能 | 移植难度 |
|------|------|----------|
| `services/HyprlandData.qml` | 窗口/工作区数据 | 高 |
| `services/HyprlandKeybinds.qml` | 键位解析 | 中 |
| `services/HyprlandConfig.qml` | 配置管理 | 中 |
| `services/HyprlandXkb.qml` | 键盘布局 | 低 |
| `services/Hyprsunset.qml` | 蓝光过滤 | 低 (独立服务) |

#### UI 组件 (需要修改)

| 文件 | 功能 | 修改内容 |
|------|------|----------|
| `modules/ii/bar/Workspaces.qml` | 工作区指示器 | 替换 Hyprland API |
| `modules/ii/bar/ActiveWindow.qml` | 活动窗口标题 | 使用 ToplevelManager |
| `modules/ii/overview/*.qml` | 工作区概览 | 完全重写 |
| `modules/ii/dock/Dock.qml` | 任务栏 | 修改窗口获取方式 |

### 3.2 创建 NiriData 服务

创建 `services/NiriData.qml` 替代 `HyprlandData.qml`:

```qml
// services/NiriData.qml
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property var windowList: []
    property var workspaces: []
    property var outputs: []
    property var focusedWorkspace: null

    // 事件流进程
    Process {
        id: eventStream
        command: ["niri", "msg", "event-stream"]
        stdout: SplitParser {
            onRead: data => {
                parseEvent(data)
            }
        }
    }

    function updateWindows() {
        process.command = ["niri", "msg", "--json", "windows"]
        process.running = true
    }

    function updateWorkspaces() {
        process.command = ["niri", "msg", "--json", "workspaces"]
        process.running = true
    }

    // ... 解析逻辑
}
```

### 3.3 创建 Compositor 抽象层

创建统一接口，支持 Hyprland 和 Niri:

```qml
// services/Compositor.qml
pragma Singleton

import QtQuick

Singleton {
    id: root

    property string current: detectCompositor()

    function detectCompositor(): string {
        if (Qt.environmentVariable("HYPRLAND_INSTANCE") !== "")
            return "hyprland"
        if (Qt.environmentVariable("NIRI_SOCKET") !== "")
            return "niri"
        return "unknown"
    }

    // 统一 API
    function focusWorkspace(index) {
        if (current === "hyprland")
            Hyprland.dispatch(`workspace ${index}`)
        else if (current === "niri")
            Niri.focusWorkspace(index)
    }

    function moveWindowToWorkspace(index) {
        if (current === "hyprland")
            Hyprland.dispatch(`movetoworkspace ${index}`)
        else if (current === "niri")
            Niri.moveColumnToWorkspace(index)
    }

    // ... 其他 API
}
```

### 3.4 修改 Workspaces.qml

```qml
// 修改前
import Quickshell.Hyprland

readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
onPressed: Hyprland.dispatch(`workspace ${workspaceValue}`)

// 修改后
import qs.services

readonly property var monitor: Compositor.monitorFor(root.QsWindow.window?.screen)
onPressed: Compositor.focusWorkspace(workspaceValue)
```

---

## Phase 4: 特性差异处理 (预计 2-3 天)

### 4.1 无直接对应的功能

| Hyprland 功能 | 解决方案 |
|---------------|----------|
| 特殊工作区 (scratchpad) | 使用 Niri 的 floating + minimize 或外部脚本 |
| 模糊效果 | 安装 picom 或放弃模糊 |
|撕裂 (tearing) | 无替代，但 Niri 可能有原生支持 |
| hyprpicker | 使用 wl-color-picker |
| hyprshot | 使用 grim + slurp |
| hyprsunset | 使用 wlsunset 或 gammastep |

### 4.2 Scratchpad 替代方案

```kdl
// 方案1: 使用浮动窗口
binds {
    Mod+S { toggle-window-floating; }
}

// 方案2: 使用专用工作区
binds {
    Mod+S { focus-workspace "scratchpad"; }
}
```

### 4.3 模糊效果替代

创建 `dots/.config/picom.conf`:

```ini
backend = "glx";
blur-method = "gaussian";
blur-size = 10;
blur-deviation = 5;

blur-background-exclude = [
    "window_type = 'desktop'",
    "_GTK_FRAME_EXTENTS@:c"
];
```

---

## Phase 5: 安装脚本更新 (预计 1 天)

### 5.1 添加 Niri 支持

修改 `sdata/lib/pkgs.sh` 添加 Niri 包:

```bash
# Niri 相关包
niri_pkgs=(
    niri
    picom          # 模糊效果
    wlsunset       # 蓝光过滤
    wl-color-picker # 取色器
)
```

### 5.2 创建 Niri 安装目标

```bash
# sdata/subcmd-install/niri.sh
install_niri() {
    install_packages "${niri_pkgs[@]}"
    link_config "niri"
    setup_picom
    setup_quickshell_niri
}
```

---

## Phase 6: 测试和调试 (预计 2-3 天)

### 6.1 测试清单

- [ ] Niri 启动正常
- [ ] 所有键位工作
- [ ] Quickshell 部件加载
- [ ] 工作区切换
- [ ] 窗口规则生效
- [ ] 截图功能
- [ ] 锁屏
- [ ] 多显示器
- [ ] 主题切换 (matugen)

### 6.2 已知问题

1. **模糊效果**: Niri 无内置模糊，需要 picom
2. **工作区概览**: 需要完全重写以适应 Niri 的列式布局
3. **窗口动画**: Niri 动画较简单，可能无法完全复制 Hyprland 的效果

---

## 文件结构规划

```
dots/.config/
├── niri/
│   ├── config.kdl          # 主配置
│   ├── keybinds.kdl        # 键位 (import)
│   ├── window-rules.kdl    # 窗口规则 (import)
│   └── scripts/
│       ├── workspace-action.sh
│       └── screenshot.sh
├── quickshell/ii/
│   ├── services/
│   │   ├── Compositor.qml      # 抽象层 (新建)
│   │   ├── NiriData.qml        # Niri 数据 (新建)
│   │   ├── HyprlandData.qml    # 保留原样
│   │   └── ...
│   └── modules/
│       └── ... (修改以使用 Compositor API)
└── picom/
    └── picom.conf          # 模糊效果 (新建)
```

---

## 时间估算

| 阶段 | 时间 |
|------|------|
| Phase 1: 基础配置 | 2-3 天 |
| Phase 2: 脚本移植 | 1-2 天 |
| Phase 3: Quickshell 移植 | 5-7 天 |
| Phase 4: 特性差异处理 | 2-3 天 |
| Phase 5: 安装脚本 | 1 天 |
| Phase 6: 测试调试 | 2-3 天 |
| **总计** | **13-19 天** |

---

## 风险和缓解措施

| 风险 | 缓解措施 |
|------|----------|
| Quickshell API 不兼容 | 创建抽象层，逐步迁移 |
| 模糊效果缺失 | 使用 picom 作为替代 |
| 工作区概念不同 | 设计新的 UI 适配列式布局 |
| 动画效果差异 | 接受简化版动画或寻找替代方案 |

---

## Why:
用户希望将 illogical-impulse 桌面配置移植到 Niri 合成器。Niri 的可滚动列式布局提供了不同的窗口管理体验。

## How to apply:
按照 Phase 顺序逐步实施，每个阶段完成后进行测试验证。优先完成核心功能（键位、窗口管理、Quickshell 基础部件），再处理高级特性。
