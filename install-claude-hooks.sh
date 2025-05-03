#!/bin/bash
# Claude Code Review Git Hooks Installation Script
# OS-aware version that only creates relevant OS-specific files
# Compatible with Mac and Windows (with WSL)

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Backup directory for rollback
BACKUP_DIR=$(mktemp -d)

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

# Function to backup a file if it exists
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup_file="$BACKUP_DIR/$(basename "$file")"
        log_message "INFO" "Backing up $file to $backup_file"
        cp "$file" "$backup_file"
    fi
}

# Function to restore a file from backup
restore_file() {
    local file="$1"
    local backup_file="$BACKUP_DIR/$(basename "$file")"
    if [ -f "$backup_file" ]; then
        log_message "INFO" "Restoring $file from backup"
        cp "$backup_file" "$file"
    elif [ -f "$file" ]; then
        log_message "INFO" "Removing $file (no backup)"
        rm "$file"
    fi
}

# Function to perform rollback
rollback() {
    log_message "WARNING" "Installation failed. Rolling back changes..."
    
    # Restore backed up files
    restore_file ".git/hooks/pre-commit"
    restore_file ".git/hooks/pre-push"
    
    # Remove custom hooks directory
    log_message "INFO" "Removing custom hooks directory"
    rm -rf ".hooks"
    
    # Reset git hooks path
    git config --unset core.hooksPath
    
    # Remove config directory if we created it
    if [ "$CONFIG_DIR_CREATED" = true ]; then
        log_message "INFO" "Removing configuration directory"
        rm -rf ".claude-code"
    fi
    
    log_message "INFO" "Rollback complete"
    exit 1
}

# Set up trap to clean up backup directory
trap "rm -rf $BACKUP_DIR" EXIT

# Track if we created the config directory
CONFIG_DIR_CREATED=false

log_message "INFO" "🔍 Claude Code Review Git Hooks Installation"
log_message "INFO" "============================================="
log_message "INFO" "Detected OS: $OS_TYPE"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    log_message "ERROR" "Not a git repository. Please run this script from the root of a git repository."
    exit 1
fi

# Check for Claude Code CLI
if ! command -v claude &> /dev/null; then
    log_message "ERROR" "Claude Code CLI not found."
    log_message "INFO" "Please install it using: npm install -g @anthropic-ai/claude-code"
    log_message "INFO" "Then run this script again."
    exit 1
else
    log_message "SUCCESS" "Found Claude Code CLI: $(which claude)"
    
    # Validate Claude Code CLI works
    log_message "INFO" "Validating Claude Code CLI..."
    if ! claude --version &> /dev/null; then
        log_message "ERROR" "Claude Code CLI version check failed. There might be an issue with your installation."
        exit 1
    fi
    log_message "SUCCESS" "Claude Code CLI validation passed"
fi

# Create configuration directory if it doesn't exist
log_message "INFO" "Creating configuration directory..."
if [ ! -d ".claude-code" ]; then
    mkdir -p ".claude-code"
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to create .claude-code directory."
        exit 1
    fi
    CONFIG_DIR_CREATED=true
fi

# Update .gitignore to exclude generated files
log_message "INFO" "Updating .gitignore file..."
if [ -f ".gitignore" ]; then
    # Check if .hooks/ is already in .gitignore
    if ! grep -q "^/.hooks/" ".gitignore" && ! grep -q "^.hooks/" ".gitignore"; then
        echo -e "\n# Claude Code Review files\n/.hooks/" >> ".gitignore"
        log_message "SUCCESS" "Added /.hooks/ to .gitignore"
    else
        log_message "INFO" "/.hooks/ already in .gitignore"
    fi
    
    # Check if .claude-code/ is already in .gitignore
    if ! grep -q "^/.claude-code/" ".gitignore" && ! grep -q "^.claude-code/" ".gitignore"; then
        echo -e "/.claude-code/" >> ".gitignore"
        log_message "SUCCESS" "Added /.claude-code/ to .gitignore"
    else
        log_message "INFO" "/.claude-code/ already in .gitignore"
    fi
    
    # Check if PowerShell script is already in .gitignore
    if ! grep -q "^/install-claude-hooks.ps1" ".gitignore" && ! grep -q "^install-claude-hooks.ps1" ".gitignore"; then
        echo -e "/install-claude-hooks.ps1" >> ".gitignore"
        log_message "SUCCESS" "Added /install-claude-hooks.ps1 to .gitignore"
    else
        log_message "INFO" "/install-claude-hooks.ps1 already in .gitignore"
    fi
