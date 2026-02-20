import Foundation
import Carbon

final class HotKeyManager: @unchecked Sendable {
    static let shared = HotKeyManager()

    var onToggle: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    private init() {}

    func register() {
        let keyCode: UInt32 = 50 // backtick
        let modifiers: UInt32 = UInt32(cmdKey)

        var hotKeyID = EventHotKeyID(
            signature: UTGetOSTypeFromString("WAVE" as CFString),
            id: 1
        )

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let refPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return noErr }
                let mgr = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { mgr.onToggle?() }
                return noErr
            },
            1,
            &eventType,
            refPointer,
            &handlerRef
        )

        let status = RegisterEventHotKey(
            keyCode, modifiers, hotKeyID,
            GetApplicationEventTarget(), 0, &hotKeyRef
        )
        if status != noErr {
            print("[Wave] Failed to register Cmd+` hotkey: \(status)")
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
        }
    }

    deinit { unregister() }
}
