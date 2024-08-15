//
//  CloudFileModel.swift
//  
//
//  Created by 孟超 on 2024/8/15.
//

#if canImport(UIKit)

import UIKit
import SwiftUI



@available(iOS 13.0, *)
public protocol CloudFileModelDelegate: AnyObject {
    /// The method called when the state of the model may been updated from one state to another.
    ///
    /// This function is called at main queue or `MainActor`.
    func modelStateDidChanged()
}

/// The protocols that need to be followed when implementing data structures for cloud file read and write operations.
@available(iOS 13.0, *)
public protocol CloudFilePresenter: Sendable {
    /// Create an instance representing an empty file.
    ///
    /// The method should be callable from any thread when implemented.
    static func createEmptyPresenter() -> Self
    /// Create a file instance based on the specified data.
    ///
    /// The method should be callable from any thread when implemented.
    static func createPresenter(from data: Data) throws -> Self
    /// Return the data corresponding to the current instance.
    ///
    /// The method should be callable from any thread when implemented.
    func getPresentedData() throws -> Data
}

@available(iOS 13.0, *)
@MainActor
public class CloudFileModel<FilePresenter>: ObservableObject where FilePresenter: CloudFilePresenter {
    public typealias Version = ConflictedVersion<FilePresenter>
    typealias Document = CloudDocument<FilePresenter>
    
    /// Enum for Current Document Status.
    public enum State: String, Error {
        /// The document status is normal.
        case normal
        /// The document status is marked as deleted.
        ///
        /// Please refrain from saving the file or resolving conflicts at this time.
        case deleted
        /// The document status is closed.
        ///
        /// At this point, only access to all properties within this class is allowed, please do not access any methods within this class.
        case closed
        /// The document status is conflicted.
        ///
        /// At this point, only access to all properties within this class is allowed, as well as method to resolve the conflict ``selectVersion(for:)``.
        case conflicted
    }
    
    
    private let document: Document
    private weak var documentBrowser: UIDocumentBrowserViewController?
    
    /// The document status.
    public var state: State {
        if self.document.isDeleted { return .deleted }
        else if self.document.isClosed { return .closed }
        else if self.document.documentState.contains(.inConflict) || !self.conflictedVersions.isEmpty {
            return .conflicted
        } else {
            return .normal
        }
    }
    /// The state management delegate of current delegate.
    public var delegate: (any CloudFileModelDelegate)?
    
    /// Retrieve the cloud storage version corresponding to the current document.
    ///
    /// If the document has already been deleted, this method will throw an error.
    public var currentVersion: Version {
        get throws {
            guard let version = NSFileVersion.currentVersionOfItem(at: self.fileURL) else {
                throw CocoaError(.fileNoSuchFile)
            }
            return Version(fileVersion: version)
        }
    }

    /// Cloud document version conflicting with the current document version.
    ///
    /// When the current document's status is not conflict, the value of this property is an empty array.
    public var conflictedVersions: [Version] {
        self.document.conflictedVersions
    }
    
    /// The file URL of the current text document.
    public var fileURL: URL {
        self.document.fileURL
    }
    /// The file name of the current text document.
    public var fileName: String {
        self.document.localizedName
    }
    
    /// The file content of the current text document.
    public var content: FilePresenter {
        self.document.content
    }
    
    /// Indicate whether the current document has been deleted.
    public var isDeleted: Bool {
        self.document.isDeleted
    }
    
    
    /// Indicate whether the current document has been closed.
    public var isClosed: Bool {
        self.document.isClosed
    }
    
    /// Construct the current model using the specified iCloud file URL.
    ///
    /// - Parameter fileURL: The Cloud file `URL` that can be accessed within a secure scope. They are typically derived from `UIDocumentBrowserViewController` or `UIDocumentPickerViewController` or SwiftUI `DocumentGroup` or SwiftUI `.fileImporter`.
    /// - Parameter documentBrowser: If the `URL` corresponding to the first parameter comes from the `UIDocumentBrowserViewController`, you can pass this parameter to achieve document renaming.
    /// - Note: If you want to use file renaming operations with `DocumentGroup` in SwiftUI, you can access the root view controller of the current `Scene` using @`SceneDelegate` and pass that controller into this parameter.
    @available(iOS 16.0, *)
    public init(fileURL: URL, documentBrowser: UIDocumentBrowserViewController? = nil) async throws {
        self.documentBrowser = documentBrowser
        self.document = .init(fileURL: fileURL)
        self.document.setDocumentModel(for: self)
        try await self.document.load()
    }
    
