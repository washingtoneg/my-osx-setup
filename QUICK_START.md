# QUICK START - Apply Fixes to Your Repository

## What You Have

I've analyzed your entire repository and created fixed versions of all the broken files. Here's what to do:

## Option 1: Extract and Use Fixed Repository (Easiest)

1. **Download the fixed ZIP** (my-osx-setup-FIXED.zip)
2. **Extract it**
3. **Run it!**

```bash
cd ~/Downloads
unzip my-osx-setup-FIXED.zip
cd my-osx-setup-FIXED
./setup.sh
```

That's it! The fixed version will work on your Apple Silicon Mac.

---

## Option 2: Update Your Existing Repository

If you want to apply the fixes to your existing cloned repo:

### Step 1: Backup
```bash
cp -r my-osx-setup my-osx-setup-backup
```

### Step 2: Copy Fixed Files

From the `my-osx-setup-FIXED` directory, copy these files to your existing repo:

```bash
# Core files
cp my-osx-setup-FIXED/setup.sh my-osx-setup/
cp my-osx-setup-FIXED/bootstrap.sh my-osx-setup/
cp my-osx-setup-FIXED/README.md my-osx-setup/

# Ansible files
cp my-osx-setup-FIXED/ansible/hosts my-osx-setup/ansible/
cp my-osx-setup-FIXED/ansible/ansible.cfg my-osx-setup/ansible/
cp my-osx-setup-FIXED/ansible/requirements.yml my-osx-setup/ansible/

# Role files
cp my-osx-setup-FIXED/ansible/roles/darwin_bootstrap/tasks/homebrew.yml \
   my-osx-setup/ansible/roles/darwin_bootstrap/tasks/

cp my-osx-setup-FIXED/ansible/roles/darwin_bootstrap/defaults/main.yml \
   my-osx-setup/ansible/roles/darwin_bootstrap/defaults/
```

### Step 3: Make Executable
```bash
chmod +x my-osx-setup/setup.sh
chmod +x my-osx-setup/bootstrap.sh
chmod +x my-osx-setup/ansible/hosts
```

### Step 4: Test
```bash
cd my-osx-setup
./setup.sh
```

---

## What Changed - Quick Summary

### Files Modified (7 total)

1. ✅ **setup.sh** - Complete rewrite with Apple Silicon support
2. ✅ **ansible/hosts** - Architecture-aware Python detection  
3. ✅ **ansible/ansible.cfg** - Modern Ansible settings
4. ✅ **ansible/requirements.yml** - NEW FILE - Collections
5. ✅ **ansible/roles/darwin_bootstrap/tasks/homebrew.yml** - Module FQCN
6. ✅ **ansible/roles/darwin_bootstrap/defaults/main.yml** - Updated packages
7. ✅ **bootstrap.sh** - NEW FILE - Easy first-time setup

### Files Unchanged (can use originals)

- ✅ `bash_utils.sh` - No changes needed
- ✅ All other task files - Will work once main files fixed

---

## Critical Issues Fixed

### 1. Homebrew (CRITICAL)
- ❌ Old: Hardcoded `/usr/local` (Intel only)
- ✅ New: Detects architecture, uses `/opt/homebrew` on Apple Silicon

### 2. Python (CRITICAL)
- ❌ Old: Python 2 (EOL and removed from macOS)
- ✅ New: Python 3.12 installed via Homebrew

### 3. Ansible (CRITICAL)
- ❌ Old: Installed via Homebrew (deprecated)
- ✅ New: Installed via pip3 with collections

### 4. Ansible Modules (CRITICAL)
- ❌ Old: `homebrew:`, `homebrew_cask:` (broken)
- ✅ New: `community.general.homebrew:`, etc. (FQCN)

### 5. Rosetta 2 (NEW)
- ✅ Added: Automatic Rosetta 2 installation on Apple Silicon

### 6. Package Versions (IMPORTANT)
- ✅ Updated: PostgreSQL 9.6 → 16
- ✅ Updated: Ruby 2.6.1 → 3.2.2

