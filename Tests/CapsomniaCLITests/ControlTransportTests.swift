import Foundation
import XCTest
@testable import CapsomniaControl
@testable import CapsomniaCLI

final class ControlTransportTests: XCTestCase {
    func testRequestRoundTripThroughTemporarySocket() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cpsm-\(getpid())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        _ = chmod(directory.path, mode_t(S_IRUSR | S_IWUSR | S_IXUSR))
        let path = directory.appendingPathComponent("endpoint").path
        defer { try? FileManager.default.removeItem(at: directory) }
        let server = try ControlServer(endpointPath: path) { request, reply in
            XCTAssertEqual(request, ControlRequest(arguments: ["status"]))
            reply(.success(.object(["state": .string("on")])))
        }
        try server.start()
        defer { server.stop() }

        let client = try ControlClient(endpointPath: path, connectTimeout: 1, responseTimeout: 2)
        let expectation = expectation(description: "response")
        var response: ControlResponse?
        DispatchQueue.global().async {
            response = try? client.send(ControlRequest(arguments: ["status"]))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
        XCTAssertEqual(response, .success(.object(["state": .string("on")])))
    }

    func testLegacyUpdaterCacheIsMigratedAndStillAcceptsRequests() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cpsm-old-\(getpid())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        XCTAssertEqual(chmod(directory.path, 0o755), 0)
        let cachedInstaller = directory.appendingPathComponent("Capsomnia-4.0.0.pkg")
        let cachedData = Data("existing update download".utf8)
        try cachedData.write(to: cachedInstaller)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("endpoint").path
        let server = try ControlServer(endpointPath: path) { _, reply in
            reply(.success(.string("ready")))
        }
        try server.start()
        defer { server.stop() }
        var info = stat()
        XCTAssertEqual(lstat(directory.path, &info), 0)
        XCTAssertEqual(info.st_mode & 0o777, 0o700)
        XCTAssertEqual(try Data(contentsOf: cachedInstaller), cachedData)

