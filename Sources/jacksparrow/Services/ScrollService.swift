import AppKit
import ApplicationServices

@MainActor
final class ScrollService: ObservableObject {
    enum State: Equatable {
        case stopped
        case paused
        case running
        case needsPermission
        case refused
    }

    @Published private(set) var state: State = .stopped
    @Published private(set) var isEnabled = Defaults.bool(ScrollService.enabledKey, default: true)
    @Published private(set) var invertedEvents = 0
    @Published private(set) var systemReportsAccess = AXIsProcessTrusted()
    @Published private(set) var attempts = 0

    private static let enabledKey = "shliker.invertWheel"

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var permissionTimer: Timer?
    private let logging = ProcessInfo.processInfo.environment["JS_SCROLLLOG"] == "1"
    private let logURL = URL(fileURLWithPath: "/tmp/jacksparrow-scroll.log")
    private var loggedLines = 0
    private var seenContinuous = 0
    private var seenDiscrete = 0
    private var pendingCount = 0
    private var lastPublish = Date.distantPast
    private let publishInterval: TimeInterval = 0.1

    var statusTitle: String {
        switch state {
        case .running:         return "Inverting wheel mice"
        case .paused:          return "Paused"
        case .needsPermission: return "Accessibility access needed"
        case .refused:         return "Access granted but tap refused"
        case .stopped:         return "Stopped"
        }
    }

    var needsAttention: Bool { state == .needsPermission || state == .refused }

    func activate() {
        guard isEnabled else {
            stopTap()
            state = .paused
            return
        }
        guard tap == nil else { return }

        attempts += 1
        systemReportsAccess = AXIsProcessTrusted()

        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        guard let machPort = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: scrollTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            log("tapCreate REFUSED · trusted=\(systemReportsAccess) · attempt=\(attempts)")
            state = systemReportsAccess ? .refused : .needsPermission
            startPermissionWatch()
            return
        }

        log("tap created · trusted=\(systemReportsAccess) · attempt=\(attempts)")

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPort, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: machPort, enable: true)

        tap = machPort
        source = runLoopSource
        stopPermissionWatch()
        state = .running
    }

    func deactivate() {
        stopTap()
        stopPermissionWatch()
        state = .stopped
    }

    func setEnabled(_ value: Bool) {
        guard value != isEnabled else { return }
        Defaults.set(value, forKey: Self.enabledKey)
        isEnabled = value
        if value {
            activate()
        } else {
            stopTap()
            stopPermissionWatch()
            state = .paused
        }
    }

    func requestPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        startPermissionWatch()
    }

    func flushCounter() {
        guard pendingCount > 0 else { return }
        invertedEvents += pendingCount
        pendingCount = 0
    }

    private func stopTap() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        tap = nil
        source = nil
    }

    private func startPermissionWatch() {
        guard permissionTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkPermission() }
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    private func stopPermissionWatch() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    func recheckAccess() {
        guard isEnabled else { return }
        stopTap()
        activate()
    }

    private func checkPermission() {
        guard needsAttention, isEnabled else { return }
        activate()
    }

    fileprivate func logEvent(continuous: Int64, delta: Int64, point: Int64, fixed: Double) {
        if continuous == 0 { seenDiscrete += 1 } else { seenContinuous += 1 }
        log("scroll continuous=\(continuous) delta=\(delta) point=\(point) fixed=\(fixed) · discrete=\(seenDiscrete) continuousTotal=\(seenContinuous)")
    }

    private func log(_ line: String) {
        guard logging, loggedLines < 200 else { return }
        loggedLines += 1
        let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let text = "\(stamp) \(line)\n"
        if let handle = try? FileHandle(forWritingTo: logURL) {
            handle.seekToEndOfFile()
            handle.write(Data(text.utf8))
            try? handle.close()
        } else {
            try? text.write(to: logURL, atomically: true, encoding: .utf8)
        }
    }

    fileprivate func countInverted() {
        pendingCount += 1
        let now = Date()
        guard now.timeIntervalSince(lastPublish) >= publishInterval else { return }
        lastPublish = now
        flushCounter()
    }

    fileprivate func reenableAfterDisable() {
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
    }
}

private func scrollTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let service = Unmanaged<ScrollService>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        MainActor.assumeIsolated { service.reenableAfterDisable() }
        return nil
    }

    guard type == .scrollWheel else { return Unmanaged.passUnretained(event) }

    let continuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
    let delta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
    let pointDelta = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
    let fixedDelta = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)

    MainActor.assumeIsolated {
        service.logEvent(continuous: continuous, delta: delta, point: pointDelta, fixed: fixedDelta)
    }

    guard continuous == 0 else { return Unmanaged.passUnretained(event) }

    event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -delta)
    event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -pointDelta)
    event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedDelta)

    MainActor.assumeIsolated { service.countInverted() }
    return Unmanaged.passUnretained(event)
}
