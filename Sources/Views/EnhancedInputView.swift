// EnhancedInputView.swift
// Claude Desktop Mac - Enhanced Input View
//
// Message input area with file upload, image paste, and drag-drop support

import SwiftUI
import Theme
import Models
import State
import Upload

// MARK: - Enhanced Input View

public struct EnhancedInputView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    @Bindable var inputState: MessageInputState
    @Bindable var imageUploader: ImageUploader
    @Bindable var fileUploader: FileUploader

    let connectionState: ConnectionState
    let isStreaming: Bool
    let projectPath: String?
    let model: String

    let onSend: () -> Void
    let onInterrupt: () -> Void
    let onAttachFiles: (([URL]) -> Void)?

    @FocusState private var isInputFocused: Bool

    // Drag and drop state
    @State private var isDropTarget: Bool = false
    @State private var showAttachmentPicker: Bool = false

    public init(
        inputState: MessageInputState,
        imageUploader: ImageUploader,
        fileUploader: FileUploader,
        connectionState: ConnectionState,
        isStreaming: Bool,
        projectPath: String?,
        model: String,
        onSend: @escaping () -> Void,
        onInterrupt: @escaping () -> Void,
        onAttachFiles: (([URL]) -> Void)? = nil
    ) {
        self.inputState = inputState
        self.imageUploader = imageUploader
        self.fileUploader = fileUploader
        self.connectionState = connectionState
        self.isStreaming = isStreaming
        self.projectPath = projectPath
        self.model = model
        self.onSend = onSend
        self.onInterrupt = onInterrupt
        self.onAttachFiles = onAttachFiles
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Attachment previews
            attachmentPreviewsView

            // Input area
            HStack(alignment: .bottom, spacing: Spacing.md.rawValue) {
                // Attachment button
                attachmentButton

                // Text input with drop support
                dropTargetView

                // Send/Stop button
                sendOrStopButton
            }
            .padding(.horizontal, Spacing.lg.rawValue)
            .padding(.vertical, Spacing.md.rawValue)

            // Info bar
            InputInfoBar(
                projectPath: projectPath,
                model: model,
                connectionState: connectionState
            )
        }
        .background(Color.bgSecondary(scheme: colorScheme))
        .onSubmit {
            if inputState.canSend && !isStreaming {
                onSend()
            }
        }
        .onPasteCommand(of: [.png, .tiff, .fileURL]) { providers in
            handlePaste(providers: providers)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Message input area")
        .sheet(isPresented: $showAttachmentPicker) {
            AttachmentPickerSheet(
                imageUploader: imageUploader,
                fileUploader: fileUploader
            )
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var attachmentPreviewsView: some View {
        if !imageUploader.attachments.isEmpty || !fileUploader.attachments.isEmpty {
            VStack(spacing: Spacing.sm.rawValue) {
                // Image previews
                if !imageUploader.attachments.isEmpty {
                    ImagePreviewView(uploader: imageUploader)
                }

                // File previews
                if !fileUploader.attachments.isEmpty {
                    FileAttachmentView(uploader: fileUploader)
                }
            }
            .padding(.horizontal, Spacing.lg.rawValue)
            .padding(.top, Spacing.sm.rawValue)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var attachmentButton: some View {
        Menu {
            Button {
                showAttachmentPicker = true
            } label: {
                Label("Choose Files...", systemImage: "doc")
            }

            Button {
                // Open file picker for images
                pickImages()
            } label: {
                Label("Choose Images...", systemImage: "photo")
            }

            Divider()

            if canPasteFromClipboard {
                Button {
                    Task {
                        await imageUploader.addImageFromPasteboard()
                    }
                } label: {
                    Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                }
            }
        } label: {
            Image(systemName: "paperclip")
                .font(.system(size: 16))
                .foregroundColor(attachmentButtonColor)
        }
        .menuStyle(.borderlessButton)
        .disabled(connectionState != .connected || isStreaming)
        .help("Attach files or images")
    }

    private var attachmentButtonColor: Color {
        if connectionState != .connected || isStreaming {
            return Color.fgTertiary(scheme: colorScheme)
        }
        if !imageUploader.attachments.isEmpty || !fileUploader.attachments.isEmpty {
            return .accentPrimary
        }
        return Color.fgSecondary(scheme: colorScheme)
    }

    private var dropTargetView: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if inputState.text.isEmpty && !isDropTarget {
                Text(placeholderText)
                    .font(.inputText)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .padding(.horizontal, Spacing.md.rawValue)
                    .padding(.vertical, Spacing.sm.rawValue + 4)
                    .accessibilityHidden(true)
            }

            // Drop indicator overlay
            if isDropTarget {
                dropIndicatorOverlay
            }

            // Text editor
            TextEditor(text: $inputState.text)
                .font(.inputText)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                .focused($isInputFocused)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 36, maxHeight: WindowDimensions.inputMaxHeight - 48)
                .disabled(connectionState != .connected || isStreaming)
        }
        .padding(.horizontal, Spacing.sm.rawValue)
        .padding(.vertical, Spacing.xs.rawValue)
        .background(dropTargetBackground)
        .cornerRadius(CornerRadius.md.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .stroke(enhancedInputBorderColor, lineWidth: enhancedInputBorderWidth)
        )
        .onDrop(of: [.fileURL, .image, .png, .tiff], isTargeted: $isDropTarget) { providers in
            handleDrop(providers: providers)
        }
        .onAppear {
            isInputFocused = true
        }
    }

    @ViewBuilder
    private var dropIndicatorOverlay: some View {
        VStack(spacing: Spacing.sm.rawValue) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 24))
                .foregroundColor(.accentPrimary)

            Text("Drop files or images here")
                .font(.callout)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary(scheme: colorScheme).opacity(0.8))
    }

    private var dropTargetBackground: Color {
        if isDropTarget {
            return Color.accentPrimary.opacity(0.1)
        }
        return Color.bgTertiary(scheme: colorScheme)
    }

    @ViewBuilder
    private var sendOrStopButton: some View {
        if isStreaming {
            Button(action: onInterrupt) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .buttonStyle(.primary)
            .accessibilityLabel("Stop response")
            .accessibilityHint("Double tap to interrupt Claude's response")
            .help("Stop (Escape)")
        } else {
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .buttonStyle(.primary)
            .disabled(!canSend)
            .accessibilityLabel("Send message")
            .accessibilityHint("Double tap to send your message")
            .help("Send (Cmd+Enter)")
        }
    }

    // MARK: - Computed Properties

    private var placeholderText: String {
        if connectionState != .connected {
            return "Connect to Claude to start..."
        } else if isStreaming {
            return "Waiting for response..."
        } else {
            return "Type your message... (Cmd+Enter to send, drag files to attach)"
        }
    }

    private var canSend: Bool {
        inputState.canSend && connectionState == .connected
    }

    private var canPasteFromClipboard: Bool {
        let pasteboard = NSPasteboard.general
        return pasteboard.canReadItem(withDataConformingToTypes: [.png, .tiff, .fileURL])
    }

    private var enhancedInputBorderColor: Color {
        if highContrast {
            return isInputFocused ? Color.accentPrimaryHighContrast : Color.fgSecondaryHighContrast
        }
        if isDropTarget {
            return Color.accentPrimary
        }
        return isInputFocused ? Color.accentPrimary : Color.fgTertiary(scheme: colorScheme).opacity(0.3)
    }

    private var enhancedInputBorderWidth: CGFloat {
        highContrast ? 2 : (isInputFocused || isDropTarget ? 2 : 1)
    }

    // MARK: - Actions

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false

        for provider in providers {
            // Handle image data
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let uiImage = image as? UIImage, let data = uiImage.pngData() {
                        Task { @MainActor in
                            await imageUploader.addImage(from: data, fileName: "dropped-image.png")
                        }
                    }
                }
                handled = true
            }
            // Handle file URLs
            else if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, error in
                    if let data = data as? Data,
                       let urlString = String(data: data, encoding: .utf8),
                       let url = URL(string: urlString) {
                        Task { @MainActor in
                            await handleFileURL(url)
                        }
                    } else if let url = data as? URL {
                        Task { @MainActor in
                            await handleFileURL(url)
                        }
                    }
                }
                handled = true
            }
        }

        return handled
    }

    private func handleFileURL(_ url: URL) async {
        // Check if it's an image
        let ext = url.pathExtension.lowercased()
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "bmp", "tiff", "tif"]

        if imageExtensions.contains(ext) {
            await imageUploader.addImage(from: url)
        } else {
            await fileUploader.addFile(from: url)
        }
    }

    private func handlePaste(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.tiff.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.png.identifier, options: nil) { data, error in
                    if let data = data as? Data {
                        Task { @MainActor in
                            await imageUploader.addImage(from: data, fileName: "pasted-image.png")
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                    if let data = data as? Data,
                       let urlString = String(data: data, encoding: .utf8),
                       let url = URL(string: urlString) {
                        Task { @MainActor in
                            await handleFileURL(url)
                        }
                    }
                }
            }
        }
    }

    private func pickImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK {
            Task {
                for url in panel.urls {
                    await imageUploader.addImage(from: url)
                }
            }
        }
    }
}

