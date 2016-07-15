/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest

import Basic
import Build
import PackageDescription
import PackageGraph
import PackageModel
import Utility

final class DescribeTests: XCTestCase {
    let dummyPackage = Package(manifest: Manifest(path: AbsolutePath("/"), url: "/", package: PackageDescription.Package(name: "Foo"), products: [], version: nil))
    
    struct InvalidToolchain: Toolchain {
        var platformArgsClang: [String] { fatalError() }
        var platformArgsSwiftc: [String] { fatalError() }
        var sysroot: String?  { fatalError() }
        var SWIFT_EXEC: String { fatalError() }
        var clang: String { fatalError() }
    }

    func testDescribingNoModulesThrows() {
        do {
            let tempDir = try TemporaryDirectory(removeTreeOnDeinit: true)
            let graph = PackageGraph(rootPackage: dummyPackage, modules: [], externalModules: [], products: [])
            _ = try describe(tempDir.path.appending("foo"), .debug, graph, flags: BuildFlags(), toolchain: InvalidToolchain())
            XCTFail("This call should throw")
        } catch Build.Error.noModules {
            XCTAssert(true, "This error should be thrown")
        } catch {
            XCTFail("No other error should be thrown")
        }
    }

    func testDescribingCModuleThrows() {
        do {
            let tempDir = try TemporaryDirectory(removeTreeOnDeinit: true)
            let graph = PackageGraph(rootPackage: dummyPackage, modules: [try CModule(name: "MyCModule", sources: Sources(paths: [], root: "/"), path: "/")], externalModules: [], products: [])
            _ = try describe(tempDir.path.appending("foo"), .debug, graph, flags: BuildFlags(), toolchain: InvalidToolchain())
            XCTFail("This call should throw")
        } catch Build.Error.onlyCModule (let name) {
            XCTAssert(true, "This error should be thrown")
            XCTAssertEqual(name, "MyCModule")
        } catch {
            XCTFail("No other error should be thrown")
        }
    }

    static var allTests = [
        ("testDescribingNoModulesThrows", testDescribingNoModulesThrows),
        ("testDescribingCModuleThrows", testDescribingCModuleThrows),
    ]
}
