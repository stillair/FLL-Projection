#define SBUFFER_FXH

////////////////////////////////////////////////////////////////
//
//             Structured Buffer Helpers
//
////////////////////////////////////////////////////////////////

// Buffersize
uint sbSize (StructuredBuffer<float> sBuffer)
{
	uint count, dummy;	
	sBuffer.GetDimensions(count,dummy);
	return count;
}

uint sbSize (StructuredBuffer<float2> sBuffer)
{
	uint count, dummy;	
	sBuffer.GetDimensions(count,dummy);
	return count;
}

uint sbSize (StructuredBuffer<float3> sBuffer)
{
	uint count, dummy;	
	sBuffer.GetDimensions(count,dummy);
	return count;
}

uint sbSize (StructuredBuffer<float4> sBuffer)
{
	uint count, dummy;	
	sBuffer.GetDimensions(count,dummy);
	return count;
}

uint sbSize (StructuredBuffer<float4x4> sBuffer)
{
	uint count, dummy;	
	sBuffer.GetDimensions(count,dummy);
	return count;
}

uint sbSize (StructuredBuffer<uint> sBuffer)
{
	uint count, dummy;	
	sBuffer.GetDimensions(count,dummy);
	return count;
}

// Safe Buffer Load with Defualt value

float sbLoad(StructuredBuffer<float> sBuffer, float defaultValue, uint dtid)
{
	float value = defaultValue;
	uint count = sbSize(sBuffer);
	if (count > 0) value = sBuffer[dtid.x % count];
	return value;
}

float2 sbLoad(StructuredBuffer<float2> sBuffer, float2 defaultValue, uint dtid)
{
	float2 value = defaultValue;
	uint count = sbSize(sBuffer);
	if (count > 0) value = sBuffer[dtid.x % count];
	return value;
}

float3 sbLoad(StructuredBuffer<float3> sBuffer, float3 defaultValue, uint dtid)
{
	float3 value = defaultValue;
	uint count = sbSize(sBuffer);
	if (count > 0) value = sBuffer[dtid.x % count];
	return value;
}

float4 sbLoad(StructuredBuffer<float4> sBuffer, float4 defaultValue, uint dtid)
{
	float4 value = defaultValue;
	uint count = sbSize(sBuffer);
	if (count > 0) value = sBuffer[dtid.x % count];
	return value;
}

float4x4 sbLoad(StructuredBuffer<float4x4> sBuffer, float4x4 defaultValue, uint dtid)
{
	float4x4 value = defaultValue;
	uint count = sbSize(sBuffer);
	if (count > 0) value = sBuffer[dtid.x % count];
	return value;
}

uint sbLoad(StructuredBuffer<uint> sBuffer, uint defaultValue, uint dtid)
{
	uint value = defaultValue;
	uint count = sbSize(sBuffer);
	if (count > 0) value = sBuffer[dtid.x % count];
	return value;
}


////////////////////////////////////////////////////////////////
//EOF