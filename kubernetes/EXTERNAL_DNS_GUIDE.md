# External-DNS with BIND DNS Integration Guide

This guide explains how to use external-dns in Kubernetes to automatically manage DNS records in your BIND DNS server running via Docker Compose.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Kubernetes    │    │   external-dns   │    │   BIND DNS      │
│   Services &    │───▶│   Controller     │───▶│   Server        │
│   Ingresses     │    │   (RFC2136)      │    │   (Docker)      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                         │
                                │ TSIG Authentication     │
                                └─────────────────────────┘
```

## 🚀 Quick Setup

### 1. Prepare BIND DNS Server

Ensure your BIND DNS server is running with the k8s.local zone:

```bash
# Start BIND DNS server
docker-compose up -d

# Verify k8s.local zone is loaded
docker-compose exec bind dig @localhost k8s.local SOA

# Test TSIG authentication
docker-compose exec bind dig @localhost -k tsig-key:${TSIG_KEY_SECRET} k8s.local SOA
```

### 2. Install external-dns

```bash
# Navigate to kubernetes directory
cd kubernetes

# Install with default settings (Docker Desktop)
./install-external-dns.sh install

# Or specify BIND host for other environments
BIND_HOST=192.168.1.100 ./install-external-dns.sh install
```

### 3. Test with Example Service

```bash
# Deploy test service
kubectl apply -f examples/test-services.yaml

# Check external-dns logs
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns -f

# Verify DNS record creation
dig @localhost nginx.k8s.local
```

## ⚙️ Configuration Options

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BIND_HOST` | `host.docker.internal` | BIND DNS server hostname |
| `BIND_PORT` | `53` | BIND DNS server port |
| `BIND_ZONE` | `k8s.local` | DNS zone to manage |
| `TSIG_KEY_NAME` | `tsig-key` | TSIG key name |
| `TSIG_KEY_SECRET` | From `.env` | TSIG key secret |

### Different Environments

#### Docker Desktop (macOS/Windows)
```bash
# Uses host.docker.internal (default)
./install-external-dns.sh install
```

#### Linux with Docker
```bash
# Use host IP address
BIND_HOST=172.17.0.1 ./install-external-dns.sh install
```

#### Remote BIND Server
```bash
# Use actual IP address
BIND_HOST=192.168.1.100 ./install-external-dns.sh install
```

#### Custom Zone
```bash
# Use different zone
BIND_ZONE=example.local ./install-external-dns.sh install
```

## 📝 Using external-dns Annotations

### Service Annotations

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    # Basic hostname
    external-dns.alpha.kubernetes.io/hostname: myapp.k8s.local
    
    # Multiple hostnames
    external-dns.alpha.kubernetes.io/hostname: myapp.k8s.local,api.k8s.local
    
    # Custom TTL
    external-dns.alpha.kubernetes.io/ttl: "300"
    
    # CNAME target
    external-dns.alpha.kubernetes.io/target: "real-server.example.com"
spec:
  type: LoadBalancer
  # ... rest of service spec
```

### Ingress Annotations

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    # Hostname from ingress rules
    external-dns.alpha.kubernetes.io/hostname: web.k8s.local,app.k8s.local
    
    # Custom TTL
    external-dns.alpha.kubernetes.io/ttl: "600"
spec:
  rules:
    - host: web.k8s.local
      # ... ingress rules
```

## 🔧 Management Commands

### Installation and Upgrades

```bash
# Install external-dns
./install-external-dns.sh install

# Upgrade external-dns
./install-external-dns.sh upgrade

# Uninstall external-dns
./install-external-dns.sh uninstall
```

### Monitoring and Troubleshooting

```bash
# Check status
./install-external-dns.sh status

# View logs
./install-external-dns.sh logs

# Check pod status
kubectl get pods -n external-dns

# Describe pod for details
kubectl describe pod -n external-dns -l app.kubernetes.io/name=external-dns
```

## 🧪 Testing and Validation

### 1. Deploy Test Services

```bash
# Deploy example services
kubectl apply -f examples/test-services.yaml

# Check services are created
kubectl get svc
```

### 2. Verify DNS Records

```bash
# Check if DNS records are created
dig @localhost nginx.k8s.local
dig @localhost api.k8s.local
dig @localhost web.k8s.local

# Check TXT records (used by external-dns for tracking)
dig @localhost TXT external-dns-nginx.k8s.local
```

### 3. Test Record Updates

```bash
# Update service annotation
kubectl annotate service nginx-service external-dns.alpha.kubernetes.io/hostname=nginx-new.k8s.local --overwrite

# Watch logs for updates
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns -f

# Verify new record
dig @localhost nginx-new.k8s.local
```

### 4. Test Record Deletion

```bash
# Delete service
kubectl delete service nginx-service

# Verify record is removed
dig @localhost nginx.k8s.local
```

