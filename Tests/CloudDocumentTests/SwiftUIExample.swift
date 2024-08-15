import XCTest
import SwiftUI
import UniformTypeIdentifiers
@testable import CloudDocument

@available(iOS 14.0, *)
struct ExampleDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.text]
    }
    init() {}
    init(configuration: ReadConfiguration) throws {}
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileReadCorruptFile)
    }
}

/// @main
class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {}

class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {}

@available(iOS 14.0, *)
struct CloudDocumentApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        DocumentGroup(newDocument: ExampleDocument()) { document in
            RootView(documentConfiguration: document)
        }
    }
}

@available(iOS 14.0, *)
struct RootView: View {
    @EnvironmentObject var sceneDelegate: SceneDelegate
    var documentConfiguration: FileDocumentConfiguration<ExampleDocument>
    var body: some View {
        ContentView(documentModel: .init(fileURL: documentConfiguration.fileURL!))
    }
}

@available(iOS 14.0, *)
struct ContentView: View {
    @StateObject var documentModel: CloudTextFileModel
    var body: some View {
        Spacer()
    }
}

