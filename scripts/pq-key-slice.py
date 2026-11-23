#!/usr/bin/env python3
import os
import sys


def main():
    source, record_size, start, end, destination = sys.argv[1:6]
    record_size, start, end = int(record_size), int(start), int(end)
    if not 0 <= start < end:
        raise SystemExit(f"invalid validator range {start}..{end}")
    if os.path.getsize(source) < end * record_size:
        raise SystemExit(f"{source} holds fewer than {end} records of {record_size} bytes")
    with open(source, "rb") as src:
        src.seek(start * record_size)
        records = src.read((end - start) * record_size)
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    temporary = destination + ".tmp"
    with open(temporary, "wb") as dst:
        dst.seek(start * record_size)
        dst.write(records)
    os.chmod(temporary, 0o644)
    os.replace(temporary, destination)


if __name__ == "__main__":
    main()
