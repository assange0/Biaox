find_package(Qt6 REQUIRED COMPONENTS Test)

qt_add_executable(tst_mobakeygen
    tst_mobakeygen.cpp
    ${PROJECT_SOURCE_DIR}/src/moba/mobakeygen.cpp
    ${PROJECT_SOURCE_DIR}/src/moba/mobakeygen.hpp
    ${PROJECT_SOURCE_DIR}/src/moba/mxtprowriter.cpp
    ${PROJECT_SOURCE_DIR}/src/moba/mxtprowriter.hpp
)

target_include_directories(tst_mobakeygen PRIVATE
    ${PROJECT_SOURCE_DIR}/src/moba
)

target_link_libraries(tst_mobakeygen PRIVATE
    Qt6::Core
    Qt6::CorePrivate
    Qt6::Gui
    Qt6::Qml
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
