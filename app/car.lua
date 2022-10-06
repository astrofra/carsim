hg = require("harfang")
require("utils")

function CarModelCreate(name, instance_node_name, scene, scene_physics, resources, start_position, start_rotation)
    local o = {}
    o.start_position = start_position or hg.Vec3(0, 0, 0)
    o.start_rotation = start_rotation or hg.Vec3(0, 0, 0)
    o.name = name
   
    -- Instance_node is not affected by physics.
    o.instance_node = scene:GetNode(instance_node_name)
    if not o.instance_node:IsValid() then
        print("ERROR - Instance node not found !")
        return
    end
    o.instance_node:GetTransform():SetPos(hg.Vec3(0, 0, 0))
    o.scene_view = o.instance_node:GetInstanceSceneView()
    o.nodes = o.scene_view:GetNodes(scene)
    o.root_node = o.scene_view:GetNode(scene, "car_body")
    if not o.root_node:IsValid() then
        print("ERROR - Parent node not found !")
        return
    end
    o.root_node:GetTransform():SetPos(o.start_position)
    o.root_node:GetTransform():SetRot(o.start_rotation)
    local thrust_node = o.scene_view:GetNode(scene, "thrust")
    if not thrust_node:IsValid() then
        print("ERROR - 'thrust' node not found !")
        return
    end
    o.thrust_transform = thrust_node:GetTransform()
    o.wheels = {}
    for n = 0, 3 do
        wheel = o.scene_view:GetNode(scene, "wheel_" .. n)
        if not wheel:IsValid() then
            print("ERROR - Wheel_"..n.." node not found !")
            return
        end
        table.insert(o.wheels, wheel)
    end
    
    o.ray_dir = nil
    obj = o.wheels[1]:GetObject()
    _,bounds = obj:GetMinMax(resources)
    o.wheels_ray = bounds.mx.y
    o.ray_max_dist = o.wheels_ray + 0.2

    o.wheels_rot_speed = {0, 0, 0, 0}
    o.ground_hits = {false, false, false, false}
    o.ground_impacts = {nil, nil, nil, nil}

    -- Constants
    
    o.mass = NodeGetPhysicsMass(o.root_node)
    o.center_of_mass = NodeGetPhysicsCenterOfMass(o.root_node)
    o.spring_friction = 2500
    o.tires_reaction = 25
    o.tires_adhesion = 5000
    o.steering_angle_max = 25
    o.thrust_power = 400000 -- Acceleration
    o.brakes_power = 1000000
    o.steering_speed = 150
   
    -- Variables
    o.steering_angle = 0
   
    -- Setup physics

    -- o.chassis_rigid = scene:CreateRigidBody()
    -- o.chassis_rigid:SetType(hg.RBT_Dynamic)
    -- o.root_node:SetRigidBody(o.chassis_rigid)
    -- colbox = scene:CreateCollision()
    -- colbox:SetType(hg.CT_Cube)
    -- colbox:SetSize(hg.Vec3(1, 0.5, 3))
    -- colbox:SetMass(o.mass)
    -- colbox:SetLocalTransform(hg.TransformationMat4(hg.Vec3(0, 0, 0), hg.Deg3(0, 0, 0)))
    -- o.root_node:SetCollision(1,colbox)
    -- o.chassis_rigid:SetAngularDamping(0)
    -- o.chassis_rigid:SetLinearDamping(0)
    -- scene_physics:NodeCreatePhysicsFromAssets(o.root_node)


    -- Get wheels position
    o.local_rays = {}
    for _, wheel in pairs(o.wheels) do
        table.insert(o.local_rays, wheel:GetTransform():GetPos())
    end
   
    return o
end

function CarModelReset(car_model, scene_physics)
    scene_physics:NodeResetWorld(car_model.root_node, hg.TransformationMat4(car_model.start_position, car_model.start_rotation))
end

function CarModelIncreaseSteering(car_model, angle)
    car_model.steering_angle = math.max(math.min(car_model.steering_angle + angle, car_model.steering_angle_max), -car_model.steering_angle_max)
    car_model.thrust_transform:SetRot(hg.Deg3(0, car_model.steering_angle, 0))
end

function CarModelApplyAcceleration(car_model, value, scene_physics)
    f = 0
    for i = 1, 2 do
        if car_model.ground_hits[i] then
            f = f + 0.5
        end
    end
    pos = hg.GetT(car_model.thrust_transform:GetWorld())
    dir = hg.GetZ(car_model.thrust_transform:GetWorld())
    scene_physics:NodeAddImpulse(car_model.root_node, dir *  f * value * (1/60), pos)
end

function CarModelApplyBrake(car_model, value, scene_physics)
    f = 0
    for i = 1, 4 do
        if car_model.ground_hits[i] then
            f = f + 0.25
        end
    end
    v = scene_physics:NodeGetLinearVelocity(car_model.root_node)
    value = value * math.min(hg.Len(v), 1)
    pos = hg.GetT(car_model.thrust_transform:GetWorld())
    scene_physics:NodeAddImpulse(car_model.root_node,hg.Normalize(v) * (1 / 60) * f * -value, pos)
end

