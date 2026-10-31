#!/usr/bin/env python3
"""Remove only the stock state_store charging veto from the measured Image.

The vendor function calls avrman_rk817_bat_get_charge_state(), then returns
-EBUSY for POWER_SUPPLY_STATUS_CHARGING or FULL. Replace that conditional
branch with NOP, retaining all normal suspend and charger safety callbacks.
Never modify the vendor input or accept a different kernel revision.
"""

import argparse
import hashlib
import json
from pathlib import Path


STOCK_SHA256 = "670c32a86cf006a574d5ec498df6c14e3ac61af6ed6b109f458b5711c228da56"
OFFSET = 0x8BD40
# BL avrman_rk817_bat_get_charge_state; CBNZ w0, return_ebusy.
CONTEXT_OFFSET = 0x8BD3C
CONTEXT = bytes.fromhex("b94b1c94c0030035")
NOP = bytes.fromhex("1f2003d5")


def patched_image(original):
    if hashlib.sha256(original).hexdigest() != STOCK_SHA256:
        raise ValueError("refusing unrecognized kernel SHA-256")
    if original[CONTEXT_OFFSET:CONTEXT_OFFSET + len(CONTEXT)] != CONTEXT:
        raise ValueError("refusing unexpected state_store instructions")
    result = bytearray(original)
    result[OFFSET:OFFSET + 4] = NOP
    changed = [i for i, (a, b) in enumerate(zip(original, result)) if a != b]
    if changed != list(range(OFFSET, OFFSET + 4)):
        raise ValueError("patch changed bytes outside the single instruction")
    return bytes(result)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve():
        parser.error("output must differ from the vendor input")
    original = args.input.read_bytes()
    result = patched_image(original)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    # Exclusive creation protects existing artifacts and rollback copies.
    with args.output.open("xb") as stream:
        stream.write(result)
    print(json.dumps({
        "input_sha256": STOCK_SHA256,
        "output_sha256": hashlib.sha256(result).hexdigest(),
        "bytes": len(result),
        "instruction_offset": hex(OFFSET),
        "before": original[OFFSET:OFFSET + 4].hex(),
        "after": NOP.hex(),
        "policy": "allow-standard-suspend-while-usb-charging",
    }, indent=2))


if __name__ == "__main__":
    main()
