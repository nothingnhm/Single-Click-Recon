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
# ======================================================
set -e

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "[!] Please run as root: sudo ./install_all_tools.sh"
  exit 1
fi

echo "[+] Updating system..."
apt update -y && apt upgrade -y

echo "[+] Installing dependencies..."
apt install -y git curl wget unzip jq make build-essential python3 python3-pip

# Install Go
if ! command -v go >/dev/null 2>&1; then
  echo "[+] Installing Go..."
  wget https://go.dev/dl/go1.22.5.linux-amd64.tar.gz
  rm -rf /usr/local/go
  tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
  echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
  source ~/.bashrc
fi

echo "[+] Go version: $(go version)"

# ========== ProjectDiscovery Tools ==========

echo "[+] Installing Subfinder..."
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest


echo "[+] Installing DNSX..."
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest


echo "[+] Installing HTTPX..."
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest


echo "[+] Installing Naabu..."
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest


echo "[+] Installing Nuclei..."
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

# ========== Other Recon Tools ==========

echo "[+] Installing Amass..."
apt install -y amass

echo "[+] Installing Assetfinder..."
go install github.com/tomnomnom/assetfinder@latest


echo "[+] Installing Findomain..."
rm -f /usr/bin/findomain
cd /opt
git clone https://github.com/Findomain/Findomain.git findomain-src 2>/dev/null || true
cd findomain-src
git pull || true
cargo build --release
cp target/release/findomain /usr/bin/findomain
cd ~/findomain/releases/latest/download/findomain-linux
chmod +x findomain-linux
mv findomain-linux /usr/bin/findomain


echo "[+] Installing FFUF..."
go install github.com/ffuf/ffuf/v2@latest


echo "[+] Installing Masscan..."
git clone https://github.com/robertdavidgraham/masscan /opt/masscan
cd /opt/masscan
make
ln -sf /opt/masscan/bin/masscan /usr/bin/masscan
cd ~


echo "[+] Installing Gowitness..."
go install github.com/sensepost/gowitness@latest


echo "[+] Installing Waybackurls..."
go install github.com/tomnomnom/waybackurls@latest


echo "[+] Installing GAU..."
go install github.com/lc/gau/v2/cmd/gau@latest


echo "[+] Installing GF..."
go install github.com/tomnomnom/gf@latest

# Move Go tools to PATH
mkdir -p /usr/local/bin
cp ~/go/bin/* /usr/local/bin/ 2>/dev/null || true

# GF patterns
mkdir -p ~/.gf
cd ~/.gf
wget https://raw.githubusercontent.com/tomnomnom/gf/master/examples/xss.json
wget https://raw.githubusercontent.com/tomnomnom/gf/master/examples/sqli.json
wget https://raw.githubusercontent.com/tomnomnom/gf/master/examples/redirect.json
cd ~


echo "\n==========================================="
echo "[✔] All tools installed successfully!"
echo "[✔] Make sure to restart your terminal."
echo "==========================================="

#  made by nothingnhm
