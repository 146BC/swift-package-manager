/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import PackageType
import Utility
import POSIX

public protocol XcodeprojOptions {
    /// The list of additional arguments to pass to the compiler.
    var Xcc: [String] { get }

    /// The list of additional arguments to pass to the linker.
    var Xld: [String] { get }

    /// The list of additional arguments to pass to `swiftc`.
    var Xswiftc: [String] { get }

    /// If provided, a path to an xcconfig file to be included by the project.
    ///
    /// This allows the client to override settings defined in the project itself.
    var xcconfigOverrides: String? { get }
}

/**
 Generates an xcodeproj at the specified path.
 - Returns: the path to the generated project
*/
public func generate(dstdir: String, projectName: String, srcroot: String, modules: [XcodeModuleProtocol], externalModules: [XcodeModuleProtocol], products: [Product], options: XcodeprojOptions) throws -> String {

    let xcodeprojName = "\(projectName).xcodeproj"
    let xcodeprojPath = try mkdir(dstdir, xcodeprojName)
    let schemesDirectory = try mkdir(xcodeprojPath, "xcshareddata/xcschemes")
    let schemeName = "\(projectName).xcscheme"

////// the pbxproj file describes the project and its targets
    try open(xcodeprojPath, "project.pbxproj") { fwrite in
        try pbxproj(srcroot: srcroot, projectRoot: dstdir, xcodeprojPath: xcodeprojPath, modules: modules, externalModules: externalModules, products: products, options: options, printer: fwrite)
    }

////// the scheme acts like an aggregate target for all our targets
   /// it has all tests associated so CMD+U works
    try open(schemesDirectory, schemeName) { fwrite in
        xcscheme(container: xcodeprojName, modules: modules, printer: fwrite)
    }

////// we generate this file to ensure our main scheme is listed
   /// before any inferred schemes Xcode may autocreate
    try open(schemesDirectory, "xcschememanagement.plist") { fwrite in
        fwrite("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        fwrite("<plist version=\"1.0\">")
        fwrite("<dict>")
        fwrite("  <key>SchemeUserState</key>")
        fwrite("  <dict>")
        fwrite("    <key>\(schemeName)</key>")
        fwrite("    <dict></dict>")
        fwrite("  </dict>")
        fwrite("  <key>SuppressBuildableAutocreation</key>")
        fwrite("  <dict></dict>")
        fwrite("</dict>")
        fwrite("</plist>")
    }

    return xcodeprojPath
}


private func open(_ path: String..., body: ((String) -> Void) throws -> Void) throws {
    var error: ErrorProtocol? = nil

    try Utility.fopen(Path.join(path), mode: .Write) { fp in
        try body { line in
            if error == nil {
                do {
                    try fputs(line, fp)
                    try fputs("\n", fp)
                } catch let caught {
                    error = caught
                }
            }
        }
    }

    guard error == nil else { throw error! }
}
