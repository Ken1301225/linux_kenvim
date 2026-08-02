# Todo Form Empty Notes Line Fix

## Problem

The todo form stores six field values as real buffer lines. It appends note
lines only when a task already has non-empty notes, while `notes:` itself is
drawn as a virtual line after the sixth field. A new task therefore has no
seventh buffer line: the label is visible, but Neovim rejects attempts to move
the cursor onto it as out of range.

## Decision

Keep the value-only buffer and the existing `notes:` virtual label. When a task
has no notes, append one empty real line after the six fields. Existing notes
continue to be split into real lines starting at line seven.

The existing parser already reads notes from line seven onward and removes
trailing empty lines. Saving an untouched empty notes line therefore still
produces `notes = ""`, while text entered on that line is saved normally.

## Verification

Extend the form regression test to verify that a task with empty notes:

- has an empty seventh buffer line;
- allows the window cursor to move to that line;
- saves text entered on that line as notes;
- still saves an untouched line as empty notes.

Run the focused form test first, then the complete todo test suite.

## Non-Goals

This fix does not change labels, layout, parsing rules, key mappings,
validation, or the Markdown storage format.
