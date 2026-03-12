// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import XCTest
import Foundation
@testable import OnnxRuntimeBindings

final class SwiftOnnxRuntimeBindingsTests: XCTestCase {
    let modelPath: String = Bundle.module.url(forResource: "single_add.basic", withExtension: "ort")!.path

    func testGetVersionString() throws {
        do {
            let version = ORTVersion()
            XCTAssertNotNil(version)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateSession() throws {
        do {
            let env = try ORTEnv(loggingLevel: ORTLoggingLevel.verbose)
            let options = try ORTSessionOptions()
            try options.setLogSeverityLevel(ORTLoggingLevel.verbose)
            try options.setIntraOpNumThreads(1)
            // Create the ORTSession
            _ = try ORTSession(env: env, modelPath: modelPath, sessionOptions: options)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testAppendCoreMLEP() throws {
        do {
            let env = try ORTEnv(loggingLevel: ORTLoggingLevel.verbose)
            let sessionOptions: ORTSessionOptions = try ORTSessionOptions()
            let coreMLOptions: ORTCoreMLExecutionProviderOptions = ORTCoreMLExecutionProviderOptions()
            coreMLOptions.enableOnSubgraphs = true
            try sessionOptions.appendCoreMLExecutionProvider(with: coreMLOptions)

            XCTAssertTrue(ORTIsCoreMLExecutionProviderAvailable())
            _ = try ORTSession(env: env, modelPath: modelPath, sessionOptions: sessionOptions)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testAppendXnnpackEP() throws {
        do {
            let env = try ORTEnv(loggingLevel: ORTLoggingLevel.verbose)
            let sessionOptions: ORTSessionOptions = try ORTSessionOptions()
            let XnnpackOptions: ORTXnnpackExecutionProviderOptions = ORTXnnpackExecutionProviderOptions()
            XnnpackOptions.intra_op_num_threads = 2
            try sessionOptions.appendXnnpackExecutionProvider(with: XnnpackOptions)

            XCTAssertTrue(ORTIsCoreMLExecutionProviderAvailable())
            _ = try ORTSession(env: env, modelPath: modelPath, sessionOptions: sessionOptions)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateBoolTensorTrue() throws {
        do {
            var boolValue: Bool = true
            let data = NSMutableData(bytes: &boolValue, length: MemoryLayout<Bool>.size)
            let tensor = try ORTValue(
                tensorData: data,
                elementType: .bool,
                shape: [1]
            )

            let typeInfo = try tensor.tensorTypeAndShapeInfo()
            XCTAssertEqual(typeInfo.elementType, .bool)
            XCTAssertEqual(typeInfo.shape, [1])

            let tensorData = try tensor.tensorData()
            let readValue = (tensorData as Data).withUnsafeBytes { ptr -> Bool in
                return ptr.load(as: Bool.self)
            }
            XCTAssertTrue(readValue)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateBoolTensorFalse() throws {
        do {
            var boolValue: Bool = false
            let data = NSMutableData(bytes: &boolValue, length: MemoryLayout<Bool>.size)
            let tensor = try ORTValue(
                tensorData: data,
                elementType: .bool,
                shape: [1]
            )

            let typeInfo = try tensor.tensorTypeAndShapeInfo()
            XCTAssertEqual(typeInfo.elementType, .bool)
            XCTAssertEqual(typeInfo.shape, [1])

            let tensorData = try tensor.tensorData()
            let readValue = (tensorData as Data).withUnsafeBytes { ptr -> Bool in
                return ptr.load(as: Bool.self)
            }
            XCTAssertFalse(readValue)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateBoolTensorArray() throws {
        do {
            var boolValues: [Bool] = [true, false, true, false]
            let data = NSMutableData(bytes: &boolValues, length: boolValues.count * MemoryLayout<Bool>.stride)
            let tensor = try ORTValue(
                tensorData: data,
                elementType: .bool,
                shape: [NSNumber(value: boolValues.count)]
            )

            let typeInfo = try tensor.tensorTypeAndShapeInfo()
            XCTAssertEqual(typeInfo.elementType, .bool)
            XCTAssertEqual(typeInfo.shape, [4])

            let tensorData = try tensor.tensorData()
            let readValues = (tensorData as Data).withUnsafeBytes { ptr -> [Bool] in
                return Array(ptr.bindMemory(to: Bool.self))
            }
            XCTAssertEqual(readValues, [true, false, true, false])
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
}
