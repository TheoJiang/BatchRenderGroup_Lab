using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TryGetAmbient : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        // MaterialPropertyBlock a;
        // a.CopySHCoefficientArraysFrom();

    }

    // Update is called once per frame
    void Update()
    {
        LightProbes.GetInterpolatedProbe(gameObject.transform.position, null, out var propProbe);
        Debug.Log(propProbe[0,0]);
        Debug.Log(propProbe[0,1]);
        Debug.Log(propProbe[0,2]);
        Debug.Log(propProbe[0,3]);
        Debug.Log(propProbe[0,4]);
        Debug.Log(propProbe[0,5]);
        Debug.Log(propProbe[0,6]);
        Debug.Log(propProbe[0,7]);
        Debug.Log(propProbe[0,8]);
        Debug.Log("/////////////////////");
        Debug.Log(propProbe[1,0]);
        Debug.Log(propProbe[1,1]);
        Debug.Log(propProbe[1,2]);
        Debug.Log(propProbe[1,3]);
        Debug.Log(propProbe[1,4]);
        Debug.Log(propProbe[1,5]);
        Debug.Log(propProbe[1,6]);
        Debug.Log(propProbe[1,7]);
        Debug.Log(propProbe[1,8]);
        Debug.Log("/////////////////////");
        Debug.Log(propProbe[2,0]);
        Debug.Log(propProbe[2,1]);
        Debug.Log(propProbe[2,2]);
        Debug.Log(propProbe[2,3]);
        Debug.Log(propProbe[2,4]);
        Debug.Log(propProbe[2,5]);
        Debug.Log(propProbe[2,6]);
        Debug.Log(propProbe[2,7]);
        Debug.Log(propProbe[2,8]);
    }
}
