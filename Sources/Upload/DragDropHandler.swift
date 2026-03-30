// DragDropHandler.swift
// Claude Desktop Mac - Drag and Drop Handling
//
// Handles drag and drop operations for files and images

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drop Delegate

/// Handles drop operations for file and image attachments
public class DropDelegate: DropDelegateProtocol {
    private let onImageDrop: (Data, String) -> Void
    private let onFileDrop: ([URL]) -> Void
    private let onDropStateChanged: (Bool) -> Void

    public init(
        onImageDrop: @escaping (Data, String) -> Void,
        onFileDrop: @escaping ([URL]) -> Void,
        onDropStateChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.onImageDrop = onImageDrop
        self.onFileDrop = onFileDrop
        self.onDropStateChanged = onDropStateChanged
    }

    public func validateDrop(info: DropInfo) -> Bool {
        // Check for images
        if info.hasItemsConforming(to: [.image]) {
            return true
        }

        // Check for file URLs
        if info.hasItemsConforming(to: [.fileURL]) {
            return true
        }

        // Check for plain text URLs
        if info.hasItemsConforming(to: [.plainText]) {
            return true
        }

        return false
    }

    public func dropEntered(info: DropInfo) {
        onDropStateChanged(true)
    }

    public func dropExited(info: DropInfo) {
        onDropStateChanged(false)
    }

    public func performDrop(info: DropInfo) -> Bool {
        onDropStateChanged(false)

        var hasProcessed = false

        // Handle image items
        let imageProviders = info.itemProviders(for: [.image])
        for provider in imageProviders {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, error in
                if let data = data as? Data {
                    let fileName = provider.suggestedName ?? "dropped-image.png"
                    DispatchQueue.main.async {
                        self.onImageDrop(data, fileName)
                    }
                } else if let url = data as? URL {
                    DispatchQueue.main.async {
                        if let imageData = try? Data(contentsOf: url) {
                            self.onImageDrop(imageData, url.lastPathComponent)
                        }
                    }
                }
            }
            hasProcessed = true
        }

        // Handle file URL items
        let fileProviders = info.itemProviders(for: [.fileURL])
        var fileURLs: [URL] = []

        let group = DispatchGroup()

        for provider in fileProviders {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                defer { group.leave() }

                if let data = data as? Data,
                   let urlString = String(data: data, encoding: .utf8),
                   let url = URL(string: urlString) {
                    fileURLs.append(url)
                } else if let url = data as? URL {
                    fileURLs.append(url)
                }
            }
            hasProcessed = true
        }

        group.notify(queue: .main) {
            if !fileURLs.isEmpty {
                self.onFileDrop(fileURLs)
            }
        }

        return hasProcessed
    }
}

// MARK: - Drop Delegate Protocol

/// Protocol for drop delegate (for testing/mocking)
public protocol DropDelegateProtocol {
    func validateDrop(info: DropInfo) -> Bool
    func dropEntered(info: DropInfo) -> Void
    func dropExited(info: DropInfo) -> Void
    func performDrop(info: DropInfo) -> Bool
}

// MARK: - Drag Drop Handler

/// Manages drag and drop operations
@MainActor
@Observable
public final class DragDropHandler {

    // MARK: - Properties

    public var isDropTargeted: Bool = false
    public var droppedFiles: [URL] = []
    public var droppedImages: [(data: Data, name: String)] = []

    // MARK: - Callbacks

    public var onImageReceived: ((Data, String) -> Void)?
    public var onFilesReceived: (([URL]) -> Void)?

    // MARK: - Initialization

    public init() {}

    // MARK: - Drop Delegate Creation

    /// Create a drop delegate for handling drops
    public func createDropDelegate() -> DropDelegate {
        DropDelegate(
            onImageDrop: { [weak self] data, name in
                self?.handleImageDrop(data: data, name: name)
            },
            onFileDrop: { [weak self] urls in
                self?.handleFileDrop(urls: urls)
            },
            onDropStateChanged: { [weak self] isTargeted in
                self?.isDropTargeted = isTargeted
            }
        )
    }

