# Snip - Advanced Snippet Manager

## Written in Bash

A powerful command-line snippet manager for storing, organizing, and executing
code snippets and commands with support for encryption,
variables with default values, OTP codes,
and multiple interfaces (CLI, fzf, rofi).

## Features

- **Snippet Management**: Create, edit, delete, list, and search snippets
- **Variable Substitution**: Use `@{varName}` placeholders for dynamic values with optional defaults
- **GPG Encryption**: Encrypt sensitive snippets with GPG
- **OTP Support**: Store and generate TOTP codes for 2FA
- **Password Management**: Store and manage passwords with username, URL, and notes
- **Secrets Management**: Store and encrypt sensitive data securely like API keys, passwords, etc...
- **Multiple Interfaces**: CLI, fzf search, and rofi integration
- **Git Sync**: Version control and sync snippets across devices
- **Share Snippets**: Quick sharing via termbin.com
- **Safe Execution**: Preview and confirm before running snippets
- **Health Check**: Verify all dependencies are installed
- **Cross-Platform**: Works on macOS and Linux

## Installation

1. Clone this repository or download the script
2. Make it executable:

```bash
chmod +x snip
```

3. Move to your PATH (optional):

```bash
sudo mv snip /usr/local/bin/
```

## Dependencies

### Required

