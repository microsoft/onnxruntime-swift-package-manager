// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import  <Foundation/Foundation.h>

#include "onnxruntime/onnxruntime_cxx_api.h"
#include "onnxruntime_extensions/onnxruntime_extensions.h"

@interface OrtExt : NSObject

// Note: This is like a "dummy" function where it calls `RegisterCustomOp` method from ORT Extensions
// in order to make the symbols available.
+ (void)registerCustomOpsForOrtExt;

@end


@implementation OrtExt

+ (void)registerCustomOpsForOrtExt {
    auto session_options = Ort::SessionOptions();
    if (RegisterCustomOps(session_options, OrtGetApiBase()) != nullptr) {
      NSLog(@"Unable to call RegisterCustomOps.");
    }
    NSLog(@"RegisterCustomOps succeeded.");
}

@end