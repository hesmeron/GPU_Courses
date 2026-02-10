using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

class InstancedDrawPass : ScriptableRenderPass
{
    private static readonly int TransformationMatrices = Shader.PropertyToID("_TransformationMatrices");
    private Material _material;
    private Mesh _mesh;

    public InstancedDrawPass(Material material, Mesh mesh)
    {

        _material = material;
        _mesh = mesh;
    }

    private class PassData
    {
        public BufferHandle culledMatricesBuffer;
        public BufferHandle argsBuffer;
        public Material material;
        public Mesh mesh;
    }
    
    static void ExecutePass(PassData data, RasterGraphContext context)
    {
        MaterialPropertyBlock block = context.renderGraphPool.GetTempMaterialPropertyBlock();
        block.SetBuffer(TransformationMatrices, data.culledMatricesBuffer);
        int shaderPass = data.material.FindPass("ForwardLitProcedural");
        
        context.cmd.DrawMeshInstancedIndirect(
            data.mesh,
            0,
            data.material,
            shaderPass,
            data.argsBuffer,
            0,
            block);
    }
    
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        const string passName = "Render Custom Pass";
        CullingFrameData cullingFrameData = frameData.GetOrCreate<CullingFrameData>();
            
        using (var builder = renderGraph.AddRasterRenderPass<PassData>(passName, out var passData))
        {
            passData.culledMatricesBuffer = cullingFrameData.CulledMatricesBuffer;
            passData.material = _material;
            passData.mesh = _mesh;
            passData.argsBuffer = cullingFrameData.ArgsBuffer;
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            
            builder.UseBuffer(passData.culledMatricesBuffer, AccessFlags.Read);
            builder.UseBuffer(passData.argsBuffer, AccessFlags.Read);
            //builder.UseTexture(resourceData.mainShadowsTexture, AccessFlags.ReadWrite);
            builder.SetRenderAttachment(resourceData.activeColorTexture, 0);
            builder.SetRenderAttachmentDepth(resourceData.activeDepthTexture);
            builder.SetRenderFunc((PassData data, RasterGraphContext context) => ExecutePass(data, context));
        }
    }
}