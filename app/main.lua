-- HARFANG® 3D - Car driving simulator prototype

hg = require("harfang")
require("car")
require("car_camera")
require("visual_debug")
require("utils")

function main(visual_debug_physics, visual_debug_car_physics)

    -- default values
    visual_debug_physics = visual_debug_physics or false
    visual_debug_car_physics = visual_debug_car_physics or false

    local debug_res_x, debug_res_y = 256, 128

    -- HARFANG3D inits
    hg.InputInit()
    hg.WindowSystemInit()

    local res_x, res_y = ResolutionMultiplier(1280, 720, 0.75)
    local win = hg.RenderInit('Raycast car', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

    pipeline = hg.CreateForwardPipeline()
    local res = hg.PipelineResources()

    hg.AddAssetsFolder("assets")

    -- imgui
    local imgui_prg = hg.LoadProgramFromAssets('core/shader/imgui')
    local imgui_img_prg = hg.LoadProgramFromAssets('core/shader/imgui_image')

    hg.ImGuiInit(10, imgui_prg, imgui_img_prg)

    -- Display physics debug lines
    local vtx_line_layout = hg.VertexLayoutPosFloatColorUInt8()
    local lines_program = hg.LoadProgramFromAssets("shaders/pos_rgb")

    -- Load scene
    local scene = hg.Scene()
    hg.LoadSceneFromAssets("main.scn", scene, res, hg.GetForwardPipelineInfo())
    local default_camera = scene:GetNode("Camera")

    -- Ground
    local vs_decl= hg.VertexLayoutPosFloatNormUInt8()
    local cube_mdl = hg.CreateCubeModel(vs_decl, 10, 10, 10)
    local cube_ref = res:AddModel('cube', cube_mdl)
    local ground_mdl = hg.CreateCubeModel(vs_decl, 100, 0.01, 100)
    local ground_ref = res:AddModel('ground', ground_mdl)
    local prg_ref = hg.LoadPipelineProgramRefFromAssets('core/shader/pbr.hps', res, hg.GetForwardPipelineInfo())

    local mat_ground = CreateMaterialFromProgram(prg_ref, hg.Vec4(0.25, 0.25, 0.25, 1),hg.Vec4(1, 1, 0, 1))

    local cube_node = hg.CreatePhysicCube(scene, hg.Vec3(10,10,10), hg.TransformationMat4(hg.Vec3(0, -2.5, -10),hg.Deg3(30, 0, 10)), cube_ref, {mat_ground}, 0)
    local ground_node = hg.CreatePhysicCube(scene, hg.Vec3(100, 0.01, 100), hg.TranslationMat4(hg.Vec3(0, -0.005, 0)), ground_ref, {mat_ground}, 0)

    cube_node:GetRigidBody():SetType(hg.RBT_Kinematic)
    ground_node:GetRigidBody():SetType(hg.RBT_Kinematic)

    -- Scene physics
    local clocks = hg.SceneClocks()
    local physics = hg.SceneBullet3Physics()
    local car = CarModelCreate("Generic Car", "car", scene, physics, res, hg.Vec3(0, 1.5, 0))
    physics:SceneCreatePhysicsFromAssets(scene)

    -- Car camera
    local car_camera = CarCameraCreate("car", scene)

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
        local view_id = 0, passId
        local lines = {} -- list of debugging draw primitives
        local car_velocity

        -- ImGui
        hg.ImGuiBeginFrame(res_x, res_y, dt, hg.ReadMouse(), hg.ReadKeyboard())

        visual_debug_physics, visual_debug_car_physics = 
            DisplayDebugUI(debug_res_x, debug_res_y, dt, visual_debug_physics, visual_debug_car_physics, car.mass)

        -- Car updates
        CarModelControlKeyboard(car, physics, keyboard, dt)
        lines, car_velocity = CarModelUpdate(car, scene, physics, dt, lines, visual_debug_car_physics)
        local current_camera_node = CarCameraUpdate(car_camera, scene, keyboard, dt, car_velocity)
        if current_camera_node == nil then
            scene:SetCurrentCamera(default_camera)
            current_camera_node = default_camera
        end

        -- Scene updates
        hg.SceneUpdateSystems(scene, clocks, dt, physics, hg.time_from_sec_f(1.0/60.0), 4)
        view_id, passId = hg.SubmitSceneToPipeline(view_id, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)

            -- debug draw lines
        local opaque_view_id = hg.GetSceneForwardPipelinePassViewId(passId, hg.SFPP_Opaque)
        for i=1, #lines do
            draw_line(lines[i].pos_a, lines[i].pos_b, lines[i].color, opaque_view_id, vtx_line_layout, lines_program)
        end

        -- Debug physics
        if visual_debug_physics then
            hg.SetViewClear(view_id, 0, 0, 1.0, 0)
            hg.SetViewRect(view_id, 0, 0, res_x, res_y)
            local cam_mat = current_camera_node:GetTransform():GetWorld()
            local view_matrix = hg.InverseFast(cam_mat)
            c = current_camera_node:GetCamera()
            local projection_matrix = hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1))
            hg.SetViewTransform(view_id, view_matrix, projection_matrix)
            local rs = hg.ComputeRenderState(hg.BM_Opaque, hg.DT_Disabled, hg.FC_Disabled)
            physics:RenderCollision(view_id, vtx_line_layout, lines_program, rs, 0)
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
