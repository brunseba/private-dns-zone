#!/bin/bash
# Automated release management script using commitizen and semantic versioning
# This script handles version bumping, changelog generation, and release preparation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Script information
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
DRY_RUN=false
INCREMENT=""
PRERELEASE=""
SKIP_HOOKS=false
AUTO_PUSH=false

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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [INCREMENT]

Automated release management using commitizen and semantic versioning.

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Show what would be done without making changes
    -p, --push          Automatically push changes and tags to remote
    -s, --skip-hooks    Skip pre-commit hooks during release
    --prerelease TYPE   Create a prerelease (alpha, beta, rc)

INCREMENT:
    auto                Automatically determine version increment (default)
    major               Force major version increment (X.0.0)
    minor               Force minor version increment (X.Y.0)
    patch               Force patch version increment (X.Y.Z)

EXAMPLES:
    $0                  # Automatic version increment based on commits
    $0 minor            # Force minor version increment
    $0 --dry-run        # Preview changes without applying them
    $0 --prerelease beta # Create beta prerelease
    $0 -p major         # Force major increment and push to remote

ENVIRONMENT VARIABLES:
    CZ_PRE_COMMIT_HOOKS=false  # Skip pre-commit hooks
    CZ_DRY_RUN=true           # Enable dry-run mode
    GIT_AUTHOR_NAME           # Override git author for release commit
    GIT_AUTHOR_EMAIL          # Override git email for release commit

EOF
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    # Check if commitizen is installed
    if ! command_exists cz; then
        log_error "Commitizen not found. Install with: pip install commitizen"
        log_info "Or run: ./scripts/setup-pre-commit.sh to install all dev tools"
        exit 1
    fi
    
    # Check if we have a clean working directory
    if [[ "$DRY_RUN" == false ]] && ! git diff --quiet; then
        log_error "Working directory is not clean. Please commit or stash changes."
        exit 1
    fi
    
    # Check if we have staged changes
    if [[ "$DRY_RUN" == false ]] && ! git diff --cached --quiet; then
        log_error "There are staged changes. Please commit or unstage them."
        exit 1
    fi
    
    # Check if we're on the main branch (optional warning)
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
        log_warning "You're not on the main branch (current: $current_branch)"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted"
            exit 0
        fi
    fi
    
    log_success "Prerequisites check passed"
}

# Get current version
get_current_version() {
    if command_exists cz; then
        cz version --project 2>/dev/null || echo "0.0.0"
    else
        echo "0.0.0"
    fi
}

# Show current status
show_status() {
    log_step "Current status..."
    
    local current_version
    current_version=$(get_current_version)
    
    echo "  Current version: $current_version"
    echo "  Current branch: $(git branch --show-current)"
    echo "  Last commit: $(git log -1 --oneline)"
    echo "  Commits since last tag: $(git rev-list --count HEAD ^$(git describe --tags --abbrev=0 2>/dev/null || echo 'HEAD'))"
    
    # Show unreleased commits
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [[ -n "$last_tag" ]]; then
        echo ""
        log_info "Commits since last release ($last_tag):"
        git log --oneline --no-merges "$last_tag"..HEAD | head -10
    else
        echo ""
        log_info "No previous releases found"
    fi
}

# Validate commitizen configuration
validate_cz_config() {
    log_step "Validating commitizen configuration..."
    
    if ! cz info >/dev/null 2>&1; then
        log_error "Commitizen configuration is invalid"
        log_info "Check your pyproject.toml [tool.commitizen] section"
        exit 1
    fi
    
    log_success "Commitizen configuration is valid"
}

# Run pre-release checks
run_pre_release_checks() {
    log_step "Running pre-release checks..."
    
    # Check if pre-commit is available and run it
    if [[ "$SKIP_HOOKS" == false ]] && command_exists pre-commit; then
        log_info "Running pre-commit hooks..."
        if ! pre-commit run --all-files; then
            log_error "Pre-commit hooks failed. Fix issues and try again."
            exit 1
        fi
        log_success "Pre-commit hooks passed"
    else
        log_warning "Skipping pre-commit hooks"
    fi
    
    # Run tests if available
    if [[ -f "pyproject.toml" ]] && command_exists pytest; then
        log_info "Running tests..."
        if ! pytest -q; then
            log_error "Tests failed. Fix issues and try again."
            exit 1
        fi
        log_success "Tests passed"
    else
        log_warning "No tests found or pytest not available"
    fi
    
    # Validate Docker Compose if available
    if [[ -f "docker-compose.yml" ]] && command_exists docker-compose; then
        log_info "Validating Docker Compose configuration..."
        if ! docker-compose config -q; then
            log_error "Docker Compose configuration is invalid"
            exit 1
        fi
        log_success "Docker Compose configuration is valid"
    fi
}