## 🔍 Troubleshooting

### Common Issues

#### 1. external-dns Cannot Connect to BIND

**Symptoms:**
- Logs show connection timeouts
- No DNS records are created

**Solutions:**
```bash
# Check BIND host configuration
echo $BIND_HOST

# Test connectivity from Kubernetes
kubectl run test-pod --image=busybox --rm -it -- nslookup k8s.local $BIND_HOST

# For Docker Desktop, try different hosts:
BIND_HOST=host.docker.internal ./install-external-dns.sh upgrade
BIND_HOST=docker.for.mac.localhost ./install-external-dns.sh upgrade  # macOS
BIND_HOST=docker.for.windows.localhost ./install-external-dns.sh upgrade  # Windows
```

#### 2. TSIG Authentication Failures

**Symptoms:**
- Logs show "TSIG signature verification failed"
- DNS updates are rejected

**Solutions:**
```bash
# Check TSIG key in secret
kubectl get secret external-dns-tsig-secret -n external-dns -o yaml

# Verify TSIG key matches BIND configuration
docker-compose exec bind named-checkconf -p | grep -A 5 "tsig-key"

# Test TSIG manually
docker-compose exec bind dig @localhost -k tsig-key:${TSIG_KEY_SECRET} k8s.local SOA
```

#### 3. Zone Not Found

**Symptoms:**
- Logs show "zone not found" errors
- Records are not created

**Solutions:**
```bash
# Check if zone exists in BIND
docker-compose exec bind dig @localhost k8s.local SOA

# Check zone configuration
docker-compose exec bind named-checkzone k8s.local /var/lib/bind/db.k8s.local

# Restart BIND if needed
docker-compose restart bind
```

#### 4. Network Connectivity Issues

**Symptoms:**
- Connection timeouts
- DNS queries fail

**Solutions:**
```bash
# Check Docker network
docker network ls
docker network inspect private-dns-zone_dns-network

# Check if BIND is listening
docker-compose exec bind netstat -tulpn | grep :53

# Test from host
dig @localhost k8s.local SOA
```

### Debug Commands

```bash
# Enable debug logging
kubectl patch deployment external-dns -n external-dns -p '{"spec":{"template":{"spec":{"containers":[{"name":"external-dns","args":["--source=service","--source=ingress","--provider=rfc2136","--rfc2136-host='$BIND_HOST'","--rfc2136-port=53","--rfc2136-zone=k8s.local","--rfc2136-tsig-secret=external-dns-tsig-secret","--rfc2136-tsig-secret-alg=hmac-sha256","--rfc2136-tsig-keyname=tsig-key","--rfc2136-tsig-axfr","--domain-filter=k8s.local","--registry=txt","--txt-owner-id=external-dns-k8s","--txt-prefix=external-dns-","--log-level=debug","--events"]}]}}}}'

# Check BIND logs
docker-compose logs bind

# Check external-dns events
kubectl get events -n external-dns --sort-by='.lastTimestamp'

# Test BIND connectivity
kubectl run debug-pod --image=nicolaka/netshoot --rm -it -- bash
# Then inside the pod:
# dig @$BIND_HOST k8s.local SOA
# nslookup k8s.local $BIND_HOST
```

## 📊 Monitoring and Metrics

### Prometheus Metrics

external-dns exposes metrics on port 7979:

```bash
# Port forward to access metrics
kubectl port-forward -n external-dns svc/external-dns-metrics 7979:7979

# View metrics
curl http://localhost:7979/metrics
```

### Key Metrics

- `external_dns_source_endpoints_total` - Number of endpoints from sources
- `external_dns_registry_endpoints_total` - Number of endpoints in registry
- `external_dns_controller_last_sync_timestamp` - Last successful sync
- `external_dns_controller_sync_duration_seconds` - Sync duration

## 🏷️ Best Practices

### 1. Zone Organization

```bash
# Use subdomains for different environments
# Production: app.prod.k8s.local
# Staging: app.staging.k8s.local
# Development: app.dev.k8s.local
```

### 2. TTL Management

```yaml
# Short TTL for development/testing
external-dns.alpha.kubernetes.io/ttl: "60"

# Medium TTL for staging
external-dns.alpha.kubernetes.io/ttl: "300"

# Longer TTL for production
external-dns.alpha.kubernetes.io/ttl: "3600"
```

### 3. Security

```bash
# Use separate TSIG keys for different environments
# Rotate TSIG keys regularly
# Monitor external-dns logs for security events
```

### 4. Backup and Recovery

```bash
# Regular BIND zone backups
docker-compose exec bind cp /var/lib/bind/db.k8s.local /var/lib/bind/backups/

# Monitor journal files
docker-compose exec bind ls -la /var/lib/bind/*.jnl
```

This integration provides automatic DNS management for your Kubernetes services while keeping your BIND DNS server running reliably via Docker Compose!
