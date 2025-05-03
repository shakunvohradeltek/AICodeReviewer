# AICodeReviewer

Git hooks for automated code reviews using Anthropic's Claude-Code. Get expert code reviews automatically during your git workflow.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- Pre-commit and pre-push hooks for real-time code review
- Expert AI code review before your code is committed or pushed
- Support for multiple programming languages and frameworks
- Customizable review prompts and file type filtering
- Easy installation and uninstallation
- Cross-platform support (Mac, Linux, Windows with WSL)

## Prerequisites

Before installing the Git hooks, ensure you have:

1. **Git** (version 2.9+) installed
   - For Mac/Linux: Typically pre-installed or available via package manager
   - For Windows: Download from [git-scm.com](https://git-scm.com/)
   - For WSL: Install Git inside your WSL environment:
     ```bash
     sudo apt update && sudo apt install git
     ```

2. **Claude Code CLI** installed:
   - For Mac/Linux: 
     ```bash
     npm install -g @anthropic-ai/claude-code
     ```
   - For Windows: 
     - WSL (Windows Subsystem for Linux) must be installed 
     - Claude Code CLI must be installed within WSL:
       ```bash
       wsl npm install -g @anthropic-ai/claude-code
       ```

3. **Environment Requirements**:
   - For Mac/Linux: **Bash** shell
   - For Windows: **PowerShell** and **WSL** with a Linux distribution (Ubuntu recommended)

## Installation

### For Mac, Linux, or Windows with WSL

1. Download the `install-claude-hooks.sh` script
2. Make it executable:
   ```bash
   chmod +x install-claude-hooks.sh
   ```
3. Run the installer:
   ```bash
   ./install-claude-hooks.sh
   ```

**Note for Windows Subsystem for Linux (WSL) users**:

- Git must be installed in your WSL environment:
  ```bash
  sudo apt update && sudo apt install git
  ```
- Two installation options are available for Windows users:
  
  1. **Windows Git + WSL Claude (recommended)**: 
     - Use `install-windows-hooks.ps1` to set up hooks that work with Windows Git but run Claude from WSL
     - This allows you to use Git from Windows while leveraging Claude in WSL
     - Requires Git in both Windows and WSL
  
  2. **WSL-only approach**:
     - Use `install-claude-hooks.sh` within WSL
     - Git commands must be run from the WSL terminal to trigger the hooks correctly
     - This approach won't work if you use Git from Windows

- The script will detect if you're running in WSL and create PowerShell scripts as needed
- When using WSL with repositories that require authentication:
  - You may need to reconfigure credentials within WSL
  - For Azure DevOps/TFS: Use `git config --global credential.helper store` or set up SSH keys
  - For AWS CodeCommit: Configure AWS credentials in the WSL environment
  - For other repositories: You may need to re-authenticate within the WSL environment

The installer will:
- Create a `.claude-code` directory for configuration
- Create a `.claude-code/prompt.txt` file with detailed review instructions 
- Create a `.hooks` directory for custom Git hooks
- Configure Git to use standard hooks directory (.git/hooks) for IDE compatibility
- Copy hooks to .git/hooks directory for execution
- Install the pre-commit hook (and optionally pre-push)
- Create a default configuration file
- Backup any existing hooks

### For Windows

There are two installation methods available for Windows users, depending on how you want to use Git:

#### Option 1: Windows Git + WSL Claude (Recommended)

This option lets you use Git from Windows while the hooks run Claude in WSL.

1. Make sure you have WSL installed and set up:
   ```powershell
   # Install WSL if not already installed
   wsl --install
   ```

2. Install required components in WSL:
   ```powershell
   # Install Git, Node.js and npm in WSL
   wsl sudo apt update
   wsl sudo apt install -y git nodejs npm
   
   # Install Claude Code CLI in WSL
   wsl npm install -g @anthropic-ai/claude-code
   ```

3. Download the `install-windows-hooks.ps1` script to your repository root

4. Open PowerShell as Administrator

5. Enable script execution if needed:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

6. Run the installer:
   ```powershell
   .\install-windows-hooks.ps1
   ```

This method:
- Creates special bridge scripts that connect Windows Git with WSL Claude
- Allows you to use Git from Windows natively (Git GUI, IDE integrations, etc.)
- Runs Claude in WSL when Git hooks are triggered
- Creates a `.claude-code/prompt.txt` file for customizing the review prompt
- Configures pre-commit hooks to use the prompt from this file
- Configures Git to ensure hooks work properly in IDEs like VS Code and IntelliJ

#### Option 2: WSL-only Approach

With this option, you must use Git from within WSL.

1. Make sure you have WSL installed and set up:
   ```powershell
   # Install WSL if not already installed
   wsl --install
   ```

2. Start a WSL terminal session

3. Navigate to your repository and run the installer from within WSL:
   ```bash
   # Install Git and Claude CLI in WSL
   sudo apt update && sudo apt install -y git nodejs npm
   npm install -g @anthropic-ai/claude-code
   
   # Run the shell script installer
   cd /path/to/your/repo
   chmod +x install-claude-hooks.sh
   ./install-claude-hooks.sh
   ```

**Important Notes for Windows Users**:
- The installers will verify that WSL and Claude Code CLI are properly installed
- If you experience authentication issues with your repository in WSL:
  - For Azure DevOps/TFS: Configure credentials in WSL with `git config --global credential.helper store`
  - For AWS CodeCommit: Set up AWS credentials in the WSL environment
  - For other repositories: You may need to re-authenticate within WSL

## How It Works

The installation process sets up a custom hooks directory and configures Git to use it, ensuring a more reliable and consistent experience across different environments.

### Hooks Directory Setup

- Creates a `.hooks` directory in your repository root to store hook scripts
- Creates a `.claude-code/prompt.txt` file with detailed review instructions
- Configures Git to use standard hooks directory (.git/hooks) for IDE compatibility
- Copies hooks from .hooks to .git/hooks to ensure they're executed
- The hooks directory and configuration files are gitignored by default
- This approach ensures hooks are:
  - Repository-specific
  - Optional for each developer (not forced on the team)
  - Consistently applied when installed
  - Compatible with IDEs and Git clients
  - Easier to maintain and update

### 1. Pre-commit Hook

- Automatically runs when you execute `git commit`
- Analyzes your staged changes before they're committed
- Shows feedback about potential issues
- Gives you the option to proceed or abort the commit

### 2. Pre-push Hook (Optional)

- Automatically runs when you execute `git push`
- Reviews all commits that are about to be pushed
- Analyzes the entire diff between your local and remote branches
- Gives you the option to proceed or abort the push

### Workflow

1. You make code changes as usual
2. You stage changes with `git add`
3. When you run `git commit`:
   - The pre-commit hook intercepts the commit
   - The hook extracts the diff of your staged changes
   - Claude Code CLI analyzes the diff
   - Results are displayed in your terminal
   - You decide whether to proceed or fix issues
4. If you also installed the pre-push hook, a similar process occurs before pushing

## Configuration

The hooks are configured via the `.claude-code/config.json` file in your repository:

```json
{
    "enabledHooks": ["pre-commit", "pre-push"],
    "fileTypes": [".ts", ".js", ".java", ".cs", ".py", ".rb", ".go", ".php", ".css", ".html", ".jsx", ".tsx", ".groovy", ".gsp", ".swift", ".kt", ".c", ".cpp", ".h", ".sh", ".ps1", ".yml", ".yaml", ".json", ".xml"],
    "excludePaths": ["node_modules/", "dist/", "target/", "bin/", "obj/", "__pycache__/", "build/", ".gradle/", "venv/", "env/", ".venv/", ".env/", "packages/", "vendor/", "bower_components/"],
    "claudePath": "/home/username/.nvm/versions/node/v23.11.0/bin/claude"
}
```

For Windows users with WSL, the review prompt is now stored in `.claude-code/prompt.txt`:

```
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
```

### Configuration Options

- **enabledHooks**: Which hooks to activate (`pre-commit`, `pre-push`)
- **fileTypes**: File extensions to include in the review
- **excludePaths**: Directories/paths to exclude from reviews
- **claudePath**: The path to the Claude CLI in WSL (for Windows users)
- **prompt.txt**: File containing detailed prompt instructions for code review (preferred over reviewPrompt in config.json)

## Usage

### Normal Workflow

Once installed, the hooks work automatically:

1. Make your code changes
2. Stage changes: `git add .`
3. Commit changes: `git commit -m "Your message"`
4. The pre-commit hook runs automatically
5. Review the feedback
6. Type `y` to proceed or `n` to abort and fix issues

### Bypassing Hooks

If you need to bypass the hooks for a specific commit:

```bash
git commit --no-verify -m "Your message"
```

Or for pushing:

```bash
git push --no-verify
```

### Temporarily Disabling Hooks

Edit the `.claude-code/config.json` file and change `enabledHooks` to an empty array:

```json
{
    "enabledHooks": [],
    "fileTypes": [".ts", ".js", ".java", ".cs", ".py", ".rb", ".go", ".php", ".css", ".html", ".jsx", ".tsx", ".groovy", ".gsp", ".swift", ".kt", ".c", ".cpp", ".h", ".sh", ".ps1", ".yml", ".yaml", ".json", ".xml"],
    "excludePaths": ["node_modules/", "dist/", "target/", "bin/", "obj/", "__pycache__/", "build/", ".gradle/", "venv/", "env/", ".venv/", ".env/", "packages/", "vendor/", "bower_components/"],
    "reviewPrompt": "You are an expert code reviewer. Review the following code changes for potential issues including bugs, memory leaks, breaking changes, and best practice violations..."
}
```

## Uninstallation

### For Mac, Linux, or Windows with WSL

1. Download the `uninstall-claude-hooks.sh` script
2. Make it executable:
   ```bash
   chmod +x uninstall-claude-hooks.sh
   ```
3. Run the uninstaller:
   ```bash
   ./uninstall-claude-hooks.sh
   ```

The uninstaller will:
- Check Git hooks path configuration and ask if you want to reset it
- Offer to remove the custom `.hooks` directory
- Offer to remove the `.claude-code` configuration directory and prompt.txt
- Remove any Claude hooks from the `.git/hooks` directory
- Restore any backed-up hooks if available
- Provide detailed logs of the uninstallation process

### For Windows

#### If you used Option 1 (Windows Git + WSL Claude)

1. Use the `uninstall-windows-hooks.ps1` script included in the repository
2. Open PowerShell as Administrator 
3. Run the uninstaller:
   ```powershell
   .\uninstall-windows-hooks.ps1
   ```

The uninstaller will:
- Remove the Git hooks from the `.git/hooks` directory
- Offer to remove the custom `.hooks` directory
- Offer to remove the `.claude-code` configuration directory with prompt.txt
- Offer to clean up Claude-related entries from .gitignore
- Offer to self-delete after completion

#### If you used Option 2 (WSL-only Approach)

1. Start a WSL terminal session
2. Navigate to your repository
3. Run the uninstaller script:
   ```bash
   chmod +x uninstall-claude-hooks.sh
   ./uninstall-claude-hooks.sh
   ```

**Note**: The uninstallers will only remove the Git hooks configuration and related files. They will not uninstall WSL or remove the Claude Code CLI from your system.

## Troubleshooting

### Hook Not Running

1. Check that the scripts are executable:
   ```bash
   chmod +x .hooks/pre-commit
   chmod +x .hooks/pre-push
   ```

2. Verify hooks are in the correct location:
   ```bash
   ls -la .hooks/
   ```

3. Check that git is configured to use the custom hooks directory:
   ```bash
   git config core.hooksPath
   ```

   It should return a path like `/path/to/your/repo/.hooks`

4. Check configuration in `.claude-code/config.json`

### Claude Code CLI Not Found

If the hook can't find Claude Code CLI:

1. Verify it's installed globally:
   ```bash
   claude --version
   ```

2. If installed but not found in PATH, edit the hook script and provide the full path

### Common Errors

- **"No relevant staged files found"**: Your changes don't match the file types in the configuration
- **"Error running Claude Code CLI"**: Check your Claude Code installation or authentication
- **Review times out**: Your diff might be too large, try committing smaller changes
- **PowerShell syntax errors**: If you encounter syntax errors with the Windows installer:
  - Try using the `install-claude-hooks-fixed.ps1` script which has improved compatibility
  - Make sure you're running PowerShell (not CMD)
  - Check if you have the latest PowerShell version installed
- **IDE Git Integration Not Triggering Hooks**:
  - Verify Git hooks configuration: `git config core.hooksPath` (should return `.git/hooks`)
  - If not set correctly, run: `git config core.hooksPath .git/hooks`
  - Restart your IDE after installing hooks or changing configuration
  - For IntelliJ/JetBrains IDEs: Go to Settings → Version Control → Git and ensure "Run Git hooks" is checked
  - For VS Code: Try using the command palette for Git operations instead of the GUI buttons

- **Windows Git not triggering hooks with Claude in WSL**:
  - Make sure you've used the `install-windows-hooks.ps1` script which creates the proper bridge between Windows Git and WSL
  - Verify that `wsl` command works in your Windows command prompt or PowerShell
  - Check if the hook scripts are executable in WSL with `wsl ls -la .git/hooks/`
  - Try running `wsl bash -c "cd $(wsl wslpath "$(pwd)") && claude --version"` to test if Claude can be accessed from WSL

## FAQ

### Does this replace manual code reviews?

No, it complements them. The hook provides immediate feedback during development, but team code reviews are still valuable for design discussions and deeper analysis.

### Will the hooks send my code to external servers?

Yes, the hooks send your code diffs to Claude via the Claude Code CLI. Only changes (not the entire codebase) are sent. If you have sensitive code, review the diffs before committing.

### Does the uninstaller remove Claude Code CLI?

No, the uninstaller only removes the Git hooks and configuration files. The Claude Code CLI remains installed for other uses.

### How do the hooks work with IDEs?

The installation scripts configure Git to use the standard hooks directory (.git/hooks) with:
```bash
git config core.hooksPath .git/hooks
```

This ensures better compatibility with IDEs like Visual Studio Code and IntelliJ that expect hooks to be in the standard location. The hooks are stored in both:
- `.hooks/` directory (as a centralized hooks repository)
- `.git/hooks/` directory (where git and IDEs expect to find them)

This hybrid approach offers several advantages:
- Compatible with all IDEs and Git clients
- Repository-specific configuration
- Installation is a conscious decision by each developer (opt-in)
- Works reliably across different environments
- Easier to maintain and update
- Provides a cleaner uninstallation process

Note: The .hooks/ and .claude-code/ directories are gitignored by default, making the hooks truly opt-in for each developer. This ensures nobody gets hooks without explicitly running the installation script.

### How can I customize what Claude looks for?

Edit the `.claude-code/prompt.txt` file to customize the review prompt. This approach is preferred as it allows for more detailed multi-line prompts.

The hooks for all platforms (Mac, Linux, Windows) have been updated to check for and use this file when it exists. If the file doesn't exist, the hooks will fall back to using the `reviewPrompt` in the `.claude-code/config.json` file.

### Will this slow down my commits?

The pre-commit hook adds a few seconds to the commit process while Claude analyzes your changes. For very large changes, it might take longer.

### Does this work with all IDEs and Git clients?

Yes, since it uses standard Git hooks, it works with any IDE or Git client that respects Git hooks. The installer explicitly configures Git to use the standard hooks directory with `git config core.hooksPath .git/hooks`, which ensures better compatibility with IDEs like Visual Studio Code and IntelliJ. 

For some IDEs, you may need to:
- Restart the IDE after installing hooks
- Enable Git hooks in the IDE's settings
- Use specific Git commands or commit methods within the IDE

See the troubleshooting section for IDE-specific guidance.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.