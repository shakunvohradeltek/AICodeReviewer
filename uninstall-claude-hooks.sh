#!/bin/bash
# Claude Code Review Git Hooks Uninstall Script
# OS-aware version that only creates relevant OS-specific files
# Compatible with Mac and Windows (with WSL)

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# OS detection
OS_TYPE="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # More robust WSL detection that works for both WSL1 and WSL2
    if grep -q Microsoft /proc/version 2>/dev/null || \
       grep -q WSL /proc/version 2>/dev/null || \
       [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
        OS_TYPE="wsl"
    else
        OS_TYPE="linux"
    fi
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS_TYPE="windows"
fi

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

log_message "INFO" "🗑️  Claude Code Review Git Hooks Uninstaller"
log_message "INFO" "============================================="
log_message "INFO" "Detected OS: $OS_TYPE"

# Check if git repository exists
if [ ! -d ".git" ]; then
    log_message "ERROR" "Not a git repository. Nothing to uninstall."
    exit 1
fi

# Check for custom hooks directory or git hooks directory
if [ ! -d ".hooks" ] && [ ! -d ".git/hooks" ]; then
    log_message "ERROR" "Neither custom hooks directory nor git hooks directory found. Nothing to uninstall."
    exit 1
fi

# Check for custom hooks directory
if [ -d ".hooks" ]; then
    # Check for pre-commit hook in custom directory
    if [ -f ".hooks/pre-commit" ]; then
        # Check if it's our hook by looking for Claude references
        if grep -q "Claude Code Review" ".hooks/pre-commit"; then
            log_message "INFO" "Removing pre-commit hook..."
            rm ".hooks/pre-commit"
            log_message "SUCCESS" "Pre-commit hook removed"
        else
            log_message "WARNING" "Pre-commit hook exists but doesn't appear to be a Claude Code Review hook."
            read -p "Do you want to remove it anyway? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm ".hooks/pre-commit"
                log_message "SUCCESS" "Pre-commit hook removed"
            else
                log_message "INFO" "Skipping pre-commit hook removal"
            fi
        fi
    else
        log_message "INFO" "No pre-commit hook found in custom hooks directory"
    fi
    
    # Also check for any hooks in the default location
    if [ -f ".git/hooks/pre-commit" ]; then
        # Check if it's our hook by looking for Claude references
        if grep -q "Claude Code Review" ".git/hooks/pre-commit"; then
            log_message "INFO" "Removing pre-commit hook from default location..."
            rm ".git/hooks/pre-commit"
            log_message "SUCCESS" "Pre-commit hook removed from default location"
        fi
    fi
else
    # Check for pre-commit hook in default location
    if [ -f ".git/hooks/pre-commit" ]; then
        # Check if it's our hook by looking for Claude references
        if grep -q "Claude Code Review" ".git/hooks/pre-commit"; then
            log_message "INFO" "Removing pre-commit hook..."
            rm ".git/hooks/pre-commit"
            log_message "SUCCESS" "Pre-commit hook removed"
        else
            log_message "WARNING" "Pre-commit hook exists but doesn't appear to be a Claude Code Review hook."
            read -p "Do you want to remove it anyway? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm ".git/hooks/pre-commit"
                log_message "SUCCESS" "Pre-commit hook removed"
            else
                log_message "INFO" "Skipping pre-commit hook removal"
            fi
        fi
    else
        log_message "INFO" "No pre-commit hook found"
    fi
fi

# Check for pre-push hook in custom directory
if [ -d ".hooks" ] && [ -f ".hooks/pre-push" ]; then
    # Check if it's our hook by looking for Claude references
    if grep -q "Claude Code Review" ".hooks/pre-push"; then
        log_message "INFO" "Removing pre-push hook from custom directory..."
        rm ".hooks/pre-push"
        log_message "SUCCESS" "Pre-push hook removed from custom directory"
    else
        log_message "WARNING" "Pre-push hook exists in custom directory but doesn't appear to be a Claude Code Review hook."
        read -p "Do you want to remove it anyway? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm ".hooks/pre-push"
            log_message "SUCCESS" "Pre-push hook removed from custom directory"
        else
            log_message "INFO" "Skipping pre-push hook removal from custom directory"
        fi
    fi
fi

# Also check for pre-push hook in default location
if [ -f ".git/hooks/pre-push" ]; then
    # Check if it's our hook by looking for Claude references
    if grep -q "Claude Code Review" ".git/hooks/pre-push"; then
        log_message "INFO" "Removing pre-push hook from default location..."
        rm ".git/hooks/pre-push"
        log_message "SUCCESS" "Pre-push hook removed from default location"
    else
        log_message "WARNING" "Pre-push hook exists in default location but doesn't appear to be a Claude Code Review hook."
        read -p "Do you want to remove it anyway? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm ".git/hooks/pre-push"
            log_message "SUCCESS" "Pre-push hook removed from default location"
        else
            log_message "INFO" "Skipping pre-push hook removal from default location"
        fi
    fi
fi

# Check for custom hooks directory
if [ -d ".hooks" ]; then
    log_message "INFO" "Found .hooks custom hooks directory."
    read -p "Do you want to remove this directory? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_message "INFO" "Removing custom hooks directory..."
        rm -rf ".hooks"
        log_message "SUCCESS" "Custom hooks directory removed"
    else
        log_message "INFO" "Keeping custom hooks directory"
    fi
fi

# Reset Git hooks path configuration
log_message "INFO" "Checking Git hooks path configuration..."
current_hooks_path=$(git config core.hooksPath)
if [ $? -eq 0 ]; then
    log_message "INFO" "Current Git hooks path is: $current_hooks_path"
    echo ""
    read -p "Do you want to reset Git hooks path configuration? (y/n) " reset_hooks_path
    if [[ $reset_hooks_path =~ ^[Yy]$ ]]; then
        git config --unset core.hooksPath
        log_message "SUCCESS" "Reset Git hooks path to default"
    else
        log_message "INFO" "Keeping Git hooks path configuration"
    fi
else
    log_message "INFO" "Git hooks path is not explicitly configured, no need to reset"
fi

# Check for configuration directory
if [ -d ".claude-code" ]; then
    log_message "INFO" "Found .claude-code configuration directory."
    read -p "Do you want to remove this directory and all configuration? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_message "INFO" "Removing configuration directory..."
        rm -rf ".claude-code"
        log_message "SUCCESS" "Configuration directory removed"
    else
        log_message "INFO" "Keeping configuration directory"
    fi
fi

# Create Windows PowerShell uninstaller only if we're on Windows or WSL
if [[ "$OS_TYPE" == "windows" || "$OS_TYPE" == "wsl" ]]; then
    log_message "INFO" "Creating Windows PowerShell uninstaller script..."
    cat > uninstall-claude-hooks.ps1 << 'EOF'
# Claude Code Review Git Hooks Uninstall Script for Windows
# Run this script from PowerShell

# Define colors and functions
function Write-ColorLog {
    param (
        [string]$Level,
        [string]$Message
    )
    
    switch ($Level) {
        "INFO" { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        default { Write-Host "$Message" }
    }
}

Write-ColorLog -Level "INFO" -Message "🗑️  Claude Code Review Git Hooks Uninstaller (Windows)"
Write-ColorLog -Level "INFO" -Message "============================================="

# Check if git hooks directory exists
if (-not (Test-Path ".git\hooks")) {
    Write-ColorLog -Level "ERROR" -Message "Git hooks directory not found. Nothing to uninstall."
    exit 1
}

# Check for pre-commit hook
if (Test-Path ".git\hooks\pre-commit") {
    # Check if it's our hook by looking for Claude references
    $hookContent = Get-Content ".git\hooks\pre-commit" -Raw
    if ($hookContent -match "Claude Code Review") {
        Write-ColorLog -Level "INFO" -Message "Removing pre-commit hook..."
        Remove-Item ".git\hooks\pre-commit" -Force
        Write-ColorLog -Level "SUCCESS" -Message "Pre-commit hook removed"
    } else {
        Write-ColorLog -Level "WARNING" -Message "Pre-commit hook exists but doesn't appear to be a Claude Code Review hook."
        $removeAnyway = Read-Host "Do you want to remove it anyway? (y/n)"
        if ($removeAnyway -eq "y" -or $removeAnyway -eq "Y") {
            Remove-Item ".git\hooks\pre-commit" -Force
            Write-ColorLog -Level "SUCCESS" -Message "Pre-commit hook removed"
        } else {
            Write-ColorLog -Level "INFO" -Message "Skipping pre-commit hook removal"
        }
    }
} else {
    Write-ColorLog -Level "INFO" -Message "No pre-commit hook found"
}

# Check for pre-push hook
if (Test-Path ".git\hooks\pre-push") {
    # Check if it's our hook by looking for Claude references
    $hookContent = Get-Content ".git\hooks\pre-push" -Raw
    if ($hookContent -match "Claude Code Review") {
        Write-ColorLog -Level "INFO" -Message "Removing pre-push hook..."
        Remove-Item ".git\hooks\pre-push" -Force
        Write-ColorLog -Level "SUCCESS" -Message "Pre-push hook removed"
    } else {
        Write-ColorLog -Level "WARNING" -Message "Pre-push hook exists but doesn't appear to be a Claude Code Review hook."
        $removeAnyway = Read-Host "Do you want to remove it anyway? (y/n)"
        if ($removeAnyway -eq "y" -or $removeAnyway -eq "Y") {
            Remove-Item ".git\hooks\pre-push" -Force
            Write-ColorLog -Level "SUCCESS" -Message "Pre-push hook removed"
        } else {
            Write-ColorLog -Level "INFO" -Message "Skipping pre-push hook removal"
        }
    }
} else {
    Write-ColorLog -Level "INFO" -Message "No pre-push hook found"
}

# Check for configuration directory
if (Test-Path ".claude-code") {
    Write-ColorLog -Level "INFO" -Message "Found .claude-code configuration directory."
    $removeConfig = Read-Host "Do you want to remove this directory and all configuration? (y/n)"
    if ($removeConfig -eq "y" -or $removeConfig -eq "Y") {
        Write-ColorLog -Level "INFO" -Message "Removing configuration directory..."
        Remove-Item ".claude-code" -Recurse -Force
        Write-ColorLog -Level "SUCCESS" -Message "Configuration directory removed"
    } else {
        Write-ColorLog -Level "INFO" -Message "Keeping configuration directory"
    }
}

Write-ColorLog -Level "SUCCESS" -Message "Uninstallation Complete!"
Write-ColorLog -Level "INFO" -Message "Note: This script didn't remove the Claude Code CLI itself."
Write-ColorLog -Level "INFO" -Message "If you want to remove Claude Code CLI, run: npm uninstall -g @anthropic-ai/claude-code"
EOF

    log_message "SUCCESS" "Created Windows PowerShell uninstaller at uninstall-claude-hooks.ps1"
else
    log_message "INFO" "Skipping Windows PowerShell uninstaller creation (detected $OS_TYPE environment)"
fi

log_message "SUCCESS" "Uninstallation Complete!"
log_message "INFO" "Note: This script didn't remove the Claude Code CLI itself."
log_message "INFO" "If you want to remove Claude Code CLI, run: npm uninstall -g @anthropic-ai/claude-code"