    /// Construct the current model using the specified iCloud file URL.
    ///
    /// - Parameter fileURL: The Cloud file `URL` that can be accessed within a secure scope. They are typically derived from `UIDocumentBrowserViewController` or `UIDocumentPickerViewController` or SwiftUI `DocumentGroup` or SwiftUI `.fileImporter`.
    /// - Parameter documentBrowser: If the `URL` corresponding to the first parameter comes from the `UIDocumentBrowserViewController`, you can pass this parameter to achieve document renaming.
    /// - Note: If you want to use file renaming operations with `DocumentGroup` in SwiftUI, you can access the root view controller of the current `Scene` using @`SceneDelegate` and pass that controller into this parameter.
    @available(iOS 16.0, *)
    public init(fileURL: URL, documentBrowser: UIDocumentBrowserViewController? = nil) {
        self.documentBrowser = documentBrowser
        self.document = .init(fileURL: fileURL)
        self.document.setDocumentModel(for: self)
        Task {
            try await self.document.load()
        }
    }
    
    /// Construct the current model using the specified iCloud file URL.
    ///
    /// - Parameter fileURL: The Cloud file `URL` that can be accessed within a secure scope. They are typically derived from `UIDocumentBrowserViewController` or `UIDocumentPickerViewController` or SwiftUI `DocumentGroup` or SwiftUI `.fileImporter`.
    @available(iOS, obsoleted: 16.0, message: "Please use init(fileURL:documentBrowser).")
    public init(fileURL: URL) async throws {
        self.document = .init(fileURL: fileURL)
        self.document.setDocumentModel(for: self)
        try await self.document.load()
    }
    
    /// Construct the current model using the specified iCloud file URL.
    ///
    /// - Parameter fileURL: The Cloud file `URL` that can be accessed within a secure scope. They are typically derived from `UIDocumentBrowserViewController` or `UIDocumentPickerViewController` or SwiftUI `DocumentGroup` or SwiftUI `.fileImporter`.
    @available(iOS, obsoleted: 16.0, message: "Please use init(fileURL:documentBrowser).")
    public init(fileURL: URL) {
        self.document = .init(fileURL: fileURL)
        self.document.setDocumentModel(for: self)
        Task {
            try await self.document.load()
        }
    }
    
    /// Rename the actual file name corresponding to the current document.
    ///
    /// - Parameter proposedName: The proposed new name to rename the document to. If proposedName is already taken, the system might alter the proposed name and confirm the new suggestion with the user. The final name that the system chooses appears in the return value.
    ///
    /// - Returns: Return the new URL corresponding to the renamed file. If a suitable document browser instance was not passed in when the current class was constructed, this method will return `nil`.
    ///
    /// - Warning: If the document status is illegal, this method will throw an error `Self.State`.
    @discardableResult
    @available(iOS 16.0, *)
    public func renameDocument(proposedName: String) async throws -> URL? {
        guard let documentBrowser else {
            return nil
        }
        guard self.state != .deleted && self.state != .closed else {
            throw self.state
        }
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, any Error>) -> Void in
            documentBrowser.renameDocument(at: self.fileURL, proposedName: proposedName) { newURL, error in
                if let error {
                    cont.resume(throwing: error)
                }
                else if let newURL { cont.resume(returning: newURL) }
                else { cont.resume(returning: self.fileURL) }
            }
        }
    }
    
    /// Save the file with the specified content and encoding.
    ///
    /// This method can only be called when the document is in a `.normal` state. Otherwise, an error will be thrown.
    ///
    /// - Warning: If the document status is illegal, this method will throw an error `Self.State`.
    public func saveDocument(for content: FilePresenter) async throws {
        guard self.state != .closed && self.state != .deleted else {
            throw self.state
        }
        self.document.content = content
        let isSucceed = await self.document.save(to: self.document.fileURL, for: .forOverwriting)
        guard !isSucceed else { return }
        let error = self.document.savingError ?? CocoaError(.fileWriteUnknown)
        throw error
    }
    
    /// Select the specified version to resolve the document conflict.
    ///
    /// This method can only be called when the document is in a `.conflicted` state. Otherwise, an error will be thrown.
    ///
    /// - Warning: If the document status is illegal, this method will throw an error `Self.State`.
    public func selectVersion(for version: Version) throws {
        guard self.state == .conflicted else {
            throw self.state
        }
        try self.document.selectVersion(for: version)
    }
    
    /// Safely close access to the current document.
    ///
    /// If the current class detects that the document has been deleted by another process, this method will be called automatically.
    ///
    /// This method can be safely called multiple times without repeatedly throwing errors.
    public func close() async {
        if self.isClosed { return }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.document.close { isSucceed in
                cont.resume()
            }
        }
    }
    
    @MainActor
    func updateUI() {
        self.delegate?.modelStateDidChanged()
        self.objectWillChange.send()
    }
}



#endif
