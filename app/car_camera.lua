-- car camera

-- hg = require("harfang")
-- require("utils")

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
    table.insert(o.camera_list, o.scene_view:GetNode(scene, "camera_interior"))
    table.insert(o.camera_list, o.scene_view:GetNode(scene, "camera_exterior_rear"))

    o.current_camera = 0

    return o
end

function CarCameraUpdate(o, scene, kb, dt)
    -- if car_camera.current_camera then
    --     scene:SetCurrentCamera(car_camera.current_camera)
    -- end

    if kb:Pressed(hg.K_C) then
        o.current_camera = o.current_camera + 1
        if o.current_camera > #o.camera_list then
            o.current_camera = 0
        end

        if o.current_camera > 0 then
            scene:SetCurrentCamera(o.camera_list[o.current_camera])
        end
    end

    if o.current_camera then
        return o.camera_list[o.current_camera]
    else
        return nil
    end
end