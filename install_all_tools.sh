#!/usr/bin/env bash
# ======================================================
#  made by nothingnhm
#  One‑Click Installer Script for Kali Linux
#  Installs all major Bug Bounty Recon Tools
#  Tools Included:
#  subfinder, amass, assetfinder, findomain, dnsx, httpx,
#  ffuf, naabu, masscan, gowitness, nuclei, waybackurls,
#  gau, gf
#  made by nothingnhm
# Run as root: sudo ./install_all_tools.sh
# ======================================================

set -euo pipefail
IFS=$'\n\t'

# --- Config ---
GO_VERSION="1.25.5"                 # pinned to latest checked at time-of-edit (Dec 12, 2025)
GODOWNLOAD_URL="https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
GOBIN_DEFAULT="/root/go/bin"
INSTALL_DIR="/opt"
RETRY_WGET="wget -q --retry-connrefused --tries=5 --timeout=30 -O"

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "[!] Please run as root: sudo $0"
  exit 1
fi

echo "[+] Updating system..."
apt update -y
DEBIAN_FRONTEND=noninteractive apt upgrade -y

echo "[+] Installing base dependencies..."
apt install -y git curl wget unzip jq make build-essential python3 python3-pip ca-certificates \
    libpcap-dev xz-utils

# chrome/chromium needed by gowitness for headless screenshots
apt install -y chromium chromium-driver || true

# --- Install Go (if missing or different) ---
need_go_install=false
if command -v go >/dev/null 2>&1; then
  INSTALLED_GO_VERSION="$(go version | awk '{print $3}' | sed 's/go//')"
  if [ "$INSTALLED_GO_VERSION" != "$GO_VERSION" ]; then
    echo "[i] Found go $INSTALLED_GO_VERSION but will install $GO_VERSION for compatibility."
    need_go_install=true
  else
    echo "[+] go $GO_VERSION already installed."
  fi
else
  need_go_install=true
fi

if [ "$need_go_install" = true ]; then
  echo "[+] Installing Go ${GO_VERSION}..."
  tmpfile="/tmp/go${GO_VERSION}.tar.gz"
  $RETRY_WGET "$tmpfile" "${GODOWNLOAD_URL}"
  rm -rf /usr/local/go
  tar -C /usr/local -xzf "$tmpfile"
  rm -f "$tmpfile"
  # system-wide profile for go
  cat >/etc/profile.d/go.sh <<'EOF'
# Go environment
export PATH=/usr/local/go/bin:$PATH
export GOPATH=${HOME}/go
export GOBIN=${GOPATH}/bin
export PATH=${GOBIN}:/usr/local/go/bin:$PATH
EOF
  chmod +x /etc/profile.d/go.sh
  # apply to current shell
  export PATH=/usr/local/go/bin:$PATH
  export GOPATH="${HOME}/go"
  export GOBIN="${GOPATH}/bin"
  mkdir -p "${GOBIN}"
fi

# Ensure GOBIN/GOPATH exist in this run
export GOPATH="${GOPATH:-$HOME/go}"
export GOBIN="${GOBIN:-$GOPATH/bin}"
mkdir -p "$GOBIN"

echo "[+] go version: $(go version || echo 'go not available')"
echo "[+] GOPATH=$GOPATH"
echo "[+] GOBIN=$GOBIN"

# helper to install go-based tools (keeps environment stable)
go_install() {
  local pkg="$1"
  echo "[+] Installing ${pkg##*/}..."
  # allow failures to be visible but don't stop entire script if go install has transient issue
  if ! GO111MODULE=on go install -v "$pkg@latest"; then
    echo "[!] go install failed for $pkg — retrying once..."
    GO111MODULE=on go install -v "$pkg@latest" || {
      echo "[!] Failed to install $pkg via go install. You can try manually later."
    }
  fi
}

# -------------------------
# ProjectDiscovery tools (recommended install via go)
# -------------------------
go_install "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
go_install "github.com/projectdiscovery/dnsx/cmd/dnsx"
go_install "github.com/projectdiscovery/httpx/cmd/httpx"
# naabu needs libpcap-dev (installed above)
go_install "github.com/projectdiscovery/naabu/v2/cmd/naabu"
go_install "github.com/projectdiscovery/nuclei/v3/cmd/nuclei"

