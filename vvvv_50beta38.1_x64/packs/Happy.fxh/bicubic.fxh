////////////////////////////////////////////////////////////////
//
//             Bicubic sampling
//
////////////////////////////////////////////////////////////////

float BSplineCubic(float p1, float p2, float p3, float p4, float range) 
{
    float mu = frac(range);
    float a0 = p4 - p3*3 + p2*3 - p1;
    float a1 = p3*3 - p2*6 + p1*3.;
  float a2 = p3*3 - p1*3;
    float a3 = p3 + p2*4 + p1;
  
  return (a3+mu*(a2+mu*(a1+mu*a0)))/6.;
}

float2 BSplineCubic(float2 p1, float2 p2, float2 p3, float2 p4, float range) 
{
    float mu = frac(range);
    float2 a0 = p4 - p3*3 + p2*3 - p1;
    float2 a1 = p3*3 - p2*6 + p1*3.;
  float2 a2 = p3*3 - p1*3;
    float2 a3 = p3 + p2*4 + p1;
  
  return (a3+mu*(a2+mu*(a1+mu*a0)))/6.;
}

float3 BSplineCubic(float3 p1, float3 p2, float3 p3, float3 p4, float range) 
{
    float mu = frac(range);
    float3 a0 = p4 - p3*3 + p2*3 - p1;
    float3 a1 = p3*3 - p2*6 + p1*3.;
  float3 a2 = p3*3 - p1*3;
    float3 a3 = p3 + p2*4 + p1;
  
  return (a3+mu*(a2+mu*(a1+mu*a0)))/6.;
}

struct SplinePosTan3
{
  float3 Pos;
  float3 Tang;
};

SplinePosTan3 BSplineCubic3PT(float3 p1, float3 p2, float3 p3, float3 p4, float range) 
{
  SplinePosTan3 Out = (SplinePosTan3)0;

    float mu = frac(range);
    float3 a0 = p4 - p3*3 + p2*3 - p1;
    float3 a1 = p3*3 - p2*6 + p1*3.;
  float3 a2 = p3*3 - p1*3;
    float3 a3 = p3 + p2*4 + p1;
  
  Out.Pos = (a3+mu*(a2+mu*(a1+mu*a0)))/6.;
  Out.Tang = normalize((mu*(2*a0*mu+a1)+mu*(a0*mu+a1)+a2)/6.);
  return Out;
}


////////////////////////////////////////////////////////////////
//
//             Volume sampling wip
//
////////////////////////////////////////////////////////////////

  float hiQSample(float3 uvw, Texture3D tex, SamplerState s, float smooth) 
  {
     float  invVolSize = 1.0/64.0;
    // float3 uvw2 = floor(uvw * NOISE_LATTICE_SIZE) * INV_LATTICE_SIZE;
      float3 t    = uvw;
      t = lerp(uvw, t*t*(3 - 2*t), smooth);
      float2 d = float2( invVolSize, 0 );
    

        // the 8-lookup version... (SLOW)
        float4 f1 = float4( tex.SampleLevel(s, uvw + d.xxx, 0).x, 
                            tex.SampleLevel(s, uvw + d.yxx, 0).x, 
                            tex.SampleLevel(s, uvw + d.xyx, 0).x, 
                            tex.SampleLevel(s, uvw + d.yyx, 0).x );
        float4 f2 = float4( tex.SampleLevel(s, uvw + d.xxy, 0).x, 
                            tex.SampleLevel(s, uvw + d.yxy, 0).x, 
                            tex.SampleLevel(s, uvw + d.xyy, 0).x, 
                            tex.SampleLevel(s, uvw + d.yyy, 0).x );
        float4 f3 = lerp(f2, f1, t.zzzz);
        float2 f4 = lerp(f3.zw, f3.xy, t.yy);
        float  f5 = lerp(f4.y, f4.x, t.x);
  
      
      return f5;
  }


