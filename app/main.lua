-- HARFANG® 3D - www.harfang3d.com - Raycast Car demo sample

hg = require("harfang")
require("car")
require("debug")
require("utils")

function main(visual_debug_physics)

    -- default values
    visual_debug_physics = visual_debug_physics or false

    local debug_res_x, debug_res_y = 256, 128

    -- HARFANG3D inits
    hg.InputInit()
    hg.WindowSystemInit()

    local res_x, res_y = 1280, 720
    local win = hg.RenderInit('Raycast car', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

    pipeline = hg.CreateForwardPipeline()
    local res = hg.PipelineResources()

    hg.AddAssetsFolder("assets")

    -- imgui
    local imgui_prg = hg.LoadProgramFromAssets('core/shader/imgui')
    local imgui_img_prg = hg.LoadProgramFromAssets('core/shader/imgui_image')

    hg.ImGuiInit(10, imgui_prg, imgui_img_prg)

    -- Display physics debug lines
    local vtx_lines = hg.VertexLayout()
    vtx_lines:Begin()
    vtx_lines:Add(hg.A_Position, 3, hg.AT_Float)
    vtx_lines:Add(hg.A_Color0, 3, hg.AT_Float)
    vtx_lines:End()
    local lines_program = hg.LoadProgramFromAssets("shaders/pos_rgb")

    -- Load scene
    local scene = hg.Scene()
    hg.LoadSceneFromAssets("main.scn", scene, res, hg.GetForwardPipelineInfo())
    local cam = scene:GetNode("Camera")

    -- Ground
    local vs_decl= hg.VertexLayoutPosFloatNormUInt8()
    local cube_mdl = hg.CreateCubeModel(vs_decl, 10, 10, 10)
    local cube_ref = res:AddModel('cube', cube_mdl)
    local ground_mdl = hg.CreateCubeModel(vs_decl, 100, 0.01, 100)
    local ground_ref = res:AddModel('ground', ground_mdl)
    local prg_ref = hg.LoadPipelineProgramRefFromAssets('core/shader/pbr.hps', res, hg.GetForwardPipelineInfo())

    local mat_ground = CreateMaterialFromProgram(prg_ref, hg.Vec4(22/255, 42/255, 42/255, 1),hg.Vec4(1, 1, 0, 1))

    local cube_node = hg.CreatePhysicCube(scene, hg.Vec3(10,10,10), hg.TransformationMat4(hg.Vec3(0, -2.5, -10),hg.Deg3(30, 0, 10)), cube_ref, {mat_ground}, 0)
    local ground_node = hg.CreatePhysicCube(scene, hg.Vec3(100, 0.01, 100), hg.TranslationMat4(hg.Vec3(0, -0.005, 0)), ground_ref, {mat_ground}, 0)

    cube_node:GetRigidBody():SetType(hg.RBT_Kinematic)
    ground_node:GetRigidBody():SetType(hg.RBT_Kinematic)

    -- Scene physics

    local clocks = hg.SceneClocks()
    local physics = hg.SceneBullet3Physics()
    local car = CarModelCreate("Generic Car", "car", scene, physics, res, hg.Vec3(0, 1.5, 0))
    physics:SceneCreatePhysicsFromAssets(scene)

    -- Inputs
    local keyboard = hg.Keyboard()
    local mouse = hg.Mouse()
    hg.ResetClock()

    -- Main loop
    while not keyboard:Pressed(hg.K_Escape) do

        keyboard:Update()
        mouse:Update()

        local dt = hg.TickClock()
        local dts = hg.time_to_sec_f(dt)
        local view_id, passId

        -- ImGui
        hg.ImGuiBeginFrame(res_x, res_y, dt, hg.ReadMouse(), hg.ReadKeyboard())

        hg.ImGuiBegin("Debug", true, hg.ImGuiWindowFlags_NoMove | hg.ImGuiWindowFlags_NoResize)
        hg.ImGuiSetWindowSize("Debug", hg.Vec2(debug_res_x, debug_res_y), hg.ImGuiCond_Once)
        hg.ImGuiText("dt = " .. tostring(TruncateFloat(dts, 4)))
        _, visual_debug_physics = hg.ImGuiCheckbox("Physics debug", visual_debug_physics)
        hg.ImGuiEnd()
        -- visual_debug_physics = DisplayDebugGUI(debug_res_x, debug_res_y, dt, visual_debug_physics)

        -- Car updates
        CarModelControlKeyboard(car, physics, keyboard, dt)
        CarModelUpdate(car, scene, physics, dt)

        -- Scene updates
        hg.SceneUpdateSystems(scene, clocks, dt, physics, dt, 4)
        view_id, passId = hg.SubmitSceneToPipeline(0, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)

        -- Debug physics
        if visual_debug_physics then
            hg.SetViewClear(view_id, 0, 0, 1.0, 0)
            hg.SetViewRect(view_id, 0, 0, res_x, res_y)
            local cam_mat = cam:GetTransform():GetWorld()
            local view_matrix = hg.InverseFast(cam_mat)
            c = cam:GetCamera()
            local projection_matrix = hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1))
            hg.SetViewTransform(view_id, view_matrix, projection_matrix)
            local rs = hg.ComputeRenderState(hg.BM_Opaque, hg.DT_Disabled, hg.FC_Disabled)
            physics:RenderCollision(view_id, vtx_lines, lines_program, rs, 0)
            view_id = view_id + 1
        end

        hg.ImGuiEndFrame(view_id)

        -- EoF

        hg.Frame()
        hg.UpdateWindow(win)    

    end

    hg.RenderShutdown()
    hg.DestroyWindow(win)
end

main()
