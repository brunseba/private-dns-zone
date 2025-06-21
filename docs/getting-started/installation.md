# Installation Guide

This guide provides detailed installation instructions for the BIND DNS server with TSIG support across different environments and deployment scenarios.

## 🐳 Docker-based Installation (Recommended)

The easiest way to get started is using our pre-configured Docker setup.

### Prerequisites

=== "Linux (Ubuntu/Debian)"
    ```bash
    # Update package list
    sudo apt update
    
    # Install Docker
    sudo apt install docker.io docker-compose
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Start Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Verify installation
    docker --version
    docker-compose --version
    ```

=== "macOS"
    ```bash
    # Install Docker Desktop
    # Download from https://docker.com/products/docker-desktop
    
    # Or using Homebrew
    brew install --cask docker
    
    # Verify installation
    docker --version
    docker-compose --version
    ```

=== "Windows"
    ```powershell
    # Install Docker Desktop for Windows
    # Download from https://docker.com/products/docker-desktop
    
    # Or using Chocolatey
    choco install docker-desktop
    
    # Verify installation
    docker --version
    docker-compose --version
    ```

### Quick Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-org/private-dns-zone.git
cd private-dns-zone

# 2. Start the DNS server
docker-compose up -d

# 3. Verify installation
dig @localhost www.example.local
```

### Custom Installation

For production environments, you may want to customize the installation:

```bash
# 1. Clone and configure
git clone https://github.com/your-org/private-dns-zone.git
cd private-dns-zone

# 2. Generate new TSIG keys (recommended for production)
./scripts/generate-tsig-keys.sh

# 3. Customize configuration
cp config/named.conf.local config/named.conf.local.backup
# Edit configuration files as needed

# 4. Validate configuration
docker-compose run --rm bind named-checkconf /etc/bind/named.conf

# 5. Start with custom configuration
docker-compose up -d
```

## 📦 Native Installation

For environments where Docker is not available or desired.

### Ubuntu/Debian

```bash
# 1. Install BIND
sudo apt update
sudo apt install bind9 bind9utils bind9-doc

# 2. Stop default BIND service
sudo systemctl stop bind9
sudo systemctl disable bind9

# 3. Create directory structure
sudo mkdir -p /etc/bind/zones
sudo mkdir -p /var/log/bind

