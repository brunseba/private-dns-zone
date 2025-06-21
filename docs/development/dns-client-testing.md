# DNS Client Testing Container

The DNS client testing container provides a complete environment for testing all DNS use cases in an isolated, reproducible manner. Based on Alpine Linux, it includes all necessary tools for testing BIND DNS integration with External-DNS, DNSControl, and octoDNS.

## Overview

The `dns-client` service is a Docker container specifically designed for testing DNS functionality without requiring local tool installation. It includes:

- **BIND DNS tools** (`dig`, `nslookup`, `nsupdate`) with TSIG support
- **DNSControl** for JavaScript-based declarative DNS management
- **octoDNS** for Python-based DNS-as-code operations
- **Testing scripts** for automated validation of all use cases
- **Example configurations** for quick start testing

## Quick Start

### 1. Start the Testing Environment

```bash
# Generate TSIG keys and start BIND DNS server
./env-manager.sh generate-keys
docker-compose up -d bind

# Start the DNS client testing container
docker-compose --profile testing up -d dns-client
```

### 2. Run All Tests

```bash
# Execute comprehensive test suite
docker-compose --profile testing exec dns-client run-all-tests
```

### 3. Interactive Testing

```bash
# Start interactive shell in the container
docker-compose --profile testing exec dns-client bash

# Or run specific tests
docker-compose --profile testing exec dns-client test-dns
docker-compose --profile testing exec dns-client test-dnscontrol
docker-compose --profile testing exec dns-client test-octodns
```

## Available Testing Commands

### `test-dns`
Tests basic DNS functionality and TSIG authentication:

```bash
docker-compose --profile testing exec dns-client test-dns
```

**What it tests:**
- Basic DNS resolution (SOA, NS records)
- TSIG authentication with configured keys
- Dynamic DNS updates using external-dns key
- Record creation, verification, and cleanup

### `test-dnscontrol`
Tests DNSControl configuration and validation:

```bash
docker-compose --profile testing exec dns-client test-dnscontrol
```

**What it tests:**
- Creates example `dnsconfig.js` if not present
- Validates DNSControl configuration syntax
- Previews changes that would be applied
- Demonstrates declarative DNS management workflow

### `test-octodns`
Tests octoDNS configuration and validation:

```bash
docker-compose --profile testing exec dns-client test-octodns
```

**What it tests:**
- Creates example `config.yaml` and zone files if not present
- Activates octoDNS Python virtual environment
- Validates octoDNS configuration
- Plans changes for DNS synchronization

### `run-all-tests`
Executes comprehensive test suite covering all use cases:

```bash
docker-compose --profile testing exec dns-client run-all-tests
```

**What it includes:**
- DNS server readiness check
- All individual test suites (DNS, DNSControl, octoDNS)
- Comprehensive validation of the entire ecosystem

## Container Features

### Alpine Linux Base
- **Minimal footprint**: ~200MB container size
- **Security focused**: Regular security updates
- **Performance**: Fast startup and low resource usage

### Pre-installed Tools
- **DNS Tools**: `dig`, `nslookup`, `nsupdate`, `host`
- **DNSControl**: Latest version compiled from source
- **octoDNS**: Installed in isolated Python virtual environment
- **Development Tools**: Go, Python3, Node.js, git, curl, jq, yq
- **Network Tools**: tcpdump, netcat, ping for debugging

### Environment Integration
- **TSIG Keys**: Automatically configured from environment variables
- **DNS Server**: Connects to BIND DNS container by default
- **Workspace**: Mounts project directory as `/workspace`
- **Examples**: Auto-generates example configurations

## Testing Workflows

### UC-001: External-DNS Integration Testing

```bash
# Test basic DNS resolution and TSIG
docker-compose --profile testing exec dns-client test-dns

# Test dynamic updates (simulates external-dns behavior)
docker-compose --profile testing exec dns-client bash -c '
echo "server bind 53
key hmac-sha256:$EXTERNAL_DNS_TSIG_KEY_NAME $EXTERNAL_DNS_TSIG_KEY_SECRET
update add k8s-test.example.local 300 A 10.0.0.100
send" | nsupdate
'

# Verify the record
docker-compose --profile testing exec dns-client dig @bind k8s-test.example.local A
```

### UC-002: DNSControl Integration Testing

```bash
# Test DNSControl workflow
docker-compose --profile testing exec dns-client test-dnscontrol

# Interactive DNSControl testing
docker-compose --profile testing exec dns-client bash
cd /workspace
dnscontrol check      # Validate configuration
dnscontrol preview    # Preview changes
# dnscontrol push     # Apply changes (uncomment when ready)
```

### UC-003: octoDNS Integration Testing

