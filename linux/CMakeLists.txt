cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "Washio")
set(APPLICATION_ID "com.powersoft.washio")

# Add default compile options for all compilers.
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Werror -fexceptions -D_GLIBCXX_USE_CXX11_ABI=0)
endif()

# Flutter library, compiled from the Dart code.
add_library(flutter_engine STATIC IMPORTED)
set_target_properties(flutter_engine PROPERTIES
  IMPORTED_LOCATION "${FLUTTER_ENGINE}"
  INTERFACE_INCLUDE_DIRECTORIES "${FLUTTER_ENGINE}/include"
)

# Application, which links to the Flutter library.
add_executable(${BINARY_NAME} "runner/main.cc" "runner/my_application.cc" "flutter/generated_plugin_registrant.cc")
target_link_libraries(${BINARY_NAME} flutter_engine)

# Copy the data assets from the Flutter project.
add_custom_command(
  OUTPUT "${CMAKE_BINARY_DIR}/data"
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${PROJECT_BUILD_DIR}/data"
          "${CMAKE_BINARY_DIR}/data"
  DEPENDS flutter_data_assets
)
target_link_libraries(${BINARY_NAME} PRIVATE flutter_data_assets)

# System-level dependencies.
target_link_libraries(${BINARY_NAME} PRIVATE
  pkg-config::gtk+-3.0
)

# Install the application.
install(TARGETS ${BINARY_NAME} DESTINATION "bin")
install(DIRECTORY "${CMAKE_BINARY_DIR}/data" DESTINATION "bin")
