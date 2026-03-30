// ImageUploader.swift
// Claude Desktop Mac - Image Upload Handling
//
// Handles image upload, validation, and preview

import SwiftUI
import Combine
import Theme

// MARK: - Image Attachment

/// Represents an image attachment for messages
public struct ImageAttachment: Identifiable, Codable, Sendable {
    public let id: UUID
    public let fileName: String
    public let fileSize: Int64
    public let mimeType: String
    public let width: Int
    public let height: Int
    public let data: Data?
    public let fileURL: URL?

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    public var thumbnail: NSImage? {
        guard let data = data else { return nil }
        return NSImage(data: data)
    }

    public init(
        id: UUID = UUID(),
        fileName: String,
        fileSize: Int64,
        mimeType: String,
        width: Int,
        height: Int,
        data: Data? = nil,
        fileURL: URL? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.width = width
        self.height = height
        self.data = data
        self.fileURL = fileURL
    }
}

// MARK: - Supported Image Formats

/// Supported image formats for upload
public enum ImageFormat: String, CaseIterable, Sendable {
    case jpeg = "public.jpeg"
    case png = "public.png"
    case gif = "public.gif"
    case webp = "public.webp"
    case bmp = "public.bmp"
    case tiff = "public.tiff"

    public var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .gif: return "gif"
        case .webp: return "webp"
        case .bmp: return "bmp"
        case .tiff: return "tiff"
        }
    }

    public var mimeType: String {
        switch self {
        case .jpeg: return "image/jpeg"
        case .png: return "image/png"
        case .gif: return "image/gif"
        case .webp: return "image/webp"
        case .bmp: return "image/bmp"
        case .tiff: return "image/tiff"
        }
    }

    public var maxFileSize: Int64 {
        switch self {
        case .gif: return 5 * 1024 * 1024  // 5 MB for GIFs
        default: return 10 * 1024 * 1024   // 10 MB for others
        }
    }

    public static func from(mimeType: String) -> ImageFormat? {
        switch mimeType.lowercased() {
        case "image/jpeg", "image/jpg": return .jpeg
        case "image/png": return .png
        case "image/gif": return .gif
        case "image/webp": return .webp
        case "image/bmp": return .bmp
        case "image/tiff": return .tiff
        default: return nil
        }
    }

    public static func from(extension ext: String) -> ImageFormat? {
        switch ext.lowercased() {
        case "jpg", "jpeg": return .jpeg
        case "png": return .png
        case "gif": return .gif
        case "webp": return .webp
        case "bmp": return .bmp
        case "tiff", "tif": return .tiff
        default: return nil
        }
    }
}

// MARK: - Image Validator

/// Validates images before upload
public struct ImageValidator: Sendable {

    public static let shared = ImageValidator()

    public init() {}

    /// Validation result
    public enum ValidationResult {
        case valid
        case invalidFormat(String)
        case fileSizeTooLarge(maxSize: Int64)
        case dimensionsTooLarge(maxWidth: Int, maxHeight: Int)
        case corruptedFile
    }

    /// Maximum dimensions for uploaded images
    public static let maxDimensions = CGSize(width: 4096, height: 4096)

    /// Validate an image file
    public func validate(fileURL: URL) async -> ValidationResult {
        // Check file extension
        let ext = fileURL.pathExtension
        guard let format = ImageFormat.from(extension: ext) else {
            return .invalidFormat("Unsupported image format: .\(ext)")
        }

        // Check file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            guard let fileSize = attributes[.size] as? Int64 else {
                return .corruptedFile
            }

