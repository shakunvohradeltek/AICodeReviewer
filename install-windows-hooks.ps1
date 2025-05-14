# Claude Code Review Git Hooks Installation Script for Windows
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
        Write-ColorLog -Level "ERROR" -Message "Windows Subsystem for Linux (WSL) is not installed or not configured."
        Write-ColorLog -Level "INFO" -Message "Please install WSL by running: wsl --install"
        Write-ColorLog -Level "INFO" -Message "After installing WSL, install Ubuntu or another Linux distribution from the Microsoft Store."
        Write-ColorLog -Level "INFO" -Message "Then restart your computer and run this script again."
        exit 1
    }
    Write-ColorLog -Level "SUCCESS" -Message "WSL is installed and ready."
} catch {
    Write-ColorLog -Level "ERROR" -Message "Windows Subsystem for Linux (WSL) is not installed or not properly configured."
    Write-ColorLog -Level "INFO" -Message "Please install WSL by running: wsl --install"
    Write-ColorLog -Level "INFO" -Message "After installing WSL, install Ubuntu or another Linux distribution from the Microsoft Store."
    Write-ColorLog -Level "INFO" -Message "Then restart your computer and run this script again."
    exit 1
}

# Git in WSL is optional for this approach - we'll use Windows Git with the hooks
Write-ColorLog -Level "INFO" -Message "Checking for Git in WSL..."
$gitInWSL = wsl which git 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-ColorLog -Level "INFO" -Message "Git is not installed in WSL, but that's optional for this approach."
    Write-ColorLog -Level "INFO" -Message "We'll be using Windows Git with Claude in WSL."
} else {
    Write-ColorLog -Level "SUCCESS" -Message "Git is also installed in WSL: $gitInWSL"
}

# Check for Claude Code CLI in WSL - with comprehensive detection
Write-ColorLog -Level "INFO" -Message "Checking for Claude Code CLI in WSL..."

# Try multiple approaches to find Claude in WSL
$claudeFound = $false
$claudePath = ""

# Simple approach to check both paths that are known to work
# Check both /usr/local/bin/claude and NVM paths with detected Node.js version
Write-ColorLog -Level "INFO" -Message "Checking known paths for Claude..."

# First check if Claude is in standard PATH (your machine)
$claudeInWSL = wsl bash -c "which claude 2>/dev/null || echo ''"
if ($claudeInWSL -and $claudeInWSL -ne '') {
    $claudeFound = $true
    $claudePath = $claudeInWSL.Trim()
    Write-ColorLog -Level "SUCCESS" -Message "Found Claude Code CLI in PATH: $claudePath"
    
    # Test Claude CLI
    Write-ColorLog -Level "INFO" -Message "Testing Claude CLI in WSL..."
    $claudeVersion = wsl claude --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ColorLog -Level "WARNING" -Message "Claude Code CLI found but not working properly."
    } else {
        Write-ColorLog -Level "SUCCESS" -Message "Claude CLI in WSL is working: $claudeVersion"
    }
}

# Check NVM path (where Claude is actually found in this system)
if (-not $claudeFound) {
    Write-ColorLog -Level "INFO" -Message "Checking NVM path for Claude..."
    
    # Dynamically detect Node.js version instead of hardcoding
    $nodeVersion = wsl bash -c "node --version 2>/dev/null | tr -d 'v' || echo ''" 
    if ($nodeVersion -eq "") {
        Write-ColorLog -Level "INFO" -Message "Node.js not found in WSL or version cannot be detected"
    } else {
        Write-ColorLog -Level "INFO" -Message "Detected Node.js version: $nodeVersion"
        $nvmClaudePath = "~/.nvm/versions/node/v$nodeVersion/bin/claude"
        Write-ColorLog -Level "INFO" -Message "Testing dynamic NVM path: $nvmClaudePath"
        $claudeCheck = wsl test -f $nvmClaudePath 2>&1
        if ($LASTEXITCODE -eq 0) {
            $claudeFound = $true
            $claudePath = $nvmClaudePath
            Write-ColorLog -Level "SUCCESS" -Message "Found Claude Code CLI in NVM path: $claudePath"
            
            # Test Claude CLI with the specific path
            Write-ColorLog -Level "INFO" -Message "Testing Claude CLI in WSL using NVM path..."
            $claudeVersion = wsl bash -c "$nvmClaudePath --version" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-ColorLog -Level "WARNING" -Message "Claude Code CLI found but not working properly at NVM path. Error: $claudeVersion"
                # Try with different quoting
                $claudeVersion = wsl bash -c "'$nvmClaudePath' --version" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorLog -Level "SUCCESS" -Message "Claude CLI in WSL is working with different quoting: $claudeVersion"
                }
            } else {
                Write-ColorLog -Level "SUCCESS" -Message "Claude CLI in WSL is working at NVM path: $claudeVersion"
            }
        }
    }
}

# Check /usr/local/bin explicitly (your machine)
if (-not $claudeFound) {
    Write-ColorLog -Level "INFO" -Message "Checking /usr/local/bin for Claude..."
    $localBinClaudePath = "/usr/local/bin/claude"
    $claudeCheck = wsl test -f $localBinClaudePath 2>&1
    if ($LASTEXITCODE -eq 0) {
        $claudeFound = $true
        $claudePath = $localBinClaudePath
        Write-ColorLog -Level "SUCCESS" -Message "Found Claude Code CLI in /usr/local/bin: $claudePath"
        
        # Test Claude CLI
        Write-ColorLog -Level "INFO" -Message "Testing Claude CLI in WSL..."
        $claudeVersion = wsl $localBinClaudePath --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ColorLog -Level "WARNING" -Message "Claude Code CLI found but not working properly at this path."
        } else {
            Write-ColorLog -Level "SUCCESS" -Message "Claude CLI in WSL is working: $claudeVersion"
        }
    }
}

