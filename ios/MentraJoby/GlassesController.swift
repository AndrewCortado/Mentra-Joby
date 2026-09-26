import AVFoundation
import Foundation
import MentraBluetoothSDK
import SwiftUI

enum ConnectionPhase: Equatable {
    case searching
    case connecting
    case connected
    case disconnected

    var title: String {
        switch self {
        case .searching:
            "Searching"
        case .connecting:
            "Connecting"
        case .connected:
            "Connected"
        case .disconnected:
            "Disconnected"
        }
    }

    static func from(_ state: GlassesConnectionState) -> ConnectionPhase {
        switch state {
        case .scanning:
            .searching
        case .connecting, .bonding:
            .connecting
        case .connected:
            .connected
        case .disconnected:
            .disconnected
        @unknown default:
            .disconnected
        }
    }
}

struct ReconnectPolicy: Equatable {
    var interval: TimeInterval = 30

    func shouldRetry(phase: ConnectionPhase, hasDefaultDevice: Bool, userDisconnected: Bool) -> Bool {
        phase == .disconnected && hasDefaultDevice && !userDisconnected
    }
}

struct WelcomeOnce: Equatable {
    private(set) var spoken = false

    mutating func consume(ready: Bool, hasBluetoothRoute: Bool) -> Bool {
        guard ready, hasBluetoothRoute, !spoken else { return false }
        spoken = true
        return true
    }
}

@MainActor
final class GlassesController: ObservableObject, MentraBluetoothSDKDelegate {
    static let welcomeText = "Welcome to the Mentra X Joby tour"
    static let audioRouteHint = "select Mentra Live in Settings → Bluetooth"

    @Published private(set) var phase: ConnectionPhase = .disconnected
    @Published private(set) var devices: [Device] = []
    @Published private(set) var needsAudioRouteHint = false
    @Published private(set) var isReconnecting = false
    @Published private(set) var statusMessage: String?

    private let sdk: MentraBluetoothSDK
    private let speaker: WelcomeSpeaking
    private let defaults: UserDefaults
    private let routeIsBluetooth: () -> Bool
    private let reconnectPolicy = ReconnectPolicy()
    private var savedDevice: Device?
    private var userDisconnected = false
    private var glassesReady = false
    private var welcome = WelcomeOnce()
    // Mentra Live discovery does not publish GlassesConnectionState.scanning.
    private var scanning = false
    private var scanSession: ScanSession?
    private var retryTimer: Timer?
    private var foreground = true
    private var started = false
    private var routeObserver: NSObjectProtocol?

