package main

import "core:math/linalg"
import "core:math"

sign :: proc (i: f32) -> f32 {
    if i>0 do return 1
    if i<0 do return -1
    if i==0 do return 0
    return i
}

normalize_f32 :: proc(v: linalg.Vector3f32) -> linalg.Vector3f32 {
    result := linalg.Vector3f32{v.x, v.y, v.z}

    length := math.sqrt_f32(v.x*v.x+v.y*v.y+v.z*v.z)
    if length != 0 {
        ilength := 1/length
        result *= ilength
    }
    return result
}

rotateByAxisAngle_f32 :: proc(v, axis: linalg.Vector3f32, angle: f32) -> linalg.Vector3f32 {
    result := linalg.Vector3f32{v.x, v.y, v.z}

    length := math.sqrt_f32(axis.x*axis.x+axis.y*axis.y+axis.z*axis.z)
    if length == 0 {length = 1.0}
    ilength := 1/length

    t := angle/2
    a := math.cos_f32(t)
    w := axis*ilength*math.sin_f32(t)

    wv := linalg.vector_cross3(w,v)
    wwv := linalg.vector_cross3(w,wv)
    wv*=2*a
    wwv*=2
    return result+wv+wwv
}

angle_f32 :: proc(v1, v2: linalg.Vector3f32) -> f32 {
    cross := linalg.vector_cross3(v1, v2)
    len := math.sqrt_f32(cross.x*cross.x+cross.y*cross.y+cross.z*cross.z)
    dot := linalg.vector_dot(v1,v2)
    return math.atan2_f32(len,dot)
}