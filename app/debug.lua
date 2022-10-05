hg = require("harfang")

function DisplayDebugGUI(debug_res_x, debug_res_y, dt, visual_debug_physics)
        local dts = hg.time_to_sec_f(dt)

        hg.ImGuiBegin("Debug", true, hg.ImGuiWindowFlags_NoMove | hg.ImGuiWindowFlags_NoResize)
        hg.ImGuiSetWindowSize("Debug", hg.Vec2(debug_res_x, debug_res_y), hg.ImGuiCond_Once)
        hg.ImGuiText("dt = " .. tostring(TruncateFloat(dts, 4)))
        _, visual_debug_physics = hg.ImGuiCheckbox("Physics debug", visual_debug_physics)
        hg.ImGuiEnd()

        return visual_debug_physics
end