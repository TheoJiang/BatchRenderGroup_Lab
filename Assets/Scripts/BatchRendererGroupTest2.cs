using System;
using System.Collections.Generic;
using System.Diagnostics;
using Unity.Burst;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Jobs;
using Unity.Mathematics;
using Unity.Rendering;
using UnityEngine;
using UnityEngine.Rendering;
using Debug = UnityEngine.Debug;

public unsafe class BatchRendererGroupTest2 : MonoBehaviour
{
   [SerializeField]
   private MeshFilter _mesh;

   [SerializeField] private Material _material;

   private BatchRendererGroup _batchRendererGroup;

  // private NativeArray<CullData> _cullDatas;
   private NativeMultiHashMap<int,CullData> _cullDic;
   struct CullData
   {
      public AABB bound;
      public float3 position;
      public float minDistance;
      public float maxDistance;

   }

   public int arrayLength = 10;

   private void Start()
   {
      _batchRendererGroup = new BatchRendererGroup(OnPerformCulling);
  //    _cullDatas = new NativeArray<CullData>(50000,Allocator.Persistent);
      
      _cullDic = new NativeMultiHashMap<int, CullData>(100,Allocator.Persistent);
      
      Stopwatch stopwatch =new Stopwatch();
      stopwatch.Restart();
      aDD();
      Debug.Log("batch render group :" + stopwatch.ElapsedMilliseconds);
   }

   void OnGUI()
   {
      if(GUILayout.Button("click"))
          aDD();
      if(GUILayout.Button("update"))
         UpdateData();
      
   }

   private int z = 0;
   void aDD()
   { 
      var pos = new float3[arrayLength* arrayLength];
      var rot = new quaternion[arrayLength* arrayLength];
      var scale = new float3[arrayLength* arrayLength];

      // for (int j = 0; j < arrayLength; j++)
      // {
      //
      //    for (int i = 0; i < arrayLength; i++)
      //    {
      //       pos[i] = new float3(i*2,j*2,j*2);
      //       rot[i] = quaternion.identity;
      //       scale[i] = new float3(1,1,1);
      //    }
      //    AddBatch(0,arrayLength* arrayLength,pos,rot,scale);
      // }

      {
      
         for (int i = 0; i < arrayLength; i++)
         {
            pos[i] = new float3(i,i,i);
            rot[i] = quaternion.identity;
            scale[i] = new float3(1,1,1);
            AddBatch(0,1,pos,rot,scale);
         }
      }
      
      z++;
   }

   private int updateIndex = 0;
   
   void UpdateData()
   {
      AABB localbound;
      localbound.Center = this._mesh.mesh.bounds.center;
      localbound.Extents = _mesh.mesh.bounds.extents;
      var pos = new float3[4];
      var rot = new quaternion[4];
      var scale = new float3[4];

      for (int i = 0; i < 4; i++)
      {
         pos[i] = new float3(i*2,updateIndex,0);
         rot[i] = quaternion.identity;
         scale[i] = new float3(1,1,1);
      }


      _batchRendererGroup.SetInstancingData(updateIndex,4,null);
      
      
      int colorArrayIndex = Shader.PropertyToID("_Color");
    
      float* nativePtr = null;
    
      var arr4 = _batchRendererGroup.GetBatchVectorArray(updateIndex,colorArrayIndex);
      
      nativePtr = (float*)arr4.GetUnsafePtr();
    
      var colors = new NativeArray<Vector4>(4,Allocator.Temp);

      colors[1] =  ( new Vector4( Color.red.r, Color.red.g, Color.red.b, Color.red.a));
      colors[2] = ( new Vector4( Color.yellow.r, Color.yellow.g, Color.yellow.b, Color.yellow.a));
      colors[0] = ( new Vector4( Color.blue.r, Color.blue.g, Color.blue.b, Color.blue.a));
      colors[3] = Color.cyan;
      
      MaterialPropertyBlock mpb = new MaterialPropertyBlock();
      mpb.SetVectorArray("_Color", colors.ToArray());
      
      _batchRendererGroup.SetInstancingData(updateIndex,4,mpb);

      
      // UnsafeUtility.MemCpy(nativePtr,  (float*)colors.GetUnsafePtr(), UnsafeUtility.SizeOf<float4>() * 4);
      var matrices = _batchRendererGroup.GetBatchMatrices(updateIndex);
      
      
      NativeMultiHashMapIterator<int> it;
      CullData cullData;
      bool has = _cullDic.TryGetFirstValue(updateIndex, out  cullData, out it);
   
      for (int i = 0; i < 4; i++)
      {
         matrices[i] = float4x4.TRS(pos[i], rot[i], scale[i]);
        
         var aabb = AABB.Transform(matrices[i], localbound);

         if(i > 0)
             has = _cullDic.TryGetNextValue(out cullData, ref it);
         if(!has)
            _cullDic.Add(updateIndex, new CullData()
            {
               bound =  aabb,
               position = pos[i],
               minDistance = 0,
               maxDistance = 10
            });
         else
         {
            cullData = new CullData()
            {
               bound =  aabb,
               position = pos[i],
               minDistance = 0,
               maxDistance = 10
            };
         }
      }

      updateIndex++;
   }
   
   
   private JobHandle _handle;