# 4. Copy configuration files
sudo cp config/* /etc/bind/
sudo cp zones/* /etc/bind/zones/

# 5. Set permissions
sudo chown -R bind:bind /etc/bind
sudo chown -R bind:bind /var/log/bind
sudo chmod 640 /etc/bind/named.conf.keys

# 6. Start BIND
sudo systemctl start bind9
sudo systemctl enable bind9
```

### CentOS/RHEL/Rocky Linux

```bash
# 1. Install BIND
sudo dnf install bind bind-utils

# 2. Stop default BIND service
sudo systemctl stop named
sudo systemctl disable named

# 3. Create directory structure
sudo mkdir -p /etc/named/zones
sudo mkdir -p /var/log/named

# 4. Copy configuration files
sudo cp config/named.conf /etc/named.conf
sudo cp config/named.conf.* /etc/named/
sudo cp zones/* /etc/named/zones/

# 5. Set SELinux contexts (if enabled)
sudo setsebool -P named_write_master_zones 1
sudo restorecon -R /etc/named
sudo restorecon -R /var/log/named

# 6. Set permissions
sudo chown -R named:named /etc/named
sudo chown -R named:named /var/log/named
sudo chmod 640 /etc/named/named.conf.keys

# 7. Start BIND
sudo systemctl start named
sudo systemctl enable named
```

### FreeBSD

```bash
# 1. Install BIND
sudo pkg install bind916

# 2. Enable BIND in rc.conf
sudo sysrc named_enable="YES"
sudo sysrc named_conf="/usr/local/etc/namedb/named.conf"

# 3. Create directory structure
sudo mkdir -p /usr/local/etc/namedb/zones
sudo mkdir -p /var/log/named

# 4. Copy configuration files
sudo cp config/* /usr/local/etc/namedb/
sudo cp zones/* /usr/local/etc/namedb/zones/

# 5. Set permissions
sudo chown -R bind:bind /usr/local/etc/namedb
sudo chown -R bind:bind /var/log/named
sudo chmod 640 /usr/local/etc/namedb/named.conf.keys

# 6. Start BIND
sudo service named start
```

## 🔧 Configuration Validation

After installation, validate your configuration:

```bash
# Check main configuration syntax
named-checkconf /etc/bind/named.conf  # Ubuntu/Debian
named-checkconf /etc/named.conf       # CentOS/RHEL

# Check zone files
named-checkzone example.local /etc/bind/zones/db.example.local

# Test TSIG key configuration
dig @localhost -k tsig-key:dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24= www.example.local
```

## 🏗️ Production Setup

### High Availability Configuration

For production environments, consider this multi-server setup:

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  bind-primary:
    image: internetsystemsconsortium/bind9:9.19
    hostname: ns1.example.com
    networks:
      - dns-network
    volumes:
      - ./config:/etc/bind
      - ./zones:/var/lib/bind
      - bind-logs:/var/log/bind
    ports:
      - "53:53/udp"
      - "53:53/tcp"
    environment:
      - BIND9_USER=bind
    restart: unless-stopped

  bind-secondary:
    image: internetsystemsconsortium/bind9:9.19
    hostname: ns2.example.com
    networks:
      - dns-network
    volumes:
      - ./config-secondary:/etc/bind
      - bind-secondary-zones:/var/lib/bind
      - bind-secondary-logs:/var/log/bind
    environment:
      - BIND9_USER=bind
    restart: unless-stopped
    depends_on:
      - bind-primary

  monitoring:
    image: prom/prometheus
    networks:
      - dns-network
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    restart: unless-stopped

networks:
  dns-network:
    driver: bridge

volumes:
  bind-logs:
  bind-secondary-zones:
  bind-secondary-logs:
```

### Security Hardening

```bash
# 1. Generate production TSIG keys
openssl rand -base64 32 > /tmp/master-key
openssl rand -base64 32 > /tmp/admin-key

# 2. Set strict file permissions
chmod 600 /etc/bind/named.conf.keys
chown root:bind /etc/bind/named.conf.keys

# 3. Configure firewall
# Ubuntu/Debian
sudo ufw allow 53/udp
sudo ufw allow 53/tcp
sudo ufw allow from trusted_network to any port 953

# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="trusted_network/24" port protocol="tcp" port="953" accept'
sudo firewall-cmd --reload

# 4. Setup log rotation
cat > /etc/logrotate.d/bind << EOF
/var/log/bind/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        /bin/systemctl reload bind9 > /dev/null 2>&1 || true
    endscript
}
EOF
```

## 🚀 Kubernetes Deployment

For containerized environments with Kubernetes:

```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dns-system

---
# k8s/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: bind-config
  namespace: dns-system
data:
  named.conf: |
    # BIND configuration content here

---
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bind-dns
  namespace: dns-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: bind-dns
  template:
    metadata:
      labels:
        app: bind-dns
    spec:
      containers:
      - name: bind
        image: internetsystemsconsortium/bind9:9.19
        ports:
        - containerPort: 53
          protocol: UDP
        - containerPort: 53
          protocol: TCP
        volumeMounts:
        - name: config
          mountPath: /etc/bind
        - name: zones
          mountPath: /var/lib/bind
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: config
        configMap:
          name: bind-config
      - name: zones
        persistentVolumeClaim:
          claimName: bind-zones-pvc

---
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: bind-dns-service
  namespace: dns-system
spec:
  selector:
    app: bind-dns
  ports:
  - name: dns-udp
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
  type: LoadBalancer
```

## 📋 Post-Installation Checklist

After installation, verify these items:

- [ ] DNS server responds to queries
- [ ] TSIG authentication works
- [ ] Zone files load correctly
- [ ] Logs are being written
- [ ] Security configurations are active
- [ ] Backup procedures are in place
- [ ] Monitoring is configured
- [ ] Documentation is updated

## 🔍 Troubleshooting Installation Issues

### Common Problems

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Permission denied | Container fails to start | Check file ownership and permissions |
| Port already in use | Bind error on port 53 | Stop conflicting DNS services |
| Configuration syntax error | BIND fails to start | Validate configuration with `named-checkconf` |
| TSIG key not found | Authentication failures | Verify key configuration and syntax |
| Zone loading failed | Queries return SERVFAIL | Check zone file syntax with `named-checkzone` |

### Debug Commands

```bash
# Check BIND process
ps aux | grep named

# Check listening ports
sudo netstat -tulpn | grep :53

# Test configuration
named-checkconf -z

# Check system logs
journalctl -u bind9 -f  # systemd systems
tail -f /var/log/messages | grep named  # syslog systems

# Docker-specific debugging
docker-compose logs bind
docker-compose exec bind rndc status
```

This installation guide covers the most common deployment scenarios. For specific requirements or advanced configurations, refer to the BIND configuration files in the `config/` directory.
