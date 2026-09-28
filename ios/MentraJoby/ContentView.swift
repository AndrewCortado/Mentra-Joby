import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: GlassesController

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(controller.phase.title)
                .font(.largeTitle.bold())
            if controller.isReconnecting {
                Text("Reconnecting…")
                    .font(.title3)
            }
            if let statusMessage = controller.statusMessage {
                Text(statusMessage)
                    .foregroundStyle(.secondary)
            }
            if controller.needsAudioRouteHint {
                Text(GlassesController.audioRouteHint)
            }
            ForEach(controller.devices) { device in
                Button(device.name) {
                    controller.connect(device)
                }
                .buttonStyle(.bordered)
            }
            VStack(alignment: .leading, spacing: 12) {
                Button("Scan", action: controller.scan)
                Button("Reconnect", action: controller.reconnect)
                Button("Disconnect", action: controller.disconnect)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
