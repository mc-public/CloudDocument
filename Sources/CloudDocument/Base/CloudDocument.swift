//
//  CloudDocument.swift
//  
//
//  Created by 孟超 on 2024/8/15.
//

#if canImport(UIKit)

import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Data structure representing a iCloud document.
@MainActor
@available(iOS 13.0, *)
class CloudDocument<FileModel>: UIDocument where FileModel: CloudFileModel {
    
    private weak var documentModel: CloudFilePresenter<FileModel>?
    
    var fileDataInfo: FileModel.DataInfo? {
        self.content.dataInfo
    }
    
    /// All versions of conflicts that need to be resolved in the current document.
    @AtomicValue(.NSLock, defaultValue: [])
    private(set) var conflictedVersions:   [ConflictedVersion<FileModel>]
    
    /// Indicate whether the current document has been deleted.
    @AtomicValue(.NSLock, defaultValue: false)
    private(set) var isDeleted: Bool
    
    /// Indicate whether the current document has been closed.
    @AtomicValue(.NSLock, defaultValue: false)
    private(set) var isClosed: Bool

    /// The data read from the disk during the last file load.
    ///
    /// When this value is `nil`, it means that the data loading has not been executed yet, or it has been executed but failed.
    @AtomicValue(.NSLock, defaultValue: Data())
    private var fileData: Data
    
    /// Errors that may occur during file saving process.
    @AtomicValue(.NSLock, defaultValue: nil)
    private(set) var savingError: Error?
    
    /// Errors that may occur during file opening process.
    @AtomicValue(.NSLock, defaultValue: nil)
    private(set) var openingError: Error?
    
    /// The content represented by the current document.
    @AtomicValue(.NSLock, defaultValue: FileModel.createEmptyModel())
    var content: FileModel
 
    /// Returns a document object initialized with its file-system location.
    override init(fileURL url: URL) {
        super.init(fileURL: url)
        NotificationCenter.default.addObserver(forName: Self.stateChangedNotification, object: nil, queue: .main) { [weak self] notification in
            MainActor.assumeIsolated {
                self?.documentStateChanged()
            }
        }
    }
    
    func setDocumentModel(for model: CloudFilePresenter<FileModel>) {
        self.documentModel = model
    }
    
    @objc @MainActor
    private func documentStateChanged() {
        self.documentModel?.updateUI()
        #if false
        print("[\(Self.self)] Current State: [", terminator: " ")
        if self.documentState.contains(.closed) {
            print(".closed", terminator: " ")
        } else if self.documentState.contains(.editingDisabled) {
            print(".editingDisabled", terminator: " ")
        } else if self.documentState.contains(.inConflict) {
            print(".inConflict", terminator: " ")
        } else if self.documentState.contains(.normal) {
            print(".normal", terminator: " ")
        } else if self.documentState.contains(.progressAvailable) {
            print(".progressAvailable", terminator: " ")
        } else if self.documentState.contains(.savingError) {
            print(".savingError", terminator: " ")
        }
        print("]")
        if !self.conflictedVersions.isEmpty {
            print("[\(Self.self)] Version Count: \(self.conflictedVersions.count)\( self.fetchConflictVersion().count)")
        }
        #endif
    }
    
    private func fetchConflictVersion() -> [ConflictedVersion<FileModel>] {
        guard let versions = NSFileVersion.unresolvedConflictVersionsOfItem(at: self.fileURL), !versions.isEmpty else {
            return []
        }
        return versions.map({ ConflictedVersion(fileVersion: $0) })
    }
    
    /// Select the specified conflict version to resolve the document conflict issue.
    ///
    /// - Parameter version: Selected subsequent document version. All other conflicting versions will be removed.
    @MainActor
    func selectVersion(for version: ConflictedVersion<FileModel>) throws {
        do {
            _ = try version.fileVersion.replaceItem(at: self.fileURL, options: NSFileVersion.ReplacingOptions(rawValue: 0))
            try NSFileVersion.removeOtherVersionsOfItem(at: self.fileURL)
            self.revert(toContentsOf: self.fileURL)
            for version in NSFileVersion.unresolvedConflictVersionsOfItem(at: self.fileURL) ?? [] {
                version.isResolved = true
            }
        } catch {
            throw error
        }
        
    }
    
    /// Saves document data asynchronously.
    func save(for saveOperation: UIDocument.SaveOperation) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, any Error>) in
            self.save(to: self.fileURL, for: saveOperation) { isSucceed in
                if isSucceed { cont.resume() }
                else { cont.resume(throwing: self.savingError ?? CocoaError(.fileWriteUnknown)) }
            }
        }
    }
    
    /// Load document data asynchronously.
    @MainActor
    func load() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, any Error>) in
            self.open { isSucceed in
                if isSucceed {
                    cont.resume()
                } else {
                    cont.resume(throwing: self.openingError ?? CocoaError(.fileReadUnknown))
                }
            }
        }
    }
    
    /// Load document data asynchronously.
    @MainActor
    func load(_ completionHandler: ((Error?) -> ())? = nil) {
        Task {
            do { try await self.load() }
            catch { completionHandler?(error) }
        }
    }
    
