// swift-tools-version: 5.6
//   The swift-tools-version declares the minimum version of Swift required to build this package and MUST be the first
//   line of this file. 5.6 is required to support zip files for the pod archive binaryTarget.
//
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
//
// A user of the Swift Package Manager (SPM) package will consume this file directly from the ORT SPM github repository.
// For context, the end user's config will look something like:
//
//     dependencies: [
//       .package(url: "https://github.com/microsoft/onnxruntime-swift-package-manager", from: "1.16.0"), 
//       ...
//     ],
// NOTE: For specifying valid and latest release version above, please refer to this page:
// https://github.com/microsoft/onnxruntime-swift-package-manager/releases

import PackageDescription
import class Foundation.ProcessInfo

let package = Package(
    name: "onnxruntime",
    platforms: [.iOS(.v12),
                .macOS(.v11)],
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
                ]),
        .testTarget(name: "OnnxRuntimeExtensionsTests",
                    dependencies: ["OnnxRuntimeExtensions", "OnnxRuntimeBindings"],
                    path: "swift/OnnxRuntimeExtensionsTests",
                    resources: [
                        .copy("Resources/decode_image.onnx")
                    ]),
    ],
    cxxLanguageStandard: .cxx17
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
    // ORT 1.16.0 release
    package.targets.append(
       Target.binaryTarget(name: "onnxruntime",
                           url: "https://onnxruntimepackages.z14.web.core.windows.net/pod-archive-onnxruntime-c-1.16.0.zip",
                           checksum: "684f317081d6795e5fd619972bc5dd9a648156ba9d3e0fb2292314582a216d8e")
    )
}

if let ext_pod_archive_path = ProcessInfo.processInfo.environment["ORT_EXTENSIONS_IOS_POD_LOCAL_PATH"] {
    package.targets.append(Target.binaryTarget(name: "onnxruntime_extensions", path: ext_pod_archive_path))
} else {
     // ORT Extensions 0.9.0 release
      package.targets.append(
         Target.binaryTarget(name: "onnxruntime_extensions",
                             url: "https://onnxruntimepackages.z14.web.core.windows.net/pod-archive-onnxruntime-extensions-c-0.9.0.zip",
                             checksum: "2549ae80482a1de285aa54cc07440b7daf8a93f91043eff6ba56b6e73274d6cf")
      )
 }