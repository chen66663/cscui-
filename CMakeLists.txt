cmake_minimum_required(VERSION 3.24)

project(cscui
    VERSION 1.0.0
    DESCRIPTION "cscui Qt Quick component workbench"
    LANGUAGES CXX
)

# Single-configuration generators otherwise default to an unoptimized build,
# which makes animation-heavy Qt Quick scenes appear artificially sluggish.
# Respect an explicitly selected configuration in local and CI environments.
if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
        Debug Release RelWithDebInfo MinSizeRel)
endif()

# Keep the language contract explicit for every generator and developer IDE.
set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ language standard")
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL
    "Generate compile_commands.json for IDEs and static analysis" FORCE)

find_package(Qt6 6.8 REQUIRED COMPONENTS Concurrent Quick Multimedia Network)
qt_standard_project_setup(REQUIRES 6.8)

option(CSCUI_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" OFF)

# The executable and QML module intentionally share the cscui product name.
qt_add_executable(cscui
    main.cpp
    core/music.cpp
    core/music.h
)

# QML files are collected only from the two owned source directories.  The
# narrow CONFIGURE_DEPENDS globs preserve automatic discovery without walking
# build, generated, or user-controlled directories.
set(CSCUI_QML_FILES Main.qml)
foreach(qml_directory IN ITEMS components pages)
    file(GLOB qml_files CONFIGURE_DEPENDS
        RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
        "${qml_directory}/*.qml"
    )
    list(SORT qml_files)
    list(APPEND CSCUI_QML_FILES ${qml_files})
endforeach()
if(NOT CSCUI_QML_FILES)
    message(FATAL_ERROR "No QML sources were found for cscui")
endif()

qt_add_qml_module(cscui
    URI cscui
    VERSION 1.0
    QML_FILES ${CSCUI_QML_FILES}
)

# Keep non-QML assets under one stable runtime prefix: qrc:/cscui/.
qt_add_resources(cscui_resources src.qrc)
target_sources(cscui PRIVATE ${cscui_resources})

target_link_libraries(cscui
    PRIVATE
        Qt6::Quick
        Qt6::Multimedia
        Qt6::Network
        Qt6::Concurrent
)
target_compile_features(cscui PRIVATE cxx_std_17)

if(MSVC)
    target_compile_options(cscui PRIVATE /W4 /permissive-)
    if(CSCUI_WARNINGS_AS_ERRORS)
        target_compile_options(cscui PRIVATE /WX)
    endif()
else()
    target_compile_options(cscui PRIVATE -Wall -Wextra -Wpedantic)
    if(CSCUI_WARNINGS_AS_ERRORS)
        target_compile_options(cscui PRIVATE -Werror)
    endif()
endif()

set_target_properties(cscui PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    WIN32_EXECUTABLE TRUE
    OUTPUT_NAME cscui
)

# CTest provides a stable CI entry point.  Qt's generated qmllint target is
# used so the test exercises the same QML module that is shipped.
include(CTest)
if(BUILD_TESTING)
    add_test(
        NAME cscui_qml_lint
        COMMAND ${CMAKE_COMMAND}
            --build "${CMAKE_BINARY_DIR}"
            --target cscui_qmllint
            --config $<CONFIG>
    )
    set_tests_properties(cscui_qml_lint PROPERTIES LABELS "qml;static")
endif()

include(GNUInstallDirs)
install(TARGETS cscui
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