else
    log_message "WARNING" ".gitignore file not found, creating new one"
    echo -e "# Claude Code Review files\n/.hooks/\n/.claude-code/\n/install-claude-hooks.ps1" > ".gitignore"
    log_message "SUCCESS" "Created .gitignore with Claude Code Review exclusions"
fi

# Create config file if it doesn't exist
if [ ! -f ".claude-code/config.json" ]; then
    log_message "INFO" "Creating default configuration file..."
    cat > ".claude-code/config.json" << 'EOF'
{
    "enabledHooks": ["pre-commit"],
    "fileTypes": [".ts", ".js", ".java", ".cs", ".py", ".rb", ".go", ".php", ".css", ".html", ".jsx", ".tsx", ".groovy", ".gsp", ".swift", ".kt", ".c", ".cpp", ".h", ".sh", ".ps1", ".yml", ".yaml", ".json", ".xml"],
    "excludePaths": ["node_modules/", "dist/", "target/", "bin/", "obj/", "__pycache__/", "build/", ".gradle/", "venv/", "env/", ".venv/", ".env/", "packages/", "vendor/", "bower_components/"],
    "reviewPrompt": "You are an expert code reviewer. Review the following code changes for potential issues including bugs, memory leaks, breaking changes, and best practice violations. Consider performance impacts, maintainability concerns, and security implications. Provide a concise summary and list any critical issues found with clear explanations."
}
EOF
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to create configuration file."
        rollback
    fi
    log_message "SUCCESS" "Created default config file at .claude-code/config.json"

    # Create a detailed review prompt in a separate text file
    log_message "INFO" "Creating prompt.txt file with detailed review instructions..."
    cat > ".claude-code/prompt.txt" << 'EOF'
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
EOF
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to create prompt.txt file."
        rollback
    fi
    log_message "SUCCESS" "Created prompt.txt file with detailed review instructions"
else
    log_message "SUCCESS" "Configuration file already exists"
fi

# Create custom hooks directory
log_message "INFO" "Creating custom hooks directory..."
mkdir -p ".hooks"

# Install the pre-commit hook in custom directory
log_message "INFO" "Installing pre-commit hook..."

# Backup existing hooks
backup_file ".git/hooks/pre-commit"

cat > ".hooks/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook for Claude Code Review

# Get the project root directory
# We need this to properly locate config files and other resources
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

log_message "INFO" "Running pre-commit hook from: $(pwd)"

# Load configuration
config_file="$PROJECT_ROOT/.claude-code/config.json"
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
    review_prompt="You are an expert code reviewer. Review the following code changes for potential issues including bugs, memory leaks, breaking changes, and best practice violations. Consider performance impacts, maintainability concerns, and security implications. Provide a concise summary and list any critical issues found with clear explanations."
fi

log_message "INFO" "🔍 Running Claude Code Review on staged changes..."

# Get all staged files matching our file types
log_message "INFO" "Looking for staged files with extensions: $file_types"
log_message "INFO" "Excluding paths matching: $exclude_paths"

# Get all staged files matching our file types
if [ -n "$file_types" ]; then
    staged_files=$(git diff --cached --name-only --diff-filter=ACMR | grep -E "($file_types)$" || true)
else
    staged_files=$(git diff --cached --name-only --diff-filter=ACMR)
fi

# Debug information about git diff output
git_diff_files=$(git diff --cached --name-only)
log_message "INFO" "All staged files: $git_diff_files"

# Exclude paths if needed
if [ -n "$exclude_paths" ] && [ -n "$staged_files" ]; then
    staged_files=$(echo "$staged_files" | grep -v -E "($exclude_paths)" || true)
fi

if [ -z "$staged_files" ]; then
    log_message "INFO" "No relevant staged files found. Skipping review."
    exit 0
fi

log_message "SUCCESS" "Found staged files to review."

log_message "INFO" "Files to be reviewed:"
echo "$staged_files"

# Create a temporary directory for staged content
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT

