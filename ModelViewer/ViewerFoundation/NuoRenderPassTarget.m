//
//  NuoRenderTarget.m
//  ModelViewer
//
//  Created by middleware on 11/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoRenderPassTarget.h"



@interface NuoRenderPassTarget()

@property (nonatomic, strong) id<MTLTexture> sampleTexture;

@end




@implementation NuoRenderPassTarget
{
    id<MTLRenderCommandEncoder> _renderPassEncoder;
    size_t _renderPassEncoderCount;
}


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _targetPixelFormat = MTLPixelFormatBGRA8Unorm;
        _renderPassEncoderCount = 0;
    }
    return self;
}


- (BOOL)isTextMatchDrawableSize:(id<MTLTexture>)texture
{
    return texture.width == self.drawableSize.width &&
           texture.height == self.drawableSize.height;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    _drawableSize = drawableSize;
    
    [self makeTextures];
}


- (void)setSampleCount:(NSUInteger)sampleCount
{
    if (_sampleCount == sampleCount)
        return;
    
    _sampleCount = sampleCount;
    
    if (_drawableSize.width > 0 && _drawableSize.height > 0)
        [self makeTextures];
}


- (void)makeTextures
{
    assert(_name);
    
    if (![self isTextMatchDrawableSize:_depthTexture] ||
        _depthTexture.sampleCount != _sampleCount)
    {
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                        width:[self drawableSize].width
                                                                                       height:[self drawableSize].height
                                                                                    mipmapped:NO];
        desc.sampleCount = _sampleCount;
        desc.textureType = (_sampleCount == 1) ? MTLTextureType2D : MTLTextureType2DMultisample;
        desc.resourceOptions = MTLResourceStorageModePrivate;
        desc.usage = MTLTextureUsageRenderTarget;
        
        self.depthTexture = [_device newTextureWithDescriptor:desc];
        
        NSString* name = [[NSString alloc] initWithFormat:@"%@ - %@", _name, @"depth sample"];
        [self.sampleTexture setLabel:name];
        
        MTLTextureDescriptor *sampleDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_targetPixelFormat
                                                                                              width:[self drawableSize].width
                                                                                             height:[self drawableSize].height
                                                                                          mipmapped:NO];
        
        if (_manageTargetTexture)
        {
            sampleDesc.sampleCount = 1;
            sampleDesc.textureType = MTLTextureType2D;
            sampleDesc.resourceOptions = _sharedTargetTexture ? MTLResourceStorageModeManaged : MTLResourceStorageModePrivate;
            sampleDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
            
            _targetTexture = [_device newTextureWithDescriptor:sampleDesc];
            
            NSString* name = [[NSString alloc] initWithFormat:@"%@ - %@", _name, @"target"];
            [_targetTexture setLabel:name];
        }
    }
    
    if (_sampleCount > 1 && (![self isTextMatchDrawableSize:_sampleTexture] ||
                             _sampleTexture.sampleCount != _sampleCount))
        
    {
        MTLTextureDescriptor *sampleDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_targetPixelFormat
                                                                                              width:[self drawableSize].width
                                                                                             height:[self drawableSize].height
                                                                                          mipmapped:NO];
        
        sampleDesc.sampleCount = _sampleCount;
        sampleDesc.textureType = MTLTextureType2DMultisample;
        sampleDesc.resourceOptions = MTLResourceStorageModePrivate;
        sampleDesc.usage = MTLTextureUsageRenderTarget;
        
        self.sampleTexture = [_device newTextureWithDescriptor:sampleDesc];
        
        NSString* sampleName = [[NSString alloc] initWithFormat:@"%@ - %@", _name, @"sample"];
        [self.sampleTexture setLabel:sampleName];
    }
}



- (id<MTLRenderCommandEncoder>)retainRenderPassEndcoder:(id<MTLCommandBuffer>)commandBuffer;
{
    if (_renderPassEncoder)
    {
        _renderPassEncoderCount += 1;
        return _renderPassEncoder;
    }
    
    MTLRenderPassDescriptor *passDescriptor = [self currentRenderPassDescriptor];
    _renderPassEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    _renderPassEncoderCount = 1;
    
    return _renderPassEncoder;
}



- (void)releaseRenderPassEndcoder
{
    assert(_renderPassEncoderCount > 0);
    
    _renderPassEncoderCount -= 1;
    if (_renderPassEncoderCount == 0)
    {
        [_renderPassEncoder endEncoding];
        _renderPassEncoder = nil;
    }
}



- (MTLRenderPassDescriptor *)currentRenderPassDescriptor
{
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    if (!_targetTexture)
        return nil;
    
    passDescriptor.colorAttachments[0].texture = (_sampleCount == 1) ? _targetTexture : _sampleTexture;
    passDescriptor.colorAttachments[0].clearColor = _clearColor;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[0].storeAction = (_sampleCount == 1) ? MTLStoreActionStore : MTLStoreActionMultisampleResolve;
    if (_sampleCount > 1)
        passDescriptor.colorAttachments[0].resolveTexture = _targetTexture;
    
    passDescriptor.depthAttachment.texture = self.depthTexture;
    passDescriptor.depthAttachment.clearDepth = 1.0;
    passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    passDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    
    return passDescriptor;
}





@end
