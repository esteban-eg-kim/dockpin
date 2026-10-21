import SwiftUI

/// First-run window, shown only while the Accessibility permission is missing.
struct OnboardingView: View {
    @ObservedObject var model: AppModel
    var close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text("dockpin").font(.title2.bold())
                    Text("Keep the Dock on one display.").foregroundStyle(.secondary)
                }
            }

            Text("To stop the Dock from following the cursor to other displays, dockpin needs to see mouse movement. Allow it under System Settings › Privacy & Security › Accessibility.")
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Label(
                    model.trusted ? "Access allowed" : "Waiting for access…",
                    systemImage: model.trusted ? "checkmark.circle.fill" : "hourglass"
                )
                .foregroundStyle(model.trusted ? .green : .secondary)
                Spacer()
                if model.trusted {
                    Button("Done", action: close).keyboardShortcut(.defaultAction)
                } else {
                    Button("Open System Settings") { model.requestAccess() }
                        .keyboardShortcut(.defaultAction)
                }
            }

            Text("dockpin lives in the menu bar (\(Image(systemName: "pin.fill"))). Pick the Dock's display there.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 440)
    }
}
