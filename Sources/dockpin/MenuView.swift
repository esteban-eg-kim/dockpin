import SwiftUI

struct MenuView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Toggle("Pin the Dock", isOn: $model.enabled)

        Divider()

        Picker("Keep the Dock on", selection: $model.pinnedID) {
            ForEach(model.screens) { screen in
                Text(screen.title).tag(Optional(screen.id))
            }
        }
        .pickerStyle(.inline)
        .disabled(!model.enabled)

        Divider()

        Toggle("Hold ⌥ to Let It Move", isOn: $model.optionBypass)
        Toggle("Open at Login", isOn: Binding(
            get: { model.launchAtLogin },
            set: { model.setLaunchAtLogin($0) }
        ))

        Divider()

        if model.trusted {
            Text("Accessibility: Allowed")
        } else {
            Button("⚠️ Allow Accessibility Access…") { model.requestAccess() }
        }
        Button("About dockpin") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.orderFrontStandardAboutPanel(nil)
        }
        Button("Quit dockpin") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
