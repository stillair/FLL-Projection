//@author: mburk
//@help: internet
//@tags: shading
//@credits: Vux, Dottore, Catweasel

static const uint MAX_REFLECTION_LOD = 9;

float2 R : TARGETSIZE;

int ID : DRAWINDEX;

struct LightStruct
{
	float4   Color;
    float4   lPos;
	
    float    lightRange;
    float    lAtt0;
    float    lAtt1;
    float    lightType;
	
    float 	 useShadow;
	float 	 shadowType;
	float 	 lightBleedingLimit;
	float 	 lightSize;
	
	float 	 penumbraScale;
	float 	 numShadowSamples;
	float 	 shadowPOMSamples;
	float 	 shadowPOM;
};

struct LightMatricesStruct
{
	row_major 	float4x4 VP;
	row_major	float4x4 V;
	row_major	float4x4 P;
};

struct MaterialStruct
{
	float metallic;
	float roughness;
	
	float 	pad0;
	float 	pad1;
	float4  Color;
	float4  Emissive;
	
	row_major float4x4	tTex;
	row_major float4x4	tTexInv;
	
	float 	sssAmount;
	float 	sssFalloff;
	float 	sss;
	float 	pad2;
	
	float 	fHeightMapScale;
	float 	POMnumSamples;
	float 	POM;
	float 	pad3;
	
	float4	Refraction;
	
	float	bumpy;
	float	TangentDir;
	float	useTex;
	float	Iridescence;
	
	#ifdef doControlTextures
	
	float	sampleAlbedo;
	float	sampleEmissive;
	float	sampleNormal;
	float	sampleHeight;
	
	float	sampleRoughness;
	float	sampleMetallic;
	float	sampleAO;
	float	pad4;
	
	#endif
};


static const float3 F = float3(0.04,0.04,0.04);	

cbuffer cbPerObject : register (b0)
{	
	//transforms
	float4x4 tW: WORLD;
	float4x4 tWI: WORLDINVERSE;
	float4x4 tVP: VIEWPROJECTION;
	float4x4 tV: VIEW;
	float4x4 tWVP: WORLDVIEWPROJECTION;
	
	float4 GlobalReflectionColor <bool color = true; string uiname="Global Reflection Color";>  = { 0.0f,0.0f,0.0f,0.0f };
	float4 GlobalDiffuseColor <bool color = true; string uiname="Global Diffuse Color";>  = { 0.0f,0.0f,0.0f,0.0f };
	
	float Alpha <float uimin=0.0; float uimax=1.0;> = 1;
	float lPower <String uiname="Power"; float uimin=0.0;> = 1.0;     //shininess of specular highlight

	float2 iblIntensity <String uiname="IBL Intensity";> = float2(1,1);	
	
	uint mCount <String uiname="Material Count";> ;
	
	uint num;
};

cbuffer cbPerRender : register (b1)
{	
	float4x4 tVI : VIEWINVERSE;
}

Texture2D texture2d <string uiname="Texture"; >;
Texture2D EmissiveTex <string uiname="Emissive"; >;
Texture2D normalTex <string uiname="NormalMap"; >;
Texture2D heightMap <string uiname="HeightMap"; >;
Texture2D roughTex <string uiname="RoughnessMap"; >;
Texture2D metallTex <string uiname="MetallicMap"; >;
Texture2D aoTex <string uiname="AOMap"; >;
Texture2D iridescence <string uiname="Iridescence"; >;

StructuredBuffer <bool> useTex;

TextureCube cubeTexRefl <string uiname="CubeMap Refl"; >;
TextureCube cubeTexIrradiance <string uiname="CubeMap Irradiance"; >;
Texture2D brdfLUT <string uiname="brdfLUT"; >;

Texture2DArray lightMap <string uiname="SpotTex"; >;
Texture2DArray shadowMap <string uiname="ShadowMap"; >;

StructuredBuffer <LightStruct> Light  <string uiname="Light Parameter Buffer";>;
StructuredBuffer <LightMatricesStruct> LightMatrices  <string uiname="Light Matrices Buffer";>;
StructuredBuffer <MaterialStruct> Material  <string uiname="Material";>;

SamplerState g_samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = WRAP;
    AddressV = WRAP;
};

SamplerState g_samLinearIBL
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

