import MentraBluetoothSDK
import XCTest
@testable import MentraJoby

@MainActor
final class GlassesControllerTests: XCTestCase {
    func testConnectionPhaseMapsAllSdkStates() {
        XCTAssertEqual(ConnectionPhase.from(.disconnected), .disconnected)
        XCTAssertEqual(ConnectionPhase.from(.scanning), .searching)
        XCTAssertEqual(ConnectionPhase.from(.connecting), .connecting)
        XCTAssertEqual(ConnectionPhase.from(.bonding), .connecting)
        XCTAssertEqual(ConnectionPhase.from(.connected), .connected)
        XCTAssertEqual(ConnectionPhase.searching.title, "Searching")
        XCTAssertEqual(ConnectionPhase.connecting.title, "Connecting")
        XCTAssertEqual(ConnectionPhase.connected.title, "Connected")
        XCTAssertEqual(ConnectionPhase.disconnected.title, "Disconnected")
    }

    func testReconnectPolicyRetriesOnlyWhileDisconnectedWithASavedDevice() {
        let policy = ReconnectPolicy()
        XCTAssertEqual(policy.interval, 30)
        XCTAssertTrue(policy.shouldRetry(phase: .disconnected, hasDefaultDevice: true, userDisconnected: false))
        XCTAssertFalse(policy.shouldRetry(phase: .disconnected, hasDefaultDevice: true, userDisconnected: true))
        XCTAssertFalse(policy.shouldRetry(phase: .disconnected, hasDefaultDevice: false, userDisconnected: false))
        XCTAssertFalse(policy.shouldRetry(phase: .searching, hasDefaultDevice: true, userDisconnected: false))
        XCTAssertFalse(policy.shouldRetry(phase: .connecting, hasDefaultDevice: true, userDisconnected: false))
        XCTAssertFalse(policy.shouldRetry(phase: .connected, hasDefaultDevice: true, userDisconnected: false))
    }

    func testSpeaksWelcomeOnceWhenRouteIsAlreadyBluetooth() {
        let speaker = FakeSpeaker()
        let (controller, sdk) = makeController(speaker: speaker, bluetoothRoute: true)

        controller.mentraBluetoothSDK(sdk, didUpdateGlasses: glasses(ready: false))
        XCTAssertEqual(speaker.lines, [])

        controller.mentraBluetoothSDK(sdk, didUpdateGlasses: glasses(ready: true))
        controller.mentraBluetoothSDK(sdk, didUpdateGlasses: glasses(ready: true))
        XCTAssertEqual(speaker.lines, ["Welcome to the Mentra X Joby tour"])
        XCTAssertFalse(controller.needsAudioRouteHint)
    }

    func testWaitsForBluetoothRouteThenSpeaksOnce() {
        let speaker = FakeSpeaker()
        let route = RouteFlag(false)
        let (controller, sdk) = makeController(speaker: speaker, route: route)

        controller.mentraBluetoothSDK(sdk, didUpdateGlasses: glasses(ready: true))
        XCTAssertEqual(speaker.lines, [])
        XCTAssertTrue(controller.needsAudioRouteHint)

        route.value = true
        controller.handleAudioRouteChange()
        controller.handleAudioRouteChange()
        XCTAssertEqual(speaker.lines, [GlassesController.welcomeText])
        XCTAssertFalse(controller.needsAudioRouteHint)
        XCTAssertEqual(GlassesController.audioRouteHint, "select Mentra Live in Settings → Bluetooth")
    }

    private func makeController(speaker: FakeSpeaker, bluetoothRoute: Bool) -> (GlassesController, MentraBluetoothSDK) {
        makeController(speaker: speaker, route: RouteFlag(bluetoothRoute))
    }

    private func makeController(speaker: FakeSpeaker, route: RouteFlag) -> (GlassesController, MentraBluetoothSDK) {
        let suite = "MentraJobyTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let sdk = MentraBluetoothSDK(configuration: .init(analytics: .disabled))
        let controller = GlassesController(
            sdk: sdk,
            speaker: speaker,
            defaults: defaults,
            routeIsBluetooth: { route.value }
        )
        return (controller, sdk)
    }

    private func glasses(ready: Bool) -> GlassesRuntimeState {
        .connected(
            battery: GlassesBatteryState(charging: false, level: nil),
            connection: .connected,
            device: ConnectedGlassesInfo(
                appVersion: nil,
                bluetoothName: "Mentra Live",
                buildNumber: nil,
                color: nil,
                deviceModel: .mentraLive,
                firmwareVersion: nil,
                serialNumber: nil,
                style: nil
            ),
            firmware: FirmwareInfo(appVersion: nil, buildNumber: nil, source: .unknown, version: nil),
            hotspot: .disabled,
            ready: ready,
            signal: SignalState(strengthDbm: nil, updatedAt: nil),
            voiceActivityDetectionEnabled: false,
            wifi: .disconnected
        )
    }
}

private final class FakeSpeaker: WelcomeSpeaking {
    private(set) var lines: [String] = []

    func speak(_ text: String) {
        lines.append(text)
    }
}

private final class RouteFlag {
    var value: Bool
    init(_ value: Bool) { self.value = value }
}
