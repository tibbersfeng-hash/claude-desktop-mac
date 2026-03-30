// DiffView.swift
// Claude Desktop Mac - Diff View
//
// Displays file differences with syntax highlighting

import SwiftUI
import Theme
import Models
import ViewModels

// MARK: - Diff View

public struct DiffView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.reduceMotion) private var reduceMotion

    let fileDiff: FileDiff
    @State private var viewMode: DiffViewMode = .unified

    public init(fileDiff: FileDiff) {
        self.fileDiff = fileDiff
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            DiffHeaderView(
                filePath: fileDiff.filePath,
                additions: fileDiff.additions,
                deletions: fileDiff.deletions,
                viewMode: $viewMode
            )

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Diff content
            ScrollView([.horizontal, .vertical]) {
                if viewMode == .unified {
                    UnifiedDiffView(hunks: fileDiff.hunks)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    SideBySideDiffView(hunks: fileDiff.hunks)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .scrollIndicators(.automatic)

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Actions
            DiffActionsView()
        }
        .background(Color.bgPrimary(scheme: colorScheme))
        .cornerRadius(CornerRadius.lg.rawValue)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("File diff for \(fileDiff.fileName)")
        .accessibilityValue("\(fileDiff.additions) additions, \(fileDiff.deletions) deletions")
    }
}

// MARK: - Diff Header View

struct DiffHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme

    let filePath: String
    let additions: Int
    let deletions: Int
    @Binding var viewMode: DiffViewMode

    var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // File path
            HStack(spacing: Spacing.xs.rawValue) {
                Image(systemName: "doc.text")
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                Text(filePath)
                    .font(.diffHeader)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
            }

            // Stats
            HStack(spacing: Spacing.sm.rawValue) {
                if additions > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("\(additions)")
                    }
                    .foregroundColor(.diffAdditionFg)
                }

                if deletions > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "minus")
                            .font(.system(size: 10))
                        Text("\(deletions)")
                    }
                    .foregroundColor(.diffDeletionFg)
                }
            }
            .font(.captionText)

            Spacer()

            // View mode picker
            Picker("", selection: $viewMode) {
                ForEach(DiffViewMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
    }
}

// MARK: - Unified Diff View

struct UnifiedDiffView: View {
    @Environment(\.colorScheme) private var colorScheme

    let hunks: [DiffHunk]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(hunks.enumerated()), id: \.offset) { hunkIndex, hunk in
                // Hunk header
                if hunkIndex > 0 {
                    Divider()
                        .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))
                        .padding(.vertical, Spacing.xs.rawValue)
                }

                HStack(spacing: Spacing.sm.rawValue) {
                    Text("@@ -\(hunk.oldStart),\(hunk.oldCount) +\(hunk.newStart),\(hunk.newCount) @@")
                        .font(.diffLineNumber)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                        .padding(.horizontal, Spacing.xs.rawValue)
                        .background(Color.fgTertiary(scheme: colorScheme).opacity(0.1))

                    Spacer()
                }
                .padding(.horizontal, Spacing.md.rawValue)
                .padding(.vertical, Spacing.xs.rawValue)

                // Lines
                ForEach(hunk.lines) { line in
                    UnifiedDiffLineView(line: line)
                }
            }
        }
    }
}

// MARK: - Unified Diff Line View

struct UnifiedDiffLineView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    let line: DiffLine

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Line numbers
            HStack(spacing: 0) {
                // Old line number
                Text(line.oldLineNumber.map { String($0) } ?? "")
                    .font(.diffLineNumber)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .frame(width: 40, alignment: .trailing)
                    .accessibilityHidden(true)

                Divider()
                    .frame(width: 1)
                    .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

                // New line number
                Text(line.newLineNumber.map { String($0) } ?? "")
                    .font(.diffLineNumber)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .frame(width: 40, alignment: .trailing)
                    .accessibilityHidden(true)
            }

            // Change indicator
            Text(changeIndicator)
                .font(.diffLineNumber)
                .foregroundColor(changeColor)
                .frame(width: 16, alignment: .center)
                .background(backgroundColor)
                .accessibilityHidden(true)

            // Content
            Text(line.content)
                .font(.diffCode)
                .foregroundColor(foregroundColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, Spacing.md.rawValue)
        }
        .background(backgroundColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(diffLineAccessibilityLabel)
        .accessibilityHint(line.type.accessibilityHint)
    }

    private var changeIndicator: String {
        switch line.type {
        case .addition: return "+"
        case .deletion: return "-"
        case .context: return " "
        }
    }

    private var changeColor: Color {
        switch line.type {
        case .addition: return highContrast ? .diffAdditionFgHighContrast : .diffAdditionFg
        case .deletion: return highContrast ? .diffDeletionFgHighContrast : .diffDeletionFg
        case .context: return Color.fgTertiary(scheme: colorScheme)
        }
    }

    private var foregroundColor: Color {
        switch line.type {
        case .addition: return highContrast ? .diffAdditionFgHighContrast : .diffAdditionFg
        case .deletion: return highContrast ? .diffDeletionFgHighContrast : .diffDeletionFg
        case .context: return Color.fgPrimary(scheme: colorScheme)
        }
    }

    private var backgroundColor: Color {
        switch line.type {
        case .addition: return highContrast ? .diffAdditionBgHighContrast : .diffAdditionBg
        case .deletion: return highContrast ? .diffDeletionBgHighContrast : .diffDeletionBg
        case .context: return Color.clear
        }
    }

    private var diffLineAccessibilityLabel: String {
        let lineDesc = line.type.accessibilityDescription
        let lineNum = line.newLineNumber ?? line.oldLineNumber ?? 0
        return "\(lineDesc) \(lineNum): \(line.content)"
    }
}

