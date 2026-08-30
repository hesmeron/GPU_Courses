using System.Collections.Generic;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public interface IShadowPass
{
    void ExecuteShadowPass(RasterCommandBuffer cmd, ref ShadowSliceData slice);
}


public static class ShadowRenderer
{
    private static readonly List<IShadowPass> _framePasses = new();

    public static void Enqueue(IShadowPass pass)
    {
        if (pass != null)
            _framePasses.Add(pass);
    }

    internal static void Execute(RasterCommandBuffer cmd, ref ShadowSliceData slice)
    {
        foreach (var pass in _framePasses)
        {
            pass.ExecuteShadowPass(cmd, ref slice);
        }
        _framePasses.Clear();
    }
}