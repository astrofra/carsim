-- HARFANG® 3D - www.harfang3d.com - Raycast Car demo sample

hg = require("harfang")
require("car")

function main(visual_debug_physics)

    -- HARFANG3D inits
    hg.InputInit()
    hg.WindowSystemInit()

    local res_x, res_y = 1280, 720
    local win = hg.RenderInit('Raycast car', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

    pipeline = hg.CreateForwardPipeline()
    local res = hg.PipelineResources()

    hg.AddAssetsFolder("assets")

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
        local vid, passId

        -- Car updates
        CarModelControlKeyboard(car, physics, keyboard, dt)
        CarModelUpdate(car, scene, physics, dt)

        -- Scene updates
        hg.SceneUpdateSystems(scene, clocks, dt, physics, hg.time_from_sec_f(1/60), 3)
        vid, passId = hg.SubmitSceneToPipeline(0, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)

        -- Debug physics
        if visual_debug_physics then
            hg.SetViewClear(vid, 0, 0, 1.0, 0)
            hg.SetViewRect(vid, 0, 0, res_x, res_y)
            local cam_mat = cam:GetTransform():GetWorld()
            local view_matrix = hg.InverseFast(cam_mat)
            c = cam:GetCamera()
            local projection_matrix = hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1))
            hg.SetViewTransform(vid, view_matrix, projection_matrix)
            local rs = hg.ComputeRenderState(hg.BM_Opaque, hg.DT_Disabled, hg.FC_Disabled)
            physics:RenderCollision(vid, vtx_lines, lines_program, rs, 0)
        end

        -- EoF

        hg.Frame()
        hg.UpdateWindow(win)    

    end

    hg.RenderShutdown()
    hg.DestroyWindow(win)
end

main()
