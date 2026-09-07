import Foundation
import CapsomniaControl

public struct CapsomniaCLICommand {
    public static let version = "0.1.0"

    public init() {}

    @discardableResult
    public static func run(
        arguments: [String] = Array(CommandLine.arguments.dropFirst()),
        output: @escaping (String) -> Void = { print($0) },
        errorOutput: @escaping (String) -> Void = { FileHandle.standardError.write(($0 + "\n").data(using: .utf8)!) }
    ) -> Int32 {
        let wantsJSON = arguments.contains("--json")
        do {
            let parsed = try CLIParser.parse(arguments)
            if parsed.help { output(Self.helpText); return 0 }
            if parsed.version { output("cpsm \(version)"); return 0 }

            let bundle = try AppBundle(path: parsed.appPath)
            let client = try ControlClient(bundleIdentifier: bundle.identifier)
            let response = try sendWithLaunch(
                client: client,
                request: ControlRequest(arguments: parsed.commandArguments),
                appPath: bundle.path
            )
            if parsed.json {
                output(try encode(response))
            } else if response.ok {
                output(humanText(for: response.result))
            } else {
                errorOutput(response.error ?? "Capsomnia rejected the request")
                return 1
            }
            return response.ok ? 0 : 1
        } catch let error as CLIError {
            emitError(error.localizedDescription, json: wantsJSON, output: output, errorOutput: errorOutput)
            return error.exitCode
        } catch let error as ControlTransportError {
            emitError(error.localizedDescription, json: wantsJSON, output: output, errorOutput: errorOutput)
            return 1
        } catch {
            emitError(error.localizedDescription, json: wantsJSON, output: output, errorOutput: errorOutput)
            return 1
        }
    }

    private static func emitError(
        _ message: String,
        json: Bool,
        output: (String) -> Void,
        errorOutput: (String) -> Void
    ) {
        if json, let encoded = try? encode(.failure(message)) {
            output(encoded)
        } else {
            errorOutput(message)
        }
    }

    public static let helpText = """
    Usage: cpsm [--json] [--app PATH] <command>

    Commands:
      on                              Turn Capsomnia on
      off                             Turn Capsomnia off and sleep the Mac
      toggle                          Toggle Capsomnia
      status [--json]                 Show current state
      timer set <duration>            Start a one-shot timer (for example 2h or 90s)
      timer status                    Show the active timer
      timer restart                   Restart the active timer
      timer cancel                    Cancel the timer and keep Capsomnia on
      settings get [key]              Read one or all settings
      settings set <key> <value>      Change a setting
      doctor                          Check the app and control channel
      help                            Show this help
      version                         Show the CLI version

    Options:
      --json                          Emit a stable JSON response
      --app PATH                      Use a local Capsomnia.app bundle
    """

    private static func sendWithLaunch(
        client: ControlClient,
        request: ControlRequest,
        appPath: String
    ) throws -> ControlResponse {
        do {
            return try client.send(request)
        } catch let error as ControlTransportError {
            guard case .connectFailed = error else { throw error }
            try AppBundle.launch(path: appPath)
            let deadline = Date().addingTimeInterval(8)
            var lastError = error
            while Date() < deadline {
                do { return try client.send(request) }
                catch let retryError as ControlTransportError {
                    guard case .connectFailed = retryError else { throw retryError }
                    lastError = retryError
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
            throw lastError
        }
    }

    private static func encode(_ response: ControlResponse) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(response)
        return String(decoding: data, as: UTF8.self)
    }

    private static func humanText(for value: JSONValue?) -> String {
        guard let value else { return "OK" }
        switch value {
        case let .object(object):
            return object.keys.sorted().map { key in
                "\(key): \(humanText(for: object[key]))"
            }.joined(separator: "\n")
        case let .array(array):
            return array.map { humanText(for: $0) }.joined(separator: "\n")
        case let .string(string): return string
        case let .bool(value): return value ? "true" : "false"
        case let .number(value):
            return value.rounded() == value ? String(Int(value)) : String(value)
        case .null: return "null"
        }
    }
}

private enum CLIError: Error, LocalizedError {
    case usage(String)
    case missingApp(String)
    case invalidSetting(String)
    case cannotLaunch(String)

    var exitCode: Int32 { 2 }
    var errorDescription: String? {
        switch self {
        case let .usage(message): return "Error: \(message)\n\nRun 'cpsm help' for usage."
        case let .missingApp(message), let .invalidSetting(message), let .cannotLaunch(message): return message
        }
    }
}

private struct ParsedCLI {
    var appPath = "/Applications/Capsomnia.app"
    var json = false
    var help = false
    var version = false
    var commandArguments: [String] = []
}

private enum CLIParser {
    static let settingKeys: Set<String> = [
        "dedicated-caps-lock-mode", "show-menu-bar-icon", "language", "launch-at-login",
        "keep-display-awake", "ignore-external-caps-lock-off-while-lid-closed",
        "auto-off-minutes", "automatic-update-checks"
    ]
    static let boolSettings: Set<String> = [
        "dedicated-caps-lock-mode", "show-menu-bar-icon", "launch-at-login",
        "keep-display-awake", "ignore-external-caps-lock-off-while-lid-closed", "automatic-update-checks"
    ]