# If still not found, prompt for installation
if (-not $claudeFound) {
    Write-ColorLog -Level "ERROR" -Message "Claude Code CLI not found in WSL."
    Write-ColorLog -Level "INFO" -Message "Please install it in your WSL environment using:"
    Write-ColorLog -Level "INFO" -Message "wsl npm install -g @anthropic-ai/claude-code"
    Write-ColorLog -Level "INFO" -Message "If npm is not installed in WSL, first run: wsl sudo apt update && wsl sudo apt install -y nodejs npm"
    Write-ColorLog -Level "INFO" -Message "Then run this script again."
    exit 1
}

# Create directories
Write-ColorLog -Level "INFO" -Message "Creating required directories..."
if (-not (Test-Path ".hooks")) {
    New-Item -Path ".hooks" -ItemType Directory -Force | Out-Null
    Write-ColorLog -Level "SUCCESS" -Message "Created .hooks directory."
}

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
    if (-not ($gitignoreContent -match "(?m)^/?\.hooks/?$")) {
        $addEntries += "/.hooks/"
    }
    
    if (-not ($gitignoreContent -match "(?m)^/?\.claude-code/?$")) {
        $addEntries += "/.claude-code/"
    }
    
    if (-not ($gitignoreContent -match "(?m)^/?install-windows-hooks.*\.ps1$")) {
        $addEntries += "/install-windows-hooks*.ps1"
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
    $gitignoreContent = "# Claude Code Review files`n/.hooks/`n/.claude-code/`n/install-windows-hooks*.ps1"
    [System.IO.File]::WriteAllText((Join-Path -Path (Get-Location) -ChildPath ".gitignore"), $gitignoreContent)
    Write-ColorLog -Level "SUCCESS" -Message "Created .gitignore with Claude Code Review exclusions"
}

# Create config file
Write-ColorLog -Level "INFO" -Message "Creating configuration file..."

# Verify Claude is working in WSL as a final check
Write-ColorLog -Level "INFO" -Message "Performing final verification of Claude in WSL..."

# Check what Windows user we're running as to construct the correct path
$windowsUser = $env:USERNAME
Write-ColorLog -Level "INFO" -Message "Detected Windows username: $windowsUser" 

# Check for required WSL dependencies first
Write-ColorLog -Level "INFO" -Message "Checking for required dependencies in WSL..."
$nodeInstalled = wsl bash -c "command -v node > /dev/null 2>&1 && echo 'yes' || echo 'no'"
$npmInstalled = wsl bash -c "command -v npm > /dev/null 2>&1 && echo 'yes' || echo 'no'"

if ($nodeInstalled -eq "no" -or $npmInstalled -eq "no") {
    Write-ColorLog -Level "WARNING" -Message "Node.js or npm is missing in WSL. This is required for Claude to work."
    Write-ColorLog -Level "INFO" -Message "Please run the following commands in WSL to install Node.js and npm:"
    Write-ColorLog -Level "INFO" -Message "sudo apt update && sudo apt install -y nodejs npm"
    Write-ColorLog -Level "INFO" -Message "After installing, run this script again."
    Write-ColorLog -Level "WARNING" -Message "Continuing setup, but note that Claude may not run correctly without Node.js and npm installed."
}

# Map the Windows username to a WSL username - get the actual Linux username
$wslUsername = (wsl whoami).Trim()
if ($LASTEXITCODE -eq 0 -and $wslUsername -ne "") {
    # Found the WSL username
    Write-ColorLog -Level "SUCCESS" -Message "Detected WSL username: $wslUsername"
    $wslHomeDir = "/home/$wslUsername"
} else {
    # Fall back to default if we can't detect it
    $wslHomeDir = "/home/spworkeradm"
    Write-ColorLog -Level "WARNING" -Message "Could not detect WSL username, using default: $wslHomeDir"
}
Write-ColorLog -Level "INFO" -Message "Using WSL home directory: $wslHomeDir"

# First try the NVM path with dynamically detected Node.js version
# Use ABSOLUTE path for reliability with Windows Git/WSL integration
$nodeVersion = wsl bash -c "node --version 2>/dev/null | tr -d 'v\n' || echo ''" 
if ($nodeVersion -eq "") {
    Write-ColorLog -Level "INFO" -Message "Node.js not found in WSL or version cannot be detected"
    # Fall back to checking Claude in PATH since node version can't be detected
    $nvmClaudePath = "$wslHomeDir/.nvm/versions/node/*/bin/claude"
} else {
    Write-ColorLog -Level "INFO" -Message "Detected Node.js version: $nodeVersion"
    $nvmClaudePath = "$wslHomeDir/.nvm/versions/node/v$nodeVersion/bin/claude"
}