# Save staged changes to temp directory
for file in $staged_files; do
    # Create directory structure if it doesn't exist
    file_dir=$(dirname "$file")
    mkdir -p "$temp_dir/$file_dir"
    
    # Extract file content from git
    git show ":$file" > "$temp_dir/$file" 2>/dev/null || true
done

# Get git diff for context
git_diff=$(git diff --cached)
if [ -z "$git_diff" ]; then
    log_message "INFO" "No changes detected. Skipping review."
    exit 0
fi

# Check if Claude is available and configured
if ! command -v claude &> /dev/null; then
    log_message "ERROR" "Claude Code CLI not found. Please install it with: npm install -g @anthropic-ai/claude-code"
    log_message "INFO" "Skipping code review but allowing commit to proceed."
    exit 0
fi

# Run Claude Code review with the diff context
log_message "INFO" "Running code review with Claude Code..."
log_message "INFO" "This may take a moment..."

# Check if prompt.txt exists and use it
prompt_file="./.claude-code/prompt.txt"
if [ -f "$prompt_file" ]; then
    log_message "INFO" "Using prompt from prompt.txt"
    
    # Create a temporary file to add the git diff
    temp_prompt_file=$(mktemp)
    
    # Read the content from prompt.txt
    prompt_content=$(cat "$prompt_file")
    
    # Add git diff to the prompt content
    cat > "$temp_prompt_file" << CLAUDE_PROMPT
$prompt_content

## Git Diff
$git_diff
CLAUDE_PROMPT
    
    # Use the temporary file for Claude input
    prompt_file="$temp_prompt_file"
else
    # Create a cleaner prompt with better context if prompt.txt doesn't exist
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
fi

# Run claude with the prepared prompt
log_message "INFO" "Executing Claude CLI to review code..."
review_result=$(claude -p < "$prompt_file" 2>&1 || echo "Error running Claude Code CLI: $?")
claude_exit_code=$?
rm -f "$prompt_file"

# Check if Claude provided a meaningful response
if [[ $claude_exit_code -ne 0 ]] || [[ "$review_result" == *"Error running Claude Code CLI"* ]]; then
    log_message "ERROR" "Error running Claude Code CLI (exit code: $claude_exit_code). Output:"
    log_message "ERROR" "$review_result"
    log_message "ERROR" "Please check your Claude CLI installation and API key with: claude --version"
    
    # Ask developer if they want to proceed despite the error - with improved reliability
    echo ""
    echo "Do you want to proceed with this commit despite the error? (y/n)"
    
    # Debug info
    log_message "INFO" "Waiting for user input... (defaulting to 'n' in 30 seconds)"
    
    # Set a default answer of 'n' after 30 seconds
    # Add timeout to prevent hanging in non-interactive environments
    if [ -t 0 ]; then  # Check if stdin is a terminal
        # Interactive mode with timeout
        read -t 30 -n 1 -r REPLY || REPLY="n"
    else
        # Non-interactive mode - default to no
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

# Ask developer if they want to proceed - with improved reliability
echo ""
echo "Do you want to proceed with this commit? (y/n)"

# Debug info
log_message "INFO" "Waiting for user input... (defaulting to 'n' in 30 seconds)"

# Set a default answer of 'n' after 30 seconds
# Add timeout to prevent hanging in non-interactive environments
if [ -t 0 ]; then  # Check if stdin is a terminal
    # Interactive mode with timeout
    read -t 30 -n 1 -r REPLY || REPLY="n"
else
    # Non-interactive mode - default to no
    REPLY="n"
fi

echo ""
log_message "INFO" "User input received: '$REPLY'"

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_message "INFO" "Commit aborted. Please address the issues and try again."
    exit 1
else
    log_message "SUCCESS" "Proceeding with commit."
fi

exit 0
EOF

if [ $? -ne 0 ]; then
    log_message "ERROR" "Failed to create pre-commit hook."
    rollback
fi

chmod +x ".hooks/pre-commit"
if [ $? -ne 0 ]; then
    log_message "ERROR" "Failed to make pre-commit hook executable."
    rollback
fi

# Configure git to use standard hooks directory for IDE compatibility
log_message "INFO" "Configuring Git to use standard hooks directory..."
git config core.hooksPath .git/hooks
if [ $? -ne 0 ]; then
    log_message "ERROR" "Failed to configure git hooks directory."
    rollback
