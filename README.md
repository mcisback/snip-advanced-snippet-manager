# Snip - Advanced Snippet Manager
## Written in Bash

A powerful command-line snippet manager for storing, organizing, and executing code snippets and commands with support for encryption, variables, and multiple interfaces (CLI, fzf, rofi).

## Features

- **Snippet Management**: Create, edit, delete, list, and search snippets
- **Variable Substitution**: Use `@{varName}` placeholders for dynamic values
- **GPG Encryption**: Encrypt sensitive snippets with GPG
- **Multiple Interfaces**: CLI, fzf search, and rofi integration
- **Git Sync**: Version control and sync snippets across devices
- **Share Snippets**: Quick sharing via termbin.com
- **Safe Execution**: Preview and confirm before running snippets

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
- `gpg` (for encryption features)

### Optional
- `fzf` - For interactive snippet search (here: https://github.com/junegunn/fzf)
- `bat` - For syntax-highlighted preview (here: https://github.com/sharkdp/bat)
- `rofi` - For GUI snippet selection (optional)
- `gum` - For enhanced interactive prompts (here: https://github.com/charmbracelet/gum)
- `tree` - For directory listing
- `git` - For sync functionality
- `terminal-notifier` or `notify-send` - For notifications (optional, required if you use rofi)

## Configuration

On first run, snip creates:
- `~/.snip/` - Main directory
- `~/.snip/snippets/` - Snippets storage
- `~/.snip/.env` - Configuration file

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

| Command | Alias | Description |
|---------|-------|-------------|
| `help` | `h` | Display help information |
| `add` | `a` | Create a new snippet |
| `edit` | `e` | Edit an existing snippet |
| `del` | `d` | Delete a snippet |
| `list` | `ls` | List snippets in a directory |
| `search` | `fzf` | Search snippets interactively |
| `show` | `s` | Display a snippet |
| `raw` | `rw` | Show snippet without variable parsing |
| `run` | `r` | Execute a snippet |
| `share` | `shr` | Share snippet via termbin |
| `sync` | `u` | Sync with git repository |
| `config` | `c` | Manage configuration |
| `runrofi` | `rf` | Run rofi interface |
| `gpg_id` | `gi` | Set GPG ID for encryption |
| `encrypt` | `enc` | Encrypt a snippet |
| `decrypt` | `dec` | Decrypt a snippet |

### Examples

#### Creating Snippets

```bash
# Create a simple snippet
snip add docker/ps
# Opens editor to create ~/.snip/snippets/docker/ps

# Create nested snippet
snip add git/workflows/deploy
```

#### Viewing Snippets

```bash
# Show a snippet
snip show docker/ps

# Show without variable substitution
snip raw docker/ps

# List all snippets in a directory
snip list docker
```

#### Interactive Search

```bash
# Search and show (requires fzf and bat)
snip search

# Search and edit
snip search --edit

# Search and delete
snip search --delete

# Search by name
snip search docker
```

#### Running Snippets

```bash
# Run a snippet (prompts for confirmation)
snip run docker/cleanup

# The script will:
# 1. Display the snippet
# 2. Prompt for any variables
# 3. Ask for confirmation (CTRL-R to run)
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

### Encryption

#### Create a new GPG key

1. Run `gpg --full-generate-key`
2. Select RSA and RSA (option 1)
3. Choose 4096-bit key size
4. Set expiration (recommended never)
5. Enter your name and email
6. Set a strong passphrase or leave it empty, with empty passphrase you don't need to enter it every time you decrypt a snippet
7. View your key with `gpg --list-keys`
8. Copy your key ID using the methods below

To see your newly created key, run:

```bash
gpg --list-keys
```

You'll see output like:
```
pub   rsa4096 2026-01-02 [SC] [expires: 2027-01-02]
      A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0
uid           [ultimate] John Doe (Work laptop key) <john.doe@example.com>
sub   rsa4096 2026-01-02 [E] [expires: 2027-01-02]
```

In this example, the key ID is `A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0`.

**Remember:** Keep your private key and passphrase secure. Never share your private key with anyone.

#### Setup GPG Encryption

```bash
# Set your GPG ID
snip gpg_id your-gpg-key-id
# For example, if your key ID is A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0:
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
```

#### Store Secrets

```bash
snip add secrets/openai/myproject/api-key

# Encrypt a secret
snip encrypt secrets/openai/myproject/api-key

# Decrypt and view
snip raw secrets/openai/myproject/api-keys
# OR
snip show secrets/openai/myproject/api-key
```


### Sharing Snippets

```bash
# Share a snippet (gets a termbin.com URL)
snip share docker/compose

# Encrypted snippets prompt for confirmation
snip share passwords/config
# Asks: "snippet is encrypted, share unencrypted?"
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

# Sync snippets
snip sync
# Or with custom message
snip sync "Added new docker snippets"
```

### Rofi Integration

For GUI-based snippet selection (requires rofi):

```bash
# Copy snippet to clipboard
snip runrofi --copy

# Edit snippet via rofi
snip runrofi --edit

# Add new snippet via rofi
snip runrofi --add
```

Set custom rofi theme:
```bash
# In ~/.snip/.env
ROFI_USER_THEME=/path/to/your/theme.rasi
```

## Snippet Organization

Organize snippets in directories for better management:

```
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
└── kubernetes/
    ├── pods
    └── services
```

## Advanced Usage

### Working with Directories

```bash
# Show snippet from a directory (opens fzf picker)
snip show docker/

# Delete entire directory
snip del docker/
# Prompts for confirmation (with gum)
```

### Script Integration

```bash
# Get snippet content programmatically
snippet_content=$(snip raw docker/ps)

# Use in scripts
snip show deployment/prod | bash
```

## Security Notes

1. **Encryption**: Encrypted snippets use GPG and require your GPG key
2. **Sharing**: Be careful when sharing encrypted snippets - you'll be prompted
3. **Execution**: The `run` command requires confirmation (CTRL-R) before execution
4. **Git Sync**: Ensure your git repository is private if storing sensitive data

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
```

### Missing Dependencies
```bash
# Install optional dependencies (Ubuntu/Debian)
sudo apt install fzf bat tree

# macOS
brew install fzf bat tree
# macOS or Linux
brew install gum
```

## Tips & Tricks

1. **Quick Access**: Create shell aliases:
   ```bash
   alias s='snip show'
   alias sr='snip run'
   alias sf='snip search'
   ```

2. **Template Snippets**: Use variables for reusable templates
   ```bash
   # Snippet: projects/new
   mkdir -p @{project_name}/{src,tests,docs}
   cd @{project_name}
   git init
   ```

3. **Backup**: Regular sync keeps snippets safe
   ```bash
   # Add to cron
   0 */6 * * * snip sync "Auto backup"
   ```

4. **Categories**: Use consistent naming for easy searching
   ```bash
   snip search docker    # Shows all docker-related snippets
   ```

## License

This script is provided as-is for personal and commercial use.
