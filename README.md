# Biaox

一个基于 **Qt 6 + Qt Quick Controls** 的小工具箱。界面参考 Qt Quick Controls Gallery 的结构：保留欢迎页、左上角菜单按钮和从左侧滑出的抽屉；每个菜单项打开一个独立的小工具页面。

UI 使用项目内的**黑橙扁平设计系统**：Qt Quick Controls 的 **Basic Style** 作为行为基座，视觉由 `qml/Theme.qml` 和 `qml/components/` 下的 `App*` 组件统一提供。

当前内置：

- **MobaXterm 注册机**：输入用户名和版本号，生成并保存 `Custom.mxtpro`。
- **文件哈希校验**：选择或拖入单个文件，计算 MD5 / SHA-1 / SHA-256，复制结果并校验来源网站提供的哈希值。
- **新功能待添加**：占位页，后续工具会插在它前面。

界面使用简体中文和深色黑橙主题，配色受 Pornhub 的黑橙视觉启发，但不是其产品、商标或素材的复制。当前不提供运行时主题切换。

## 环境要求

- Qt 6.10 或更新版本（当前在 **Qt 6.12.0** 上构建验证）
- CMake 3.21 或更新版本
- C++17 编译器
- Qt 模块：Core、Gui、Qml、Quick、QuickControls2、QuickDialogs2、Concurrent、Test（仅测试需要）
- `QZipWriter` 使用的 QtCore 私有头文件；CMake 通过 `Qt6::CorePrivate` 引入，配置阶段出现私有模块警告是预期行为
- `QtConcurrent` 用于在后台线程计算文件哈希

## 构建和运行

在仓库根目录（`Biaox` 的同级目录）执行：

```bash
cmake -S Biaox -B Biaox/build -DCMAKE_BUILD_TYPE=Release
cmake --build Biaox/build -j"$(nproc)"
./Biaox/build/bin/Biaox
```

也可以用 Qt Creator 直接打开 `Biaox/CMakeLists.txt`，选择 Qt 6 Kit 后构建运行。

## 测试

```bash
ctest --test-dir Biaox/build --output-on-failure
```

测试覆盖 MobaXterm keygen 和文件哈希后端逻辑：

- ASCII 和中文用户名的已知 license 向量
- 非法用户名、非法版本号
- `Custom.mxtpro` 的 ZIP 结构和 `Pro.key` 内容
- 版本列表重载和自动追加新版本
- 空文件和 `abc` 的 MD5 / SHA-1 / SHA-256 已知向量
- 无效文件、目录和非本地 URL 的拒绝
- 预期哈希的常见格式解析、算法识别、匹配与不匹配

UI 本身通过启动应用进行手工冒烟检查。
本次 UI 重构另外在 Xvfb 下用截图复核了欢迎页、抽屉、工具页、下拉框、菜单、对话框和最小窗口尺寸。
文件哈希页也复核了空态、已选文件、计算完成、复制、校验通过/失败和拖拽选中。

## 使用

1. 启动后是欢迎页。点击左上角的菜单按钮，或点击“打开工具箱”，也可以从窗口左边缘向右滑动打开抽屉。
2. 选择 **MobaXterm 注册机**：
   - 输入用户名。用户名不能包含 `#`、`|` 或控制字符。
   - 从下拉框选择版本号，或直接输入 `major.minor`，例如 `26.6`。
   - 点击“生成”，在保存对话框中选择位置。文件名默认预填为 `Custom.mxtpro`，程序会自动补全 `.mxtpro` 后缀（建议保持该文件名）。
   - 生成后“输出文件”中会显示保存路径，可点击“打开文件夹”。
3. 选择 **文件哈希校验**：
   - 点击“选择文件”打开系统文件对话框，或把**单个**本地文件拖到文件面板。多文件和目录会被拒绝。
   - 选择后点击“计算”，程序在后台计算 MD5、SHA-1、SHA-256；大文件计算期间界面保持响应，但不显示进度，也没有取消按钮。
   - 每个哈希值可点击“复制”写入系统剪贴板。
   - 在“校验”输入框中粘贴来源网站提供的哈希值，程序会自动识别算法并实时比对。支持大小写混用、`SHA256:` 前缀、`hash *文件名` 和分组书写；只接受一个哈希值。
   - 计算完成后“计算”仍可再次点击，用于重新计算同一个文件。
