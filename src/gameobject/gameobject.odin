package gameobject 

import "core:math/linalg"
import rl "vendor:raylib"

GameObject :: struct {
    mesh: rl.Mesh,
    material: rl.Material,
    boundingBox: rl.BoundingBox,
    transform: linalg.Matrix4f32, // order: scale, rotate, translate, transpose (required if the matrix is non-zero).
}

set_transform :: proc (o: ^GameObject, pos, scale: linalg.Vector3f32, rotation: linalg.Vector4f32) {
    o.transform = transpose(linalg.matrix4_scale(scale)*linalg.matrix4_rotate(rotation.w, linalg.Vector3f32(rotation.xyz)))
}

draw :: proc (o: GameObject) {
    rl.DrawMesh(o.mesh, o.material, o.transform)
    rl.DrawBoundingBox(o.boundingBox, rl.GREEN)
}