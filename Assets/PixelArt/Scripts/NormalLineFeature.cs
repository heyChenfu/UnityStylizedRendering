using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class NormalLineFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class NormalLineFeatureSetting 
    { 
        public LayerMask layer;
        public Material normalTexMat;
        public Material normalLineMat;
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingPrePasses;
        [Range(0, 1)]
        public float Edge = 0;
    }

    public NormalLineFeatureSetting setting = new NormalLineFeatureSetting();

    public class DrawNormalTexPass : ScriptableRenderPass
    {

        private NormalLineFeatureSetting _setting;
        NormalLineFeature _feature;
        ShaderTagId _shaderTag = new ShaderTagId("DepthOnly");
        FilteringSettings _filer;

        public DrawNormalTexPass(NormalLineFeatureSetting setting, NormalLineFeature feature)
        {
            _setting = setting;
            _feature = feature;

            RenderQueueRange queue = new RenderQueueRange();
            queue.lowerBound = 1000;
            queue.upperBound = 3500;
            _filer = new FilteringSettings(queue, _setting.layer);

        }

        // called each frame before Execute, use it to set up things the pass will need
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);

            int temp = Shader.PropertyToID("_NormalTex");
            //申请了一个临时rt，同时将该rt与第一个参数"nameID"所代表的全局的ShaderProperty进行了绑定
            cmd.GetTemporaryRT(temp, cameraTextureDescriptor);
            //设置渲染目标
            ConfigureTarget(temp);
            ConfigureClear(ClearFlag.All, Color.black);

        }

        // Execute is called for every eligible camera every frame. It's not called at the moment that
        // rendering is actually taking place, so don't directly execute rendering commands here.
        // Instead use the methods on ScriptableRenderContext to set up instructions.
        // RenderingData provides a bunch of (not very well documented) information about the scene
        // and what's being rendered.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //CommandBuffer cmd = CommandBufferPool.Get("绘制NormalTex");
            DrawingSettings draw = CreateDrawingSettings(_shaderTag, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
            draw.overrideMaterial = _setting.normalTexMat;
            draw.overrideMaterialPassIndex = 0;
            context.DrawRenderers(renderingData.cullResults, ref draw, ref _filer);
            //CommandBufferPool.Release(cmd);
        }
    }

    public class DrawNormalLinePass : ScriptableRenderPass
    {
        private NormalLineFeatureSetting _setting;
        NormalLineFeature _feature;

        public DrawNormalLinePass(NormalLineFeatureSetting setting, NormalLineFeature feature)
        {
            _setting = setting;
            _feature = feature;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("绘制法线描边");
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            _setting.normalLineMat.SetFloat("_Edge", _setting.Edge);
            int normalLineID = Shader.PropertyToID("_NormalLineTex");
            cmd.GetTemporaryRT(normalLineID, desc);
            cmd.Blit(normalLineID, normalLineID, _setting.normalLineMat, 0);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(Shader.PropertyToID("_NormalLineTex"));
            cmd.ReleaseTemporaryRT(Shader.PropertyToID("_NormalTex"));
        }

    }

    private DrawNormalTexPass _drawNormalTexPass;
    private DrawNormalLinePass _drawNormalLinePass;

    /// <inheritdoc/>
    public override void Create()
    {
        _drawNormalTexPass = new DrawNormalTexPass(setting, this);
        _drawNormalTexPass.renderPassEvent = setting.passEvent;
        _drawNormalLinePass = new DrawNormalLinePass(setting, this);
        _drawNormalLinePass.renderPassEvent = setting.passEvent;

    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_drawNormalTexPass);
        renderer.EnqueuePass(_drawNormalLinePass);
    }
}


