
Shader "Hidden/UnityStandardAnisotropic (Custom)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_TangentMap("Tangent Map (RG)", 2D) = "white" {}
		_AnisotropyMap ("Anisotropy Map (RGB)", 2D) = "white" {}
		_Anisotropy ("Anisotropy", Range(0,1)) = 1.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Transparent"}
		LOD 200
		
		CGPROGRAM
		#include "UnityCG.cginc"
		#include "CGIncludes/UnityAnisotropicBRDF.cginc"
		#include "CGIncludes/UnityAnisotropicLighting.cginc"
		#define UNITY_BRDF_PBS BRDF_Unity_Anisotropic
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface AnisotropicSurface StandardAnisotropic vertex:vert fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 5.0

		sampler2D _MainTex;
		sampler2D _TangentMap;
		sampler2D _AnisotropyMap;
		float _Anisotropy;

		//Vertex struct
		struct Input
		{
			float2 uv_MainTex;
			float3 normal;
			float3 viewDir;
			float3 normalDir;
			float3 tangentDir;
			float3 bitangentDir;
		};

		//Vertex shader
		void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			//Normal 2 World
			o.normalDir = normalize(UnityObjectToWorldNormal(v.normal));
			//Tangent 2 World
			float3 tangentMul = normalize(mul(unity_ObjectToWorld, v.tangent.xyz));
			o.tangentDir = float4(tangentMul, v.tangent.w);
			// Bitangent
			o.bitangentDir = cross(o.normalDir, o.tangentDir);
		}

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END

		void AnisotropicSurface (Input IN, inout SurfaceOutputStandardAnisotropic o) 
		{
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
			o.Anisotropy = tex2D(_AnisotropyMap, IN.uv_MainTex) * _Anisotropy;

			float3x3 worldToTangent;
			worldToTangent[0] = float3(1, 0, 0);
			worldToTangent[1] = float3(0, 1, 0);
			worldToTangent[2] = float3(0, 0, 1); 

			float3 tangentTS = tex2D(_TangentMap, IN.uv_MainTex);
			float3 tangentTWS = mul(tangentTS, worldToTangent);
			float3 fTangent;
			if (tangentTS.z < 1)
				fTangent = tangentTWS;
			else
				fTangent = IN.tangentDir;
			o.WorldVectors = float3x3(fTangent, IN.bitangentDir, IN.normalDir);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
