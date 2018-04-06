
#import <Metal/Metal.h>

#include "NuoMeshOptions.h"
#include "NuoMeshRotation.h"
#include "NuoUniforms.h"




/**
 *
 
     NuoRenderPass
        NuoShadowMapRenderer
        NuoDeferredRenderer
        NuoRenderPipelinePass
            NuoMeshSceneRenderPass
                NuoScreenSpaceRenderer
                (App Classes ...)
     
 */




@class NuoMeshBounds;


@interface NuoMesh : NSObject


@property (nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic, strong) id<MTLRenderPipelineState> screenSpacePipelineState;
@property (nonatomic, strong) id<MTLRenderPipelineState> shadowPipelineState;
@property (nonatomic, strong) id<MTLDepthStencilState> depthStencilState;

@property (nonatomic, readonly, assign) float smoothTolerance;
@property (nonatomic, assign) BOOL smoothConservative;



@property (nonatomic, assign) NSUInteger sampleCount;
@property (nonatomic, assign) BOOL shadowOptionPCSS;
@property (nonatomic, assign) BOOL shadowOptionPCF;



// mesh rotation in model coordinate, around given axis.
// better for script-based rotation
//
@property (nonatomic, strong) NuoMeshRotation* rotation;

// mesh transform about the poise (rotation around model center).
// note this transform may include a slight translation before rotation
// because the model need to be centered (usually around its bounding box)
//
@property (nonatomic, assign) matrix_float4x4 transformPoise;

// mesh transform about the translate in the world coordinate
//
@property (nonatomic, assign) matrix_float4x4 transformTranslate;

// all (prior view-matrix) mesh-transforms concatenate and passed to GPU
//
@property (nonatomic, strong) NSArray<id<MTLBuffer>>* transformBuffers;



// unified material (common to all vertices)
//
@property (nonatomic, assign, readonly) BOOL hasUnifiedMaterial;
@property (nonatomic, assign) float unifiedOpacity;

@property (nonatomic, assign) BOOL reverseCommonCullMode;


@property (nonatomic, readonly) id<MTLBuffer> vertexBuffer;
@property (nonatomic, readonly) id<MTLBuffer> indexBuffer;

@property (nonatomic, strong) NuoMeshBounds* boundsLocal;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL cullEnabled;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                  withVerticesBuffer:(void*)buffer withLength:(size_t)length
                         withIndices:(void*)indices withLength:(size_t)indicesLength;

// get a clone of the current mesh for debugging purpose.
// the cloned version shall share most of GPU resources.
//
- (instancetype)cloneForMode:(NuoMeshModeShaderParameter)mode;

// used to implement the "cloneForMode" through the class hierachy
//
- (void)shareResourcesFrom:(NuoMesh*)mesh;

- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor;

- (void)makePipelineScreenSpaceStateWithVertexShader:(NSString*)vertexShader
                                  withFragemtnShader:(NSString*)fragmentShader;
- (void)makePipelineScreenSpaceStateWithVertexShader:(NSString*)vertexShader
                                  withFragemtnShader:(NSString*)fragmentShader
                                       withConstants:(MTLFunctionConstantValues*)constants;

- (void)makePipelineShadowState:(NSString*)vertexShadowShader;
- (void)makePipelineState:(MTLRenderPipelineDescriptor*)pipelineDescriptor;
- (void)makeDepthStencilState;

- (void)makeGPUStates;


- (void)setRawModel:(void*)model;
- (NSString*)modelName;
- (void)smoothWithTolerance:(float)tolerance;


- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform;
- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index;
- (void)drawScreenSpace:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index;
- (void)drawShadow:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index;
- (BOOL)hasTransparency;
- (void)setTransparency:(BOOL)transparent;

- (NuoMeshBounds*)worldBounds:(matrix_float4x4)transform;

- (void)centerMesh;

/**
 *  this is expensive operation as private buffers are supposed not to be updated frequently
 */
+ (void)updatePrivateBuffer:(id<MTLBuffer>)buffer
           withCommandQueue:(id<MTLCommandQueue>)commandQueue
                   withData:(void*)data withSize:(size_t)size;


@end


#if __cplusplus

#include <memory>


class NuoModelBase;
class NuoModelOption;

NuoMesh* CreateMesh(const NuoModelOption& options,
                    id<MTLCommandQueue> commandQueue,
                    const std::shared_ptr<NuoModelBase> model);

#endif