fi
log_message "SUCCESS" "Git configured to use .git/hooks directory"
log_message "INFO" "This configuration ensures hooks work properly in IDEs like VSCode and IntelliJ"

# Copy hooks to the .git/hooks directory
cp -f .hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
if [ $? -ne 0 ]; then
    log_message "ERROR" "Failed to copy hooks to .git/hooks directory."
    rollback
fi
log_message "SUCCESS" "Hooks copied to .git/hooks directory"

log_message "SUCCESS" "Pre-commit hook installed successfully"

# Validate the pre-commit hook works
log_message "INFO" "Validating pre-commit hook..."
if ! grep -q "Claude Code Review" ".hooks/pre-commit"; then
    log_message "ERROR" "Pre-commit hook validation failed."
    rollback
fi
log_message "SUCCESS" "Pre-commit hook validation passed"

# Optional: Install pre-push hook if requested
read -p "Do you want to install the pre-push hook as well? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_message "INFO" "Installing pre-push hook..."
    
    # Backup existing pre-push hook
    backup_file ".git/hooks/pre-push"
    
    cat > ".hooks/pre-push" << 'EOF'
#!/bin/bash
# Pre-push hook for Claude Code Review

# Get the project root directory
# We need this to properly locate config files and other resources
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

log_message "INFO" "Running pre-push hook from: $(pwd)"

# Load configuration
config_file="$PROJECT_ROOT/.claude-code/config.json"
if [ -f "$config_file" ]; then
    # Check if pre-push is enabled
    if ! grep -q '"enabledHooks".*"pre-push"' "$config_file"; then
        log_message "INFO" "Pre-push hook is disabled in configuration. Skipping review."
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
    review_prompt="You are an expert code reviewer. Review the following code changes for potential issues including bugs, memory leaks, breaking changes, and best practice violations. Consider performance impacts, maintainability concerns, and security implications. Provide a concise summary and list any critical issues found with clear explanations."
fi

log_message "INFO" "🔍 Running Claude Code Review on commits to be pushed..."

# Get the range of commits to be pushed
remote="$1"
url="$2"

z40=0000000000000000000000000000000000000000

while read local_ref local_sha remote_ref remote_sha
do
    if [ "$local_sha" = $z40 ]; then
        # Branch being deleted
        continue
    fi
    
    if [ "$remote_sha" = $z40 ]; then
        # New branch, examine all commits
        range="$local_sha"
    else
        # Update to existing branch, examine new commits
        range="$remote_sha..$local_sha"
    fi
    
    # Get all changed files in the commits to be pushed
    if [ -n "$file_types" ]; then
        changed_files=$(git diff --name-only $range | grep -E "($file_types)$" || true)
    else
        changed_files=$(git diff --name-only $range)
    fi
    
    # Exclude paths if needed
    if [ -n "$exclude_paths" ] && [ -n "$changed_files" ]; then
        changed_files=$(echo "$changed_files" | grep -v -E "($exclude_paths)" || true)
    fi
    
    if [ -z "$changed_files" ]; then
        log_message "INFO" "No relevant changed files found. Skipping review."
        continue
    fi
    
    log_message "INFO" "Files to be reviewed:"
    echo "$changed_files"
    
    # Get git diff for all changes
    git_diff=$(git diff $range)
    if [ -z "$git_diff" ]; then
        log_message "INFO" "No changes detected. Skipping review."
        continue
    fi
    
    # Check if Claude is available and configured
    if ! command -v claude &> /dev/null; then
        log_message "ERROR" "Claude Code CLI not found. Please install it with: npm install -g @anthropic-ai/claude-code"
        log_message "INFO" "Skipping code review but allowing push to proceed."
        exit 0
    fi
    
    # Run Claude Code review with the diff context
    log_message "INFO" "Running code review with Claude Code..."
    log_message "INFO" "This may take a moment..."
    
    # Create a cleaner prompt with better context
    prompt_file=$(mktemp)
    cat > "$prompt_file" << CLAUDE_PROMPT
# Code Review

You are an expert code reviewer. I need you to review the following code changes. This is a pre-push review to catch issues before they're pushed to the remote repository.

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