////////////////////////////////////////////////////////////////
//
//             Texture sampling
//
////////////////////////////////////////////////////////////////
//texture size XY
float2 size_source;

float3 filter(float x)
{
  x = frac(x);
  float x2 = x*x;
  float x3 = x2*x;
  float w0 = (  -x3 + 3*x2 - 3*x + 1)/6.0;
  float w1 = ( 3*x3 - 6*x2       + 4)/6.0;
  float w2 = (-3*x3 + 3*x2 + 3*x + 1)/6.0;
  float w3 = x3/6;

  float h0 = 1 - w1/(w0+w1) + x;
  float h1 = 1 + w3/(w2+w3) - x;

  return float3(h0, h1, w0+w1);
}

float4 SampleBicubic(Texture2D tx, SamplerState s, float2 tex, float2 size_source)
{

//pixel size XY
  float2 pix = 1.0/size_source;

  //calc filter texture coordinates
  float2 w = tex*size_source-float2(0.5, 0.5);

  // fetch offsets and weights from filter function
  float3 hg_x = filter(-w.x);
  float3 hg_y = filter(-w.y);

  float2 e_x = {pix.x, 0};
  float2 e_y = {0, pix.y};

  // determine linear sampling coordinates
  float2 coord_source10 = tex + hg_x.x * e_x;
  float2 coord_source00 = tex - hg_x.y * e_x;
  float2 coord_source11 = coord_source10 + hg_y.x * e_y;
  float2 coord_source01 = coord_source00 + hg_y.x * e_y;
  coord_source10 = coord_source10 - hg_y.y * e_y;
  coord_source00 = coord_source00 - hg_y.y * e_y;

  // fetch four linearly interpolated inputs
  float4 tex_source00 = tx.Sample( s, coord_source00 );
  float4 tex_source10 = tx.Sample( s, coord_source10 );
  float4 tex_source01 = tx.Sample( s, coord_source01 );
  float4 tex_source11 = tx.Sample( s, coord_source11 );

  // weight along y direction
  tex_source00 = lerp( tex_source00, tex_source01, hg_y.z );
  tex_source10 = lerp( tex_source10, tex_source11, hg_y.z );

  // weight along x direction
  tex_source00 = lerp( tex_source00, tex_source10, hg_x.z );

  return tex_source00;
}

float4 LoadBicubic(Texture2D tx, float2 tex, float2 size_source)
{
  //calc filter texture coordinates
  float2 w = tex*size_source;

  // fetch offsets and weights from filter function
  float3 hg_x = filter(-w.x);
  float3 hg_y = filter(-w.y);

  float2 e_x = {1, 0};
  float2 e_y = {0, 1};

  // determine linear sampling coordinates
  float2 coord_source10 = tex + hg_x.x * e_x;
  float2 coord_source00 = tex - hg_x.y * e_x;
  float2 coord_source11 = coord_source10 + hg_y.x * e_y;
  float2 coord_source01 = coord_source00 + hg_y.x * e_y;
  coord_source10 = coord_source10 - hg_y.y * e_y;
  coord_source00 = coord_source00 - hg_y.y * e_y;

  // fetch four linearly interpolated inputs
  float4 tex_source00 = tx.Load(int3(floor(coord_source00), 0) );
  float4 tex_source10 = tx.Load(int3(floor(coord_source10), 0) );
  float4 tex_source01 = tx.Load(int3(floor(coord_source01), 0) );
  float4 tex_source11 = tx.Load(int3(floor(coord_source11), 0) );

  // weight along y direction
  tex_source00 = lerp( tex_source00, tex_source01, hg_y.z );
  tex_source10 = lerp( tex_source10, tex_source11, hg_y.z );

  // weight along x direction
  tex_source00 = lerp( tex_source00, tex_source10, hg_x.z );

  return tex_source00;
}

////////////////////////////////////////////////////////////////
//EOF
