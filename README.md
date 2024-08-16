# CloudDocument

![](https://img.shields.io/badge/Platform_Compatibility-iOS13.0+-blue)
![](https://img.shields.io/badge/Swift_Compatibility-5.8-red)

CloudDocument uses `UIDocument` to coordinate access to iCloud documents, providing a simple and powerful API for handling conflicts related to syncing with iCloud documents. It is suitable for both SwiftUI and UIKit applications.
    

## Features

- Asynchronous and error-handling based API.
- Simple and powerful API for controlling file saving.
- Simple and powerful API for handling cloud file conflicts.
- Renaming of `URL` from `UIDocumentBrowserViewController` in a document-based application on UIKit or SwiftUI in iOS 16.0.
- A class `CloudTextPresenter` for automatically processing text files and text encoding has been provided.

## Usage Example

Detailed descriptions of all documents are available in the source code files. Here is a brief overview of how to use it.

### Make Data Structure Conform to `CloudFileModel` Protocol

For example, here is an example of making the `String` type conform to the `CloudFileModel` protocol.
```swift
extension String: CloudFileModel {
    public typealias DataInfo = String.Encoding
    public static func createEmptyModel() -> String {
        .init()
    }
    public static func createModel(from data: Data) throws -> String {
        String(data: data, encoding: self.dataInfo!) ?? .init()
    }
    public func accessModelData() throws -> Data {
        guard let data = self.data(using: self.dataInfo!) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return data
    }
     var dataInfo: DataInfo? { .utf8 }
}
```
It is important to note that types conforming to this protocol must be valuable semantics. Otherwise it will lead to unexpected behavior.

### Load File Model and Use in SwiftUI

Here is an example code snippet.
```swift
import SwiftUI
import UIKit

struct DocumentEditor: View {
    @StateObject var document: CloudFilePresenter<String>
    var body: some View {
        Text(self.document.content)
    }
}

class DocumentBrowserViewController: UIDocumentBrowserViewController {
    func presentDocument(at url: URL) async throws {
        let document = try await CloudFilePresenter<String>(fileURL: url, documentBrowser: self)
        let hostViewController = UIHostingController(rootView: DocumentEditor(model: document))
        hostViewController.modalPresentationStyle = .fullScreen
        hostViewController.sizingOptions = .preferredContentSize
        self.present(hostViewController, animated: true)
    }
}
```

## Notes

If you want to fully utilize SwiftUI for editing documents in a UIKit-based document class app, you need to remove the Storyboard, otherwise it may cause abnormal sizes for SwiftUI views.
