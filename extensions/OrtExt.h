// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface OrtExt : NSObject

// This is like a stub function where it called `RegisterCustomOp` method from
// ORT Extensions so that the function gets used directly otherwise registering
// custom ops using name would raise a symbol not found error as it has been
// thrown away (as unused) during linking stage. This makes RegisterCustomOps
// using function name possible at swift user level code in the package.

// note: `extensionsIncludedInPackage` is not explicitly called in the source code
// but SPM generally follows the convention of the Objective-C runtime and 
// does not optimize away methods declared in Objective-C headers.
- (void)extensionsIncludedInPackage;

@end