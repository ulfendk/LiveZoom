import Cocoa
import Carbon

enum HotkeyKey: Int {
    case one = 18
    case two = 19
    case three = 20
    case four = 21
    case five = 23
    case six = 22
    case seven = 26
}

struct HotkeyModifiers: OptionSet {
    let rawValue: Int
    
    static let command = HotkeyModifiers(rawValue: cmdKey)
    static let shift = HotkeyModifiers(rawValue: shiftKey)
    static let option = HotkeyModifiers(rawValue: optionKey)
    static let control = HotkeyModifiers(rawValue: controlKey)
}

class HotkeyManager {
    private var hotkeys: [EventHotKeyRef?] = []
    private var handlers: [UInt32: () -> Void] = [:]
    private var nextId: UInt32 = 1
    
    init() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            var hotkeyId = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyId)
            
            manager.handlers[hotkeyId.id]?()
            return noErr
        }, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }
    
    func registerHotkey(key: HotkeyKey, modifiers: HotkeyModifiers, handler: @escaping () -> Void) {
        var hotkeyRef: EventHotKeyRef?
        let hotkeyId = EventHotKeyID(signature: OSType(0x4C5A4F4D), id: nextId) // 'LZOM'
        
        let carbonModifiers = UInt32(modifiers.rawValue)
        
        RegisterEventHotKey(UInt32(key.rawValue), carbonModifiers, hotkeyId, GetApplicationEventTarget(), 0, &hotkeyRef)
        
        hotkeys.append(hotkeyRef)
        handlers[nextId] = handler
        nextId += 1
    }
    
    deinit {
        for hotkey in hotkeys {
            if let hotkey = hotkey {
                UnregisterEventHotKey(hotkey)
            }
        }
    }
}
