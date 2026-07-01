// msvc_compat.h — force-included on MSVC only (CMakeLists /FI flag).
//
// GCC and Clang pull <chrono> in transitively through <random> / <thread>;
// MSVC's standard library is stricter about transitive includes, so
// sdf/src/util.cpp (which uses std::chrono::high_resolution_clock) fails to
// compile without an explicit include.  Rather than modifying the upstream
// sxyu/sdf submodule, we inject it here.
#pragma once
#include <chrono>