# -------------------------
# Other go-based tools
# -------------------------
go_install "github.com/tomnomnom/assetfinder"
go_install "github.com/ffuf/ffuf/v2"
go_install "github.com/sensepost/gowitness"         # gowitness v3+
go_install "github.com/tomnomnom/waybackurls"
go_install "github.com/lc/gau/v2/cmd/gau"
go_install "github.com/tomnomnom/gf"

# Install dns utilities and amass (system packages are usually fine on Kali)
echo "[+] Installing amass and masscan via apt (fast & reliable)..."
apt install -y amass masscan

# -------------------------
# Findomain - download prebuilt binary from releases (no cargo build)
# -------------------------
echo "[+] Installing Findomain (prebuilt binary from GitHub releases)..."
cd /tmp
# try downloading latest release binary zip (x86_64)
if $RETRY_WGET findomain.zip "https://github.com/Findomain/Findomain/releases/latest/download/findomain-linux.zip"; then
  unzip -o findomain.zip -d findomain_tmp >/dev/null 2>&1 || true
  # the release typically contains an executable named 'findomain' or 'findomain-linux'
  if [ -f findomain_tmp/findomain ] ; then
    mv findomain_tmp/findomain /usr/local/bin/findomain
    chmod +x /usr/local/bin/findomain
  elif [ -f findomain_tmp/findomain-linux ] ; then
    mv findomain_tmp/findomain-linux /usr/local/bin/findomain
    chmod +x /usr/local/bin/findomain
  else
    echo "[!] Could not find prebuilt Findomain binary inside zip; attempting to build from source..."
    rm -rf findomain_tmp
    git -C "${INSTALL_DIR}" clone https://github.com/Findomain/Findomain.git findomain-src 2>/dev/null || true
    cd "${INSTALL_DIR}/findomain-src"
    # try cargo build if cargo available
    if command -v cargo >/dev/null 2>&1; then
      cargo build --release --locked || true
      if [ -f target/release/findomain ]; then
        cp target/release/findomain /usr/local/bin/findomain
        chmod +x /usr/local/bin/findomain
      fi
    else
      echo "[!] cargo not found — skipping build-from-source. To build Findomain from source install cargo/rust and rerun."
    fi
  fi
  rm -rf findomain.zip findomain_tmp || true
else
  echo "[!] Could not download Findomain release zip. You can install via 'apt install findomain' or build from source."
fi

# -------------------------
# Move go binaries to global path
# -------------------------
echo "[+] Copying installed go binaries to /usr/local/bin..."
mkdir -p /usr/local/bin
# copy only executable files
if [ -d "$GOBIN" ]; then
  for f in "$GOBIN"/*; do
    if [ -f "$f" ] && [ -x "$f" ]; then
      cp -f "$f" /usr/local/bin/
    fi
  done
fi

# -------------------------
# GF patterns
# -------------------------
echo "[+] Installing GF patterns..."
GF_DIR="${HOME}/.gf"
mkdir -p "$GF_DIR"
cd "$GF_DIR"
# download some common example patterns
$RETRY_WGET xss.json "https://raw.githubusercontent.com/tomnomnom/gf/master/examples/xss.json"
$RETRY_WGET sqli.json "https://raw.githubusercontent.com/tomnomnom/gf/master/examples/sqli.json"
$RETRY_WGET redirect.json "https://raw.githubusercontent.com/tomnomnom/gf/master/examples/redirect.json"
# add community pattern repos (optional)
if command -v git >/dev/null 2>&1; then
  git -C /tmp clone https://github.com/1ndianl33t/Gf-Patterns.git 2>/dev/null || true
  if [ -d /tmp/Gf-Patterns ]; then
    cp -v /tmp/Gf-Patterns/*.json "$GF_DIR/" 2>/dev/null || true
    rm -rf /tmp/Gf-Patterns
  fi
fi
cd ~

# -------------------------
# Final messages & quick checks
# -------------------------
echo "==========================================="
echo "[✔] Tool installation attempts finished."
echo "[i] Note: If any 'go install' failed due to Go version mismatch or network issues, rerun the failing 'go install' commands manually."
echo "[i] Make sure your shell loads /etc/profile.d/go.sh (logout/login or 'source /etc/profile.d/go.sh')"
echo "[✔] PATH (current): $PATH"
echo "==========================================="

#  made by nothingnhm
