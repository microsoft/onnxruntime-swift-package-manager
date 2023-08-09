// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "OrtExt.h"

@implementation OrtExt

- (void)extensionsIncludedInPackage {

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