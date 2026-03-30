// FileUploader.swift
// Claude Desktop Mac - File Upload Handling
//
// Handles file upload, validation, and preview

import SwiftUI
import Combine
import Theme

// MARK: - File Attachment

/// Represents a file attachment for messages
public struct FileAttachment: Identifiable, Codable, Sendable {
    public let id: UUID
    public let fileName: String
    public let fileSize: Int64
    public let fileExtension: String
    public let mimeType: String
    public let fileURL: URL?
    public let data: Data?

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    public var icon: String {
        FileIconHelper.icon(for: fileExtension)
    }

    public var iconColor: Color {
        FileIconHelper.color(for: fileExtension)
    }

    public init(
        id: UUID = UUID(),
        fileName: String,
        fileSize: Int64,
        fileExtension: String,
        mimeType: String,
        fileURL: URL? = nil,
        data: Data? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.fileExtension = fileExtension
        self.mimeType = mimeType
        self.fileURL = fileURL
        self.data = data
    }
}

// MARK: - File Type Categories

/// Categories of supported file types
public enum FileCategory: String, CaseIterable, Sendable {
    case code
    case config
    case document
    case data
    case script
    case other

    /// File extensions for each category
    public var extensions: [String] {
        switch self {
        case .code:
            return ["swift", "py", "js", "ts", "rs", "go", "java", "kt", "c", "cpp", "h", "hpp", "cs", "rb", "php", "scala", "lua", "r", "m", "mm"]
        case .config:
            return ["json", "yaml", "yml", "toml", "xml", "env", "ini", "conf", "config", "plist"]
        case .document:
            return ["md", "txt", "rst", "adoc", "org", "tex", "pdf", "doc", "docx"]
        case .data:
            return ["csv", "sql", "tsv", "parquet", "avro", "proto"]
        case .script:
            return ["sh", "bash", "zsh", "ps1", "psm1", "bat", "cmd", "fish"]
        case .other:
            return []
        }
    }

    /// Detect category from file extension
    public static func detect(from ext: String) -> FileCategory {
        let lowercased = ext.lowercased()
        for category in FileCategory.allCases where category != .other {
            if category.extensions.contains(lowercased) {
                return category
            }
        }
        return .other
    }
}

// MARK: - File Icon Helper

/// Helper for file icons and colors
public enum FileIconHelper: Sendable {
    public static func icon(for ext: String) -> String {
        let lowercased = ext.lowercased()

        switch lowercased {
        // Languages
        case "swift":
            return "swift"
        case "py":
            return "chevron.left.forwardslash.chevron.right"
        case "js":
            return "curlybraces"
        case "ts":
            return "curlybraces"
        case "rs":
            return "gearshape"
        case "go":
            return "chevron.left.forwardslash.chevron.right"
        case "java":
            return "cup.and.saucer"
        case "kt", "kts":
            return "chevron.left.forwardslash.chevron.right"
        case "c", "cpp", "h", "hpp":
            return "chevron.left.forwardslash.chevron.right"
        case "cs":
            return "chevron.left.forwardslash.chevron.right"
        case "rb":
            return "diamond"
        case "php":
            return "chevron.left.forwardslash.chevron.right"

        // Config
        case "json":
            return "curlybraces"
        case "yaml", "yml":
            return "doc.text"
        case "toml":
            return "doc.text"
        case "xml":
            return "chevron.left.forwardslash.chevron.right"
        case "env":
            return "lock"
        case "plist":
            return "gearshape"

        // Documents
        case "md", "markdown":
            return "doc.text"
        case "txt":
            return "doc"
        case "pdf":
            return "doc.richtext"
        case "rst":
            return "doc.text"

        // Data
        case "csv":
            return "tablecells"
        case "sql":
            return "cylinder"
        case "tsv":
            return "tablecells"

        // Scripts
        case "sh", "bash", "zsh":
            return "terminal"
        case "ps1", "psm1":
            return "terminal"
        case "fish":
            return "terminal"

        // Other
        default:
            return "doc"
        }
    }

    public static func color(for ext: String) -> Color {
        let lowercased = ext.lowercased()

        switch lowercased {
        case "swift":
            return .orange
        case "py":
            return .blue
        case "js":
            return .yellow
        case "ts":
            return .blue
        case "rs":
            return .orange
        case "go":
            return .cyan
        case "java":
            return .red
        case "kt", "kts":
            return .purple
        case "c":
            return .blue
        case "cpp", "hpp":
            return .blue
        case "cs":
            return .purple
        case "rb":
            return .red
        case "php":
            return .indigo
        case "json":
            return .yellow
        case "yaml", "yml":
            return .red
        case "toml":
            return .gray
        case "xml":
            return .orange
        case "md", "markdown":
            return .blue
        case "sql":
            return .blue
        case "csv":
            return .green
        case "sh", "bash", "zsh":
            return .green
        default:
            return .gray
        }
    }
}

// MARK: - File Validator

/// Validates files before upload
public struct FileValidator: Sendable {

    public static let shared = FileValidator()

    /// Maximum single file size (5 MB)
    public static let maxFileSize: Int64 = 5 * 1024 * 1024

    /// Maximum total file size (20 MB)
    public static let maxTotalSize: Int64 = 20 * 1024 * 1024

    /// Maximum number of files
    public static let maxFiles = 10

    /// Supported extensions
    public static let supportedExtensions = FileCategory.allCases.flatMap { $0.extensions }

    public init() {}

    /// Validation result
    public enum ValidationResult {
        case valid
        case unsupportedType(String)
        case fileSizeTooLarge(maxSize: Int64)
        case fileNotAllowed
    }