//MARK: - UIDocument Override
    
    /// Reads the document data in a file at a specified location in the application sandbox.
    public override func read(from url: URL) throws {
        do {
            try super.read(from: url)
        } catch {
            self.openingError = error
            throw error
        }
    }
    
    /// Saves document data to the specified location in the application sandbox.
    public override func save(to url: URL, for saveOperation: UIDocument.SaveOperation, completionHandler: ((Bool) -> Void)? = nil) {
        guard saveOperation != .forCreating else {
            super.save(to: url, for: saveOperation, completionHandler: completionHandler)
            return
        }
        let onCompletion = { (error: Error?) -> () in
            self.savingError = error
            Task { @MainActor in
                completionHandler?(error == nil)
            }
        }
        do {
            let content = try self.contents(forType: String())
            self.performAsynchronousFileAccess {
                let coordinator = NSFileCoordinator(filePresenter: self)
                var coordinatorError: NSError?
                coordinator.coordinate(writingItemAt: self.fileURL, options: .forMerging, error: &coordinatorError) { url in
                    do {
                        let fileAttr = try self.fileAttributesToWrite(to: self.fileURL, for: saveOperation)
                        try self.writeContents(content, andAttributes: fileAttr, safelyTo: self.fileURL, for: saveOperation)
                        onCompletion(nil)
                    } catch {
                        onCompletion(error)
                        return
                    }
                }
                if let coordinatorError {
                    onCompletion(coordinatorError)
                }
            }
        } catch {
            onCompletion(error)
        }
        
    }
    
    /// Get the document data about current content.
    public override func contents(forType typeName: String) throws -> Any {
        return try self.content.accessModelData()
    }
    
    /// Loads the document data into the app’s data model.
    public override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // super.load(fromContents: contents, ofType: typeName)
        guard let data = contents as? Data else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.fileData = data
        self.content = try .createModel(from: data)
    }
    
    /// Tells your object that the presented item moved or was renamed.
    public override func presentedItemDidMove(to newURL: URL) {
        super.presentedItemDidMove(to: newURL)
        Task { @MainActor in
            self.documentModel?.updateUI()
        }
    }
    
    public override func presentedItemDidGain(_ version: NSFileVersion) {
        super.presentedItemDidGain(version)
        if self.conflictedVersions.contains(where: { item in
            item.fileVersion.isEqual(to: version)
        }) {
            return
        }
        self.conflictedVersions.append(.init(fileVersion: version))
        Task { @MainActor in
            self.documentModel?.updateUI()
        }
    }
    
    public override func presentedItemDidLose(_ version: NSFileVersion) {
        super.presentedItemDidLose(version)
        self.conflictedVersions.removeAll { item in
            item.fileVersion.isEqual(to: version)
        }
        Task { @MainActor in
            self.documentModel?.updateUI()
        }
    }
    
    public override func accommodatePresentedItemDeletion(completionHandler: @escaping @Sendable ((any Error)?) -> Void) {
        guard !self.documentState.contains(.closed) else { return }
        super.close { _ in
            self.isClosed = true
            self.isDeleted = true
            self.conflictedVersions = []
            super.accommodatePresentedItemDeletion { error in
                completionHandler(error)
                Task { @MainActor in
                    self.documentModel?.updateUI()
                }
            }
        }
    }
    
    /// Asynchronously closes the document after saving any changes.
    public override func close(completionHandler: ((Bool) -> Void)? = nil) {
        let onCompletion = { (isSucceed: Bool) -> Void in
            completionHandler?(isSucceed)
            self.isClosed = true
            self.conflictedVersions = []
            self.documentModel?.updateUI()
        }
        super.close(completionHandler: onCompletion)
    }
}

/// Data structure for indicating possible conflicts in document versions.
@MainActor
@available(iOS 13.0, *)
public struct ConflictedVersion<FileModel>: Identifiable where FileModel: CloudFileModel {
    public let id = UUID()
    /// The string containing the user-presentable name of the file version.
    public var localizedName: String? {
        self.fileVersion.localizedName
    }
    /// The file URL about current conflicted file.
    ///
    /// This value may not necessarily be equal to the fileURL of the `UIDocument`.
    ///
    /// The location of file versions is managed by the system and should **not** be exposed to the user.
    public var url: URL {
        self.fileVersion.url
    }
    /// The modification date of the version.
    ///
    /// If the version has been invalid, this value is `nil`.
    public var date: Date? {
        self.fileVersion.modificationDate
    }
    /// The content of the current conflicted document version as a `String`.
    public var content: FileModel {
        get throws {
            let doc = CloudDocument<FileModel>(fileURL: self.url)
            try doc.read(from: self.url)
            return doc.content
        }
    }
    /// The `NSFileVersion` instance about current version.
    fileprivate let fileVersion: NSFileVersion
    init(fileVersion: NSFileVersion) {
        self.fileVersion = fileVersion
    }
}

@available(*, unavailable)
extension ConflictedVersion: Hashable {}

@available(iOS 13.0, *)
extension ConflictedVersion: Sendable {}

extension URL {
    fileprivate var _versionedPath: String {
        return if #available(iOS 16.0, *) {
            self.path(percentEncoded: false)
        } else {
            self.path
        }
    }
}

extension NSFileVersion: @unchecked Sendable {}

extension NSFileVersion {
    fileprivate var persistentIdentifierData: Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: self.persistentIdentifier, requiringSecureCoding: false)
    }
    
    fileprivate func isEqual(to version: NSFileVersion) -> Bool {
        if self == version || self === version || self.url == version.url || (self.url._versionedPath as NSString).standardizingPath == (version.url._versionedPath as NSString).standardizingPath {
            return true
        }
        if let data = self.persistentIdentifierData, data == version.persistentIdentifierData {
            return true
        }
        return false
    }
}

#endif
