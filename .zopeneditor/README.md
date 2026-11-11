# GRUB scripts - Git remote user build

Version 2.1.1

Modular build automation system for remote z/OS development environments.

## License

```txt
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2026. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#
# The grub scripts and documentation provided with this product are licensed
# under the IBM license terms and are licensed under the applicable
# IBM license terms. These files are not licensed under, and do not inherit,
# the license applicable to the customer's workspace or any other source code
# in which they may be placed. Use of the grub scripts and documentation is
# subject to the IBM license terms applicable to this product.
```

## Quick start

```bash
# Sync code and build (SSH)
grub_client prerequisites --hostname user@myserver --remoteWorkspace /u/user/project
grub_client gitPush --hostname user@myserver --remoteWorkspace /u/user/project
grub_client execute --hostname user@myserver --remoteWorkspace /u/user/project/MyRepo --command "./build"
grub_client fetch --hostname user@myserver --remoteWorkspace /u/user/project/MyRepo --files "*.log"

# Sync code and build (RSE API)
grub_client prerequisites --zoweProfile myprofile --remoteWorkspace /u/user/project
grub_client gitBundle --zoweProfile myprofile --remoteWorkspace /u/user/project
grub_client execute --zoweProfile myprofile --remoteWorkspace /u/user/project/MyRepo --command "./build"
grub_client fetch --zoweProfile myprofile --remoteWorkspace /u/user/project/MyRepo --files "*.log"
```

## Overview

GRUB provides six modular commands for z/OS development:

| Command           | Purpose                                | Transport     |
| ----------------- | -------------------------------------- | ------------- |
| **prerequisites** | Check requirements                     | SSH / RSE API |
| **gitPush**       | Push changes by using the Git protocol | SSH only      |
| **gitBundle**     | Transfer files by using Git bundles    | SSH / RSE API |
| **upload**        | Upload files                           | SSH / RSE API |
| **execute**       | Run commands                           | SSH / RSE API |
| **fetch**         | Download files                         | SSH / RSE API |

**Key features:**

- Dual transport support (SSH or RSE API through Zowe(TM))
- Delta bundles for efficient file transfers
- Git server clone support
- Automatic EBCDIC and UTF-8 conversion
- Preserves of uncommitted local changes
- GLOB pattern support for file operations
- Absolute path support for fetch operations
- Language-agnostic operation

## Manual Installation

These steps are not required when using GRUB from within IBM Z Open Editor.

```bash
# Option 1: Add to PATH (recommended)
export PATH="/path/to/grub-scripts/bin:$PATH"

# Option 2: Copy to a directory in your PATH
cp bin/grub_client /usr/local/bin/
cp bin/grub_server /usr/local/bin/
chmod +x /usr/local/bin/grub_*

# Option 3: For Z Open Editor integration
mkdir -p .zopeneditor/bin
cp bin/grub_client .zopeneditor/bin/
cp bin/grub_server .zopeneditor/bin/
chmod +x .zopeneditor/bin/grub_*

# Verify installation
grub_client --version
```

## Prerequisites

### Client (local machine)

**Required:**

- Git 2.0 or later
- Bash shell

**For SSH mode:**

- Password-less SSH configured

**For RSE API mode:**

- Zowe CLI with the RSE API plugin installed
- RSE API profile configured

### Server (z/OS)

**Required:**

- Git for z/OS

**For SSH mode:**

- SSH server running

**For RSE API mode:**

- RSE API service running

### Repository setup

Create `.gitattributes` file in the repository root:

```gitattributes
# EBCDIC source files
*.c working-tree-encoding=IBM-1047
*.h working-tree-encoding=IBM-1047
*.cpp working-tree-encoding=IBM-1047
*.cbl working-tree-encoding=IBM-1047
*.pli working-tree-encoding=IBM-1047
*.asm working-tree-encoding=IBM-1047
*.jcl working-tree-encoding=IBM-1047
Makefile working-tree-encoding=IBM-1047

# Text files (terminal-compatible)
*.json working-tree-encoding=ISO8859-1
*.xml working-tree-encoding=ISO8859-1
*.md working-tree-encoding=ISO8859-1
*.txt working-tree-encoding=ISO8859-1

# Binary files
*.jar binary
*.zip binary
*.o binary

# Alternative: IBM z/OS Git extension format (also supported)
# *.c zos-working-tree-encoding=ibm-1047 git-encoding=utf-8
# *.json zos-working-tree-encoding=utf-8 git-encoding=utf-8
```