    /// Validate a file
    public func validate(fileURL: URL) async -> ValidationResult {
        let ext = fileURL.pathExtension.lowercased()

        // Check if extension is supported
        guard Self.supportedExtensions.contains(ext) else {
            return .unsupportedType("Unsupported file type: .\(ext)")
        }

        // Check file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64, fileSize > Self.maxFileSize {
                return .fileSizeTooLarge(maxSize: Self.maxFileSize)
            }
        } catch {
            return .fileNotAllowed
        }

        return .valid
    }
}

// MARK: - File Uploader

/// Handles file upload operations
@MainActor
@Observable
public final class FileUploader {

    // MARK: - Singleton

    public static let shared = FileUploader()

    // MARK: - Properties

    public var attachments: [FileAttachment] = []
    public var isUploading: Bool = false
    public var uploadProgress: Double = 0.0
    public var errorMessage: String?

    // MARK: - Computed Properties

    public var totalSize: Int64 {
        attachments.reduce(0) { $0 + $1.fileSize }
    }

    public var canAddMore: Bool {
        attachments.count < FileValidator.maxFiles &&
        totalSize < FileValidator.maxTotalSize
    }

    public var remainingCapacity: Int64 {
        max(0, FileValidator.maxTotalSize - totalSize)
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Add file from URL
    public func addFile(from url: URL) async -> Bool {
        guard canAddMore else {
            errorMessage = "Maximum files or total size limit reached"
            return false
        }

        // Validate
        let validation = await FileValidator.shared.validate(fileURL: url)
        switch validation {
        case .valid:
            break
        case .unsupportedType(let message):
            errorMessage = message
            return false
        case .fileSizeTooLarge(let maxSize):
            errorMessage = "File too large. Maximum size: \(ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file))"
            return false
        case .fileNotAllowed:
            errorMessage = "File not accessible"
            return false
        }

        // Load file info
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let fileSize = attributes[.size] as? Int64 else {
                errorMessage = "Failed to read file"
                return false
            }

            // Check remaining capacity
            if fileSize > remainingCapacity {
                errorMessage = "Not enough capacity. Remaining: \(ByteCountFormatter.string(fromByteCount: remainingCapacity, countStyle: .file))"
                return false
            }

            // Optionally load file data for smaller files
            var data: Data?
            if fileSize < 1024 * 1024 { // Load data for files < 1MB
                data = try Data(contentsOf: url)
            }

            let attachment = FileAttachment(
                fileName: url.lastPathComponent,
                fileSize: fileSize,
                fileExtension: url.pathExtension,
                mimeType: mimeType(for: url.pathExtension),
                fileURL: url,
                data: data
            )

            attachments.append(attachment)
            clearError()
            return true
        } catch {
            errorMessage = "Failed to read file: \(error.localizedDescription)"
            return false
        }
    }

    /// Add multiple files from URLs
    public func addFiles(from urls: [URL]) async -> Int {
        var successCount = 0
        for url in urls {
            if await addFile(from: url) {
                successCount += 1
            }
        }
        return successCount
    }

    /// Remove an attachment
    public func removeAttachment(_ id: UUID) {
        attachments.removeAll { $0.id == id }
    }

    /// Clear all attachments
    public func clearAttachments() {
        attachments.removeAll()
    }

    // MARK: - Private Methods

    private func mimeType(for ext: String) -> String {
        let lowercased = ext.lowercased()

        switch lowercased {
        case "json":
            return "application/json"
        case "yaml", "yml":
            return "application/x-yaml"
        case "xml":
            return "application/xml"
        case "toml":
            return "application/toml"
        case "md", "markdown":
            return "text/markdown"
        case "txt":
            return "text/plain"
        case "csv":
            return "text/csv"
        case "sql":
            return "application/sql"
        case "swift":
            return "text/x-swift"
        case "py":
            return "text/x-python"
        case "js":
            return "text/javascript"
        case "ts":
            return "text/typescript"
        case "html":
            return "text/html"
        case "css":
            return "text/css"
        default:
            return "application/octet-stream"
        }
    }

    private func clearError() {
        errorMessage = nil
    }
}

// MARK: - File Attachment View

/// A view that displays file attachment previews
public struct FileAttachmentView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var uploader: FileUploader

    public init(uploader: FileUploader) {
        self.uploader = uploader
    }

    public var body: some View {
        if !uploader.attachments.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                // Total size indicator
                HStack {
                    Text("\(uploader.attachments.count) file\(uploader.attachments.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                    Spacer()

                    Text(ByteCountFormatter.string(fromByteCount: uploader.totalSize, countStyle: .file))
                        .font(.caption)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }

                // File list
                ForEach(uploader.attachments) { attachment in
                    FileAttachmentItem(
                        attachment: attachment,
                        onRemove: { uploader.removeAttachment(attachment.id) }
                    )
                }
            }
            .padding(Spacing.sm.rawValue)
            .background(Color.bgTertiary(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)
        }
    }
}

// MARK: - File Attachment Item

private struct FileAttachmentItem: View {
    @Environment(\.colorScheme) private var colorScheme

    let attachment: FileAttachment
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            // File icon
            Image(systemName: attachment.icon)
                .font(.title3)
                .foregroundColor(attachment.iconColor)
                .frame(width: 32, height: 32)
                .background(Color.bgSecondary(scheme: colorScheme))
                .cornerRadius(CornerRadius.sm.rawValue)

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.fileName)
                    .font(.callout)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    .lineLimit(1)

                Text(attachment.formattedSize)
                    .font(.caption2)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }

            Spacer()

            // Remove button
            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.xs.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme).opacity(0.5))
        .cornerRadius(CornerRadius.sm.rawValue)
        .onHover { isHovered = $0 }
    }
}
