import Foundation

@main
enum CapsomniaCLI {
    static func main() {
        let status = CapsomniaCLICommand.run()
        if status != 0 { exit(status) }
    }
}
