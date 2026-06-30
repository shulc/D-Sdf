/// Smoke-test for D-Sdf: build a triangulated unit cube (half-extent 0.5,
/// centred at the origin, 12 triangles), query signed distances and
/// containment at representative points, then assert expected signs and
/// magnitudes.
///
/// The SDF uses sxyu/sdf's "nearest-vertex + incident-face" approximation
/// (see sdfc_distance docs), which is exact enough for a regular cube:
///   - origin (inside)      : expected dist ~ -0.5, contains = 1
///   - (2, 0, 0) (outside)  : expected dist ~ +1.5, contains = 0
///   - (0.5, 0, 0) (surface): expected |dist| < 0.15
module sdf_cube;

import std.stdio  : writefln, writeln;
import std.math   : abs, sqrt;
import sdf.c;

void main()
{
    // -------------------------------------------------------------------------
    // Unit cube: 8 vertices, half-extent 0.5, centred at origin.
    // Vertices ordered so that triangle normals point outward (CCW from outside).
    // -------------------------------------------------------------------------
    //
    //     v7-----v6
    //    /|      /|
    //   v4-----v5 |
    //   |  v3--|--v2
    //   | /    | /
    //   v0-----v1
    //
    //   v0 = (-0.5, -0.5, -0.5)   v1 = ( 0.5, -0.5, -0.5)
    //   v2 = ( 0.5,  0.5, -0.5)   v3 = (-0.5,  0.5, -0.5)
    //   v4 = (-0.5, -0.5,  0.5)   v5 = ( 0.5, -0.5,  0.5)
    //   v6 = ( 0.5,  0.5,  0.5)   v7 = (-0.5,  0.5,  0.5)

    immutable float[24] verts = [
        -0.5f, -0.5f, -0.5f,  //  0
         0.5f, -0.5f, -0.5f,  //  1
         0.5f,  0.5f, -0.5f,  //  2
        -0.5f,  0.5f, -0.5f,  //  3
        -0.5f, -0.5f,  0.5f,  //  4
         0.5f, -0.5f,  0.5f,  //  5
         0.5f,  0.5f,  0.5f,  //  6
        -0.5f,  0.5f,  0.5f,  //  7
    ];

    // 12 triangles (2 per face), outward CCW normals.
    immutable uint[36] tris = [
        0, 2, 1,  0, 3, 2,  // -Z face
        4, 5, 6,  4, 6, 7,  // +Z face
        0, 1, 5,  0, 5, 4,  // -Y face
        3, 6, 2,  3, 7, 6,  // +Y face
        0, 4, 7,  0, 7, 3,  // -X face
        1, 2, 6,  1, 6, 5,  // +X face
    ];

    // Build the SDF.  robust=1 for reliable containment even on marginal winding.
    sdfc_t* h = sdfc_build(verts.ptr, 8, tris.ptr, 12, /*robust=*/1);
    assert(h !is null, "sdfc_build returned null");
    scope (exit) sdfc_free(h);

    // -------------------------------------------------------------------------
    // Query points
    // -------------------------------------------------------------------------
    immutable float[9] queryPts = [
        0.0f,  0.0f, 0.0f,   // P0: origin — well inside
        2.0f,  0.0f, 0.0f,   // P1: far outside along +X
        0.5f,  0.0f, 0.0f,   // P2: on the +X face
    ];
    float[3] dist;
    sdfc_distance(h, queryPts.ptr, 3, dist.ptr);

    int[3] inside;
    sdfc_contains(h, queryPts.ptr, 3, inside.ptr);

    writefln("P0 (origin):          dist = %+.4f, inside = %d", dist[0], inside[0]);
    writefln("P1 (2,0,0):           dist = %+.4f, inside = %d", dist[1], inside[1]);
    writefln("P2 (0.5,0,0) surface: dist = %+.4f, inside = %d", dist[2], inside[2]);

    // -------------------------------------------------------------------------
    // Assertions
    // -------------------------------------------------------------------------

    // P0: origin is strictly inside → dist < 0, |dist| ≈ 0.5 (nearest face)
    assert(dist[0] < 0.0f,
           "P0 (origin) should be inside (negative distance)");
    assert(abs(dist[0]) > 0.3f && abs(dist[0]) < 0.7f,
           "P0: |dist| should be near 0.5 for the nearest cube face");
    assert(inside[0] == 1,
           "P0: contains() should report inside");

    // P1: (2,0,0) is outside → dist > 0, dist ≈ 1.5 (surface at x=0.5)
    assert(dist[1] > 0.0f,
           "P1 (2,0,0) should be outside (positive distance)");
    assert(dist[1] > 1.0f && dist[1] < 2.0f,
           "P1: dist should be around 1.5");
    assert(inside[1] == 0,
           "P1: contains() should report outside");

    // P2: (0.5,0,0) is on the face → |dist| should be small
    assert(abs(dist[2]) < 0.15f,
           "P2 (surface point): |dist| should be near zero");

    writeln("OK");
}
