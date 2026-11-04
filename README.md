# Biaox

一个基于 **Qt 6 + Qt Quick Controls** 的小工具箱。界面参考 Qt Quick Controls Gallery：保留欢迎页、左上角菜单按钮和从左侧滑出的抽屉；每个菜单项打开一个独立的小工具页面。

当前内置：

- **MobaXterm 激活文件**：输入用户名和版本号，生成并保存 `Custom.mxtpro`。
- **新功能待添加**：占位页，后续工具会插在它前面。

界面使用 Material 深色主题和简体中文，目前UI的配色方案模仿的是Pornhub网站的配色，不提供运行时主题切换。

## 环境要求

- Qt 6.8 或更新版本（当前在 **Qt 6.12.0** 上构建验证）
- CMake 3.21 或更新版本
- C++17 编译器
- Qt 模块：Core、Gui、Qml、Quick、QuickControls2、QuickDialogs2、Test（仅测试需要）
- `QZipWriter` 使用的 QtCore 私有头文件；CMake 通过 `Qt6::CorePrivate` 引入，配置阶段出现私有模块警告是预期行为

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

测试覆盖已有的 MobaXterm keygen 后端逻辑：

- ASCII 和中文用户名的已知 license 向量
- 非法用户名、非法版本号
- `Custom.mxtpro` 的 ZIP 结构和 `Pro.key` 内容
- 版本列表重载和自动追加新版本

UI 本身通过启动应用进行手工冒烟检查。

## 使用

1. 启动后是欢迎页。点击左上角的菜单按钮，或点击“打开工具箱”，也可以从窗口左边缘向右滑动打开抽屉。
2. 选择 **MobaXterm 激活文件**：
   - 输入用户名。用户名不能包含 `#`、`|` 或控制字符。
   - 从下拉框选择版本号，或直接输入 `major.minor`，例如 `26.6`。
   - 点击“生成”，在保存对话框中选择位置。文件名默认预填为 `Custom.mxtpro`，程序会自动补全 `.mxtpro` 后缀（建议保持该文件名）。
   - 生成后“输出文件”中会显示保存路径，可点击“打开文件夹”。
3. 点击左上角返回按钮，或按 `Esc` / `Back`，回到欢迎页。
4. 最后一页“新功能待添加”用于后续扩展。

将生成的 `Custom.mxtpro` 放到 MobaXterm 安装目录（与 `MobaXterm.exe` 同级），然后重启 MobaXterm。

> MobaXterm 是商业软件。本工具仅适合在拥有有效授权或纯学习研究的前提下使用，请通过官方渠道购买 Professional 版。

### 版本列表文件

Moba 页面会自动从内置默认列表初始化 `versions.txt`。文件位置取决于平台的应用配置目录，页面底部会显示真实路径。Linux 下通常是：

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

- 下拉框暂时设置成不可编辑，如需修改适配的MobaXterm版本号，请手动修改版本列表文件。
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
   import QtQuick.Controls
   import Biaox

   ScrollablePage {
       id: page
       title: qsTr("我的工具")

       ColumnLayout {
           width: parent.width
           spacing: 16

           Label {
               Layout.fillWidth: true
               text: qsTr("这里放工具界面。")
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

## 项目结构

```text
Biaox/
├── CMakeLists.txt
├── src/
│   ├── main.cpp
│   └── moba/                 # 从 mobaXkeygen 复制的后端
├── qml/
│   ├── Main.qml              # header + Drawer + StackView
│   ├── ToolCatalog.qml       # 工具列表（Singleton）
│   ├── WelcomePage.qml
│   ├── ScrollablePage.qml
│   └── pages/
│       ├── MobaXtermKeygenPage.qml
│       └── ComingSoonPage.qml
├── resources/versions.txt
├── icons/biaox/              # 菜单/返回图标主题
└── tests/
```

## 实现说明和限制

- 所有 QML 页面和 C++ `MobaKeygen` 注册在同一个 QML 模块 `Biaox` 中，入口使用 `engine.loadFromModule("Biaox", "Main")`。
- `QZipWriter` / `QZipReader` 是 QtCore 私有 API。当前 Qt 6.12 可用；如果以后更换 Qt 版本导致私有头变化，只需调整 `src/moba/mxtprowriter.cpp` 和测试中的读取部分。
- 深色主题下菜单/返回图标为黑色 PNG，通过 `icon.color: "white"` 着色。
- 抽屉只在欢迎页可交互滑出；进入工具页后通过左上角返回按钮回到欢迎页，与 Gallery 的默认行为一致。
- 当前没有实现运行时样式切换、深浅色切换或横向固定抽屉。
- 主要在 Linux 上构建验证；Windows / macOS 理论上可构建，但保存对话框和打开文件夹的行为可能因平台而异。
- 部分界面结构和菜单/返回图标来自 Qt Quick Controls Gallery（BSD-3-Clause，版权归 The Qt Company Ltd.），复制文件保留了原版权头；Moba keygen 后端来自同级的 `mobaXkeygen` 项目。
- UI配色想模仿Pornhub的黄黑设计，但是控件使用了Qt Quick Controls的Material Style，这可能限制了自定义控件的风格。