        let client = try ControlClient(endpointPath: path)
        let completed = expectation(description: "legacy cache request")
        var response: ControlResponse?
        DispatchQueue.global().async {
            response = try? client.send(ControlRequest(arguments: ["status"]))
            completed.fulfill()
        }
        wait(for: [completed], timeout: 3)
        XCTAssertEqual(response, .success(.string("ready")))
    }

    func testSymlinkedCacheIsRejectedWithoutChangingItsTarget() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cpsm-link-\(getpid())")
        let target = directory.appendingPathComponent("target")
        let link = directory.appendingPathComponent("link")
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        XCTAssertEqual(chmod(target.path, 0o755), 0)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        defer { try? FileManager.default.removeItem(at: directory) }

        let server = try ControlServer(endpointPath: link.appendingPathComponent("endpoint").path) { _, _ in }
        XCTAssertThrowsError(try server.start()) { error in
            XCTAssertEqual(error as? ControlTransportError, .unsafeEndpoint)
        }
        var info = stat()
        XCTAssertEqual(lstat(target.path, &info), 0)
        XCTAssertEqual(info.st_mode & 0o777, 0o755)
        XCTAssertFalse(FileManager.default.fileExists(atPath: target.appendingPathComponent("endpoint").path))
    }

    func testForeignOwnedCacheIsRejectedWithoutChangingPermissions() throws {
        // /private/tmp is a system-owned directory, unlike our temporary fixtures.
        let directory = "/private/tmp"
        var before = stat()
        XCTAssertEqual(lstat(directory, &before), 0)
        try XCTSkipIf(before.st_uid == getuid(), "Requires an unprivileged test user")
        let path = "\(directory)/cpsm-foreign-\(getpid()).sock"
        let server = try ControlServer(endpointPath: path) { _, _ in }
        XCTAssertThrowsError(try server.start()) { error in
            XCTAssertEqual(error as? ControlTransportError, .unsafeEndpoint)
        }
        var after = stat()
        XCTAssertEqual(lstat(directory, &after), 0)
        XCTAssertEqual(after.st_mode, before.st_mode)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    func testForeignEndpointIsNotRemoved() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("capsomnia-control-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("endpoint").path
        try Data("keep".utf8).write(to: URL(fileURLWithPath: path))
        defer { try? FileManager.default.removeItem(at: directory) }

        XCTAssertThrowsError(try ControlServer(endpointPath: path, handler: { _, _ in }).start())
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func testDuplicateServerIsRefused() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cpsm-dup-\(getpid())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        _ = chmod(directory.path, mode_t(S_IRUSR | S_IWUSR | S_IXUSR))
        let path = directory.appendingPathComponent("endpoint").path
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = try ControlServer(endpointPath: path) { _, reply in reply(.success()) }
        try first.start()
        defer { first.stop() }
        XCTAssertThrowsError(try ControlServer(endpointPath: path) { _, _ in }.start()) { error in
            XCTAssertEqual(error as? ControlTransportError, .endpointAlreadyRunning)
        }
    }

    func testClientResponseTimeoutDoesNotRetry() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cpsm-time-\(getpid())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        _ = chmod(directory.path, mode_t(S_IRUSR | S_IWUSR | S_IXUSR))
        let path = directory.appendingPathComponent("endpoint").path
        defer { try? FileManager.default.removeItem(at: directory) }
        let server = try ControlServer(endpointPath: path) { _, _ in }
        try server.start()
        defer { server.stop() }
        let client = try ControlClient(endpointPath: path, connectTimeout: 1, responseTimeout: 0.05)
        XCTAssertThrowsError(try client.send(ControlRequest(arguments: ["on"]))) { error in
            XCTAssertEqual(error as? ControlTransportError, .timedOut)
        }
    }

    func testServerSurvivesReplyToDisconnectedClient() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cpsm-disc-\(getpid())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        _ = chmod(directory.path, mode_t(S_IRUSR | S_IWUSR | S_IXUSR))
        let path = directory.appendingPathComponent("endpoint").path
        defer { try? FileManager.default.removeItem(at: directory) }
        let lock = NSLock()
        var count = 0
        let server = try ControlServer(endpointPath: path) { _, reply in
            lock.lock(); count += 1; let current = count; lock.unlock()
            if current == 1 {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { reply(.success()) }
            } else {
                reply(.success(.string("alive")))
            }
        }
        try server.start()
        defer { server.stop() }
        let impatient = try ControlClient(endpointPath: path, connectTimeout: 1, responseTimeout: 0.02)
        let first = expectation(description: "first request timeout")
        DispatchQueue.global().async {
            do {
                _ = try impatient.send(ControlRequest(arguments: ["status"]))
                XCTFail("Expected response timeout")
            } catch {
                XCTAssertEqual(error as? ControlTransportError, .timedOut)
            }
            first.fulfill()
        }
        wait(for: [first], timeout: 1)
        Thread.sleep(forTimeInterval: 0.2)
        let patient = try ControlClient(endpointPath: path, connectTimeout: 1, responseTimeout: 1)
        let second = expectation(description: "second request")
        var response: ControlResponse?
        DispatchQueue.global().async {
            response = try? patient.send(ControlRequest(arguments: ["status"]))
            second.fulfill()
        }
        wait(for: [second], timeout: 2)
        XCTAssertEqual(response, .success(.string("alive")))
    }
}

final class CapsomniaCLITests: XCTestCase {
    func testHelpDoesNotRequireAnInstalledApp() {
        var output = ""
        let status = CapsomniaCLICommand.run(arguments: ["help"], output: { output = $0 }, errorOutput: { _ in })
        XCTAssertEqual(status, 0)
        XCTAssertTrue(output.contains("timer set <duration>"))
    }

    func testMalformedMutationDoesNotLaunchOrConnect() {
        var errors = ""
        let status = CapsomniaCLICommand.run(arguments: ["timer", "set", "3weeks"], output: { _ in }, errorOutput: { errors = $0 })
        XCTAssertEqual(status, 2)
        XCTAssertTrue(errors.contains("timer set requires"))
    }

    func testVersionAndJSONUsageError() {
        var version = ""
        XCTAssertEqual(CapsomniaCLICommand.run(arguments: ["version"], output: { version = $0 }, errorOutput: { _ in }), 0)
        XCTAssertEqual(version, "cpsm 0.1.0")

        var json = ""
        let status = CapsomniaCLICommand.run(
            arguments: ["--json", "settings", "set", "shortcut", "x"],
            output: { json = $0 },
            errorOutput: { _ in }
        )
        XCTAssertEqual(status, 2)
        XCTAssertTrue(json.contains("\"ok\":false"))
        XCTAssertTrue(json.contains("read-only"))
    }
}
