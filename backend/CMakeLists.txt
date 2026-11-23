cmake_minimum_required(VERSION 3.15)
project(HostelManagementSystem)

set(CMAKE_CXX_STANDARD 17)

# Find Drogon (installed via vcpkg)
find_package(Drogon CONFIG REQUIRED)
# Find libsodium for Argon2id hashing
find_package(libsodium CONFIG REQUIRED)
# Find jwt-cpp for JWT handling
find_package(jwt-cpp CONFIG REQUIRED)

# Add source files
add_executable(HostelManagementSystem
    main.cpp
    controllers/HealthController.cpp
)

target_include_directories(HostelManagementSystem PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(HostelManagementSystem PRIVATE Drogon::Drogon sodium jwt-cpp)