Write-ColorLog -Level "INFO" -Message "Testing Claude at dynamic NVM path: $nvmClaudePath..."
$claudeNvmCheck = wsl bash -c "test -f $nvmClaudePath && $nvmClaudePath --version 2>&1 || echo 'Not found'" 
if ($claudeNvmCheck -and $claudeNvmCheck -ne 'Not found' -and -not ($claudeNvmCheck -match "command not found")) {
    Write-ColorLog -Level "SUCCESS" -Message "Claude is properly installed and working in WSL NVM path: $claudeNvmCheck"
    # If Claude worked, use the ABSOLUTE NVM path for a more reliable config
    $claudePath = $nvmClaudePath
    Write-ColorLog -Level "INFO" -Message "Using absolute NVM Claude path: $claudePath"
} else {
    # Try the standard approach as fallback
    Write-ColorLog -Level "INFO" -Message "Claude not found at dynamic NVM path, trying PATH lookup..."
    
    # Construct a PATH that includes potential NVM paths
    # We'll use a separate bash script to avoid PowerShell string interpolation issues
    $nvmPathScript = @'
#!/bin/bash
PATH_WITH_NVM="/usr/local/bin:/usr/bin:/bin"
NODE_VERSION=$(node --version 2>/dev/null | tr -d 'v\n' || echo "")

if [ -n "$NODE_VERSION" ]; then
    PATH_WITH_NVM="$PATH_WITH_NVM:$HOME/.nvm/versions/node/v$NODE_VERSION/bin"
else
    PATH_WITH_NVM="$PATH_WITH_NVM:$HOME/.nvm/versions/node/*/bin"
fi

export PATH="$PATH_WITH_NVM:$PATH"
'@
    $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".sh"
    $nvmPathScript | Out-File -Encoding UTF8 $tempScriptPath
    $wslTempPath = wsl wslpath -u "'$tempScriptPath'"
    
    Write-ColorLog -Level "INFO" -Message "Testing Claude with dynamic PATH script at: $wslTempPath"
    $claudeVersionCheck = wsl bash -c "chmod +x $wslTempPath && source $wslTempPath && claude --version 2>&1"
    if ($LASTEXITCODE -eq 0) {
        Write-ColorLog -Level "SUCCESS" -Message "Claude is properly installed and working in WSL: $claudeVersionCheck"
        # If Claude worked, find its ABSOLUTE path for a more reliable config
        $exactClaudePath = wsl bash -c "chmod +x $wslTempPath && source $wslTempPath && which claude 2>/dev/null | xargs readlink -f || echo ''"
        if ($exactClaudePath -and $exactClaudePath -ne "") {
            $claudePath = $exactClaudePath.Trim()
            Write-ColorLog -Level "INFO" -Message "Using exact absolute Claude path: $claudePath"
        } else {
            # If we can't get the exact path, but Claude works in PATH, use 'claude' and rely on PATH
            $claudePath = "claude"
            Write-ColorLog -Level "INFO" -Message "Using Claude from PATH: $claudePath"
        }
    } else {
        Write-ColorLog -Level "WARNING" -Message "Claude CLI check failed in WSL: $claudeVersionCheck"
        Write-ColorLog -Level "WARNING" -Message "Your dev team will need to install Claude CLI in WSL with: npm install -g @anthropic-ai/claude-code"
        # Set a path that will be expanded when used
        if ($nodeVersion -ne "") {
            $claudePath = "$wslHomeDir/.nvm/versions/node/v$nodeVersion/bin/claude"
        } else {
            $claudePath = "claude"
        }
        Write-ColorLog -Level "INFO" -Message "Using fallback Claude path: $claudePath"
    }
    
    # Clean up temporary script
    Remove-Item -Path $tempScriptPath -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path ".claude-code\config.json")) {
    # Use the dynamically detected path based on Node.js version
    if ($nodeVersion -ne "") {
        $dynamicClaudePath = "$wslHomeDir/.nvm/versions/node/v$nodeVersion/bin/claude"
    } else {
        # If we couldn't detect Node.js version, use the claude path we found earlier
        $dynamicClaudePath = $claudePath
    }
    
    # Log the path being used
    Write-ColorLog -Level "INFO" -Message "Setting config.json with claude path: $dynamicClaudePath"
    
    $configJson = @"
{
    "enabledHooks": ["pre-commit"],
    "fileTypes": [".ts", ".js", ".java", ".cs", ".py", ".rb", ".go", ".php", ".css", ".html", ".jsx", ".tsx", ".groovy", ".gsp", ".swift", ".kt", ".c", ".cpp", ".h", ".sh", ".ps1", ".yml", ".yaml", ".json", ".xml"],
    "excludePaths": ["node_modules/", "dist/", "target/", "bin/", "obj/", "__pycache__/", "build/", ".gradle/", "venv/", "env/", ".venv/", ".env/", "packages/", "vendor/", "bower_components/"],
    "claudePath": "$dynamicClaudePath"
}
"@

# Create a detailed review prompt in a separate text file
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

# Create the pre-commit hook script in WSL format
Write-ColorLog -Level "INFO" -Message "Creating the pre-commit hook script for WSL..."

$preCommitHookContent = @'
#!/bin/bash
# Pre-commit hook for Claude Code Review in WSL

# Get the project root directory
PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd "$PROJECT_ROOT" || exit 1

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

log_message "INFO" "Running pre-commit hook from WSL"

# Load configuration
config_file="./.claude-code/config.json"
if [ -f "$config_file" ]; then
    # Check if pre-commit is enabled
    if ! grep -q '"enabledHooks".*"pre-commit"' "$config_file"; then
        log_message "INFO" "Pre-commit hook is disabled in configuration. Skipping review."
        exit 0
    fi
    
    # Extract file types to review
    file_types=$(grep -o '"fileTypes":[^]]*]' "$config_file" | grep -o '"[^"]*"' | sed 's/"//g' | tr '\n' '|' | sed 's/|$//' || echo ".ts|.js|.java|.css|.html")
    if [ -z "$file_types" ]; then
        file_types=".ts|.js|.java|.css|.html"
    fi
    
    # Extract paths to exclude
    exclude_paths=$(grep -o '"excludePaths":[^]]*]' "$config_file" | grep -o '"[^"]*"' | sed 's/"//g' | tr '\n' '|' | sed 's/|$//' || echo "node_modules/|dist/|target/")
    if [ -z "$exclude_paths" ]; then
        exclude_paths="node_modules/|dist/|target/"
    fi
    
    # Extract claude path from config
    claude_path=$(grep -o '"claudePath":"[^"]*"' "$config_file" | sed 's/"claudePath":"//g' | sed 's/"//g' || echo "")
    
    # Extract review prompt
    review_prompt=$(grep -o '"reviewPrompt":"[^"]*"' "$config_file" | sed 's/"reviewPrompt":"//g' | sed 's/"//g' || echo "Review the following code changes for bugs, memory leaks, breaking changes, and best practices issues.")
    if [ -z "$review_prompt" ]; then
        review_prompt="You are an expert code reviewer. Review the following code changes for potential issues including bugs, memory leaks, breaking changes, and best practice violations. Consider performance impacts, maintainability concerns, and security implications. Provide a concise summary and list any critical issues found with clear explanations."
    fi
else
    # Default values if config file not found
    log_message "WARNING" "Configuration file not found. Using default settings."
    file_types=".ts|.js|.java|.css|.html"
    exclude_paths="node_modules/|dist/|target/"
    claude_path=""
    review_prompt="You are an expert code reviewer. Review the following code changes for potential issues including bugs, memory leaks, breaking changes, and best practice violations. Consider performance impacts, maintainability concerns, and security implications. Provide a concise summary and list any critical issues found with clear explanations."
fi

log_message "INFO" "🔍 Running Claude Code Review on staged changes..."

# Get all staged files matching our file types
log_message "INFO" "Looking for staged files with extensions: $file_types"
log_message "INFO" "Excluding paths matching: $exclude_paths"

# Get all staged files matching our file types
if [ -n "$file_types" ]; then
    staged_files=$(git diff --staged --name-only --diff-filter=ACMR 2>/dev/null || git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | grep -E "($file_types)$" || true)
else
    staged_files=$(git diff --staged --name-only --diff-filter=ACMR 2>/dev/null || git diff --cached --name-only --diff-filter=ACMR 2>/dev/null)
fi

# Debug information about git diff output
git_diff_files=$(git diff --staged --name-only 2>/dev/null || git diff --cached --name-only 2>/dev/null)
log_message "INFO" "All staged files: $git_diff_files"

# Exclude paths if needed
if [ -n "$exclude_paths" ] && [ -n "$staged_files" ]; then
    staged_files=$(echo "$staged_files" | grep -v -E "($exclude_paths)" || true)
fi

if [ -z "$staged_files" ]; then
    log_message "INFO" "No relevant staged files found. Skipping review."
    exit 0
fi

log_message "SUCCESS" "Found staged files to review:"
echo "$staged_files"

# Get git diff for context
git_diff=$(git diff --staged 2>/dev/null || git diff --cached 2>/dev/null)
if [ -z "$git_diff" ]; then
    log_message "INFO" "No changes detected. Skipping review."
    exit 0
fi

# Check if prompt.txt exists and use it
prompt_file="./.claude-code/prompt.txt"
if [ -f "$prompt_file" ]; then
    log_message "INFO" "Using prompt from prompt.txt"
else
    # Create a temporary file for the prompt as fallback
    log_message "INFO" "prompt.txt not found, using default prompt"
    prompt_file=$(mktemp)
    cat > "$prompt_file" << CLAUDE_PROMPT
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

## Git Diff
$git_diff

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
CLAUDE_PROMPT
    temp_prompt_file=true
fi

# Run claude with the prepared prompt
log_message "INFO" "Executing Claude CLI to review code..."

# Check multiple locations for Claude
log_message "INFO" "Checking for Claude in multiple locations..."

# Try predefined paths first for better reliability
claude_found=false
claude_path_to_use=""

# First try to detect Node.js version dynamically
node_version=$(node --version 2>/dev/null | tr -d 'v\n' || echo "")
if [ -n "$node_version" ]; then
    # If we can detect Node.js version, check that specific NVM path
    log_message "INFO" "Detected Node.js version: $node_version"
    if [ -f ~/.nvm/versions/node/v$node_version/bin/claude ]; then
        claude_found=true
        claude_path_to_use=~/.nvm/versions/node/v$node_version/bin/claude
        log_message "SUCCESS" "Found Claude at NVM path with detected Node version: $claude_path_to_use"
    fi
else
    # If we can't detect Node.js version, try to find Claude in NVM directory wildcards
    log_message "INFO" "Could not detect Node.js version, checking NVM path patterns"
    # Try to find Claude in any NVM path
    nvm_claude_path=$(find ~/.nvm/versions/node -name claude -path "*/bin/claude" 2>/dev/null | head -n 1)
    if [ -n "$nvm_claude_path" ]; then
        claude_found=true
        claude_path_to_use=$nvm_claude_path
        log_message "SUCCESS" "Found Claude at NVM path by search: $claude_path_to_use"
    fi
fi

# Then check /usr/local/bin path if not found yet
if [ "$claude_found" = false ] && [ -f /usr/local/bin/claude ]; then
    claude_found=true
    claude_path_to_use=/usr/local/bin/claude
    log_message "SUCCESS" "Found Claude at /usr/local/bin: $claude_path_to_use"
fi

# Then check standard PATH if not found yet
if [ "$claude_found" = false ] && command -v claude &> /dev/null; then
    claude_found=true
    claude_path_to_use=$(which claude)
    log_message "SUCCESS" "Found Claude in PATH: $claude_path_to_use"
fi

# Try to use the specific Claude path from config if we haven't found it yet
if [ "$claude_found" = false ] && [ -n "$claude_path" ] && [ -f "${claude_path/#\~/$HOME}" ]; then
    claude_found=true
    claude_path_to_use="${claude_path/#\~/$HOME}"
    log_message "SUCCESS" "Found Claude at config path: $claude_path_to_use"
fi

# If Claude still not found, try harder to find it in any NVM directory
if [ "$claude_found" = false ]; then
    # This is a more aggressive search in case our simpler methods failed
    log_message "INFO" "Searching all Node.js version directories for Claude..."
    # Try to find Claude in any Node version directory with a recursive find
    nvm_claude_path=$(find ~/.nvm -path "*/bin/claude" -type f 2>/dev/null | head -n 1)
    if [ -n "$nvm_claude_path" ]; then
        claude_found=true
        claude_path_to_use=$nvm_claude_path
        log_message "SUCCESS" "Found Claude through full NVM search: $claude_path_to_use"
    fi
fi

# Now use the Claude path we found
if [ "$claude_found" = true ]; then
    log_message "INFO" "Using Claude at: $claude_path_to_use"
    log_message "INFO" "Running Claude with: $claude_path_to_use -p < $prompt_file"
    "$claude_path_to_use" -p < "$prompt_file" > /tmp/claude_result 2>&1
    claude_exit_code=$?
    review_result=$(cat /tmp/claude_result)
    rm -f /tmp/claude_result
else
    # Claude not found, provide helpful error message
    log_message "ERROR" "Claude CLI not found in any location"
    log_message "ERROR" "Please install Claude CLI with: npm install -g @anthropic-ai/claude-code"
    review_result="Error: Claude CLI not found. Please install it with npm install -g @anthropic-ai/claude-code"
    claude_exit_code=1
fi

# Clean up temp file only if we created one
if [ "${temp_prompt_file:-false}" = true ]; then
    rm -f "$prompt_file"
fi

# Check if Claude provided a meaningful response
if [[ $claude_exit_code -ne 0 ]] || [[ "$review_result" == *"Error running Claude Code CLI"* ]]; then
    log_message "ERROR" "Error running Claude Code CLI (exit code: $claude_exit_code). Output:"
    log_message "ERROR" "$review_result"
    
    # Provide detailed help on fixing the issue
    log_message "INFO" "Troubleshooting steps:"
    log_message "INFO" "1. Verify Claude CLI is installed: npm install -g @anthropic-ai/claude-code"
    log_message "INFO" "2. Check your Claude API key is set: claude config"
    log_message "INFO" "3. Test Claude CLI: claude --version"
    log_message "INFO" "4. Update config if needed: edit .claude-code/config.json with correct claudePath"
    
    # Debug info
    PATH_INFO=$(echo $PATH)
    CLAUDE_WHICH=$(which claude 2>/dev/null || echo "Not found")
    log_message "INFO" "Current PATH: $PATH_INFO"
    log_message "INFO" "Claude location: $CLAUDE_WHICH"
    
    # Ask developer if they want to proceed despite the error
    echo ""
    echo "Do you want to proceed with this commit despite the error? (y/n)"
    
    # Debug info
    log_message "INFO" "Waiting for user input... (defaulting to 'y' in 30 seconds to avoid blocking)"
    
    # Set a default answer of 'n' after 30 seconds to be less disruptive
    if [ -t 0 ]; then  # Check if stdin is a terminal
        # Interactive mode with timeout
        read -t 30 -n 1 -r REPLY || REPLY="n"
    else
        # Non-interactive mode - default to yes to avoid blocking
        REPLY="n"
    fi
    
    echo ""
    log_message "INFO" "User input received: '$REPLY'"
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_message "WARNING" "Proceeding with commit despite Claude CLI error."
        exit 0
    else
        log_message "INFO" "Commit aborted due to Claude CLI error."
        exit 1
    fi
fi

log_message "SUCCESS" "Code review completed successfully."

# Display results to developer
echo "==============================================="
echo "📋 Claude Code Review Results"
echo "==============================================="
echo "$review_result"
echo "==============================================="

# Display results to developer
log_message "INFO" "Code review completed. To commit anyway, use: git commit --no-verify"
log_message "INFO" "Commit aborted to allow review of changes. Please address any issues if needed."

# Always exit with error to block commit
exit 1
'@

# Write the WSL hook script with LF line endings and NO BOM
$utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllText((Join-Path -Path (Get-Location) -ChildPath ".hooks\pre-commit"), $preCommitHookContent.Replace("`r`n", "`n"), $utf8NoBomEncoding)
Write-ColorLog -Level "SUCCESS" -Message "Created pre-commit hook for WSL."

# Make the hook executable in WSL - with proper path handling
$currentPath = Get-Location
$wslPath = wsl wslpath -u "'$currentPath/.hooks/pre-commit'" 2>&1
Write-ColorLog -Level "INFO" -Message "Converting path to WSL format: $wslPath"
wsl bash -c "chmod +x '$wslPath'"
Write-ColorLog -Level "SUCCESS" -Message "Made hook script executable in WSL."

# Create the Git hook scripts - using a different approach that works reliably with Git for Windows
Write-ColorLog -Level "INFO" -Message "Creating Git hook scripts..."

# This batch script definition will be replaced by the updated version below

# Create a separate PowerShell script for Claude code review
# Use the detected dynamic path that we already set above
# The dynamicClaudePath variable was already set based on detected Node.js version

$claudePsScript = @"
# PowerShell script for Claude Code Review
# Created by install-windows-hooks-fixed.ps1

Write-Host '[INFO] Claude Code Review pre-commit hook running...'
Write-Host '[INFO] Getting git diff and saving to temp file...'

# Get git diff and save to temp file
git diff --staged | Out-File -Encoding utf8 "$env:TEMP\git-diff.txt"

# Convert Windows temp path to WSL path
`$wslTempPath = (wsl wslpath -a "$env:TEMP\git-diff.txt") 2>&1
Write-Host "[INFO] Converted temp file path to WSL format: `$wslTempPath"

# Run Claude in WSL with the diff file
Write-Host '[INFO] Running Claude in WSL...'
# Use the dynamic path to Claude based on current user
`$claudePath = "$dynamicClaudePath" 
Write-Host "[INFO] Using Claude path: `$claudePath"

# Check if prompt.txt exists and use it
`$promptFile = ".\.claude-code\prompt.txt"
if (Test-Path `$promptFile) {
    Write-Host "`n========================================================"
    Write-Host "USING PROMPT FROM prompt.txt"
    Write-Host "========================================================`n"
    
    # Read the prompt from the file
    `$promptContent = Get-Content -Path `$promptFile -Raw
    
    # Save the prompt to a temporary file to avoid command-line escaping issues
    `$promptTempFile = [System.IO.Path]::GetTempFileName()
    `$promptContent | Out-File -Encoding utf8 `$promptTempFile
    `$wslPromptPath = (wsl wslpath -a "`$promptTempFile") 2>&1
    
    # Use WSL to read the content and pipe it directly to Claude
    `$claudeCommand = "wsl -e bash -c 'cat `$wslPromptPath | $dynamicClaudePath -p - < `$wslTempPath'"
} else {
    Write-Host "`n========================================================"
    Write-Host "USING DEFAULT PROMPT (prompt.txt not found)"
    Write-Host "========================================================`n"
    
    # Use default prompt
    `$claudeCommand = "wsl -e bash -c '$dynamicClaudePath -p ""Review this code diff for issues. Provide: 1) Summary 2) Issues with severity 3) Positive aspects"" < `$wslTempPath'"
}

