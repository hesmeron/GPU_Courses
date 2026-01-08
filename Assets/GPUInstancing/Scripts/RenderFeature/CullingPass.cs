using UnityEngine;
using UnityEngine.Assertions;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class CullingPass : ScriptableRenderPass
{
    private static readonly int InMatrices = Shader.PropertyToID("IN_Matrices");
    private static readonly int InFrustumPlanes = Shader.PropertyToID("IN_FrustumPlanes");
    private static readonly int OutCulledMatrices = Shader.PropertyToID("OUT_CulledMatrices");
    private static readonly int InRadius = Shader.PropertyToID("IN_Radius");
    
    
    private ComputeShader _cullingShader;
    private static ComputeBuffer planesBuffer;
    private Mesh _mesh;

    public CullingPass(ComputeShader cullingShader, Mesh mesh)
    {
        _mesh = mesh;
        _cullingShader = cullingShader;
        if (planesBuffer == null)
        {
            planesBuffer = new ComputeBuffer(6, sizeof(float) * 4);
        }

    }
    
    private class PassData
    {
        //Input buffer handle  that contains all the matrices to be culled
        public BufferHandle InputBufferHandle;
        public BufferHandle OutputBufferHandle;
        public BufferHandle IndirectArgsBufferHandle;
        public Mesh Mesh;
        public ComputeShader Shader;
    }
    
    static void ExecutePass(PassData data, ComputeGraphContext context)
    {   

        int width = 100;
        int height = 100;
        Matrix4x4[] zedroMatices = new Matrix4x4[width*height];

        for (int x = 0; x < width; x++)
        {
            for (int z = 0; z < height; z++)
            {
                //We simply fill out this array with evenly spaced soldiers
                Matrix4x4 matrix = Matrix4x4.zero;
                zedroMatices[x * height + z] = matrix;
            }
        }
        
        context.cmd.SetBufferData(data.OutputBufferHandle, zedroMatices);
        context.cmd.SetBufferCounterValue(data.OutputBufferHandle, 0);
        Debug.Log("Execute culling pass");
        ComputeShader shader = data.Shader;
        int kernel = shader.FindKernel("CSMain");
        

        Matrix4x4[] matrices = new Matrix4x4[width*height];

        for (int x = 0; x < width; x++)
        {
            for (int z = 0; z < height; z++)
            {
                //We simply fill out this array with evenly spaced soldiers
                Matrix4x4 matrix = Matrix4x4.TRS(new Vector3(x * 1.2f, 0, z * 1.5f), Quaternion.identity,
                    Vector3.one);
                matrices[x * height + z] = matrix;
            }
        }
        context.cmd.SetBufferData(data.InputBufferHandle, matrices);
        Plane[] frustumPlanes = GeometryUtility.CalculateFrustumPlanes(Camera.main);
        Vector4[] planeVectors = new Vector4[6];
        for (int i = 0; i < 6; i++)
        {
            Plane p = frustumPlanes[i];
            planeVectors[i] = new Vector4(p.normal.x, p.normal.y, p.normal.z, p.distance);
        }
        planesBuffer.SetData(planeVectors);
        //context.cmd.SetBufferCounterValue(data.OutputBufferHandle, 0);
        shader.SetBuffer(kernel, InFrustumPlanes, planesBuffer);
        shader.SetBuffer(kernel, InMatrices, data.InputBufferHandle);
        shader.SetBuffer(kernel, OutCulledMatrices, data.OutputBufferHandle);
        shader.SetFloat(InRadius, 3);
        context.cmd.DispatchCompute(shader, 0, 10000, 1, 1);
        context.cmd.CopyCounterValue(data.OutputBufferHandle, data.IndirectArgsBufferHandle,sizeof(uint));
    }
    
    //We record render graph as we would in any other render feature
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        const string passName = "Culling Pass";
        //We get our input buffer from the static class and import it to get a buffer handle
        //so that we can use it within the pass

        var desc  =new BufferDesc(10000, sizeof(float) * 16, GraphicsBuffer.Target.Structured);
        BufferHandle inputBufferHandle = renderGraph.CreateBuffer(desc);
        BufferHandle outputBufferHandle = renderGraph.CreateBuffer(new BufferDesc(10000, 
            sizeof(float) * 16,
            GraphicsBuffer.Target.Structured
            | GraphicsBuffer.Target.Append ));


        BufferHandle indirectArgsHandle = renderGraph.CreateBuffer(new BufferDesc(1, 5 * sizeof(uint), GraphicsBuffer.Target.IndirectArguments));//renderGraph.ImportBuffer(InstancedDrawSystem.GetArgsBuffer(_mesh));
        
        //We get or create an instance of this ContextItem class
        CullingFrameData cullingFrameData = frameData.GetOrCreate<CullingFrameData>();
        //We fill in the reference for CulledMatricesBuffer
        cullingFrameData.CulledMatricesBuffer = outputBufferHandle;
        cullingFrameData.ArgsBuffer = indirectArgsHandle;
        
        using (var builder = renderGraph.AddComputePass<PassData>(passName, out var passData))
        {
            //We fill in PassData with this buffer hande
            passData.Shader = _cullingShader;
            passData.Mesh = _mesh;
            passData.InputBufferHandle = inputBufferHandle;
            passData.OutputBufferHandle = outputBufferHandle;
            passData.IndirectArgsBufferHandle = indirectArgsHandle;
            //We have to declare that we will be using this buffer so it is accessible in this pass
            //We only need read permissions as we will be not modifying this buffer.
            builder.UseBuffer(passData.InputBufferHandle, AccessFlags.Read);
            builder.UseBuffer(passData.OutputBufferHandle, AccessFlags.Write);
            builder.UseBuffer(passData.IndirectArgsBufferHandle, AccessFlags.Write);
            builder.SetRenderFunc((PassData data, ComputeGraphContext context) => ExecutePass(data, context));
        }
    }
}