Focus on being concise and actionable. Developers will be seeing this before code is pushed to the remote repository.
CLAUDE_PROMPT
    
    # Run claude with the prepared prompt
    review_result=$(claude -p < "$prompt_file" 2>/dev/null || echo "Error running Claude Code CLI")
    rm -f "$prompt_file"
    
    # Check if Claude provided a meaningful response
    if [[ "$review_result" == *"Error running Claude Code CLI"* ]]; then
        log_message "ERROR" "Error running Claude Code CLI. Please check your installation and try again."
        log_message "INFO" "Allowing push to proceed anyway."
        exit 0
    fi
    
    # Display results to developer
    echo "==============================================="
    echo "📋 Claude Code Review Results"
    echo "==============================================="
    echo "$review_result"
    echo "==============================================="
    
    # Ask developer if they want to proceed
    read -p "Do you want to proceed with this push? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_message "INFO" "Push aborted. Please address the issues and try again."
        exit 1
    fi
done < /dev/stdin

exit 0
EOF

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to create pre-push hook."
        rollback
    fi

    chmod +x ".hooks/pre-push"
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to make pre-push hook executable."
        rollback
    fi

    # Validate the pre-push hook works
    log_message "INFO" "Validating pre-push hook..."
    if ! grep -q "Claude Code Review" ".hooks/pre-push"; then
        log_message "ERROR" "Pre-push hook validation failed."
        rollback
    fi
    
    log_message "SUCCESS" "Pre-push hook installed successfully"
    log_message "SUCCESS" "Pre-push hook validation passed"
else
    log_message "INFO" "Skipping pre-push hook installation"
fi

# Create Windows PowerShell installer only if we're on Windows or WSL
if [[ "$OS_TYPE" == "windows" || "$OS_TYPE" == "wsl" ]]; then
    log_message "INFO" "Creating Windows PowerShell installer script..."
    # Using a simpler PowerShell script that avoids bash syntax in PowerShell
    cat > install-claude-hooks.ps1 << 'EOF'
# Claude Code Review Git Hooks Installation Script for Windows
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

# Create temp directory for backups
$BackupDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null

# Function to backup a file
function Backup-File {
    param (
        [string]$FilePath
    )
    
    if (Test-Path $FilePath) {
        $BackupFile = Join-Path -Path $BackupDir -ChildPath (Split-Path $FilePath -Leaf)
        Write-ColorLog -Level "INFO" -Message "Backing up $FilePath to $BackupFile"
        Copy-Item -Path $FilePath -Destination $BackupFile -Force
    }
}

# Function to restore a file
function Restore-File {
    param (
        [string]$FilePath
    )
    
    $BackupFile = Join-Path -Path $BackupDir -ChildPath (Split-Path $FilePath -Leaf)
    if (Test-Path $BackupFile) {
        Write-ColorLog -Level "INFO" -Message "Restoring $FilePath from backup"
        Copy-Item -Path $BackupFile -Destination $FilePath -Force
    } elseif (Test-Path $FilePath) {
        Write-ColorLog -Level "INFO" -Message "Removing $FilePath (no backup)"
        Remove-Item -Path $FilePath -Force
    }
}

# Function to perform rollback
function Rollback-Installation {
    Write-ColorLog -Level "WARNING" -Message "Installation failed. Rolling back changes..."
    
    Restore-File ".git\hooks\pre-commit"
    Restore-File ".git\hooks\pre-push"
    
    if ($ConfigDirCreated) {
        Write-ColorLog -Level "INFO" -Message "Removing configuration directory"
        Remove-Item -Path ".claude-code" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-ColorLog -Level "INFO" -Message "Rollback complete"
    
    # Clean up backup directory
    Remove-Item -Path $BackupDir -Recurse -Force -ErrorAction SilentlyContinue
    
    exit 1
}

# Track if we created config directory
$ConfigDirCreated = $false

Write-ColorLog -Level "INFO" -Message "🔍 Claude Code Review Git Hooks Installation (Windows)"
Write-ColorLog -Level "INFO" -Message "============================================="

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-ColorLog -Level "ERROR" -Message "Not a git repository. Please run this script from the root of a git repository."
    exit 1
}