Write-Host "[DEBUG] Running command: `$claudeCommand"
Invoke-Expression `$claudeCommand

# Clean up temporary prompt file if it exists
if (Test-Path Variable:promptTempFile) {
    if (Test-Path `$promptTempFile) {
        Remove-Item -Path `$promptTempFile -Force -ErrorAction SilentlyContinue
    }
}

# After showing the review, always block the commit
Write-Host ""
Write-Host "========================================================"
Write-Host "COMMIT BLOCKED BY POLICY"
Write-Host "This repository requires using git commit --no-verify"
Write-Host "to bypass the pre-commit hook and code review."
Write-Host "========================================================"

# Exit with error to block commit
exit 1
"@

# Write Claude PowerShell script file
$utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllText((Join-Path -Path (Get-Location) -ChildPath ".git\hooks\pre-commit-claude.ps1"), $claudePsScript, $utf8NoBomEncoding)
Write-ColorLog -Level "SUCCESS" -Message "Created pre-commit-claude.ps1 script."

# Create a simple batch script for compatibility
$batchScript = @"
@echo off
:: Windows bridge script for Claude Code Review
:: Created by install-windows-hooks-fixed.ps1

echo [INFO] Claude Code Review pre-commit hook triggered from Git
echo [INFO] Running pre-commit-claude.ps1 script...

:: Call the PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0pre-commit-claude.ps1"

:: Always block the commit explicitly, regardless of PowerShell exit code
echo.
echo ========================================================
echo COMMIT BLOCKED BY POLICY
echo This repository requires using git commit --no-verify
echo to bypass the pre-commit hook and code review.
echo ========================================================

:: Always exit with error to block commit
exit /b 1
"@

# Create the batch script file using ASCII encoding (no BOM)
[System.IO.File]::WriteAllText((Join-Path -Path (Get-Location) -ChildPath "pre-commit.bat"), $batchScript, [System.Text.ASCIIEncoding]::new())
Write-ColorLog -Level "SUCCESS" -Message "Created pre-commit.bat bridge script."

# Now create the shell script hook that Git will call (this is what Git looks for)
# Use the dynamically detected Node.js version
# We already have dynamicClaudePath set up above based on node version detection
$claudeNvmPath = $dynamicClaudePath
# Start with a template
$shellScriptTemplate = @'
#!/bin/sh
# Git pre-commit hook that calls Claude in WSL directly and always blocks commits

echo "Running Claude Code Review..."

# Check for required Node.js in WSL 
if ! wsl bash -c "command -v node > /dev/null 2>&1"; then
    echo "ERROR: Node.js is not installed in WSL. Claude requires Node.js to run."
    echo "Please run these commands in WSL to install Node.js and npm:"
    echo "  sudo apt update && sudo apt install -y nodejs npm"
    echo "After installing, try committing again."
    echo "To bypass this check and commit anyway, use: git commit --no-verify"
    exit 1
fi

# Use dynamic path to Claude based on current user
echo "Using Claude path: CLAUDE_PATH_PLACEHOLDER"

# Check if prompt.txt exists and use it
PROMPT_FILE="./.claude-code/prompt.txt"
if [ -f "$PROMPT_FILE" ]; then
    echo ""
    echo "========================================================"
    echo "USING PROMPT FROM prompt.txt"
    echo "========================================================"
    echo ""
    
    # Get the git diff and pipe it directly to Claude in WSL, using the prompt from the file
    PROMPT_CONTENT=$(cat "$PROMPT_FILE")
    git diff --staged | wsl bash -c "CLAUDE_PATH_PLACEHOLDER -p \"$PROMPT_CONTENT\""
else
    echo ""
    echo "========================================================"
    echo "USING DEFAULT PROMPT (prompt.txt not found)"
    echo "========================================================"
    echo ""
    
    # Use default prompt
    git diff --staged | wsl bash -c "CLAUDE_PATH_PLACEHOLDER -p 'Review this code diff for issues. Provide: 1) Summary 2) Issues with severity 3) Positive aspects'"
fi
CLAUDE_EXIT_CODE=$?

if [ $CLAUDE_EXIT_CODE -ne 0 ]; then
    echo "ERROR: Claude had an error (exit code $CLAUDE_EXIT_CODE)."
    echo "This might be due to missing Node.js or npm in your WSL environment."
    echo "Please check that both are installed by running these commands in WSL:"
    echo "  command -v node npm"
    echo "If missing, install with: sudo apt update && sudo apt install -y nodejs npm"
    echo "To bypass this check and commit anyway, use: git commit --no-verify"
    exit 1
fi

# After showing the review, always block the commit
echo ""
echo "========================================================"
echo "COMMIT BLOCKED BY POLICY"
echo "This repository requires using git commit --no-verify"
echo "to bypass the pre-commit hook and code review."
echo "========================================================"

# Always exit with error to block commit
exit 1
'@

# Replace the placeholder with the actual path
$shellScript = $shellScriptTemplate -replace "CLAUDE_PATH_PLACEHOLDER", $claudeNvmPath

# Ensure .git/hooks directory exists
if (-not (Test-Path ".git\hooks")) {
    New-Item -Path ".git\hooks" -ItemType Directory -Force | Out-Null
}

# Write the shell script with LF line endings and NO BOM
$utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllText((Join-Path -Path (Get-Location) -ChildPath ".git\hooks\pre-commit"), $shellScript.Replace("`r`n", "`n"), $utf8NoBomEncoding)
Write-ColorLog -Level "SUCCESS" -Message "Created shell script hook in .git\hooks\pre-commit."

# Copy the batch file to the hooks directory
Copy-Item -Path "pre-commit.bat" -Destination ".git\hooks\pre-commit.bat" -Force
Write-ColorLog -Level "SUCCESS" -Message "Copied batch file to .git\hooks\pre-commit.bat."

# Note about permissions - WSL can't change permissions on Windows filesystem
Write-ColorLog -Level "INFO" -Message "Setting up hook permissions..."

# Convert the path for reference
$currentPath = (Get-Location).Path
$fullHookPath = Join-Path -Path $currentPath -ChildPath ".git\hooks\pre-commit"
Write-ColorLog -Level "INFO" -Message "Windows hook path: $fullHookPath"

# Convert Windows path to WSL path for logging
$wslCmd = "wslpath -u '$fullHookPath'"
$wslPath = wsl bash -c $wslCmd 2>&1
Write-ColorLog -Level "INFO" -Message "WSL hook path: $wslPath"

# Remove read-only attributes to ensure files can be executed
cmd.exe /c attrib -r ".git\hooks\pre-commit" 2>&1 | Out-Null
cmd.exe /c attrib -r ".git\hooks\pre-commit.bat" 2>&1 | Out-Null
cmd.exe /c attrib -r ".hooks\pre-commit" 2>&1 | Out-Null
Write-ColorLog -Level "SUCCESS" -Message "Removed read-only attributes from hook files."

# Ensure no Byte Order Mark (BOM) in pre-commit files
$utf8WithoutBom = New-Object System.Text.UTF8Encoding $false
foreach ($hookFile in @(".git\hooks\pre-commit", ".hooks\pre-commit")) {
    try {
        $filePath = Join-Path -Path (Get-Location) -ChildPath $hookFile
        if (Test-Path $filePath) {
            # Read the file content as bytes to check for BOM safely
            $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
            $hasBom = $false
            
            # Check if it starts with UTF-8 BOM (EF BB BF)
            if ($fileBytes.Length -ge 3 -and $fileBytes[0] -eq 0xEF -and $fileBytes[1] -eq 0xBB -and $fileBytes[2] -eq 0xBF) {
                $hasBom = $true
                Write-ColorLog -Level "INFO" -Message "Found UTF-8 BOM in $hookFile, removing it"
                # Create new array without BOM
                $newBytes = New-Object byte[] ($fileBytes.Length - 3)
                [Array]::Copy($fileBytes, 3, $newBytes, 0, $fileBytes.Length - 3)
                [System.IO.File]::WriteAllBytes($filePath, $newBytes)
            }
            
            # Ensure the file has LF line endings (for shell scripts)
            $content = [System.IO.File]::ReadAllText($filePath)
            $newContent = $content.Replace("`r`n", "`n")
            if ($content -ne $newContent) {
                Write-ColorLog -Level "INFO" -Message "Converting CRLF to LF line endings in $hookFile"
                [System.IO.File]::WriteAllText($filePath, $newContent, $utf8WithoutBom)
            }
        }
    } catch {
        $errorMessage = $_.Exception.Message
        Write-ColorLog -Level "WARNING" -Message "Could not process $hookFile`: $errorMessage"
    }
}

# Note: We're not trying to change permissions because it's not allowed on Windows drives in WSL
Write-ColorLog -Level "INFO" -Message "Note: Cannot change permissions on Windows drives from WSL."
Write-ColorLog -Level "INFO" -Message "This is normal and Git will still be able to execute the script."

# Clean up the temporary batch file
Remove-Item -Path "pre-commit.bat" -Force
Write-ColorLog -Level "SUCCESS" -Message "Cleaned up temporary files."

# Configure Git to use the standard hooks directory for IDE compatibility
Write-ColorLog -Level "INFO" -Message "Configuring Git to use standard hooks directory..."
git config core.hooksPath .git/hooks
Write-ColorLog -Level "SUCCESS" -Message "Git configured to use .git/hooks directory"
Write-ColorLog -Level "INFO" -Message "This configuration ensures hooks work properly in IDEs like VSCode and IntelliJ"

# Automatically configure git safe.directory to prevent permission errors in WSL
$repoPath = (Get-Location).Path
$wslRepoPath = (wsl wslpath -u "'$repoPath'" 2>&1).Trim()
Write-ColorLog -Level "INFO" -Message "Configuring Git repository as safe directory: $wslRepoPath"
wsl git config --global --add safe.directory "$wslRepoPath" 2>&1 | Out-Null
Write-ColorLog -Level "SUCCESS" -Message "Git repository added to safe.directory list."

Write-ColorLog -Level "SUCCESS" -Message "Installation Complete!"
Write-ColorLog -Level "SUCCESS" -Message "Claude Code Review Git hooks have been installed."
Write-ColorLog -Level "INFO" -Message "You can now use Git from Windows, and hooks will run Claude in WSL."

# Tips and info
Write-Output "`n===== IMPORTANT INSTRUCTIONS FOR DEVELOPMENT TEAM ====="
Write-Output "Developers must follow these steps to make Claude Code Review work:"
Write-Output ""
Write-Output "1. PRE-REQUISITE: Make sure Node.js and npm are installed in WSL:"
Write-Output "   - Open WSL terminal (Windows Terminal with Ubuntu/WSL tab or run 'wsl' in cmd)"
Write-Output "   - Check if Node.js is installed: command -v node npm"
Write-Output "   - If not installed, run: sudo apt update && sudo apt install -y nodejs npm"
Write-Output "   - This is REQUIRED - Claude will not work without Node.js!"
Write-Output ""
Write-Output "2. MUST install Claude CLI in WSL:"
Write-Output "   - Open WSL terminal (Windows Terminal with Ubuntu/WSL tab or run 'wsl' in cmd)"
Write-Output "   - Run: npm install -g @anthropic-ai/claude-code"
Write-Output "   - Configure Claude: claude config"
Write-Output "   - Test with: claude --version"
Write-Output ""
Write-Output "3. If hooks don't run in your IDE (VSCode, IntelliJ, etc.):"
Write-Output "   - This script has configured Git for IDE compatibility with: git config core.hooksPath .git/hooks"
Write-Output "   - Verify with: git config core.hooksPath (should output .git/hooks)"
Write-Output "   - For some IDEs, you may need to restart the IDE after installation"
Write-Output "   - For IntelliJ: Settings -> Version Control -> Git -> verify 'Run Git hooks' is checked"
Write-Output "   - For VS Code: Try using the command palette to commit rather than GUI buttons"
Write-Output ""
Write-Output "4. If hooks don't run or you see path errors:"
Write-Output "   - Common error: '/usr/bin/env: node: No such file or directory'"
Write-Output "   - This means Node.js is missing! Install it first (see step 1)"
Write-Output "   - Make sure claude is in PATH: run 'wsl which claude'"
Write-Output "   - Update claude path in .claude-code/config.json if needed"
Write-Output "   - Check permissions: cmd.exe /c attrib -r .git\hooks\pre-commit .git\hooks\pre-commit.bat"
Write-Output "   - Re-run the installation script"
Write-Output ""
Write-Output "4. Bypass hook for a specific commit: git commit --no-verify"
Write-Output ""
Write-Output "5. Disable hooks entirely: Edit .claude-code\config.json and remove pre-commit from enabledHooks"
Write-Output ""
Write-Output "6. For more detailed debugging:"
Write-Output "   - Test wsl connection: wsl echo 'WSL is working'"
Write-Output "   - Check if Node.js is installed: wsl command -v node"
Write-Output "   - Check if Claude runs in WSL directly: wsl claude --version"
Write-Output "   - Verify temp directory: echo %TEMP% (Windows) or wsl bash -c 'echo \$TMPDIR' (WSL)"
Write-Output ""
Write-Output "7. Common issues and solutions:"
Write-Output "   - '/usr/bin/env: node: No such file or directory': Install Node.js in WSL"
Write-Output "   - 'claude not found': Install Claude CLI in WSL with npm"
Write-Output "   - Path errors: Use full paths in scripts and config"
Write-Output "   - Hook not running: Check Git hooks directory permissions"
Write-Output "   - WSL errors: Make sure WSL is properly installed and configured"
Write-Output ""
Write-Output "===== END INSTRUCTIONS ====="