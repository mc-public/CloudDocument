# CloudDocument

![](https://img.shields.io/badge/Platform_Compatibility-iOS13.0+-blue)
![](https://img.shields.io/badge/Swift_Compatibility-5.8-red)

CloudDocument uses `UIDocument` to coordinate access to iCloud documents, providing a simple and powerful API for handling conflicts related to syncing with iCloud documents. It is suitable for both SwiftUI and UIKit applications.
    

## Features

- Asynchronous and error-handling based API.
- Simple and powerful API for controlling file saving.
- Simple and powerful API for handling cloud file conflicts.
- Renaming of `URL` from `UIDocumentBrowserViewController` in a document-based application on UIKit or SwiftUI in iOS 16.0.

## Usage Example

Detailed descriptions of all documents are available in the source code files. Here is a brief overview of how to use it.

### Make Data Structure Conform to `CloudFilePresenter` Protocol

For example, here is an example of making the `String` type conform to the `CloudFilePresenter` protocol.
```swift
extension String: CloudFilePresenter {
    public static func createEmptyPresenter() -> String {
        .init()
    }
    public static func createPresenter(from data: Data) throws -> String {
        String(data: data) ?? .init()
    }
    public func getPresentedData() throws -> Data {
        guard let data = self.data(using: .fastest) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return data
    }
}
```
It is important to note that types conforming to this protocol must be value types, otherwise it will lead to unexpected behavior.

### Load File Model and Use in SwiftUI

Here is an example code snippet.
```swift
import SwiftUI
import UIKit

struct DocumentEditor: View {
    @StateObject var document: CloudFileModel<String>
    var body: some View {
        Text(self.document.content)
    }
}

class DocumentBrowserViewController: UIDocumentBrowserViewController {
    func presentDocument(at url: URL) async throws {
        let document = try await CloudFileModel<String>(fileURL: url, documentBrowser: self)
        let hostViewController = UIHostingController(rootView: DocumentEditor(model: document))
        hostViewController.modalPresentationStyle = .fullScreen
        hostViewController.sizingOptions = .preferredContentSize
        self.present(hostViewController, animated: true)
    }
}
```

## Notes

If you want to fully utilize SwiftUI for editing documents in a UIKit-based document class app, you need to remove the Storyboard, otherwise it may cause abnormal sizes for SwiftUI views.
