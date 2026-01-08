using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;

public class InstancedDrawFeature : ScriptableRendererFeature
{
    [SerializeField]
    private ComputeShader computeShader;
    [SerializeField] 
    private Material material;
    [SerializeField]
    private Mesh mesh;
    
    
    InstancedDrawPass renderPass;
    private CullingPass cullingPass;
    private InstancedShadowPass shadowPass;

    /// <inheritdoc/>
    public override void Create()
    {
        cullingPass = new CullingPass(computeShader, mesh);
        cullingPass.renderPassEvent = RenderPassEvent.BeforeRendering;
        //shadowPass  = new InstancedShadowPass(material, mesh);
        renderPass = new InstancedDrawPass(material, mesh);
        renderPass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }
    
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(cullingPass); 
        //ShadowRenderer.Enqueue(shadowPass);
        renderer.EnqueuePass(renderPass);
    }
}