            if fileSize > format.maxFileSize {
                return .fileSizeTooLarge(maxSize: format.maxFileSize)
            }
        } catch {
            return .corruptedFile
        }

        // Check image dimensions
        guard let image = NSImage(contentsOf: fileURL),
              let representation = image.representations.first else {
            return .corruptedFile
        }

        let width = representation.pixelsWide
        let height = representation.pixelsHigh

        if width > Int(Self.maxDimensions.width) || height > Int(Self.maxDimensions.height) {
            return .dimensionsTooLarge(
                maxWidth: Int(Self.maxDimensions.width),
                maxHeight: Int(Self.maxDimensions.height)
            )
        }

        return .valid
    }

    /// Validate image data
    public func validate(data: Data, fileName: String) async -> ValidationResult {
        // Determine format from data
        guard let image = NSImage(data: data),
              let representation = image.representations.first else {
            return .corruptedFile
        }

        // Check file size
        let fileSize = Int64(data.count)
        let ext = (fileName as NSString).pathExtension
        let format = ImageFormat.from(extension: ext)

        if let format = format, fileSize > format.maxFileSize {
            return .fileSizeTooLarge(maxSize: format.maxFileSize)
        }

        // Check dimensions
        let width = representation.pixelsWide
        let height = representation.pixelsHigh

        if width > Int(Self.maxDimensions.width) || height > Int(Self.maxDimensions.height) {
            return .dimensionsTooLarge(
                maxWidth: Int(Self.maxDimensions.width),
                maxHeight: Int(Self.maxDimensions.height)
            )
        }

        return .valid
    }
}

// MARK: - Image Uploader

/// Handles image upload operations
@MainActor
@Observable
public final class ImageUploader {

    // MARK: - Singleton

    public static let shared = ImageUploader()

    // MARK: - Properties

    public var attachments: [ImageAttachment] = []
    public var isUploading: Bool = false
    public var uploadProgress: Double = 0.0
    public var errorMessage: String?

    // MARK: - Constants

    public static let maxAttachments = 5

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Add image from file URL
    public func addImage(from url: URL) async -> Bool {
        guard attachments.count < Self.maxAttachments else {
            errorMessage = "Maximum \(Self.maxAttachments) images allowed"
            return false
        }

        // Validate
        let validation = await ImageValidator.shared.validate(fileURL: url)
        switch validation {
        case .valid:
            break
        case .invalidFormat(let message):
            errorMessage = message
            return false
        case .fileSizeTooLarge(let maxSize):
            errorMessage = "File too large. Maximum size: \(ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file))"
            return false
        case .dimensionsTooLarge(let maxWidth, let maxHeight):
            errorMessage = "Image dimensions too large. Maximum: \(maxWidth)x\(maxHeight)"
            return false
        case .corruptedFile:
            errorMessage = "Corrupted or invalid image file"
            return false
        }

        // Load image data
        do {
            let data = try Data(contentsOf: url)
            guard let image = NSImage(data: data),
                  let representation = image.representations.first else {
                errorMessage = "Failed to load image"
                return false
            }

            let attachment = ImageAttachment(
                fileName: url.lastPathComponent,
                fileSize: Int64(data.count),
                mimeType: ImageFormat.from(extension: url.pathExtension)?.mimeType ?? "image/jpeg",
                width: representation.pixelsWide,
                height: representation.pixelsHigh,
                data: data,
                fileURL: url
            )

            attachments.append(attachment)
            clearError()
            return true
        } catch {
            errorMessage = "Failed to read file: \(error.localizedDescription)"
            return false
        }
    }

    /// Add image from pasteboard (clipboard)
    public func addImageFromPasteboard() async -> Bool {
        let pasteboard = NSPasteboard.general

        // Check for image data
        if let data = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png),
           let image = NSImage(data: data),
           let representation = image.representations.first {

            guard attachments.count < Self.maxAttachments else {
                errorMessage = "Maximum \(Self.maxAttachments) images allowed"
                return false
            }

            let attachment = ImageAttachment(
                fileName: "pasted-image.png",
                fileSize: Int64(data.count),
                mimeType: "image/png",
                width: representation.pixelsWide,
                height: representation.pixelsHigh,
                data: data
            )

            attachments.append(attachment)
            clearError()
            return true
        }

        // Check for file URL
        if let urlString = pasteboard.string(forType: .fileURL),
           let url = URL(string: urlString) {
            return await addImage(from: url)
        }

