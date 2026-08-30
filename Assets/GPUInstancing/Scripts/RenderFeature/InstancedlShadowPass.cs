using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class  InstancedShadowPass : ScriptableRenderPass, IShadowPass
{
    private Mesh _mesh;
    private Material _material;
    private GraphicsBuffer _matrices;
    private GraphicsBuffer _argsBuffer;
    public static BufferHandle CulledMatricesBuffer = BufferHandle.nullHandle;
    public static  BufferHandle ArgsBuffer = BufferHandle.nullHandle;
    private static readonly int TransformationMatrices = Shader.PropertyToID("_TransformationMatrices");

    public InstancedShadowPass(Material material, Mesh mesh)
    {
        _mesh = mesh;
        _material = material;
        renderPassEvent = RenderPassEvent.BeforeRenderingShadows;
    }
    
    private class PassData
    {
        public BufferHandle culledMatricesBuffer;
        public BufferHandle argsBuffer;
    }
    
    static void ExecutePass(PassData data, RasterGraphContext context)
    {
        CulledMatricesBuffer = data.culledMatricesBuffer;
        ArgsBuffer = data.argsBuffer;
    }
    
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        const string passName = "Render Shadow Pass";
        CullingFrameData cullingFrameData = frameData.GetOrCreate<CullingFrameData>();
            
        using (var builder = renderGraph.AddRasterRenderPass<PassData>(passName, out var passData))
        {
            passData.culledMatricesBuffer = cullingFrameData.CulledMatricesBuffer;
            passData.argsBuffer = cullingFrameData.ArgsBuffer;
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            
            builder.UseBuffer(passData.culledMatricesBuffer, AccessFlags.Read);
            builder.UseBuffer(passData.argsBuffer, AccessFlags.Read);
            //we have to set render attachment even though we will have no use for it
            builder.SetRenderAttachment(resourceData.activeColorTexture, 0);
            builder.SetRenderFunc((PassData data, RasterGraphContext context) => ExecutePass(data, context));
        }
    }
    public void ExecuteShadowPass(RasterCommandBuffer cmd, ref ShadowSliceData slice)
    {
        var block = new MaterialPropertyBlock();
        block.SetBuffer(TransformationMatrices, CulledMatricesBuffer);
        
        int shadowPass = _material.FindPass("ShadowCaster");
        if (shadowPass >= 0)
        {
            cmd.DrawMeshInstancedIndirect(
                _mesh,
                0,
                _material,
                shadowPass,
                ArgsBuffer,
                0,
                block);


        }
    }
}