    static func parse(_ arguments: [String]) throws -> ParsedCLI {
        var result = ParsedCLI()
        var positional: [String] = []
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--help", "-h": result.help = true
            case "--version", "-v": result.version = true
            case "--json": result.json = true
            case "--app":
                index += 1
                guard index < arguments.count, !arguments[index].hasPrefix("-") else {
                    throw CLIError.usage("--app requires a path")
                }
                result.appPath = arguments[index]
            default:
                if argument.hasPrefix("-") { throw CLIError.usage("Unknown option '\(argument)'") }
                positional.append(argument)
            }
            index += 1
        }
        if result.help || result.version { return result }
        if positional == ["help"] { result.help = true; return result }
        if positional == ["version"] { result.version = true; return result }
        try validate(positional)
        result.commandArguments = positional
        return result
    }

    private static func validate(_ args: [String]) throws {
        guard let command = args.first else { throw CLIError.usage("A command is required") }
        switch command {
        case "on", "off", "toggle", "status", "doctor":
            guard args.count == 1 else { throw CLIError.usage("'\(command)' does not accept arguments") }
        case "timer":
            guard args.count >= 2 else { throw CLIError.usage("timer requires set, status, restart, or cancel") }
            switch args[1] {
            case "set":
                guard args.count == 3, validDuration(args[2]) else { throw CLIError.usage("timer set requires a duration from 1s to 24h") }
            case "status", "restart", "cancel":
                guard args.count == 2 else { throw CLIError.usage("timer \(args[1]) does not accept arguments") }
            default: throw CLIError.usage("Unknown timer command '\(args[1])'")
            }
        case "settings":
            guard args.count >= 2 else { throw CLIError.usage("settings requires get or set") }
            switch args[1] {
            case "get":
                guard args.count <= 3 else { throw CLIError.usage("settings get accepts an optional key") }
                if args.count == 3 { try validateKey(args[2], writable: false) }
            case "set":
                guard args.count == 4 else { throw CLIError.usage("settings set requires a key and value") }
                try validateKey(args[2], writable: true)
                try validateValue(key: args[2], value: args[3])
            default: throw CLIError.usage("Unknown settings command '\(args[1])'")
            }
        case "help", "version":
            guard args.count == 1 else { throw CLIError.usage("'\(command)' does not accept arguments") }
        default: throw CLIError.usage("Unknown command '\(command)'")
        }
    }

    private static func validateKey(_ key: String, writable: Bool) throws {
        if key == "shortcut" && !writable { return }
        guard settingKeys.contains(key) else {
            throw CLIError.invalidSetting("Unknown or read-only setting '\(key)'")
        }
    }

    private static func validateValue(key: String, value: String) throws {
        if boolSettings.contains(key), value != "true", value != "false", value != "on", value != "off" {
            throw CLIError.invalidSetting("Setting '\(key)' expects true or false")
        }
        if key == "language", !["en", "ja", "ko", "zh-Hans"].contains(value) {
            throw CLIError.invalidSetting("language must be en, ja, ko, or zh-Hans")
        }
        if key == "auto-off-minutes",
           Int(value).map({ $0 < 0 || $0 > 1440 }) ?? true {
            throw CLIError.invalidSetting("auto-off-minutes must be between 0 and 1440")
        }
    }

    private static func validDuration(_ value: String) -> Bool {
        let units: [(Character, Double)] = [("s", 1), ("m", 60), ("h", 3600)]
        guard let unit = units.first(where: { value.last == $0.0 }),
              let amount = Double(value.dropLast()), amount.isFinite, amount >= 1 else { return false }
        return amount * unit.1 <= 24 * 3600
    }
}

private struct AppBundle {
    let path: String
    let identifier: String

    init(path: String) throws {
        let expanded = (path as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expanded) else {
            throw CLIError.missingApp("Capsomnia.app was not found at \(expanded)")
        }
        guard let bundle = Bundle(path: expanded), let identifier = bundle.bundleIdentifier else {
            throw CLIError.missingApp("Could not read the bundle identifier from \(expanded)")
        }
        self.path = expanded
        self.identifier = identifier
    }

    static func launch(path: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", path]
        do { try process.run(); process.waitUntilExit() }
        catch { throw CLIError.cannotLaunch("Could not launch Capsomnia: \(error.localizedDescription)") }
        guard process.terminationStatus == 0 else {
            throw CLIError.cannotLaunch("Could not launch Capsomnia")
        }
    }
}