---

## Before You Run

### 1. Get GitHub API Token
```bash
# Create at: https://github.com/settings/tokens/new
# Scope: admin:public_key
export GITHUB_API_TOKEN="your_token_here"
```

### 2. Check Your System
```bash
sw_vers -productVersion  # macOS version
uname -m                 # arm64 or x86_64
```

### 3. Connect to Power
The setup takes 30-60 minutes. Don't let your laptop die!

---

## Running the Setup

### Method 1: Bootstrap (Recommended for first time)
```bash
curl -fsSL https://raw.githubusercontent.com/washingtoneg/my-osx-setup/main/bootstrap.sh | bash
```

### Method 2: Manual
```bash
cd my-osx-setup-FIXED
./setup.sh
```

---

## After Setup

### 1. Generate SSH Key
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub | pbcopy
# Add at: https://github.com/settings/ssh/new
```

### 2. Test SSH
```bash
ssh -T git@github.com
```

### 3. Clone Your Dotfiles
```bash
git clone git@github.com:washingtoneg/dotfiles.git ~/scratch/dotfiles
cd ~/scratch/dotfiles
./install.sh
```

---

## Verification

After setup completes, verify everything:

```bash
# Check Homebrew
brew --version
brew --prefix  # Should show /opt/homebrew on Apple Silicon

# Check Python
python3 --version  # Should be 3.12.x

# Check Ansible
ansible --version
ansible-galaxy collection list | grep community.general

# Check architecture
uname -m  # arm64 or x86_64
```

---

## If Something Goes Wrong

### Setup Fails Early
- Check you have admin/sudo access
- Make sure you're on macOS 13+ (Ventura or later)
- Ensure stable internet connection

### Homebrew Issues
```bash
# Reset PATH
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"     # Intel
```

### Ansible Issues
```bash
# Install collections manually
cd ansible
ansible-galaxy collection install -r requirements.yml
```

### Permission Issues
- System Settings > Privacy & Security > Full Disk Access
- Add Terminal.app or iTerm.app
- Restart terminal

---

## Commit Changes to GitHub

Once you've tested and verified:

```bash
cd my-osx-setup
git add .
git commit -m "Fix Apple Silicon compatibility for 2026

- Add architecture detection
- Update Homebrew paths for arm64
- Update to Python 3.12
- Add Ansible Galaxy collections
- Update all Ansible modules to FQCN
- Add Rosetta 2 installation
- Update deprecated packages (postgresql, ruby)
- Add bootstrap.sh for easier setup"

git push origin main
```

---

## Files in my-osx-setup-FIXED.zip

```
my-osx-setup-FIXED/
├── setup.sh                     ← Main setup script (FIXED)
├── bootstrap.sh                 ← Bootstrap helper (NEW)
├── bash_utils.sh                ← Utilities (unchanged)
├── README.md                    ← Documentation (UPDATED)
├── ansible.cfg                  ← Root config (unchanged)
└── ansible/
    ├── ansible.cfg              ← Working config (FIXED)
    ├── hosts                    ← Inventory (FIXED)
    ├── requirements.yml         ← Collections (NEW)
    ├── playbooks/
    │   └── darwin_bootstrap.yml
    └── roles/
        └── darwin_bootstrap/
            ├── defaults/
            │   └── main.yml     ← Package lists (FIXED)
            ├── tasks/
            │   ├── main.yml
            │   ├── homebrew.yml ← Homebrew (FIXED)
            │   └── ...          ← Other tasks (unchanged)
            └── handlers/
                └── main.yml
```

---

## Next Steps

1. ✅ Extract and review the fixed repository
2. ✅ Test on your Apple Silicon Mac
3. ✅ Compare changes with your original
4. ✅ Commit to GitHub
5. ✅ Enjoy your automated Mac setup!

---

## Need Help?

Read the detailed analysis in `DETAILED_ANALYSIS.md` for:
- Line-by-line explanation of every change
- Rationale for each fix
- Testing strategies
- Known issues and workarounds

**You're ready to go! 🚀**
