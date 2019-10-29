//@author: flux
//@help: Physically based BRDF analytic light
//@tags: PBR, GGX, Lambert, Disney

#define PI_2 6.28318531
#define PI    3.14159265

cbuffer cbPerDraw : register(b0)
{
	float4x4 tLAV: LAYERVIEW;
	float4x4 tP: PROJECTION;
	float4x4 tLVP: LAYERVIEWPROJECTION;
};

struct LightBuffer
{
	float3 pos;
	float lum;
	float3 dir;
	float rad;
	float3 col;	
	float ang;
	float type;
};

StructuredBuffer<float4x4> Transform;
StructuredBuffer<float4x4> TransformINV;   // Inverse
StructuredBuffer<float4> AlbedoColor;
StructuredBuffer<float4> MaterialProperties;
StructuredBuffer<LightBuffer> light;

struct SurfaceProp
{
	float3x3 tbn;
	float4 mat;    //metallic, roughness, anisoUV
	float3 vDirV;
	bool iso;
	float3 albedo;
	bool disney;	
};

cbuffer cbPerObj : register(b1)
{
	bool disney <String uiname="DiffuseBRDF";> = 1;
};

cbuffer cbLayerSemantics : register(b2)
{
	int tonemap : GAMMA_CORRECT;
}

struct vsInput
{
    float4 PosO : POSITION;
	float3 NormO : NORMAL;
	#if TANGENTS	
	float3 TangO : TANGENT;
	float3 BinormO : BINORMAL;
	#endif
	float4 uv: TEXCOORD0;
	uint ii : SV_InstanceID;
};

struct psInput
{
    float4 posScreen : SV_Position;
    float4 uv: TEXCOORD0;
    float3 NormV: NORMAL;   
	#if TANGENTS	
	float3 TangV: TANGENT;
	float3 BinormV: BINORMAL;	
	#endif	
    float3 vDirV: TEXCOORD1;
	uint ii : InstanceID;
};

Texture2D Albedo <string uiname="Albedo";>;
Texture2D NormalMap <string uiname="Normal Map";>;
Texture2D Material <string uiname="Material Properties";>;

SamplerState linearSampler <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

#include "CotangentFrame.fxh"
#include "BRDF.fxh"

cbuffer cbTextureData : register(b3)
{
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
};

//______________________________________________________________________________

psInput VS(vsInput In)
{
    psInput Out;
  
	float4x4 tW = Transform[In.ii];
	float4x4 tWIT = tW;
		
	uint inv, dummy;
    TransformINV.GetDimensions(inv, dummy);
	
	if(inv > 0){
		tWIT = transpose(TransformINV[In.ii]);
	}
		
	float4 PosW  = mul(In.PosO,tW);
	
	Out.NormV = normalize(mul(mul(In.NormO, (float3x3)tWIT),(float3x3)tLAV));	

	#if TANGENTS	
	Out.TangV = normalize(mul(mul(In.TangO, (float3x3)tW),(float3x3)tLAV));		
	Out.BinormV = normalize(mul(mul(In.BinormO, (float3x3)tW),(float3x3)tLAV));	
	#endif
	
    Out.posScreen  = mul(PosW,tLVP);
    Out.uv = mul(In.uv, tTex);
	Out.vDirV = mul(float4(PosW.xyz,1),tLAV).xyz;
	Out.ii = In.ii;
	
	return Out;
}
//______________________________________________________________________________


float4 PS(psInput In, uniform bool iso): SV_Target
{
    float3 albedo = Albedo.Sample(linearSampler, In.uv.xy).xyz;	
	float3 normalmap = NormalMap.Sample(linearSampler,In.uv.xy).xyz;
	float4 mat = Material.Sample(linearSampler, In.uv.xy);

	uint colSize, matSize, lightSize, dummy;
    AlbedoColor.GetDimensions(colSize, dummy);
	MaterialProperties.GetDimensions(matSize, dummy);
	light.GetDimensions(lightSize, dummy);
	
	float4 col  = AlbedoColor[In.ii % colSize];
	float4 matp = MaterialProperties[In.ii % matSize];
	mat.w = mat.z;
	mat *= float4(matp.xy,max(0,matp.z),abs(min(0,matp.z)));
		
	// to linear color space
	albedo = pow(abs(albedo*col.rgb),2.2f); 
	
	#if TANGENTS
	float3x3 tbn = float3x3(In.TangV,In.BinormV,In.NormV);
	#else
	float3x3 tbn = cotangent_frame(In.NormV, In.vDirV, In.uv.xy);
	#endif
			
	tbn = TBN_matrix(tbn,normalmap, matp.w);
	
	SurfaceProp p = {tbn, mat, In.vDirV, iso, albedo, disney};
	float3 result = 0;
	
	if(lightSize > 0){
		for (uint i = 0; i < lightSize; i++) {
			result += GGX(p,light[i]);		
		}	
	}	

	result = tonemap ? ToneMapper(result) : result;
    return float4(result,col.a);
}
//______________________________________________________________________________


technique11 Isotropic
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS(1) ) );
	}
}

technique11 Anisotropic
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS(0) ) );
	}
}
