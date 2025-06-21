# Devbox Development Environment

This document describes how to use the provided `devbox.json` configuration to quickly set up a development environment with all necessary tools for consuming BIND DNS services.

## What is Devbox?

[Devbox](https://github.com/jetpack-io/devbox) is a command-line tool that creates isolated, reproducible development environments using Nix. It ensures that all team members have the same tool versions and dependencies.

## Prerequisites

1. **Install Devbox**:
   ```bash
   # macOS
   brew install jetpack-io/devbox/devbox
   
   # Linux
   curl -fsSL https://get.jetpack.io/devbox | bash
   ```

2. **Install Nix** (if not already installed):
   ```bash
   sh <(curl -L https://nixos.org/nix/install)
   ```

## Quick Start

1. **Clone the repository** and navigate to the project directory:
   ```bash
   git clone <repository-url>
   cd private-dns-zone
   ```

2. **Start the devbox environment**:
   ```bash
   devbox shell
   ```

   This will:
   - Install all required packages (dig, DNSControl, Python, Go, Docker, etc.)
   - Set up octoDNS Python virtual environment
   - Install DNSControl
   - Verify all installations
   - Display quick start commands

## Included Tools

The devbox environment includes:

### Core DNS Tools
- **BIND utilities** (`dig`, `nslookup`, `nsupdate`) with TSIG support
- **Docker & Docker Compose** for running BIND DNS server

### DNS Management Clients
- **DNSControl** - JavaScript-based declarative DNS management
- **octoDNS** - Python-based DNS-as-code with multi-provider support
- **External-DNS** (documentation and examples)

### Development Tools
- **Go** (for DNSControl and external-dns)
- **Python 3** with pip (for octoDNS)
- **Node.js** and npm (for JavaScript tooling)
- **curl, jq, yq** (for API interactions and data processing)

## Available Scripts

The devbox environment provides several convenient scripts:

### Activate octoDNS Environment
```bash
devbox run activate-octodns
```

### Test DNS Resolution
```bash
devbox run test-dns
```

### Validate All Configurations
```bash
devbox run validate-all
```

### Setup Example Directories
```bash
devbox run setup-examples
```

## Usage Examples

### Testing BIND DNS Server with TSIG

1. **Start the BIND DNS server**:
   ```bash
   ./env-manager.sh generate-keys
   docker-compose up -d
   ```

2. **Test basic DNS resolution**:
   ```bash
   dig @localhost example.local A
   ```

3. **Test with TSIG authentication**:
   ```bash
   # Get TSIG key from environment
   TSIG_KEY=$(grep EXTERNAL_DNS_TSIG_KEY_SECRET .env | cut -d'=' -f2)
   
   # Test with TSIG
   dig @localhost -y hmac-sha256:external-dns-key:$TSIG_KEY example.local A
   ```

### Using DNSControl

1. **Create a basic configuration**:
   ```bash
   cat > dnsconfig.js << 'EOF'
   var REG_NONE = NewRegistrar("none");
   var DSP_BIND = NewDnsProvider("bind", {
       "server": "127.0.0.1:53",
       "tsig_key_name": "external-dns-key",
       "tsig_key_algorithm": "hmac-sha256",
       "tsig_key_secret": env.TSIG_KEY_SECRET
   });
   
   D("example.local", REG_NONE, DnsProvider(DSP_BIND),
       A("@", "192.168.1.100"),
       A("www", "192.168.1.100")
   );
   EOF
   ```

2. **Validate and apply**:
   ```bash
   dnscontrol check
   dnscontrol preview
   dnscontrol push
   ```

### Using octoDNS

1. **Activate the octoDNS environment**:
   ```bash
   source ~/.octodns-env/bin/activate
   ```

2. **Create a basic configuration**:
   ```bash
   cat > config.yaml << 'EOF'
   providers:
     bind:
       class: octodns_bind.BindProvider
       host: 127.0.0.1
       port: 53
       key_name: external-dns-key
       key_algorithm: HMAC-SHA256
       key_secret: env/TSIG_KEY_SECRET
   
   zones:
     example.local.:
       sources:
         - bind
       targets:
         - bind
   EOF
   ```

3. **Create zone file**:
   ```bash
   mkdir -p zones
   cat > zones/example.local.yaml << 'EOF'
   ---
   '':
     - type: A
       value: 192.168.1.100
   www:
     - type: A
       value: 192.168.1.100
   EOF
   ```

4. **Validate and apply**:
   ```bash
   octodns-validate --config-file config.yaml
   octodns-sync --config-file config.yaml --plan
   octodns-sync --config-file config.yaml
   ```

## Environment Variables

The devbox environment sets several useful variables:

- `DNS_SERVER=localhost` - Default DNS server for testing
- `DNS_PORT=53` - Default DNS port
- `PYTHONPATH` - Includes octoDNS virtual environment paths

## Troubleshooting

### Common Issues

1. **DNSControl not found**:
   ```bash
   # Install manually via Go
   go install github.com/StackExchange/dnscontrol/v4@latest
   ```

2. **octoDNS command not found**:
   ```bash
   # Activate the virtual environment
   source ~/.octodns-env/bin/activate
   ```

3. **TSIG authentication fails**:
   ```bash
   # Verify TSIG key is correctly set
   grep TSIG .env
   # Test with nsupdate
   echo -e "server localhost\nupdate add test.example.local 300 A 192.168.1.200\nsend" | nsupdate -y hmac-sha256:external-dns-key:$TSIG_KEY
   ```

### Verification Commands

```bash
# Check all tools are installed
devbox run validate-all

# Test DNS server is running
dig @localhost example.local SOA

# Verify TSIG support
dig -y hmac-sha256:external-dns-key:$TSIG_KEY @localhost example.local SOA
```

## Benefits of Using Devbox

1. **Consistent Environment** - All team members get the same tool versions
2. **Fast Setup** - One command installs everything needed
3. **Isolated** - No conflicts with system packages
4. **Reproducible** - Environment can be recreated anywhere
5. **Version Controlled** - devbox.json tracks exact dependencies

## Next Steps

After setting up the devbox environment:

1. Review the [Use Cases documentation](../use-cases/uc-000-overview.md)
2. Follow specific integration guides:
   - [UC-001: External-DNS Integration](../use-cases/uc-001-external-dns.md)
   - [UC-002: DNSControl Integration](../use-cases/uc-002-dnscontrol.md)
   - [UC-003: octoDNS Integration](../use-cases/uc-003-octodns.md)
3. Explore the example configurations in the `examples/` directory

The devbox environment provides everything you need to develop, test, and deploy DNS management solutions with your BIND DNS server.
