#!/usr/bin/env python3
"""Hold an exclusive lock, then exec the remaining argv (fd stays open)."""
from __future__ import annotations

import fcntl
import os
import shutil
import sys
import time


def main() -> int:
    if len(sys.argv) < 4:
        sys.stderr.write("uso: with-lock.py LOCKFILE SECONDS command...\n")
        return 2
    lock_path = sys.argv[1]
    timeout = float(sys.argv[2])
    cmd = sys.argv[3:]
    exe = cmd[0]
    if not os.path.isabs(exe):
        found = shutil.which(exe)
        if not found:
            sys.stderr.write(f"✗ comando não encontrado: {exe}\n")
            return 1
        cmd = [found, *cmd[1:]]
    parent = os.path.dirname(os.path.abspath(lock_path))
    if parent:
        os.makedirs(parent, exist_ok=True)
    fd = os.open(lock_path, os.O_CREAT | os.O_RDWR, 0o644)
    deadline = None if timeout <= 0 else time.time() + timeout
    while True:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            break
        except BlockingIOError:
            if deadline is None or time.time() >= deadline:
                sys.stderr.write("✗ atualização já em andamento\n")
                return 1
            time.sleep(0.15)
    os.set_inheritable(fd, True)
    os.execv(cmd[0], cmd)


if __name__ == "__main__":
    raise SystemExit(main())
