-- car camera

function CarLightsCreate(instance_node_name, scene)
    local o = {}
    o.instance_node = scene:GetNode(instance_node_name)
    if not o.instance_node:IsValid() then
        print("!CarLightsCreate(): Instance node '" .. instance_node_name .. "' not found!")
        return
    end

    -- carlights
    -- carlight_reverse, carlight_head_light, carlight_day_light, carlight_brake, carlight_backLight, carlight_turn_left, carlight_turn_right

    local scene_view = o.instance_node:GetInstanceSceneView()
    local root_node = scene_view:GetNode(scene, "carlights")
    if not root_node:IsValid() then
        print("!CarLightsCreate(): Carlights node not found !")
        return
    end

    o.car_view = root_node:GetInstanceSceneView()
    o.carlight_list = {}
    for _, carlight_name in ipairs({"reverse", "head_light", "day_light", "brake", "backLight", "turn_left", "turn_right"}) do
        local _n = o.car_view:GetNode(scene, "carlight_" .. carlight_name)
        o.carlight_list["carlight_" .. carlight_name] = {node = _n, enabled = false}
        _n:Disable()
    end
    return o
end

function CarLightsSetBrake(o, state)
    o.carlight_list.carlight_brake.enabled = state
end

function CarLightsSetReverse(o, state)
    o.carlight_list.carlight_reverse.enabled = state
end

function CarLightsUpdate(o, scene, dt)
    --
    for carlight_name in pairs(o.carlight_list) do
        if o.carlight_list[carlight_name].enabled then
            o.carlight_list[carlight_name].node:Enable()
        else
            o.carlight_list[carlight_name].node:Disable()
        end
    end
end