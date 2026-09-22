// macarchy-avstate: is any app using the microphone or the camera right now?
// Prints "mic=0|1 cam=0|1" and exits. The SketchyBar `mic` and `cam` items poll
// it so the bar shows the same thing the native menu bar's orange/green dots do.
//
// Build: home/.config/macarchy/swift/build (install.sh runs it when swiftc exists).
import CoreAudio
import CoreMediaIO
import Foundation

func micInUse() -> Bool {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size) == noErr else { return false }
    var devs = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &devs) == noErr else { return false }
    for d in devs {
        var sAddr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreams, mScope: kAudioObjectPropertyScopeInput, mElement: kAudioObjectPropertyElementMain)
        var sSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(d, &sAddr, 0, nil, &sSize) == noErr, sSize > 0 else { continue }  // input-capable only
        var rAddr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var running: UInt32 = 0
        var rSize = UInt32(MemoryLayout<UInt32>.size)
        if AudioObjectGetPropertyData(d, &rAddr, 0, nil, &rSize, &running) == noErr, running != 0 { return true }
    }
    return false
}

func camInUse() -> Bool {
    var addr = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices), mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal), mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
    var size: UInt32 = 0
    guard CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &addr, 0, nil, &size) == noErr else { return false }
    var devs = [CMIODeviceID](repeating: 0, count: Int(size) / MemoryLayout<CMIODeviceID>.size)
    var used: UInt32 = 0
    guard CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &addr, 0, nil, size, &used, &devs) == noErr else { return false }
    for d in devs {
        var rAddr = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere), mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal), mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        var running: UInt32 = 0
        let rSize = UInt32(MemoryLayout<UInt32>.size)
        var u: UInt32 = 0
        if CMIOObjectGetPropertyData(d, &rAddr, 0, nil, rSize, &u, &running) == noErr, running != 0 { return true }
    }
    return false
}

print("mic=\(micInUse() ? 1 : 0) cam=\(camInUse() ? 1 : 0)")
