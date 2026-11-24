
cmake_minimum_required(VERSION 3.15)

project(HostelManagementSystem)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Drogon CONFIG REQUIRED)
find_package(libsodium CONFIG REQUIRED)
find_package(jwt-cpp CONFIG REQUIRED)

# Collect all backend C++ source files
file(GLOB_RECURSE BACKEND_SOURCES
    CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
)

add_executable(HostelManagementSystem ${BACKEND_SOURCES})

target_include_directories(HostelManagementSystem
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(HostelManagementSystem
    PRIVATE
    Drogon::Drogon
    sodium
    jwt-cpp
)
