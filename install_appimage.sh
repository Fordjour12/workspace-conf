#!/bin/bash

# AppImage System-Wide Installer Script
# Usage: ./install_appimage.sh /path/to/your/appimage.AppImage

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        print_error "Please run it as a regular user (it will use sudo when needed)"
        exit 1
    fi
}

# Check if AppImage path is provided
check_args() {
    if [[ $# -eq 0 ]]; then
        print_error "Usage: $0 /path/to/your/appimage.AppImage"
        print_error "Example: $0 ~/Downloads/myapp.AppImage"
        exit 1
    fi
    
    APPIMAGE_PATH="$1"
    
    if [[ ! -f "$APPIMAGE_PATH" ]]; then
        print_error "File not found: $APPIMAGE_PATH"
        exit 1
    fi
    
    if [[ ! "$APPIMAGE_PATH" =~ \.AppImage$ ]]; then
        print_error "File does not appear to be an AppImage: $APPIMAGE_PATH"
        exit 1
    fi
}

# Extract application name from AppImage
get_app_name() {
    # Try to get the name from the AppImage filename
    local filename=$(basename "$APPIMAGE_PATH")
    local app_name="${filename%.AppImage}"
    
    # Remove common prefixes/suffixes
    app_name=$(echo "$app_name" | sed 's/^[0-9]*//' | sed 's/-[0-9].*$//' | sed 's/-x86_64$//' | sed 's/-amd64$//')
    
    # Capitalize first letter
    app_name=$(echo "$app_name" | sed 's/^./\U&/')
    
    echo "$app_name"
}

# Check if application is already installed
check_existing_installation() {
    local app_name="$1"
    local app_name_lower=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')

    local install_dir="/opt/${app_name_lower}"
    local bin_link="/usr/local/bin/$app_name_lower"
    local desktop_file="/usr/share/applications/${app_name_lower}.desktop"

    local is_installed=false

    if [[ -d "$install_dir" ]]; then
        print_warning "Application directory already exists: $install_dir"
        is_installed=true
    fi

    if [[ -L "$bin_link" ]]; then
        print_warning "Terminal command already exists: $bin_link"
        is_installed=true
    fi

    if [[ -f "$desktop_file" ]]; then
        print_warning "Desktop entry already exists: $desktop_file"
        is_installed=true
    fi

    if [[ "$is_installed" == true ]]; then
        echo
        print_warning "This application appears to already be installed."
        read -p "Do you want to reinstall/update it? (y/N): " -n 1 -r
        echo

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installation cancelled"
            exit 0
        fi

        # Remove existing installation
        print_status "Removing existing installation..."
        sudo rm -rf "$install_dir" 2>/dev/null || true
        sudo rm -f "$bin_link" 2>/dev/null || true
        sudo rm -f "$desktop_file" 2>/dev/null || true
    fi
}

# Install AppImage system-wide
install_appimage() {
    local app_name="$1"
    local app_name_lower=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')

    # Check for existing installation
    check_existing_installation "$app_name"

    # Create system-wide directory for this specific application
    local install_dir="/opt/${app_name_lower}"
    print_status "Creating installation directory: $install_dir"
    sudo mkdir -p "$install_dir"

    # Copy AppImage to application-specific directory
    local target_path="$install_dir/${app_name}.AppImage"
    print_status "Copying AppImage to: $target_path"
    sudo cp "$APPIMAGE_PATH" "$target_path"

    # Make it executable
    print_status "Making AppImage executable"
    sudo chmod +x "$target_path"

    # Create symlink in /usr/local/bin for terminal access
    local bin_link="/usr/local/bin/$app_name_lower"
    print_status "Creating symlink in PATH: $bin_link"
    sudo ln -sf "$target_path" "$bin_link"

    # Create desktop entry
    create_desktop_entry "$app_name" "$app_name_lower" "$target_path"

    print_success "AppImage installed successfully!"
    print_status "You can now run '$app_name_lower' from the terminal"
    print_status "The application is also available in your applications menu"
}

# Create desktop entry for the application
create_desktop_entry() {
    local app_name="$1"
    local app_name_lower="$2"
    local appimage_path="$3"
    
    local desktop_dir="/usr/share/applications"
    local desktop_file="$desktop_dir/${app_name_lower}.desktop"
    
    print_status "Creating desktop entry: $desktop_file"
    
    # Create desktop entry content
    cat << EOF | sudo tee "$desktop_file" > /dev/null
[Desktop Entry]
Name=$app_name
Comment=$app_name Application
Exec=$appimage_path
Icon=$appimage_path
Terminal=false
Type=Application
Categories=Utility;Application;
MimeType=
EOF
    
    # Set proper permissions
    sudo chmod 644 "$desktop_file"
}

# Update desktop database
update_desktop_database() {
    print_status "Updating desktop database..."
    if command -v update-desktop-database >/dev/null 2>&1; then
        sudo update-desktop-database /usr/share/applications
    fi
}

# Main installation process
main() {
    print_status "AppImage System-Wide Installer"
    print_status "================================"
    
    check_root
    check_args "$@"
    
    local app_name=$(get_app_name)
    print_status "Detected application name: $app_name"
    
    # Confirm installation
    echo
    print_warning "This will install '$app_name' system-wide:"
    print_status "  - Copy to: /opt/${app_name_lower}/"
    print_status "  - Create symlink in: /usr/local/bin/"
    print_status "  - Create desktop entry in: /usr/share/applications/"
    echo
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
    
    install_appimage "$app_name"
    update_desktop_database
    
    echo
    print_success "Installation completed successfully!"
    print_status "You can now run '$app_name' from anywhere in the terminal"
}

# Run main function with all arguments
main "$@"
