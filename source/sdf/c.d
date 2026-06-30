/// D bindings for the D-Sdf C shim (include/sdf_c.h).
///
/// Provides a 1-to-1 extern(C) mapping of the C API so D code can build and
/// query signed-distance fields without touching C++ or Eigen directly.
///
/// Sign convention:
///   sdfc_distance returns *negative* for points inside the mesh and
///   *positive* for points outside (standard signed-distance convention).
///
/// Typical usage:
/// ---
/// import sdf.c;
///
/// // 12-triangle unit cube (half-extent 0.5)
/// float[24] verts = [...];
/// uint[36]  tris  = [...];
/// sdfc_t* h = sdfc_build(verts.ptr, 8, tris.ptr, 12, /*robust=*/1);
/// scope(exit) sdfc_free(h);
///
/// float[3] q = [0f, 0f, 0f];
/// float dist;
/// sdfc_distance(h, q.ptr, 1, &dist);
/// assert(dist < 0, "origin is inside the cube");
/// ---
module sdf.c;

extern (C) @nogc nothrow:

/// Opaque handle to a built signed-distance field.
/// Created by sdfc_build, released by sdfc_free.
struct sdfc_t;

/// Build a signed-distance field from a triangle mesh.
///
///   vertices_xyz  — flat XYZ float array [x0,y0,z0, x1,y1,z1, ...],
///                   length = 3 * num_vertices
///   num_vertices  — vertex count (must be > 0)
///   indices       — flat triangle index array [i0,j0,k0, i1,j1,k1, ...],
///                   length = 3 * num_triangles
///   num_triangles — triangle count (must be > 0)
///   robust        — non-zero: robust winding-number containment (slower but
///                   handles self-intersecting meshes); zero: fast, requires
///                   a clean, watertight mesh
///
/// Returns null on invalid input or allocation failure.
sdfc_t* sdfc_build(const float* vertices_xyz,
                   int          num_vertices,
                   const uint*  indices,
                   int          num_triangles,
                   int          robust);

/// Release all resources held by a handle produced by sdfc_build.
/// Passing null is a no-op.
void sdfc_free(sdfc_t* sdf);

/// Compute approximate signed distances from a batch of points to the surface.
///
///   points_xyz      — flat XYZ float array, length = 3 * num_points
///   num_points      — number of query points
///   out_signed_dist — caller-allocated output, length = num_points;
///                     negative = inside, positive = outside
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
void sdfc_contains(const sdfc_t* sdf,
                   const float*  points_xyz,
                   int           num_points,
                   int*          out_inside);
