//
//  OpenGLView.m
//  SphericalProjection (aka EquiRectangular Projection)
//
//  Created by mark lim pak mun on 10/12/2023.
//  Copyright © 2023 Incremental Innovation. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "OpenGLView.h"
#import "OGLShader.h"
#import "Model.h"
#import "VirtualCamera.h"

#define CheckGLError() { \
    GLenum err = glGetError(); \
    if (err != GL_NO_ERROR) { \
        printf("CheckGLError: %04x caught at %s:%u\n", err, __FILE__, __LINE__); \
    } \
}


@implementation OpenGLView
{
    OGLShader *sphereMappedShader;
    GLKTextureInfo *sphereMapTexInfo;
    
    Model *sphere;

    GLKMatrix4 _projectionMatrix;
    GLint _modelViewMatrixLoc;
    GLint _projectionMatrixLoc;
    GLint _equiRectangularMapLoc;
 
    CVDisplayLinkRef displayLink;
    double	  deltaTime;

    VirtualCamera *_camera;
}

- (id)initWithFrame:(NSRect)frameRect
{
    NSOpenGLPixelFormat *pf = [OpenGLView basicPixelFormat];
    self = [super initWithFrame:frameRect
                    pixelFormat:pf];
    if (self) {
        //NSLog(@"initWithFrame:%@", pf);
        NSOpenGLContext *glContext = [[NSOpenGLContext alloc] initWithFormat:pf
                                                                shareContext:nil];
        self.pixelFormat = pf;
        self.openGLContext = glContext;
        // This call should be made for OpenGL 3.2 or later shaders
        // to be compiled and linked w/o problems.
        [[self openGLContext] makeCurrentContext];
        CGSize size = CGSizeMake(frameRect.size.width, frameRect.size.height);
        _camera = [[VirtualCamera alloc] initWithScreenSize:size];
    }
    return self;
}

// seems ok to use NSOpenGLProfileVersion4_1Core
+ (NSOpenGLPixelFormat*)basicPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFADoubleBuffer,        // double buffered
        NSOpenGLPFADepthSize, 24,       // 24-bit depth buffer
        NSOpenGLPFAColorSize, 32,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        (NSOpenGLPixelFormatAttribute)0
    };
    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
}


- (void)prepareOpenGL
{
    //NSLog(@"prepareOpenGL");
    [super prepareOpenGL];

    sphere = [[Model alloc] initSphereWithRadius:1.0
                                  radialSegments:200
                                verticalSegments:200
                                   inwardNormals:YES
                                      hemisphere:NO];

    sphereMappedShader = [[OGLShader alloc] init];
    GLuint shaderIDs[2];
    shaderIDs[0] = [sphereMappedShader compile:@"SphericalProjection.vs"
                                    shaderType:GL_VERTEX_SHADER];
    shaderIDs[1] = [sphereMappedShader compile:@"SphericalProjection.fs"
                                    shaderType:GL_FRAGMENT_SHADER];
    [sphereMappedShader linkShaders:shaderIDs
                        shaderCount:2
                      deleteShaders:YES];

    glUseProgram(sphereMappedShader.program);
    _modelViewMatrixLoc = glGetUniformLocation(sphereMappedShader.program, "mvMatrix");
    _projectionMatrixLoc = glGetUniformLocation(sphereMappedShader.program, "projectionMatrix");
    //NSLog(@"%d %d", _modelViewMatrixLoc, _projectionMatrixLoc);

    _equiRectangularMapLoc = glGetUniformLocation(sphereMappedShader.program, "equiRectMap");
    CheckGLError();
    //NSLog(@"%d", _equiRectangularMapLoc);
    [self loadTextures];
    glCullFace(GL_BACK);
    CheckGLError();

    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    
    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void * _Nullable)(self));
    CVDisplayLinkStart(displayLink);
}

- (void)dealloc {
    CVDisplayLinkStop(displayLink);
}

- (CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime
{
    // deltaTime is unused in this bare bones demo, but here's how to calculate it using display link info
    // should be = 1/60
    deltaTime = 1.0 / (outputTime->rateScalar * (double)outputTime->videoTimeScale / (double)outputTime->videoRefreshPeriod);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay:YES];
    });
    return kCVReturnSuccess;
}

