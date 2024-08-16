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
class CloudTextPresenter: CloudFilePresenter<CloudTextModel> {
    
    @available(*, unavailable)
    override var fileDataInfo: CloudTextModel.Encoding? {
        super.fileDataInfo
    }
    
    /// Encoding used when loading the current document file
    ///
    /// By default, the encoding detected when firstly reading the file is used. If subsequent modifications include content from other encoding sets, UTF-8 encoding will be automatically used.
    var fileEncoding: CloudTextModel.Encoding {
        super.fileDataInfo ?? .utf8
    }
}




#endif