// MARK: - Attachment Picker Sheet

public struct AttachmentPickerSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Bindable var imageUploader: ImageUploader
    @Bindable var fileUploader: FileUploader

    @State private var selectedTab: AttachmentTab = .images

    enum AttachmentTab: String, CaseIterable {
        case images = "Images"
        case files = "Files"

        var iconName: String {
            switch self {
            case .images: return "photo"
            case .files: return "doc"
            }
        }
    }

    public init(
        imageUploader: ImageUploader,
        fileUploader: FileUploader
    ) {
        self.imageUploader = imageUploader
        self.fileUploader = fileUploader
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Attach Files")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg.rawValue)

            Divider()

            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(AttachmentTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.iconName)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.lg.rawValue)
            .padding(.vertical, Spacing.md.rawValue)

            // Content
            Group {
                switch selectedTab {
                case .images:
                    ImagePickerView(uploader: imageUploader)
                case .files:
                    FilePickerView(uploader: fileUploader)
                }
            }

            Divider()

            // Footer
            HStack {
                if let error = imageUploader.errorMessage ?? fileUploader.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.accentError)
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.primary)
            }
            .padding(Spacing.lg.rawValue)
        }
        .frame(width: 500, height: 400)
        .background(Color.bgPrimary(scheme: colorScheme))
    }
}