4. 点击左上角返回按钮，或按 `Esc` / `Back`，回到欢迎页。
5. 最后一页“新功能待添加”用于后续扩展。

将生成的 `Custom.mxtpro` 放到 MobaXterm 安装目录（与 `MobaXterm.exe` 同级），然后重启 MobaXterm。

> MobaXterm 是商业软件。本工具仅适合在拥有有效授权或纯学习研究的前提下使用，请通过官方渠道购买 Professional 版。

### 适配的MobaXterm版本列表文件

Moba 页面会自动从内置默认列表初始化 `versions.txt`。文件位置取决于平台的应用配置目录；版本号输入框下方会显示“版本列表文件”的真实路径。Linux 下通常是：

```text
~/.config/Biaox/versions.txt
```

文件格式：

```text
# 每行一个 major.minor，以 # 开头为注释
26.6
26.5
27.0
```

- 下拉框暂时设置成不可编辑，如需修改适配的 MobaXterm 版本号，请手动修改版本列表文件。
- 生成成功后，新版本会自动追加到文件。
- 修改外部文件后，点击“刷新”重新加载；点击“编辑”用系统编辑器打开。
- 设置 `MOBAXKEYGEN_CONFIG_DIR` 环境变量可以指定另一个配置目录（测试也使用这个变量隔离配置）。
- Biaox 使用自己的配置目录，不会自动迁移旧 `mobaXkeygen` 项目的 `versions.txt`；如需保留旧列表，请手工复制到上述路径。

## 新增一个工具页面

新增工具只需要三步，不需要修改 `Main.qml`：

1. 在 `qml/pages/` 新建页面，例如 `MyToolPage.qml`：

   ```qml
   import QtQuick
   import QtQuick.Layouts
   import Biaox

   ScrollablePage {
       id: page
       title: qsTr("我的工具")

       ColumnLayout {
           width: parent.width
           spacing: Theme.spaceXl

           AppSection {
               Layout.fillWidth: true
               title: qsTr("工具设置")

               AppTextField {
                   Layout.fillWidth: true
                   placeholderText: qsTr("输入内容")
               }

               AppButton {
                   text: qsTr("执行")
                   variant: "primary"
               }
           }
       }
   }
   ```

2. 把文件加入 `CMakeLists.txt` 的 `qt_add_qml_module(... QML_FILES ...)` 列表：

   ```cmake
   qml/pages/MyToolPage.qml
   ```

3. 在 `qml/ToolCatalog.qml` 的 `ListModel` 中，把占位项之前插入一条：

   ```qml
   ListElement {
       title: qsTr("我的工具")
       subtitle: qsTr("一句话描述")
       source: "pages/MyToolPage.qml"
       isPlaceholder: false
   }
   ```

重新构建即可。`source` 是相对于 `qml/Main.qml` 的路径；“新功能待添加”页面保留在最后作为占位。

如果新工具需要打开自己的对话框，把 `ScrollablePage` 继承来的 `dialogOpen` 绑定到对话框的可见性，例如：

```qml
dialogOpen: myDialog.visible
```

这样按 `Esc` 时会优先关闭工具自己的对话框，而不会意外返回欢迎页。

如果新工具需要 C++ 后端，可以把类加入 `src/` 和目标源码列表，在头文件里使用 `QML_ELEMENT`，QML 中通过 `import Biaox` 使用。当前 `MobaKeygen` 就是这样注册的。

## UI 设计系统

### 设计 token

所有颜色、字号、间距和控件尺寸集中在 `qml/Theme.qml`（`pragma Singleton`）。页面和组件中不要再写颜色/字号字面量。

核心色板：

