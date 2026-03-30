// ClaudeMdEditor.swift
// Claude Desktop Mac - CLAUDE.md Editor
//
// Visual editor for CLAUDE.md project configuration

import SwiftUI
import Combine

// MARK: - CLAUDE.md Template

/// Template for CLAUDE.md files
public enum ClaudeMdTemplate: String, CaseIterable, Identifiable, Sendable {
    case `default` = "Default"
    case swiftIOS = "Swift/iOS"
    case webFrontend = "Web Frontend"
    case python = "Python"
    case rust = "Rust"
    case golang = "Go"
    case custom = "Custom"

    public var id: String { rawValue }

    /// Template description
    public var description: String {
        switch self {
        case .default: return "Basic project template"
        case .swiftIOS: return "Swift/iOS/SwiftUI project"
        case .webFrontend: return "React/Vue/Next.js project"
        case .python: return "Python project"
        case .rust: return "Rust project"
        case .golang: return "Go project"
        case .custom: return "Start from scratch"
        }
    }

    /// Generate template content
    public func template(for projectName: String) -> String {
        switch self {
        case .default:
            return """
            # Project: \(projectName)

            ## Overview
            [Project description]

            ## Tech Stack
            - Language: [Language]
            - Framework: [Framework]

            ## Architecture
            [Architecture description]

            ## Coding Standards
            - [Coding standard 1]
            - [Coding standard 2]

            ## Notes
            [Additional notes]
            """

        case .swiftIOS:
            return """
            # Project: \(projectName)

            ## Overview
            [Project description]

            ## Tech Stack
            - Language: Swift
            - UI Framework: SwiftUI / UIKit
            - Architecture: MVVM / Clean Architecture
            - Minimum iOS Version: 15.0

            ## Coding Standards
            - Use SwiftLint for linting
            - Maximum line length: 120 characters
            - Use meaningful variable names
            - Prefer Swift modern concurrency (async/await)
            - Use SwiftUI previews for rapid development

            ## File Organization
            - Models: /Sources/Models
            - Views: /Sources/Views
            - ViewModels: /Sources/ViewModels
            - Services: /Sources/Services
            - Utilities: /Sources/Utilities

            ## Testing
            - Unit tests: XCTest
            - UI tests: XCUITest
            - Minimum coverage: 80%

            ## Dependencies
            - Managed via Swift Package Manager

            ## Notes
            [Additional notes]
            """

        case .webFrontend:
            return """
            # Project: \(projectName)

            ## Overview
            [Project description]

            ## Tech Stack
            - Language: TypeScript
            - Framework: React / Vue / Next.js
            - Styling: Tailwind CSS
            - State Management: [Zustand/Redux/Jotai]

            ## Coding Standards
            - Use ESLint + Prettier
            - Component naming: PascalCase
            - File naming: kebab-case
            - Use TypeScript strict mode
            - Prefer functional components with hooks

            ## Directory Structure
            - /components - Reusable components
            - /pages - Page components
            - /hooks - Custom hooks
            - /utils - Utility functions
            - /types - TypeScript types
            - /styles - Global styles

            ## Testing
            - Unit tests: Jest + React Testing Library
            - E2E tests: Playwright
            - Minimum coverage: 80%

            ## Notes
            [Additional notes]
            """

        case .python:
            return """
            # Project: \(projectName)

            ## Overview
            [Project description]

            ## Tech Stack
            - Language: Python 3.11+
            - Framework: [FastAPI/Django/Flask]
            - Package Manager: [Poetry/Pipenv/Pip]

            ## Coding Standards
            - Use Black for formatting
            - Use isort for imports
            - Use mypy for type checking
            - Use Ruff for linting
            - Follow PEP 8

            ## Directory Structure
            - /src - Source code
            - /tests - Tests
            - /docs - Documentation

            ## Testing
            - Unit tests: pytest
            - Coverage: pytest-cov
            - Minimum coverage: 80%

            ## Notes
            [Additional notes]
            """

        case .rust:
            return """
            # Project: \(projectName)

            ## Overview
            [Project description]

            ## Tech Stack
            - Language: Rust (latest stable)
            - Async Runtime: [Tokio/async-std]

            ## Coding Standards
            - Use rustfmt for formatting
            - Use clippy for linting
            - Maximum line length: 100 characters
            - Document public APIs with rustdoc

            ## Project Structure
            - /src - Source code
            - /tests - Integration tests
            - /benches - Benchmarks

            ## Testing
            - Unit tests: cargo test
            - Integration tests: cargo test --test '*'
            - Minimum coverage: 80%

            ## Notes
            [Additional notes]
            """

        case .golang:
            return """
            # Project: \(projectName)

            ## Overview
            [Project description]

            ## Tech Stack
            - Language: Go 1.21+
            - HTTP Framework: [Gin/Echo/stdlib]

            ## Coding Standards
            - Use gofmt for formatting
            - Use go vet for static analysis
            - Use golangci-lint for linting
            - Follow Effective Go guidelines

            ## Project Structure
            - /cmd - Main applications
            - /internal - Private code
            - /pkg - Public code
            - /api - API definitions

            ## Testing
            - Unit tests: go test
            - Minimum coverage: 80%

            ## Notes
            [Additional notes]
            """

        case .custom:
            return """
            # Project: \(projectName)

            ## Overview
            [Project description]

            ## Notes
            [Additional notes]
            """
        }
    }
}

