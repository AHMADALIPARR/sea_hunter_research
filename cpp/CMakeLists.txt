# SPDX-License-Identifier: AGPL-3.0-only
# Uncertified — research prototype, not for operational use.
cmake_minimum_required(VERSION 3.14)
project(alphazero_cpp LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(az_engine
    src/go_board.cpp
    src/mcts.cpp
)
target_include_directories(az_engine PUBLIC include)

add_executable(az_selfplay src/selfplay_main.cpp)
target_link_libraries(az_selfplay PRIVATE az_engine)

add_executable(az_test src/test_go_board.cpp)
target_link_libraries(az_test PRIVATE az_engine)

enable_testing()
add_test(NAME go_board_tests COMMAND az_test)