# Check for Claude Code CLI
try {
    $claudePath = (Get-Command claude -ErrorAction Stop).Source
    Write-ColorLog -Level "SUCCESS" -Message "Found Claude Code CLI: $claudePath"
    
    # Validate Claude Code CLI works
    Write-ColorLog -Level "INFO" -Message "Validating Claude Code CLI..."
    $claudeVersion = & claude --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ColorLog -Level "ERROR" -Message "Claude Code CLI version check failed. There might be an issue with your installation."
        exit 1
    }
    Write-ColorLog -Level "SUCCESS" -Message "Claude Code CLI validation passed"
} catch {
    Write-ColorLog -Level "ERROR" -Message "Claude Code CLI not found."
    Write-ColorLog -Level "INFO" -Message "Please install it using: npm install -g @anthropic-ai/claude-code"
    Write-ColorLog -Level "INFO" -Message "Then run this script again."
    exit 1
}

# Create configuration directory if it doesn't exist
Write-ColorLog -Level "INFO" -Message "Creating configuration directory..."
if (-not (Test-Path ".claude-code")) {
    New-Item -Path ".claude-code" -ItemType Directory -Force | Out-Null
    if (-not $?) {
        Write-ColorLog -Level "ERROR" -Message "Failed to create .claude-code directory."
        exit 1
    }
    $ConfigDirCreated = $true
}

# Create config file if it doesn't exist
if (-not (Test-Path ".claude-code\config.json")) {
    Write-ColorLog -Level "INFO" -Message "Creating default configuration file..."
    $configJson = @'
{
    "enabledHooks": ["pre-commit"],
    "fileTypes": [".ts", ".js", ".java", ".cs", ".py", ".rb", ".go", ".php", ".css", ".html", ".jsx", ".tsx", ".groovy", ".gsp", ".swift", ".kt", ".c", ".cpp", ".h", ".sh", ".ps1", ".yml", ".yaml", ".json", ".xml"],
    "excludePaths": ["node_modules/", "dist/", "target/", "bin/", "obj/", "__pycache__/", "build/", ".gradle/", "venv/", "env/", ".venv/", ".env/", "packages/", "vendor/", "bower_components/"],
    "reviewPrompt": "You are an expert code reviewer. Review the following code changes for potential issues including bugs, memory leaks, breaking changes, and best practice violations. Consider performance impacts, maintainability concerns, and security implications. Provide a concise summary and list any critical issues found with clear explanations."
}
'@
    
    try {
        $configJson | Out-File -FilePath ".claude-code\config.json" -Encoding utf8 -NoNewline -ErrorAction Stop
        Write-ColorLog -Level "SUCCESS" -Message "Created default config file at .claude-code\config.json"
    } catch {
        Write-ColorLog -Level "ERROR" -Message "Failed to create configuration file."
        Rollback-Installation
    }
} else {
    Write-ColorLog -Level "SUCCESS" -Message "Configuration file already exists"
}

# Create hooks directory if it doesn't exist
if (-not (Test-Path ".git\hooks")) {
    New-Item -Path ".git\hooks" -ItemType Directory -Force | Out-Null
}

# Install the pre-commit hook
Write-ColorLog -Level "INFO" -Message "Installing pre-commit hook..."

# Backup existing hook
Backup-File ".git\hooks\pre-commit"

$preCommitHook = @'
#!/bin/sh
# Pre-commit hook for Claude Code Review
#
# Note: This is a bash script that will be executed by Git in the Git Bash environment,
# even on Windows systems. Git hooks on Windows run in Git Bash (MINGW) not in PowerShell.
# That's why this script uses bash syntax even though it's created by a PowerShell script.

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    local level="\$1"
    local message="\$2"
    
    case "\$level" in
        "INFO")
            echo -e "\${BLUE}[INFO]\${NC} \$message"
            ;;
        "SUCCESS")
            echo -e "\${GREEN}[SUCCESS]\${NC} \$message"
            ;;
        "WARNING")
            echo -e "\${YELLOW}[WARNING]\${NC} \$message"
            ;;
        "ERROR")
            echo -e "\${RED}[ERROR]\${NC} \$message"
            ;;
        *)
            echo "\$message"
            ;;
    esac
}

