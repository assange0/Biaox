cmake_minimum_required(VERSION 3.21)
project(Biaox LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.10 REQUIRED COMPONENTS
    Core
    Concurrent
    Gui
    Qml
    Quick
    QuickControls2
    QuickDialogs2
)

qt_standard_project_setup(REQUIRES 6.10)

# Release 构建优化
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)

# 后端静态库：hash / moba 逻辑集中在此，主程序与测试共享同一份编译产物。
qt_add_library(biaox_core STATIC
    src/hash/filehasher.cpp
    src/hash/filehasher.hpp
    src/moba/mobakeygen.cpp
    src/moba/mobakeygen.hpp
    src/moba/mxtprowriter.cpp
    src/moba/mxtprowriter.hpp
)

add_library(Biaox::Core ALIAS biaox_core)

target_include_directories(biaox_core PUBLIC
    src/hash
    src/moba
)

target_link_libraries(biaox_core PUBLIC
    Qt6::Core
    Qt6::Concurrent
    Qt6::Gui
    Qt6::Qml
)

if(MSVC)
    target_compile_options(biaox_core PRIVATE /utf-8)
endif()

# QML 模块挂在 biaox_core 上：QML 文件与 C++ 类型（QML_ELEMENT）统一注册，
# 应用通过链接静态库获得模块；whole-archive 保证注册目标文件不被丢弃。
# ToolCatalog and Theme are QML singletons.
set_source_files_properties(
    qml/ToolCatalog.qml
    qml/Theme.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(biaox_core
    URI Biaox
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/ToolCatalog.qml
        qml/WelcomePage.qml
        qml/ScrollablePage.qml
        qml/components/AppButton.qml
        qml/components/AppComboBox.qml
        qml/components/AppDialog.qml
        qml/components/AppHeader.qml
        qml/components/AppIconButton.qml
        qml/components/AppMenu.qml
        qml/components/AppNavItem.qml
        qml/components/AppScrollBar.qml
        qml/components/AppSection.qml
        qml/components/AppStatus.qml
        qml/components/AppTextField.qml
        qml/components/BiaoxPage.qml
        qml/components/HashRow.qml
        qml/pages/FileHashPage.qml
        qml/pages/MobaXtermKeygenPage.qml
        qml/pages/ComingSoonPage.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Controls
        QtQuick.Dialogs
        QtQuick.Layouts
)

qt_add_executable(biaox WIN32 MACOSX_BUNDLE
    src/main.cpp
)

set_target_properties(biaox PROPERTIES
    OUTPUT_NAME Biaox
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

target_link_libraries(biaox PRIVATE
    biaox_core
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

# QML 模块在静态库里：必须整库链接，否则 qml 类型注册目标文件会被 -ffunction-sections 丢弃
if(MSVC)
    target_link_options(biaox PRIVATE "/WHOLEARCHIVE:$<TARGET_FILE:biaox_core>")
else()
    target_link_options(biaox PRIVATE
        "LINKER:--whole-archive,$<TARGET_FILE:biaox_core>,--no-whole-archive")
endif()

if(MSVC)
    target_compile_options(biaox PRIVATE /utf-8)
endif()

qt_add_resources(biaox "biaox_versions"
    PREFIX "/resources"
    BASE "resources"
    FILES
        resources/versions.txt
)

set(BIAOX_ICON_FILES
    icons/biaox/app.png
    icons/biaox/index.theme
    icons/biaox/20x20/back.png
    icons/biaox/20x20/drawer.png
    icons/biaox/20x20/menu.png
    icons/biaox/20x20@2/back.png
    icons/biaox/20x20@2/drawer.png
    icons/biaox/20x20@2/menu.png
    icons/biaox/20x20@3/back.png
    icons/biaox/20x20@3/drawer.png
    icons/biaox/20x20@3/menu.png
    icons/biaox/20x20@4/back.png
    icons/biaox/20x20@4/drawer.png
    icons/biaox/20x20@4/menu.png
)

qt_add_resources(biaox "biaox_icons"
    PREFIX "/icons"
    BASE "icons"
    FILES
        ${BIAOX_ICON_FILES}
)

include(GNUInstallDirs)

install(TARGETS biaox
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET biaox
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM

    # 不部署 Qt 翻译文件
    NO_TRANSLATIONS

    # 排除 QML 调试工具插件
    EXCLUDE_PLUGIN_TYPES qmltooling
)
install(SCRIPT ${deploy_script})

include(CTest)
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
