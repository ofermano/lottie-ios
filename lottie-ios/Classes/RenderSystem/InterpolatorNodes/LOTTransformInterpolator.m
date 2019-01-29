//
//  LOTTransformInterpolator.m
//  Lottie
//
//  Created by brandon_withrow on 7/18/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTTransformInterpolator.h"

// TODO BW Perf update, Cache transform

@implementation LOTTransformInterpolator {
  LOTPointInterpolator *_positionInterpolator;
  LOTPointInterpolator *_anchorInterpolator;
  LOTSizeInterpolator *_scaleInterpolator;
  LOTNumberInterpolator *_rotationInterpolator;
  LOTNumberInterpolator *_positionXInterpolator;
  LOTNumberInterpolator *_positionYInterpolator;
}

+ (instancetype)transformForLayer:(LOTLayer *)layer {
  NSLog(@"Opacity");
  for (LOTKeyframe *s in layer.opacity.keyframes) {
    NSLog(@"time = %@, in = (%f,%f), out = (%f,%f), scale = %f", s.keyframeTime, s.inTangent.x, s.inTangent.y, s.outTangent.x, s.outTangent.y, s.floatValue);
  }
  LOTTransformInterpolator *interpolator = nil;
  if (layer.position) {
    interpolator = [[LOTTransformInterpolator alloc] initWithPosition:layer.position.keyframes
                                                             rotation:layer.rotation.keyframes
                                                               anchor:layer.anchor.keyframes
                                                                scale:layer.scale.keyframes];
  } else {
    interpolator = [[LOTTransformInterpolator alloc] initWithPositionX:layer.positionX.keyframes
                                                             positionY:layer.positionY.keyframes
                                                              rotation:layer.rotation.keyframes
                                                                anchor:layer.anchor.keyframes
                                                                 scale:layer.scale.keyframes];
  }
  interpolator.parentKeyName = [layer.layerName copy];
  return interpolator;
}

- (instancetype)initWithPosition:(NSArray <LOTKeyframe *> *)position
                        rotation:(NSArray <LOTKeyframe *> *)rotation
                          anchor:(NSArray <LOTKeyframe *> *)anchor
                           scale:(NSArray <LOTKeyframe *> *)scale {
  self = [super init];
  if (self) {
    NSLog(@"Position");
    for (LOTKeyframe *pos in position) {
      NSLog(@"time = %@, in = (%f,%f), out = (%f,%f), pos = (%f,%f)", pos.keyframeTime, pos.inTangent.x, pos.inTangent.y, pos.outTangent.x, pos.outTangent.y, pos.pointValue.x, pos.pointValue.y);
    }
    NSLog(@"Scale");
    for (LOTKeyframe *s in scale) {
      NSLog(@"time = %@, in = (%f,%f), out = (%f,%f), scale = %f", s.keyframeTime, s.inTangent.x, s.inTangent.y, s.outTangent.x, s.outTangent.y, s.floatValue);
    }
    NSLog(@"Rotation");
    for (LOTKeyframe *rot in rotation) {
      NSLog(@"time = %@, in = (%f,%f), out = (%f,%f), rotation = %f", rot.keyframeTime, rot.inTangent.x, rot.inTangent.y, rot.outTangent.x, rot.outTangent.y, rot.floatValue);
    }
    NSLog(@"Anchor");
    for (LOTKeyframe *rot in anchor) {
      NSLog(@"time = %@, in = (%f,%f), out = (%f,%f), rotation = %f", rot.keyframeTime, rot.inTangent.x, rot.inTangent.y, rot.outTangent.x, rot.outTangent.y, rot.floatValue);
    }
    [self initializeWithPositionX:nil positionY:nil position:position rotation:rotation anchor:anchor scale:scale];
  }
  return self;
}

- (instancetype)initWithPositionX:(NSArray <LOTKeyframe *> *)positionX
                        positionY:(NSArray <LOTKeyframe *> *)positionY
                         rotation:(NSArray <LOTKeyframe *> *)rotation
                           anchor:(NSArray <LOTKeyframe *> *)anchor
                            scale:(NSArray <LOTKeyframe *> *)scale {
  self = [super init];
  if (self) {
    [self initializeWithPositionX:positionX positionY:positionY position:nil rotation:rotation anchor:anchor scale:scale];
  }
  return self;
}


- (void)initializeWithPositionX:(NSArray <LOTKeyframe *> *)positionX
                      positionY:(NSArray <LOTKeyframe *> *)positionY
                       position:(NSArray <LOTKeyframe *> *)position
                       rotation:(NSArray <LOTKeyframe *> *)rotation
                         anchor:(NSArray <LOTKeyframe *> *)anchor
                          scale:(NSArray <LOTKeyframe *> *)scale {
  
  if (position) {
    _positionInterpolator = [[LOTPointInterpolator alloc] initWithKeyframes:position];
  }
  if (positionY) {
    _positionYInterpolator = [[LOTNumberInterpolator alloc] initWithKeyframes:positionY];
  }
  if (positionX) {
    _positionXInterpolator = [[LOTNumberInterpolator alloc] initWithKeyframes:positionX];
  }
  _anchorInterpolator = [[LOTPointInterpolator alloc] initWithKeyframes:anchor];
  _scaleInterpolator = [[LOTSizeInterpolator alloc] initWithKeyframes:scale];
  _rotationInterpolator = [[LOTNumberInterpolator alloc] initWithKeyframes:rotation];
}

- (BOOL)hasUpdateForFrame:(NSNumber *)frame {
  BOOL inputUpdate = _inputNode ? [_inputNode hasUpdateForFrame:frame] : NO;
  if (inputUpdate) {
    return inputUpdate;
  }
  if (_positionInterpolator) {
    return ([_positionInterpolator hasUpdateForFrame:frame] ||
            [_anchorInterpolator hasUpdateForFrame:frame] ||
            [_scaleInterpolator hasUpdateForFrame:frame] ||
            [_rotationInterpolator hasUpdateForFrame:frame]);
  }
  return ([_positionXInterpolator hasUpdateForFrame:frame] ||
          [_positionYInterpolator hasUpdateForFrame:frame] ||
          [_anchorInterpolator hasUpdateForFrame:frame] ||
          [_scaleInterpolator hasUpdateForFrame:frame] ||
          [_rotationInterpolator hasUpdateForFrame:frame]);
}

- (CATransform3D)transformForFrame:(NSNumber *)frame {
  CATransform3D baseXform = CATransform3DIdentity;
  if (_inputNode) {
    baseXform = [_inputNode transformForFrame:frame];
  }
  CGPoint position = CGPointZero;
  if (_positionInterpolator) {
    position = [_positionInterpolator pointValueForFrame:frame];
  }
  if (_positionXInterpolator &&
      _positionYInterpolator) {
    position.x = [_positionXInterpolator floatValueForFrame:frame];
    position.y = [_positionYInterpolator floatValueForFrame:frame];
  }
  CGPoint anchor = [_anchorInterpolator pointValueForFrame:frame];
  CGSize scale = [_scaleInterpolator sizeValueForFrame:frame];
  CGFloat rotation = [_rotationInterpolator floatValueForFrame:frame];
  CATransform3D translateXform = CATransform3DTranslate(baseXform, position.x, position.y, 0);
  CATransform3D rotateXform = CATransform3DRotate(translateXform, rotation, 0, 0, 1);
  CATransform3D scaleXform = CATransform3DScale(rotateXform, scale.width, scale.height, 1);
  CATransform3D anchorXform = CATransform3DTranslate(scaleXform, -1 * anchor.x, -1 * anchor.y, 0);
  return anchorXform;
}

@end