    init(
        sdk: MentraBluetoothSDK = MentraBluetoothSDK(configuration: .init(analytics: .disabled)),
        speaker: WelcomeSpeaking? = nil,
        defaults: UserDefaults = .standard,
        routeIsBluetooth: @escaping () -> Bool = AudioRoute.currentIsBluetooth
    ) {
        self.sdk = sdk
        self.defaults = defaults
        self.routeIsBluetooth = routeIsBluetooth
        let ownsSpeaker = speaker == nil
        let resolvedSpeaker = speaker ?? WelcomeSpeaker()
        self.speaker = resolvedSpeaker
        savedDevice = Self.storedDevice(in: defaults)
        sdk.delegate = self
        if ownsSpeaker, let welcomeSpeaker = resolvedSpeaker as? WelcomeSpeaker {
            welcomeSpeaker.onPlayingChanged = { [weak self] playing in
                self?.sdk.setOwnAppAudioPlaying(playing)
            }
            welcomeSpeaker.onFinished = { [weak self] in
                self?.requestMicPermissionIfNeeded()
            }
        }
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAudioRouteChange()
            }
        }
    }

    func start() {
        guard !started else { return }
        started = true
        if let savedDevice {
            sdk.setDefaultDevice(savedDevice)
            beginConnectDefault(reconnecting: true)
        } else {
            scan()
        }
    }

    func scan() {
        let previous = scanSession
        scanSession = nil
        scanning = false
        previous?.stop()

        scanning = true
        devices = []
        statusMessage = nil
        applyPhase(.searching)
        isReconnecting = false
        do {
            scanSession = try sdk.scan(model: .mentraLive, timeout: 15, onResults: { [weak self] found in
                self?.devices = found
            }, onComplete: { [weak self] found in
                self?.finishScan(found)
            })
        } catch {
            scanning = false
            scanSession = nil
            statusMessage = Self.message(for: error)
            applyPhase(.disconnected)
        }
    }

    func connect(_ device: Device) {
        userDisconnected = false
        scanning = false
        savedDevice = device
        persist(device)
        isReconnecting = false
        statusMessage = nil
        let session = scanSession
        scanSession = nil
        applyPhase(.connecting)
        session?.stop()
        do {
            try sdk.connect(to: device)
        } catch {
            statusMessage = Self.message(for: error)
            applyPhase(.disconnected)
        }
    }

    func reconnect() {
        userDisconnected = false
        if savedDevice == nil {
            savedDevice = Self.storedDevice(in: defaults)
        }
        guard let savedDevice else {
            statusMessage = "No saved glasses. Scan and choose Mentra Live."
            return
        }
        sdk.setDefaultDevice(savedDevice)
        beginConnectDefault(reconnecting: true)
    }

    func disconnect() {
        userDisconnected = true
        scanning = false
        isReconnecting = false
        needsAudioRouteHint = false
        let session = scanSession
        scanSession = nil
        statusMessage = nil
        session?.stop()
        sdk.disconnect()
        applyPhase(.disconnected)
    }

    func appBecameActive() {
        foreground = true
        guard started else { return }
        retryIfNeeded()
        updateRetryTimer()
    }

    func appLeftForeground() {
        foreground = false
        updateRetryTimer()
    }

    func handleAudioRouteChange() {
        speakWelcomeIfNeeded()
    }

    func mentraBluetoothSDK(_: MentraBluetoothSDK, didUpdateGlasses glasses: GlassesRuntimeState) {
        glassesReady = glasses.ready
        let mapped = ConnectionPhase.from(glasses.connection)
        if scanning, mapped == .disconnected {
            applyPhase(.searching)
        } else {
            if mapped == .connecting || mapped == .connected {
                scanning = false
            }
            applyPhase(mapped)
        }
        if glasses.ready {
            statusMessage = nil
        }
        speakWelcomeIfNeeded()
    }

    func mentraBluetoothSDK(_: MentraBluetoothSDK, didFail error: BluetoothSdkError) {
        statusMessage = error.message
    }

    // Future voice input uses the glasses mic over the SDK Bluetooth link (useGlassesMic: true).
    private func requestMicPermissionIfNeeded() {
        guard !defaults.bool(forKey: StorageKey.micPermissionRequested) else { return }
        defaults.set(true, forKey: StorageKey.micPermissionRequested)
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                self?.defaults.set(granted, forKey: StorageKey.micPermissionGranted)
            }
        }
    }

    private func beginConnectDefault(reconnecting: Bool) {
        guard savedDevice != nil else { return }
        userDisconnected = false
        scanning = false
        isReconnecting = reconnecting
        statusMessage = nil
        let session = scanSession
        scanSession = nil
        applyPhase(.connecting)
        session?.stop()
        do {
            try sdk.connectDefault()
        } catch {
            statusMessage = Self.message(for: error)
            applyPhase(.disconnected)
            if reconnecting {
                isReconnecting = true
            }
        }
    }

    private func finishScan(_ found: [Device]) {
        devices = found
        scanSession = nil
        scanning = false
        guard phase == .searching else { return }
        applyPhase(.disconnected)
    }

    private func retryIfNeeded() {
        guard foreground else { return }
        guard reconnectPolicy.shouldRetry(
            phase: phase,
            hasDefaultDevice: savedDevice != nil,
            userDisconnected: userDisconnected
        ) else { return }
        beginConnectDefault(reconnecting: true)
    }

    private func applyPhase(_ newPhase: ConnectionPhase) {
        if phase == .connected, newPhase != .connected, !userDisconnected {
            isReconnecting = true
        }
        if newPhase == .connected {
            isReconnecting = false
        }
        phase = newPhase
        updateRetryTimer()
    }

    private func updateRetryTimer() {
        let allow = foreground && reconnectPolicy.shouldRetry(
            phase: phase,
            hasDefaultDevice: savedDevice != nil,
            userDisconnected: userDisconnected
        )
        if allow {
            guard retryTimer == nil else { return }
            let timer = Timer(timeInterval: reconnectPolicy.interval, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.retryIfNeeded()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            retryTimer = timer
        } else {
            retryTimer?.invalidate()
            retryTimer = nil
        }
    }

    private func speakWelcomeIfNeeded() {
        if welcome.consume(ready: glassesReady, hasBluetoothRoute: routeIsBluetooth()) {
            needsAudioRouteHint = false
            speaker.speak(Self.welcomeText)
            return
        }
        if glassesReady, !welcome.spoken, !routeIsBluetooth() {
            needsAudioRouteHint = true
        } else if routeIsBluetooth() {
            needsAudioRouteHint = false
        }
    }

    private func persist(_ device: Device) {
        defaults.set(device.model.deviceType, forKey: StorageKey.model)
        defaults.set(device.name, forKey: StorageKey.name)
        defaults.set(device.identifier ?? "", forKey: StorageKey.identifier)
    }

    private static func storedDevice(in defaults: UserDefaults) -> Device? {
        guard
            let model = defaults.string(forKey: StorageKey.model), !model.isEmpty,
            let name = defaults.string(forKey: StorageKey.name), !name.isEmpty
        else {
            return nil
        }
        let identifier = defaults.string(forKey: StorageKey.identifier).flatMap { $0.isEmpty ? nil : $0 }
        return Device(model: .fromDeviceType(model), name: name, identifier: identifier)
    }

    private static func message(for error: Error) -> String {
        if let sdkError = error as? BluetoothSdkError {
            return sdkError.message
        }
        return error.localizedDescription
    }
}

private enum StorageKey {
    static let model = "mentrajoby.savedDevice.model"
    static let name = "mentrajoby.savedDevice.name"
    static let identifier = "mentrajoby.savedDevice.identifier"
    static let micPermissionRequested = "mentrajoby.micPermissionRequested"
    static let micPermissionGranted = "mentrajoby.micPermissionGranted"
}
