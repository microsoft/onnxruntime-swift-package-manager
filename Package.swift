// swift-tools-version: 5.6
//   The swift-tools-version declares the minimum version of Swift required to build this package and MUST be the first
//   line of this file. 5.6 is required to support zip files for the pod archive binaryTarget.
//
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
//
// A user of the Swift Package Manager (SPM) package will consume this file directly from the ORT github repository.
// For context, the end user's config will look something like:
//
//     dependencies: [
//        #TODO: update to use release 'version' and the new repo url here when available
//       .package(url: "https://github.com/microsoft/onnxruntime", branch: "rel-1.15.0"), 
//       ...
//     ],
//

import PackageDescription
import class Foundation.ProcessInfo

let package = Package(
    name: "onnxruntime",
    platforms: [.iOS(.v11)],
    products: [
        .library(name: "onnxruntime",
                 type: .static,
                 targets: ["OnnxRuntimeBindings"]),
        .library(name: "onnxruntime_extensions",
                 type: .static,
                 targets: ["OnnxRuntimeExtensions"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "OnnxRuntimeBindings",
                dependencies: ["onnxruntime"],
                path: "objectivec",
                exclude: ["ReadMe.md", "format_objc.sh", "test",
                            "ort_checkpoint.mm",
                            "ort_checkpoint_internal.h",
                            "ort_training_session_internal.h",
                            "ort_training_session.mm",
                            "include/ort_checkpoint.h",
                            "include/ort_training_session.h",
                            "include/onnxruntime_training.h"],
                cxxSettings: [
                    .define("SPM_BUILD"),
                    .unsafeFlags(["-std=c++17",
                                  "-fobjc-arc-exceptions"
                                 ]),
                ], linkerSettings: [
                    .unsafeFlags(["-ObjC"]),
                ]),
        .testTarget(name: "OnnxRuntimeBindingsTests",
                    dependencies: ["OnnxRuntimeBindings"],
                    path: "swift/OnnxRuntimeBindingsTests",
                    resources: [
                        .copy("Resources/single_add.basic.ort")
                    ]),
        .target(name: "OnnxRuntimeExtensions",
                dependencies: ["onnxruntime_extensions", "onnxruntime"],
                path: "extensions",
                cxxSettings: [
                    .define("ORT_SWIFT_PACKAGE_MANAGER_BUILD"),
                    .unsafeFlags(["-std=c++17",
                                  "-fobjc-arc-exceptions"
                                 ]),
                ], linkerSettings: [
                    .unsafeFlags(["-ObjC"]),
                ]),
        .testTarget(name: "OnnxRuntimeExtensionsTests",
                    dependencies: ["OnnxRuntimeExtensions", "OnnxRuntimeBindings"],
                    path: "swift/OnnxRuntimeExtensionsTests",
                    resources: [
                        .copy("Resources/decode_image.onnx")
                    ]),
    ]
)

// Add the ORT iOS Pod archive as a binary target.
//
// There are 2 scenarios:
//
// Release version of ORT SPM github repo:
//    Target will be set to the latest released ORT iOS pod archive and its checksum.
//
// Current main of ORT SPM github repo:
//    Target will be set to the pod archive built in sync with the current main objective-c source code.

// CI or local testing where you have built/obtained the iOS Pod archive matching the current source code.
// Requires the ORT_IOS_POD_LOCAL_PATH environment variable to be set to specify the location of the pod.
if let pod_archive_path = ProcessInfo.processInfo.environment["ORT_IOS_POD_LOCAL_PATH"] {
    // ORT_IOS_POD_LOCAL_PATH MUST be a path that is relative to Package.swift.
    //
    // To build locally, tools/ci_build/github/apple/build_and_assemble_ios_pods.py can be used
    // See https://onnxruntime.ai/docs/build/custom.html#ios
    //  Example command:
    //    python3 tools/ci_build/github/apple/build_and_assemble_ios_pods.py \
    //      --variant Full \
    //      --build-settings-file tools/ci_build/github/apple/default_full_ios_framework_build_settings.json
    //
    // This should produce the pod archive in build/ios_pod_staging, and ORT_IOS_POD_LOCAL_PATH can be set to
    // "build/ios_pod_staging/pod-archive-onnxruntime-c-???.zip" where '???' is replaced by the version info in the
    // actual filename.
    package.targets.append(Target.binaryTarget(name: "onnxruntime", path: pod_archive_path))

} else {
    // ORT 1.15.0 release
    package.targets.append(
       Target.binaryTarget(name: "onnxruntime",
                           url: "https://onnxruntimepackages.z14.web.core.windows.net/pod-archive-onnxruntime-c-1.15.0.zip",
                           checksum: "9b41412329a73d7d298b1d94ab40ae9adb65cb84f132054073bc82515b4f5f82")
    )
}

if let ext_pod_archive_path = ProcessInfo.processInfo.environment["ORT_EXT_IOS_POD_LOCAL_PATH"] {
    package.targets.append(Target.binaryTarget(name: "onnxruntime_extensions", path: ext_pod_archive_path))
}
// Note: ORT Extensions 0.8.0 release version pod (Currently not working - it gives a header path not found error.)
 else {
    //   package.targets.append(
    //      Target.binaryTarget(name: "onnxruntime_extensions",
    //                          url: "https://onnxruntimepackages.z14.web.core.windows.net/pod-archive-onnxruntime-extensions-c-0.8.0.zip",
    //                          checksum: "1d003770c9a6d0ead92c04ed40d5083e8f4f55ea985750c3efab91489be15512")
    //   )
    fatalError("It is not valid to use a release version extensions c pod for now.\n" +
               "Please set ORT_EXTENSIONS_IOS_POD_LOCAL_PATH environment variable to specify a location for local dev version pod.\n" +
               "See Package.swift for more information on using a local pod archive.")
 }