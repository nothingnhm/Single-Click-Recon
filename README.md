# 🔧 Bug Bounty Recon Toolkit — One‑Click Installer for Kali Linux

This project provides a **one‑click automated installer** that sets up a full bug bounty and reconnaissance environment on **Kali Linux**.

Perfect for:

* Bug bounty hunters
* Pentesters
* Red teamers
* CTF players
* Recon automation setups

---

## 🚀 Features

### ✅ Installs 15+ Essential Recon Tools

Includes:

* **ProjectDiscovery Suite**: subfinder, dnsx, httpx, naabu, nuclei
* **Domain & Subdomain Tools**: amass, assetfinder, findomain
* **Web Recon Tools**: ffuf, gowitness, waybackurls, gau, gf
* **Network Tools**: masscan

### ⚡ One‑Click Execution

Just run:

```bash
sudo ./install_all_tools.sh
```

Everything else is automated.

### 📦 Auto‑Setup

* Auto‑installs Go
* Auto‑moves tools into PATH
* Fetches default GF patterns
* Downloads required dependencies

### 🛠 Ideal For

* Passive + active reconnaissance
* Subdomain enumeration
* Content discovery
* URL gathering
* Screenshotting
* Port scanning
* Vulnerability scanning

---

## 📥 Installation

### 1️⃣ Clone the repo

```bash
git clone https://github.com/nothingnhm/Single-Click-Recon.git
cd Single-Click-Recon
```

### 2️⃣ Make script executable

```bash
chmod +x install_all_tools.sh
```

### 3️⃣ Run installer (root required)

```bash
sudo ./install_all_tools.sh
```

### 4️⃣ Refresh terminal

```bash
source ~/.bashrc
```

---

## 🧰 Tools Installed

### 🔵 ProjectDiscovery Tools

* **subfinder** – Passive subdomain discovery
* **dnsx** – DNS probing
* **httpx** – HTTP probing
* **naabu** – Fast port scanning
* **nuclei** – Vulnerability scanning

### 🟢 Recon Tools

* **amass** – Deep subdomain enum
* **assetfinder** – Quick subdomain grabs
* **findomain** – Fast subdomain finder

### 🟣 Web Fuzzing

* **ffuf** – Directory & parameter fuzzing

### 🔴 Scanning & Screenshotting

* **masscan** – Internet‑scale port scanner
* **gowitness** – Website screenshot capture

### 🟠 URL Collection

* **waybackurls**, **gau** – URL harvesting
* **gf** – Pattern filtering

---

## 📝 Requirements

* Kali Linux (recommended)
* Root privileges
* Internet connection

---

## 🏁 After Installation

Verify tools:

```bash
subfinder -h
amass -h
httpx -h
nuclei -h
```

All binaries are placed in:

```
/usr/local/bin
```

---

## 📌 Notes

* Make sure `GOPATH` and `/usr/local/go/bin` are in your PATH.
* Script is idempotent: running multiple times won't break anything.

---

## 🤝 Contributing

Pull requests are welcome! Add tools, improve automation, or optimize performance.

---

## 📜 License

MIT License — free to use, modify, and distribute.

---

## ⭐ Support

If this project helps you, give it a ⭐ on GitHub!
