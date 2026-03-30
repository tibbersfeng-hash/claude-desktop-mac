// UnixSocketClient.swift
// Claude Desktop Mac - Unix Domain Socket Client
//
// Alternative communication method using Unix Domain Sockets

import Foundation
import Combine

// MARK: - Socket Client Error

/// Errors from Unix socket communication
public enum SocketClientError: Error, Sendable, LocalizedError {
    case connectionFailed(String)
    case notConnected
    case sendFailed(String)
    case receiveFailed(String)
    case timeout
    case invalidPath(String)
    case socketError(String)

    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "Socket connection failed: \(reason)"
        case .notConnected:
            return "Socket is not connected."
        case .sendFailed(let reason):
            return "Failed to send data: \(reason)"
        case .receiveFailed(let reason):
            return "Failed to receive data: \(reason)"
        case .timeout:
            return "Socket operation timed out."
        case .invalidPath(let path):
            return "Invalid socket path: \(path)"
        case .socketError(let reason):
            return "Socket error: \(reason)"
        }
    }
}

// MARK: - Unix Socket Client

/// Client for Unix Domain Socket communication
public final class UnixSocketClient: @unchecked Sendable {

    // MARK: - Properties

    /// Socket path
    public let socketPath: String

    /// Whether the client is connected
    public private(set) var isConnected = false

    /// Socket file descriptor
    private var socketFD: Int32 = -1

    /// Lock for thread safety
    private let lock = NSLock()

    /// Connection subject for Combine
    private let connectionSubject = CurrentValueSubject<Bool, Never>(false)

    /// Data subject for Combine
    private let dataSubject = PassthroughSubject<Data, Never>()

    /// Error subject for Combine
    private let errorSubject = PassthroughSubject<SocketClientError, Never>()

    /// Read task
    private var readTask: Task<Void, Never>?

    // MARK: - Initialization

    public init(socketPath: String) {
        self.socketPath = socketPath
    }

    deinit {
        disconnect()
    }

    // MARK: - Connection Management

    /// Connect to the Unix socket
    public func connect() async throws {
        lock.lock()
        defer { lock.unlock() }

        guard !isConnected else { return }

        // Check if socket file exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: socketPath) else {
            throw SocketClientError.invalidPath(socketPath)
        }

        // Create socket
        socketFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            throw SocketClientError.socketError("Failed to create socket")
        }

        // Configure socket address
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        addr.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)

        // Copy path to sun_path
        let pathData = socketPath.data(using: .utf8)!
        let maxPathLength = MemoryLayout.size(ofValue: addr.sun_path) - 1
        pathData.withUnsafeBytes { ptr in
            if let baseAddr = ptr.baseAddress {
                memcpy(&addr.sun_path, baseAddr, min(pathData.count, maxPathLength))
            }
        }

        // Connect
        let result = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                Darwin.connect(socketFD, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard result == 0 else {
            close(socketFD)
            socketFD = -1
            throw SocketClientError.connectionFailed(String(cString: strerror(errno)))
        }

        isConnected = true
        connectionSubject.send(true)

        // Start reading
        startReading()
    }

    /// Disconnect from the socket
    public func disconnect() {
        lock.lock()
        defer { lock.unlock() }

        guard isConnected else { return }

        readTask?.cancel()
        readTask = nil

        if socketFD >= 0 {
            close(socketFD)
            socketFD = -1
        }

        isConnected = false
        connectionSubject.send(false)
    }

    // MARK: - Data Transfer

    /// Send data through the socket
    public func send(_ data: Data) async throws {
        lock.lock()
        let fd = socketFD
        let connected = isConnected
        lock.unlock()

        guard connected else {
            throw SocketClientError.notConnected
        }

        var remaining = data.count
        var offset = 0

        while remaining > 0 {
            let sent = data.withUnsafeBytes { ptr in
                Darwin.send(fd, ptr.baseAddress! + offset, remaining, 0)
            }

            if sent < 0 {
                throw SocketClientError.sendFailed(String(cString: strerror(errno)))
            }

            remaining -= sent
            offset += sent
        }
    }

    /// Send a string through the socket
    public func send(_ string: String) async throws {
        guard let data = string.data(using: .utf8) else {
            throw SocketClientError.sendFailed("Failed to encode string")
        }
        try await send(data)
    }

    // MARK: - Reading

    private func startReading() {
        readTask = Task { [weak self] in
            guard let self = self else { return }

            let bufferSize = 4096
            var buffer = [UInt8](repeating: 0, count: bufferSize)

            while !Task.isCancelled {
                let bytesRead = recv(self.socketFD, &buffer, bufferSize, 0)

                if bytesRead < 0 {
                    if errno == EAGAIN || errno == EWOULDBLOCK {
                        continue
                    }
                    self.handleError(.receiveFailed(String(cString: strerror(errno))))
                    break
                } else if bytesRead == 0 {
                    // Connection closed
                    self.disconnect()
                    break
                } else {
                    let data = Data(bytes: buffer, count: bytesRead)
                    self.dataSubject.send(data)
                }
            }
        }
    }

    private func handleError(_ error: SocketClientError) {
        errorSubject.send(error)
    }
}

// MARK: - Combine Publishers

extension UnixSocketClient {

    /// Publisher for connection state
    public var connectionPublisher: AnyPublisher<Bool, Never> {
        connectionSubject.eraseToAnyPublisher()
    }

    /// Publisher for received data
    public var dataPublisher: AnyPublisher<Data, Never> {
        dataSubject.eraseToAnyPublisher()
    }

    /// Publisher for errors
    public var errorPublisher: AnyPublisher<SocketClientError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
}
