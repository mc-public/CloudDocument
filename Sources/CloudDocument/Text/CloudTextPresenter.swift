//
//  CloudTextPresenter.swift
//
//
//  Created by 孟超 on 2024/8/16.
//

#if canImport(UIKit)
import UIKit
import SwiftUI
/// `CloudFilePresenter` subclass for managing iCloud text files and coordinating file access.
public class CloudTextPresenter: CloudFilePresenter<CloudTextModel> {
    
    @available(*, unavailable)
    public override var fileDataInfo: CloudTextModel.Encoding? {
        super.fileDataInfo
    }
    
    @available(*, unavailable)
    public override var content: CloudTextModel {
        super.content
    }
    /// The file content of the current text document.
    public var text: String {
        super.content.string
    }
    
    /// Encoding used when loading the current document file
    ///
    /// By default, the encoding detected when firstly reading the file is used. If subsequent modifications include content from other encoding sets, UTF-8 encoding will be automatically used.
    public var fileEncoding: CloudTextModel.Encoding {
        super.fileDataInfo ?? .utf8
    }
    
    @available(*, unavailable)
    public override func saveDocument(for content: CloudTextModel) async throws {
        try await super.saveDocument(for: content)
    }
    
    /// Save the file with the specified text.
    ///
    /// This method can only be called when the document is in a `.normal` state. Otherwise, an error will be thrown.
    ///
    /// - Note: If the document status is illegal, this method will throw an error `Self.State`.
    public func saveDocument(for content: String) async throws {
        try await super.saveDocument(for: CloudTextModel(string: content, encoding: self.fileEncoding))
    }
}




#endif