   private int batchIndex = 0;
   
   void AddBatch(int offset, int count, float3[] pos, quaternion[] rot, float3[] scale)
   {
      AABB localbound;
      localbound.Center = this._mesh.mesh.bounds.center;
      localbound.Extents = _mesh.mesh.bounds.extents;

      MaterialPropertyBlock block = new MaterialPropertyBlock();
  
      var colors = new NativeArray<Vector4>(2,Allocator.Temp);

      // for (int i = 0; i < count; i+=5)
      // {
      //    colors[i] = Color.cyan;
      //    colors[i +1] = Color.red;
      //    colors[i +2] = Color.yellow;
      //    colors[i +3] = Color.blue;
      //    colors[i +4] = Color.green;
      // }
      
      for (int i = 0; i < 2; i++)
      {
         colors[i] = new Color(1, 0,0,1) * (i + 1) / 2;

      }
      
      
    //  colors[0] =  ( new Vector4( Color.red.r, Color.red.g, Color.red.b, Color.red.a));
   //   colors[1] = ( new Vector4( Color.yellow.r, Color.yellow.g, Color.yellow.b, Color.yellow.a));
    //  colors[2] = ( new Vector4( Color.blue.r, Color.blue.g, Color.blue.b, Color.blue.a));
      

      batchIndex = _batchRendererGroup.AddBatch(_mesh.mesh, 0, _material, 0, ShadowCastingMode.On, true, false,
         new Bounds(Vector3.zero, 1000 * Vector3.one), 2, null, null);
      
      
      int colorArrayIndex = Shader.PropertyToID("_Color");
      
      block.SetVectorArray("_Color", new []{colors[0]});
      _batchRendererGroup.SetInstancingData(batchIndex,2, block);


   //   colors.Dispose();
    
      var matrices = _batchRendererGroup.GetBatchMatrices(batchIndex);
      for (int i = 0; i < 2; i++)
      {
         matrices[i] = float4x4.TRS(pos[0], rot[0], scale[0]);
        
         var aabb = AABB.Transform(matrices[i], localbound);
         _cullDic.Add(batchIndex, new CullData()
         {
            bound =  aabb,
            position = pos[0],
            minDistance = 0,
            maxDistance = 100
         });
      }
      matrices[1] = float4x4.TRS(new Vector3(2, 1,1), rot[0], scale[0]);
   }
   
   private void OnDestroy()
   {
      if (this._batchRendererGroup != null)
      {
         this._batchRendererGroup.Dispose();
         this._batchRendererGroup = null;
       // _cullDatas.Dispose();

       _cullDic.Dispose();
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
          CullDatas = _cullDic,
       };
      // Debug.Log(_cullDic.GetKeyArray(Allocator.Temp).Length); ;
       var handle= cull.Schedule(batchIndex + 1, 1);
  
       return handle;
       
   }
  
  [BurstCompile]
   struct MyCullJob : IJobParallelFor
   {
      [ReadOnly] public LODGroupExtensions.LODParams LODParams;
      [DeallocateOnJobCompletion] [ReadOnly] public NativeArray<Unity.Rendering.FrustumPlanes.PlanePacket4> Planes;
   //   [NativeDisableParallelForRestriction] [ReadOnly] public NativeArray<CullData> CullDatas;    
      [NativeDisableParallelForRestriction] [ReadOnly] public  NativeMultiHashMap<int,CullData> CullDatas;
    
      [NativeDisableParallelForRestriction] public NativeArray<BatchVisibility> Batches;
      [NativeDisableParallelForRestriction] public NativeArray<int> IndexList;

      public void Execute(int index)
      {
         var bv = Batches[index];
         var visibleInstancesIndex = 0;
         var isOrtho = LODParams.isOrtho;
         var DistanceScale = LODParams.distanceScale;
         NativeMultiHashMapIterator<int> it;
         CullData cullData;
         CullDatas.TryGetFirstValue(index, out  cullData, out it);
         for (int j = 0; j < bv.instancesCount; ++j)
         {
            if(j > 0)
            {
               CullDatas.TryGetNextValue(out cullData, ref it);
            }
            
          //  var cullData =  CullDatas.[index* 50 + j];
            var rootLodDistance = math.select(DistanceScale * math.length(LODParams.cameraPos - cullData.position), DistanceScale, isOrtho);
            var rootLodIntersect = (rootLodDistance < cullData.maxDistance) && (rootLodDistance >= cullData.minDistance);
            if (rootLodIntersect)
            {
               var chunkIn = Unity.Rendering.FrustumPlanes.Intersect2NoPartial(Planes, cullData.bound);
               if (chunkIn != Unity.Rendering.FrustumPlanes.IntersectResult.Out)
               {
                  IndexList[bv.offset + visibleInstancesIndex] =  j;
//                  Debug.Log("visibleInstancesIndex" + visibleInstancesIndex + "  j:" + j);
                  visibleInstancesIndex++;
               }
            }
         }
      //   Debug.Log("visible num :" +visibleInstancesIndex);
         
         bv.visibleCount = visibleInstancesIndex;
         Batches[index] = bv; 
      }
   }
   

   
   
}