**Pattern matching:**

- Supports both `working-tree-encoding=` and `zos-working-tree-encoding=` formats.
- More specific patterns override wildcards patterns. The last matching pattern takes precedence.
- Matches standard Git .gitattributes behavior.

## Commands

### 1. Prerequisites

Check that all requirements are met.

```bash
# SSH mode
grub_client prerequisites --hostname user@myserver --remoteWorkspace /u/user/project

# RSE API mode
grub_client prerequisites --zoweProfile myprofile --remoteWorkspace /u/user/project
```

### 2. gitPush (SSH only)

Push changes by using the Git protocol.

```bash
# Basic usage with hostname
grub_client gitPush --hostname user@myserver --remoteWorkspace /u/user/project

# Using Git remote name (alternative to hostname)
grub_client gitPush --gitRemote myremote --remoteWorkspace /u/user/project

# With Git server clone
grub_client gitPush --hostname user@myserver --remoteWorkspace /u/user/project \
  --gitServerRepository git@github.com:user/repo.git
```

**Connection options:**

- `--hostname user@server`: Uses an SSH hostname from ~/.ssh/config or a directly specified hostname.
- `--gitRemote name`: Uses an existing Git remote name as an alternative to hostname.
- `--gitRemoteName name`: Name for the z/OS git remote that GRUB creates (default: `zos_<repo>`).

**What it does:**

1. Creates a temporary commit that contains all changes.
2. Pushes the changes to the remote repository through SSH.
3. Resets the temporary commit locally.
4. Initializes remote repository if necessary.

**Git server clone:**

- Use `--gitServerRepository` to clone from a Git server during the initial synchronization.
- Subsequent synchronizations use delta transfers for improved performance.
- Works with GitHub, GitLab, Bitbucket, etc.

### 3. gitBundle (SSH or RSE API)

Transfer changes by using Git bundles.

```bash
# RSE API mode
grub_client gitBundle --zoweProfile myprofile --remoteWorkspace /u/user/project

# SSH mode with hostname
grub_client gitBundle --hostname user@myserver --remoteWorkspace /u/user/project

# SSH mode with Git remote
grub_client gitBundle --gitRemote myremote --remoteWorkspace /u/user/project

# With Git server clone
grub_client gitBundle --hostname user@myserver --remoteWorkspace /u/user/project \
  --gitServerRepository git@github.com:user/repo.git
```

**What it does:**

1. Creates a temporary commit that contains all changes.

2. Creates a delta bundle that only changes since last synchronization.
3. Uploads the bundle through SSH or RSE API.
4. Applies the bundle on the remote system.
5. Resets the temporary commit locally.

### 4. Upload

Upload non-Git, such as dependency files and configuration files.

```bash
# Upload a single file
grub_client upload --hostname user@myserver --remoteWorkspace /u/user/project --files "config.json"

# Upload multiple files or folders
grub_client upload --zoweProfile myprofile --remoteWorkspace /u/user/project --files "resources data.txt"

# Upload by using GLOB patterns (preserves the directory hierarchy)
grub_client upload --zoweProfile myprofile --remoteWorkspace /u/user/project \
  --baseDir ./myproject --files "**/*.c **/*.h"

# Upload all headers files from system include directory
grub_client upload --hostname user@myserver --remoteWorkspace /u/user/project/include \
  --baseDir /usr/include --files "**/*.h"
```

**Features:**

- Supports files and directories.
- Preserves the directory structure relative to `--baseDir`.
- Creates remote directories automatically.
- Applies encoding settings from .gitattributes automatically.
- **GLOB pattern support:**
  - `*.ext` - All files with the specified extension in the current directory
  - `**/*.ext` - Recursive search in all subdirectories
  - `dir/**/*.ext` - Recursive search in a specific directory
  - `?` - Single character wildcard

