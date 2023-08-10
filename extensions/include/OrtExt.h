// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface OrtExt : NSObject

typedef struct OrtStatus *(*ORTCAPIRegisterCustomOpsFnPtr)(struct OrtSessionOptions * /*options*/,
                                                           const struct OrtApiBase * /*api*/);

+ (nonnull ORTCAPIRegisterCustomOpsFnPtr)getRegisterCustomOpsFunctionPointer;

@end