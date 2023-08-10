// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "OrtExt.h"

#include "onnxruntime_extensions/onnxruntime_extensions.h"

@implementation OrtExt

+ (nonnull ORTCAPIRegisterCustomOpsFnPtr)getRegisterCustomOpsFunctionPointer {

  // Note: This returns the address of `RegisterCustomOps` function. At swift
  // level, user can call this function to get the RegisterCustomOpsFnPtr
  // and use the function pointer to register custom ops. See
  // SwiftOnnxRuntimeExtensionsTests.swift for an example usage.
  return RegisterCustomOps;
}

@end