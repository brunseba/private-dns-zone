#!/bin/bash
# Setup script for pre-commit hooks and quality tools
# This script installs and configures pre-commit for the DNS repository

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script information
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install pre-commit
install_pre_commit() {
    log_info "Installing pre-commit..."
    
    if command_exists pip3; then
        pip3 install --user pre-commit
    elif command_exists pip; then
        pip install --user pre-commit
    elif command_exists brew; then
        log_info "Installing pre-commit via Homebrew..."
        brew install pre-commit
    elif command_exists conda; then
        log_info "Installing pre-commit via Conda..."
        conda install -c conda-forge pre-commit
    else
        log_error "No package manager found. Please install pre-commit manually:"
        log_error "pip install pre-commit"
        exit 1
    fi
    
    log_success "Pre-commit installed successfully"
}

# Install additional quality tools
install_quality_tools() {
    log_info "Installing additional quality tools..."
    
    # Install hadolint for Dockerfile linting
    if ! command_exists hadolint; then
        log_info "Installing hadolint for Dockerfile linting..."
        if command_exists brew; then
            brew install hadolint
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            wget -O /tmp/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
            chmod +x /tmp/hadolint
            sudo mv /tmp/hadolint /usr/local/bin/hadolint
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            wget -O /tmp/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Darwin-x86_64
            chmod +x /tmp/hadolint
            sudo mv /tmp/hadolint /usr/local/bin/hadolint
        fi
        log_success "Hadolint installed"
    else
        log_info "Hadolint already installed"
    fi
    
    # Install shellcheck for shell script linting
    if ! command_exists shellcheck; then
        log_info "Installing shellcheck for shell script linting..."
        if command_exists brew; then
            brew install shellcheck
        elif command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y shellcheck
        elif command_exists yum; then
            sudo yum install -y ShellCheck
        elif command_exists dnf; then
            sudo dnf install -y ShellCheck
        else
            log_warning "Could not install shellcheck automatically. Please install manually."
        fi
        
        if command_exists shellcheck; then
            log_success "Shellcheck installed"
        else
            log_warning "Shellcheck installation may have failed"
        fi
    else
        log_info "Shellcheck already installed"
    fi
    
    # Install yamllint for YAML linting
    if ! command_exists yamllint; then
        log_info "Installing yamllint for YAML linting..."
        if command_exists pip3; then
            pip3 install --user yamllint
        elif command_exists pip; then
            pip install --user yamllint
        else
            log_warning "Could not install yamllint. Please install manually with: pip install yamllint"
        fi
        
        if command_exists yamllint; then
            log_success "Yamllint installed"
        fi
    else
        log_info "Yamllint already installed"
    fi
    
    # Install markdownlint for Markdown linting
    if ! command_exists markdownlint; then
        log_info "Installing markdownlint for Markdown linting..."
        if command_exists npm; then
            npm install -g markdownlint-cli
            log_success "Markdownlint installed"
        else
            log_warning "Node.js/npm not found. Please install markdownlint manually with: npm install -g markdownlint-cli"
        fi
    else
        log_info "Markdownlint already installed"
    fi
}

# Setup pre-commit hooks
setup_pre_commit_hooks() {
    log_info "Setting up pre-commit hooks..."
    
    cd "$PROJECT_ROOT"
    
    # Install the pre-commit hooks
    if command_exists pre-commit; then
        pre-commit install
        pre-commit install --hook-type commit-msg
        log_success "Pre-commit hooks installed"
        
        # Update hooks to latest versions
        log_info "Updating hooks to latest versions..."
        pre-commit autoupdate
        log_success "Hooks updated"
        
        # Run pre-commit on all files to test setup
        log_info "Running pre-commit on all files (this may take a while)..."
        if pre-commit run --all-files; then
            log_success "All pre-commit checks passed!"
        else
            log_warning "Some pre-commit checks failed. This is normal for initial setup."
            log_info "Files have been automatically fixed where possible."
            log_info "Please review the changes and commit them."
        fi
    else
        log_error "Pre-commit not found in PATH. Please ensure it's installed correctly."
        exit 1
    fi
}

