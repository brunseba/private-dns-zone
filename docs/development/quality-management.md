# Quality Management with Pre-commit

This project uses [pre-commit](https://pre-commit.com/) to maintain code quality and consistency across all files in the repository. Pre-commit hooks automatically run quality checks before each commit, ensuring that only high-quality code enters the repository.

## Overview

The quality management system includes:

- **Automated code formatting** for Python, JavaScript, and Markdown
- **Syntax validation** for YAML, JSON, TOML, and XML files
- **Security checks** to prevent accidental commits of secrets
- **DNS-specific validation** for BIND configurations and TSIG keys
- **Documentation quality** checks including link validation
- **Conventional commit** message formatting

## Quick Setup

### Automated Setup (Recommended)

Run the automated setup script to install and configure all quality tools:

```bash
./scripts/setup-pre-commit.sh
```

This script will:
1. Install pre-commit and related quality tools
2. Set up all hooks and configurations
3. Run initial quality checks on all files
4. Provide guidance for ongoing usage

### Manual Setup

If you prefer manual installation:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install
pre-commit install --hook-type commit-msg

# Run on all files initially
pre-commit run --all-files
```

## Quality Checks

### File Format and Syntax

| Check | Description | Files |
|-------|-------------|-------|
| **YAML Syntax** | Validates YAML files for syntax errors | `*.yaml`, `*.yml` |
| **JSON Syntax** | Validates JSON files for syntax errors | `*.json` |
| **TOML Syntax** | Validates TOML files for syntax errors | `*.toml` |
| **XML Syntax** | Validates XML files for syntax errors | `*.xml` |

### File Consistency

| Check | Description | Action |
|-------|-------------|--------|
| **End of File Fixer** | Ensures files end with newline | Auto-fix |
| **Trailing Whitespace** | Removes trailing whitespace | Auto-fix |
| **Mixed Line Endings** | Ensures consistent LF line endings | Auto-fix |
| **Large Files** | Prevents files larger than 1MB | Block commit |
| **Case Conflicts** | Prevents case-insensitive filename conflicts | Block commit |
| **Merge Conflicts** | Detects unresolved merge conflict markers | Block commit |

### Security Checks

| Check | Description | Action |
|-------|-------------|--------|
| **Private Keys** | Detects private key patterns | Block commit |
| **AWS Credentials** | Detects AWS access keys | Block commit |
| **Generic Secrets** | Detects common secret patterns | Block commit |

### Code Quality

#### Python Code
- **Black**: Automatic code formatting
- **isort**: Import statement sorting
- **flake8**: Style and error linting

#### JavaScript Code (DNSControl)
- **ESLint**: Linting with DNS-specific rules
- **Prettier**: Code formatting

#### Shell Scripts
- **shellcheck**: Shell script linting and best practices

#### Docker
- **hadolint**: Dockerfile linting and best practices

### DNS-Specific Checks

| Check | Description | Purpose |
|-------|-------------|---------|
| **BIND Config Validation** | Validates `named.conf` syntax | Prevent DNS server startup failures |
| **TSIG Key Format** | Validates TSIG key base64 encoding | Ensure proper key format |
| **Docker Compose Validation** | Validates Docker Compose syntax | Prevent deployment failures |
| **Environment Security** | Checks `.env` files are in `.gitignore` | Prevent secret exposure |

### Documentation Quality

| Check | Description | Purpose |
|-------|-------------|---------|
| **Markdown Linting** | Validates Markdown style and syntax | Consistent documentation |
| **Link Validation** | Checks internal documentation links | Prevent broken documentation |
| **YAML Frontmatter** | Validates YAML in Markdown files | MkDocs compatibility |

## Usage

### Automatic Execution

Pre-commit hooks run automatically before each commit:

```bash
git add .
git commit -m "feat: add new feature"
# Pre-commit hooks run automatically
```

### Manual Execution

Run quality checks manually on all files:

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run black
pre-commit run shellcheck
pre-commit run check-yaml
```

### Run on Specific Files

```bash
# Run hooks on specific files
pre-commit run --files file1.py file2.js

# Run specific hook on specific files
pre-commit run black --files *.py
```

### Skip Hooks (Emergency Use)

```bash
# Skip all pre-commit hooks (not recommended)
git commit --no-verify -m "emergency fix"

# Skip specific hook
SKIP=black git commit -m "skip black formatting"
```

## Configuration Files

### `.pre-commit-config.yaml`

Main configuration file defining all hooks and their settings. Key sections:

- **General hooks**: File formatting, security, syntax validation
- **Language-specific hooks**: Python, JavaScript, Shell, Docker
- **DNS-specific hooks**: BIND validation, TSIG checks
- **Documentation hooks**: Markdown linting, link validation

### Tool-Specific Configurations

#### `.eslintrc.js` (JavaScript/DNSControl)
```javascript
module.exports = {
  env: { node: true, es2021: true },
  extends: ['standard'],
  rules: {
    'no-undef': 'off',     // DNSControl global functions
    'camelcase': 'off',    // DNS records use underscores
  },
  globals: {
    // DNSControl global functions
    'NewDnsProvider': 'readonly',
    'D': 'readonly',
    'A': 'readonly',
    // ... etc
  },
}
```

#### `.flake8` (Python)
```ini
[flake8]
max-line-length = 88
extend-ignore = E203, W503, E501
exclude = .git, __pycache__, .venv, venv
```

#### `.prettierrc` (Code Formatting)
```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false
}
```

## Updating Hooks

Keep hooks updated to the latest versions:

```bash
# Update all hooks to latest versions
pre-commit autoupdate

# Update specific hook
pre-commit autoupdate --repo https://github.com/psf/black
```

## DNS-Specific Quality Rules

### BIND Configuration

The `named-checkconf` hook validates BIND configuration files:

```bash
# Validates config/named.conf
named-checkconf config/named.conf
```

### TSIG Key Validation

Ensures TSIG keys are properly base64 encoded:

```bash
# Valid TSIG key format
EXTERNAL_DNS_TSIG_KEY_SECRET=dGVzdC1rZXktc2VjcmV0

# Invalid format (triggers warning)
EXTERNAL_DNS_TSIG_KEY_SECRET=plain-text-secret
```

### Docker Compose Validation

Validates Docker Compose file syntax:

```bash
# Validates docker-compose.yml
docker-compose config -q
```

### Environment File Security

Ensures sensitive environment files are gitignored:

```bash
# These files should be in .gitignore
.env
.env.local
.env.production
```

## CI/CD Integration

Pre-commit integrates seamlessly with CI/CD pipelines:

### GitHub Actions

```yaml
name: Quality Checks
on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      - name: Install pre-commit
        run: pip install pre-commit
      - name: Run pre-commit
        run: pre-commit run --all-files
```

### Pre-commit.ci

Enable automatic updates and checks with [pre-commit.ci](https://pre-commit.ci/):

1. Enable pre-commit.ci in your repository
2. Automatic hook updates via weekly PRs
3. Automatic fixes on pull requests

## Troubleshooting

### Common Issues

#### Hook Installation Fails
```bash
# Clear cache and reinstall
pre-commit clean
pre-commit install --install-hooks
```

#### Specific Tool Not Found
```bash
# Install missing tools
pip install black flake8 yamllint
npm install -g markdownlint-cli
brew install shellcheck hadolint
```

#### False Positives
```bash
# Skip specific check for one commit
SKIP=flake8 git commit -m "temporary skip"

# Exclude files from specific hooks in .pre-commit-config.yaml
- id: black
  exclude: ^(path/to/exclude/|another/path/)
```

#### Performance Issues
```bash
# Run hooks in parallel (default)
pre-commit run --all-files

# Run specific slow hook separately
pre-commit run --hook-stage manual hadolint-docker
```

### DNS-Specific Troubleshooting

#### BIND Configuration Validation Fails
```bash
# Check BIND configuration manually
named-checkconf config/named.conf

# Common issues:
# - Missing semicolons
# - Incorrect file paths
# - Invalid IP addresses
```

#### TSIG Key Format Issues
```bash
# Generate proper base64 TSIG key
openssl rand -base64 32

# Verify key format
echo "dGVzdC1rZXk=" | base64 -d
```

#### Docker Compose Validation Fails
```bash
# Check Docker Compose file manually
docker-compose config

# Common issues:
# - Invalid YAML syntax
# - Missing environment variables
# - Invalid service references
```

## Best Practices

### Development Workflow

1. **Make small, focused commits** to reduce hook execution time
2. **Run hooks locally** before pushing to catch issues early
3. **Keep hooks updated** with regular `pre-commit autoupdate`
4. **Review auto-fixes** before committing to understand changes

### Team Coordination

1. **Standardize tool versions** across team members
2. **Document exceptions** when hooks must be skipped
3. **Regular hook maintenance** to keep configurations current
4. **Share configurations** via `.pre-commit-config.yaml` in version control

### Performance Optimization

1. **Use file filters** to run hooks only on relevant files
2. **Parallelize execution** where possible (default behavior)
3. **Cache hook environments** for faster subsequent runs
4. **Skip expensive hooks** in rapid development cycles when appropriate

This quality management system ensures consistent, secure, and maintainable code across the entire DNS repository, from configuration files to documentation.
