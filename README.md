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
2. **Claude Code CLI** installed via:
   ```
   npm install -g @anthropic-ai/claude-code
   ```
3. **Bash** (for Mac/Linux/WSL) or **PowerShell** (for Windows without WSL)

## Installation

### For Mac, Linux, or Windows with WSL

1. Download the `install-claude-hooks.sh` script
2. Make it executable:
   ```
   chmod +x install-claude-hooks.sh
   ```
3. Run the installer:
   ```
   ./install-claude-hooks.sh
   ```

The installer will:
- Create a `.claude-code` directory for configuration
- Create a `.hooks` directory for custom Git hooks
- Configure Git to use this custom hooks directory
- Install the pre-commit hook (and optionally pre-push)
- Create a default configuration file
- Backup any existing hooks

### For Windows (without WSL)

1. Download the `install-claude-hooks.ps1` script (created during the install process)
2. Open PowerShell as Administrator
3. Enable script execution if needed:
   ```
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```
4. Run the installer:
   ```
   .\install-claude-hooks.ps1
   ```

## How It Works

The installation process sets up a custom hooks directory and configures Git to use it, ensuring a more reliable and consistent experience across different environments.

### Custom Hooks Directory

- Creates a `.hooks` directory in your repository root
- Configures Git to use this directory with `git config core.hooksPath`
- Places all hooks in this directory rather than in `.git/hooks`
- This approach ensures hooks are:
  - Repository-specific
  - Version-controlled
  - Consistently applied across all development environments
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
    "reviewPrompt": "You are an expert code reviewer. Review the following code changes for potential issues including bugs, memory leaks, breaking changes, and best practice violations. Consider performance impacts, maintainability concerns, and security implications. Provide a concise summary and list any critical issues found with clear explanations."
}
```

### Configuration Options

- **enabledHooks**: Which hooks to activate (`pre-commit`, `pre-push`)
- **fileTypes**: File extensions to include in the review
- **excludePaths**: Directories/paths to exclude from reviews
- **reviewPrompt**: Custom instructions for Claude Code

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

```
git commit --no-verify -m "Your message"
```

Or for pushing:

```
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
   ```
   chmod +x uninstall-claude-hooks.sh
   ```
3. Run the uninstaller:
   ```
   ./uninstall-claude-hooks.sh
   ```

The uninstaller will:
- Reset Git's hooks path to the default location (`.git/hooks`)
- Offer to remove the custom `.hooks` directory
- Remove the `.claude-code` configuration directory
- Restore any backed-up hooks if available
- Provide detailed logs of the uninstallation process

### For Windows (without WSL)

1. Download the `uninstall-claude-hooks.ps1` script (created during the uninstall process)
2. Run in PowerShell:
   ```
   .\uninstall-claude-hooks.ps1
   ```

**Note**: The uninstaller will only remove the Git hooks and configuration, not the Claude Code CLI itself.

## Troubleshooting

### Hook Not Running

1. Check that the scripts are executable:
   ```
   chmod +x .hooks/pre-commit
   chmod +x .hooks/pre-push
   ```

2. Verify hooks are in the correct location:
   ```
   ls -la .hooks/
   ```

3. Check that git is configured to use the custom hooks directory:
   ```
   git config core.hooksPath
   ```
   
   It should return a path like `/path/to/your/repo/.hooks`

4. Check configuration in `.claude-code/config.json`

### Claude Code CLI Not Found

If the hook can't find Claude Code CLI:

1. Verify it's installed globally:
   ```
   claude --version
   ```

2. If installed but not found in PATH, edit the hook script and provide the full path

### Common Errors

- **"No relevant staged files found"**: Your changes don't match the file types in the configuration
- **"Error running Claude Code CLI"**: Check your Claude Code installation or authentication
- **Review times out**: Your diff might be too large, try committing smaller changes

## FAQ

### Does this replace manual code reviews?

No, it complements them. The hook provides immediate feedback during development, but team code reviews are still valuable for design discussions and deeper analysis.

### Will the hooks send my code to external servers?

Yes, the hooks send your code diffs to Claude via the Claude Code CLI. Only changes (not the entire codebase) are sent. If you have sensitive code, review the diffs before committing.

### Does the uninstaller remove Claude Code CLI?

No, the uninstaller only removes the Git hooks and configuration files. The Claude Code CLI remains installed for other uses.

### Why use a custom hooks directory instead of the default `.git/hooks`?

The custom hooks directory approach (.hooks/) provides several advantages:
- Hooks can be version-controlled (unlike `.git/hooks`)
- Team members get consistent hooks when cloning the repository
- Works more reliably across different environments
- Easier to maintain and update for the entire team
- Prevents accidental hook bypassing that can happen with default hooks

### How can I customize what Claude looks for?

Edit the `reviewPrompt` in the `.claude-code/config.json` file to focus on specific issues like memory leaks, performance problems, or other concerns.

### Will this slow down my commits?

The pre-commit hook adds a few seconds to the commit process while Claude analyzes your changes. For very large changes, it might take longer.

### Does this work with all IDEs and Git clients?

Yes, since it uses standard Git hooks, it works with any IDE or Git client that respects Git hooks.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.