function CarModelUpdate(car_model, scene, scene_physics, dt, lines, visual_debug_physics)
    local dts = hg.time_to_sec_f(dt)

    scene_physics:NodeWake(car_model.root_node)
    car_model.ray_dir = hg.Reverse(hg.GetY(car_model.root_node:GetTransform():GetWorld()))
    for i = 1, 4 do
        CarModelUpdateWheel(car_model, scene, scene_physics, i, dt)
    end

    local car_world = car_model.root_node:GetTransform():GetWorld()
    -- local car_pos = hg.GetTranslation(car_world)
    -- car_pos = hg.Vec3(car_pos.x, car_pos.y, car_pos.z)
    -- car_pos = car_pos + car_model.center_of_mass

    if visual_debug_physics then
        local car_pos = car_world * car_model.center_of_mass
        local _s = 2.0
        table.insert(lines, {pos_a = car_pos + hg.GetX(car_world) * _s, pos_b = car_pos - hg.GetX(car_world) * _s, color = hg.Color.Red})
        table.insert(lines, {pos_a = car_pos + hg.GetY(car_world) * _s, pos_b = car_pos - hg.GetY(car_world) * _s, color = hg.Color.Green})
        table.insert(lines, {pos_a = car_pos + hg.GetZ(car_world) * _s, pos_b = car_pos - hg.GetZ(car_world) * _s, color = hg.Color.Blue})
    end

    return lines
end

function CarModelUpdateWheel(car_model, scene, scene_physics, id, dt)
    local dts = hg.time_to_sec_f(dt)

    wheel = car_model.wheels[id]
    mat = car_model.root_node:GetTransform():GetWorld()  -- Ray position in World space
    ray_pos = mat * car_model.local_rays[id]

    hit = scene_physics:RaycastFirstHit(scene,ray_pos, car_model.ray_dir * car_model.ray_max_dist + ray_pos)
    car_model.ground_hits[id] = false
    
    if hit.t > 0 and hit.t < car_model.ray_max_dist then
        car_model.ground_impacts[id] = hit
        hit_distance = hg.Len(car_model.ground_impacts[id].P - ray_pos)
        if hit_distance <= car_model.ray_max_dist then
            car_model.ground_hits[id] = true
        end
    end

    if car_model.ground_hits[id] then
        
        v = hg.Reverse(scene_physics:NodeGetPointVelocity(car_model.root_node, ray_pos))

        -- Spring bounce

        v_dot_ground_n = hg.Dot(car_model.ground_impacts[id].N, v)
        if v_dot_ground_n > 0 then
            v_bounce = car_model.ground_impacts[id].N * v_dot_ground_n
            scene_physics:NodeAddImpulse(car_model.root_node,v_bounce * car_model.spring_friction * dts, ray_pos)
        end

        -- Tire/Ground reaction
        wheel_reaction = math.sqrt(car_model.ray_max_dist - hit_distance) * car_model.tires_reaction
        scene_physics:NodeAddForce(car_model.root_node, car_model.ground_impacts[id].N * wheel_reaction * car_model.mass / 4, ray_pos)

        -- Wheel lateral friction
        x_axis = hg.GetX(wheel:GetTransform():GetWorld())
        proj = hg.Dot(x_axis, v)
        v_lat = x_axis * proj
        scene_physics:NodeAddImpulse(car_model.root_node, v_lat * car_model.tires_adhesion * dts, ray_pos)

        -- Adjust wheel on the ground
        wheel_p = wheel:GetTransform():GetPos()
        wheel_p.y = car_model.local_rays[id].y - hit_distance + car_model.wheels_ray
        wheel:GetTransform():SetPos(wheel_p)

        -- Wheel rotation
        z_axis = hg.Normalize(hg.Cross(x_axis, car_model.ray_dir))
        vlin = hg.Dot(z_axis, v)  -- Linear speed (along Z axis)
        car_model.wheels_rot_speed[id] = (vlin / car_model.wheels_ray)
    else
        car_model.wheels_rot_speed[id] = car_model.wheels_rot_speed[id] * 0.95  -- Wheel slow-down
    end

    rot = wheel:GetTransform():GetRot()
    rot.x = rot.x + car_model.wheels_rot_speed[id] * dts
    if id == 1 or id == 2 then
        rot.y = hg.Deg(car_model.steering_angle)
    end
    wheel:GetTransform():SetRot(rot)
end

function CarModelGetRootNode(car_model)
    return car_model.root_node
end

function CarModelControlKeyboard(car_model, scene_physics, kb, dt)
    local dts = hg.time_to_sec_f(dt)

    if kb:Down(hg.K_Up) then
        CarModelApplyAcceleration(car_model,  car_model.thrust_power * dts, scene_physics)
    end
    if kb:Down(hg.K_Down) then
        CarModelApplyAcceleration(car_model, -car_model.thrust_power * dts, scene_physics)
    end
    if kb:Down(hg.K_Space) then
        CarModelApplyBrake(car_model, car_model.brakes_power * dts, scene_physics)
    end
    if kb:Down(hg.K_Left) then
        CarModelIncreaseSteering(car_model, -car_model.steering_speed * dts)
    end
    if kb:Down(hg.K_Right) then
        CarModelIncreaseSteering(car_model, car_model.steering_speed * dts)
    end
    if kb:Pressed(hg.K_Backspace) then
        CarModelReset(car_model, scene_physics)
    end
end