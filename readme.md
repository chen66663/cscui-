# cscui

基于 Qt Quick 的桌面组件工作台：可复用控件、明暗主题、中英切换、运行时检查器，以及面向真实场景的组件演示。

仓库：https://github.com/chen66663/cscui-

---

## 界面预览

### 今日工作流（浅色）

表单、操作、状态标签、进度与空状态等常用控件。

![今日工作流](preview/readme-core-light.png)

### 日程与资料（深色）

列表、导航、日历、表格、轮播与备注等数据/内容组件。

![日程与资料](preview/readme-content-dark.png)

### 生活看板（深色）

图表、小组件、材质卡片、动画窗口与媒体演示。

![生活看板](preview/readme-dashboard-dark.png)

---

## 功能概览

- **三场景导航**：今日工作流 / 日程与资料 / 生活看板（`--page core|light|extended`）
- **主题与无障碍**：浅色 / 深色 / 自动；高对比、减少动态效果
- **中英切换**：`Theme.localized` + 界面一键切换
- **无边框窗口**：红绿灯按钮、拖拽移动、最大化还原
- **组件身份角标**：悬停时在组件外侧显示名称（Overlay，不挡操作）
- **丝滑切页**：单树入场动画（透明度 + 位移 + 微缩放）；`reducedMotion` 时关闭
- **运行时检查器**：`--debug-ui` 或 `Ctrl+Shift+D`（布局边界、事件日志、FPS 采样等）
- **媒体（按需）**：本地音乐扫描走后台低优先级线程池，支持取消与有界缓存

---

## 环境要求

| 项 | 版本 |
|----|------|
| Qt | **6.8+**（Quick、Multimedia、Network、Concurrent） |
| CMake | **3.24+** |
| 编译器 | C++17（MSVC / MinGW / Clang 等） |
| 可选 | Font Awesome 6 桌面字体（仓库已含 `fonts/`） |

---

## 构建与运行

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH=<Qt安装路径>
cmake --build build --config RelWithDebInfo --parallel
```

可执行文件：`build/cscui`（Windows 为 `build/cscui.exe`）。

```bash
# 直接运行
./build/cscui

# 深色 + 中文 + 看板页 + 检查器
./build/cscui --theme dark --language zh --page extended --debug-ui

# 截图（用于文档 / 冒烟）
./build/cscui --page core --theme light --language zh --window-size 1280x820 --screenshot preview/shot.png
```

### 常用命令行参数

| 参数 | 说明 |
|------|------|
| `--page core|light|extended`（或 `0|1|2`） | 启动页 |
| `--theme light|dark|auto` | 主题 |
| `--language en|zh|auto` | 语言 |
| `--debug-ui` | 打开 UI 检查器 |
| `--window-size WxH` | 窗口尺寸，如 `1280x820` |
| `--screenshot path` | 就绪后截图并退出 |

---

## 工程结构

```
.
├── Main.qml              # 无边框壳层、导航、切页、预加载、滚轮
├── main.cpp              # 启动参数、主题桥接、截图
├── components/           # 可复用组件 + 工作台辅助控件（Csc*）
├── pages/                # 三个演示场景
│   ├── BaseComponents.qml          # 今日工作流
│   ├── NoBackgroundComponents.qml  # 日程与资料
│   └── OtherComponents.qml         # 生活看板
├── core/                 # 音乐库扫描等 C++ 服务
├── docs/DESIGN_SYSTEM.md # 设计令牌与交互契约
├── fonts/                # 图标字体与演示图片
├── preview/              # 预览截图
├── scaffold/             # 应用脚手架模板
└── tools/                # 新建工程脚本
```

---

## 组件清单（47）

### 基础与表单

`Button` · `Input` · `SearchField` · `Dropdown` · `CheckBox` · `RadioButton` · `SwitchButton` · `Slider` · `MenuButton` · `Tag` · `ProgressBar` · `Divider`

### 反馈与容器

`Toast` · `AlertDialog` · `LoadingIndicator` · `Accordion` · `Card` · `CardWithTextArea` · `HoverCard` · `BlurCard` · `Drawer` · `EmptyState`

### 数据与导航

`List` · `NavBar` · `DataTable` · `Calendar` · `SimpleDatePicker` · `Carousel` · `Avatar`

### 图表与小组件

`AreaChart` · `BarChart` · `PieChart` · `Clock` · `ClockCard` · `TimeDisplay` · `BatteryCard` · `FitnessProgress` · `YearProgress` · `NextHolidayCountdown` · `HitokotoCard` · `ColorPicker`

### 媒体与窗口

`MusicPlayer` · `Playlist` · `MusicWindow` · `AnimatedWindow` · `Aboutme` · `Theme`

工作台内部还有 `Csc*` 辅助控件（分区标题、滚动条、分段控件、调试面板、身份角标等），不单独作为业务组件导出。

---

## 使用方式

### 模块导入（构建为 QML 模块后）

```qml
import cscui 1.0

Button {
    theme: appTheme
    text: "Continue"
}
```

### 源码旁路导入

```qml
import "components" as Components

Components.Button {
    theme: theme
    text: "继续"
}
```

资源前缀：`qrc:/cscui/`（字体、图片等）。

主题通过 `Theme` 对象注入；组件使用 `theme.localized("English", "中文")` 做文案。

---

## 设计与性能要点

详见 [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)。

- 语义色与间距/圆角/字号令牌统一在 `Theme.qml`
- 切页只动画入场页，避免双页同时绘制
- 列表：`reuseItems` + `cacheBuffer`（如 `DataTable` / `List`）
- 图标字体：壳层加载一次，经 `Theme.iconFamily()` / `iconSource()` 共享
- 音乐扫描：单线程低优先级池、代际号取消、有界元数据缓存

---

## 脚手架

```powershell
.\tools\New-CscuiProject.ps1 -Name SampleApp -Destination . -Template basic -NonInteractive
```

模板：`basic` / `mobile` / `productivity`（见 `scaffold/templates/`）。

---

## 许可证

见 [LICENSE](LICENSE)。