- `bash`
- `gpg` - For encryption features
- `gum` - For interactive prompts ([install here](https://github.com/charmbracelet/gum))
- `fzf` - For interactive snippet search ([install here](https://github.com/junegunn/fzf))
- `bat` - For syntax-highlighted preview ([install here](https://github.com/sharkdp/bat))

### Optional

- `rofi` - For GUI snippet selection
- `tree` - For directory listing
- `git` - For sync functionality
- `oathtool` - For OTP/TOTP code generation
- `terminal-notifier` or `notify-send` - For notifications (required for rofi)
- `pbcopy` (macOS) or `xclip` (Linux) - For clipboard support in rofi

### Check Dependencies

Run the health check to verify all required tools are installed:

```bash
snip doctor
```

This will show:

- ✅ Installed tools
- ⚠️ Missing tools with installation links

## Configuration

On first run, snip creates:

- `~/.snip/` - Main directory
- `~/.snip/snippets/` - Snippets storage
- `~/.snip/.env` - Configuration file
- `~/.snip/.gpgid` - GPG key ID for encryption

### Default Configuration

The `.env` file contains:

```bash
EDITOR=vim
```

You can customize settings:

```bash
snip config edit
```

Available config commands:

- `snip config home` - Print snip home path
- `snip config snippets` - Print snippets directory
- `snip config dotenv` - Print config file path
- `snip config editor` - Print current editor
- `snip config edit` - Edit configuration file

## Usage

### Basic Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `help` | `h` | Display help information |
| `doctor` | `doc` | Check if all requirements are met |
| `add` | `a` | Create a new snippet |
| `edit` | `e` | Edit an existing snippet |
| `del` | `d` | Delete a snippet |
| `list` | `ls` | List snippets in a directory |
| `search` | `fzf` | Search snippets interactively |
| `show` | `s` | Display a snippet with variable substitution |
| `raw` | `rw` | Show snippet without variable parsing |
| `run` | `r` | Execute a snippet |
| `share` | `shr` | Share snippet via termbin |
| `sync` | `u` | Sync with git repository |
| `config` | `c` | Manage configuration |
| `runrofi` | `rf` | Run rofi interface |
| `gpg_id` | `gi` | Set GPG ID for encryption |
| `encrypt` | `enc` | Encrypt a snippet |
| `decrypt` | `dec` | Decrypt a snippet |
| `otp` | `otp` | Manage OTP/TOTP codes |
| `password` | `psw` | Manage passwords with username, URL, and notes |

### Examples

#### Creating Snippets

```bash
# Create a simple snippet
snip add docker/ps
# Prompts for snippet path if not provided
# Choose between inline input or opening editor

# Create nested snippet
snip add git/workflows/deploy

# Add with inline content
snip add kubernetes/pods
# Choose "inline" then enter content
```

#### Viewing Snippets

```bash
# Show a snippet (with variable substitution)
snip show docker/ps

# Show without variable substitution
snip raw docker/ps
# Or
snip show docker/ps --raw

# List all snippets in a directory
snip list docker

# Show snippet from a directory (opens fzf picker)
snip show docker/
```

#### Interactive Search

```bash
# Search and show (requires fzf and bat)
snip search

# Search with preview
snip fzf

# Search and edit
snip search --edit
# Or
snip search -e

# Search and show
snip search --show
# Or
snip search -s

# Search and delete
snip search --delete
# Or
snip search -d
```

#### Editing Snippets

```bash
# Edit a specific snippet
snip edit docker/ps

# Edit via interactive search (no argument opens fzf)
snip edit

# Edit encrypted snippet (auto-detects .gpg files)
snip edit passwords/api-key
# Opens in temp file, encrypts on save
# Press Ctrl-C to exit encrypted edit mode
```

#### Running Snippets

```bash
# Run a snippet (prompts for confirmation)
snip run docker/cleanup

# The script will:
# 1. Display the snippet
# 2. Prompt for any variables
# 3. Show the final command
# 4. Wait for CTRL-R to execute (or any key to cancel)
```

### Variable Substitution

Snippets can contain variables using the syntax `@{varName}`:

```bash
# Example snippet: docker/run
docker run -d \
  --name @{container_name} \
  -p @{port}:@{port} \
  @{image_name}
```

When you show or run this snippet, you'll be prompted for:

- `container_name`
- `port`
- `image_name`

Each unique variable is only prompted once, and all instances are replaced with the same value.

#### Default Values

You can specify default values for variables using the `defaults to` syntax:

```bash
# Example snippet: docker/run-with-defaults
docker run -d \
  --name @{container_name defaults to my-app} \
  -p @{port defaults to 8080}:@{port defaults to 8080} \
  @{image_name defaults to nginx:latest}
```

When prompted, the default value will be pre-filled. Simply press Enter to accept the default, or type a new value to override it.

**Default value syntax:**

- `@{varName defaults to defaultValue}` - Variable with a default
- The default value appears after the ` defaults to ` delimiter
- Spaces are preserved in default values

**Example with complex defaults:**

```bash
# Snippet: deploy/kubernetes
kubectl apply -f @{manifest defaults to deployment.yaml}
kubectl rollout status deployment/@{app_name defaults to my-application}
```

### Encryption

#### Create a New GPG Key

1. Run `gpg --full-generate-key`
2. Select RSA and RSA (option 1)
3. Choose 4096-bit key size
4. Set expiration (recommended: 1 year or never)
5. Enter your name and email
6. Set a strong passphrase or leave it empty
   - Empty passphrase: No prompt when decrypting
   - Strong passphrase: More secure, prompts each time
7. View your key with `gpg --list-keys`
8. Copy your key ID

To see your newly created key, run:

```bash
gpg --list-keys
```

You'll see output like:
```
pub   rsa4096 2026-01-02 [SC] [expires: 2027-01-02]
      A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0
uid           [ultimate] John Doe <john.doe@example.com>
sub   rsa4096 2026-01-02 [E] [expires: 2027-01-02]
```

The key ID is the long hexadecimal string: `A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0`

**Remember:** Keep your private key and passphrase secure. Never share your private key with anyone.

#### Setup GPG Encryption

```bash
# Set your GPG ID
snip gpg_id A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0

# View current GPG ID
snip gpg_id
```

#### Encrypt/Decrypt Snippets

```bash
# Encrypt a snippet
snip encrypt passwords/api-keys
# Creates passwords/api-keys.gpg and removes original

# Decrypt and view
snip show passwords/api-keys
# Automatically detects .gpg extension

# Decrypt to stdout
snip decrypt passwords/api-keys

# Edit encrypted snippet
snip edit passwords/api-keys
# Opens in temp file, auto-saves encrypted version
# Watch for file changes and re-encrypt on save
# Press Ctrl-C to exit
```

#### Store Secrets

```bash
# Create encrypted secret
snip add secrets/openai/api-key

# Encrypt it
snip encrypt secrets/openai/api-key

# View decrypted content
snip show secrets/openai/api-key
# Or
snip raw secrets/openai/api-key
```

### OTP/TOTP Management

Snip includes built-in support for managing TOTP (Time-based One-Time Password) codes for two-factor authentication.

#### OTP Commands

| Action | Command | Description |
|--------|---------|-------------|
| Create | `snip otp myservice` | Create new OTP secret or show an existing TOTP code |
| Show | `snip otp show myservice` | Show current TOTP code |
| Edit | `snip otp edit myservice` | Edit OTP secret |
| Delete | `snip otp del myservice` | Delete OTP secret |

**Note:** When no action is specified, `show` is the default behavior.

#### Create OTP Code

```bash
# Create new OTP secret
snip otp myservice
# Prompts for OTP secret
# Asks if you want to encrypt it

# Create OTP in subfolder
snip otp github/personal
```

#### View OTP Code

```bash
# Show current TOTP code (explicit action)
snip otp show myservice
# Outputs: 123456

# Show current TOTP code (implicit, same as above)
snip otp myservice

# Interactive selection (no argument)
snip otp
# Opens fzf to select from available OTP secrets
```

#### Edit OTP Secret

```bash
# Edit OTP secret
snip otp edit myservice
# Prompts for new secret value

# Edit encrypted OTP
snip otp edit github/personal
# Decrypts, allows editing, re-encrypts
```

#### Delete OTP

```bash
# Delete OTP secret
snip otp del myservice

# Delete encrypted OTP
snip otp del github/personal
# Removes the .gpg file
```

**Note:** OTP secrets are stored in `~/.snip/snippets/otp/` and can be encrypted for additional security.

### Password Management

Snip includes built-in password management functionality to securely store credentials with username, password, URL, and notes.

#### Password Commands

| Action | Command | Description |
|--------|---------|-------------|
| Create | `snip password myservice` | Create new password entry or show existing one |
| Show All | `snip password show myservice` | Show all password fields |
| Show Password | `snip password show -p myservice` | Show only password |
| Show Username | `snip password show -u myservice` | Show only username |
| Show URL | `snip password show -l myservice` | Show only URL |
| Show Notes | `snip password show -n myservice` | Show only notes |
| Edit | `snip password edit myservice` | Edit password entry |
| Delete | `snip password del myservice` | Delete password entry |

**Note:** When no action is specified, `show` is the default behavior.

#### Create Password Entry

```bash
# Create new password
snip password myservice
# Prompts for:
# - Username
# - Password
# - URL
# - Notes (multi-line)
# Asks if you want to encrypt it

# Create password in subfolder
snip password github/personal
```

#### View Password

```bash
# Show all fields (explicit action)
snip password show myservice
# Output:
# username:john.doe
# password:secretpass123
# url:https://example.com
# notes:My notes here

# Show all fields (implicit, same as above)
snip password myservice

# Show only password
snip password show -p myservice
# Output: secretpass123

# Show only username
snip password show -u myservice
# Output: john.doe

# Show only URL
snip password show -l myservice
# Output: https://example.com

# Show only notes
snip password show -n myservice
# Output: My notes here

# Interactive selection (no argument)
snip password
# Opens fzf to select from available passwords
```

#### Edit Password

```bash
# Edit password entry
snip password edit myservice
# Prompts for each field with current value pre-filled

# Edit encrypted password
snip password edit github/personal
# Decrypts, allows editing, re-encrypts
```

#### Delete Password

```bash
# Delete password entry
snip password del myservice

# Delete encrypted password
snip password del github/personal
# Removes the .gpg file
```

**Note:** Password entries are stored in `~/.snip/snippets/passwords/` and can be encrypted for additional security.

### Sharing Snippets

```bash
# Share a snippet (gets a termbin.com URL)
snip share docker/compose
# Returns: http://termbin.com/xxxxx

# Share from directory (opens fzf picker)
snip share docker/

# Encrypted snippets prompt for confirmation
snip share passwords/config
# Asks: "passwords/config is encrypted, share unencrypted?"
```

### Git Sync

```bash
# Initialize git repository first
cd ~/.snip
git init
git remote add origin <your-repo-url>
git branch -M main
git add .
git commit -m "Initial commit"
git push -u origin main

# Sync snippets (auto-commit and push)
snip sync
# Uses default message: "Updated Snippets YYYY-MM-DD HH:MM:SS"

# Sync with custom message
snip sync "Added new docker snippets"
```

### Rofi Integration

For GUI-based snippet selection (requires rofi):

```bash
# Copy snippet to clipboard (default)
snip runrofi
# Or explicitly
snip runrofi --copy
snip runrofi -c

# Edit snippet via rofi
snip runrofi --edit
snip runrofi -e

# Add new snippet via rofi
snip runrofi --add
snip runrofi -a
```

Set custom rofi theme:

```bash
# In ~/.snip/.env
ROFI_USER_THEME=/path/to/your/theme.rasi
```

## Copy To Clipboard

**Note:** The rofi copy function uses `pbcopy` (macOS). For Linux, you need `xclip` or `xsel`.
**On Linux:**
Add this in your .bashrc

```bash
alias pbcopy='xclip -selection clipboard'
```

## Snippet Organization

Organize snippets in directories for better management:

```bash
~/.snip/snippets/
├── docker/
│   ├── ps
│   ├── cleanup
│   └── compose/
│       ├── up
│       └── down
├── git/
│   ├── rebase
│   └── workflows/
│       └── deploy
├── kubernetes/
│   ├── pods
│   └── services
├── otp/
│   ├── github.gpg
│   ├── google.gpg
│   └── aws.gpg
├── passwords/
│   ├── github.gpg
│   ├── google.gpg
│   └── work-email.gpg
└── secrets/
    ├── api-keys.gpg
    └── tokens.gpg
```

## Advanced Usage

### Working with Directories

```bash
# Show snippet from a directory (opens fzf picker)
snip show docker/

# Edit from directory
snip edit kubernetes/

# Delete entire directory
snip del docker/
# Prompts for confirmation before deleting directory

# List directory tree
snip list docker/
```

### Script Integration

```bash
# Get snippet content programmatically
snippet_content=$(snip raw docker/ps)

# Use in scripts
snip show deployment/prod | bash

# Get OTP in script
otp_code=$(snip otp github)
curl -H "X-OTP: $otp_code" https://api.example.com
```

### Encrypted Workflow

```bash
# Complete encrypted workflow
snip add secrets/db-password
# Enter password content
snip encrypt secrets/db-password

# Edit encrypted secret
snip edit secrets/db-password
# Opens temp file, auto-saves encrypted
# Ctrl-C to exit

# Use in script
DB_PASS=$(snip raw secrets/db-password)
```

## Security Notes

1. **Encryption**: Encrypted snippets use GPG and require your GPG key
2. **Sharing**: Warning when sharing encrypted snippets
3. **Execution**: `run` command requires confirmation (CTRL-R) before execution
5. **OTP Secrets**: Consider encrypting OTP secrets for additional security
6. **Encrypted Editing**: Temporary decrypted files are used during editing

## Troubleshooting

### Editor Not Found

```bash
# Set your preferred editor
echo "EDITOR=nano" >> ~/.snip/.env
# Or
snip config edit
```

### GPG Errors

```bash
# Verify GPG ID is set
snip gpg_id

# List available GPG keys
gpg --list-keys

# Set GPG ID
snip gpg_id YOUR_KEY_ID
```

### Missing Dependencies

```bash
# Check what's missing
snip doctor

# Install on Ubuntu/Debian
sudo apt install fzf bat tree gpg

# Install on macOS
brew install fzf bat tree gnupg gum

# Install gum (cross-platform)
brew install gum
# Or see: https://github.com/charmbracelet/gum
```

### OTP Not Working

```bash
# Install oathtool
# Ubuntu/Debian
sudo apt install oathtool

# macOS
brew install oath-toolkit
```

### Encrypted Edit Not Saving

- Ensure you have write permissions to `~/.snip/snippets/`
- Check that your GPG key is properly configured
- Verify the GPG ID matches your key: `snip gpg_id`

### Platform-Specific Issues

**macOS:**

- Uses `stat -f %m` for file modification time
- Uses `pbcopy` for clipboard in rofi mode

**Linux:**

- Uses `stat -c %Y` for file modification time
- May need `xclip` or `xsel` for clipboard support

## Tips & Tricks

1. **Quick Access**: Create shell aliases:

   ```bash
   alias s='snip'
   alias sr='snip run'
   alias sf='snip search'
   alias se='snip edit'
   alias sotp='snip otp'
   alias spsw='snip password'
   ```

2. **Template Snippets with Defaults**:

   ```bash
   # Snippet: projects/new
   mkdir -p @{project_name}/{src,tests,docs}
   cd @{project_name}
   git init
   echo "# @{project_name}" > README.md
   npm init -y
   echo "node_modules" > .gitignore
   code @{editor_flags defaults to .}
   ```

3. **Backup**: Regular sync keeps snippets safe:

   ```bash
   # Add to cron (every 6 hours)
   0 */6 * * * snip sync "Auto backup"
   ```

4. **Categories**: Use consistent naming for easy searching:

   ```bash
   snip search docker    # Shows all docker-related snippets
   snip list kubernetes  # List all k8s snippets
   ```

5. **Encrypted OTP**: Store 2FA codes securely:

   ```bash
   snip otp github
   # Choose to encrypt when prompted
   # Later: snip otp github outputs current code
   ```

6. **Password Management**: Store credentials with full details:

   ```bash
   snip password github
   # Enter username, password, URL, and notes
   # Choose to encrypt when prompted
   # Later: snip password show -p github outputs just the password
   ```

7. **Complex Variables with Defaults**: Chain snippets with sensible defaults:

   ```bash
   # Snippet: deploy/app
   IMAGE=@{docker_image defaults to myapp}
   TAG=@{version defaults to latest}
   REPLICAS=@{replicas defaults to 3}
   kubectl set image deployment/@{app_name defaults to web} app=$IMAGE:$TAG
   kubectl scale deployment/@{app_name defaults to web} --replicas=$REPLICAS
   ```

8. **Interactive Editing**: Use fzf for quick access:

   ```bash
   snip edit
   # Opens fzf, select snippet, edit immediately
   ```

9. **Safe Deletion**: Preview before deleting:

   ```bash
   snip del
   # Opens fzf with preview, select to delete
   # Confirms before deletion (especially for directories)
   ```

## Common Workflows

### Managing Passwords

```bash
# Store encrypted password
snip password github/work
# Enter username, password, URL, and notes
# Choose to encrypt

# Get password in scripts
GITHUB_USER=$(snip password show -u github/work)
GITHUB_PASS=$(snip password show -p github/work)

# Or just view all details
snip password show github/work
```

### Managing API Keys

```bash
# Store encrypted API key
snip add secrets/openai/key
snip encrypt secrets/openai/key

# Use in scripts
API_KEY=$(snip raw secrets/openai/key)
curl -H "Authorization: Bearer $API_KEY" https://api.openai.com
```

### Quick Commands

```bash
# Store frequently used commands
snip add docker/cleanup
# Content: docker system prune -af --volumes

# Run with one command
snip run docker/cleanup
```

### Project Templates

```bash
# Create project template with variables and defaults
snip add templates/react-app
# Content:
# npx create-react-app @{app_name defaults to my-app}
# cd @{app_name defaults to my-app}
# npm install @{dependencies defaults to axios}

# Use template
snip run templates/react-app
# Prompts with pre-filled defaults for: app_name, dependencies
```

### SSH Connection Manager

```bash
# Create SSH snippets with defaults
snip add ssh/production
# Content:
# ssh @{user defaults to deploy}@@{host defaults to prod.example.com} -p @{port defaults to 22}

# Quick connect
snip run ssh/production
```

## File Structure

```bash
~/.snip/
├── .env                 # Configuration file
├── .gpgid              # GPG key ID for encryption
├── .git/               # Git repository (optional)
└── snippets/           # All snippets
    ├── docker/
    │   ├── ps
    │   └── cleanup
    ├── secrets/
    │   └── api-key.gpg  # Encrypted snippets
    ├── otp/
    │   └── github.gpg   # Encrypted OTP secrets
    └── passwords/
        └── github.gpg   # Encrypted password entries
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This script is provided as-is for personal and commercial use.

## Changelog

### Latest Version

- ✅ Added password management with username, password, URL, and notes fields
- ✅ Added password show flags (-p, -u, -l, -n) for selective field display
- ✅ Added variable default values with `@{var defaults to value}` syntax
- ✅ Added OTP/TOTP support for 2FA codes with show/edit/del actions
- ✅ Added `doctor` command to check dependencies
- ✅ Improved encrypted snippet editing with auto-save
- ✅ Enhanced error handling with `gum` integration
- ✅ Better platform detection (macOS/Linux)
- ✅ Interactive prompts with `gum`
- ✅ Improved search with better fzf integration
- ✅ Enhanced encrypted file handling
- ✅ Better directory deletion with confirmation

## Resources

- [fzf - Fuzzy Finder](https://github.com/junegunn/fzf)
- [bat - Cat Clone with Syntax Highlighting](https://github.com/sharkdp/bat)
- [gum - Interactive CLI Tool](https://github.com/charmbracelet/gum)
- [GPG Documentation](https://www.gnupg.org/documentation/)
- [OATH Toolkit](https://www.nongnu.org/oath-toolkit/)
