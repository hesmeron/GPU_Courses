using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class  InstancedShadowPass : IShadowPass
{
    private Mesh _mesh;
    private Material _material;
    private GraphicsBuffer _matrices;

    public InstancedShadowPass(Material material, Mesh mesh)
    {
        _mesh = mesh;
        _material = material;

    }

    public void Execute(RasterCommandBuffer cmd, ref ShadowSliceData slice)
    {
        _matrices = InstancedDrawSystem.GetOutputBuffer();
        var argsBuffer = InstancedDrawSystem.GetArgsBuffer(_mesh);

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
                argsBuffer,
                0,
                block);


        }
    }
}