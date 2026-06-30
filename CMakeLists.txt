cmake_minimum_required(VERSION 3.16)
project(d_sdf CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

# ---- Vendored Eigen (header-only, submodule at extern/eigen) ---------------
# sxyu/sdf does not bundle Eigen; we provide it via a pinned submodule.
# The Eigen repo root is the include path: headers live at
#   extern/eigen/Eigen/Core, extern/eigen/Eigen/Geometry, etc.
set(EIGEN_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/extern/eigen")

# ---- sdf_c: our C shim + sxyu/sdf implementation --------------------------
# We build directly from sxyu/sdf's source files (src/sdf.cpp + src/util.cpp)
# rather than add_subdirectory on upstream's CMakeLists, which would pull in
# demo / Python / install rules we do not need. renderer.cpp is excluded
# because the Renderer class is not part of our public C API.
add_library(sdf_c STATIC
    csrc/sdf_c.cpp
    extern/sdf/src/sdf.cpp
    extern/sdf/src/util.cpp
)

target_include_directories(sdf_c
    PUBLIC  ${CMAKE_CURRENT_SOURCE_DIR}/include
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/extern/sdf/include
    PRIVATE ${EIGEN_INCLUDE_DIR}
)

# sxyu/sdf uses std::thread; link pthreads so the library is self-contained.
find_package(Threads REQUIRED)
target_link_libraries(sdf_c PRIVATE Threads::Threads)

# Suppress noise from upstream code, keep our shim clean.
target_compile_options(sdf_c PRIVATE
    -O2
    -Wno-deprecated-declarations
    -Wno-deprecated
)