// MARK: - Side by Side Diff View

struct SideBySideDiffView: View {
    @Environment(\.colorScheme) private var colorScheme

    let hunks: [DiffHunk]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 1) {
                Text("Original")
                    .font(.captionText)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    .frame(maxWidth: .infinity)

                Text("Modified")
                    .font(.captionText)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, Spacing.md.rawValue)
            .padding(.vertical, Spacing.xs.rawValue)
            .background(Color.bgSecondary(scheme: colorScheme))

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Content
            ForEach(Array(hunks.enumerated()), id: \.offset) { _, hunk in
                ForEach(hunk.lines) { line in
                    SideBySideDiffLineView(line: line)
                }
            }
        }
    }
}

// MARK: - Side by Side Diff Line View

struct SideBySideDiffLineView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    let line: DiffLine

    var body: some View {
        HStack(spacing: 1) {
            // Left side (original)
            HStack(alignment: .top, spacing: 0) {
                Text(line.oldLineNumber.map { String($0) } ?? "")
                    .font(.diffLineNumber)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .frame(width: 40, alignment: .trailing)
                    .accessibilityHidden(true)

                Text(line.type == .deletion ? line.content : "")
                    .font(.diffCode)
                    .foregroundColor(line.type == .deletion ? (highContrast ? .diffDeletionFgHighContrast : .diffDeletionFg) : Color.clear)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, Spacing.sm.rawValue)
            }
            .background(line.type == .deletion ? (highContrast ? Color.diffDeletionBgHighContrast : Color.diffDeletionBg) : Color.clear)

            Divider()
                .frame(width: 1)
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Right side (modified)
            HStack(alignment: .top, spacing: 0) {
                Text(line.newLineNumber.map { String($0) } ?? "")
                    .font(.diffLineNumber)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .frame(width: 40, alignment: .trailing)
                    .accessibilityHidden(true)

                Text(line.type == .addition ? line.content : "")
                    .font(.diffCode)
                    .foregroundColor(line.type == .addition ? (highContrast ? .diffAdditionFgHighContrast : .diffAdditionFg) : Color.clear)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, Spacing.sm.rawValue)
            }
            .background(line.type == .addition ? (highContrast ? Color.diffAdditionBgHighContrast : Color.diffAdditionBg) : Color.clear)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(diffLineAccessibilityLabel)
        .accessibilityHint(line.type.accessibilityHint)
    }

    private var diffLineAccessibilityLabel: String {
        let lineDesc = line.type.accessibilityDescription
        let lineNum = line.newLineNumber ?? line.oldLineNumber ?? 0
        return "\(lineDesc) \(lineNum): \(line.content)"
    }
}

// MARK: - Diff Actions View

struct DiffActionsView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            Button(action: {}) {
                Label("Accept", systemImage: "checkmark")
            }
            .buttonStyle(.primary)
            .accessibilityLabel("Accept changes")
            .accessibilityHint("Double tap to accept this diff")

            Button(action: {}) {
                Label("Reject", systemImage: "xmark")
            }
            .buttonStyle(.secondary)
            .accessibilityLabel("Reject changes")
            .accessibilityHint("Double tap to reject this diff")

            Spacer()

            Button("Accept All") {}
                .buttonStyle(.plain)
                .foregroundColor(Color.accentPrimary)
                .font(.captionText)
                .accessibilityLabel("Accept all changes")
                .accessibilityHint("Double tap to accept all diffs in this file")

            Button("Reject All") {}
                .buttonStyle(.plain)
                .foregroundColor(.accentError)
                .font(.captionText)
                .accessibilityLabel("Reject all changes")
                .accessibilityHint("Double tap to reject all diffs in this file")
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
    }
}

// MARK: - Diff Preview View

public struct DiffPreviewView: View {
    @Environment(\.colorScheme) private var colorScheme

    let fileDiffs: [FileDiff]

    public init(fileDiffs: [FileDiff]) {
        self.fileDiffs = fileDiffs
    }

    public var body: some View {
        VStack(spacing: Spacing.md.rawValue) {
            ForEach(fileDiffs) { fileDiff in
                DisclosureGroup {
                    DiffView(fileDiff: fileDiff)
                        .frame(maxHeight: 400)
                } label: {
                    HStack(spacing: Spacing.sm.rawValue) {
                        Image(systemName: "doc.text")
                            .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                        Text(fileDiff.fileName)
                            .font(.bodyText)
                            .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                        Spacer()

                        HStack(spacing: Spacing.xs.rawValue) {
                            if fileDiff.additions > 0 {
                                Text("+\(fileDiff.additions)")
                                    .foregroundColor(.diffAdditionFg)
                            }

                            if fileDiff.deletions > 0 {
                                Text("-\(fileDiff.deletions)")
                                    .foregroundColor(.diffDeletionFg)
                            }
                        }
                        .font(.captionText)
                    }
                }
            }
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
        .cornerRadius(CornerRadius.lg.rawValue)
    }
}

// MARK: - Preview

struct DiffView_Previews: PreviewProvider {
    static var previews: some View {
        DiffView(fileDiff: .sample)
            .frame(width: 700, height: 500)
            .padding()
            .background(Color.bgPrimaryDark)
    }
}
