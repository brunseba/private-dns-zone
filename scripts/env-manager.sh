#!/bin/bash

# Environment Manager for BIND DNS Server
# This script helps manage environment variables and configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}==== $1 ====${NC}"
}

# Function to generate a secure TSIG key
generate_tsig_key() {
    local key_name="$1"
    local algorithm="${2:-hmac-sha256}"
    
    print_info "Generating TSIG key: $key_name"
    
    # Generate a cryptographically secure key
    local key_secret
    key_secret=$(openssl rand -base64 32)
    
    echo "# TSIG Key: $key_name"
    echo "# Algorithm: $algorithm"
    echo "# Generated: $(date)"
    echo "${key_name}_SECRET=\"$key_secret\""
    echo ""
    
    # Also output in BIND format for reference
    echo "# BIND Configuration Format:"
    echo "# key \"$key_name\" {"
    echo "#     algorithm $algorithm;"
    echo "#     secret \"$key_secret\";"
    echo "# };"
    echo ""
}

# Function to generate all TSIG keys
generate_all_keys() {
    local output_file="$PROJECT_DIR/.env.keys"
    
    print_header "Generating All TSIG Keys"
    
    {
        echo "# Generated TSIG Keys for BIND DNS Server"
        echo "# Generated at: $(date)"
        echo "# WARNING: Keep these keys secure!"
        echo ""
        
        generate_tsig_key "TSIG_KEY"
        generate_tsig_key "ADMIN_KEY"
        generate_tsig_key "RNDC_KEY"
        
    } > "$output_file"
    
    chmod 600 "$output_file"
    print_info "Keys generated and saved to: $output_file"
    print_warning "Remember to copy these keys to your .env file!"
}