// MARK: - Image Picker View

private struct ImagePickerView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var uploader: ImageUploader

    var body: some View {
        VStack(spacing: Spacing.lg.rawValue) {
            // Image previews
            if !uploader.attachments.isEmpty {
                ImagePreviewView(uploader: uploader)
            }

            Spacer()

            // Add images button
            Button {
                pickImages()
            } label: {
                Label("Choose Images", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.secondary)
            .disabled(!uploader.canAddMore)

            // Info text
            Text("Supported formats: JPG, PNG, GIF, WebP. Max 10MB per image, up to 5 images.")
                .font(.caption)
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg.rawValue)
    }

    private func pickImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK {
            Task {
                for url in panel.urls {
                    await uploader.addImage(from: url)
                }
            }
        }
    }
}

// MARK: - File Picker View

private struct FilePickerView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var uploader: FileUploader

    var body: some View {
        VStack(spacing: Spacing.lg.rawValue) {
            // File previews
            if !uploader.attachments.isEmpty {
                FileAttachmentView(uploader: uploader)
            }

            Spacer()

            // Add files button
            Button {
                pickFiles()
            } label: {
                Label("Choose Files", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.secondary)
            .disabled(!uploader.canAddMore)

            // Info text
            Text("Supported formats: Code, Config, Documents, Data files. Max 5MB per file, up to 20MB total.")
                .font(.caption)
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg.rawValue)
    }

    private func pickFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .sourceCode, .script, .json, .yaml, .xml, .plainText,
            .init(filenameExtension: "md")!, .init(filenameExtension: "toml")!,
            .init(filenameExtension: "csv")!, .init(filenameExtension: "sql")!
        ]

        if panel.runModal() == .OK {
            Task {
                await uploader.addFiles(from: panel.urls)
            }
        }
    }
}

// MARK: - UTType Extension

import UniformTypeIdentifiers

extension UTType {
    static var sourceCode: UTType {
        UTType(filenameExtension: "swift") ?? .sourceCode
    }
}

// MARK: - Preview

#Preview("Enhanced Input View") {
    VStack {
        Spacer()

        EnhancedInputView(
            inputState: {
                let state = MessageInputState()
                state.text = "Hello, Claude!"
                return state
            }(),
            imageUploader: ImageUploader(),
            fileUploader: FileUploader(),
            connectionState: .connected,
            isStreaming: false,
            projectPath: "/Users/dev/project",
            model: "claude-sonnet-4.6",
            onSend: {},
            onInterrupt: {}
        )
    }
    .frame(width: 600, height: 300)
    .background(Color.bgPrimaryDark)
}
