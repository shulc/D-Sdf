// D-Sdf — C shim API around sxyu/sdf (https://github.com/sxyu/sdf).
//
// Exposes a minimal extern "C" surface so D (or any other language with a
// C FFI) can build a signed-distance field from a triangle mesh and query
// it without touching C++ or Eigen.
//
// Sign convention (deliberately normalised from sxyu/sdf's internal choice):
//   sdfc_distance result:  negative  = inside the mesh
//                          positive  = outside the mesh
//                          ~0        = on the surface
//
// All buffers are tightly-packed floats / uints; no ownership transfer
// (the SDF makes an internal copy of vertex/index data at build time).

#ifndef SDF_C_H
#define SDF_C_H

#ifdef __cplusplus
extern "C" {
#endif

/// Opaque handle to a built signed-distance field instance.
typedef struct sdfc sdfc_t;

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

/// Build a signed-distance field from a triangle mesh.
///
///   vertices_xyz  — flat XYZ float array [x0,y0,z0, x1,y1,z1, ...],
///                   length = 3 * num_vertices
///   num_vertices  — vertex count (must be > 0)
///   indices       — flat triangle index array [i0,j0,k0, i1,j1,k1, ...],
///                   length = 3 * num_triangles
///   num_triangles — triangle count (must be > 0)
///   robust        — non-zero: use robust winding-number containment test;
///                   handles self-intersecting or badly-wound meshes at the
///                   cost of some speed. Zero: assume a clean, watertight mesh.
///
/// Returns NULL on invalid input or allocation failure.
/// The mesh is assumed to be watertight for correct sign computation.
sdfc_t* sdfc_build(const float*        vertices_xyz,
                   int                 num_vertices,
                   const unsigned int* indices,
                   int                 num_triangles,
                   int                 robust);

/// Release all resources held by a handle produced by sdfc_build.
/// Passing NULL is a no-op.
void sdfc_free(sdfc_t* sdf);

// ---------------------------------------------------------------------------
// Query
// ---------------------------------------------------------------------------

/// Compute approximate signed distances from a batch of points to the mesh.
///
///   points_xyz      — flat XYZ float array, length = 3 * num_points
///   num_points      — number of query points
///   out_signed_dist — caller-allocated output, length = num_points
///                     negative = inside, positive = outside
///
/// Uses the "nearest-vertex + incident-face" approximation from sxyu/sdf.
/// Results are accurate for well-behaved meshes; sign follows the mesh
/// winding (robust=true at build time improves sign stability on bad meshes).
void sdfc_distance(const sdfc_t* sdf,
                   const float*  points_xyz,
                   int           num_points,
                   float*        out_signed_dist);

/// Test containment for a batch of points.
///
///   points_xyz  — flat XYZ float array, length = 3 * num_points
///   num_points  — number of query points
///   out_inside  — caller-allocated output, length = num_points;
///                 1 = inside or on surface, 0 = outside
///
/// Correctness depends on robust mode: robust=true uses a winding-number
/// test that is stable even for imperfect meshes; robust=false uses a
/// faster ray-casting approach that may misclassify near self-intersections.
void sdfc_contains(const sdfc_t* sdf,
                   const float*  points_xyz,
                   int           num_points,
                   int*          out_inside);

#ifdef __cplusplus
}
#endif

#endif /* SDF_C_H */
