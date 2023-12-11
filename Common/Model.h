//
//  Model.h
//  ExploringGLKMesh
//
//  Created by mark lim pak mun on 10/12/2023.
//  Copyright © 2023 mark lim pak mun. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Mesh;


@interface Model: NSObject

// public methods
// To add more parametric meshes
- (instancetype)initSphereWithRadius:(GLfloat)radius
                      radialSegments:(NSUInteger)radialSegments
                    verticalSegments:(NSUInteger)vertricalSegments
                       inwardNormals:(BOOL)inwardNormals
                          hemisphere:(BOOL)isHemisphere;

- (void) render;


@end