# Generate changelog preview
show_changelog_preview() {
    log_step "Generating changelog preview..."
    
    local temp_changelog
    temp_changelog=$(mktemp)
    
    if cz changelog --dry-run --incremental > "$temp_changelog" 2>/dev/null; then
        if [[ -s "$temp_changelog" ]]; then
            echo ""
            log_info "Changelog preview:"
            echo "----------------------------------------"
            cat "$temp_changelog"
            echo "----------------------------------------"
        else
            log_warning "No changelog changes detected"
        fi
    else
        log_warning "Could not generate changelog preview"
    fi
    
    rm -f "$temp_changelog"
}

# Perform version bump
perform_version_bump() {
    log_step "Performing version bump..."
    
    local cz_args=()
    
    # Add increment if specified
    if [[ -n "$INCREMENT" && "$INCREMENT" != "auto" ]]; then
        cz_args+=("--increment" "$INCREMENT")
    fi
    
    # Add prerelease if specified
    if [[ -n "$PRERELEASE" ]]; then
        cz_args+=("--prerelease" "$PRERELEASE")
    fi
    
    # Add dry-run if specified
    if [[ "$DRY_RUN" == true ]]; then
        cz_args+=("--dry-run")
    fi
    
    # Set environment variables for hooks
    if [[ "$SKIP_HOOKS" == true ]]; then
        export CZ_PRE_COMMIT_HOOKS=false
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        export CZ_DRY_RUN=true
    fi
    
    log_info "Running: cz bump ${cz_args[*]}"
    
    if cz bump "${cz_args[@]}"; then
        log_success "Version bump completed"
        
        # Show new version
        if [[ "$DRY_RUN" == false ]]; then
            local new_version
            new_version=$(get_current_version)
            log_success "New version: $new_version"
        fi
    else
        log_error "Version bump failed"
        exit 1
    fi
}

# Push changes to remote
push_to_remote() {
    if [[ "$AUTO_PUSH" == true && "$DRY_RUN" == false ]]; then
        log_step "Pushing changes to remote..."
        
        # Push commits and tags
        if git push && git push --tags; then
            log_success "Changes pushed to remote"
        else
            log_error "Failed to push changes to remote"
            exit 1
        fi
    fi
}

# Show post-release information
show_post_release_info() {
    if [[ "$DRY_RUN" == false ]]; then
        log_success "Release completed successfully!"
        echo ""
        log_info "Next steps:"
        echo "  1. Review the generated CHANGELOG.md"
        echo "  2. Push changes to remote: git push && git push --tags"
        echo "  3. Create a GitHub/GitLab release from the new tag"
        echo "  4. Update documentation if needed"
        echo ""
        
        local new_version
        new_version=$(get_current_version)
        log_info "New version: $new_version"
        log_info "Tag created: v$new_version"
    else
        log_info "Dry-run completed. No changes were made."
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -p|--push)
                AUTO_PUSH=true
                shift
                ;;
            -s|--skip-hooks)
                SKIP_HOOKS=true
                shift
                ;;
            --prerelease)
                PRERELEASE="$2"
                shift 2
                ;;
            major|minor|patch|auto)
                INCREMENT="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set default increment
    if [[ -z "$INCREMENT" ]]; then
        INCREMENT="auto"
    fi
    
    # Validate prerelease type
    if [[ -n "$PRERELEASE" ]]; then
        case "$PRERELEASE" in
            alpha|beta|rc)
                ;;
            *)
                log_error "Invalid prerelease type: $PRERELEASE (must be alpha, beta, or rc)"
                exit 1
                ;;
        esac
    fi
}

# Main execution
main() {
    log_info "Starting automated release process..."
    echo ""
    
    cd "$PROJECT_ROOT"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Show configuration
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY-RUN MODE - No changes will be made"
    fi
    
    echo "Configuration:"
    echo "  Increment: $INCREMENT"
    echo "  Prerelease: ${PRERELEASE:-none}"
    echo "  Auto-push: $AUTO_PUSH"
    echo "  Skip hooks: $SKIP_HOOKS"
    echo ""
    
    # Run all steps
    check_prerequisites
    validate_cz_config
    show_status
    
    if [[ "$DRY_RUN" == false ]]; then
        run_pre_release_checks
    fi
    
    show_changelog_preview
    
    # Confirm before proceeding (unless dry-run)
    if [[ "$DRY_RUN" == false ]]; then
        echo ""
        read -p "Proceed with release? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Release cancelled"
            exit 0
        fi
    fi
    
    perform_version_bump
    push_to_remote
    show_post_release_info
}

# Run main function with all arguments
main "$@"