```bash
# Test octoDNS workflow
docker-compose --profile testing exec dns-client test-octodns

# Interactive octoDNS testing
docker-compose --profile testing exec dns-client octodns-activate bash
cd /workspace
octodns-validate --config-file config.yaml         # Validate
octodns-sync --config-file config.yaml --plan      # Plan
# octodns-sync --config-file config.yaml           # Apply (uncomment when ready)
```

## Example Configurations

The container automatically creates example configurations if they don't exist:

### DNSControl Example (`dnsconfig.js`)
```javascript
var REG_NONE = NewRegistrar("none");
var DSP_BIND = NewDnsProvider("bind", {
    "server": "bind:53",
    "tsig_key_name": "external-dns-key",
    "tsig_key_algorithm": "hmac-sha256",
    "tsig_key_secret": env.EXTERNAL_DNS_TSIG_KEY_SECRET
});

D("example.local", REG_NONE, DnsProvider(DSP_BIND),
    A("@", "192.168.1.100"),
    A("www", "192.168.1.100"),
    A("api", "192.168.1.101"),
    CNAME("mail", "www"),
    MX("@", 10, "mail.example.local."),
    TXT("@", "v=spf1 include:_spf.google.com ~all")
);
```

### octoDNS Example (`config.yaml`)
```yaml
providers:
  bind:
    class: octodns_bind.BindProvider
    host: bind
    port: 53
    key_name: external-dns-key
    key_algorithm: HMAC-SHA256
    key_secret: env/EXTERNAL_DNS_TSIG_KEY_SECRET

zones:
  example.local.:
    sources:
      - bind
    targets:
      - bind
```

## Environment Variables

The container uses these environment variables from your `.env` file:

| Variable | Description | Default |
|----------|-------------|---------|
| `DNS_SERVER` | BIND DNS server hostname | `bind` |
| `DNS_PORT` | DNS server port | `53` |
| `TEST_ZONE` | Zone for testing | `example.local` |
| `TSIG_KEY_NAME` | Primary TSIG key name | From `.env` |
| `TSIG_KEY_SECRET` | Primary TSIG key secret | From `.env` |
| `EXTERNAL_DNS_TSIG_KEY_NAME` | External-DNS TSIG key name | From `.env` |
| `EXTERNAL_DNS_TSIG_KEY_SECRET` | External-DNS TSIG key secret | From `.env` |

## Troubleshooting

### Container Won't Start
```bash
# Check container logs
docker-compose --profile testing logs dns-client

# Check if BIND DNS is healthy
docker-compose ps bind
```

### DNS Resolution Fails
```bash
# Test connectivity to BIND server
docker-compose --profile testing exec dns-client ping bind

# Check BIND server status
docker-compose --profile testing exec dns-client dig @bind localhost
```

### TSIG Authentication Fails
```bash
# Verify TSIG keys are loaded
docker-compose --profile testing exec dns-client env | grep TSIG

# Test TSIG manually
docker-compose --profile testing exec dns-client bash -c '
dig @bind -y hmac-sha256:$EXTERNAL_DNS_TSIG_KEY_NAME:$EXTERNAL_DNS_TSIG_KEY_SECRET example.local SOA
'
```

### DNSControl/octoDNS Issues
```bash
# Check tool versions
docker-compose --profile testing exec dns-client dnscontrol version
docker-compose --profile testing exec dns-client octodns-activate octodns-validate --version

# Rebuild container with latest tools
docker-compose build dns-client
```

## Advanced Usage

### Custom Testing Scripts

You can mount custom testing scripts into the container:

```bash
# Create custom test script
cat > my-test.sh << 'EOF'
#!/bin/bash
echo "Running custom DNS tests..."
# Your custom test logic here
EOF

# Run it in the container
docker-compose --profile testing exec dns-client bash /workspace/my-test.sh
```

### Persistent Testing Environment

```bash
# Keep the container running for extended testing
docker-compose --profile testing up -d dns-client

# Multiple terminal sessions
docker-compose --profile testing exec dns-client bash  # Terminal 1
docker-compose --profile testing exec dns-client bash  # Terminal 2
```

### Network Analysis

```bash
# Monitor DNS traffic
docker-compose --profile testing exec dns-client tcpdump -i any port 53

# Test network connectivity
docker-compose --profile testing exec dns-client netcat -zv bind 53
```

## Integration with CI/CD

The testing container can be used in CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Test DNS Integration
  run: |
    ./env-manager.sh generate-keys
    docker-compose up -d bind
    docker-compose --profile testing run --rm dns-client run-all-tests
```

This containerized testing approach ensures consistent, reproducible testing across all environments and use cases.
