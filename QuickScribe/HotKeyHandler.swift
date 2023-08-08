//
//  HotKeyHandler.swift
//  QuickScribe
//
//  Created by Mike Brevoort on 8/7/23.
//

//import Carbon
//
//class HotKeyHandler {
//    private var hotKeyRef: EventHotKeyRef?
//
//    init() {
//        let signature: OSType = UInt32((UInt32("h".unicodeScalars.first!.value) << 24) +
//                                       (UInt32("k".unicodeScalars.first!.value) << 16) +
//                                       (UInt32("1".unicodeScalars.first!.value) << 8) +
//                                       UInt32(" ".unicodeScalars.first!.value))
//        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
//        let keyCode = UInt32(kVK_ANSI_X)
//        let modifiers = UInt32(optionKey) | UInt32(shiftKey)
//
//        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
//
//        // self.hotKeyRef = hotKeyRef
//
//        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
//        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
//            let hkRef = UnsafeMutablePointer<EventHotKeyRef?>.allocate(capacity: 1)
//            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyRef), nil, MemoryLayout<EventHotKeyRef?>.size, nil, hkRef)
//
//            if hkRef.pointee == self.hotKeyRef {
//                print("Hot key pressed!")
//            }
//            return noErr
//        }, 1, &eventType, nil, nil)
//    }
//}
//
//let handler = HotKeyHandler()
//RunLoop.current.run()
