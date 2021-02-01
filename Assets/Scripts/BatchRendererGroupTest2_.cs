using System;
using System.Collections.Generic;
using System.Diagnostics;
using Unity.Burst;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Jobs;
using Unity.Mathematics;
using Unity.Rendering;
using Unity.Rendering.HybridV2;
//using Unity.Rendering;
using UnityEngine;
using UnityEngine.Jobs;
using UnityEngine.Rendering;
using Debug = UnityEngine.Debug;
using Random = UnityEngine.Random;

public unsafe class BatchRendererGroupTest2_ : MonoBehaviour
{
   [SerializeField]
   private MeshFilter _mesh;

   [SerializeField] private Material _material;

   private BatchRendererGroup _batchRendererGroup;

   private NativeArray<CullData> _cullDatas;

   struct CullData
   {
      public AABB bound;
      public float3 position;
      public float minDistance;
      public float maxDistance;

   }

   private int arrayLength = 100;

   private void Start()
   {
      _batchRendererGroup = new BatchRendererGroup(OnPerformCulling);
      _cullDatas = new NativeArray<CullData>(50000,Allocator.Persistent);
      Stopwatch stopwatch =new Stopwatch();
      stopwatch.Restart();
      for (int j = 0; j < arrayLength; j++)
      {
         var pos = new float3[3];
         var rot = new quaternion[3];
         var scale = new float3[3];

         for (int i = 0; i < 3; i++)
         {
            pos[i] = new float3(i*5,j*2,j*2);
            rot[i] = quaternion.identity;
            scale[i] = new float3(1,1,1);
         }
         AddBatch(3*j,3,pos,rot,scale);
      }
      Debug.Log("batch render group :" + stopwatch.ElapsedMilliseconds);
   }
   
   private JobHandle _handle;
   
   void AddBatch(int offset, int count, float3[] pos, quaternion[] rot, float3[] scale)
   {
      AABB localbound;
      localbound.Center = this._mesh.mesh.bounds.center;
      localbound.Extents = _mesh.mesh.bounds.extents;

      MaterialPropertyBlock block = new MaterialPropertyBlock();
  
      var colors = new NativeArray<Vector4>(3,Allocator.Temp);
      
      colors[0] = ( new Vector4( Color.red.r, Color.red.g, Color.red.b, Color.red.a));
      colors[1] = ( new Vector4( Color.yellow.r, Color.yellow.g, Color.yellow.b, Color.yellow.a));
      colors[2] = ( new Vector4( Color.blue.r, Color.blue.g, Color.blue.b, Color.blue.a));
      
      block.SetVectorArray("_Color", colors.ToArray());

      var batchIndex = _batchRendererGroup.AddBatch(_mesh.mesh, 0, _material, 0, ShadowCastingMode.On, true, false,
         new Bounds(Vector3.zero, 1000 * Vector3.one), count, null, null);
      
      
  //   _batchRendererGroup.SetInstancingData(batchIndex,count,block);
  
      int colorArrayIndex = Shader.PropertyToID("_Color_Array");
    
      float* nativePtr = null;
    
      var arr4 = _batchRendererGroup.GetBatchVectorArray(batchIndex,colorArrayIndex);
      
      nativePtr = (float*)arr4.GetUnsafePtr();
      
      UnsafeUtility.MemCpy(nativePtr,  (float*)colors.GetUnsafePtr(), UnsafeUtility.SizeOf<float4>() * count);
     

   //   colors.Dispose();
    
      
      var matrices = _batchRendererGroup.GetBatchMatrices(batchIndex);
      for (int i = 0; i < count; i++)
      {
         matrices[i] = float4x4.TRS(pos[i], rot[i], scale[i]);
        
         var aabb = AABB.Transform(matrices[i], localbound);

         _cullDatas[offset + i] = new CullData()
         {
            bound =  aabb,
            position = pos[i],
            minDistance = 0,
            maxDistance = 100
         };

      }
   }
   
   private void OnDestroy()
   {
      if (this._batchRendererGroup != null)
      {
         this._batchRendererGroup.Dispose();
         this._batchRendererGroup = null;
         _cullDatas.Dispose();
      }
   }
   
   private JobHandle OnPerformCulling(BatchRendererGroup batchRendererGroup, BatchCullingContext cullingContext)
   {
       var planes = Unity.Rendering.FrustumPlanes.BuildSOAPlanePackets(cullingContext.cullingPlanes, Allocator.TempJob);
       var lodParms = LODGroupExtensions.CalculateLODParams(cullingContext.lodParameters);
       
       var cull = new MyCullJob()
       {
          Planes = planes,
          LODParams = lodParms,
          IndexList = cullingContext.visibleIndices,
          Batches = cullingContext.batchVisibility,
          CullDatas = _cullDatas,
       };

       var handle= cull.Schedule(arrayLength, 1);
  
       return handle;
       
   }
  
   struct MyCullJob : IJobParallelFor
   {
      [ReadOnly] public LODGroupExtensions.LODParams LODParams;
      [DeallocateOnJobCompletion] [ReadOnly] public NativeArray<Unity.Rendering.FrustumPlanes.PlanePacket4> Planes;
      [NativeDisableParallelForRestriction] [ReadOnly] public NativeArray<CullData> CullDatas;

      [NativeDisableParallelForRestriction] public NativeArray<BatchVisibility> Batches;
      [NativeDisableParallelForRestriction] public NativeArray<int> IndexList;

      public void Execute(int index)
      {
         var bv = Batches[index];
         var visibleInstancesIndex = 0;
         var isOrtho = LODParams.isOrtho;
         var DistanceScale = LODParams.distanceScale;
         for (int j = 0; j < bv.instancesCount; ++j)
         {
            var cullData =  CullDatas[index* 50 + j];
            var rootLodDistance = math.select(DistanceScale * math.length(LODParams.cameraPos - cullData.position), DistanceScale, isOrtho);
            var rootLodIntersect = (rootLodDistance < cullData.maxDistance) && (rootLodDistance >= cullData.minDistance);
            if (rootLodIntersect)
            {
               var chunkIn = Unity.Rendering.FrustumPlanes.Intersect2NoPartial(Planes, cullData.bound);
               if (chunkIn != Unity.Rendering.FrustumPlanes.IntersectResult.Out)
               {
                  IndexList[bv.offset + visibleInstancesIndex] =  j;
                  Debug.Log("visibleInstancesIndex" + visibleInstancesIndex + "  j:" + j);
                  visibleInstancesIndex++;
               }
            }
         }
         Debug.Log("visible num :" +visibleInstancesIndex);
         
         bv.visibleCount = visibleInstancesIndex;
         Batches[index] = bv; 
      }
   }
   

   
   
}
