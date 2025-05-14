# Claude Code Review Git Hooks Installation Script for Windows (Simplest Possible)
# This script sets up Git hooks to work with Claude Code in WSL

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

# Function to create a file with Unix line endings (no BOM)
function Create-UnixFile {
    param (
        [string]$Path,
        [string]$Content
    )
    
    $directory = [System.IO.Path]::GetDirectoryName($Path)
    if (-not (Test-Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
    
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    $UnixContent = $Content.Replace("`r`n", "`n")
    [System.IO.File]::WriteAllText($Path, $UnixContent, $Utf8NoBomEncoding)
}

Write-ColorLog -Level "INFO" -Message "Claude Code Review Git Hooks Installation for Windows with WSL"
Write-ColorLog -Level "INFO" -Message "========================================================"

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-ColorLog -Level "ERROR" -Message "Not a git repository. Please run this script from the root of a git repository."
    exit 1
}

# Check if WSL is installed
Write-ColorLog -Level "INFO" -Message "Checking for WSL installation..."
try {
    $wslCheck = wsl --status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ColorLog -Level "ERROR" -Message "Windows Subsystem for Linux (WSL) is not installed"
        exit 1
    }
    Write-ColorLog -Level "SUCCESS" -Message "WSL is installed and ready."
} catch {
    Write-ColorLog -Level "ERROR" -Message "Windows Subsystem for Linux (WSL) is not properly configured"
    exit 1
}

# Check for Claude in standard locations
Write-ColorLog -Level "INFO" -Message "Checking for Claude in WSL..."

# First check if it exists in /usr/local/bin (preferred path)
$localBinExists = wsl -e bash -c "test -f /usr/local/bin/claude && echo 'yes' || echo 'no'"

if ($localBinExists -eq "yes") {
    $claudePath = "/usr/local/bin/claude"
    Write-ColorLog -Level "SUCCESS" -Message "Found Claude at standard location: $claudePath"
} else {
    # Fall back to NVM path
    Write-ColorLog -Level "INFO" -Message "Checking NVM path for Claude..."
    $claudePath = wsl -e bash -c "source ~/.nvm/nvm.sh 2>/dev/null; which claude 2>/dev/null || echo ''"
    
    if ([string]::IsNullOrWhiteSpace($claudePath)) {
        Write-ColorLog -Level "ERROR" -Message "Could not find Claude in WSL. Please install it first."
        Write-ColorLog -Level "INFO" -Message "1. Install Claude: npm install -g @anthropic-ai/claude-code"
        exit 1
    }
    
    $claudePath = $claudePath.Trim()
    Write-ColorLog -Level "SUCCESS" -Message "Found Claude at NVM path: $claudePath"
    
    # Create symlink to make future access easier
    Write-ColorLog -Level "INFO" -Message "Creating symlink in /usr/local/bin for easier access..."
    Write-Host "You may be prompted for your WSL sudo password in the next step." -ForegroundColor Yellow
    Write-Host "IMPORTANT: When prompted, type your WSL sudo password and press Enter." -ForegroundColor Yellow
    
    # Use a more direct approach to ensure user sees the sudo prompt
    $symlinkCommand = "sudo ln -sf '$claudePath' /usr/local/bin/claude"
    wsl -e bash -c $symlinkCommand
    
    # Check if symlink creation was successful
    $symlinkCreated = wsl -e bash -c "test -f /usr/local/bin/claude && echo 'yes' || echo 'no'"
    if ($symlinkCreated -eq "yes") {
        Write-ColorLog -Level "SUCCESS" -Message "Created symlink at /usr/local/bin/claude"
        $claudePath = "/usr/local/bin/claude"
    } else {
        Write-ColorLog -Level "WARNING" -Message "Could not create symlink. Using direct NVM path."
    }
}

# Create directories
Write-ColorLog -Level "INFO" -Message "Creating required directories..."
if (-not (Test-Path ".claude-code")) {
    New-Item -Path ".claude-code" -ItemType Directory -Force | Out-Null
    Write-ColorLog -Level "SUCCESS" -Message "Created .claude-code directory."
}

# Update .gitignore
Write-ColorLog -Level "INFO" -Message "Updating .gitignore..."
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore" -Raw -ErrorAction SilentlyContinue
    
    # Create an array to track what needs to be added
    $addEntries = @()
    
    # Check for required entries
    if (-not ($gitignoreContent -match "(?m)^/?\.claude-code/?$")) {
        $addEntries += "/.claude-code/"
    }
    
    if (-not ($gitignoreContent -match "(?m)^/?install-.*\.ps1$")) {
        $addEntries += "/install-*.ps1"
    }
    
    # Update .gitignore if needed
    if ($addEntries.Count -gt 0) {
        $newContent = $gitignoreContent.TrimEnd()
        if (-not ($newContent -match "# Claude Code Review files")) {
            $newContent += "`n`n# Claude Code Review files"
        }
        foreach ($entry in $addEntries) {
            $newContent += "`n$entry"
            Write-ColorLog -Level "SUCCESS" -Message "Added $entry to .gitignore"
        }
        [System.IO.File]::WriteAllText((Join-Path -Path (Get-Location) -ChildPath ".gitignore"), $newContent)
    }
} else {
    # Create new .gitignore
    $gitignoreContent = "# Claude Code Review files`n/.claude-code/`n/install-*.ps1"
    [System.IO.File]::WriteAllText((Join-Path -Path (Get-Location) -ChildPath ".gitignore"), $gitignoreContent)
    Write-ColorLog -Level "SUCCESS" -Message "Created .gitignore with Claude Code Review exclusions"
}

