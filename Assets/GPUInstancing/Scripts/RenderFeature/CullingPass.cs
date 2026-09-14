using System.Collections.Generic;
using Unity.VisualScripting;
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
    private List<MassRenderer> _massRenderers;
    private static ComputeBuffer planesBuffer;
    private static Mesh _mesh;


    public CullingPass(ComputeShader cullingShader, Mesh mesh, List<MassRenderer> massRenderers)
    {
        _massRenderers = massRenderers;
        _cullingShader = cullingShader;
        _mesh = mesh;
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
        public ComputeShader Shader;
        public Matrix4x4[] Matrices;
    }
    
    static void ExecutePass(PassData data, ComputeGraphContext context)
    {   
        context.cmd.SetBufferCounterValue(data.OutputBufferHandle, 0);
        
        context.cmd.SetBufferData(data.InputBufferHandle, data.Matrices);
        Plane[] frustumPlanes = GeometryUtility.CalculateFrustumPlanes(Camera.main);
        Vector4[] planeVectors = new Vector4[6];
        for (int i = 0; i < 6; i++)
        {
            Plane p = frustumPlanes[i];
            planeVectors[i] = new Vector4(p.normal.x, p.normal.y, p.normal.z, p.distance);
        }
        planesBuffer.SetData(planeVectors);

        ComputeShader shader = data.Shader;
        int kernel = shader.FindKernel("CSMain");
        shader.SetBuffer(kernel, InFrustumPlanes, planesBuffer);
        shader.SetBuffer(kernel, InMatrices, data.InputBufferHandle);
        shader.SetBuffer(kernel, OutCulledMatrices, data.OutputBufferHandle);
        shader.SetFloat(InRadius, 3);
        context.cmd.DispatchCompute(shader, 0, data.Matrices.Length, 1, 1);
        uint[] args = new uint[5];
        args[0] = _mesh.GetIndexCount(0); //Index count
        args[1] = (uint) data.Matrices.Length; //Instance count
        args[2] = _mesh.GetIndexStart(0); //IndexStart
        args[3] = _mesh.GetBaseVertex(0); //BaseVertex
        args[4] = 0; //Instance Start
        context.cmd.SetBufferData(data.IndirectArgsBufferHandle, args);
        context.cmd.CopyCounterValue(data.OutputBufferHandle,
                                data.IndirectArgsBufferHandle,
                                sizeof(uint));
    }
    
    //We record render graph as we would in any other render feature
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        const string passName = "Culling Pass";
        //We get our input buffer from the static class and import it to get a buffer handle
        //so that we can use it within the pass

        int matrixCount = 0;
        //we can later do some pre culling here
        foreach (MassRenderer renderer in _massRenderers)
        {
            matrixCount += renderer.InstanceCount;
        }

        CullingFrameData cullingFrameData = frameData.GetOrCreate<CullingFrameData>();
        cullingFrameData.IsAnythingToDraw = matrixCount > 0;
        if (cullingFrameData.IsAnythingToDraw)
        {
            Matrix4x4[] matrices = new Matrix4x4[matrixCount];
            int offset = 0;
            foreach (MassRenderer renderer in _massRenderers)
            {
                var trsMatrices = renderer.GetTrsMatrices();
                for (var index = 0; index < trsMatrices.Length; index++)
                {
                    matrices[offset] = trsMatrices[index];
                    offset++;
                }
            }
            
            var desc  =new BufferDesc(matrixCount, sizeof(float) * 16, GraphicsBuffer.Target.Structured);
            BufferHandle inputBufferHandle = renderGraph.CreateBuffer(desc);
            BufferHandle outputBufferHandle = renderGraph.CreateBuffer(new BufferDesc(matrixCount, 
                sizeof(float) * 16,
                GraphicsBuffer.Target.Structured
                | GraphicsBuffer.Target.Append ));
            

            BufferHandle indirectArgsHandle = renderGraph.CreateBuffer(new BufferDesc(1, 
                                                                        sizeof(uint) * 5,
                                                                        GraphicsBuffer.Target.IndirectArguments));
            
            //We get or create an instance of this ContextItem class
            //We fill in the reference for CulledMatricesBuffer
            cullingFrameData.CulledMatricesBuffer = outputBufferHandle;
            cullingFrameData.ArgsBuffer = indirectArgsHandle;
            
            using (var builder = renderGraph.AddComputePass<PassData>(passName, out var passData))
            {
                //We fill in PassData with this buffer hande
                passData.Shader = _cullingShader;
                passData.InputBufferHandle = inputBufferHandle;
                passData.OutputBufferHandle = outputBufferHandle;
                passData.IndirectArgsBufferHandle = indirectArgsHandle;
                passData.Matrices = matrices;
                //We have to declare that we will be using this buffer so it is accessible in this pass
                //We only need read permissions as we will be not modifying this buffer.
                builder.UseBuffer(passData.InputBufferHandle, AccessFlags.Read);
                builder.UseBuffer(passData.OutputBufferHandle, AccessFlags.Write);
                builder.UseBuffer(passData.IndirectArgsBufferHandle, AccessFlags.Write);
                builder.SetRenderFunc((PassData data, ComputeGraphContext context) => ExecutePass(data, context));
            }
        }
    }
}