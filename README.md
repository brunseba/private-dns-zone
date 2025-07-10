# BIND DNS Server with TSIG Key Support

This repository contains a Docker Compose setup for running a BIND DNS server with TSIG (Transaction Signature) key support for secure DNS operations.

## Features

### v1.2.0 - 2025-07-10
- **Fixed BIND DNS server configuration with Ubuntu image**
- Resolved zone file conflicts in default zones
- Simplified BIND named command execution

### v1.1.0 - 2025-07-09
- Significant image size reduction from 1.77GB to 168MB
- Multistage Docker build optimization
- DNSControl v4.8.0 with Go 1.22 compatibility
- Complete octoDNS toolkit with Python 3.11

---

- ✅ BIND DNS server
- ✅ TSIG key authentication for secure operations
- ✅ Zone transfers with TSIG authentication
- ✅ Dynamic DNS updates with TSIG keys
- ✅ RNDC remote control
- ✅ Comprehensive logging
- ✅ Health checks
- ✅ Sample zones (example.local, dev.local, test.local, k8s.local)
- ✅ **Kubernetes external-dns integration** for automatic DNS management

## 🎯 Use Cases

This DNS server solution is ideal for:

### 🐳 Development
- Local development environments
- Testing DNS configurations
- Microservices discovery
- Container orchestration

### 🏭 Production
- Private DNS zones
- Internal service discovery
- Secure zone transfers
- Enterprise DNS infrastructure

### ☸️ Kubernetes Integration
- **External-DNS automation** - Automatic DNS record management for K8s services
- **Service discovery** - Kubernetes services → DNS records
- **Ingress management** - Automatic hostname resolution for ingresses
- **Multi-cluster DNS** - Centralized DNS for multiple Kubernetes clusters
- **TSIG-secured updates** - Secure dynamic updates from external-dns

### 📚 Learning
- DNS protocol understanding
- TSIG authentication mechanisms
- BIND configuration and management
- Security best practices

## Quick Start

1. **Start the DNS server:**
   ```bash
   docker-compose up -d
   ```

2. **Check server status:**
   ```bash
   docker-compose logs bind
   ```

3. **Test DNS resolution:**
   ```bash
   dig @localhost www.example.local
   ```

## TSIG Keys

The configuration includes three TSIG keys:

- **tsig-key**: Primary key for zone operations (transfers, updates)
- **admin-key**: Secondary key for administrative operations
- **rndc-key**: Key for remote control operations

⚠️ **Security Note**: The included keys are for testing only. Generate new keys for production use.

## Generating New TSIG Keys

To generate a new TSIG key:

```bash
# Generate a new key
tsig-keygen -a hmac-sha256 my-key-name

# Or using dnssec-keygen
dnssec-keygen -a HMAC-SHA256 -b 256 -n HOST my-key-name
```

## Dynamic DNS Updates

Use `nsupdate` to perform dynamic DNS updates with TSIG authentication:

```bash
# Create an nsupdate script
cat > update.txt << EOF
server localhost
key tsig-key dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24=
zone test.local
update add dynamic.test.local 300 A 10.0.0.100
send
EOF

# Apply the update
nsupdate update.txt
```

## Zone Management

### Available Zones

- `example.local`: Sample production-like zone
- `dev.local`: Development environment zone
- `test.local`: Testing zone for dynamic updates
- Reverse zones for PTR records

### Adding New Zones

1. Add zone definition to `config/named.conf.local`
2. Create zone file in `zones/` directory
3. Restart the container: `docker-compose restart bind`

## Remote Control (RNDC)

Use RNDC for server management:

```bash
# Reload configuration
docker-compose exec bind rndc reload

# Check server status
docker-compose exec bind rndc status

# Flush cache
docker-compose exec bind rndc flush
```

## Security Considerations

1. **Change Default Keys**: Replace sample TSIG keys with secure, randomly generated keys
2. **Network Access**: Restrict access to DNS ports (53, 953) to trusted networks
3. **File Permissions**: Ensure proper file permissions on configuration files
4. **Logging**: Monitor logs for unauthorized access attempts
5. **Updates**: Regularly update the BIND Docker image

## Troubleshooting

### Check Configuration Syntax
```bash
docker-compose exec bind named-checkconf /etc/bind/named.conf
```

### Validate Zone Files
```bash
docker-compose exec bind named-checkzone example.local /var/lib/bind/db.example.local
```

### View Logs
```bash
# Container logs
docker-compose logs -f bind

# BIND logs
docker-compose exec bind tail -f /var/log/bind/named.log
```

### Test TSIG Authentication
```bash
dig @localhost -k tsig-key:dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24= www.example.local
```

## Directory Structure

```
.
├── docker-compose.yml          # Docker Compose configuration
├── config/                     # BIND configuration files
│   ├── named.conf             # Main configuration
│   ├── named.conf.keys        # TSIG keys
│   ├── named.conf.local       # Local zones
│   └── named.conf.default-zones # Default zones
├── zones/                      # Zone files
│   ├── db.example.local       # Example zone
│   ├── db.dev.local          # Development zone
│   ├── db.test.local         # Test zone
│   └── db.192.168.1          # Reverse zone
└── logs/                      # Log files (created at runtime)
```

## ☸️ Kubernetes Integration with external-dns

Automate DNS record management for Kubernetes services and ingresses:

### Quick Setup

```bash
# 1. Start BIND DNS server
docker-compose up -d

# 2. Install external-dns in Kubernetes
cd kubernetes
./install-external-dns.sh install

# 3. Deploy test service with DNS annotation
kubectl apply -f examples/test-services.yaml

# 4. Verify DNS record creation
dig @localhost nginx.k8s.local
```

### Features

- **Automatic DNS Records** - Services/Ingresses → DNS records
- **TSIG Authentication** - Secure updates from Kubernetes
- **Multiple Zones** - Support for different environments
- **TTL Management** - Configurable record lifetimes
- **Cleanup** - Automatic record removal when resources are deleted

### Service Example

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.k8s.local
    external-dns.alpha.kubernetes.io/ttl: "300"
spec:
  type: LoadBalancer
  # ... service configuration
```

See [kubernetes/EXTERNAL_DNS_GUIDE.md](kubernetes/EXTERNAL_DNS_GUIDE.md) for complete setup and usage instructions.

## Performance Tuning

For production environments, consider:

- Adjusting cache sizes in `named.conf`
- Enabling query logging selectively
- Configuring rate limiting
- Setting up secondary name servers
- Implementing monitoring and alerting

## License

## 📚 Documentation

Comprehensive documentation is available using MkDocs:

```bash
# Install documentation dependencies
pip install -r docs-requirements.txt

# Serve documentation locally
mkdocs serve

# Access at http://127.0.0.1:8000
```

The documentation includes:
- **Getting Started** - Quick setup and installation guides
- **Architecture** - System design and TSIG security details  
- **User Guide** - Daily operations and troubleshooting
- **Configuration** - Advanced setup and customization
- **API Reference** - Complete technical reference

## License

This configuration is provided as-is for educational and development purposes.