// This is the renderer output callback function. The displayLinkContext object
// can be a custom (C struct) object or Objective-C instance.
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                      const CVTimeStamp* now,
                                      const CVTimeStamp* outputTime,
                                      CVOptionFlags flagsIn,
                                      CVOptionFlags* flagsOut,
                                      void* displayLinkContext)
{
    CVReturn result = [(__bridge OpenGLView *)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (void)loadTextures
{
    glUseProgram(sphereMappedShader.program);
    NSError *outError = nil;
    // The resolution of the equirectangular image should be 2:1.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"smallRapeseed"
                                                     ofType:@"jpg"];
    NSDictionary *texOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:YES], GLKTextureLoaderGenerateMipmaps,
                                nil];
    sphereMapTexInfo = [GLKTextureLoader textureWithContentsOfFile:path
                                                     options:texOptions
                                                       error:&outError];
    if (outError != nil) {
        NSLog(@"Error loading equirectangular texture:%@", outError);
    }
    glUniform1i(_equiRectangularMapLoc, 0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, sphereMapTexInfo.name);

    glUseProgram(0);
}

// This method must be called periodically to ensure
// the camera's internal objects are updated.
- (void)updateCamera
{
    [_camera update:deltaTime];
}

// The rotating camera should be inside a sphere/dome
- (void)render
{
    [self updateCamera];
    CGLLockContext([[self openGLContext] CGLContextObj]);
    glClearColor(0.5, 0.5, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);

    GLKMatrix4 viewMatrix = _camera.viewMatrix;
    GLKMatrix4 modelMatrix = GLKMatrix4MakeWithQuaternion(_camera.orientation);
    // Prepare to render the object
    // Combine the camera's view matrix with its orientation matrix.
    GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix);
    // Remove the translation component of the model-view matrix.
    // The camera will be at the centre of the scene.
    modelViewMatrix.m30 = 0.0;
    modelViewMatrix.m31 = 0.0;
    modelViewMatrix.m32 = 0.0;
    glUseProgram(sphereMappedShader.program);
    glUniformMatrix4fv(_projectionMatrixLoc, 1, GL_FALSE, _projectionMatrix.m);
    // It is not necessary to combine the view and orientation matrices.
    // Just pass the orientation matrix will do.
    glUniformMatrix4fv(_modelViewMatrixLoc, 1, GL_FALSE, modelViewMatrix.m);
    glActiveTexture(GL_TEXTURE0);   // Texture unit 0
    glBindTexture(GL_TEXTURE_2D, sphereMapTexInfo.name);
    glClear(GL_DEPTH_BUFFER_BIT);
    [sphere render];
    glUseProgram(0);

    CGLUnlockContext([[self openGLContext] CGLContextObj]);
    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
}

// overridden method
-(void)reshape
{
    NSRect frame = [self frame];
    glViewport(0, 0, frame.size.width, frame.size.height);
    GLfloat aspectRatio = frame.size.height/frame.size.width;
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(50.0),
                                                 1.0f / aspectRatio,
                                                 0.1, 10.0);
    CGSize size = CGSizeMake(frame.size.width, frame.size.height);
    [_camera resizeWithSize:size];
}

// overridden method
- (void)drawRect:(NSRect)dirtyRect
{
    [self render];
}

// these methods may need to be overridden or key events will not be detected.
- (BOOL)acceptsFirstResponder
{
    return YES;
} // acceptsFirstResponder

- (BOOL)becomeFirstResponder
{
    return  YES;
} // becomeFirstResponder

- (BOOL)resignFirstResponder
{
    return YES;
} // resignFirstResponder


- (void)mouseDown:(NSEvent *)event
{
    NSPoint mouseLocation = [self convertPoint:event.locationInWindow
                                      fromView:nil];
    [_camera startDraggingFromPoint:mouseLocation];
}

// rotational movement about x- and y-axis
- (void)mouseDragged:(NSEvent *)event
{
    NSPoint mouseLocation = [self convertPoint:event.locationInWindow
                                      fromView:nil];
    if (_camera.isDragging) {
        [_camera dragToPoint:mouseLocation];
    }
}

- (void) mouseUp:(NSEvent *)event
{
    NSPoint mouseLocation = [self convertPoint:event.locationInWindow
                                      fromView:nil];
    [_camera endDrag];
}

// The camera is at the centre of the scene so
// we don't have to support zooming in and out.
- (void)scrollWheel:(NSEvent *)event
{
    //CGFloat dz = event.scrollingDeltaY;
    //[_camera zoomInOrOut:dz];
}

- (void)keyDown:(NSEvent *)event
{
    if (event)
    {
        NSString* pChars = [event characters];
        if ([pChars length] != 0)
        {
            unichar key = [[event characters] characterAtIndex:0];
            switch(key) {
            case 27:
                exit(0);
                break;
            default:
                break;
            }
        }
    }
}


@end
