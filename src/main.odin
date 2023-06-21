package main

import "tests"
import "core:os"
import "core:fmt"
import "core:math"
import "gameobject"
import "core:math/linalg"
import rl "vendor:raylib"

Vector3f32 :: linalg.Vector3f32

main :: proc () {   
    rl.SetConfigFlags({.WINDOW_TRANSPARENT, .WINDOW_UNDECORATED, .MSAA_4X_HINT})
    rl.InitWindow(1280,720,"Game")
    defer rl.CloseWindow()
    
    if len(os.args)>1 && os.args[1] == "test" {
        tests.run_tests()
        return
    }

    camera := rl.Camera {
        Vector3f32{10,10,10},
        Vector3f32{0,0,0},
        Vector3f32{0,1,0},
        90,
        .PERSPECTIVE,
    }

    defaultMaterial := rl.LoadMaterialDefault()
    rayMaterial := rl.LoadMaterialDefault()
    rayMaterial.maps[rl.MaterialMapIndex.ALBEDO].color = rl.RED
    playerMesh := rl.GenMeshCylinder(0.5,2,16)
    rayMesh := rl.GenMeshCube(0.01,0.01,0.5)
    floorMesh := rl.GenMeshCube(100,0.05,100)
    floorBB := rl.GetMeshBoundingBox(floorMesh)
    floorGameObject := gameobject.GameObject{
        floorMesh,
        defaultMaterial,
        floorBB,
        transpose(linalg.matrix4_translate(Vector3f32{0,0,0})),
    }
    playerOriginalBB := rl.GetMeshBoundingBox(playerMesh)

    objects: [dynamic]gameobject.GameObject
    append(&objects, floorGameObject)
    cubeMesh := rl.GenMeshCube(2,1,2)

    for i in 0..<1000 {
        cubeBB := rl.GetMeshBoundingBox(cubeMesh)
        cubeBB.min += Vector3f32{i%4<2?0:2,1.5*f32(i)+0.5,(i%4==0||i%4==3)?0:2}
        cubeBB.max += Vector3f32{i%4<2?0:2,1.5*f32(i)+0.5,(i%4==0||i%4==3)?0:2}
        cubeGameObject := gameobject.GameObject{
            cubeMesh,
            defaultMaterial,
            cubeBB,
            transpose(linalg.matrix4_translate(Vector3f32{i%4<2?0:2,1.5*f32(i)+0.5,(i%4==0||i%4==3)?0:2})),
        }
        append(&objects, cubeGameObject)
    }

    playerPos := Vector3f32{0,0,0}
    playerVel := Vector3f32{0,0,0}
    playerRotation := linalg.Vector4f32{}
    playerBB := playerOriginalBB

    jumping := false
    onGround := true

    rl.DisableCursor()
    defer rl.EnableCursor()
    rl.SetTargetFPS(90)
    for !rl.WindowShouldClose() {
        delta := rl.GetFrameTime()
        moveSpeed: f32 = 10
        if !onGround do moveSpeed *= 0.5
        if rl.IsKeyDown(.LEFT_CONTROL) {moveSpeed *= 3}
        if rl.IsKeyDown(.LEFT_SHIFT) {moveSpeed /= 3}
        if rl.IsKeyDown(.SPACE) && !jumping && onGround {
            jumping = true
            onGround = false
            playerVel.y += 20*delta
        }
        if rl.IsKeyDown(.W) {playerVel -= -getRelativeForward(&camera)*moveSpeed*delta}
        if rl.IsKeyDown(.A) {playerVel -= getRelativeRight(&camera)*moveSpeed*delta}
        if rl.IsKeyDown(.S) {playerVel -= getRelativeForward(&camera)*moveSpeed*delta}
        if rl.IsKeyDown(.D) {playerVel -= -getRelativeRight(&camera)*moveSpeed*delta}
        mouseDelta := rl.GetMouseDelta()
        cameraYaw(&camera, -mouseDelta.x*0.05*delta)
        cameraPitch(&camera, -mouseDelta.y*0.05*delta)

        if !onGround {
            playerVel.y -= delta
        }

        predictedPos := (camera.position+playerVel)-Vector3f32{0,1.75,0}
        predictedBB := rl.BoundingBox{playerOriginalBB.min + predictedPos, playerOriginalBB.max + predictedPos}
        notTouchingCount := len(objects)
        for object in objects {
            bb := object.boundingBox
            if rl.CheckCollisionBoxes(predictedBB, bb) {
                predictedCenter := predictedBB.min + (predictedBB.max - predictedBB.min) * 0.5
                bbCenter := bb.min + (bb.max - bb.min) * 0.5
                relativeCenter := bbCenter-predictedCenter
                predictedExtents := predictedBB.max-predictedBB.min
                bbExtents := bb.max-bb.min
                overlap := (predictedExtents+bbExtents)-linalg.abs(relativeCenter)

                collisionNormal := linalg.normalize(relativeCenter)
                if (overlap.x < overlap.y && overlap.x < overlap.z) {
                    collisionNormal = Vector3f32{sign(relativeCenter.x), 0, 0}
                } else if (overlap.y < overlap.x && overlap.y < overlap.z) {
                    collisionNormal = Vector3f32{0, sign(relativeCenter.y), 0}
                } else if (overlap.z < overlap.x && overlap.z < overlap.y) {
                    collisionNormal = Vector3f32{0, 0, sign(relativeCenter.z)}
                }

                collisionDistanceX := math.abs(predictedCenter.x - bbCenter.x) - (predictedExtents.x + bbExtents.x)
                collisionDistanceY := math.abs(predictedCenter.y - bbCenter.y) - (predictedExtents.y + bbExtents.y)
                collisionDistanceZ := math.abs(predictedCenter.z - bbCenter.z) - (predictedExtents.z + bbExtents.z)

                collisionDistance := math.min(collisionDistanceX, collisionDistanceY, collisionDistanceZ)

                if collisionNormal.y > 0.9 || collisionNormal.y < -0.9 {
                    jumping = false
                    onGround = true
                }                

                collisionNormal = linalg.normalize(collisionNormal)
                playerVel -= linalg.dot(playerVel, collisionNormal) * collisionNormal
                
                penetrationThreshold :: 0.01
                penetrationDepth :f32= math.max(0,collisionDistance)
                if penetrationDepth > penetrationThreshold {
                    playerVel = playerVel + collisionNormal * (penetrationDepth - penetrationThreshold)
                }                
            } else {
                notTouchingCount -= 1
            }
        }
        if notTouchingCount <= 0 {
            onGround = false
        }

        camera.position += playerVel
        camera.target += playerVel
        if camera.position.y <= -50 do camera.position.y = 50
        if camera.target.y <= -50 do camera.target.y = 50
        playerPos = camera.position-Vector3f32{0,1.75,0}
        playerBB.min = playerOriginalBB.min+playerPos
        playerBB.max = playerOriginalBB.max+playerPos

        playerVel.x *= 0.5*delta
        playerVel.z *= 0.5*delta

        direction := normalize_f32(camera.target - camera.position)
        angle := math.atan2(direction.x, direction.z)

        rl.BeginDrawing()
            rl.ClearBackground(rl.Color{69,69,69,255})
            rl.BeginMode3D(camera)
                for object in objects do gameobject.draw(object)
                rl.DrawMesh(rayMesh, rayMaterial, transpose(linalg.matrix4_translate(playerPos+Vector3f32{0,1.75,0})*linalg.matrix4_rotate(angle,Vector3f32{0,1,0})*linalg.matrix4_translate(Vector3f32{0,0,0.75})))
                rl.DrawMesh(playerMesh, defaultMaterial, transpose(linalg.matrix4_translate(playerPos)*linalg.matrix4_rotate(angle, Vector3f32{0,1,0})))
                rl.DrawBoundingBox(playerBB, rl.GREEN)
                rl.DrawBoundingBox(predictedBB, rl.BLUE)
                rl.DrawGrid(100,1)
            rl.EndMode3D()
            rl.DrawFPS(15,15)
            rl.DrawText(rl.TextFormat("Coordinates: X:%f Y:%f Z:%f", playerPos.x, playerPos.y, playerPos.z), 15, 35, 20, rl.GREEN)
            rl.DrawText(rl.TextFormat("Velocity: X:%f Y:%f Z:%f", playerVel.x, playerVel.y, playerVel.z), 15, 55, 20, rl.GREEN)
            rl.DrawText(rl.TextFormat("OnGround: %s", onGround ? "true" : "false" ), 15, 75, 20, rl.GREEN)
        rl.EndDrawing()
    }
}