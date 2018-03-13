//
//  NuoTextureMesh.m
//  ModelViewer
//
//  Created by middleware on 11/3/16.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoTextureMesh.h"
#import "NuoTextureBase.h"

struct TextureMixFragment
{
    float mixProportion;
};


@implementation NuoTextureMesh
{
    id<MTLBuffer> _textureMixBuffer;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue];
    
    if (self)
    {
        _textureMixBuffer = [commandQueue.device newBufferWithLength:sizeof(TextureMixFragment)
                                                             options:MTLResourceStorageModePrivate];
    }
    
    return self;
}


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat withSampleCount:(NSUInteger)sampleCount
{
    NSString* shaderName = _auxiliaryTexture ? @"fragment_texutre_mix" :
                                               @"fragment_texutre";
     
    [self makePipelineAndSampler:pixelFormat withFragementShader:shaderName
                 withSampleCount:sampleCount withBlendMode:kBlend_None];
}


- (void)setAuxiliaryProportion:(float)auxiliaryProportion
{
    _auxiliaryProportion = auxiliaryProportion;
    
    id<MTLBuffer> buffer = [self.commandQueue.device newBufferWithLength:sizeof(TextureMixFragment)
                                                                 options:MTLResourceOptionCPUCacheModeDefault];
    TextureMixFragment mixFragment;
    mixFragment.mixProportion = _auxiliaryProportion;
    memcpy(buffer.contents, &mixFragment, sizeof(TextureMixFragment));
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
    
    [encoder copyFromBuffer:buffer sourceOffset:0
                   toBuffer:_textureMixBuffer destinationOffset:0
                       size:sizeof(TextureMixFragment)];
    [encoder endEncoding];
    [commandBuffer commit];
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFragmentTexture:_modelTexture atIndex:0];
    if (_auxiliaryTexture)
    {
        [renderPass setFragmentTexture:_auxiliaryTexture atIndex:1];
        [renderPass setFragmentBuffer:_textureMixBuffer offset:0 atIndex:0];
    }
    
    [super drawMesh:renderPass indexBuffer:index];
}


@end