#include "..\dx11\ShadowMapping.fxh"
#include "..\dx11\ParallaxOcclusionMapping.fxh"
#include "..\dx11\CookTorrance.fxh"
#ifdef doPlanarReflections
#include "PLANARREFLECTION.fxh"
#endif

#ifdef doIBL
#include "..\dx11\IBL.fxh"
#endif

#ifdef doIridescence
#ifndef doIBL
#include "..\dx11\IRIDESCENCE.fxh"
#endif
#endif

#ifdef doGlobalLight
#ifndef doIBL
#include "..\dx11\GLOBALLIGHT.fxh"
#endif
#endif

#ifdef doToneMap
#include "ToneMapping.fxh"
#endif

/////////////////////////////////////////////////////////////////////
///////////  FORWARD PLUS   /////////////////////////////////////////
/////////////////////////////////////////////////////////////////////

#include "..\modules\SuperForward\nodes\dx11\forwardplus.fxh"

int numThreadGroupsX : THREADGROUPSX;
StructuredBuffer<Light_FWP> LightFWP : LIGHTS;
StructuredBuffer<uint> LightIndexList : LIGHTINDEXLIST;
StructuredBuffer<uint2> LightGrid : LIGHTGRID;
int useForwardPlus : FORWARDPLUS;

/////////////////////////////////////////////////////////////////////

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
    float4 TexCd : TEXCOORD0;
	float4 PosW: TEXCOORD1;
	float3 NormW : TEXCOORD2;
	float3 V: TEXCOORD3;
};

struct vs2psBump
{
    float4 PosWVP: SV_POSITION;
    float4 TexCd : TEXCOORD0;
	float4 PosW: TEXCOORD1;
	float3 NormW : TEXCOORD2;
	float3 tangent : TEXCOORD3;
	float3 binormal : TEXCOORD4;
};

vs2psBump VS_Bump(
    float4 PosO: POSITION,
    float3 NormO: NORMAL,
    float4 TexCd : TEXCOORD0,
	float3 tangent : TANGENT,
    float3 binormal : BINORMAL
)
{
    //inititalize all fields of output struct with 0
    vs2psBump Out = (vs2psBump)0;
    Out.PosW = mul(PosO, tW);	
	Out.NormW = mul(NormO, (float3x3)transpose(tWI));
	Out.NormW = normalize(Out.NormW);
	// Calculate the tangent vector against the world matrix only and then normalize the final value.
    Out.tangent = mul(tangent, (float3x3)tW);
    Out.tangent = normalize(Out.tangent);
    // Calculate the binormal vector against the world matrix only and then normalize the final value.
    Out.binormal = mul(binormal, (float3x3)tW);
    Out.binormal = normalize(Out.binormal);
    Out.PosWVP  = mul(PosO, tWVP);
	Out.TexCd = mul(TexCd,Material[ID%mCount].tTex);
    return Out;
}

vs2ps VS(
    float4 PosO: POSITION,
    float3 NormO: NORMAL,
    float4 TexCd : TEXCOORD0

)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
	
    Out.PosW = mul(PosO, tW);
	Out.NormW = mul(NormO, (float3x3)transpose(tWI));
	Out.NormW = normalize(Out.NormW);
    Out.PosWVP  = mul(PosO, tWVP);
	Out.TexCd = mul(TexCd,Material[ID%mCount].tTex);
    return Out;
}