**GLOB pattern examples:**

```bash
# Upload all C source files recursively
--files "**/*.c"

# Upload headers files and source files
--files "**/*.h **/*.c"

# Upload files from a specific subdirectory
--files "src/**/*.plx"
```

### 5. Execute

Runs commands on a remote system.

```bash
# Simple command
grub_client execute --hostname user@myserver --remoteWorkspace /u/user/project/MyRepo --command "pwd"

# Build command
grub_client execute --zoweProfile myprofile --remoteWorkspace /u/user/project/MyRepo --command "./build"

# Chained commands
grub_client execute --hostname user@myserver --remoteWorkspace /u/user/project/MyRepo --command "make clean && make all"
```

### 6. Fetch

Download files from remote system with automatic encoding detection.

```bash
# Download a single file (encoding read from z/OS file tag by default)
grub_client fetch --hostname user@myserver --remoteWorkspace /u/user/project/MyRepo --files "build.log"

# Download files by using wildcard patterns
grub_client fetch --zoweProfile myprofile --remoteWorkspace /u/user/project/MyRepo --files "*.log *.err"

# Custom local directory
grub_client fetch --hostname user@myserver --remoteWorkspace /u/user/project/MyRepo --files "build.log" --localDir ./build-logs

# Fetch files from an absolute path (no --remoteWorkspace required)
grub_client fetch --zoweProfile myprofile --absolutePath \
  --files "/var/log/app.log" --localDir ./logs

# Use .gitattributes rules instead of file tags
grub_client fetch --hostname user@myserver --remoteWorkspace /u/user/project/MyRepo --files "*.log" --gitattributes

# Force binary download (no conversion)
grub_client fetch --hostname user@myserver --remoteWorkspace /u/user/project/MyRepo --files "*.bin" --binary

# Override encoding for all files
grub_client fetch --hostname user@myserver --remoteWorkspace /u/user/project/MyRepo --files "*.log" --encoding IBM-037

# Fetch multiple files from an absolute path by using wildcards
grub_client fetch --hostname user@myserver --absolutePath \
  --files "/var/log/*.log" --localDir ./logs
```

**Encoding priority (highest to lowest):**

| Priority    | Flag                | Behaviour                               |
| ----------- | ------------------- | --------------------------------------- |
| 1           | `--binary`          | No conversion -- download as-is         |
| 2           | `--encoding <name>` | Use specified codec for all files       |
| 3           | `--gitattributes`   | Use remote `.gitattributes` rules       |
| 4 (default) | _(none)_            | Read z/OS file tag via `chtag` per file |
| fallback    | untagged file       | `IBM-1047`                              |

**Features:**

- Supports wildcard patterns (expanded on the remote system)
- Default encoding detection from z/OS file tags (`chtag`)
- Automatic EBCDIC to UTF-8 conversion
- Default local directory: `./logs`
- **Absolute path support:** Use `--absolutePath` option to fetch files from any absolute path without specifying `--remoteWorkspace`

**Absolute path examples:**

```bash
# Fetch system logs
grub_client fetch --zoweProfile myprofile --absolutePath \
  --files "/var/log/syslog /var/log/messages" --localDir ./system-logs

# Fetch files by using wildcards patterns
grub_client fetch --hostname user@myserver --absolutePath \
  --files "/u/ibmuser/*.log" --localDir ./logs
```

## Transport modes

### SSH mode

**Setup:**

```bash
# Configure SSH
cat >> ~/.ssh/config << EOF
Host myserver
    HostName zos.example.com
    User myusername
    IdentityFile ~/.ssh/id_rsa
EOF

# Copy SSH key
ssh-copy-id myserver

# Test
ssh myserver "echo connected"
```

**Usage:** `--hostname user@myserver`

**Supported commands:** All six commands

### RSE API mode

**Setup:**

