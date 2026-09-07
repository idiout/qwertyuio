import Foundation

struct CommandItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var ip: String
    var port: String     // kept as String for easy editing; validated/converted when sending
    var packet: String   // plain text, or space/comma-separated hex like "AA BB 01"
}

struct RemoteTab: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var commands: [CommandItem] = []
}