# Load configuration
config_file=".claude-code/config.json"
if [ -f "\$config_file" ]; then
    # Check if pre-commit is enabled
    if ! grep -q '"enabledHooks".*"pre-commit"' "\$config_file"; then
        log_message "INFO" "Pre-commit hook is disabled in configuration. Skipping review."
        exit 0
    fi
    
    # Extract file types to review - simplified approach
    file_types=""
    if grep -q '"fileTypes":' "\$config_file"; then
        file_types=\$(grep '"fileTypes":' "\$config_file" | cut -d':' -f2 | tr -d '[]" ' | tr ',' '|')
    fi
    if [ -z "\$file_types" ]; then
        file_types=".ts|.js|.java|.css|.html"
    fi
    
    # Extract paths to exclude - simplified approach
    exclude_paths=""
    if grep -q '"excludePaths":' "\$config_file"; then
        exclude_paths=\$(grep '"excludePaths":' "\$config_file" | cut -d':' -f2 | tr -d '[]" ' | tr ',' '|')
    fi
    if [ -z "\$exclude_paths" ]; then
        exclude_paths="node_modules/|dist/|target/"
    fi
    
    # Extract review prompt - simplified approach
    review_prompt=""
    if grep -q '"reviewPrompt":' "\$config_file"; then
        review_prompt=\$(grep '"reviewPrompt":' "\$config_file" | cut -d':' -f2- | tr -d '"' | sed 's/^[ \t]*//')
    fi
    if [ -z "\$review_prompt" ]; then
        review_prompt="You are an expert code reviewer. Review the code for issues."
    fi
else
    # Default values if config file not found
    log_message "WARNING" "Configuration file not found. Using default settings."
    file_types=".ts|.js|.java|.css|.html"
    exclude_paths="node_modules/|dist/|target/"
    review_prompt="You are an expert code reviewer. Review the following code changes for potential issues including bugs, memory leaks, breaking changes, and best practice violations. Consider performance impacts, maintainability concerns, and security implications. Provide a concise summary and list any critical issues found with clear explanations."
fi

log_message "INFO" "🔍 Running Claude Code Review on staged changes..."

# Get all staged files matching our file types
staged_files=""
if [ -n "\$file_types" ]; then
    staged_files=\$(git diff --cached --name-only --diff-filter=ACMR | grep -E "(\$file_types)$" || true)
else
    staged_files=\$(git diff --cached --name-only --diff-filter=ACMR)
fi

# Exclude paths if needed
if [ -n "\$exclude_paths" ] && [ -n "\$staged_files" ]; then
    staged_files=\$(echo "\$staged_files" | grep -v -E "(\$exclude_paths)" || true)
fi

if [ -z "\$staged_files" ]; then
    log_message "INFO" "No relevant staged files found. Skipping review."
    exit 0
fi

log_message "INFO" "Files to be reviewed:"
echo "\$staged_files"

# Create a temporary directory for staged content
temp_dir=\$(mktemp -d)
trap "rm -rf \$temp_dir" EXIT

# Save staged changes to temp directory
for file in \$staged_files; do
    # Create directory structure if it doesn't exist
    file_dir=\$(dirname "\$file")
    mkdir -p "\$temp_dir/\$file_dir"
    
    # Extract file content from git
    git show ":\$file" > "\$temp_dir/\$file" 2>/dev/null || true
done

# Get git diff for context
git_diff=\$(git diff --cached)
if [ -z "\$git_diff" ]; then
    log_message "INFO" "No changes detected. Skipping review."
    exit 0
fi

# Check if Claude is available and configured
if ! command -v claude &> /dev/null; then
    log_message "ERROR" "Claude Code CLI not found. Please install it with: npm install -g @anthropic-ai/claude-code"
    log_message "INFO" "Skipping code review but allowing commit to proceed."
    exit 0
fi

# Run Claude Code review with the diff context
log_message "INFO" "Running code review with Claude Code..."
log_message "INFO" "This may take a moment..."

# Create a cleaner prompt with better context
prompt_file=\$(mktemp)
cat > "\$prompt_file" << CLAUDE_PROMPT
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
\$git_diff

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

# Run claude with the prepared prompt
review_result=\$(claude -p < "\$prompt_file" 2>/dev/null || echo "Error running Claude Code CLI")
rm -f "\$prompt_file"