#ifdef doShadowPOM
float4 doLighting(float4 PosW, float3 N, float4 TexCd, float2 pos, float3x3 tbn){
#else
float4 doLighting(float4 PosW, float3 N, float4 TexCd, float2 pos){
#endif
	
	uint texID = ID%mCount;
	
	///////////////////////////////////////////////////////////////////////////
	// INITIALIZE GLOBAL VARIABLES
	///////////////////////////////////////////////////////////////////////////
	
	float3 V = normalize(tVI[3].xyz - PosW.xyz);

	///////////////////////////////////////////////////////////////////////////
	// INITIALIZE PBR PRAMETERS WITH TEXTURE LOOKUP
	///////////////////////////////////////////////////////////////////////////
	
	float4 albedo =  Material[texID].Color;
	float roughness = Material[texID].roughness;;
	float ao = 1;
	float metallic = Material[texID].metallic;
	
	#ifdef doControlTextures
	if(useTex[texID]){
	
		
		if(Material[texID].sampleRoughness) roughness *= roughTex.Sample(g_samLinear, float3(TexCd.xy, texID)).r;

		if(Material[texID].sampleAO) ao = aoTex.Sample(g_samLinear,  float3(TexCd.xy, texID)).r;
	
		if(Material[texID].sampleMetallic) metallic *= metallTex.Sample(g_samLinear, float3(TexCd.xy, texID)).r;
		
		float4 texCol = 1;
		if(Material[texID].sampleAlbedo) albedo *= texture2d.Sample(g_samLinear, float3(TexCd.xy, texID)) * float4(ao.xxx,1);

		
	} 
	
	#endif
	
	///////////////////////////////////////////////////////////////////////////
	// INITIALIZE PBR PRAMETERS WITH TEXTURE LOOKUP
	///////////////////////////////////////////////////////////////////////////
	
	float3 iridescenceColor = 1;
	#ifdef doIridescence
	if (Material[texID].Iridescence){
		float inverseDotView = 1.0 - max(dot(N,V),0.0);
		iridescenceColor = iridescence.Sample(g_samLinear, float3(inverseDotView,0,texID)).rgb;
	} 	
	#endif
		
	///////////////////////////////////////////////////////////////////////////
	// INITIALIZE VARIABLES FOR LIGHT LOOP
	///////////////////////////////////////////////////////////////////////////
	
	float4 viewPosition;
	float4 projectTexCoord;
	
	float3 F0 = lerp(F, albedo.xyz, metallic);
	
	int shadowCounter = 0;
	int spotLightCount = 0;
	int lightCounter = 0;
	
	float4 shadow = 0;
	
	float3 lightToObject;
	float3 L;
	float lightDist;
	float falloff;

	float3 finalLight = 0;
	float attenuation;
	
	///////////////////////////////////////////////////////////////////////////
	// SHADING AND SHADOW MAPPING FOR EACH LIGHT
	///////////////////////////////////////////////////////////////////////////
	
	for(uint i = 0; i< num; i++){

		lightToObject = Light[i].lPos.xyz - PosW.xyz;
		L = normalize(lightToObject);
		lightDist = length(lightToObject);
		
		falloff = smoothstep(0,Light[i].lAtt1,(Light[i%num].lightRange-lightDist));
			
		
		switch (Light[i].lightType){
			
		// DIRECTIONAL
			case 0:
			
				shadow = 0;

				viewPosition = mul(PosW, LightMatrices[i].VP);
				
				projectTexCoord.x =  viewPosition.x / viewPosition.w / 2.0f + 0.5f;
		   		projectTexCoord.y = -viewPosition.y / viewPosition.w / 2.0f + 0.5f;			
				projectTexCoord.z =  viewPosition.z / viewPosition.w / 2.0f + 0.5f;
			
				
			
				if((saturate(projectTexCoord.x) == projectTexCoord.x) && (saturate(projectTexCoord.y) == projectTexCoord.y)
				&& (saturate(projectTexCoord.z) == projectTexCoord.z
				&& Light[i].useShadow)){
					doShadow(shadow, Light[i].shadowType, lightDist, Light[i%num].lightRange, projectTexCoord, viewPosition, i, shadowCounter, N, L);
					shadow += smoothstep(0,1,saturate(pow(length(.5-projectTexCoord.xy)*2,3)));
				} else {
					shadow = 1;
				}
							

					#ifdef doShadowPOM
						if(Light[i].shadowPOM > 0 && Material[texID].POM && useTex[texID]) shadow = min(shadow, parallaxSoftShadowMultiplier(-L, TexCd.xy, tbn, texID, i,Light[i].shadowPOM).xxxx);
					#endif
	
			
				finalLight += cookTorrance(V, L, N, albedo.xyz, Light[i].Color.rgb,
				lerp(1.0,saturate(shadow),falloff).x, 1.0, lightDist, Material[texID].sssAmount, Material[texID].sssFalloff, F0, 1, roughness, metallic, ao, iridescenceColor, texID);
				
				lightCounter ++;
				if(Light[i].useShadow) shadowCounter++;	
				break;
			
			// SPOT
			case 1:
			
				
				if(Light[i].useShadow) 	shadow = 0;
				else 					shadow = 1;
			
				viewPosition = mul(PosW, LightMatrices[i].VP);
					
				projectTexCoord.x =  viewPosition.x / viewPosition.w / 2.0f + 0.5f;
		   		projectTexCoord.y = -viewPosition.y / viewPosition.w / 2.0f + 0.5f;			
				projectTexCoord.z =  viewPosition.z / viewPosition.w / 2.0f + 0.5f;
			
				float3 falloffSpot = 0;
			
				if((saturate(projectTexCoord.x) == projectTexCoord.x) && (saturate(projectTexCoord.y) == projectTexCoord.y)
				&& (saturate(projectTexCoord.z) == projectTexCoord.z)){
					
					uint tXS,tYS,mS;
					lightMap.GetDimensions(tXS,tYS,mS);
					if(tXS+tYS > 4) falloffSpot = lightMap.SampleLevel(g_samLinear, float3(projectTexCoord.xy, spotLightCount), 0 ).rgb;
					else if(tXS+tYS < 4) falloffSpot = smoothstep(1,0,saturate(length(.5-projectTexCoord.xy)*2));

					if(Light[i].useShadow){
						doShadow(shadow, Light[i].shadowType, lightDist, Light[i%num].lightRange, projectTexCoord, viewPosition, i, shadowCounter, N, L);
					}
			
				} else {
					shadow = 1;
				}
				
				
			
				#ifdef doShadowPOM
						if(Light[i].shadowPOM > 0 && Material[texID].POM && useTex[texID]) shadow = min(shadow, parallaxSoftShadowMultiplier(-L, TexCd.xy, tbn, texID, i,Light[i].shadowPOM).xxxx);
				#endif
			
				attenuation = Light[i].lAtt0 * falloff;
				finalLight += cookTorrance(V, L, N, albedo.xyz, Light[i].Color.rgb,
				shadow.x, falloffSpot, lightDist, Material[texID].sssAmount, Material[texID].sssFalloff, F0, attenuation, roughness, metallic, ao, iridescenceColor, texID);

				if(Light[i].useShadow) shadowCounter++;	
				lightCounter ++;
				spotLightCount++;
				break;
	
			// POINT
			case 2:
			
				shadow = 0;
			
				if(Light[i].useShadow){
					
					for(int p = 0; p < 6; p++){
						
						float4x4 LightPcropp = LightMatrices[p + lightCounter].P;
				
						LightPcropp._m00 = 1;
						LightPcropp._m11 = 1;
						
						float4x4 LightVPNew = mul(LightMatrices[p + lightCounter].V,LightPcropp);
						
						viewPosition = mul(PosW, LightVPNew);
						
						projectTexCoord.x =  viewPosition.x / viewPosition.w / 2.0f + 0.5f;
			   			projectTexCoord.y = -viewPosition.y / viewPosition.w / 2.0f + 0.5f;
						projectTexCoord.z =  viewPosition.z / viewPosition.w / 2.0f + 0.5f;
					
						if((saturate(projectTexCoord.x) == projectTexCoord.x) && (saturate(projectTexCoord.y) == projectTexCoord.y)
						&& (saturate(projectTexCoord.z) == projectTexCoord.z)){
							
							viewPosition = mul(PosW, LightMatrices[p + lightCounter].VP);
							
							projectTexCoord.x =  viewPosition.x / viewPosition.w / 2.0f + 0.5f;
				   			projectTexCoord.y = -viewPosition.y / viewPosition.w / 2.0f + 0.5f;
							projectTexCoord.z =  viewPosition.z / viewPosition.w / 2.0f + 0.5f;
							
							doShadow(shadow, Light[i].shadowType, lightDist, Light[i%num].lightRange, projectTexCoord, viewPosition, i, p+shadowCounter, N, L);

						}
					}
					
							#ifdef doShadowPOM
								if(Light[i].shadowPOM > 0 && Material[texID].POM && useTex[texID]) shadow = min(shadow, parallaxSoftShadowMultiplier(-L, TexCd.xy, tbn, texID, i,Light[i].shadowPOM).xxxx);
							#endif
					
							float attenuation = Light[i].lAtt0 * falloff;
							finalLight += cookTorrance(V, L, N, albedo.xyz, Light[i].Color.rgb,
							shadow.x, 1.0, lightDist, Material[texID].sssAmount, Material[texID].sssFalloff, F0, attenuation, roughness, metallic, ao, iridescenceColor, texID);
				
							shadowCounter += 6;
							lightCounter  += 6;
				} else {
							shadow = 1;
							#ifdef doShadowPOM
								if(Light[i].shadowPOM > 0 && Material[texID].POM) shadow = min(shadow, parallaxSoftShadowMultiplier(-L, TexCd.xy, tbn, texID, i,Light[i].shadowPOM).xxxx);
							#endif
					
						    float attenuation = Light[i].lAtt0 * falloff;
							finalLight += cookTorrance(V, L, N, albedo.xyz, Light[i].Color.rgb,
							shadow, 1, lightDist, Material[texID].sssAmount, Material[texID].sssFalloff, F0, attenuation, roughness, metallic, ao, iridescenceColor, texID);
			
				}	
			
			

			break;			
		}	
	}
	
	

	///////////////////////////////////////////////////////////////////////////
	// FORWAD PLUS POINT LIGHTS
	///////////////////////////////////////////////////////////////////////////
	
	
	if(useForwardPlus){
		// Get the index of the current pixel in the light grid.
	    uint2 tileIndex = uint2( floor(pos.xy / BLOCK_SIZE));
		uint  flatIndex = tileIndex.x + ( tileIndex.y * numThreadGroupsX );
	
	    // Get the start position and offset of the light in the light index list.
	    uint startOffset = LightGrid[flatIndex].x;
	    uint lightCount  = LightGrid[flatIndex].y;
		
		for ( uint j = 0; j < lightCount; j++ )
		    {
		    
	
		    	
		    float iterator = LightIndexList[startOffset + j];
		    lightToObject = LightFWP[iterator].position.xyz - PosW.xyz;
		    	
			L = normalize(lightToObject);
			lightDist = length(lightToObject);
		    falloff = smoothstep(0,LightFWP[iterator].lAtt1,(LightFWP[iterator].range-lightDist));
		    	
		    if(lightDist > LightFWP[iterator].range) continue;
		    	
		    	  float attenuation = LightFWP[iterator].lAtt0 * falloff;
						finalLight += cookTorrance(V, L, N, albedo.xyz, LightFWP[iterator].color.rgb,
						1, 1, lightDist, Material[texID].sssAmount, Material[texID].sssFalloff, F0, attenuation, roughness, metallic, ao, iridescenceColor, texID);
	
		  }
	}
	
	
	
	///////////////////////////////////////////////////////////////////////////
	// IMAGE BASED LIGHTING
	///////////////////////////////////////////////////////////////////////////
	float planarMask = 1;
	#ifdef doPlanarReflections
		#ifndef Deferred
			if(PlanarID == ID) finalLight += PLANARREFLECTION(PosW, N, V, F0, albedo, roughness, ao, metallic, TexCd, ID, planarMask);
		#endif
	#endif
	#ifdef doIBL
		finalLight += IBL(N, V, F0, albedo, iridescenceColor, roughness, metallic, ao, texID, planarMask);
	#endif
	#ifdef doIridescence
		#ifndef doIBL
			if(Material[texID].Iridescence) finalLight += IRIDESCENCE(N, V, F0, albedo, iridescenceColor, roughness, ao, metallic );
		#endif
	#endif
	#ifdef doGlobalLight
		#ifndef doIBL
			finalLight +=  GLOBALLIGHT(N, V, F0, albedo, roughness, ao, metallic);
		#endif
	#endif
	
	///////////////////////////////////////////////////////////////////////////
	// EMISSIVE LIGHTING
	///////////////////////////////////////////////////////////////////////////
	
	#ifdef doControlTextures
		if(Material[texID].sampleEmissive){
			finalLight.rgb += saturate(Material[texID].Emissive.rgb + EmissiveTex.SampleLevel(g_samLinear, float3(TexCd.xy, texID),0).rgb);
		} else {
			finalLight.rgb += saturate( Material[texID].Emissive.rgb);
		}
	#else
		finalLight.rgb += saturate( Material[texID].Emissive.rgb);
	#endif
	
	#ifdef doToneMap
	finalLight.rgb = ACESFitted(finalLight.rgb);
	#endif
	
	
	return clamp(float4(finalLight,Alpha*albedo.a),0,3);
}	


float4 PS_PBR(vs2ps In, float4 pos : SV_POSITION): SV_Target
{	
	#ifdef doShadowPOM
		return doLighting(In.PosW, In.NormW, In.TexCd, pos.xy, 1);
	#else	
		return doLighting(In.PosW, In.NormW, In.TexCd, pos.xy);
	#endif
}

float4 PS_PBR_Bump(vs2psBump In, float4 pos : SV_POSITION): SV_Target
{	
	uint texID = ID%mCount;
	#ifdef doPOM
	if(Material[texID].POM && useTex[texID]){
		parallaxOcclusionMapping(In.TexCd.xy, In.PosW.xyz, normalize(tVI[3].xyz - In.PosW.xyz), float3x3(In.tangent,In.binormal,In.NormW.xyz),texID);
	}
	#endif
	
	float3 bumpMap = float3(0,0,0);
	
	#ifdef doControlTextures
	if(Material[texID].sampleNormal && useTex[texID]) bumpMap = normalTex.Sample(g_samLinear,float3(In.TexCd.xy, texID)).rgb;
	if(length(bumpMap) > 0) bumpMap = (bumpMap * 2.0f) - 1.0f;
	#endif
	
	float3 Nb = normalize(In.NormW.xyz + (bumpMap.x * In.tangent*Material[texID].TangentDir + bumpMap.y * In.binormal)*Material[texID].bumpy);
	
	#ifdef doShadowPOM
		return doLighting(In.PosW, Nb, In.TexCd, pos.xy, float3x3(In.tangent, In.binormal,In.NormW));
	#else	
		return doLighting(In.PosW, Nb, In.TexCd, pos.xy);
	#endif

}

float4 PS_PBR_Bump_AutoTNB(vs2ps In, float4 pos : SV_POSITION): SV_Target
{	
	uint texID = ID%mCount;
	// compute derivations of the world position
	float3 p_dx = ddx(In.PosW.xyz);
	float3 p_dy = ddy(In.PosW.xyz);
	// compute derivations of the texture coordinate
	float2 tc_dx = ddx(In.TexCd.xy);
	float2 tc_dy = ddy(In.TexCd.xy);
	// compute initial tangent and bi-tangent
	float3 t = normalize( tc_dy.y * p_dx - tc_dx.y * p_dy );
	float3 b = normalize( tc_dy.x * p_dx - tc_dx.x * p_dy ); // sign inversion
	// get new tangent from a given mesh normal
//	float3 n = normalize(In.NormW);
	float3 x = cross(In.NormW, t);
	t = cross(x, In.NormW);
	t = normalize(t);
	// get updated bi-tangent
	x = cross(b, In.NormW);
	b = cross(In.NormW, x);
	b = normalize(b);
	
	
	#ifdef doControlTextures
	#ifdef doPOM
	if(Material[texID].POM && useTex[texID]){
		parallaxOcclusionMapping(In.TexCd.xy, In.PosW.xyz, normalize(tVI[3].xyz - In.PosW.xyz), float3x3(t,b,In.NormW.xyz),texID);
	}
	#endif
	#endif
	
	float3 bumpMap = float3(0,0,0);

	#ifdef doControlTextures
	if(Material[texID].sampleNormal && useTex[texID]) bumpMap = normalTex.Sample(g_samLinear,float3(In.TexCd.xy, texID)).rgb;
	if(length(bumpMap) > 0) bumpMap = (bumpMap * 2.0f) - 1.0f;
	#endif
	
	float3 Nb = normalize(In.NormW.xyz + (bumpMap.x * (t*Material[texID].TangentDir) + bumpMap.y * (b)) * Material[texID].bumpy);

	#ifdef doShadowPOM
		return doLighting(In.PosW, Nb, In.TexCd, pos.xy, float3x3(t, b, Nb));
	#else	
		return doLighting(In.PosW, Nb, In.TexCd, pos.xy);
	#endif
}


technique10 PBR
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_PBR() ) );
	}
}

technique10 PBR_Bump
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS_Bump() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_PBR_Bump() ) );
	}
}

technique10 PBR_Bump_AutoTNB
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_PBR_Bump_AutoTNB() ) );
	}
}