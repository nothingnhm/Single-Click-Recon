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

# ------------ CHECK ROOT ------------
if [ "$EUID" -ne 0 ]; then
  echo "[!] Run as root: sudo ./install_all_tools.sh"
  exit 1
fi

echo "[+] Updating system..."
apt update -y && apt upgrade -y

echo "[+] Installing base dependencies..."
apt install -y git curl wget unzip jq make build-essential python3 python3-pip \
    libpcap-dev ca-certificates chromium chromium-driver

# ------------ GO LANGUAGE SETUP ------------
GO_VERSION="1.25.5"
GO_URL="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"

# Helper function for safe wget
retry_wget () {
    wget -q --retry-connrefused --tries=5 --timeout=30 -O "$1" "$2"
}

INSTALL_GO=false
if command -v go >/dev/null 2>&1; then
  INSTALLED=$(go version | awk '{print $3}' | sed 's/go//')
  if [ "$INSTALLED" != "$GO_VERSION" ]; then
    INSTALL_GO=true
  fi
else
  INSTALL_GO=true
fi

if [ "$INSTALL_GO" = true ]; then
  echo "[+] Installing Go ${GO_VERSION}..."
  retry_wget /tmp/go.tar.gz "$GO_URL"
  rm -rf /usr/local/go
  tar -C /usr/local -xzf /tmp/go.tar.gz
  rm -f /tmp/go.tar.gz

  cat >/etc/profile.d/go.sh <<'EOF'
export PATH=/usr/local/go/bin:$PATH
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$GOBIN:/usr/local/go/bin:$PATH
EOF
  chmod +x /etc/profile.d/go.sh
  source /etc/profile.d/go.sh
else
  source /etc/profile.d/go.sh 2>/dev/null || true
fi

export GOPATH="${HOME}/go"
export GOBIN="${GOPATH}/bin"
mkdir -p "$GOBIN"

echo "[+] Go Version: $(go version)"

# ------------ GO INSTALL HELPER ------------
go_install() {
  echo "[+] Installing $(basename "$1")..."
  GO111MODULE=on go install -v "$1@latest"
}

# ------------ PROJECTDISCOVERY TOOLS ------------
go_install github.com/projectdiscovery/subfinder/v2/cmd/subfinder
go_install github.com/projectdiscovery/dnsx/cmd/dnsx
go_install github.com/projectdiscovery/httpx/cmd/httpx
go_install github.com/projectdiscovery/naabu/v2/cmd/naabu
go_install github.com/projectdiscovery/nuclei/v3/cmd/nuclei

# ------------ OTHER GO TOOLS ------------
go_install github.com/tomnomnom/assetfinder
go_install github.com/ffuf/ffuf/v2
go_install github.com/sensepost/gowitness
go_install github.com/tomnomnom/waybackurls
go_install github.com/lc/gau/v2/cmd/gau
go_install github.com/tomnomnom/gf

# ------------ APT TOOLS ------------
echo "[+] Installing Masscan & Amass from apt..."
apt install -y masscan amass

# ------------ FINDOMAIN (PREBUILT BINARY) ------------
echo "[+] Installing Findomain..."
cd /tmp
retry_wget findomain.zip "https://github.com/Findomain/Findomain/releases/latest/download/findomain-linux.zip"
unzip -o findomain.zip -d ftmp >/dev/null 2>&1

if [ -f ftmp/findomain ]; then
  mv ftmp/findomain /usr/local/bin/findomain
  chmod +x /usr/local/bin/findomain
elif [ -f ftmp/findomain-linux ]; then
  mv ftmp/findomain-linux /usr/local/bin/findomain
  chmod +x /usr/local/bin/findomain
else
  echo "[!] Findomain binary missing — install manually if needed."
fi
rm -rf ftmp findomain.zip

# ------------ COPY GO BINARIES GLOBALLY ------------
echo "[+] Publishing Go tools to /usr/local/bin..."
cp -f "$GOBIN"/* /usr/local/bin/ 2>/dev/null || true

# ------------ GF PATTERNS ------------
echo "[+] Installing GF patterns..."
mkdir -p "$HOME/.gf"
cd "$HOME/.gf"

retry_wget xss.json "https://raw.githubusercontent.com/tomnomnom/gf/master/examples/xss.json"
retry_wget sqli.json "https://raw.githubusercontent.com/tomnomnom/gf/master/examples/sqli.json"
retry_wget redirect.json "https://raw.githubusercontent.com/tomnomnom/gf/master/examples/redirect.json"

# community patterns
if command -v git >/dev/null 2>&1; then
  git clone https://github.com/1ndianl33t/Gf-Patterns.git /tmp/gfp 2>/dev/null || true
  cp -f /tmp/gfp/*.json "$HOME/.gf/" 2>/dev/null || true
  rm -rf /tmp/gfp
fi

cd ~

# ------------ DONE ------------
echo "=============================================="
echo "[✔] All tools installed successfully!"
echo "[ℹ] Run: source /etc/profile.d/go.sh"
echo "=============================================="

#  made by nothingnhm
