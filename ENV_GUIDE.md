# Environment Variables Guide

This guide explains how to use environment variables to configure your BIND DNS server with Docker Compose.

## 📁 Files Overview

| File | Purpose | Tracked in Git |
|------|---------|---------------|
| `.env` | Current environment configuration | ❌ No (private) |
| `.env.example` | Template with example values | ✅ Yes |
| `docker-compose.yml` | Base Docker Compose configuration | ✅ Yes |
| `docker-compose.dev.yml` | Development overrides | ✅ Yes |
| `docker-compose.prod.yml` | Production overrides | ✅ Yes |

## 🚀 Quick Start

### 1. Create Environment File

```bash
# Copy the example file
cp .env.example .env

# Or use the environment manager script
./scripts/env-manager.sh create-env development
```

### 2. Generate TSIG Keys (Recommended)

```bash
# Generate secure TSIG keys
./scripts/env-manager.sh generate-keys

# Copy the generated keys to your .env file
```

### 3. Start the Server

```bash
# Development environment
docker-compose up -d

# Production environment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Development with tools
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile tools up -d
```

## ⚙️ Configuration Categories

### Container Configuration

```bash
# Docker image settings
BIND_IMAGE=internetsystemsconsortium/bind9
BIND_TAG=9.19
BIND_CONTAINER_NAME=bind-dns-server
BIND_USER=bind
```

### Network Configuration

```bash
# Port mappings
DNS_PORT_UDP=53        # DNS UDP port
DNS_PORT_TCP=53        # DNS TCP port  
RNDC_PORT=953         # RNDC control port

# Docker networking
DOCKER_NETWORK_NAME=dns-network
DOCKER_SUBNET=172.20.0.0/16
```

### Security Configuration

```bash
# TSIG Keys (base64 encoded)
TSIG_KEY_NAME=tsig-key
TSIG_KEY_SECRET=your_secure_key_here

ADMIN_KEY_NAME=admin-key
ADMIN_KEY_SECRET=your_admin_key_here

RNDC_KEY_NAME=rndc-key
RNDC_KEY_SECRET=your_rndc_key_here
```

### Performance Configuration

```bash
# Resource limits
BIND_MEMORY_LIMIT=512m
BIND_MEMORY_RESERVATION=256m
BIND_CPU_LIMIT=0.5
BIND_CPU_RESERVATION=0.1
```

### Logging Configuration

```bash
# Log level and features
LOG_LEVEL=info                    # critical, error, warning, notice, info, debug
ENABLE_QUERY_LOGGING=false
ENABLE_SECURITY_LOGGING=true
ENABLE_ZONE_TRANSFER_LOGGING=true
```

## 🔐 Security Best Practices

### 1. Generate Unique TSIG Keys

```bash
# Never use default keys in production!
# Generate secure keys:
openssl rand -base64 32

# Or use the provided script:
./scripts/env-manager.sh generate-keys
```

### 2. File Permissions

```bash
# Secure your environment file
chmod 600 .env

# Backup keys securely
./scripts/env-manager.sh backup-env
```

### 3. Environment-Specific Keys

Use different TSIG keys for each environment:

- **Development**: Use sample keys or basic generated keys
- **Staging**: Use production-like keys for testing
- **Production**: Use strong, unique keys with regular rotation

### 4. Key Rotation

```bash
# Regular key rotation (recommended quarterly)
./scripts/env-manager.sh generate-keys
# Update .env file with new keys
# Restart containers: docker-compose restart bind
```

## 🌍 Environment-Specific Configurations

### Development Environment

```bash
# .env for development
ENVIRONMENT=development
LOG_LEVEL=debug
DEBUG_MODE=true
VERBOSE_LOGGING=true
BIND_MEMORY_LIMIT=256m

# Start with development overrides
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Staging Environment

```bash
# .env for staging
ENVIRONMENT=staging
LOG_LEVEL=info
DEBUG_MODE=false
VERBOSE_LOGGING=false
BIND_MEMORY_LIMIT=512m

# Use base configuration
docker-compose up -d
```

### Production Environment

```bash
# .env for production
ENVIRONMENT=production
LOG_LEVEL=warning
DEBUG_MODE=false
VERBOSE_LOGGING=false
BIND_MEMORY_LIMIT=1g
MONITORING_ENABLED=true

# Start with production overrides
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 🛠️ Environment Manager Script

