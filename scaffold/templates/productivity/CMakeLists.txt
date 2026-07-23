cmake_minimum_required(VERSION 3.24)
project(__PROJECT_NAME__ VERSION 0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ language standard")
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Generate compile_commands.json" FORCE)
find_package(Qt6 6.8 REQUIRED COMPONENTS Quick Multimedia Network)
qt_standard_project_setup(REQUIRES 6.8)
qt_add_executable(__PROJECT_NAME__
    main.cpp
)
# Keep automatic QML discovery scoped to the project-owned component folder.
file(GLOB QML_COMPONENTS CONFIGURE_DEPENDS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "components/*.qml")
qt_add_qml_module(__PROJECT_NAME__
    URI cscui
    VERSION 1.0
    QML_FILES
                Main.qml
                pages/HomePage.qml
                pages/FavoritesPage.qml
                pages/SettingsPage.qml
                pages/TasksPage.qml
                pages/CalendarPage.qml
                pages/ReportsPage.qml
                ${QML_COMPONENTS}
)
qt_add_resources(APP_RESOURCES
    src.qrc
)
target_sources(__PROJECT_NAME__ PRIVATE ${APP_RESOURCES})
target_link_libraries(__PROJECT_NAME__ PRIVATE Qt6::Quick Qt6::Multimedia Qt6::Network)
target_compile_features(__PROJECT_NAME__ PRIVATE cxx_std_17)
if(MSVC)
    target_compile_options(__PROJECT_NAME__ PRIVATE /W4 /permissive-)
else()
    target_compile_options(__PROJECT_NAME__ PRIVATE -Wall -Wextra -Wpedantic)
endif()
include(CTest)
if(BUILD_TESTING)
    add_test(NAME __PROJECT_NAME___qml_lint
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR}
            --target __PROJECT_NAME___qmllint --config $<CONFIG>)
endif()
set_target_properties(__PROJECT_NAME__ PROPERTIES WIN32_EXECUTABLE TRUE)
