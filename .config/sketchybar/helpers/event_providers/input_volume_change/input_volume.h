#pragma once

#include <AudioToolbox/AudioToolbox.h>
#include <CoreAudio/CoreAudio.h>
#include <stdbool.h>

typedef struct {
    AudioDeviceID device_id;
    Float32 volume;
    bool muted;
} input_volume_info;

// Get the default input device
AudioDeviceID get_default_input_device(void);

// Get current input volume (0.0 - 1.0)
Float32 get_input_volume(AudioDeviceID device_id);

// Check if input is muted
bool is_input_muted(AudioDeviceID device_id);

// Setup volume change listener
OSStatus setup_input_volume_listener(AudioDeviceID device_id, AudioObjectPropertyListenerProc listener, void* client_data);

// Remove volume change listener
OSStatus remove_input_volume_listener(AudioDeviceID device_id, AudioObjectPropertyListenerProc listener, void* client_data);

// Get input volume info
input_volume_info get_input_volume_info(void);