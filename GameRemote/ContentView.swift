import SwiftUI

struct ContentView: View {
    @StateObject private var store = Store()

    @State private var isEditingLayout = false

    @State private var showAddTabAlert = false
    @State private var newTabName = ""

    @State private var renamingTabID: RemoteTab.ID?
    @State private var renameText = ""

    @State private var showCommandEditor = false
    @State private var editingCommand: CommandItem?

    @State private var toast: String?

    private var selectedTab: RemoteTab? {
        store.tabs.first { $0.id == store.selectedTabID }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            content
        }
        .background(Color(.systemBackground))
        // Add tab
        .alert("New Tab", isPresented: $showAddTabAlert) {
            TextField("Tab name", text: $newTabName)
            Button("Add") {
                store.addTab(named: newTabName)
                newTabName = ""
            }
            Button("Cancel", role: .cancel) { newTabName = "" }
        }
        // Rename tab
        .alert("Rename Tab", isPresented: Binding(
            get: { renamingTabID != nil },
            set: { if !$0 { renamingTabID = nil } }
        )) {
            TextField("Tab name", text: $renameText)
            Button("Save") {
                if let id = renamingTabID { store.renameTab(id, to: renameText) }
                renamingTabID = nil
            }
            Button("Cancel", role: .cancel) { renamingTabID = nil }
        }
        // Add/edit command
        .sheet(isPresented: $showCommandEditor) {
            CommandEditorView(
                existing: editingCommand,
                defaultIP: selectedTab?.commands.last?.ip ?? "",
                defaultPort: selectedTab?.commands.last?.port ?? ""
            ) { item in
                guard let tabID = store.selectedTabID else { return }
                if editingCommand != nil {
                    store.updateCommand(item, in: tabID)
                } else {
                    store.addCommand(item, to: tabID)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(.caption)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Sidebar (customizable tabs)

    private var sidebar: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(store.tabs) { tab in
                        sidebarRow(for: tab)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 8)
            }

            Spacer(minLength: 0)

            Button {
                showAddTabAlert = true
            } label: {
                Label("Tab", systemImage: "plus")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 8)

            Button {
                isEditingLayout.toggle()
            } label: {
                Label(isEditingLayout ? "Done" : "Edit", systemImage: isEditingLayout ? "checkmark" : "pencil")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 130)
        .background(Color(.secondarySystemBackground))
    }

    private func sidebarRow(for tab: RemoteTab) -> some View {
        HStack(spacing: 4) {
            Button {
                store.selectedTabID = tab.id
            } label: {
                Text(tab.name)
                    .lineLimit(1)
                    .font(.system(size: 14, weight: tab.id == store.selectedTabID ? .semibold : .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8).padding(.horizontal, 10)
                    .background(tab.id == store.selectedTabID ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)

            if isEditingLayout {
                Menu {
                    Button("Rename") {
                        renameText = tab.name
                        renamingTabID = tab.id
                    }
                    Button("Delete", role: .destructive) {
                        store.deleteTab(tab.id)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .padding(.trailing, 4)
                }
            }
        }
    }

    // MARK: - Content (commands for the selected tab)

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let tab = selectedTab {
                HStack {
                    Text(tab.name).font(.title3).bold()
                    Spacer()
                    Button {
                        editingCommand = nil
                        showCommandEditor = true
                    } label: {
                        Label("Add Command", systemImage: "plus.circle.fill")
                    }
                }
                .padding()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                        ForEach(tab.commands) { command in
                            commandTile(command, in: tab)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            } else {
                Spacer()
                VStack(spacing: 8) {
                    Text("No tabs yet").foregroundColor(.secondary)
                    Button("Add a Tab") { showAddTabAlert = true }
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
    }

    private func commandTile(_ command: CommandItem, in tab: RemoteTab) -> some View {
        VStack(spacing: 6) {
            Button {
                send(command)
            } label: {
                VStack(spacing: 4) {
                    Text(command.name).font(.headline).multilineTextAlignment(.center)
                    Text("\(command.ip):\(command.port)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            if isEditingLayout {
                HStack {
                    Button("Edit") {
                        editingCommand = command
                        showCommandEditor = true
                    }
                    .font(.caption)
                    Spacer()
                    Button("Delete", role: .destructive) {
                        store.deleteCommand(command.id, from: tab.id)
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Sending

    private func send(_ command: CommandItem) {
        NetworkSender.send(ip: command.ip, port: command.port, packet: command.packet) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    showToast("Sent: \(command.name)")
                case .failure(let message):
                    showToast("Failed: \(message)")
                }
            }
        }
    }

    private func showToast(_ text: String) {
        withAnimation { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { toast = nil }
        }
    }
}

#Preview {
    ContentView()
}
