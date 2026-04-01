#!/usr/bin/env python3
"""Reference model for the tiny GPU triangle raster path."""

from __future__ import annotations

import argparse


FB_SIZE = 32


def edge(ax: int, ay: int, bx: int, by: int, px: int, py: int) -> int:
    return (bx - ax) * (py - ay) - (by - ay) * (px - ax)


def rasterize(v0: tuple[int, int], v1: tuple[int, int], v2: tuple[int, int]) -> tuple[int, int, int, int, int, list[int]]:
    xs = [v0[0], v1[0], v2[0]]
    ys = [v0[1], v1[1], v2[1]]
    min_x = max(0, min(xs))
    max_x = min(FB_SIZE - 1, max(xs))
    min_y = max(0, min(ys))
    max_y = min(FB_SIZE - 1, max(ys))
    area2 = edge(v0[0], v0[1], v1[0], v1[1], v2[0], v2[1])

    rows = [0] * FB_SIZE
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            e0 = edge(v0[0], v0[1], v1[0], v1[1], x, y)
            e1 = edge(v1[0], v1[1], v2[0], v2[1], x, y)
            e2 = edge(v2[0], v2[1], v0[0], v0[1], x, y)
            inside = False
            if area2 > 0:
                inside = e0 >= 0 and e1 >= 0 and e2 >= 0
            elif area2 < 0:
                inside = e0 <= 0 and e1 <= 0 and e2 <= 0
            if inside:
                rows[y] |= 1 << x

    return min_x, min_y, max_x, max_y, area2, rows


def main() -> int:
    parser = argparse.ArgumentParser(description="Reference model for the tiny GPU rasterizer")
    parser.add_argument("--x0", type=int, default=2)
    parser.add_argument("--y0", type=int, default=2)
    parser.add_argument("--x1", type=int, default=10)
    parser.add_argument("--y1", type=int, default=2)
    parser.add_argument("--x2", type=int, default=2)
    parser.add_argument("--y2", type=int, default=10)
    args = parser.parse_args()

    min_x, min_y, max_x, max_y, area2, rows = rasterize(
        (args.x0, args.y0),
        (args.x1, args.y1),
        (args.x2, args.y2),
    )
    pixel_count = sum(bin(row).count("1") for row in rows)
    bbox = (max_y << 24) | (max_x << 16) | (min_y << 8) | min_x

    print(f"triangle       = ({args.x0},{args.y0}) ({args.x1},{args.y1}) ({args.x2},{args.y2})")
    print(f"area2          = {area2} (0x{area2 & 0xFFFFFFFF:08X})")
    print(f"bbox           = min=({min_x},{min_y}) max=({max_x},{max_y}) packed=0x{bbox:08X}")
    print(f"pixel_count    = {pixel_count}")
    for y, row in enumerate(rows):
        if row:
            print(f"row[{y:02d}]       = 0x{row:08X}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
