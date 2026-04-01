#!/usr/bin/env python3
"""Software reference for the tiny NPU v2 classifier."""

from __future__ import annotations

import argparse


def unpack_i8x4(word: int) -> list[int]:
    values = []
    for shift in (0, 8, 16, 24):
        byte = (word >> shift) & 0xFF
        if byte & 0x80:
            byte -= 0x100
        values.append(byte)
    return values


def pack_i8x4(values: list[int]) -> int:
    if len(values) != 4:
        raise ValueError("need exactly 4 int8 values")

    word = 0
    for shift, value in zip((0, 8, 16, 24), values):
        word |= (value & 0xFF) << shift
    return word


def model_weights(model_id: int) -> tuple[list[int], list[int], list[int], list[int], int, int]:
    if model_id == 2:
        return (
            [-1, -1, -1, -1],
            [1, 1, 1, 1],
            [1, 1, 1, 1],
            [-1, -1, -1, -1],
            2,
            -2,
        )

    return (
        [1, 1, 1, 1],
        [-1, -1, -1, -1],
        [-1, -1, -1, -1],
        [1, 1, 1, 1],
        0,
        0,
    )


def runtime_demo_weights() -> tuple[list[int], list[int], list[int], list[int], int, int]:
    return (
        [2, 0, 2, 0],
        [2, 0, 2, 0],
        [0, 2, 0, 2],
        [0, 2, 0, 2],
        0,
        0,
    )


def runtime_mlp_demo_weights() -> tuple[list[int], list[int], list[int], list[int], int, int]:
    return (
        [2, 0, 2, 0],
        [2, 0, 2, 0],
        [0, 2, 0, 2],
        [0, 2, 0, 2],
        -8,
        -8,
    )


def dot(lhs: list[int], rhs: list[int]) -> int:
    return sum(a * b for a, b in zip(lhs, rhs))


def run_reference(
    model_id: int,
    seq_length: int,
    input0: int,
    input1: int,
    custom_weights: tuple[list[int], list[int], list[int], list[int], int, int] | None = None,
) -> dict[str, int]:
    vec0 = unpack_i8x4(input0)
    vec1 = unpack_i8x4(input1)
    if custom_weights is None:
        w0a, w0b, w1a, w1b, bias0, bias1 = model_weights(model_id)
    else:
        w0a, w0b, w1a, w1b, bias0, bias1 = custom_weights
    linear0 = dot(vec0, w0a) + dot(vec1, w0b) + bias0
    linear1 = dot(vec0, w1a) + dot(vec1, w1b) + bias1
    if model_id == 0x81:
        hidden0 = max(0, linear0)
        hidden1 = max(0, linear1)
        logit0 = hidden0 - hidden1
        logit1 = hidden1 - hidden0
    else:
        hidden0 = linear0
        hidden1 = linear1
        logit0 = linear0
        logit1 = linear1
    class_id = 1 if logit1 > logit0 else 0
    status_word = (0x4E << 24) | (class_id << 16) | ((model_id & 0xFF) << 8) | (seq_length & 0xFF)
    return {
        "hidden0": hidden0,
        "hidden1": hidden1,
        "logit0": logit0,
        "logit1": logit1,
        "class_id": class_id,
        "status_word": status_word,
    }


def parse_word(value: str) -> int:
    return int(value, 0) & 0xFFFFFFFF


def parse_vec4(value: str) -> list[int]:
    parts = [int(part, 0) for part in value.split(",")]
    if len(parts) != 4:
        raise argparse.ArgumentTypeError("need four comma-separated int8 values")
    for part in parts:
        if part < -128 or part > 127:
            raise argparse.ArgumentTypeError("each value must fit signed int8")
    return parts