```bash
# Install Zowe CLI
npm install -g @zowe/cli@latest

# Install RSE API plugin
zowe plugins install @zowe/rse-api-for-zowe-cli@latest

# Create profile
zowe profiles create rseapi-profile myprofile \
  --host zos.example.com \
  --port 6800 \
  --user myusername \
  --password mypassword

# Test
zowe rse-api-for-zowe-cli issue unix "echo test" --cwd "/" --rse-profile myprofile
```

**Usage:** `--zoweProfile myprofile`

**Supported commands:** All commands except gitPush (use gitBundle instead)

## Complete workflows

### Workflow 1: SSH mode

```bash
# 1. Check prerequisites
grub_client prerequisites --hostname user@myserver --remoteWorkspace /u/user/project

# 2. Sync code
grub_client gitPush --hostname user@myserver --remoteWorkspace /u/user/project

# 3. Execute build
grub_client execute --hostname user@myserver --remoteWorkspace /u/user/project/MyRepo --command "./build"

# 4. Fetch results
grub_client fetch --hostname user@myserver --remoteWorkspace /u/user/project/MyRepo --files "*.log"
```

### Workflow 2: RSE API mode

```bash
# 1. Check prerequisites
grub_client prerequisites --zoweProfile myprofile --remoteWorkspace /u/user/project

# 2. Sync code
grub_client gitBundle --zoweProfile myprofile --remoteWorkspace /u/user/project

# 3. Execute build
grub_client execute --zoweProfile myprofile --remoteWorkspace /u/user/project/MyRepo --command "./build"

# 4. Fetch results
grub_client fetch --zoweProfile myprofile --remoteWorkspace /u/user/project/MyRepo --files "*.log"
```

### Workflow 3: Git server clone

```bash
# First sync - clone from Git server
grub_client gitBundle --hostname user@myserver --remoteWorkspace /u/user/project \
  --gitServerRepository git@github.com:user/repo.git

# Execute build
grub_client execute --hostname user@myserver --remoteWorkspace /u/user/project/repo --command "./build"

# Subsequent syncs - use delta bundles (faster)
grub_client gitBundle --hostname user@myserver --remoteWorkspace /u/user/project \
  --gitServerRepository git@github.com:user/repo.git

# Fetch results
grub_client fetch --hostname user@myserver --remoteWorkspace /u/user/project/repo --files "*.log"
```

## Encoding setup

### How encoding works

1. **On the Client**: Files are stored in UTF-8.
2. **During transfer**: The Git bundle contains a binary representation of the files.
3. **On z/OS**: `grub_server` applies `chtag` based on `.gitattributes`.
4. **File tagging**: Automatically applies `chtag` for IBM-1047, UTF-8, ISO8859-1.

### Encoding recommendations

**For z/OS source files (EBCDIC):**

- Use `IBM-1047` for C, C++, COBOL, PL/I, Assembler, JCL, and makefiles.
- Required by z/OS compilers.

**For text files viewable in a z/OS terminal:**

- Use `ISO8859-1` for JSON, XML, Markdown, and text files.
- Compatible with UTF-8 tools and z/OS terminals.
- Displays correctly in `cat`, `vi`, and SSH sessions.

**Why ISO8859-1 instead of UTF-8?**

- UTF-8 files can appear garbled in z/OS EBCDIC terminals.
- ISO8859-1 provides broad compatibility across tools and environments.

## Troubleshooting

### Git not found

```bash
# Check git
which git
git --version

# On z/OS, add to ~/.profile
export PATH="/usr/lpp/IBM/foz/v1r1/bin:$PATH"
```

### SSH connection failed

```bash
# Test connection
ssh myserver "echo connected"

# Check config
cat ~/.ssh/config

# Copy key
ssh-copy-id myserver
```

### Zowe profile issues

```bash
# List profiles
zowe profiles list rseapi

# Test profile
zowe rse-api-for-zowe-cli issue unix "pwd" --cwd "/" --rse-profile myprofile
```

### Encoding issues

```bash
# Check .gitattributes
cat .gitattributes

# On z/OS, check file tags
ls -T

# Manually tag a file
chtag -tc IBM-1047 myfile.c
```

