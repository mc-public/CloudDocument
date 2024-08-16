//
//  CloudFileModel.swift
//
//
//  Created by 孟超 on 2024/8/16.
//

#if canImport(UIKit)
import Foundation

/// The protocols that need to be followed when implementing data structures for cloud file read and write operations.
///
/// - Note: The objects following this protocol will be created or destructed multiple times throughout the lifecycle of `CloudFilePresenter`.
@available(iOS 13.0, *)
public protocol CloudFileModel: Sendable {
    /// Create an instance representing an empty file.
    ///
    /// The method should be callable from any thread when implemented.
    static func createEmptyModel() -> Self
    
    /// Create a file instance based on the specified data.
    ///
    /// The method should be callable from any thread when implemented.
    static func createModel(from data: Data) throws -> Self
    
    /// Return the data corresponding to the current instance.
    ///
    /// The method should be callable from any thread when implemented.
    func accessModelData() throws -> Data
    
    /// Return the file data information corresponding to the create of the current model.
    ///
    /// The `CloudFilePresenter` uses this property to load the information of the every time the document is read from file storage. For example, this attribute can be used to store the actual encoding of string data read during the data decoding.
    ///
    /// If this functionality is not needed, simply return `nil` when implementing this property. 
    var dataInfo: DataInfo? { get }
    
    /// Information on updated document data when loading file content
    ///
    /// This information describes the characteristics of the document file data.
    associatedtype DataInfo
}

#endif