def main() -> int:
    parser = argparse.ArgumentParser(description="Reference model for zybo_z7_10 NPU v2 tiny classifier")
    parser.add_argument("--model", type=int, default=1, help="model id")
    parser.add_argument("--seq-length", type=int, default=8, help="sequence length field")
    parser.add_argument("--input0", type=parse_word, default=parse_word("0x04030201"), help="packed int8x4 word 0")
    parser.add_argument("--input1", type=parse_word, default=parse_word("0x00000000"), help="packed int8x4 word 1")
    parser.add_argument("--runtime-demo", action="store_true", help="use the built-in runtime-MMIO demo weights")
    parser.add_argument("--runtime-mlp-demo", action="store_true", help="use the built-in runtime MLP demo weights")
    parser.add_argument("--w0a", type=parse_vec4, help="custom class0 weights for input0, comma-separated")
    parser.add_argument("--w0b", type=parse_vec4, help="custom class0 weights for input1, comma-separated")
    parser.add_argument("--w1a", type=parse_vec4, help="custom class1 weights for input0, comma-separated")
    parser.add_argument("--w1b", type=parse_vec4, help="custom class1 weights for input1, comma-separated")
    parser.add_argument("--bias0", type=int, default=0, help="custom class0 bias")
    parser.add_argument("--bias1", type=int, default=0, help="custom class1 bias")
    parser.add_argument("--emit-mmio", action="store_true", help="print packed MMIO payload words for runtime model")
    args = parser.parse_args()

    custom_weights = None
    if args.runtime_demo:
        custom_weights = runtime_demo_weights()
        args.model = 0x80
    elif args.runtime_mlp_demo:
        custom_weights = runtime_mlp_demo_weights()
        args.model = 0x81
    elif any(value is not None for value in (args.w0a, args.w0b, args.w1a, args.w1b)):
        if None in (args.w0a, args.w0b, args.w1a, args.w1b):
            parser.error("custom mode needs --w0a --w0b --w1a --w1b together")
        custom_weights = (args.w0a, args.w0b, args.w1a, args.w1b, args.bias0, args.bias1)
        args.model = 0x80

    result = run_reference(args.model, args.seq_length, args.input0, args.input1, custom_weights)
    print(f"model_id    = {args.model}")
    print(f"seq_length  = {args.seq_length}")
    print(f"input0      = 0x{args.input0:08X} -> {unpack_i8x4(args.input0)}")
    print(f"input1      = 0x{args.input1:08X} -> {unpack_i8x4(args.input1)}")
    print(f"hidden0     = {result['hidden0']}")
    print(f"hidden1     = {result['hidden1']}")
    print(f"logit0      = {result['logit0']}")
    print(f"logit1      = {result['logit1']}")
    print(f"class_id    = {result['class_id']}")
    print(f"status_word = 0x{result['status_word']:08X}")
    if custom_weights is not None:
        w0a, w0b, w1a, w1b, bias0, bias1 = custom_weights
        print(f"runtime_w0a = 0x{pack_i8x4(w0a):08X} -> {w0a}")
        print(f"runtime_w0b = 0x{pack_i8x4(w0b):08X} -> {w0b}")
        print(f"runtime_w1a = 0x{pack_i8x4(w1a):08X} -> {w1a}")
        print(f"runtime_w1b = 0x{pack_i8x4(w1b):08X} -> {w1b}")
        print(f"runtime_b0  = {bias0}")
        print(f"runtime_b1  = {bias1}")
        if args.emit_mmio:
            print("mmio_writes:")
            print(f"  REG_NPU_WEIGHT0_A = 0x{pack_i8x4(w0a):08X}")
            print(f"  REG_NPU_WEIGHT0_B = 0x{pack_i8x4(w0b):08X}")
            print(f"  REG_NPU_WEIGHT1_A = 0x{pack_i8x4(w1a):08X}")
            print(f"  REG_NPU_WEIGHT1_B = 0x{pack_i8x4(w1b):08X}")
            print(f"  REG_NPU_BIAS0     = 0x{bias0 & 0xFFFFFFFF:08X}")
            print(f"  REG_NPU_BIAS1     = 0x{bias1 & 0xFFFFFFFF:08X}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
