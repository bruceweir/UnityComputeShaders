﻿Shader "Instanced/InstancedIndirectSurfaceShader" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#include "Quaternion.cginc"

		#pragma surface surf Standard addshadow
		#pragma instancing_options procedural:setup

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		
		fixed4 _Color;
		half _Glossiness;
		half _Metallic;

		struct Input {
			float2 uv_MainTex;
		};


		#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
			StructuredBuffer<float3> positions;
			StructuredBuffer<float4> quaternions;
			StructuredBuffer<float3> previousPositions;
			StructuredBuffer<float4> previousQuaternions;
			float blendAlpha;
		#endif

		void setup()
		{
		#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
			//float4x4 rotation = quaternion_to_matrix(nlerp(previousQuaternions[unity_InstanceID], quaternions[unity_InstanceID], blendAlpha));
			float4x4 rotation = quaternion_to_matrix(quaternions[unity_InstanceID]);
			//float3 position 	= lerp(previousPositions[unity_InstanceID], positions[unity_InstanceID], blendAlpha);
			float3 position 	= positions[unity_InstanceID];
			float4x4 translation = {
				1,0,0,position.x,
				0,1,0,position.y,
				0,0,1,position.z,
				0,0,0,1
			};
			unity_ObjectToWorld = mul(translation, rotation);

			
			// inverse transform matrix
			// taken from richardkettlewell's post on
			// https://forum.unity3d.com/threads/drawmeshinstancedindirect-example-comments-and-questions.446080/

			float3x3 w2oRotation;
			w2oRotation[0] = unity_ObjectToWorld[1].yzx * unity_ObjectToWorld[2].zxy - unity_ObjectToWorld[1].zxy * unity_ObjectToWorld[2].yzx;
			w2oRotation[1] = unity_ObjectToWorld[0].zxy * unity_ObjectToWorld[2].yzx - unity_ObjectToWorld[0].yzx * unity_ObjectToWorld[2].zxy;
			w2oRotation[2] = unity_ObjectToWorld[0].yzx * unity_ObjectToWorld[1].zxy - unity_ObjectToWorld[0].zxy * unity_ObjectToWorld[1].yzx;

			float det = dot(unity_ObjectToWorld[0], w2oRotation[0]);

			w2oRotation = transpose(w2oRotation);

			w2oRotation *= rcp(det);

			float3 w2oPosition = mul(w2oRotation, -unity_ObjectToWorld._14_24_34);

			
			unity_WorldToObject._11_21_31_41 = float4(w2oRotation._11_21_31, 0.0f);
			unity_WorldToObject._12_22_32_42 = float4(w2oRotation._12_22_32, 0.0f);
			unity_WorldToObject._13_23_33_43 = float4(w2oRotation._13_23_33, 0.0f);
			unity_WorldToObject._14_24_34_44 = float4(w2oPosition, 1.0f);
		#endif
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}

		ENDCG
	}
	FallBack "Diffuse"
}
