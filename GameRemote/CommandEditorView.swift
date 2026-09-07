import SwiftUI

struct CommandEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var ip: String
    @State private var port: String
    @State private var packet: String

    private let existingID: UUID?
    let onSave: (CommandItem) -> Void

    init(existing: CommandItem? = nil,
         defaultIP: String = "",
         defaultPort: String = "",
         onSave: @escaping (CommandItem) -> Void) {
        _name = State(initialValue: existing?.name ?? "")
        _ip = State(initialValue: existing?.ip ?? defaultIP)
        _port = State(initialValue: existing?.port ?? defaultPort)
        _packet = State(initialValue: existing?.packet ?? "")
        self.existingID = existing?.id
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Command") {
                    TextField("Name", text: $name)
                }
                Section("Target") {
                    TextField("IP address", text: $ip)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
                Section("Packet") {
                    TextField("Text, or hex like AA BB 01", text: $packet)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Text("Plain text is sent as UTF-8. Space- or comma-separated hex bytes (e.g. \"AA BB 01\" or \"0xAA,0xBB\") are sent as raw bytes.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(existingID == nil ? "New Command" : "Edit Command")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let item = CommandItem(
                            id: existingID ?? UUID(),
                            name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "Command" : name,
                            ip: ip,
                            port: port,
                            packet: packet
                        )
                        onSave(item)
                        dismiss()
                    }
                    .disabled(ip.trimmingCharacters(in: .whitespaces).isEmpty || port.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
