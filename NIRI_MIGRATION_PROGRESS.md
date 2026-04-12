# Niri 移植进度

## 已完成的工作

### Phase 1: Niri 基础配置 ✅

| 文件 | 状态 | 说明 |
|------|------|------|
| `dots/.config/niri/config.kdl` | ✅ 完成 | 主配置文件 |
| `dots/.config/niri/keybinds.kdl` | ✅ 完成 | 键位映射 |
| `dots/.config/niri/window-rules.kdl` | ✅ 完成 | 窗口规则 |

### Phase 2: 脚本移植 ✅

| 文件 | 状态 | 说明 |
|------|------|------|
| `scripts/launch_first_available.sh` | ✅ 完成 | 应用启动脚本 |
| `scripts/workspace_action.sh` | ✅ 完成 | 工作区操作 |
| `scripts/zoom.sh` | ✅ 完成 | 缩放（使用放大镜工具替代） |
| `scripts/start_geoclue_agent.sh` | ✅ 完成 | GeoClue 服务 |
| `scripts/restore_video_wallpaper.sh` | ✅ 完成 | 视频壁纸恢复 |
| `scripts/screenshot.sh` | ✅ 完成 | 截图脚本 |
| `scripts/snip_to_search.sh` | ✅ 完成 | 截图搜索 |

### Phase 3: Quickshell 服务移植 ✅ (核心)

| 文件 | 状态 | 说明 |
|------|------|------|
| `services/NiriData.qml` | ✅ 完成 | 替代 HyprlandData |
| `services/NiriConfig.qml` | ✅ 完成 | Niri 配置管理 |
| `services/NiriXkb.qml` | ✅ 完成 | 键盘布局 |
| `services/NiriKeybinds.qml` | ✅ 完成 | 键位解析 |
| `services/NightLight.qml` | ✅ 完成 | 替代 Hyprsunset (使用 wlsunset) |
| `services/NiriFocusGrab.qml` | ✅ 完成 | 替代 GlobalFocusGrab |

### Phase 3: Quickshell UI 组件移植 (进行中)

| 文件 | 状态 | 说明 |
|------|------|------|
| `shell-niri.qml` | ✅ 完成 | 主 shell 文件（无 Hyprland 导入） |
| `GlobalStates-niri.qml` | ✅ 完成 | 全局状态（无 Hyprland 导入） |
| `modules/ii/bar/Workspaces-niri.qml` | ✅ 完成 | 工作区指示器 |
| `modules/ii/cheatsheet/CheatsheetKeybinds-niri.qml` | ✅ 完成 | 快捷键表 |
| `modules/ii/overview/Overview-niri.qml` | ✅ 完成 | 概览界面 |

## 待完成的工作

### 剩余 Quickshell 组件

需要修改以下文件（将 `-niri` 版本覆盖原文件或创建新文件）：

1. **modules/ii/bar/**
   - `Bar.qml` - 移除 HyprlandFocusGrab
   - `ActiveWindow.qml` - 使用 ToplevelManager
   - `Dock.qml` - 移除 Hyprland 导入

2. **modules/ii/sidebarLeft/**
   - `SidebarLeft.qml` - 移除 HyprlandFocusGrab

3. **modules/ii/sidebarRight/**
   - `SidebarRight.qml` - 移除 HyprlandFocusGrab

4. **modules/ii/sessionScreen/**
   - `SessionScreen.qml` - 移除 HyprlandFocusGrab

5. **modules/ii/lock/**
   - `Lock.qml` - 移除 HyprlandFocusGrab

6. **modules/ii/background/**
   - `Background.qml` - 移除 Hyprland 导入

7. **modules/waffle/**
   - 所有相关文件

### Phase 5: 安装脚本

- 更新 `sdata/` 中的安装脚本
- 添加 Niri 包依赖

### Phase 6: 测试

- 在真实 Niri 环境中测试

## 使用说明

### 启用 Niri 版本

```bash
# 备份原文件
cp dots/.config/quickshell/ii/shell.qml dots/.config/quickshell/ii/shell-hyprland.qml

# 使用 Niri 版本
cp dots/.config/quickshell/ii/shell-niri.qml dots/.config/quickshell/ii/shell.qml
cp dots/.config/quickshell/ii/GlobalStates-niri.qml dots/.config/quickshell/ii/GlobalStates.qml

# 复制服务文件
cp dots/.config/quickshell/ii/services/Niri*.qml dots/.config/quickshell/ii/services/
cp dots/.config/quickshell/ii/services/NightLight.qml dots/.config/quickshell/ii/services/

# 复制 UI 组件
cp dots/.config/quickshell/ii/modules/ii/bar/Workspaces-niri.qml dots/.config/quickshell/ii/modules/ii/bar/Workspaces.qml
cp dots/.config/quickshell/ii/modules/ii/cheatsheet/CheatsheetKeybinds-niri.qml dots/.config/quickshell/ii/modules/ii/cheatsheet/CheatsheetKeybinds.qml
cp dots/.config/quickshell/ii/modules/ii/overview/Overview-niri.qml dots/.config/quickshell/ii/modules/ii/overview/Overview.qml
```

### 注意事项

1. **模糊效果**: Niri 开发分支已支持模糊，当前版本需要 picom 或等待上游发布
2. **NightLight**: 使用 `wlsunset` 替代 `hyprsunset`
3. **键盘布局**: 使用 `setxkbmap` 查询布局（Niri 不直接暴露）

## 文件对照表

| 原 Hyprland 文件 | Niri 替代文件 |
|------------------|---------------|
| `HyprlandData.qml` | `NiriData.qml` |
| `HyprlandConfig.qml` | `NiriConfig.qml` |
| `HyprlandKeybinds.qml` | `NiriKeybinds.qml` |
| `HyprlandXkb.qml` | `NiriXkb.qml` |
| `Hyprsunset.qml` | `NightLight.qml` |
| `GlobalFocusGrab.qml` | `NiriFocusGrab.qml` |
| `shell.qml` | `shell-niri.qml` |
| `GlobalStates.qml` | `GlobalStates-niri.qml` |
| `Workspaces.qml` | `Workspaces-niri.qml` |
| `CheatsheetKeybinds.qml` | `CheatsheetKeybinds-niri.qml` |
| `Overview.qml` | `Overview-niri.qml` |
