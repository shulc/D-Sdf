// D-Sdf — C shim implementation.
//
// Wraps sdf::SDF in an opaque handle and normalises the sign convention:
//   sxyu/sdf operator()  : positive = inside, negative = outside
//   sdfc_distance output : negative = inside, positive = outside (standard)
//
// The SDF is constructed with copy=true so the handle owns its own copy of
// vertices and faces — callers may free their buffers after sdfc_build returns.

#include "sdf_c.h"
#include "sdf/sdf.hpp"

#include <memory>
#include <new>

// ---------------------------------------------------------------------------
// Internal handle
// ---------------------------------------------------------------------------

struct sdfc {
    std::unique_ptr<sdf::SDF> impl;
};

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

extern "C" sdfc_t* sdfc_build(const float*        vertices_xyz,
                               int                 num_vertices,
                               const unsigned int* indices,
                               int                 num_triangles,
                               int                 robust)
{
    if (!vertices_xyz || num_vertices <= 0 || !indices || num_triangles <= 0)
        return nullptr;

    // Build Eigen row-major views over the caller's flat arrays.
    //   sdf::Points    = Eigen::Matrix<float,    Dynamic, 3, RowMajor>
    //   sdf::Triangles = Eigen::Matrix<uint32_t, Dynamic, 3, RowMajor>
    // static_assert ensures unsigned int == sdf::Index (uint32_t) at compile time.
    static_assert(sizeof(unsigned int) == sizeof(sdf::Index),
                  "unsigned int must be 32 bits on this platform");

    Eigen::Map<const sdf::Points> verts(vertices_xyz, num_vertices, 3);
    Eigen::Map<const sdf::Triangles> faces(
        reinterpret_cast<const sdf::Index*>(indices), num_triangles, 3);

    sdfc* h = new (std::nothrow) sdfc();
    if (!h) return nullptr;

    try {
        // copy=true: SDF makes its own copies of verts + faces.
        h->impl.reset(new sdf::SDF(verts, faces, robust != 0, /*copy=*/true));
    } catch (...) {
        delete h;
        return nullptr;
    }
    return h;
}

extern "C" void sdfc_free(sdfc_t* h)
{
    delete h;  // delete nullptr is a no-op
}

// ---------------------------------------------------------------------------
// Query
// ---------------------------------------------------------------------------

extern "C" void sdfc_distance(const sdfc_t* h,
                               const float*  points_xyz,
                               int           num_points,
                               float*        out_signed_dist)
{
    if (!h || !h->impl || !points_xyz || num_points <= 0 || !out_signed_dist)
        return;

    Eigen::Map<const sdf::Points> query(points_xyz, num_points, 3);

    // sdf::SDF::operator() returns a column vector of SDF values with the
    // convention positive = inside, negative = outside. Negate for the
    // standard sign: negative = inside, positive = outside.
    sdf::Vector result = (*h->impl)(query);
    for (int i = 0; i < num_points; ++i)
        out_signed_dist[i] = -result(i);
}

extern "C" void sdfc_contains(const sdfc_t* h,
                               const float*  points_xyz,
                               int           num_points,
                               int*          out_inside)
{
    if (!h || !h->impl || !points_xyz || num_points <= 0 || !out_inside)
        return;

    Eigen::Map<const sdf::Points> query(points_xyz, num_points, 3);
    auto result = h->impl->contains(query);
    for (int i = 0; i < num_points; ++i)
        out_inside[i] = result(i) ? 1 : 0;
}
