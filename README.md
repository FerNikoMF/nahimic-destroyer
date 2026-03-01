# 💥 Nahimic Destroyer

A lightweight, one-click PowerShell script to completely eradicate Nahimic audio bloatware from your Windows system and permanently block it from reinstalling via Windows Update.

## 🛑 The Problem
If you own a laptop (like Lenovo Legion, MSI, etc.), Nahimic is often forced onto your system at the OEM level. Even if you manually uninstall it, Windows Update will quietly download and install it again in the background. It consumes resources, interferes with audio setups, and is notoriously hard to remove.

## 🛠️ What this script does
1. **Registry Block:** Edits Windows Policies to permanently deny the installation of Nahimic/A-Volute Hardware IDs.
2. **Process Termination:** Force-kills all running Nahimic services and background processes.
3. **Driver Store Cleanup:** Uses native Windows `pnputil` to rip the drivers completely out of the Windows Driver Store.
4. **Deep Clean:** Deletes leftover folders in `System32`, `AppData`, and removes associated Scheduled Tasks.

## 🚀 Quick Start (One-Line Execution)

The easiest way to run the destroyer. Open **PowerShell as Administrator** and paste the following command:


```powershell
irm "https://raw.githubusercontent.com/FerNikoMF/nahimic-destroyer/refs/heads/main/run.ps1" | iex
```


# 💻 Manual Execution
If you prefer to review the code before running it:
Download the run.ps1 file from this repository.
Open PowerShell as Administrator.
Navigate to the downloaded file and run it.

# ⚠️ Disclaimer
This script modifies the Windows Registry to block specific hardware IDs. While it is safe and targeted strictly at Nahimic/A-Volute components, use it at your own risk. A system restart is required after execution.
