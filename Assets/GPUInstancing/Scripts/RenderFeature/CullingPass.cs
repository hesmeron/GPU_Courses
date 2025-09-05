using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class CullingPass : ScriptableRenderPass
{
    private class PassData
    {
        //here will go all the data 
    }
    
    static void ExecutePass(PassData data, ComputeGraphContext context)
    {
        //here will be all the culling logic
    }
    
    //We record render graph as we would in any other render feature
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        const string passName = "Culling Pass";
            
        using (var builder = renderGraph.AddComputePass<PassData>(passName, out var passData))
        {
            builder.SetRenderFunc((PassData data, ComputeGraphContext context) => ExecutePass(data, context));
        }
    }
}