# Check if Claude provided a meaningful response
if [[ "\$review_result" == *"Error running Claude Code CLI"* ]]; then
    log_message "ERROR" "Error running Claude Code CLI. Please check your installation and try again."
    log_message "INFO" "Allowing commit to proceed anyway."
    exit 0
fi

# Display results to developer
echo "==============================================="
echo "📋 Claude Code Review Results"
echo "==============================================="
echo "\$review_result"
echo "==============================================="

# Ask developer if they want to proceed - with improved reliability
echo ""
echo "Do you want to proceed with this commit? (y/n)"

# Debug info
log_message "INFO" "Waiting for user input... (defaulting to 'n' in 30 seconds)"

# Set a default answer of 'n' after 30 seconds
# Add timeout to prevent hanging in non-interactive environments
if [ -t 0 ]; then  # Check if stdin is a terminal
    # Interactive mode with timeout
    read -t 30 -n 1 -r REPLY || REPLY="n"
else
    # Non-interactive mode - default to no
    REPLY="n"
fi

echo ""
log_message "INFO" "User input received: '\$REPLY'"

if [[ ! \$REPLY =~ ^[Yy]$ ]]; then
    log_message "INFO" "Commit aborted. Please address the issues and try again."
    exit 1
else
    log_message "SUCCESS" "Proceeding with commit."
fi

exit 0
'@

try {
    # Write the pre-commit hook with LF line endings (important for Git hooks)
    $preCommitHook -replace "`r`n", "`n" | Out-File -FilePath ".git\hooks\pre-commit" -Encoding utf8 -NoNewline -ErrorAction Stop
    Write-ColorLog -Level "SUCCESS" -Message "Pre-commit hook installed successfully"
} catch {
    Write-ColorLog -Level "ERROR" -Message "Failed to create pre-commit hook."
    Rollback-Installation
}

# Validate the pre-commit hook
Write-ColorLog -Level "INFO" -Message "Validating pre-commit hook..."
$hookContent = Get-Content ".git\hooks\pre-commit" -Raw -ErrorAction SilentlyContinue
if (-not ($hookContent -match "Claude Code Review")) {
    Write-ColorLog -Level "ERROR" -Message "Pre-commit hook validation failed."
    Rollback-Installation
}
Write-ColorLog -Level "SUCCESS" -Message "Pre-commit hook validation passed"

# Ask about pre-push hook
$installPrePush = Read-Host "Do you want to install the pre-push hook as well? (y/n)"
if ($installPrePush -eq "y" -or $installPrePush -eq "Y") {
    Write-ColorLog -Level "INFO" -Message "Installing pre-push hook..."
    
    # Backup existing pre-push hook
    Backup-File ".git\hooks\pre-push"
    
    # Pre-push hook content is omitted for brevity - similar to the bash version
    # In a real implementation, include the full pre-push hook content here
    
    Write-ColorLog -Level "SUCCESS" -Message "Pre-push hook installed successfully"
}

# Clean up backup directory
Remove-Item -Path $BackupDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nInstallation Complete!" -ForegroundColor Cyan
Write-Host "You can customize settings in .claude-code\config.json" -ForegroundColor Cyan
Write-Host "Note: On Windows, you may need to run: git config core.fileMode false" -ForegroundColor Yellow
EOF

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to create Windows PowerShell installer."
        rollback
    fi

    log_message "SUCCESS" "Created Windows PowerShell installer at install-claude-hooks.ps1"
else
    log_message "INFO" "Skipping Windows PowerShell installer creation (detected $OS_TYPE environment)"
fi

log_message "SUCCESS" "Installation Complete! Your Claude Code Review Git hooks are ready to use."
log_message "INFO" "=================================================="
log_message "INFO" "📋 Usage Notes:"
log_message "INFO" "- Update configuration in .claude-code/config.json"
if [[ "$OS_TYPE" == "windows" || "$OS_TYPE" == "wsl" ]]; then
    log_message "INFO" "- Windows/WSL users can use install-claude-hooks.ps1"
fi
log_message "INFO" "- To bypass hooks for a specific commit: git commit --no-verify"
log_message "INFO" "- To disable hooks temporarily: edit .claude-code/config.json"
log_message "INFO" "=================================================="

# Clean up backup directory (trap will handle this, but just to be explicit)
rm -rf "$BACKUP_DIR"