using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class CullingPass : ScriptableRenderPass
{
    private static readonly int InMatrices = Shader.PropertyToID("IN_Matrices");
    private static readonly int OutCulledMatrices = Shader.PropertyToID("OUT_CulledMatrices");
    
    private ComputeShader _cullingShader;

    public CullingPass(ComputeShader cullingShader)
    {
        _cullingShader = cullingShader;
    }
    
    private class PassData
    {
        //Input buffer handle  that contains all the matrices to be culled
        public BufferHandle InputBufferHandle;
        public BufferHandle OutputBufferHandle;
        public ComputeShader Shader;
    }
    
    static void ExecutePass(PassData data, ComputeGraphContext context)
    {
        Debug.Log("Execute culling pass");
        ComputeShader shader = data.Shader;
        int kernel = shader.FindKernel("CSMain");
        shader.SetBuffer(kernel, InMatrices, data.InputBufferHandle);
        shader.SetBuffer(kernel, OutCulledMatrices, data.OutputBufferHandle);
        context.cmd.DispatchCompute(shader, 0, 10000, 1, 1);
    }
    
    //We record render graph as we would in any other render feature
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        const string passName = "Culling Pass";
        //We get our input buffer from the static class and import it to get a buffer handle
        //so that we can use it within the pass
        BufferHandle inputBufferHandle = renderGraph.ImportBuffer(InstancedDrawSystem.GetInputBuffer());
        
        //We get or create an instance of this ContextItem class
        CullingFrameData cullingFrameData = frameData.GetOrCreate<CullingFrameData>();
        //We fill in the reference for CuledMatricesBuffer
        cullingFrameData.CulledMatricesBuffer = inputBufferHandle;    
        
        using (var builder = renderGraph.AddComputePass<PassData>(passName, out var passData))
        {
            //We fill in PassData with this buffer hande
            passData.InputBufferHandle = inputBufferHandle;
            //We have to declare that we will be using this buffer so it is accessible in this pass
            //We only need read permissions as we will be not modifying this buffer.
            builder.UseBuffer(passData.InputBufferHandle, AccessFlags.Read);
            builder.SetRenderFunc((PassData data, ComputeGraphContext context) => ExecutePass(data, context));
        }
    }
}