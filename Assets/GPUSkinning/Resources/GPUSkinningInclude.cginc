﻿#ifndef GPUSKINNING_INCLUDE
#define GPUSKINNING_INCLUDE

uniform sampler2D _GPUSkinning_TextureMatrix;
uniform float _GPUSkinning_NumPixelsPerFrame;
uniform float2 _GPUSkinning_TextureSize;

UNITY_INSTANCING_CBUFFER_START(GPUSkinningProperties0)
	UNITY_DEFINE_INSTANCED_PROP(float, _GPUSkinning_ClipLength)
	UNITY_DEFINE_INSTANCED_PROP(float, _GPUSkinning_ClipFPS)
	UNITY_DEFINE_INSTANCED_PROP(float, _GPUSkinning_Time)
	UNITY_DEFINE_INSTANCED_PROP(float, _GPUSkinning_PixelSegmentation)
	UNITY_DEFINE_INSTANCED_PROP(float, _GPUSkinning_RootMotionEnabled)
UNITY_INSTANCING_CBUFFER_END

UNITY_INSTANCING_CBUFFER_START(GPUSkinningProperties1)
	UNITY_DEFINE_INSTANCED_PROP(float4x4, _GPUSkinning_RootMotionInv)
UNITY_INSTANCING_CBUFFER_END

inline float4 indexToUV(int index)
{
	int row = (int)(index / _GPUSkinning_TextureSize.x);
	int col = index - row * _GPUSkinning_TextureSize.x;
	return float4(col / _GPUSkinning_TextureSize.x, row / _GPUSkinning_TextureSize.y, 0, 0);
}

inline float4x4 getMatrix(int frameStartIndex, float boneIndex)
{
	int matStartIndex = frameStartIndex + boneIndex * 3;
	float4 row0 = tex2Dlod(_GPUSkinning_TextureMatrix, indexToUV(matStartIndex));
	float4 row1 = tex2Dlod(_GPUSkinning_TextureMatrix, indexToUV(matStartIndex + 1));
	float4 row2 = tex2Dlod(_GPUSkinning_TextureMatrix, indexToUV(matStartIndex + 2));
	float4 row3 = float4(0, 0, 0, 1);
	float4x4 mat = float4x4(row0, row1, row2, row3);
	return mat;
}

inline int getFrameStartIndex()
{
	float time = UNITY_ACCESS_INSTANCED_PROP(_GPUSkinning_Time);
	float fps = UNITY_ACCESS_INSTANCED_PROP(_GPUSkinning_ClipFPS);
	float length = UNITY_ACCESS_INSTANCED_PROP(_GPUSkinning_ClipLength);
	float segment = UNITY_ACCESS_INSTANCED_PROP(_GPUSkinning_PixelSegmentation);
	int frameIndex = (int)fmod(time * fps, length * fps);
	int frameStartIndex = segment + frameIndex * _GPUSkinning_NumPixelsPerFrame;
	return frameStartIndex;
}

#define rootMotionEnabled UNITY_ACCESS_INSTANCED_PROP(_GPUSkinning_RootMotionEnabled) > 0

#define rootMotionInv UNITY_ACCESS_INSTANCED_PROP(_GPUSkinning_RootMotionInv)

#define textureMatrix(uv2, uv3) int frameStartIndex = getFrameStartIndex(); \
								float4x4 mat0 = getMatrix(frameStartIndex, uv2.x); \
								float4x4 mat1 = getMatrix(frameStartIndex, uv2.z); \
								float4x4 mat2 = getMatrix(frameStartIndex, uv3.x); \
								float4x4 mat3 = getMatrix(frameStartIndex, uv3.z);

inline float4 skin1(float4 vertex, float4 uv2, float4 uv3)
{
	textureMatrix(uv2, uv3);
	if (rootMotionEnabled)
	{
		return mul(rootMotionInv, mul(mat0, vertex)) * uv2.y;
	}
	else
	{
		return mul(mat0, vertex) * uv2.y;
	}
}

inline float4 skin2(float4 vertex, float4 uv2, float4 uv3)
{
	textureMatrix(uv2, uv3);
	if (rootMotionEnabled)
	{
		float4x4 rootInv = rootMotionInv;
		return
			mul(rootInv, mul(mat0, vertex)) * uv2.y +
			mul(rootInv, mul(mat1, vertex)) * uv2.w;
	}
	else
	{
		return
			mul(mat0, vertex) * uv2.y +
			mul(mat1, vertex) * uv2.w;
	}
}

inline float4 skin4(float4 vertex, float4 uv2, float4 uv3)
{
	textureMatrix(uv2, uv3);
	if (rootMotionEnabled)
	{
		float4x4 rootInv = rootMotionInv;
		return
			mul(rootInv, mul(mat0, vertex)) * uv2.y +
			mul(rootInv, mul(mat1, vertex)) * uv2.w +
			mul(rootInv, mul(mat2, vertex)) * uv3.y +
			mul(rootInv, mul(mat3, vertex)) * uv3.w;
	}
	else
	{
		return
			mul(mat0, vertex) * uv2.y +
			mul(mat1, vertex) * uv2.w +
			mul(mat2, vertex) * uv3.y +
			mul(mat3, vertex) * uv3.w;
	}
}

#endif