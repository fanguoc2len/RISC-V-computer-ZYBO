#!/usr/bin/env python3
"""Pack an 8-feature runtime model into MMIO words for NPU v2."""

from __future__ import annotations

import argparse


def parse_vec8(value: str) -> list[int]:
    parts = [int(part, 0) for part in value.split(",")]
    if len(parts) != 8:
        raise argparse.ArgumentTypeError("need eight comma-separated int8 values")
    for part in parts:
        if part < -128 or part > 127:
            raise argparse.ArgumentTypeError("each weight must fit signed int8")
    return parts


def pack_i8x4(values: list[int]) -> int:
    word = 0
    for shift, value in zip((0, 8, 16, 24), values):
        word |= (value & 0xFF) << shift
    return word


def main() -> int:
    parser = argparse.ArgumentParser(description="Pack a runtime NPU v2 model into MMIO register words")
    parser.add_argument("--class0", type=parse_vec8, required=True, help="eight int8 weights for class0")
    parser.add_argument("--class1", type=parse_vec8, required=True, help="eight int8 weights for class1")
    parser.add_argument("--bias0", type=int, default=0, help="signed bias for class0")
    parser.add_argument("--bias1", type=int, default=0, help="signed bias for class1")
    parser.add_argument("--model", choices=("linear", "mlp"), default="linear",
                        help="runtime model interpretation: linear -> 0x80, mlp -> 0x81")
    parser.add_argument("--base", type=lambda value: int(value, 0), default=0x43C00000, help="MMIO base address")
    args = parser.parse_args()

    class0_a = args.class0[:4]
    class0_b = args.class0[4:]
    class1_a = args.class1[:4]
    class1_b = args.class1[4:]

    reg_words = {
        "REG_NPU_WEIGHT0_A": pack_i8x4(class0_a),
        "REG_NPU_WEIGHT0_B": pack_i8x4(class0_b),
        "REG_NPU_WEIGHT1_A": pack_i8x4(class1_a),
        "REG_NPU_WEIGHT1_B": pack_i8x4(class1_b),
        "REG_NPU_BIAS0": args.bias0 & 0xFFFFFFFF,
        "REG_NPU_BIAS1": args.bias1 & 0xFFFFFFFF,
    }
    reg_offsets = {
        "REG_NPU_WEIGHT0_A": 0x68,
        "REG_NPU_WEIGHT0_B": 0x6C,
        "REG_NPU_WEIGHT1_A": 0x70,
        "REG_NPU_WEIGHT1_B": 0x74,
        "REG_NPU_BIAS0": 0x78,
        "REG_NPU_BIAS1": 0x7C,
    }

    print("packed_words:")
    print(f"  REG_NPU_CFG0      = 0x{(0x81 if args.model == 'mlp' else 0x80):08X}")
    for name, word in reg_words.items():
        print(f"  {name:16s} = 0x{word:08X}")

    print("\ndevmem_writes:")
    print(f"  devmem 0x{args.base + 0x0C:08X} 32 0x{(0x81 if args.model == 'mlp' else 0x80):08X}")
    for name, offset in reg_offsets.items():
        print(f"  devmem 0x{args.base + offset:08X} 32 0x{reg_words[name]:08X}")

    print("\nc_snippet:")
    print(f"  reg_write(base, 0x0C, 0x{(0x81 if args.model == 'mlp' else 0x80):08X}u);")
    print(f"  reg_write(base, 0x68, 0x{reg_words['REG_NPU_WEIGHT0_A']:08X}u);")
    print(f"  reg_write(base, 0x6C, 0x{reg_words['REG_NPU_WEIGHT0_B']:08X}u);")
    print(f"  reg_write(base, 0x70, 0x{reg_words['REG_NPU_WEIGHT1_A']:08X}u);")
    print(f"  reg_write(base, 0x74, 0x{reg_words['REG_NPU_WEIGHT1_B']:08X}u);")
    print(f"  reg_write(base, 0x78, 0x{reg_words['REG_NPU_BIAS0']:08X}u);")
    print(f"  reg_write(base, 0x7C, 0x{reg_words['REG_NPU_BIAS1']:08X}u);")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