    // MARK: - Drop Handlers

    private func handleImageDrop(data: Data, name: String) {
        droppedImages.append((data: data, name: name))
        onImageReceived?(data, name)
    }

    private func handleFileDrop(urls: [URL]) {
        droppedFiles.append(contentsOf: urls)
        onFilesReceived?(urls)
    }

    // MARK: - Clear

    public func clearDroppedItems() {
        droppedFiles.removeAll()
        droppedImages.removeAll()
    }
}

// MARK: - Drop Overlay View

/// A view that displays when dragging files over the drop target
public struct DropOverlayView: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 48))
                .foregroundColor(.accentPrimary)

            Text("Drop files here")
                .font(.title3)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))

            Text("Images, code files, documents")
                .font(.caption)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary(scheme: colorScheme).opacity(0.95))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg.rawValue)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundColor(.accentPrimary)
        )
    }
}

// MARK: - Drop Area Modifier

extension View {
    /// Add drop handling to a view
    public func dropArea(
        handler: DragDropHandler,
        isTargeted: Binding<Bool>
    ) -> some View {
        self.onDrop(
            of: [.image, .fileURL],
            isTargeted: isTargeted,
            perform: { providers in
                handleDrop(providers: providers, handler: handler)
            }
        )
    }

    private func handleDrop(providers: [NSItemProvider], handler: DragDropHandler) -> Bool {
        var hasHandled = false

        for provider in providers {
            // Check for image
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, error in
                    if let data = data as? Data {
                        let name = provider.suggestedName ?? "dropped-image.png"
                        Task { @MainActor in
                            handler.onImageReceived?(data, name)
                        }
                    } else if let url = data as? URL, let data = try? Data(contentsOf: url) {
                        Task { @MainActor in
                            handler.onImageReceived?(data, url.lastPathComponent)
                        }
                    }
                }
                hasHandled = true
            }

            // Check for file URL
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                    var url: URL?

                    if let data = data as? Data,
                       let urlString = String(data: data, encoding: .utf8) {
                        url = URL(string: urlString)
                    } else if let fileURL = data as? URL {
                        url = fileURL
                    }

                    if let url = url {
                        Task { @MainActor in
                            handler.onFilesReceived?([url])
                        }
                    }
                }
                hasHandled = true
            }
        }

        return hasHandled
    }
}

// MARK: - Input Drop Area View

/// A combined view for input area with drop support
public struct InputDropAreaView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let content: Content
    let handler: DragDropHandler

    @State private var isTargeted = false

    public init(handler: DragDropHandler, @ViewBuilder content: () -> Content) {
        self.handler = handler
        self.content = content()
    }

    public var body: some View {
        ZStack {
            content
                .onDrop(
                    of: [.image, .fileURL],
                    isTargeted: $isTargeted,
                    perform: { providers in
                        handleDrop(providers: providers)
                    }
                )

            if isTargeted {
                DropOverlayView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
        .onChange(of: isTargeted) { _, newValue in
            handler.isDropTargeted = newValue
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var hasHandled = false

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, error in
                    if let data = data as? Data {
                        let name = provider.suggestedName ?? "dropped-image.png"
                        Task { @MainActor in
                            handler.onImageReceived?(data, name)
                        }
                    }
                }
                hasHandled = true
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                    var url: URL?

                    if let data = data as? Data,
                       let urlString = String(data: data, encoding: .utf8) {
                        url = URL(string: urlString)
                    } else if let fileURL = data as? URL {
                        url = fileURL
                    }

                    if let url = url {
                        Task { @MainActor in
                            handler.onFilesReceived?([url])
                        }
                    }
                }
                hasHandled = true
            }
        }

        return hasHandled
    }
}
