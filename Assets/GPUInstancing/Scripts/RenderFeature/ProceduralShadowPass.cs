using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class  InstancedShadowPass : IShadowPass
{
    private Mesh _mesh;
    private Material _material;
    private GraphicsBuffer _matrices;
    private static ComputeBuffer _argsBuffer;

    public InstancedShadowPass(Material material, Mesh mesh)
    {
        _mesh = mesh;
        _material = material;
        _matrices = InstancedDrawSystem.GetOutputBuffer();
        if (_argsBuffer == null)
        {
            uint[] args = new uint[5];
            args[0] = mesh.GetIndexCount(0);
            args[1] = (uint)100;
            args[2] = mesh.GetIndexStart(0);
            args[3] = mesh.GetBaseVertex(0);
            args[4] = 0;

            _argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
            _argsBuffer.SetData(args);
        }
    }

    public void Execute(RasterCommandBuffer cmd, ref ShadowSliceData slice)
    {
        _matrices =InstancedDrawSystem.GetOutputBuffer();
        GraphicsBuffer.CopyCount(_matrices, _argsBuffer, sizeof(uint)*1);

        var block = new MaterialPropertyBlock();
        block.SetBuffer("_TransformationMatrices", _matrices);

        int shadowPass = _material.FindPass("ShadowCaster");
        if (shadowPass >= 0)
        {
            Debug.Log("Execute shadow pass");

            cmd.DrawMeshInstancedIndirect(
                _mesh,
                0,
                _material,
                shadowPass,
                _argsBuffer,
                0,
                block);


        }
    }
}