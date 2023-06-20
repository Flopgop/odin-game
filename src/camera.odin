package main

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

@(private="file")
facing: Vector3f32

getRelativeForward :: proc(cam: ^rl.Camera) -> linalg.Vector3f32 {
    forward := cam.target-cam.position
    forward.y = 0
    return normalize_f32(forward)
}
getRelativeUp :: proc(cam: ^rl.Camera) -> linalg.Vector3f32 {
    return normalize_f32(cam.up)
}
getRelativeRight :: proc(cam: ^rl.Camera) -> linalg.Vector3f32 {
    right := linalg.vector_cross3(getRelativeForward(cam), getRelativeUp(cam))
    right.y = 0
    return normalize_f32(right)
}

moveCameraForward :: proc(cam: ^rl.Camera, distance: f32) {
    forward := getRelativeForward(cam)
    moveCamera(cam,distance,forward)
}

moveCameraBackward :: proc(cam: ^rl.Camera, distance: f32) {
    forward := getRelativeForward(cam)
    moveCamera(cam,distance,-forward)
}

moveCameraRight :: proc(cam: ^rl.Camera, distance: f32) {
    right := getRelativeRight(cam)
    moveCamera(cam,distance,right)
}

moveCameraLeft :: proc(cam: ^rl.Camera, distance: f32) {
    right := getRelativeRight(cam)
    moveCamera(cam,distance,-right)
}

moveCameraUp :: proc(cam: ^rl.Camera, distance: f32) {
    moveCamera(cam,distance,getRelativeUp(cam))
}

moveCameraDown :: proc(cam: ^rl.Camera, distance: f32) {
    moveCamera(cam,distance,-getRelativeUp(cam))
}

moveCamera :: proc (cam: ^rl.Camera, distance: f32, direction: linalg.Vector3f32) {
    cam.position += direction*distance
    cam.target += direction*distance
}

cameraYaw :: proc(cam: ^rl.Camera, angle: f32) {
    up := getRelativeUp(cam)
    target := rotateByAxisAngle_f32(cam.target-cam.position, up, angle)
    cam.target = cam.position+target
}

cameraPitch :: proc (cam: ^rl.Camera, angle: f32) {
    up := getRelativeUp(cam)
    target := cam.target-cam.position

    transformedAngle := angle

    maxUp := angle_f32(up, target)-0.001
    if angle > maxUp {transformedAngle = maxUp}

    maxDown := (angle_f32(-up, target)*-1)+0.001
    if angle < maxDown {transformedAngle = maxDown}

    right := getRelativeRight(cam)
    target = rotateByAxisAngle_f32(target, right, transformedAngle)
    cam.target = cam.position + target
}