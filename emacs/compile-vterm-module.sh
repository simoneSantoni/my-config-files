#!/usr/bin/env bash
#
# Compile the emacs-libvterm native module ahead of time.
#
# GUI Emacs prompts "Vterm needs `vterm-module' to work. Compile it now?" the
# first time `(require 'vterm)` runs, because the package ships only the Elisp
# and CMake sources -- the .so has to be built locally against libvterm. Running
# this script once after the package is installed builds the module so the
# prompt never appears (and batch/daemon startups don't hang on it).
#
# Requirements: cmake, libtool, make, a C compiler, and libvterm dev headers.

set -euo pipefail

# Build tool sanity check up front, so failures are legible instead of a CMake
# error 200 lines deep.
missing=()
for tool in emacs cmake make libtool cc; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "error: missing required build tools: ${missing[*]}" >&2
    echo "install them (e.g. on Debian/Ubuntu: sudo apt install cmake libtool-bin build-essential libvterm-dev)" >&2
    exit 1
fi

# Find the installed vterm package directory (newest, if several are present).
vterm_dir="$(emacs --batch --eval \
    "(progn (require 'package) (package-initialize) \
       (let ((d (and (package-installed-p 'vterm) \
                     (package-desc-dir (cadr (assq 'vterm package-alist)))))) \
         (when d (princ d))))" 2>/dev/null)"

if [ -z "${vterm_dir}" ] || [ ! -d "${vterm_dir}" ]; then
    echo "error: vterm package not found. Start Emacs once to let init.el install it, then re-run this script." >&2
    exit 1
fi

echo "Found vterm at: ${vterm_dir}"

if [ -f "${vterm_dir}/vterm-module.so" ]; then
    echo "vterm-module.so already built -- nothing to do."
    exit 0
fi

# Let vterm drive its own build: `vterm-module-compile' runs the bundled
# CMake/make recipe and downloads a pinned libvterm if the system one is too
# old, so this stays correct across vterm versions. Setting
# `vterm-always-compile-module' before loading vterm makes it build the module
# itself, non-interactively, instead of asking "Compile it now?".
echo "Compiling vterm-module..."
emacs --batch \
    --eval "(progn (require 'package) (package-initialize) (setq vterm-always-compile-module t) (require 'vterm))"

if [ -f "${vterm_dir}/vterm-module.so" ]; then
    echo "Success: ${vterm_dir}/vterm-module.so"
else
    echo "error: compilation finished but vterm-module.so is missing." >&2
    exit 1
fi
