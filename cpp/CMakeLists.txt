# SPDX-License-Identifier: AGPL-3.0-only
# Uncertified — research prototype, not for operational use.
cmake_minimum_required(VERSION 3.14)
if(NOT DEFINED PROJECT_NAME)
  project(alphazero_cpp LANGUAGES CXX)
endif()
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(az_engine
    ${CMAKE_CURRENT_SOURCE_DIR}/src/go_board.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/mcts.cpp
)
target_include_directories(az_engine PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_executable(az_selfplay ${CMAKE_CURRENT_SOURCE_DIR}/src/selfplay_main.cpp)
target_link_libraries(az_selfplay PRIVATE az_engine)

add_executable(az_test ${CMAKE_CURRENT_SOURCE_DIR}/src/test_go_board.cpp)
target_link_libraries(az_test PRIVATE az_engine)

enable_testing()
add_test(NAME go_board_tests COMMAND az_test)
