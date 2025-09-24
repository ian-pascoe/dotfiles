#include "input_volume.h"
#include "../sketchybar.h"
#include <stdio.h>
#include <unistd.h>
#include <signal.h>

static volatile bool running = true;

void signal_handler(int sig) {
    running = false;
}

OSStatus volume_listener(AudioObjectID object_id,
                        UInt32 num_addresses,
                        const AudioObjectPropertyAddress addresses[],
                        void* client_data) {
    
    input_volume_info info = get_input_volume_info();
    
    // Format volume as percentage
    int volume_percent = (int)(info.volume * 100);
    
    // Create sketchybar command
    char command[256];
    if (info.muted) {
        snprintf(command, sizeof(command), 
                "--trigger input_volume_change volume=0 muted=true");
    } else {
        snprintf(command, sizeof(command), 
                "--trigger input_volume_change volume=%d muted=false", 
                volume_percent);
    }
    
    sketchybar(command);
    return noErr;
}

int main() {
    // Setup signal handlers
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    AudioDeviceID input_device = get_default_input_device();
    if (input_device == kAudioObjectUnknown) {
        fprintf(stderr, "No default input device found\n");
        return 1;
    }
    
    // Setup listener for volume changes
    OSStatus status = setup_input_volume_listener(input_device, volume_listener, NULL);
    if (status != noErr) {
        fprintf(stderr, "Failed to setup volume listener: %d\n", (int)status);
        return 1;
    }
    
    // Send initial state
    input_volume_info info = get_input_volume_info();
    int volume_percent = (int)(info.volume * 100);
    char command[256];
    if (info.muted) {
        snprintf(command, sizeof(command), 
                "--trigger input_volume_change volume=0 muted=true");
    } else {
        snprintf(command, sizeof(command), 
                "--trigger input_volume_change volume=%d muted=false", 
                volume_percent);
    }
    sketchybar(command);
    
    // Keep running until signal received
    while (running) {
        usleep(100000); // Sleep for 100ms
    }
    
    // Cleanup
    remove_input_volume_listener(input_device, volume_listener, NULL);
    
    return 0;
}

AudioDeviceID get_default_input_device(void) {
    AudioDeviceID device_id = kAudioObjectUnknown;
    UInt32 size = sizeof(device_id);
    
    AudioObjectPropertyAddress property_address = {
        kAudioHardwarePropertyDefaultInputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };
    
    OSStatus status = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                               &property_address,
                                               0, NULL,
                                               &size, &device_id);
    
    if (status != noErr) {
        return kAudioObjectUnknown;
    }
    
    return device_id;
}

Float32 get_input_volume(AudioDeviceID device_id) {
    Float32 volume = 0.0;
    UInt32 size = sizeof(volume);
    
    AudioObjectPropertyAddress property_address = {
        kAudioDevicePropertyVolumeScalar,
        kAudioDevicePropertyScopeInput,
        kAudioObjectPropertyElementMain
    };
    
    OSStatus status = AudioObjectGetPropertyData(device_id,
                                               &property_address,
                                               0, NULL,
                                               &size, &volume);
    
    if (status != noErr) {
        return 0.0;
    }
    
    return volume;
}

bool is_input_muted(AudioDeviceID device_id) {
    UInt32 muted = 0;
    UInt32 size = sizeof(muted);
    
    AudioObjectPropertyAddress property_address = {
        kAudioDevicePropertyMute,
        kAudioDevicePropertyScopeInput,
        kAudioObjectPropertyElementMain
    };
    
    OSStatus status = AudioObjectGetPropertyData(device_id,
                                               &property_address,
                                               0, NULL,
                                               &size, &muted);
    
    if (status != noErr) {
        return false;
    }
    
    return muted != 0;
}

OSStatus setup_input_volume_listener(AudioDeviceID device_id, AudioObjectPropertyListenerProc listener, void* client_data) {
    AudioObjectPropertyAddress volume_address = {
        kAudioDevicePropertyVolumeScalar,
        kAudioDevicePropertyScopeInput,
        kAudioObjectPropertyElementMain
    };
    
    AudioObjectPropertyAddress mute_address = {
        kAudioDevicePropertyMute,
        kAudioDevicePropertyScopeInput,
        kAudioObjectPropertyElementMain
    };
    
    OSStatus status1 = AudioObjectAddPropertyListener(device_id, &volume_address, listener, client_data);
    OSStatus status2 = AudioObjectAddPropertyListener(device_id, &mute_address, listener, client_data);
    
    if (status1 != noErr) return status1;
    if (status2 != noErr) return status2;
    
    return noErr;
}

OSStatus remove_input_volume_listener(AudioDeviceID device_id, AudioObjectPropertyListenerProc listener, void* client_data) {
    AudioObjectPropertyAddress volume_address = {
        kAudioDevicePropertyVolumeScalar,
        kAudioDevicePropertyScopeInput,
        kAudioObjectPropertyElementMain
    };
    
    AudioObjectPropertyAddress mute_address = {
        kAudioDevicePropertyMute,
        kAudioDevicePropertyScopeInput,
        kAudioObjectPropertyElementMain
    };
    
    AudioObjectRemovePropertyListener(device_id, &volume_address, listener, client_data);
    AudioObjectRemovePropertyListener(device_id, &mute_address, listener, client_data);
    
    return noErr;
}

input_volume_info get_input_volume_info(void) {
    input_volume_info info = {0};
    
    info.device_id = get_default_input_device();
    if (info.device_id != kAudioObjectUnknown) {
        info.volume = get_input_volume(info.device_id);
        info.muted = is_input_muted(info.device_id);
    }
    
    return info;
}