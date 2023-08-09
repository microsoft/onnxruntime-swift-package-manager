// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#include "onnxruntime/onnxruntime_cxx_api.h"
#include "onnxruntime_extensions/onnxruntime_extensions.h"

@interface OrtExt : NSObject

// This is like a stub function where it calls `RegisterCustomOp` method from
// ORT Extensions so that the function gets used directly otherwise registering
// custom ops using name would raise a symbol not found error as it has been
// thrown away (as unused) during linking stage
+ (void)extensionsIncludedInPackage;

@end

@implementation OrtExt

+ (void)extensionsIncludedInPackage {

  auto session_options = Ort::SessionOptions();

  // Note: This is a dummy call to RegisterCustomOps to ensure the extensions
  // library is available. It does NOT register custom ops for your inference
  // session. You MUST call ORTSessionOptions registerCustomOps(usingFunction:
  // "RegisterCustomOps") on the session options instance that is provided to
  // the ORTSession constructor.
  OrtStatus* ort_status = nullptr;

  if ((ort_status = RegisterCustomOps(session_options, OrtGetApiBase())) != nullptr) {
    Ort::GetApi().ReleaseStatus(ort_status);
    NSLog(@"Unable to call RegisterCustomOps.\n"
           "This can happen when the extensions headers or extensions target is not available to the package.\n"
           "Please ensure that both ORT and ORT Extensions binary pod archive are correctly included. See Package.swift for more info.");
  } else {
    NSLog(@"RegisterCustomOps succeeded.");
  }
}

@end