| Token | 值 | 用途 |
|---|---|---|
| `Theme.brand` | `#FF9900` | 品牌色、主按钮、focus、选中态 |
| `Theme.brandHover` / `brandPressed` | `#FFAD33` / `#E68A00` | 主按钮状态 |
| `Theme.canvas` / `header` | `#000000` | 窗口、顶栏、页面底色 |
| `Theme.drawer` | `#0A0A0A` | 抽屉 |
| `Theme.surface` / `surfaceAlt` | `#121212` / `#1A1A1A` | 弹层、对话框、hover 层 |
| `Theme.input` | `#0F0F0F` | 输入框底色 |
| `Theme.border` / `borderStrong` | `#2A2A2A` / `#5A5A5A` | 分隔线 / 交互描边 |
| `Theme.textPrimary` / `textSecondary` / `textMuted` | `#FFFFFF` / `#A6A6A6` / `#8A8A8A` | 文字层级 |
| `Theme.warning` | `#FFB74D` | 警告状态 |
| `Theme.danger` | `#FF5C5C` | 错误状态 |
| `Theme.success` | `#69F0AE` | 成功状态 |
| `Theme.overlay` | `#B3000000` | 70% 黑色遮罩 |

字号阶梯：32（欢迎页标题）、24（占位页/对话框强调）、18（顶栏标题/对话框正文标题）、16（区块标题/导航标题）、15（正文/输入/按钮）、14（标签/状态）、13（路径/提示）。正文使用平台默认字体族，不硬编码字体，保证中文回退。

尺寸：顶栏 56、输入/按钮 36、图标按钮 40、圆角 4（96px 品牌 logo 用 `radiusLg` 8）、页面左右内边距 24、工具页最大内容宽 820、抽屉 300、对话框最大宽 480。

### 组件

| 组件 | 说明 |
|---|---|
| `BiaoxPage` | 所有页面的基类，统一黑底和 `dialogOpen` 约定 |
| `ScrollablePage` | 可滚动工具页基类，内容居中、最大宽 820 |
| `AppButton` | `variant: "primary" \| "secondary" \| "ghost"`，统一尺寸/状态/focus |
| `AppIconButton` | 顶栏图标按钮，hover/focus 图标变橙 |
| `AppTextField` | 36px 输入框，橙色 focus 描边，无浮动标签 |
| `AppComboBox` | 紧凑下拉框，宽度随控件、最大高度 240、超出滚动 |
| `AppHeader` | 56px 顶栏，支持页面标题/根页面品牌字标 |
| `AppMenu` | 暗色菜单，40px 行高，hover 橙字 |
| `AppDialog` | 暗色对话框，4px 圆角、1px 描边、自定义底部按钮 |
| `AppSection` | 平面区块：15px 标题 + 1px 分隔线 + 内容 |
| `AppNavItem` | 抽屉导航项，56px，hover/选中橙条，左内边距 24 与抽屉头部/页脚同基线 |
| `AppStatus` | 状态行，`severity: "info" \| "success" \| "warning" \| "error"`（成功绿、警告橙、错误红） |
| `AppScrollBar` | 6px 细滚动条，内容溢出时显示，手柄距容器内容右缘统一内缩 4px |
| `HashRow` | 文件哈希页的单行哈希结果：算法名 + 匹配徽标 + 只读值 + 复制按钮 |

### 使用约定

- 每个页面只放一个主操作按钮（`variant: "primary"`）；其余操作使用 `secondary`。
- 错误用 `AppStatus` 的 `error`（红），提示/文件名警告用 `warning`（橙），校验通过用 `success`（绿），普通信息用 `info`。
- 文件哈希页的拖拽面板用 `surface` 底 + 弱描边（`border`）与输入框（`input` 底 + `borderStrong`）区分，1px 描边、4px 圆角；拖入有效文件时描边变橙，无效拖拽变红；不新增卡片或阴影。
- 整个 UI 只使用 **0 或 4px 圆角**（96px 品牌 logo 除外，用 `radiusLg`）；不要新增胶囊按钮、卡片阴影、水波纹、缩放弹层等 Material 语言。应用图标本身是品牌资产，是唯一例外。
- 不再使用 Material Style。不要在页面中 `import QtQuick.Controls.Material`，也不要写 `Material.*` 附加属性。
- 平面区块用 `AppSection` 的标题 + 分隔线分组，不要把 Material `Frame` 当成卡片使用。
- 菜单里的分组分隔线用 `AppMenu` 的 `dividerBeforeText` 指定（Qt 6.12 中 `MenuSeparator` 与自定义 delegate 不兼容，不要直接使用）。
- 系统 `FileDialog` 和 OS 窗口标题栏/边框由平台绘制，是仅有的非自绘表面：桌面环境通常跟随系统主题；在无桌面/裸 X 环境下文件对话框可能回退为浅色 Qt 对话框，这是预期例外。
- 目前只提供深色主题，没有运行时主题切换或浅色主题。