# Create config.json
Write-ColorLog -Level "INFO" -Message "Creating configuration file..."
if (-not (Test-Path ".claude-code\config.json")) {
    $configJson = @"
{
    "enabledHooks": ["pre-commit"],
    "fileTypes": [".ts", ".js", ".java", ".cs", ".py", ".rb", ".go", ".php", ".css", ".html", ".jsx", ".tsx", ".groovy", ".gsp", ".swift", ".kt", ".c", ".cpp", ".h", ".sh", ".ps1", ".yml", ".yaml", ".json", ".xml"],
    "excludePaths": ["node_modules/", "dist/", "target/", "bin/", "obj/", "__pycache__/", "build/", ".gradle/", "venv/", "env/", ".venv/", ".env/", "packages/", "vendor/", "bower_components/"],
    "claudePath": "$claudePath"
}
"@

    # Create a detailed review prompt
    $promptContent = @"
# Code Review

You are an expert code reviewer. I need you to review the following code changes. This is a pre-commit review to catch issues before they're committed.

## Your Task
Please review the following git diff and identify:
1. Potential bugs or logical errors
2. Memory leaks (especially unsubscribed observables and event listeners)
3. Performance issues or inefficient code
4. Breaking changes that could affect other parts of the application
5. Best practice violations or maintainability concerns
6. Security implications

## Review Output Format
Please provide your review in this format:

1. First, a 2-3 sentence summary of the changes
2. A list of issues found, each with:
   - Severity (CRITICAL, HIGH, MEDIUM, LOW)
   - File and line number
   - Brief explanation of the issue
   - Suggested fix
3. Any positive aspects of the code changes

Focus on being concise and actionable. Developers will be seeing this at commit time.
"@
    
    # Use UTF-8 encoding without BOM
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllText((Join-Path -Path (Get-Location) -ChildPath ".claude-code\config.json"), $configJson, $Utf8NoBomEncoding)
    
    # Create the prompt.txt file
    $promptPath = (Join-Path -Path (Get-Location) -ChildPath ".claude-code\prompt.txt")
    [System.IO.File]::WriteAllText($promptPath, $promptContent, $Utf8NoBomEncoding)
    Write-ColorLog -Level "SUCCESS" -Message "Created prompt.txt file with detailed review instructions"
    Write-ColorLog -Level "SUCCESS" -Message "Created config.json file with Claude path: $claudePath"
}

# Create the pre-commit hook script (absolute simplest approach)
Write-ColorLog -Level "INFO" -Message "Creating pre-commit hook script..."

# Create pre-commit hook content without any temp files
$preCommitHook = @'
#!/bin/sh
# Simplest possible pre-commit hook for Claude Code Review

echo "[INFO] Running Claude Code Review pre-commit hook..."

# Run Claude using WSL with direct piping - no temp files needed
if [ -f ".claude-code/prompt.txt" ]; then
    echo "[INFO] Using prompt from .claude-code/prompt.txt"
    
    # Read prompt file into a variable
    PROMPT_CONTENT=$(cat ".claude-code/prompt.txt")
    
    # Pipe git diff directly to Claude with WSL
    git diff --staged | wsl bash -c "source ~/.nvm/nvm.sh && CLAUDE_PATH -p \"$PROMPT_CONTENT\""
else
    echo "[INFO] Using default prompt"
    git diff --staged | wsl bash -c "source ~/.nvm/nvm.sh && CLAUDE_PATH -p \"Review this code diff for issues. Provide: 1) Summary 2) Issues with severity 3) Positive aspects\""
fi

echo "[INFO] To commit anyway, use: git commit --no-verify"
exit 1  # Block commit
'@

# Replace placeholder with actual claude path
$preCommitHook = $preCommitHook.Replace("CLAUDE_PATH", $claudePath)

# Ensure the hooks directory exists
if (-not (Test-Path ".git\hooks")) {
    New-Item -Path ".git\hooks" -ItemType Directory -Force | Out-Null
    Write-ColorLog -Level "INFO" -Message "Created .git/hooks directory"
}

# Create the pre-commit hook with Unix line endings
$gitHooksDir = Join-Path -Path (Get-Location) -ChildPath ".git\hooks"
$preCommitPath = Join-Path -Path $gitHooksDir -ChildPath "pre-commit"
Create-UnixFile -Path $preCommitPath -Content $preCommitHook
Write-ColorLog -Level "SUCCESS" -Message "Created pre-commit hook script."

# Configure Git to use the standard hooks directory
Write-ColorLog -Level "INFO" -Message "Configuring Git to use standard hooks directory..."
git config core.hooksPath .git/hooks
Write-ColorLog -Level "SUCCESS" -Message "Git configured to use .git/hooks directory"

Write-ColorLog -Level "SUCCESS" -Message "Installation Complete!"
Write-ColorLog -Level "SUCCESS" -Message "Claude Code Review Git hooks have been installed."
Write-ColorLog -Level "INFO" -Message "You can now use Git from Windows, and hooks will run Claude in WSL."

Write-Host "`n===== IMPORTANT INSTRUCTIONS ====="
Write-Host "To bypass the pre-commit hook: git commit --no-verify"
Write-Host "To disable hooks: Edit .claude-code\config.json and remove pre-commit from enabledHooks"
Write-Host "===== END INSTRUCTIONS =====`n"