# Claude Code Review Git Hooks Uninstallation Script for Windows
# This script removes Git hooks set up by install-windows-hooks.ps1

# Define color functions for logging
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

Write-ColorLog -Level "INFO" -Message "Claude Code Review Git Hooks Uninstallation for Windows with WSL"
Write-ColorLog -Level "INFO" -Message "========================================================"

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-ColorLog -Level "ERROR" -Message "Not a git repository. Please run this script from the root of a git repository."
    exit 1
}

# Reset Git hooks path configuration
Write-ColorLog -Level "INFO" -Message "Checking Git hooks path configuration..."
$currentHooksPath = git config core.hooksPath 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-ColorLog -Level "INFO" -Message "Current Git hooks path is: $currentHooksPath"
    Write-Output ""
    $resetHooksPath = Read-Host "Do you want to reset Git hooks path configuration? (y/n)"
    if ($resetHooksPath -eq "y") {
        git config --unset core.hooksPath
        Write-ColorLog -Level "SUCCESS" -Message "Reset Git hooks path to default"
    } else {
        Write-ColorLog -Level "INFO" -Message "Keeping Git hooks path configuration"
    }
} else {
    Write-ColorLog -Level "INFO" -Message "Git hooks path is not explicitly configured, no need to reset"
}

# Remove hooks from .git/hooks
Write-ColorLog -Level "INFO" -Message "Removing Git hooks..."

# List of hook files to remove
$hookFiles = @(
    ".git\hooks\pre-commit",
    ".git\hooks\pre-commit.bat",
    ".git\hooks\pre-commit-claude.ps1"
)

foreach ($hookFile in $hookFiles) {
    if (Test-Path $hookFile) {
        Remove-Item -Path $hookFile -Force
        Write-ColorLog -Level "SUCCESS" -Message "Removed $hookFile"
    } else {
        Write-ColorLog -Level "INFO" -Message "$hookFile not found, skipping"
    }
}

# Ask if user wants to remove the .hooks directory
Write-ColorLog -Level "INFO" -Message "Checking for .hooks directory..."
if (Test-Path ".hooks") {
    Write-Output ""
    $removeHooks = Read-Host "Do you want to remove the .hooks directory? (y/n)"
    if ($removeHooks -eq "y") {
        Remove-Item -Path ".hooks" -Recurse -Force
        Write-ColorLog -Level "SUCCESS" -Message "Removed .hooks directory"
    } else {
        Write-ColorLog -Level "INFO" -Message "Keeping .hooks directory"
    }
}

# Ask if user wants to remove the .claude-code directory
Write-ColorLog -Level "INFO" -Message "Checking for .claude-code directory..."
if (Test-Path ".claude-code") {
    Write-Output ""
    $removeConfig = Read-Host "Do you want to remove the .claude-code directory with configuration? (y/n)"
    if ($removeConfig -eq "y") {
        Remove-Item -Path ".claude-code" -Recurse -Force
        Write-ColorLog -Level "SUCCESS" -Message "Removed .claude-code directory with configuration"
    } else {
        Write-ColorLog -Level "INFO" -Message "Keeping .claude-code directory with configuration"
    }
}

# Clean up gitignore entries
Write-ColorLog -Level "INFO" -Message "Checking .gitignore for Claude Code entries..."
if (Test-Path ".gitignore") {
    Write-Output ""
    $cleanGitignore = Read-Host "Do you want to remove Claude Code entries from .gitignore? (y/n)"
    if ($cleanGitignore -eq "y") {
        $gitignoreContent = Get-Content ".gitignore" -Raw
        $newContent = $gitignoreContent -replace "# Claude Code Review files\n", "" `
                                     -replace "/\.hooks/\n", "" `
                                     -replace "/\.claude-code/\n", "" `
                                     -replace "/install-windows-hooks.*\.ps1\n", "" `
                                     -replace "/uninstall-windows-hooks.*\.ps1\n", ""
        [System.IO.File]::WriteAllText((Join-Path -Path (Get-Location) -ChildPath ".gitignore"), $newContent)
        Write-ColorLog -Level "SUCCESS" -Message "Removed Claude Code entries from .gitignore"
    } else {
        Write-ColorLog -Level "INFO" -Message "Keeping Claude Code entries in .gitignore"
    }
}

# Self-delete option
Write-Output ""
$selfDelete = Read-Host "Do you want this script to delete itself after completion? (y/n)"
if ($selfDelete -eq "y") {
    # Create a temporary batch file to delete the script after it exits
    $scriptPath = $MyInvocation.MyCommand.Path
    $tempBatPath = [System.IO.Path]::GetTempFileName() + ".bat"
    @"
@echo off
ping -n 2 127.0.0.1 > nul
del "$scriptPath"
del "%~f0"
"@ | Out-File -FilePath $tempBatPath -Encoding ascii
    
    Write-ColorLog -Level "SUCCESS" -Message "Uninstallation complete! This script will self-delete."
    
    # Start the batch file to delete this script
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $tempBatPath" -WindowStyle Hidden
} else {
    Write-ColorLog -Level "SUCCESS" -Message "Uninstallation complete!"
}

Write-ColorLog -Level "INFO" -Message "Claude Code Review Git hooks have been uninstalled."
Write-ColorLog -Level "INFO" -Message "Note: This script does not uninstall WSL or Claude Code CLI."