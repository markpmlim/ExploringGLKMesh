## Exploring GLKMesh

The class GLKMesh is part of the GLKit framework and was introduced in macOS 10.11 (El Capitan). The Metal framework was also introduced in macOS 10.11. Both GLKMesh and MTKMesh objects can be instantiated from instances of MDLMesh. Both classes GLKMesh and MTKMesh and their associated classes have similar methods. For example, both Metal and GLKit have a method with the signature:


```objective-C

    NSArray<GLKMesh *> *glkMeshes = [GLKMesh newMeshesFromAsset:mdlAsset
                                                   sourceMeshes:&mdlMeshes
                                                          error:&error];


    NSArray<MTKMesh *> *metalMeshes = [MTKMesh newMeshesFromAsset:mdlAsset
                                                           device:metalDevice
                                                     sourceMeshes:&mdlMeshes
                                                            error:&error];

```

Logically, the instance of MDLAsset could be created using the method:

```objective-C

    MDLAsset *mdlAsset = [[MDLAsset alloc] initWithURL:assetURL
                                      vertexDescriptor:vertexDescriptor
                                       bufferAllocator:allocator];             

```

where 

    vertexDescriptor is an instance of MDLVertexDescriptor (or nil), and,
    allocator is either an instance of MTKMeshBufferAllocator, GLKMeshBufferAllocator or MDLMeshBufferDataAllocator. 

However, the above call crashes if the allocator is GLKMeshBufferAllocator.

In other words, we could not create an array of GLKMeshes from an MDLAsset object. Trying to create such an array with an instance of MDLMeshBufferDataAllocator will be flagged as an error. A NIL object is returned.

    Error Domain=GLKModelErrorDomain Code=0 "(null)" UserInfo={GLKModelErrorKey=Vertex buffer in MDLMesh was not created using a GLKMeshBufferAllocator} 


Perusing the menu item "Document and API reference" (under XCode's Help Menu), we observe that a GLKMesh object can be instantiated with the instance method:

```objective-C

    GLKMesh *glkMesh = [[GLKMesh alloc] initWithMesh:mdlMesh
                                                error:&error];

```

The quickest way to create an MDLMesh object is to apply its Parametric Meshes creating methods like:

    newBoxWithDimensions:segments:geometryType:inwardNormals:allocator:

Naturally, the allocator will be an instance of GLKMeshBufferAllocator since we want to create a GLKMesh object.

Examining the output of the values assigned to the various properties of GLKMesh and its associated classes, we discovered GLKit will create OpenGL vertex buffer objects (VBOs) and Element Buffer Objects (EBOs). VBOs are returned via the chained property

    _glkMesh.vertexBuffers[i].glBufferName

and EBOs 

    glkMesh.submeshes[i].elementBuffer.glBufferName

Here, i is an index into the NSArray of vertex buffers or submeshes.

As stated in the article, "Vertex Specification" posted by Khronos.org, EBOs are bind internally to a VAO. The next step is to dig out enough information to execute the following OpenGL calls:

    glVertexAttribPointer, glBindBuffer (on the ebo) and glDrawElements. 

Further Observations:

(a) It is not possible to create a GLKMesh instance from a MDLMesh object if the allocator is not an instance of GLKMeshBufferAllocator. When the GLKMesh method initWithMesh:error: is called, the error message "Vertex buffer in MDLMesh was not created using a GLKMeshBufferAllocator" will be returned.

(b) The number of vertex buffers and the number of submeshes might be more than 1 in an actual MDLMesh. Usually the vertices' position, normal and texture coordinate attributes are interleaved as part of a structure viz.

    struct {
        GLKVector3 position;
        GLKVector3 normal;
        GLKVector2 texCoord;
    } Vertex_t;

    The vertex data is stored as an array of structures of type Vertex_t. On the other hand, the vertex data can stored as a structure of arrays. Separate buffers are allocated to store the positions, normal and texture coordinate attributes.

<br />
<br />
In conclusion, the class GLKMesh is of limited utility since GLKMesh objects cannot be instantiated
(a) if the allocator is not an instance of GLKMeshBufferAllocator. But default, MDLMeshes are instantiated with a MDLMeshBufferDataAllocator object,
(b) from MDLAssets objects.


<br />
<br />
<br />

The focus of this demo is on how use GLKMeshes in an OpenGL program running under macOS 10.11 or later.  This demo loads an equirectangular image (resolution 2:1) and projects it onto the inner surface of a sphere.

<br />
<br />

Compiled and run under XCode 8.3.2
<br />
Tested on macOS 10.12
<br />
Deployment set at macOS 10.11.

<br />
<br />
<br />

Resources:

https://www.khronos.org/opengl/wiki/Vertex_Specification#Vertex_Array_Object

https://www.khronos.org/opengl/wiki/Vertex_Specification#Vertex_Buffer_Object

https://www.khronos.org/opengl/wiki/Vertex_Specification#Index_buffers
