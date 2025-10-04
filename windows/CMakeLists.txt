cmake_minimum_required(VERSION 3.10)

# The name of the project.
project(Washio LANGUAGES CXX)

# The name of the executable.
set(BINARY_NAME "Washio")

# The application ID.
set(APPLICATION_ID "com.powersoft.washio")

set(RUNNER_SRC
    "runner/flutter_window.cc"
    "runner/main.cc"
    "runner/utils.cc"
    "runner/win32_window.cc"
    "flutter/generated_plugin_registrant.cc"
    "${CMAKE_CURRENT_BINARY_DIR}/flutter/generated_config.cmake"
)

# Link the runner with the Flutter library and the Windows API.
add_executable(${BINARY_NAME} WIN32 ${RUNNER_SRC})
target_link_libraries(${BINARY_NAME} PRIVATE flutter_wrapper_app)

# Add a build rule for the version resource file.
if (MSVC)
    target_sources(${BINARY_NAME} PRIVATE "runner/Runner.rc")
endif ()

# Set the icon for the executable.
set_target_properties(${BINARY_NAME} PROPERTIES
    VS_WIN32_EXECUTABLE_SUBSTEM_VERSION "10.0"
    MACOSX_BUNDLE_ICON_FILE "icons/app_icon.ico"
)

# Copy the data assets from the Flutter project.
add_custom_command(
    OUTPUT "${CMAKE_BINARY_DIR}/data"
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${PROJECT_BUILD_DIR}/data"
            "${CMAKE_BINARY_DIR}/data"
    DEPENDS flutter_data_assets
)
target_link_libraries(${BINARY_NAME} PRIVATE flutter_data_assets)

# Install the application.
install(TARGETS ${BINARY_NAME} DESTINATION "bin")
install(DIRECTORY "${CMAKE_BINARY_DIR}/data" DESTINATION "bin")
