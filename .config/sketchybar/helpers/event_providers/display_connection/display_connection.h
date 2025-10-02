#pragma once

#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stdbool.h>

typedef struct {
  CGDirectDisplayID display_id;
  bool connected;
  CGRect bounds;
  char name[256];
} display_info;

typedef struct {
  display_info *displays;
  uint32_t count;
  uint32_t capacity;
} display_list;

// Function declarations
void display_list_init(display_list *list);
void display_list_free(display_list *list);
void display_list_update(display_list *list);
bool display_list_has_changes(const display_list *old_list,
                              const display_list *new_list);
void display_reconfigure_callback(CGDirectDisplayID display,
                                  CGDisplayChangeSummaryFlags flags,
                                  void *user_info);
