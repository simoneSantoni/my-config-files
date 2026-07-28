#!/usr/bin/env bash

set -Eeuo pipefail

readonly TUXEDO_REPO_URL="https://rpm.tuxedocomputers.com/fedora/tuxedo.repo"

log() {
  printf '\n==> %s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

if (( EUID != 0 )); then
  die "run this script as root: sudo $0"
fi

[[ -r /etc/os-release ]] || die "cannot identify the operating system"
# shellcheck disable=SC1091
source /etc/os-release
[[ ${ID:-} == "fedora" ]] || die "this script supports Fedora only (found ${ID:-unknown})"

vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)
model=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
[[ $vendor == "TUXEDO" ]] || die "this does not appear to be TUXEDO hardware (vendor: ${vendor:-unknown})"

printf 'Detected: %s, Fedora %s, kernel %s\n' \
  "${model:-TUXEDO computer}" "${VERSION_ID:-unknown}" "$(uname -r)"

log "Updating Fedora"
dnf upgrade --refresh

log "Installing matched kernel development files and DKMS"
dnf install kernel-devel-matched dkms

latest_kernel=$(
  rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' \
    | sort -V \
    | tail -n 1
)
[[ -n $latest_kernel ]] || die "could not identify the newest installed kernel"
[[ -d /usr/src/kernels/$latest_kernel ]] || \
  die "development files are missing for kernel $latest_kernel"

if dnf repolist --all 2>/dev/null | grep -qE '^tuxedo([[:space:]]|$)'; then
  log "TUXEDO repository is already configured"
else
  log "Adding the official TUXEDO repository"
  dnf config-manager addrepo --from-repofile="$TUXEDO_REPO_URL"
fi

log "Installing the TUXEDO software suite"
dnf install tuxedo-suite

# tuxedo-suite installs tuxedo-repository, which owns the permanent repository
# definition. Remove the unowned bootstrap definition to avoid a duplicate repo ID.
if [[ -f /etc/yum.repos.d/tuxedo.repo ]] && \
   ! rpm -qf /etc/yum.repos.d/tuxedo.repo >/dev/null 2>&1; then
  rm -f /etc/yum.repos.d/tuxedo.repo
fi

log "Building TUXEDO DKMS modules for kernel $latest_kernel"
dkms autoinstall -k "$latest_kernel"

log "Checking package dependencies"
dnf check

for package in \
  tuxedo-repository \
  tuxedo-suite \
  tuxedo-drivers \
  tuxedo-control-center \
  tuxedo-tomte; do
  rpm -q "$package" >/dev/null || die "required package is missing: $package"
done

dkms_status=$(dkms status -k "$latest_kernel")
grep -qE '^tuxedo-drivers/.+: installed' <<<"$dkms_status" || \
  die "tuxedo-drivers was not installed for kernel $latest_kernel"

log "Installed TUXEDO packages"
rpm -qa --qf '%{NAME} %{VERSION}-%{RELEASE}\n' \
  | grep -E '^(tuxedo|tomte)' \
  | sort || true

printf '\nDKMS modules for %s:\n%s\n' "$latest_kernel" "$dkms_status"

cat <<'EOF'

Setup finished. Reboot into the updated kernel to load the new drivers:

  sudo reboot

After reboot, useful checks are:

  lsmod | grep -E 'tuxedo|uniwill|clevo'
  systemctl --failed
EOF
