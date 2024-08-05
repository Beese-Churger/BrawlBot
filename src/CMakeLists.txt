cmake_minimum_required(VERSION 3.5)
set(CMAKE_CXX_STANDARD 11)
project(brawlbot-main LANGUAGES CXX)

find_package(aws-lambda-runtime REQUIRED)
add_executable(${PROJECT_NAME} "main.cpp")
target_link_libraries(${PROJECT_NAME} PUBLIC AWS::aws-lambda-runtime)
aws_lambda_package_target(${PROJECT_NAME})

find_package(nlohmann_json REQUIRED)
target_link_libraries(${PROJECT_NAME} PRIVATE nlohmann_json::nlohmann_json)

find_package(CURL REQUIRED)
include_directories(${CURL_INCLUDE_DIR})
target_link_libraries(${PROJECT_NAME} PRIVATE ${CURL_LIBRARIES})

# Find pkg-config
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBSODIUM REQUIRED libsodium)

# Include the directories
include_directories(${LIBSODIUM_INCLUDE_DIRS})

# # Link the libraries
# link_directories(${LIBSODIUM_LIBRARY_DIRS})

# Link against libsodium
target_link_libraries(${PROJECT_NAME} PRIVATE ${LIBSODIUM_LIBRARIES})