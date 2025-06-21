# Release Management

This project uses [Semantic Versioning](https://semver.org/) with [Commitizen](https://commitizen-tools.github.io/commitizen/) to automate version management and changelog generation. This ensures consistent, predictable releases with clear communication about changes.

## Overview

The release management system provides:

- **Semantic Versioning (SemVer)** for predictable version increments
- **Conventional Commits** for structured commit messages
- **Automated Changelog** generation based on commit history
- **Version Bumping** with automatic tag creation
- **Release Validation** with pre-commit hooks and testing
- **CI/CD Integration** for automated releases

## Semantic Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

### Version Components

| Component | When to Increment | Example |
|-----------|-------------------|---------|
| **MAJOR** | Breaking changes that require user action | `1.0.0` → `2.0.0` |
| **MINOR** | New features that are backwards-compatible | `1.0.0` → `1.1.0` |
| **PATCH** | Backwards-compatible bug fixes | `1.0.0` → `1.0.1` |

### Pre-release Versions

Pre-release versions append identifiers:

- **Alpha**: `1.0.0-alpha.1` - Early development
- **Beta**: `1.0.0-beta.1` - Feature complete, testing phase
- **Release Candidate**: `1.0.0-rc.1` - Potentially final version

## Conventional Commits

All commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types

| Type | Version Impact | Description | Example |
|------|----------------|-------------|---------|
| `feat` | MINOR | New features | `feat(dns): add TSIG key rotation` |
| `fix` | PATCH | Bug fixes | `fix(docker): resolve container startup issue` |
| `docs` | PATCH | Documentation | `docs: update installation guide` |
| `style` | PATCH | Code formatting | `style: apply black formatting` |
| `refactor` | PATCH | Code restructuring | `refactor(env): simplify key generation` |
| `perf` | MINOR | Performance improvements | `perf(dns): optimize query response time` |
| `test` | PATCH | Testing changes | `test: add integration tests` |
| `build` | PATCH | Build system changes | `build: update Docker base image` |
| `ci` | PATCH | CI/CD changes | `ci: add automated testing workflow` |
| `chore` | PATCH | Maintenance tasks | `chore: update dependencies` |
| `revert` | Varies | Revert previous changes | `revert: rollback TSIG changes` |

### Breaking Changes

Breaking changes trigger a MAJOR version increment:

```bash
feat(api)!: remove deprecated DNS endpoints

BREAKING CHANGE: The legacy DNS API endpoints have been removed.
Use the new v2 endpoints instead.
```

### Scope Examples

Common scopes for this project:

- `dns` - DNS server functionality
- `tsig` - TSIG authentication
- `docker` - Docker/containerization
- `env` - Environment management
- `docs` - Documentation
- `ci` - CI/CD workflows
- `test` - Testing infrastructure

## Release Process

### Interactive Commit Creation

Use Commitizen for guided commit creation:

```bash
# Install commitizen (if not already installed)
pip install commitizen

# Create interactive commit
cz commit
```

This provides a guided interface for creating properly formatted commits.

### Automated Release Script

Use the automated release script for version management:

```bash
# Basic release (auto-increment based on commits)
./scripts/release.sh

# Force specific increment
./scripts/release.sh major
./scripts/release.sh minor
./scripts/release.sh patch

# Preview changes without applying
./scripts/release.sh --dry-run

# Create pre-release
./scripts/release.sh --prerelease beta

# Release and push automatically
./scripts/release.sh --push
```

### Manual Release Steps

For manual release management:

```bash
# 1. Ensure clean working directory
git status

# 2. Run quality checks
pre-commit run --all-files

# 3. Generate changelog and bump version
cz bump

# 4. Push changes and tags
git push && git push --tags
```

## Release Script Options

### Command Line Options

| Option | Description | Example |
|--------|-------------|---------|
| `--dry-run` | Preview changes without applying | `./scripts/release.sh --dry-run` |
| `--push` | Automatically push to remote | `./scripts/release.sh --push` |
| `--skip-hooks` | Skip pre-commit hooks | `./scripts/release.sh --skip-hooks` |
| `--prerelease TYPE` | Create pre-release version | `./scripts/release.sh --prerelease beta` |

### Increment Types

| Type | Description | When to Use |
|------|-------------|-------------|
| `auto` | Automatic based on commits | Default behavior |
| `major` | Force major increment | Breaking changes |
| `minor` | Force minor increment | New features |
| `patch` | Force patch increment | Bug fixes only |

### Usage Examples

```bash
# Preview next release
./scripts/release.sh --dry-run

# Create minor release with push
./scripts/release.sh minor --push

# Create beta pre-release
./scripts/release.sh --prerelease beta

# Emergency patch release (skip hooks)
./scripts/release.sh patch --skip-hooks --push
```

## Configuration

### Commitizen Configuration

Configuration is in `pyproject.toml`:

```toml
[tool.commitizen]
name = "cz_conventional_commits"
tag_format = "v$version"
version_scheme = "semver"
version_provider = "scm"
update_changelog_on_bump = true
major_version_zero = true
bump_message = "bump: version $current_version → $new_version"

# Version files to update
version_files = [
    "pyproject.toml:version",
    "scripts/_version.py",
    "docker-compose.yml:labels.*version",
    "docs/index.md:<!-- version: ",
]
```

### Changelog Configuration

```toml
[tool.commitizen.changelog]
file_name = "CHANGELOG.md"
unreleased_title = "Unreleased"
order = ["feat", "fix", "refactor", "perf"]
start_rev = "HEAD"
incremental = true
```

## Version File Updates

The release process automatically updates version references in:

| File | Pattern | Purpose |
|------|---------|---------|
| `pyproject.toml` | `version = "X.Y.Z"` | Python package version |
| `scripts/_version.py` | `__version__ = "X.Y.Z"` | Runtime version info |
| `docker-compose.yml` | `labels.*version` | Container labels |
| `docs/index.md` | `<!-- version: X.Y.Z -->` | Documentation version |

## Changelog Generation

The changelog is automatically generated from commit messages:

### Changelog Sections

1. **Added** - New features (`feat`)
2. **Fixed** - Bug fixes (`fix`)
3. **Changed** - Refactoring and improvements (`refactor`)
4. **Performance** - Performance improvements (`perf`)
5. **Security** - Security-related changes
6. **Deprecated** - Features marked for removal
7. **Removed** - Removed features

### Example Changelog Entry

```markdown
## [1.2.0] - 2024-01-15

### Added
- feat(dns): add automatic TSIG key rotation functionality
- feat(docker): support for multi-architecture builds

### Fixed
- fix(env): resolve environment variable validation issue
- fix(docs): correct installation command examples

### Changed
- refactor(tsig): simplify key generation process
- refactor(scripts): improve error handling in env-manager

### Performance
- perf(dns): optimize DNS query response time by 15%
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    if: "!contains(github.event.head_commit.message, 'bump:')"
    
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Install dependencies
        run: |
          pip install commitizen
          pip install -e .[dev]
      
      - name: Configure Git
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
      
      - name: Run tests
        run: pytest
      
      - name: Bump version and create changelog
        run: |
          cz bump --changelog --yes
      
      - name: Push changes
        run: |
          git push && git push --tags
      
      - name: Create GitHub Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ steps.cz.outputs.version }}
          release_name: Release ${{ steps.cz.outputs.version }}
          body_path: CHANGELOG.md
```

### GitLab CI Example

```yaml
release:
  stage: release
  image: python:3.9
  before_script:
    - pip install commitizen
    - git config --global user.email "gitlab-ci@example.com"
    - git config --global user.name "GitLab CI"
  script:
    - cz bump --changelog --yes
    - git push origin HEAD:main
    - git push origin --tags
  only:
    - main
  except:
    variables:
      - $CI_COMMIT_MESSAGE =~ /^bump:/
```

## Best Practices

### Commit Guidelines

1. **Write clear, descriptive commit messages**
   ```bash
   # Good
   feat(dns): add support for ECDSA TSIG keys
   
   # Bad
   update dns stuff
   ```

2. **Use appropriate scopes**
   ```bash
   feat(tsig): add key rotation
   fix(docker): resolve health check timeout
   docs(api): update TSIG authentication guide
   ```

3. **Include breaking change information**
   ```bash
   feat(api)!: redesign TSIG key management API
   
   BREAKING CHANGE: The TSIG key API has been redesigned.
   See migration guide for upgrade instructions.
   ```

### Release Guidelines

1. **Test before release**
   - Run full test suite
   - Validate Docker Compose configuration
   - Test documentation builds

2. **Use dry-run for preview**
   ```bash
   ./scripts/release.sh --dry-run
   ```

3. **Review changelog before publishing**
   - Ensure all changes are documented
   - Check for missing or incorrect entries
   - Validate version increment logic

4. **Coordinate team releases**
   - Communicate planned releases
   - Ensure all features are complete
   - Coordinate with deployment schedules

### Version Strategy

1. **Use semantic versioning consistently**
   - Breaking changes = MAJOR
   - New features = MINOR
   - Bug fixes = PATCH

2. **Consider pre-releases for testing**
   ```bash
   # Alpha for early development
   ./scripts/release.sh --prerelease alpha
   
   # Beta for testing
   ./scripts/release.sh --prerelease beta
   
   # Release candidate for final testing
   ./scripts/release.sh --prerelease rc
   ```

3. **Maintain backwards compatibility**
   - Deprecate before removing features
   - Provide migration guides for breaking changes
   - Support multiple versions when possible

## Troubleshooting

### Common Issues

#### Commitizen Not Found
```bash
# Install commitizen
pip install commitizen

# Or install all dev dependencies
pip install -e .[dev]
```

#### Invalid Commit Messages
```bash
# Check commit message format
cz check --rev-range HEAD~1..HEAD

# Fix last commit message
git commit --amend -m "feat(dns): add new feature"
```

#### Version Conflicts
```bash
# Reset to clean state
git checkout .
git clean -fd

# Manual version bump
cz bump --increment patch
```

#### Pre-commit Hook Failures
```bash
# Skip hooks for emergency release
./scripts/release.sh --skip-hooks

# Fix issues and re-run
pre-commit run --all-files
./scripts/release.sh
```

### Recovery Procedures

#### Rollback Release
```bash
# Rollback to previous tag
git tag -d v1.2.0  # Delete local tag
git push origin :refs/tags/v1.2.0  # Delete remote tag
git reset --hard HEAD~1  # Reset to previous commit
```

#### Fix Incorrect Version
```bash
# Manual version correction
git tag v1.2.1 HEAD
git push origin v1.2.1

# Update CHANGELOG.md manually
# Commit changes
git add CHANGELOG.md
git commit -m "docs: fix changelog for v1.2.1"
```

This release management system ensures consistent, automated, and traceable releases while maintaining high quality standards through integrated testing and validation.
