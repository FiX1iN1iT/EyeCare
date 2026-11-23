//
//  SmartPauseMonitor.swift
//  EyeCare
//

import CoreAudio
import Foundation

/// Следит за тем, что приложение-звонок открыло входное аудиоустройство.
/// Не записывает и не читает аудиоданные, поэтому разрешение на микрофон не нужно.
final class SmartPauseMonitor {
    private var inputDeviceIDs: Set<AudioDeviceID>
    private let onMicrophoneUsageChanged: (Bool) -> Void
    private var isMicrophoneInUse = false
    private var devicesListener: AudioObjectPropertyListenerBlock!
    private var runningListeners: [AudioDeviceID: AudioObjectPropertyListenerBlock] = [:]
    private var devicesAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    private let runningAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    init(onMicrophoneUsageChanged: @escaping (Bool) -> Void) {
        self.onMicrophoneUsageChanged = onMicrophoneUsageChanged
        inputDeviceIDs = Self.currentInputDeviceIDs()
        inputDeviceIDs.forEach(installRunningListener)

        devicesListener = { [weak self] _, _ in
            self?.devicesDidChange()
        }
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddress,
            .main,
            devicesListener
        )

        checkForMicrophoneInUse()
    }

    deinit {
        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddress,
            .main,
            devicesListener
        )
        for (deviceID, listener) in runningListeners {
            var address = runningAddress
            AudioObjectRemovePropertyListenerBlock(deviceID, &address, .main, listener)
        }
    }

    private func devicesDidChange() {
        let currentIDs = Self.currentInputDeviceIDs()
        let removedIDs = inputDeviceIDs.subtracting(currentIDs)
        let addedIDs = currentIDs.subtracting(inputDeviceIDs)

        for deviceID in removedIDs {
            removeRunningListener(for: deviceID)
        }
        for deviceID in addedIDs {
            installRunningListener(for: deviceID)
        }
        inputDeviceIDs = currentIDs
        checkForMicrophoneInUse()
    }

    private func installRunningListener(for deviceID: AudioDeviceID) {
        guard runningListeners[deviceID] == nil else { return }
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.checkForMicrophoneInUse()
        }
        var address = runningAddress
        guard AudioObjectAddPropertyListenerBlock(deviceID, &address, .main, listener) == noErr else {
            return
        }
        runningListeners[deviceID] = listener
    }

    private func removeRunningListener(for deviceID: AudioDeviceID) {
        guard let listener = runningListeners.removeValue(forKey: deviceID) else { return }
        var address = runningAddress
        AudioObjectRemovePropertyListenerBlock(deviceID, &address, .main, listener)
    }

    private func checkForMicrophoneInUse() {
        var microphoneInUse = false
        for deviceID in inputDeviceIDs where Self.isRunning(deviceID) {
            microphoneInUse = true
            break
        }
        guard microphoneInUse != isMicrophoneInUse else { return }
        isMicrophoneInUse = microphoneInUse
        onMicrophoneUsageChanged(microphoneInUse)
    }

    private static func currentInputDeviceIDs() -> Set<AudioDeviceID> {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size
        ) == noErr else { return [] }

        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(), count: count)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceIDs
        ) == noErr else { return [] }

        var inputDeviceIDs = Set<AudioDeviceID>()
        for deviceID in deviceIDs where hasInputStream(deviceID) {
            inputDeviceIDs.insert(deviceID)
        }
        return inputDeviceIDs
    }

    private static func hasInputStream(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr,
              size >= MemoryLayout<AudioBufferList>.size else { return false }

        let bufferList = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { bufferList.deallocate() }
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, bufferList) == noErr else {
            return false
        }
        return bufferList.assumingMemoryBound(to: AudioBufferList.self).pointee.mNumberBuffers > 0
    }

    private static func isRunning(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var isRunning: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &isRunning) == noErr && isRunning != 0
    }
}
