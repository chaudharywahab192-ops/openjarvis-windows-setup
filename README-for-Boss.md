# OpenJarvis Quick Setup Guide

Welcome! This 1-click installer sets up your free local AI assistant (**OpenJarvis**) with 8 starter skills on your Windows PC. Everything runs 100% locally and stays completely free.

---

### Step 1: Open PowerShell
1. Press the **Windows Key** on your keyboard.
2. Type `powershell`.
3. Press **Enter** (or click **Windows PowerShell**).

---

### Step 2: Run This Command
Copy and paste the command below into your PowerShell window, then press **Enter**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; .\Install-OpenJarvis.ps1
```

*(Installation takes about 5 to 10 minutes depending on internet speed. It automatically installs free background tools, downloads your local AI model, and configures your starter skills.)*

---

### Step 3: Enjoy Your New AI Assistant!
When finished, the screen will show a green **`RESULT: PASS`** summary box.

**How to open your AI chat anytime:**
- Open a new PowerShell window, type `jarvis`, and press **Enter**.
- Or run `.\START-Jarvis.ps1` in this setup folder.

**What success looks like:**
- `jarvis doctor` health check displays **0 errors**.
- Typing `jarvis` opens the interactive chat prompt where you can start talking to your assistant immediately!

---

### Need Help?
If anything goes wrong or you see red error text, simply copy and paste the red text and send it to **Vesper**!
