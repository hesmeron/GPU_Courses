using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class CullingPass : ScriptableRenderPass
{
    private class PassData
    {
        //Input buffer handle  that contains all the matrices to be culled
        public BufferHandle InputBufferHandle;
    }
    
    static void ExecutePass(PassData data, ComputeGraphContext context)
    {
        //here will be all the culling logic
    }
    
    //We record render graph as we would in any other render feature
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        const string passName = "Culling Pass";
        //We get our input buffer from the static class and import it to get a buffer handle
        //so that we can use it within the pass
        BufferHandle inputBufferHandle = renderGraph.ImportBuffer(InstancedDrawSystem.GetInputBuffer());

            
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