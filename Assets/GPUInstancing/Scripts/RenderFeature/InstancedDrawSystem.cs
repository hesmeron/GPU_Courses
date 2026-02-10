using System.Collections.Generic;
using UnityEngine;

public class InstancedDrawSystem
{
    private static Dictionary<Mesh, GraphicsBuffer> _meshComputeBufferDict;
    
    public static GraphicsBuffer GetArgsBuffer(Mesh mesh)
    {
        if (_meshComputeBufferDict == null)
        {
            _meshComputeBufferDict = new Dictionary<Mesh, GraphicsBuffer>();
        }
        if (_meshComputeBufferDict.TryGetValue(mesh, out var argsBuffer))
        {
            return argsBuffer;
        }
        else
        {
            uint[] args = new uint[5];
            args[0] = mesh.GetIndexCount(0);
            args[1] = (uint)10000;
            args[2] = mesh.GetIndexStart(0);
            args[3] = mesh.GetBaseVertex(0);
            args[4] = 0;
            var buffer = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, 1, 5 * sizeof(uint));
            buffer.name = "ArgsBuffer_" + mesh.name;
            buffer.SetData(args);
            _meshComputeBufferDict.Add(mesh, buffer);
            return buffer;
        }

    }
}
