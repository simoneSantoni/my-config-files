#!/usr/bin/env python3
"""Strip a leading blank line + mbox ">From -" separator from maildir files.

Some client copying mail into Gmail (Thunderbird-style, judging by the
"From - <date>" format) prepends a blank line and an escaped mbox separator
to the message. RFC 822 parsers then see the blank first line as the
header/body divider, i.e. a message with NO headers: mu indexes it with
date 1970-01-01 and no subject/sender, so it sorts to the bottom of every
mu4e view and looks "missing". Gmail's web UI is lenient and hides the
problem.

Run over ~/.maildir/gmail; also wired into offlineimaprc as postsynchook so
newly synced corrupted messages are repaired before mu ever indexes them.
Only the exact pattern is touched: file starts with one blank line, then a
">From " line, then something that looks like a real header. Idempotent.
"""
import re
import sys
from pathlib import Path

MAILDIR = Path.home() / ".maildir" / "gmail"
# one leading blank line (LF or CRLF), one ">From ..." line, then a header
PAT = re.compile(rb"\A\r?\n>From [^\n]*\n(?=[!-9;-~]+:)")

def main():
    fixed = skipped = 0
    for sub in ("new", "cur"):
        for f in MAILDIR.glob(f"*/{sub}/*"):
            if not f.is_file():
                continue
            with open(f, "rb") as fh:
                head = fh.read(4096)
            if not head.startswith((b"\n", b"\r\n")):
                continue
            if not PAT.search(head):
                skipped += 1
                print(f"SKIP (unexpected shape): {f}", file=sys.stderr)
                continue
            data = f.read_bytes()
            f.write_bytes(PAT.sub(b"", data, count=1))
            fixed += 1
    print(f"fixed {fixed} file(s), skipped {skipped} unexpected")

if __name__ == "__main__":
    main()
