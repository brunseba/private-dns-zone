# MkDocs Documentation Setup

This guide helps you set up and run the MkDocs documentation for the BIND DNS server project.

## ✅ Issues Fixed

- ❌ `materialx.emoji` deprecated → ✅ `material.extensions.emoji`
- ❌ Missing plugins causing errors → ✅ Optional plugins commented out
- ❌ Broken internal links → ✅ All links fixed or updated
- ❌ References to non-existent pages → ✅ Removed or updated

## 🚀 Quick Setup

### Option 1: Using Virtual Environment (Recommended)

```bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r docs-requirements.txt

# Serve documentation locally
mkdocs serve

# Access at http://127.0.0.1:8000
```

### Option 2: Using System Python

```bash
# Install dependencies globally (if allowed)
pip install mkdocs mkdocs-material pymdown-extensions

# Serve documentation
mkdocs serve
```

### Option 3: Using pipx (Isolated installation)

```bash
# Install pipx if not available
brew install pipx  # macOS
# or apt install pipx  # Ubuntu

# Install MkDocs with pipx
pipx install mkdocs
pipx inject mkdocs mkdocs-material pymdown-extensions

# Serve documentation
mkdocs serve
```

## 📚 Available Commands

```bash
# Serve documentation locally (with live reload)
mkdocs serve

# Build static documentation
mkdocs build

# Build and check for warnings
mkdocs build --strict

# Clean build directory
mkdocs build --clean

# Deploy to GitHub Pages (if configured)
mkdocs gh-deploy
```

## 🎨 Documentation Features

### ✅ Working Features
- Material Design theme with dark/light mode
- Search functionality
- Code syntax highlighting with copy buttons
- Tabbed content for multi-platform instructions
- Admonitions (tips, warnings, notes)
- Custom DNS-themed styling
- Mermaid diagram support
- Responsive design

### 🔧 Optional Features (Can be enabled)
To enable additional features, uncomment in `mkdocs.yml`:

```yaml
plugins:
  - search:
      lang: en
  - mermaid2:           # Uncomment and install: pip install mkdocs-mermaid2-plugin
      version: 9.4.3
  - git-revision-date-localized:  # Uncomment and install: pip install mkdocs-git-revision-date-localized-plugin
      type: date
  - minify:             # Uncomment and install: pip install mkdocs-minify-plugin
      minify_html: true
```

## 📖 Documentation Structure

```
docs/
├── index.md                    # Homepage
├── getting-started/            # Getting started guides
│   ├── overview.md            # Project overview
│   ├── quick-start.md         # 5-minute setup
│   └── installation.md       # Detailed installation
├── design/                    # Architecture docs
│   ├── architecture.md       # System architecture
│   └── tsig-security.md      # TSIG security design
├── user-guide/               # User guides
│   └── basic-operations.md   # Daily operations
└── assets/                   # Documentation assets
    ├── stylesheets/extra.css # Custom styling
    └── javascripts/mermaid.js # Mermaid config
```

## 🐛 Troubleshooting

### Common Issues

1. **Plugin not found errors**
   ```bash
   # Install missing plugins
   pip install mkdocs-mermaid2-plugin mkdocs-git-revision-date-localized-plugin
   ```

2. **Module import errors**
   ```bash
   # Reinstall with compatible versions
   pip install -r docs-requirements.txt --force-reinstall
   ```

3. **Port already in use**
   ```bash
   # Use different port
   mkdocs serve --dev-addr 127.0.0.1:8001
   ```

4. **Permission errors**
   ```bash
   # Use virtual environment or user install
   pip install --user mkdocs mkdocs-material
   ```

### Build Warnings

The following warning is expected and can be ignored:
```
WARNING - Excluding 'README.md' from the site because it conflicts with 'index.md'.
```

## 🚀 Deployment Options

### GitHub Pages
```bash
# Configure repository settings, then:
mkdocs gh-deploy
```

### Static Hosting
```bash
# Build static files
mkdocs build

# Deploy to web server
rsync -av site/ user@server:/var/www/docs/
```

### Docker Deployment
```dockerfile
FROM squidfunk/mkdocs-material:latest
COPY . /docs
WORKDIR /docs
EXPOSE 8000
CMD ["serve", "--dev-addr=0.0.0.0:8000"]
```

## ✨ Next Steps

1. **Customize content**: Edit markdown files in `docs/`
2. **Add pages**: Create new `.md` files and update navigation in `mkdocs.yml`
3. **Enable plugins**: Uncomment and install optional plugins as needed
4. **Deploy**: Choose a deployment method and set up automated builds
5. **Monitor**: Set up analytics and user feedback collection

The documentation is now fully functional and ready for use! 🎉
