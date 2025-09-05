#!/usr/bin/env python3
import sys
import subprocess

jobid = sys.argv[1]

try:
    output = subprocess.check_output(
        ["sacct", "-j", jobid, "--format=State", "--noheader"],
        text=True,
        stderr=subprocess.DEVNULL
    ).strip()

    state = output.split()[0]
except Exception:
    print("unknown")
    sys.exit(0)

if state in {"PENDING", "CONFIGURING", "RUNNING", "COMPLETING"}:
    print("running")
elif state == "COMPLETED":
    print("success")
elif state in {"FAILED", "CANCELLED", "TIMEOUT", "PREEMPTED"}:
    print("failed")
else:
    print("unknown")