### gitBundle verification failed (SSH mode)

If `gitBundle` works with RSE API but fails with SSH, try the following steps:

**1. Enable debug mode**

```bash
grub_client gitBundle --hostname user@myserver --remoteWorkspace /u/user/project --debug
```

This command shows:

- Git version and location on z/OS
- Bundle file size and encoding tag
- Detailed error messages from `git bundle verify`

**2. Check bundle file transfer**

```bash
# After failed attempt, check if bundle exists on z/OS
ssh user@myserver "ls -lT /tmp/grub_*.bundle"

# Expected results:
# - File exists
# - Size matches local bundle
# - Tag is 'b binary' (not 't text')
```

**3. Common causes & solutions**

| Issue                  | Symptom            | Solution                                                                   |
| ---------------------- | ------------------ | -------------------------------------------------------------------------- |
| **Bundle not binary**  | Tag shows `t text` | Bundle is uploaded via sftp (binary). Check the network and try `--debug`. |
| **Git not in PATH**    | "git: not found"   | Automatic resolution is attempted. See the following note.                 |
| **Corrupted transfer** | Size mismatch      | Check the network connection and try a smaller change set.                 |
| **Git version**        | "unknown option"   | Update Git on z/OS. Git 2.x or later is required.                          |

**Note on Git PATH resolution:**
The server automatically searches for Git in common z/OS locations:

- `/usr/lpp/IBM/foz/v1r1/bin` (zOpen Git)
- `/usr/local/zopen/usr/local/bin` (zOpen alternate location)
- `/usr/lpp/IBM/git/bin` (IBM Git)
- `/opt/freeware/bin` (Freeware)
- `/usr/local/bin` (Standard UNIX System Services location)

If Git is not found, the error output shows "Git location: git: not found" Add Git to the `PATH` environment variable manually.

**4. Manual verification**

```bash
# On z/OS, verify the bundle manually
ssh user@myserver "cd /u/user/project && git bundle verify /tmp/grub_*.bundle"

# If this command succeeds but grub_client fails, the issue is likely related to PATH.
# Add to ~/.profile on z/OS (adjust path as needed):
export PATH="/usr/lpp/IBM/foz/v1r1/bin:$PATH"

# Or, for the alternate zOpen location:
export PATH="/usr/local/zopen/usr/local/bin:$PATH"
```

**5. Preserve the bundle for analysis**

```bash
# Keep the bundle file for manual inspection
grub_client gitBundle --hostname user@myserver --remoteWorkspace /u/user/project --preserve-bundle

# Bundle location: /tmp/grub_<user>_<repo>.bundle
# Manual Verification: git bundle verify /tmp/grub_*.bundle
```

## Common options

```bash
-v, --verbose               # Enable verbose output
--debug                     # Enable debug mode (set -x on client and server)
--preserve-bundle           # Preserve bundle files for manual inspection
-h, --help                  # Show help
--version                   # Show version
--localWorkspace <path>     # Local workspace (default: current directory)
--remoteWorkspace <path>    # Remote workspace on z/OS (required for most commands)
--gitRemote <name>          # Git remote name (alternative to --hostname for Git operations)
--gitRemoteName <name>      # Name for the z/OS git remote GRUB creates (default: zos_<repo>)
--gitServerRepository <url> # Git server URL for cloning (for example, git@github.com:user/repo.git)
--files <list>              # File list for upload or fetch (supports GLOB patterns)
--command <cmd>             # Command for execute
--localDir <path>           # Local directory for fetch (default: ./logs)
--baseDir <path>            # Base directory for upload (preserves the hierarchy from this point)
--absolutePath              # For fetch, allows absolute paths without --remoteWorkspace
```

**Debug options:**

- `--debug`: Enables command tracing (`set -x`) on both the client and server and shows all commands that run.
- `--preserve-bundle`: Preserves bundle files in `/tmp` for manual testing. Useful with `--debug`.
- These options can be used together or separately.

## Support

For issues or questions, please contact the IBM technical support.
