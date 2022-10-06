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

    o.camera_interior = wheel = o.scene_view:GetNode(scene, "camera_interior")
    o.camera_exterior_rear = wheel = o.scene_view:GetNode(scene, "camera_exterior_rear")
end