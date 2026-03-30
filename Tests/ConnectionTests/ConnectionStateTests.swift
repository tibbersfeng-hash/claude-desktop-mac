import XCTest
@testable import State

final class ConnectionStateTests: XCTestCase {

    func testConnectionStateIsActive() {
        XCTAssertTrue(ConnectionState.connected.isActive)
        XCTAssertTrue(ConnectionState.connecting.isActive)
        XCTAssertTrue(ConnectionState.reconnecting.isActive)

        XCTAssertFalse(ConnectionState.idle.isActive)
        XCTAssertFalse(ConnectionState.disconnected.isActive)
        XCTAssertFalse(ConnectionState.error.isActive)
    }

    func testConnectionStateCanStartAction() {
        XCTAssertTrue(ConnectionState.idle.canStartAction)
        XCTAssertTrue(ConnectionState.disconnected.canStartAction)
        XCTAssertTrue(ConnectionState.error.canStartAction)

        XCTAssertFalse(ConnectionState.connected.canStartAction)
        XCTAssertFalse(ConnectionState.connecting.canStartAction)
        XCTAssertFalse(ConnectionState.reconnecting.canStartAction)
    }

    func testConnectionStateDescription() {
        XCTAssertEqual(ConnectionState.connected.description, "Connected")
        XCTAssertEqual(ConnectionState.connecting.description, "Connecting...")
        XCTAssertEqual(ConnectionState.idle.description, "Not Connected")
        XCTAssertEqual(ConnectionState.error.description, "Connection Error")
    }
}
