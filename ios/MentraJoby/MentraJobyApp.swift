import SwiftUI

@main
struct MentraJobyApp: App {
    @StateObject private var controller = GlassesController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(controller: controller)
                .onAppear { controller.start() }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        controller.appBecameActive()
                    } else {
                        controller.appLeftForeground()
                    }
                }
        }
    }
}
