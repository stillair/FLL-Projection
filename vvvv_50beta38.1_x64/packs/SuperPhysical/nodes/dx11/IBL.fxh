static const half3 wavelength[3] =
{
	{ 1, 0, 0},
	{ 0, 1, 0},
	{ 0, 0, 1},
};

float3 IBL(float3 N, float3 V, float3 F0, float4 albedo, float3 iridescenceColor, float roughness, float metallic, float ao, uint texID, float planarMask){
	
	///////////////////////////////////
	//  IBL
	//////////////////////////////////
	

	float3 reflColor = float3(0,0,0);
	float3 refrColor = float3(0,0,0);
	float3 IBL = float3(0,0,0);

	float3 kS  = fresnelSchlickRoughness(max(dot(N, V), 0.0), F0,roughness);
	float3 kD  = 1.0 - kS;
		   kD *= 1.0 - metallic;
	float2 envBRDF  = brdfLUT.Sample(g_samLinearIBL, float2(max(dot(N, V), 0.0),roughness)*float2(1,-1)).rg;
	
	float3 reflVect = -reflect(V,N);
	float3 reflVecNorm = N;
	
	
			
	IBL = cubeTexIrradiance.Sample(g_samLinear,reflVecNorm).rgb;
	IBL  = IBL * albedo.xyz;
	
	float3 refl = cubeTexRefl.SampleLevel(g_samLinearIBL,reflVect,roughness*MAX_REFLECTION_LOD).rgb;
	
	#ifdef doIridescence
	if(Material[texID].Iridescence){
	  refl *= iridescenceColor * (kS * envBRDF.x + envBRDF.y);
	} else {
		refl *= (kS * envBRDF.x + envBRDF.y);
	}
	#else
		refl *= (kS * envBRDF.x + envBRDF.y);
	#endif
	
	#ifdef doRefraction
	if(Material[texID].Refraction.x){
		float3 refrVect;
	    for(int r=0; r<3; r++) {
	    	refrVect = refract(-V, N , Material[texID].Refraction.xyz[r]);
	    	refrColor += cubeTexRefl.SampleLevel(g_samLinearIBL,refrVect,roughness*MAX_REFLECTION_LOD).rgb * wavelength[r];
		}
		refrColor *= 1 - (kS * envBRDF.x + envBRDF.y);
		
		IBL *= roughness;
	}
	#endif
	

	IBL  = saturate( (IBL * iblIntensity.x + refrColor) * kD + refl * iblIntensity.y) * ao;
	
	#ifdef doRefraction
	if(Material[texID].Refraction.x){
		IBL += GlobalReflectionColor.rgb;
	}
	#endif
	
		float GlobalReflConstant = 1.75;
		#ifdef doGlobalLight
			#ifdef doPlanarReflections
				#ifndef Deferred
					if(PlanarID == ID){
						if(dot(planeNormal[0], V) < 0){
							GlobalReflConstant -= planarIntensity;
							refl *= planarMask;
						} 
					}
				#endif
			#endif
		
		IBL +=  GlobalDiffuseColor.rgb * albedo.rgb * kD * ao + GlobalReflectionColor.rgb *(kS * envBRDF.x + envBRDF.y) * ao * GlobalReflConstant * iridescenceColor;
		
		#endif

	return IBL;
}