// MARK: - CLAUDE.md Editor View

/// A visual editor for CLAUDE.md files
public struct ClaudeMdEditorView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var content: String
    let project: Project
    let onSave: ((String) -> Void)?

    @State private var editMode: EditMode = .edit
    @State private var selectedTemplate: ClaudeMdTemplate?
    @State private var showingTemplatePicker = false
    @State private var hasUnsavedChanges = false
    @State private var showingDiscardAlert = false

    public init(
        content: Binding<String>,
        project: Project,
        onSave: ((String) -> Void)? = nil
    ) {
        self._content = content
        self.project = project
        self.onSave = onSave
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView

            Divider()

            // Editor / Preview
            editorView

            Divider()

            // Status bar
            statusBarView
        }
        .sheet(isPresented: $showingTemplatePicker) {
            TemplatePickerSheet(selectedTemplate: $selectedTemplate)
        }
        .onChange(of: selectedTemplate) { _, newTemplate in
            if let template = newTemplate {
                content = template.template(for: project.name)
                hasUnsavedChanges = true
            }
        }
    }

    // MARK: - Toolbar

    private var toolbarView: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // Mode picker
            Picker("Mode", selection: $editMode) {
                Text("Edit").tag(EditMode.edit)
                Text("Preview").tag(EditMode.preview)
            }
            .pickerStyle(.segmented)
            .frame(width: 150)

            Spacer()

            // Template button
            Button("Templates") {
                showingTemplatePicker = true
            }
            .buttonStyle(.secondary)

            // Reset button
            Button("Reset") {
                showingDiscardAlert = true
            }
            .disabled(!hasUnsavedChanges)

            // Save button
            Button("Save") {
                saveContent()
            }
            .disabled(!hasUnsavedChanges)
            .buttonStyle(.primary)
        }
        .padding()
        .background(Color.bgSecondary(scheme: colorScheme))
    }

    // MARK: - Editor View

    @ViewBuilder
    private var editorView: some View {
        if editMode == .edit {
            TextEditor(text: $content)
                .font(.codeBlock)
                .background(Color.bgPrimary(scheme: colorScheme))
                .onChange(of: content) { _, _ in
                    hasUnsavedChanges = true
                }
        } else {
            ScrollView {
                AdvancedMarkdownView(content: content)
                    .padding()
            }
            .background(Color.bgPrimary(scheme: colorScheme))
        }
    }

    // MARK: - Status Bar

    private var statusBarView: some View {
        HStack {
            if hasUnsavedChanges {
                Image(systemName: "circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption2)
                Text("Unsaved changes")
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption2)
                Text("Saved")
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }

            Spacer()

            Text("\(content.components(separatedBy: "\n").count) lines | \(content.count) characters")
                .font(.caption)
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.xs.rawValue)
        .background(Color.bgTertiary(scheme: colorScheme))
    }

    // MARK: - Private Methods

    private func saveContent() {
        hasUnsavedChanges = false
        onSave?(content)
    }

    private enum EditMode {
        case edit
        case preview
    }
}

// MARK: - Template Picker Sheet

private struct TemplatePickerSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedTemplate: ClaudeMdTemplate?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Choose Template")
                    .font(.headline)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))

            Divider()

            // Templates
            ScrollView {
                VStack(spacing: Spacing.sm.rawValue) {
                    ForEach(ClaudeMdTemplate.allCases) { template in
                        TemplateRow(
                            template: template,
                            isSelected: selectedTemplate == template,
                            colorScheme: colorScheme,
                            onSelect: {
                                selectedTemplate = template
                                dismiss()
                            }
                        )
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.secondary)
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))
        }
        .frame(width: 400, height: 400)
        .background(Color.bgPrimary(scheme: colorScheme))
    }
}

// MARK: - Template Row

private struct TemplateRow: View {
    let template: ClaudeMdTemplate
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.rawValue)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Text(template.description)
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentPrimary)
            }
        }
        .padding()
        .background(isSelected ? Color.accentPrimary.opacity(0.1) : (isHovered ? Color.bgHover(scheme: colorScheme) : Color.bgSecondary(scheme: colorScheme)))
        .cornerRadius(CornerRadius.md.rawValue)
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
    }
}
