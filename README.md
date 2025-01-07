# Go Language Installer for macOS
Bash script for installing Go (Golang) on macOS. Supports both system-wide and user-specific installations.

## Features

- ✅ Supports both system-wide and user-specific installations
- ✅ Automatic latest version detection
- ✅ Custom version selection
- ✅ SHA256 checksum verification
- ✅ Automatic PATH configuration
- ✅ Multiple shell support (zsh, bash)
- ✅ Homebrew installation detection and cleanup
- ✅ Backup of modified shell configuration files
- ✅ Error handling

## Requirements

- macOS operating system
- curl
- tar
- shasum
- sudo access (for system-wide installation only)

## Installation

1. Download the installer script:
```bash
curl -O https://raw.githubusercontent.com/gmassawe/go-install/main/install.sh
```

2. Make the script executable:
```bash
chmod +x install.sh
```

## Usage

Run the script:
```bash
./install.sh
```

The script will guide you through the installation process with interactive prompts:

1. Choose installation type:
   - System-wide (requires sudo)
   - User-only (installed in ~/.local/go)

2. Select Go version:
   - Latest version (default)
   - Specific version (if needed)

### Installation Types

#### System-wide Installation
- Install location: `/usr/local/go`
- Requires sudo access
- Available to all users
- PATH update: `/usr/local/go/bin`

#### User-only Installation
- Install location: `~/.local/go`
- No sudo required
- Available only to current user
- PATH update: `$HOME/.local/go/bin`

## Shell Configuration

The script automatically updates your shell configuration file (`~/.zshrc`, `~/.bashrc`, or `~/.bash_profile`) to include the Go binary path. A backup of your original configuration file is created before any modifications.

## Examples

### Default Installation (Latest Version)
```bash
$ ./install.sh
[>] Select installation type:
1) System-wide installation (requires sudo)
2) User-only installation
Enter your choice (1 or 2): 1
[>] The latest version of Go is 1.21.5
[>] Installing Go 1.21.5...
```

### Specific Version Installation
```bash
$ ./install.sh
[>] Select installation type:
1) System-wide installation (requires sudo)
2) User-only installation
Enter your choice (1 or 2): 2
[>] The latest version of Go is 1.21.5
Enter the version you want to install (default: 1.21.5): 1.20.12
[>] Installing Go 1.20.12...
```

## Verification

After installation, verify Go is installed correctly:
```bash
go version
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   [ERROR]: Failed to remove existing Go installation
   ```
   Solution: Ensure you have appropriate permissions. For system-wide installation, use a sudo-enabled user.

2. **Checksum Verification Failed**
   ```bash
   [ERROR]: Checksum verification failed
   ```
   Solution: Re-run the script. If the error persists, check your internet connection or try a different version.

3. **PATH Not Updated**
   ```bash
   go: command not found
   ```
   Solution: Restart your terminal or run:
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

## Security

This script includes several security features:
- SHA256 checksum verification of downloaded files
- Secure temporary directory usage
- Backup of modified configuration files
- No external dependencies beyond standard Unix tools

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License
```
This project is licensed under the MIT License 
```
