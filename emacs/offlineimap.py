"""Credential helpers for OfflineIMAP."""

from pathlib import Path


def gmail_app_password():
    """Return the Gmail App Password from its private local file."""
    return Path("~/.keys/emacs_stellaris16.txt").expanduser().read_text().strip()
