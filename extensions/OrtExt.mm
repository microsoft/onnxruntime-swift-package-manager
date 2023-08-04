// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import  <Foundation/Foundation.h>

#include "onnxruntime/onnxruntime_cxx_api.h"
#include "onnxruntime_extensions/onnxruntime_extensions.h"

@interface OrtExt : NSObject

// Note: This is like a stub function where it calls `RegisterCustomOp` method from ORT Extensions
// so that the function gets used directly otherwise registering custom ops using name would raise
// a symbol not found error as it has been thrown away (as unused) during linking stage
+ (void)extensionsIncludedInPackage;

@end


@implementation OrtExt

+ (void)extensionsIncludedInPackage {
    auto session_options = Ort::SessionOptions();
    if (RegisterCustomOps(session_options, OrtGetApiBase()) != nullptr) {
      NSLog(@"Unable to call RegisterCustomOps.");
    }
    NSLog(@"RegisterCustomOps succeeded.");
}

@end