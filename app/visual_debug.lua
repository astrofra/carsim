-- Debug user interface

-- hg = require("harfang")

function DisplayDebugUI(debug_res_x, debug_res_y, dt, visual_debug_physics, visual_debug_car_physics, car_mass)
        local dts = hg.time_to_sec_f(dt)

        hg.ImGuiBegin("Debug", true, hg.ImGuiWindowFlags_NoMove | hg.ImGuiWindowFlags_NoResize)
        hg.ImGuiSetWindowSize("Debug", hg.Vec2(debug_res_x, debug_res_y), hg.ImGuiCond_Once)
        hg.ImGuiText("dt = " .. tostring(TruncateFloat(dts, 4)))
        hg.ImGuiText("car_mass = " .. tostring(car_mass) .. "Kg")
        _, visual_debug_physics = hg.ImGuiCheckbox("Col. debug", visual_debug_physics)
        _, visual_debug_car_physics = hg.ImGuiCheckbox("Car debug", visual_debug_car_physics)
        hg.ImGuiEnd()

        return visual_debug_physics, visual_debug_car_physics
end

function draw_line(pos_a, pos_b, line_color, vid, vtx_line_layout, line_shader)
	local vtx = hg.Vertices(vtx_line_layout, 2)
	vtx:Begin(0):SetPos(pos_a):SetColor0(line_color):End()
	vtx:Begin(1):SetPos(pos_b):SetColor0(line_color):End()
	hg.DrawLines(vid, vtx, line_shader)
end