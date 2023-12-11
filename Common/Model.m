//
//  Model.m
//  ExploringGLKMesh
//
//  Created by mark lim pak mun on 10/12/2023.
//  Copyright © 2023 mark lim pak mun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/ModelIO.h>
#import <GLKit/GLKit.h>
#import "OGLShader.h"
#import "Model.h"




@implementation Model
{
    GLKMesh     *_glkMesh;
    GLuint      _vao;           // vertex array object

    GLuint      _vbo;           // vertex buffer object
    GLuint      _ebo;           // element/index buffer object
    GLsizei     _indicesCount;
    GLenum      _mode;
    GLenum      _indexType;
    NSUInteger _indexBufferOffset;

}

- (instancetype)initSphereWithRadius:(GLfloat)radius
                      radialSegments:(NSUInteger)radialSegments
                    verticalSegments:(NSUInteger)vertricalSegments
                       inwardNormals:(BOOL)inwardNormals
                          hemisphere:(BOOL)isHemisphere
{
    self = [super init];
    if (self) {
        GLKMeshBufferAllocator *allocator = [[GLKMeshBufferAllocator alloc] init];

        MDLMesh* sphereMesh = [MDLMesh newEllipsoidWithRadii:(vector_float3){radius, radius, radius}
                                              radialSegments:radialSegments
                                            verticalSegments:vertricalSegments
                                                geometryType:MDLGeometryTypeTriangles
                                               inwardNormals:inwardNormals
                                                  hemisphere:isHemisphere
                                                   allocator:allocator];
        NSError *error = nil;
        _glkMesh = [[GLKMesh alloc] initWithMesh:sphereMesh
                                           error:&error];
        [self prepareForOpenGL];
    }
    return self;
}

- (void)dealloc
{
    glDeleteVertexArrays(1, &_vao);
    // We assume the VBO and EBO are deleted by the system.
}
    
- (void)render
{
    glBindVertexArray(_vao);
    // Note: the EBO is internally bind to the VAO.
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ebo);
    glDrawElements(_mode, _indicesCount, _indexType,
                   (const void *)_indexBufferOffset);
}

/*
 Extract the values that were assigned to the various properties.
 */
    
- (void)prepareForOpenGL
{
    glGenVertexArrays(1, &_vao);
    glBindVertexArray(_vao);
    MDLVertexDescriptor *vertDesc = _glkMesh.vertexDescriptor;
    // All built-in parametric MDLMeshes have position, normal and tex coords attributes in that order.
    MDLVertexAttribute *posAttr = [vertDesc attributeNamed:MDLVertexAttributePosition];
    // MDLVertexAttributeData is not available for GLKMesh so we access an element of
    // the array of MDLVertexBufferLayouts
    // There is only 1 layout
    NSUInteger stride = vertDesc.layouts[0].stride;
    // There is only one Vertex Buffer
    _vbo = _glkMesh.vertexBuffers[0].glBufferName;
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    GLKVertexAttributeParameters vertAttrParms = GLKVertexAttributeParametersFromModelIO(posAttr.format);
    // We need the stride, format and offset properties to call
    // glEnableVertexAttribArray & glVertexAttribPointer
    //NSLog(@"%@ %@ %@", posAttr, normalAttr, texCoordAttr);
    // The vertex shader should precede the position attribute with the phrase
    // layout(location = 0)
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,
                          vertAttrParms.size,           // # of components - 1, 2, 3 or 4
                          vertAttrParms.type,           // e.g. GL_FLOAT
                          vertAttrParms.normalized,     // usually 0 (false)
                          (GLsizei)stride,
                          (const void *)posAttr.offset);
    MDLVertexAttribute *normalAttr = [vertDesc attributeNamed:MDLVertexAttributeNormal];
    vertAttrParms = GLKVertexAttributeParametersFromModelIO(normalAttr.format);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,
                          vertAttrParms.size,
                          vertAttrParms.type,
                          vertAttrParms.normalized,
                          (GLsizei)stride,
                          (const void *)normalAttr.offset);
    MDLVertexAttribute *texCoordAttr = [vertDesc attributeNamed:MDLVertexAttributeTextureCoordinate];
    vertAttrParms = GLKVertexAttributeParametersFromModelIO(texCoordAttr.format);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2,
                          vertAttrParms.size,
                          vertAttrParms.type,
                          vertAttrParms.normalized,
                          (GLsizei)stride,
                          (const void *)texCoordAttr.offset);
    // Assume there is only 1 element in the array of submeshes
    // We require the following values to perform glBindBuffer
    _ebo = _glkMesh.submeshes[0].elementBuffer.glBufferName;
    // ...  and glDrawElements
    // An example of mode is GL_TRIANGLES
    _mode = _glkMesh.submeshes[0].mode;
    // An example of type is GL_UNSIGNED_SHORT
    _indexType = _glkMesh.submeshes[0].type;
    // # of elements in the elementBuffer (GLKMeshBuffer).
    _indicesCount = _glkMesh.submeshes[0].elementCount;
    // offset, in bytes, into the element buffer (usually 0)
    _indexBufferOffset = _glkMesh.submeshes[0].elementBuffer.offset;
}
    
@end

