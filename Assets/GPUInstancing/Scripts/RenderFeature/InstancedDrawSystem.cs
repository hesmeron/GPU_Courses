using System.Collections.Generic;
using UnityEngine;

public class InstancedDrawSystem
{
    private static GraphicsBuffer _outputBuffer;
    private static GraphicsBuffer _inputBuffer;
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
            _meshComputeBufferDict.Add(mesh, buffer);
            return buffer;
        }

    }

    public static GraphicsBuffer GetInputBuffer()
    {
        //We will create a matrix buffer only if one does not already exist, in order to prevent a memory leak
        if (_inputBuffer == null)
        {
            //here we create our matrix array
            int width = 100;
            int height = 100;
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
            //We create a structured buffer that has an allocated size of float4x4 matrix per entry
            
            _inputBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured,
                matrices.Length, sizeof(float) * 16);
            _inputBuffer.SetData(matrices);
            //Remember to name the buffer in a most unimaginative way possible
            _inputBuffer.name = "InputBuffer";
        }

        return _inputBuffer;
    }
    
    public static GraphicsBuffer GetOutputBuffer()
    {
        if (_outputBuffer == null)
        {
            _outputBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured 
                                               | GraphicsBuffer.Target.Append, 
                10000,  sizeof(float) * 16);
            _outputBuffer.name = "OutputBuffer";
        }
        return _outputBuffer;
    }
}
