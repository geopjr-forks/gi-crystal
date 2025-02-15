#pragma once

#include <glib-object.h>

G_BEGIN_DECLS

/**
 * TestFlagFlags:
 * @TEST_FLAG_OPTION1: Option1
 * @TEST_FLAG_OPTION2: Option2
 * @TEST_FLAG_ALL: Option1 | Option2
 *
 * Used to test flags.
 */
typedef enum {
  TEST_FLAG_OPTION1 = 1,
  TEST_FLAG_OPTION2 = 2,
  TEST_FLAG_ALL = 3
} TestFlagFlags;

GType test_flag_flags_get_type();

/**
 * TestEmptyFlags:
 * @TEST_EMPTY_NONE: None
 *
 * Used to test flags that have only the NONE entry.
 */
typedef enum {
  TEST_EMPTY_NONE = 0
} TestEmptyFlags;

GType test_empty_flags_get_type();

G_END_DECLS
