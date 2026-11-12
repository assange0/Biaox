find_package(Qt6 REQUIRED COMPONENTS Test Concurrent CorePrivate)

# 测试链接 biaox_core 静态库，不再重复编译后端源码。
# CorePrivate 仅供测试用 QZipReader 作独立校验 oracle（应用本体不依赖私有 API）。

qt_add_executable(tst_mobakeygen
    tst_mobakeygen.cpp
)

target_link_libraries(tst_mobakeygen PRIVATE
    biaox_core
    Qt6::Core
    Qt6::CorePrivate
    Qt6::Test
)

if(MSVC)
    target_compile_options(tst_mobakeygen PRIVATE /utf-8)
endif()

qt_add_resources(tst_mobakeygen "tst_mobakeygen_versions"
    PREFIX "/resources"
    BASE "${PROJECT_SOURCE_DIR}/resources"
    FILES
        "${PROJECT_SOURCE_DIR}/resources/versions.txt"
)

add_test(NAME tst_mobakeygen COMMAND tst_mobakeygen)

qt_add_executable(tst_filehasher
    tst_filehasher.cpp
)

target_link_libraries(tst_filehasher PRIVATE
    biaox_core
    Qt6::Core
    Qt6::Concurrent
    Qt6::Test
)

if(MSVC)
    target_compile_options(tst_filehasher PRIVATE /utf-8)
endif()

add_test(NAME tst_filehasher COMMAND tst_filehasher)
