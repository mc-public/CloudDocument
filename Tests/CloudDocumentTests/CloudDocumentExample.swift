//
//  CloudDocumentExample.swift
//
//
//  Created by 孟超 on 2024/8/15.
//

import Foundation
@testable import CloudDocument

extension String: CloudFilePresenter {
    public static func createEmptyPresenter() -> String {
        .init()
    }
    public static func createPresenter(from data: Data) throws -> String {
        String(data: data, encoding: .utf8) ?? .init()
    }
    public func getPresentedData() throws -> Data {
        guard let data = self.data(using: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return data
    }
}

typealias CloudTextFileModel = CloudFileModel<String>
