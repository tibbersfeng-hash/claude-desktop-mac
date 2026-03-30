// CommunicationPipeline.swift
// Claude Desktop Mac - Communication Pipeline Module
//
// Provides stdio-based communication with Claude Code CLI

import Foundation
import Combine

// MARK: - Pipeline State

/// State of the communication pipeline
public enum PipelineState: String, Sendable, Codable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error
}

// MARK: - Pipeline Error

/// Errors from the communication pipeline
public enum PipelineError: Error, Sendable, LocalizedError {
    case notConnected
    case writeFailed(String)
    case readFailed(String)
    case connectionTimeout
    case invalidData(String)
    case pipelineClosed

    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Communication pipeline is not connected."
        case .writeFailed(let reason):
            return "Failed to write to pipeline: \(reason)"
        case .readFailed(let reason):
            return "Failed to read from pipeline: \(reason)"
        case .connectionTimeout:
            return "Connection timed out."
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        case .pipelineClosed:
            return "Communication pipeline is closed."
        }
    }
}

// MARK: - Communication Pipeline Delegate

/// Delegate for communication pipeline events
public protocol CommunicationPipelineDelegate: AnyObject, Sendable {
    func pipeline(_ pipeline: CommunicationPipeline, didChangeState state: PipelineState)
    func pipeline(_ pipeline: CommunicationPipeline, didReceiveData data: Data)
    func pipeline(_ pipeline: CommunicationPipeline, didEncounterError error: PipelineError)
}

// MARK: - Communication Pipeline

/// Handles bidirectional communication with CLI via stdio
public final class CommunicationPipeline: @unchecked Sendable {

    // MARK: - Properties

    /// Current pipeline state
    public private(set) var state: PipelineState = .disconnected {
        didSet {
            stateSubject.send(state)
            notifyStateChange(state)
        }
    }

    /// Input file handle (for writing to CLI)
    private var inputFileHandle: FileHandle?

    /// Output file handle (for reading from CLI)
    private var outputFileHandle: FileHandle?

    /// Delegate for events
    public weak var delegate: CommunicationPipelineDelegate?

    /// Lock for thread safety
    private let lock = NSLock()

    /// State subject for Combine
    private let stateSubject = CurrentValueSubject<PipelineState, Never>(.disconnected)

    /// Data subject for Combine
    private let dataSubject = PassthroughSubject<Data, Never>()

    /// Error subject for Combine
    private let errorSubject = PassthroughSubject<PipelineError, Never>()

    /// Write queue for serializing writes
    private let writeQueue = DispatchQueue(label: "com.claude.desktop.pipeline.write", qos: .userInitiated)

    // MARK: - Initialization

    public init() {}

    deinit {
        disconnect()
    }

    // MARK: - Connection Management

    /// Connect to the CLI using file handles
    /// - Parameters:
    ///   - inputHandle: File handle for writing (stdin)
    ///   - outputHandle: File handle for reading (stdout)
    public func connect(input: FileHandle, output: FileHandle) async throws {
        lock.lock()
        defer { lock.unlock() }

        guard state == .disconnected else {
            throw PipelineError.notConnected
        }

        state = .connecting

        inputFileHandle = input
        outputFileHandle = output

        // Start reading
        startReading()

        state = .connected
    }

    /// Disconnect the pipeline
    public func disconnect() {
        lock.lock()
        defer { lock.unlock() }

        guard state == .connected || state == .connecting else { return }

        state = .disconnecting

        stopReading()

        // Close handles (but don't close them if they're managed externally)
        // The process manager owns these handles
        inputFileHandle = nil
        outputFileHandle = nil

        state = .disconnected
    }

    // MARK: - Data Transfer

    /// Write data to the pipeline
    /// - Parameter data: Data to write
    public func write(_ data: Data) async throws {
        lock.lock()
        let handle = inputFileHandle
        let currentState = state
        lock.unlock()

        guard currentState == .connected else {
            throw PipelineError.notConnected
        }

        guard let fileHandle = handle else {
            throw PipelineError.pipelineClosed
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            writeQueue.async { [weak self] in
                do {
                    fileHandle.write(data)
                    continuation.resume()
                } catch {
                    self?.handleWriteError(error)
                    continuation.resume(throwing: PipelineError.writeFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Write a string to the pipeline
    /// - Parameters:
    ///   - string: String to write
    ///   - encoding: String encoding (default UTF-8)
    public func write(_ string: String, encoding: String.Encoding = .utf8) async throws {
        guard let data = string.data(using: encoding) else {
            throw PipelineError.invalidData("Failed to encode string")
        }
        try await write(data)
    }

    /// Write data with newline terminator
    public func writeLine(_ data: Data) async throws {
        var lineData = data
        lineData.append(contentsOf: [0x0A]) // newline
        try await write(lineData)
    }

    /// Write string with newline terminator
    public func writeLine(_ string: String, encoding: String.Encoding = .utf8) async throws {
        guard let data = (string + "\n").data(using: encoding) else {
            throw PipelineError.invalidData("Failed to encode string")
        }
        try await write(data)
    }

    // MARK: - Reading

    private var readTask: Task<Void, Never>?

    private func startReading() {
        guard let outputHandle = outputFileHandle else { return }

        readTask = Task { [weak self] in
            outputHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    self?.handleReceivedData(data)
                }
            }
        }
    }

    private func stopReading() {
        readTask?.cancel()
        readTask = nil
        outputFileHandle?.readabilityHandler = nil
    }

    // MARK: - Event Handling

    private func handleReceivedData(_ data: Data) {
        dataSubject.send(data)

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.delegate?.pipeline(self, didReceiveData: data)
        }
    }

    private func handleWriteError(_ error: Error) {
        let pipelineError = PipelineError.writeFailed(error.localizedDescription)
        errorSubject.send(pipelineError)

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.delegate?.pipeline(self, didEncounterError: pipelineError)
        }
    }

    private func notifyStateChange(_ newState: PipelineState) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.delegate?.pipeline(self, didChangeState: newState)
        }
    }
}

// MARK: - Combine Publishers

extension CommunicationPipeline {

    /// Publisher for state changes
    public var statePublisher: AnyPublisher<PipelineState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    /// Publisher for received data
    public var dataPublisher: AnyPublisher<Data, Never> {
        dataSubject.eraseToAnyPublisher()
    }

    /// Publisher for errors
    public var errorPublisher: AnyPublisher<PipelineError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
}

// MARK: - Async Sequence Support

extension CommunicationPipeline {

    /// Async sequence of received data
    public var receivedData: AsyncStream<Data> {
        AsyncStream { continuation in
            let cancellable = dataSubject.sink { data in
                continuation.yield(data)
            }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