The `scripts/env-manager.sh` script helps manage your environment configuration:

### Commands

```bash
# Generate new TSIG keys
./scripts/env-manager.sh generate-keys

# Validate environment file
./scripts/env-manager.sh validate

# Create environment file for specific type
./scripts/env-manager.sh create-env production

# Show environment information
./scripts/env-manager.sh show-info

# Backup current environment
./scripts/env-manager.sh backup-env
```

### Validation Features

The script checks for:
- ✅ Required variables present
- ✅ No default/insecure values
- ✅ Proper file permissions
- ✅ Environment-specific settings

## 📊 Variable Reference

### Required Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `BIND_IMAGE` | String | Docker image name | `internetsystemsconsortium/bind9` |
| `BIND_TAG` | String | Docker image tag | `9.19` |
| `BIND_CONTAINER_NAME` | String | Container name | `bind-dns-server` |
| `DNS_PORT_UDP` | Number | DNS UDP port | `53` |
| `DNS_PORT_TCP` | Number | DNS TCP port | `53` |
| `RNDC_PORT` | Number | RNDC control port | `953` |
| `TSIG_KEY_SECRET` | String | Base64 TSIG key | `base64-encoded-key` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENVIRONMENT` | `development` | Environment type |
| `LOG_LEVEL` | `info` | Logging level |
| `DEBUG_MODE` | `false` | Enable debug mode |
| `MONITORING_ENABLED` | `false` | Enable monitoring |
| `BACKUP_ENABLED` | `true` | Enable backups |

## 🧪 Testing Your Configuration

### 1. Validate Environment

```bash
# Check environment file
./scripts/env-manager.sh validate

# Test Docker Compose configuration
docker-compose config
```

### 2. Test DNS Server

```bash
# Start server
docker-compose up -d

# Test DNS resolution
dig @localhost www.example.local

# Test TSIG authentication
dig @localhost -k ${TSIG_KEY_NAME}:${TSIG_KEY_SECRET} www.example.local
```

### 3. Health Checks

```bash
# Check container health
docker-compose ps

# View logs
docker-compose logs bind

# RNDC status
docker-compose exec bind rndc status
```

## 🔄 Environment Migration

### Development to Production

1. **Backup current environment**
   ```bash
   ./scripts/env-manager.sh backup-env
   ```

2. **Generate new production keys**
   ```bash
   ./scripts/env-manager.sh generate-keys
   ```

3. **Create production environment**
   ```bash
   ./scripts/env-manager.sh create-env production
   ```

4. **Update TSIG keys in .env file**

5. **Validate configuration**
   ```bash
   ./scripts/env-manager.sh validate
   docker-compose config
   ```

6. **Deploy with production overrides**
   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

## 🚨 Troubleshooting

### Common Issues

#### 1. Environment file not found
```bash
# Error: .env file not found
# Solution: Create from template
cp .env.example .env
```

#### 2. Invalid TSIG keys
```bash
# Error: TSIG signature verification failed
# Solution: Check key format and encoding
echo "your-key" | base64 -d  # Should not error
```

#### 3. Port conflicts
```bash
# Error: Port 53 already in use
# Solution: Change ports in .env
DNS_PORT_UDP=5353
DNS_PORT_TCP=5353
```

#### 4. Permission denied
```bash
# Error: Cannot read .env file
# Solution: Check file permissions
chmod 600 .env
```

### Debug Commands

```bash
# Show loaded environment variables
docker-compose config

# Test environment parsing
docker-compose run --rm bind env | grep BIND

# Validate BIND configuration
docker-compose exec bind named-checkconf
```

## 📝 Best Practices Summary

1. **🔑 Security**
   - Never commit `.env` files to version control
   - Generate unique TSIG keys for each environment
   - Use strong, random keys (32+ characters base64)
   - Rotate keys regularly (quarterly recommended)

2. **📁 Organization**
   - Use environment-specific override files
   - Keep sensitive data in `.env` files only
   - Document all custom variables

3. **🧪 Testing**
   - Validate environment files before deployment
   - Test configuration changes in development first
   - Use the environment manager script for consistency

4. **🔄 Deployment**
   - Use different configurations for different environments
   - Backup environment files before changes
   - Monitor logs after configuration changes

This environment system provides flexibility while maintaining security and consistency across different deployment scenarios.
