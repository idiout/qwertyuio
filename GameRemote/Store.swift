import Foundation
import Combine

final class Store: ObservableObject {
    @Published var tabs: [RemoteTab] {
        didSet { save() }
    }
    @Published var selectedTabID: RemoteTab.ID?

    private let storageKey = "gameremote.tabs.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([RemoteTab].self, from: data),
           !decoded.isEmpty {
            self.tabs = decoded
        } else {
            self.tabs = Store.defaultTabs()
        }
        self.selectedTabID = tabs.first?.id
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tabs) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func defaultTabs() -> [RemoteTab] {
        [
            RemoteTab(name: "Main", commands: [
                CommandItem(name: "Jump", ip: "192.168.1.100", port: "8080", packet: "jump"),
                CommandItem(name: "Attack", ip: "192.168.1.100", port: "8080", packet: "attack")
            ])
        ]
    }

    // MARK: Tabs

    func addTab(named name: String) {
        let tab = RemoteTab(name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "New Tab" : name)
        tabs.append(tab)
        selectedTabID = tab.id
    }

    func renameTab(_ id: RemoteTab.ID, to newName: String) {
        guard let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { tabs[idx].name = trimmed }
    }

    func deleteTab(_ id: RemoteTab.ID) {
        tabs.removeAll { $0.id == id }
        if selectedTabID == id { selectedTabID = tabs.first?.id }
    }

    func moveTab(from source: IndexSet, to destination: Int) {
        tabs.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: Commands

    func addCommand(_ command: CommandItem, to tabID: RemoteTab.ID) {
        guard let idx = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        tabs[idx].commands.append(command)
    }

    func updateCommand(_ command: CommandItem, in tabID: RemoteTab.ID) {
        guard let tIdx = tabs.firstIndex(where: { $0.id == tabID }),
              let cIdx = tabs[tIdx].commands.firstIndex(where: { $0.id == command.id }) else { return }
        tabs[tIdx].commands[cIdx] = command
    }

    func deleteCommand(_ commandID: CommandItem.ID, from tabID: RemoteTab.ID) {
        guard let tIdx = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        tabs[tIdx].commands.removeAll { $0.id == commandID }
    }
}