# Create configuration files for quality tools
create_config_files() {
    log_info "Creating configuration files for quality tools..."
    
    # Create .eslintrc.js for JavaScript linting
    if [[ ! -f "$PROJECT_ROOT/.eslintrc.js" ]]; then
        cat > "$PROJECT_ROOT/.eslintrc.js" << 'EOF'
module.exports = {
  env: {
    node: true,
    es2021: true,
  },
  extends: [
    'standard'
  ],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module',
  },
  rules: {
    // DNS-specific rules for DNSControl
    'no-undef': 'off', // DNSControl has global functions
    'camelcase': 'off', // DNS records often use underscores
  },
  globals: {
    // DNSControl global functions
    'NewDnsProvider': 'readonly',
    'NewRegistrar': 'readonly',
    'D': 'readonly',
    'A': 'readonly',
    'AAAA': 'readonly',
    'CNAME': 'readonly',
    'MX': 'readonly',
    'TXT': 'readonly',
    'PTR': 'readonly',
    'SRV': 'readonly',
    'NS': 'readonly',
    'SOA': 'readonly',
    'env': 'readonly',
  },
}
EOF
        log_success "ESLint configuration created"
    fi
    
    # Create .prettierrc for code formatting
    if [[ ! -f "$PROJECT_ROOT/.prettierrc" ]]; then
        cat > "$PROJECT_ROOT/.prettierrc" << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "avoid",
  "endOfLine": "lf"
}
EOF
        log_success "Prettier configuration created"
    fi
    
    # Create .flake8 for Python linting
    if [[ ! -f "$PROJECT_ROOT/.flake8" ]]; then
        cat > "$PROJECT_ROOT/.flake8" << 'EOF'
[flake8]
max-line-length = 88
extend-ignore = E203, W503, E501
exclude = 
    .git,
    __pycache__,
    .venv,
    venv,
    .tox,
    build,
    dist,
    *.egg-info
per-file-ignores =
    __init__.py:F401
EOF
        log_success "Flake8 configuration created"
    fi
}

# Update .gitignore with quality tool artifacts
update_gitignore() {
    log_info "Updating .gitignore with quality tool artifacts..."
    
    GITIGNORE_ADDITIONS="
# Pre-commit and quality tools
.pre-commit-cache/
.mypy_cache/
.pytest_cache/
.coverage
htmlcov/
.tox/
.cache/

# Editor and IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Node.js (for JavaScript linting)
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Python
__pycache__/
*.py[cod]
*\$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST
"
    
    if [[ -f "$PROJECT_ROOT/.gitignore" ]]; then
        if ! grep -q "Pre-commit and quality tools" "$PROJECT_ROOT/.gitignore"; then
            echo "$GITIGNORE_ADDITIONS" >> "$PROJECT_ROOT/.gitignore"
            log_success "Updated .gitignore with quality tool artifacts"
        else
            log_info ".gitignore already contains quality tool entries"
        fi
    else
        echo "$GITIGNORE_ADDITIONS" > "$PROJECT_ROOT/.gitignore"
        log_success "Created .gitignore with quality tool artifacts"
    fi
}

# Display final instructions
show_final_instructions() {
    log_success "Pre-commit setup complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Pre-commit will now run automatically on every commit"
    echo "  2. To run pre-commit manually: pre-commit run --all-files"
    echo "  3. To update hooks: pre-commit autoupdate"
    echo "  4. To skip pre-commit for a commit: git commit --no-verify"
    echo ""
    log_info "Available quality checks:"
    echo "  • YAML/JSON syntax validation"
    echo "  • Dockerfile linting with hadolint"
    echo "  • Shell script linting with shellcheck"
    echo "  • Markdown formatting and linting"
    echo "  • Python code formatting (Black) and linting (flake8)"
    echo "  • JavaScript linting (ESLint)"
    echo "  • BIND configuration validation"
    echo "  • TSIG key format validation"
    echo "  • Docker Compose validation"
    echo "  • Documentation link checking"
    echo "  • Conventional commit message format"
    echo ""
    log_info "Configuration files created:"
    echo "  • .pre-commit-config.yaml - Pre-commit configuration"
    echo "  • .eslintrc.js - JavaScript linting rules"
    echo "  • .prettierrc - Code formatting rules"
    echo "  • .flake8 - Python linting configuration"
    echo ""
    log_warning "Note: The first run may take longer as hooks are installed."
    log_info "For more information, see: https://pre-commit.com/"
}

# Main execution
main() {
    log_info "Setting up pre-commit and quality tools for DNS repository..."
    echo ""
    
    # Check if pre-commit is already installed
    if ! command_exists pre-commit; then
        install_pre_commit
    else
        log_info "Pre-commit already installed"
    fi
    
    # Install additional quality tools
    install_quality_tools
    
    # Create configuration files
    create_config_files
    
    # Update .gitignore
    update_gitignore
    
    # Setup pre-commit hooks
    setup_pre_commit_hooks
    
    # Show final instructions
    show_final_instructions
}

# Run main function
main "$@"