        errorMessage = "No image found in clipboard"
        return false
    }

    /// Add image from data (drag and drop)
    public func addImage(from data: Data, fileName: String) async -> Bool {
        guard attachments.count < Self.maxAttachments else {
            errorMessage = "Maximum \(Self.maxAttachments) images allowed"
            return false
        }

        // Validate
        let validation = await ImageValidator.shared.validate(data: data, fileName: fileName)
        switch validation {
        case .valid:
            break
        case .invalidFormat(let message):
            errorMessage = message
            return false
        case .fileSizeTooLarge(let maxSize):
            errorMessage = "File too large. Maximum size: \(ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file))"
            return false
        case .dimensionsTooLarge(let maxWidth, let maxHeight):
            errorMessage = "Image dimensions too large. Maximum: \(maxWidth)x\(maxHeight)"
            return false
        case .corruptedFile:
            errorMessage = "Corrupted or invalid image data"
            return false
        }

        guard let image = NSImage(data: data),
              let representation = image.representations.first else {
            errorMessage = "Failed to load image"
            return false
        }

        let attachment = ImageAttachment(
            fileName: fileName,
            fileSize: Int64(data.count),
            mimeType: ImageFormat.from(extension: (fileName as NSString).pathExtension)?.mimeType ?? "image/jpeg",
            width: representation.pixelsWide,
            height: representation.pixelsHigh,
            data: data
        )

        attachments.append(attachment)
        clearError()
        return true
    }

    /// Remove an attachment
    public func removeAttachment(_ id: UUID) {
        attachments.removeAll { $0.id == id }
    }

    /// Clear all attachments
    public func clearAttachments() {
        attachments.removeAll()
    }

    /// Check if can add more attachments
    public var canAddMore: Bool {
        attachments.count < Self.maxAttachments
    }

    // MARK: - Private Methods

    private func clearError() {
        errorMessage = nil
    }
}

// MARK: - Image Preview View

/// A view that displays image attachment previews
public struct ImagePreviewView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var uploader: ImageUploader

    public init(uploader: ImageUploader) {
        self.uploader = uploader
    }

    public var body: some View {
        if !uploader.attachments.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm.rawValue) {
                    ForEach(uploader.attachments) { attachment in
                        ImagePreviewItem(
                            attachment: attachment,
                            onRemove: { uploader.removeAttachment(attachment.id) }
                        )
                    }
                }
                .padding(Spacing.sm.rawValue)
            }
            .frame(height: 120)
            .background(Color.bgTertiary(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)
        }
    }
}

// MARK: - Image Preview Item

private struct ImagePreviewItem: View {
    @Environment(\.colorScheme) private var colorScheme

    let attachment: ImageAttachment
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Image thumbnail
            if let image = attachment.thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .cornerRadius(CornerRadius.sm.rawValue)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.bgSecondary(scheme: colorScheme))
                    .frame(width: 100, height: 100)
                    .cornerRadius(CornerRadius.sm.rawValue)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    )
            }

            // Remove button
            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }

            // File info overlay
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(attachment.fileName)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text("\(attachment.width)x\(attachment.height) | \(attachment.formattedSize)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(4)
                .background(Color.black.opacity(0.6))
            }
            .cornerRadius(CornerRadius.sm.rawValue, corners: [.bottomLeft, .bottomRight])
        }
        .onHover { isHovered = $0 }
    }
}

// MARK: - View Extension for Corner Radius

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tl = corners.contains(.topLeft) ? CGPoint(x: rect.minX, y: rect.minY + radius) : rect.origin
        let tr = corners.contains(.topRight) ? CGPoint(x: rect.maxX - radius, y: rect.minY) : CGPoint(x: rect.maxX, y: rect.minY)
        let bl = corners.contains(.bottomLeft) ? CGPoint(x: rect.minX, y: rect.maxY - radius) : CGPoint(x: rect.minX, y: rect.maxY)
        let br = corners.contains(.bottomRight) ? CGPoint(x: rect.maxX - radius, y: rect.maxY - radius) : CGPoint(x: rect.maxX, y: rect.maxY)

        path.move(to: tl)
        if corners.contains(.topLeft) {
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            path.addLine(to: tr)
        }

        if corners.contains(.topRight) {
            path.addLine(to: tr)
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius), radius: radius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }

        if corners.contains(.bottomRight) {
            path.addLine(to: br)
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius), radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        } else {
            path.addLine(to: bl)
        }

        if corners.contains(.bottomLeft) {
            path.addLine(to: bl)
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius), radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - UIRectCorner for macOS

public struct UIRectCorner: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let topLeft = UIRectCorner(rawValue: 1 << 0)
    public static let topRight = UIRectCorner(rawValue: 1 << 1)
    public static let bottomLeft = UIRectCorner(rawValue: 1 << 2)
    public static let bottomRight = UIRectCorner(rawValue: 1 << 3)
    public static let allCorners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}
