# cscui

**Qt Quick 桌面组件工作台**

47 个可复用控件 · 明暗主题 · 中英界面 · 运行时检查器 · 场景化演示

<p align="center">
  <a href="https://github.com/chen66663/cscui-"><img src="https://img.shields.io/badge/GitHub-chen66663%2Fcscui--blue?logo=github" alt="repo" /></a>
  <img src="https://img.shields.io/badge/Qt-6.8+-41CD52?logo=qt&logoColor=white" alt="Qt" />
  <img src="https://img.shields.io/badge/QML-Module-76B900" alt="QML" />
  <img src="https://img.shields.io/badge/License-see%20LICENSE-lightgrey" alt="license" />
</p>

---

## 预览

### 三个场景

| 今日工作流 | 日程与资料 | 生活看板 |
|:----------:|:----------:|:--------:|
| ![](preview/readme-01-workflow-light.png) | ![](preview/readme-03-content-light.png) | ![](preview/readme-05-dashboard-light.png) |
| 表单 · 搜索 · 标签 · 进度 · 空状态 | 列表 · 日历 · 表格 · 轮播 · 备注 | 图表 · 时钟 · 健身 · 媒体 |

### 浅色 / 深色对照

#### 今日工作流

<p align="center">
  <img src="preview/readme-01-workflow-light.png" width="49%" alt="今日工作流 浅色" />
  <img src="preview/readme-02-workflow-dark.png" width="49%" alt="今日工作流 深色" />
</p>

#### 日程与资料

<p align="center">
  <img src="preview/readme-03-content-light.png" width="49%" alt="日程与资料 浅色" />
  <img src="preview/readme-04-content-dark.png" width="49%" alt="日程与资料 深色" />
</p>

#### 生活看板

<p align="center">
  <img src="preview/readme-05-dashboard-light.png" width="49%" alt="生活看板 浅色" />
  <img src="preview/readme-06-dashboard-dark.png" width="49%" alt="生活看板 深色" />
</p>

### 检查器 · 窄屏

<p align="center">
  <img src="preview/readme-07-debug-ui.png" width="63%" alt="运行时检查器" />
  <img src="preview/readme-08-narrow.png" width="33%" alt="窄窗口" />
</p>

<p align="center">
  <sub>左：运行时检查器（布局边界 / 事件 / FPS）　右：窄窗口自动收成图标导航</sub>
</p>

---

## 能做什么

| 能力 | 说明 |
|------|------|
| 场景导航 | 工作流 / 资料 / 看板，侧栏 + 顶部分段切换 |
| 主题 | 浅色、深色、跟随系统；支持高对比与减少动态效果 |
| 语言 | 中文 / 英文一键切换 |
| 窗口 | 无边框、红绿灯、拖拽、最大化还原 |
| 组件名 | 鼠标悬停时在组件外侧显示名称 |
| 检查器 | `Ctrl+Shift+D` 或 `--debug-ui` |
| 媒体 | 本地音乐按需加载，不默认扫盘 |

---

## 快速开始

### 依赖

- **Qt 6.8+**（Quick、Multimedia、Network、Concurrent）
- **CMake 3.24+**
- **C++17** 编译器

### 构建运行

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH=<你的Qt路径>
cmake --build build --config RelWithDebInfo --parallel

# Windows
build\cscui.exe

# 其它
./build/cscui
```

### 命令行

```bash
# 深色 + 中文 + 看板 + 检查器
cscui --theme dark --language zh --page extended --debug-ui

# 截一张图
cscui --page core --theme light --language zh --window-size 1280x820 --screenshot out.png
```

| 参数 | 含义 |
|------|------|
| `--page core \| light \| extended` | 启动页（也可用 `0 \| 1 \| 2`） |
| `--theme light \| dark \| auto` | 主题 |
| `--language en \| zh \| auto` | 语言 |
| `--debug-ui` | 打开检查器 |
| `--window-size WxH` | 窗口大小 |
| `--screenshot path` | 截图后退出 |

---

## 目录

```
.
├── Main.qml / main.cpp   # 窗口壳层、导航、CLI
├── components/           # 业务组件 + Csc* 辅助控件
├── pages/                # 三个演示页
├── core/                 # C++ 服务（如音乐库）
├── docs/                 # 设计系统文档
├── fonts/                # 图标字体与示例图
├── preview/              # README 截图
├── scaffold/             # 应用模板
└── tools/                # 新建工程脚本
```

---

## 组件一览（47）

<details open>
<summary><b>表单与操作</b></summary>

`Button` · `Input` · `SearchField` · `Dropdown` · `CheckBox` · `RadioButton` · `SwitchButton` · `Slider` · `MenuButton` · `Tag` · `ProgressBar` · `Divider`

</details>

<details open>
<summary><b>反馈与容器</b></summary>

`Toast` · `AlertDialog` · `LoadingIndicator` · `Accordion` · `Card` · `CardWithTextArea` · `HoverCard` · `BlurCard` · `Drawer` · `EmptyState`

</details>

<details open>
<summary><b>数据与导航</b></summary>

`List` · `NavBar` · `DataTable` · `Calendar` · `SimpleDatePicker` · `Carousel` · `Avatar`

</details>

<details open>
<summary><b>图表与小组件</b></summary>

`AreaChart` · `BarChart` · `PieChart` · `Clock` · `ClockCard` · `TimeDisplay` · `BatteryCard` · `FitnessProgress` · `YearProgress` · `NextHolidayCountdown` · `HitokotoCard` · `ColorPicker`

</details>

<details open>
<summary><b>媒体与系统</b></summary>

`MusicPlayer` · `Playlist` · `MusicWindow` · `AnimatedWindow` · `Aboutme` · `Theme`

</details>

工作台还有 `Csc*` 辅助控件（分区标题、滚动条、分段控件、调试面板、身份角标等）。

设计令牌与交互约定见 [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)。

---

## 在项目里用

```qml
import cscui 1.0

Button {
    theme: appTheme
    text: "Continue"
}
```

源码直接引用：

```qml
import "components" as Components

Components.Button {
    theme: theme
    text: "继续"
}
```

资源前缀：`qrc:/cscui/`。

---

## 新建应用

```powershell
.\tools\New-CscuiProject.ps1 -Name SampleApp -Destination . -Template basic -NonInteractive
```

可选模板：`basic` · `mobile` · `productivity`

---

## 许可证

见 [LICENSE](LICENSE)。
