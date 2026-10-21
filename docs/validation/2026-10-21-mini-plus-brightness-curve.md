# mini PLUS brightness curve calibration

Date: 2026-10-21  
Scope: physical backlight response and plumOS twenty-level brightness control

## Observed behavior

The `SELECT` plus volume hotkey was observed in the live input-service log and
successfully changed the kernel backlight value. A full-range probe from raw
255 to raw 1 and back to the saved value produced a visible change on the
physical panel.

User acceptance then identified that the Bubble-derived curve showed almost no
visible change through logical level 12 (raw 52), followed by a sudden increase
at level 13 (raw 68). This is target-specific panel behavior and is not an input
or PWM-routing failure.

## Candidate correction

Keep the shared plumOS range and settings contract at 1..20, but map it onto the
mini PLUS panel's measured transition and useful PWM region. Raw 52 remains the
dim floor so deploying the new curve can preserve the currently selected
physical brightness:

```text
level:  1  2  3  4  5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20
raw:   52 63 73 84 95 105 116 127 137 148 159 169 180 191 201 212 223 233 244 255
```

The curve is identified as `mini-plus-panel-linear-52-255-v1` in runtime and
component metadata. Host tests verify representative low, middle, knee and
maximum mappings without changing the saved setting during an explicit apply.

## Remaining physical gate

The candidate is not accepted until the user confirms that all twenty steps are
monotonic, that the minimum is sufficiently dim, and that no abrupt jump remains.
