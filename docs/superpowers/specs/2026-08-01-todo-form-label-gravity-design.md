# Todo Form Label Gravity Fix

## Problem

The todo form renders field labels as inline virtual text anchored by extmarks at
column zero. Extmarks use right gravity by default, so inserting at column zero
moves the label after the newly inserted text. This lets a new task title appear
visually before `title:`.

## Decision

Keep the existing value-only buffer and inline virtual labels. Set
`right_gravity = false` on the six field-label extmarks so each label remains at
column zero when text is inserted at its anchor. The `notes:` virtual line is not
affected because it is not an inline field label.

No cursor guards or input mappings are needed. Neovim's extmark gravity provides
the intended boundary for typing, pasting, and programmatic text insertion.

## Verification

Add a regression assertion to the form test that inserts text at column zero and
checks both outcomes:

- the title-label extmark remains at column zero;
- the buffer contains the inserted title value unchanged.

Run the focused form test first, then the complete todo test suite.

## Non-Goals

This fix does not change form layout, parsing, key mappings, validation, or the
storage format.