### 验收红线（改 UI 后自查）

1. **对比度**：正文（textPrimary）≥ 7:1、次要文字（textSecondary/textMuted）≥ 4.5:1；禁用态用 `Theme.textDisabled`（在 #000 上约 4.1:1），不得回退到更暗的自定义灰。
2. **基线**：抽屉、页面内容、对话框统一 24px 左基线；不新增自定义缩进。
3. **选中态**：列表/下拉的"当前选中"必须用 `Theme.selectedOverlay`（品牌橙 12%），`Theme.hoverOverlay` 只用于 hover；两者同时成立时选中态优先。
4. **滚动条**：一律用 `AppScrollBar`，手柄距容器内容右缘 4px；浮层内缩 = 浮层 padding + 滚动条内缩，不要写自定义位置。
5. **首屏可用**：新增/修改工具页后，在默认 960×640 与最小 720×480 两种尺寸下检查主流程入口首屏可见（可滚动，但不能被折叠线藏住）。

## 项目结构

```text
Biaox/
├── CMakeLists.txt
├── src/
│   ├── main.cpp              # Basic style + 启动暗色 palette
│   ├── hash/                 # 文件哈希后端（QtConcurrent）
│   └── moba/                 # 从 mobaXkeygen 复制的后端
├── qml/
│   ├── Main.qml              # header + Drawer + StackView + 菜单/关于
│   ├── Theme.qml             # 设计 token（Singleton）
│   ├── ToolCatalog.qml       # 工具列表（Singleton）
│   ├── WelcomePage.qml
│   ├── ScrollablePage.qml
│   ├── components/           # BiaoxPage + App* 统一控件 + HashRow
│   └── pages/
│       ├── FileHashPage.qml
│       ├── MobaXtermKeygenPage.qml
│       └── ComingSoonPage.qml
├── resources/versions.txt
├── icons/biaox/              # 菜单/返回/更多图标主题
└── tests/
```

## 实现说明和限制

- 所有 QML 页面和 C++ `MobaKeygen`、`FileHasher` 注册在同一个 QML 模块 `Biaox` 中，入口使用 `engine.loadFromModule("Biaox", "Main")`。
- 文件哈希在 `QtConcurrent` 后台线程中分块计算，三种算法共用一次文件读取；页面不提供进度和取消 UI，离开页面时会取消后台任务。
- `QZipWriter` / `QZipReader` 是 QtCore 私有 API。当前 Qt 6.12 可用；如果以后更换 Qt 版本导致私有头变化，只需调整 `src/moba/mxtprowriter.cpp` 和测试中的读取部分。
- `main.cpp` 明确设置为 Qt Quick Controls 的 **Basic** style，并设置启动暗色 palette；UI 的颜色/结构由 `Theme.qml` 和 `App*` 组件提供。
- 菜单/返回/更多图标仍是黑色 PNG，通过 `icon.color` 绑定到 `Theme`：默认白色，hover/focus 橙色。应用图标 `qrc:/icons/biaox/app.png` 同时用于欢迎页和抽屉。
- 抽屉只在欢迎页可交互滑出；进入工具页后通过左上角返回按钮回到欢迎页，与 Gallery 的默认行为一致。
- 当前没有实现运行时样式切换、深浅色切换或横向固定抽屉。
- 主要在 Linux 上构建验证；Windows / macOS 理论上可构建，但保存对话框和打开文件夹的行为可能因平台而异。
- 部分界面结构和菜单/返回图标来自 Qt Quick Controls Gallery（BSD-3-Clause，版权归 The Qt Company Ltd.），复制文件保留了原版权头；Moba keygen 后端来自同级的 `mobaXkeygen` 项目。
- UI 的黑橙扁平风格受 Pornhub 配色启发，但没有使用其 logo、字体、图片或商标，也不代表与其有任何关联。
