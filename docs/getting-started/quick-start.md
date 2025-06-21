# Quick Start Guide

Get your BIND DNS server with TSIG running in under 5 minutes! This guide provides the fastest path to a working DNS server.

## 🚀 One-Minute Setup

=== "Linux/macOS"
    ```bash
    # Clone and start
    git clone https://github.com/your-org/private-dns-zone.git
    cd private-dns-zone
    docker-compose up -d
    
    # Test
    dig @localhost www.example.local
    ```

=== "Windows (PowerShell)"
    ```powershell
    # Clone and start
    git clone https://github.com/your-org/private-dns-zone.git
    cd private-dns-zone
    docker-compose up -d
    
    # Test
    nslookup www.example.local localhost
    ```

!!! success "That's it!"
    Your DNS server is now running with TSIG authentication enabled!

## 📋 Step-by-Step Walkthrough

### Step 1: Prerequisites Check

Verify you have the required tools:

```bash
# Check Docker
docker --version
# Should output: Docker version 20.10+ or higher

# Check Docker Compose
docker-compose --version
# Should output: Docker Compose version 2.0+ or higher

# Check dig utility (optional but recommended)
dig -v
```

### Step 2: Get the Code

```bash
# Option 1: Clone from Git
git clone https://github.com/your-org/private-dns-zone.git
cd private-dns-zone

# Option 2: Download ZIP (if you don't have Git)
# Download and extract the ZIP file, then navigate to the directory
```

### Step 3: Start the DNS Server

```bash
# Start in detached mode
docker-compose up -d

# Check status
docker-compose ps
```

Expected output:
```
      Name                    Command               State                    Ports                  
--------------------------------------------------------------------------------------------------
bind-dns-server   named -g -c /etc/bind/name ...   Up      0.0.0.0:53->53/tcp, 0.0.0.0:53->53/udp,
                                                           0.0.0.0:953->953/tcp
```

### Step 4: Verify DNS Resolution

Test the pre-configured zones:

```bash
# Test example.local zone
dig @localhost www.example.local

# Test development zone
dig @localhost api.dev.local

# Test reverse lookup
dig @localhost -x 192.168.1.20
```

### Step 5: Test TSIG Authentication

Verify TSIG keys are working:

```bash
# Test with TSIG key
dig @localhost -k tsig-key:dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24= www.example.local
```

## 🧪 Quick Tests

Run these tests to ensure everything is working correctly:

### Basic DNS Resolution
```bash
# Should return an IP address
dig @localhost www.example.local +short
# Expected: 192.168.1.20

# Should return a CNAME
dig @localhost web.example.local +short
# Expected: www.example.local.
```

### Dynamic Updates
```bash
# Use the provided script
./scripts/update-dns.sh test
```

### Server Health
```bash
# Check container health
docker-compose exec bind rndc status

# View logs
docker-compose logs bind
```

## 🎯 What's Running?

After successful startup, you have:

| Service | Port | Purpose |
|---------|------|---------|
| DNS Server | 53/UDP, 53/TCP | DNS resolution |
| RNDC Control | 953/TCP | Remote administration |

### Pre-configured Zones

| Zone | Type | Purpose |
|------|------|---------|
| `example.local` | Forward | Sample production zone |
| `dev.local` | Forward | Development services |
| `test.local` | Forward | Dynamic updates testing |
| `1.168.192.in-addr.arpa` | Reverse | Reverse lookups |

### TSIG Keys Available

| Key Name | Purpose |
|----------|---------|
| `tsig-key` | Zone operations and transfers |
| `admin-key` | Administrative operations |
| `rndc-key` | Remote control operations |

## 🔧 Common Commands

Keep these handy for daily operations:

```bash
# Start the server
docker-compose up -d

# Stop the server
docker-compose down

# Restart the server
docker-compose restart bind

# View logs
docker-compose logs -f bind

# Check configuration
docker-compose exec bind named-checkconf

# Reload configuration
docker-compose exec bind rndc reload

# Flush DNS cache
docker-compose exec bind rndc flush
```

## 🚨 Troubleshooting Quick Fixes

### Container Won't Start
```bash
# Check for port conflicts
sudo netstat -tulpn | grep :53

# View detailed logs
docker-compose logs bind

# Check configuration syntax
docker-compose exec bind named-checkconf /etc/bind/named.conf
```

### DNS Not Resolving
```bash
# Test with different tools
nslookup www.example.local localhost
host www.example.local localhost

# Check if server is listening
sudo netstat -tulpn | grep :53
```

### Permission Issues
```bash
# Fix file permissions
sudo chown -R 53:53 zones/
sudo chmod 755 zones/
sudo chmod 644 zones/*
```

## ⭐ What's Next?

Now that you have a working DNS server:

1. **Customize Your Zones** - Edit files in the `zones/` directory to add your own domains
2. **Secure Your Setup** - Change default TSIG keys for production use
3. **Set Up Monitoring** - Configure log monitoring and alerting
4. **[Learn TSIG](../design/tsig-security.md)** - Deep dive into TSIG security

!!! tip "Pro Tip"
    Bookmark this page! You'll reference these commands frequently during development.

## 💡 Quick Tips

- **Development**: Use the `dev.local` zone for your local services
- **Testing**: Use the `test.local` zone for dynamic update experiments  
- **Monitoring**: Check logs regularly with `docker-compose logs -f bind`
- **Security**: Change default TSIG keys for production use
- **Backup**: Regular backups of the `zones/` directory are recommended
