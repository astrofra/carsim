-- car camera

function CarCameraCreate(instance_node_name, scene)
    local o = {}
    o.instance_node = scene:GetNode(instance_node_name)
    if not o.instance_node:IsValid() then
        print("!CarCameraCreate(): Instance node '" .. instance_node_name .. "' not found!")
        return
    end

    o.scene_view = o.instance_node:GetInstanceSceneView()
    o.nodes = o.scene_view:GetNodes(scene)
    o.root_node = o.scene_view:GetNode(scene, "car_body")
    if not o.root_node:IsValid() then
        print("!CarCameraCreate(): Parent node not found !")
        return
    end

    o.camera_list = {}
    for _, camera_name in ipairs({"camera_interior", "camera_exterior_rear"}) do
        local _n = o.scene_view:GetNode(scene, camera_name)
        local _f = hg.Normalize(hg.GetZ(_n:GetTransform():GetWorld()))
        local _p = _n:GetTransform():GetPos()
        table.insert(o.camera_list, {node = _n, trs = _n:GetTransform(), vec_front = _f, pos = _p})
    end

    o.current_camera = 0

    return o
end

function CarCameraUpdate(o, scene, kb, dt, car_velocity)
    -- if car_camera.current_camera then
    --     scene:SetCurrentCamera(car_camera.current_camera)
    -- end

    if kb:Pressed(hg.K_C) then
        o.current_camera = o.current_camera + 1
        if o.current_camera > #o.camera_list then
            o.current_camera = 0
        end

        if o.current_camera > 0 then
            scene:SetCurrentCamera(o.camera_list[o.current_camera].node)
        end
    end

    if o.current_camera > 0 then -- if one of the car's camera
        -- simulate head inertia
        local _p = o.camera_list[o.current_camera].pos
        local _f = Clamp(Map(hg.Len(car_velocity), -20.0, 20.0, 0.0, 1.0), 0.0, 1.0)
        _f = EaseInOutQuick(_f)
        _f = Map(_f, 0.0, 1.0, -0.1, 0.1)
        _p = _p + o.camera_list[o.current_camera].vec_front * _f
        o.camera_list[o.current_camera].trs:SetPos(_p)

        -- return current camera node
        return o.camera_list[o.current_camera].node
    else
        return nil
    end
end