# Function to validate environment file
validate_env() {
    local env_file="${1:-$PROJECT_DIR/.env}"
    
    print_header "Validating Environment File: $env_file"
    
    if [[ ! -f "$env_file" ]]; then
        print_error "Environment file not found: $env_file"
        return 1
    fi
    
    # Check required variables
    local required_vars=(
        "BIND_IMAGE"
        "BIND_TAG"
        "BIND_CONTAINER_NAME"
        "DNS_PORT_UDP"
        "DNS_PORT_TCP"
        "RNDC_PORT"
        "TSIG_KEY_SECRET"
        "ADMIN_KEY_SECRET"
        "RNDC_KEY_SECRET"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" "$env_file"; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_error "Missing required variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        return 1
    fi
    
    # Check for default/insecure values
    local insecure_patterns=(
        "CHANGE_ME"
        "password"
        "admin"
        "dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24"
    )
    
    local warnings=()
    
    for pattern in "${insecure_patterns[@]}"; do
        if grep -q "$pattern" "$env_file"; then
            warnings+=("Found potentially insecure value: $pattern")
        fi
    done
    
    if [[ ${#warnings[@]} -gt 0 ]]; then
        print_warning "Security warnings:"
        for warning in "${warnings[@]}"; do
            echo "  - $warning"
        done
    fi
    
    print_info "Environment file validation completed"
}

# Function to create environment file from template
create_env_from_template() {
    local env_type="${1:-development}"
    local output_file="$PROJECT_DIR/.env"
    
    print_header "Creating Environment File: $env_type"
    
    if [[ -f "$output_file" ]]; then
        print_warning "Environment file already exists: $output_file"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Aborted"
            return 0
        fi
    fi
    
    # Copy from example
    if [[ -f "$PROJECT_DIR/.env.example" ]]; then
        cp "$PROJECT_DIR/.env.example" "$output_file"
        print_info "Created $output_file from .env.example"
    else
        print_error ".env.example not found"
        return 1
    fi
    
    # Customize for environment type
    case "$env_type" in
        "development")
            sed -i.bak 's/ENVIRONMENT=.*/ENVIRONMENT=development/' "$output_file"
            sed -i.bak 's/LOG_LEVEL=.*/LOG_LEVEL=debug/' "$output_file"
            sed -i.bak 's/DEBUG_MODE=.*/DEBUG_MODE=true/' "$output_file"
            ;;
        "staging")
            sed -i.bak 's/ENVIRONMENT=.*/ENVIRONMENT=staging/' "$output_file"
            sed -i.bak 's/LOG_LEVEL=.*/LOG_LEVEL=info/' "$output_file"
            sed -i.bak 's/DEBUG_MODE=.*/DEBUG_MODE=false/' "$output_file"
            ;;
        "production")
            sed -i.bak 's/ENVIRONMENT=.*/ENVIRONMENT=production/' "$output_file"
            sed -i.bak 's/LOG_LEVEL=.*/LOG_LEVEL=warning/' "$output_file"
            sed -i.bak 's/DEBUG_MODE=.*/DEBUG_MODE=false/' "$output_file"
            sed -i.bak 's/BIND_MEMORY_LIMIT=.*/BIND_MEMORY_LIMIT=1g/' "$output_file"
            ;;
    esac
    
    rm -f "$output_file.bak"
    print_info "Environment file customized for: $env_type"
    print_warning "Don't forget to generate new TSIG keys for production!"
}

# Function to show environment info
show_env_info() {
    local env_file="${1:-$PROJECT_DIR/.env}"
    
    print_header "Environment Information"
    
    if [[ ! -f "$env_file" ]]; then
        print_error "Environment file not found: $env_file"
        return 1
    fi
    
    echo "Environment File: $env_file"
    echo "Size: $(du -h "$env_file" | cut -f1)"
    echo "Modified: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$env_file" 2>/dev/null || stat -c "%y" "$env_file" 2>/dev/null)"
    echo ""
    
    echo "Key Variables:"
    grep -E "^(ENVIRONMENT|BIND_IMAGE|BIND_TAG|DNS_PORT_UDP|LOG_LEVEL)=" "$env_file" || true
    echo ""
    
    echo "Security Status:"
    if grep -q "CHANGE_ME" "$env_file"; then
        echo "  ❌ Contains default values"
    else
        echo "  ✅ No default values found"
    fi
    
    if grep -q "dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24" "$env_file"; then
        echo "  ❌ Contains sample TSIG keys"
    else
        echo "  ✅ Using custom TSIG keys"
    fi
}

# Function to backup environment file
backup_env() {
    local env_file="${1:-$PROJECT_DIR/.env}"
    local backup_dir="$PROJECT_DIR/backups"
    
    print_header "Backing Up Environment File"
    
    if [[ ! -f "$env_file" ]]; then
        print_error "Environment file not found: $env_file"
        return 1
    fi
    
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/.env.backup.$(date +%Y%m%d_%H%M%S)"
    
    cp "$env_file" "$backup_file"
    chmod 600 "$backup_file"
    
    print_info "Environment file backed up to: $backup_file"
}

# Show usage
usage() {
    cat << EOF
Usage: $0 <command> [arguments]

Commands:
  generate-keys              Generate new TSIG keys
  validate [env-file]        Validate environment file
  create-env <type>          Create environment file (development|staging|production)
  show-info [env-file]       Show environment information
  backup-env [env-file]      Backup environment file

Examples:
  $0 generate-keys
  $0 validate
  $0 create-env production
  $0 show-info
  $0 backup-env

Environment Types:
  development  - Debug enabled, verbose logging, lower resource limits
  staging      - Balanced settings for testing
  production   - Security focused, higher resource limits, minimal logging
EOF
}

# Main script logic
main() {
    case "${1:-}" in
        "generate-keys")
            generate_all_keys
            ;;
        "validate")
            validate_env "$2"
            ;;
        "create-env")
            create_env_from_template "$2"
            ;;
        "show-info")
            show_env_info "$2"
            ;;
        "backup-env")
            backup_env "$2"
            ;;
        "help"|"-h"|"--help"|"")
            usage
            ;;
        *)
            print_error "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
