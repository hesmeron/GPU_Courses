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
    private static GraphicsBuffer _counterCopyBuffer;

    public InstancedDrawPass(Material material, Mesh mesh)
    {
        if (_counterCopyBuffer == null)
        {
            _counterCopyBuffer= new GraphicsBuffer(GraphicsBuffer.Target.Raw, 1, sizeof(uint));
        }
        _material = material;
        _mesh = mesh;
    }

    private class PassData
    {
        public BufferHandle culledMatricesBuffer;
        public Material material;
        public Mesh mesh;
    }
    
    static void ExecutePass(PassData data, RasterGraphContext context)
    {
        int shaderPass = data.material.FindPass("Unlit");
        MaterialPropertyBlock block = context.renderGraphPool.GetTempMaterialPropertyBlock();
        block.SetBuffer(TransformationMatrices, data.culledMatricesBuffer);
        
        GraphicsBuffer.CopyCount(data.culledMatricesBuffer, _counterCopyBuffer, 0);
        uint[] counterValueArray = new uint[1];
        _counterCopyBuffer.GetData(counterValueArray);
//        Debug.Log("Buffer counter " + counterValueArray[0]);
        int counterValue = (int) counterValueArray[0];
        if (counterValue > 0)
        {
            context.cmd.DrawMeshInstancedProcedural(data.mesh, //a mesh to draw that we get form the inspector
                0, //relevant when the mesh has multiple submeshes, we just set it to 0
                data.material, //a material to draw that we get form the inspector
                shaderPass, //As ina previously used function we set the pass that will be used in rendering
                counterValue, //for know we assume all matrices are present here. We will replace this later down the line
                block); //here, all the material properties are set
        }
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
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
            
            builder.UseBuffer(passData.culledMatricesBuffer, AccessFlags.Read);
            builder.SetRenderAttachment(resourceData.activeColorTexture, 0);
            builder.SetRenderAttachmentDepth(resourceData.activeDepthTexture);
            builder.SetRenderFunc((PassData data, RasterGraphContext context) => ExecutePass(data, context));
        }
    }
}