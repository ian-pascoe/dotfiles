#include "display_connection.h"
#include "../sketchybar.h"
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static volatile bool running = true;
static char event_name[256] = "display_change";
static display_list current_displays;

void signal_handler(int sig) { running = false; }

void display_reconfigure_callback(CGDirectDisplayID display,
                                  CGDisplayChangeSummaryFlags flags,
                                  void *user_info) {
  display_list new_displays;
  display_list_init(&new_displays);
  display_list_update(&new_displays);

  bool should_trigger = false;
  char command[512];

  if (flags & kCGDisplayAddFlag) {
    should_trigger = true;
    snprintf(command, sizeof(command),
             "--trigger '%s' action=connected display_id=%u count=%u",
             event_name, display, new_displays.count);
  } else if (flags & kCGDisplayRemoveFlag) {
    should_trigger = true;
    snprintf(command, sizeof(command),
             "--trigger '%s' action=disconnected display_id=%u count=%u",
             event_name, display, new_displays.count);
  } else if (display_list_has_changes(&current_displays, &new_displays)) {
    should_trigger = true;
    snprintf(command, sizeof(command),
             "--trigger '%s' action=changed display_id=%u count=%u", event_name,
             display, new_displays.count);
  }

  if (should_trigger) {
    sketchybar(command);
    display_list_free(&current_displays);
    current_displays = new_displays;
  } else {
    display_list_free(&new_displays);
  }
}

int main(int argc, char **argv) {
  if (argc < 2) {
    printf("Usage: %s \"<event-name>\"\n", argv[0]);
    exit(1);
  }

  // Store the event name
  strncpy(event_name, argv[1], sizeof(event_name) - 1);
  event_name[sizeof(event_name) - 1] = '\0';

  // Setup signal handlers
  signal(SIGINT, signal_handler);
  signal(SIGTERM, signal_handler);

  // Initialize display list
  display_list_init(&current_displays);
  display_list_update(&current_displays);

  // Setup the event in sketchybar
  char event_message[512];
  snprintf(event_message, 512, "--add event '%s'", event_name);
  sketchybar(event_message);

  // Send initial state
  char initial_command[512];
  snprintf(initial_command, sizeof(initial_command),
           "--trigger '%s' action=initial count=%u", event_name,
           current_displays.count);
  sketchybar(initial_command);

  // Register for display configuration changes
  CGDisplayRegisterReconfigurationCallback(display_reconfigure_callback, NULL);

  // Keep running until signal received
  while (running) {
    usleep(100000); // Sleep for 100ms
  }

  // Cleanup
  CGDisplayRemoveReconfigurationCallback(display_reconfigure_callback, NULL);
  display_list_free(&current_displays);

  return 0;
}

void display_list_init(display_list *list) {
  list->displays = NULL;
  list->count = 0;
  list->capacity = 0;
}

void display_list_free(display_list *list) {
  if (list->displays) {
    free(list->displays);
    list->displays = NULL;
  }
  list->count = 0;
  list->capacity = 0;
}

void display_list_update(display_list *list) {
  // Get the number of active displays
  uint32_t display_count;
  CGGetActiveDisplayList(0, NULL, &display_count);

  // Ensure we have enough capacity
  if (display_count > list->capacity) {
    list->displays =
        realloc(list->displays, display_count * sizeof(display_info));
    list->capacity = display_count;
  }

  // Get the display IDs
  CGDirectDisplayID *display_ids =
      malloc(display_count * sizeof(CGDirectDisplayID));
  CGGetActiveDisplayList(display_count, display_ids, &display_count);

  // Update display information
  list->count = display_count;
  for (uint32_t i = 0; i < display_count; i++) {
    list->displays[i].display_id = display_ids[i];
    list->displays[i].connected = true;
    list->displays[i].bounds = CGDisplayBounds(display_ids[i]);

    // Get display name (simplified)
    snprintf(list->displays[i].name, sizeof(list->displays[i].name),
             "Display_%u", display_ids[i]);
  }

  free(display_ids);
}

bool display_list_has_changes(const display_list *old_list,
                              const display_list *new_list) {
  if (old_list->count != new_list->count) {
    return true;
  }

  // Check if any display IDs have changed
  for (uint32_t i = 0; i < old_list->count; i++) {
    bool found = false;
    for (uint32_t j = 0; j < new_list->count; j++) {
      if (old_list->displays[i].display_id ==
          new_list->displays[j].display_id) {
        found = true;
        break;
      }
    }
    if (!found) {
      return true;
    }
  }

  return false;
}
