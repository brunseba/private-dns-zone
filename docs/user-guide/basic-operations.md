# Basic Operations

This guide covers the fundamental operations for managing your BIND DNS server with TSIG authentication. Whether you're new to DNS administration or transitioning from another DNS server, this guide will help you get productive quickly.

## 🚀 Starting and Stopping the Server

### Starting the DNS Server

=== "Docker Compose"
    ```bash
    # Start in background (recommended for production)
    docker-compose up -d
    
    # Start with logs visible (useful for debugging)
    docker-compose up
    
    # Start specific service only
    docker-compose up -d bind
    ```

=== "Individual Container"
    ```bash
    # Run BIND container directly
    docker run -d \
      --name bind-dns \
      -p 53:53/udp -p 53:53/tcp -p 953:953/tcp \
      -v $(pwd)/config:/etc/bind \
      -v $(pwd)/zones:/var/lib/bind \
      -v $(pwd)/logs:/var/log/bind \
      internetsystemsconsortium/bind9:9.19
    ```

### Stopping the DNS Server

```bash
# Stop all services gracefully
docker-compose down

# Stop and remove volumes (⚠️ deletes data)
docker-compose down -v

# Force stop if graceful shutdown fails
docker-compose kill
```

### Checking Server Status

```bash
# Check container status
docker-compose ps

# View resource usage
docker-compose top

# Check health status
docker-compose exec bind rndc status
```

## 🔍 Basic DNS Queries

### Testing DNS Resolution

=== "Using dig"
    ```bash
    # Basic A record lookup
    dig @localhost www.example.local
    
    # Short answer only
    dig @localhost www.example.local +short
    
    # Specific record type
    dig @localhost example.local MX
    
    # Reverse lookup
    dig @localhost -x 192.168.1.20
    
    # Query with TSIG authentication
    dig @localhost -k tsig-key:dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24= www.example.local
    ```

=== "Using nslookup"
    ```bash
    # Interactive mode
    nslookup
    > server localhost
    > www.example.local
    > exit
    
    # Command line mode
    nslookup www.example.local localhost
    
    # Specific record type
    nslookup -type=MX example.local localhost
    ```

=== "Using host"
    ```bash
    # Basic lookup
    host www.example.local localhost
    
    # All record types
    host -a example.local localhost
    
    # Specific type
    host -t MX example.local localhost
    ```

### Understanding Query Results

```bash
# Example dig output explanation
$ dig @localhost www.example.local

; <<>> DiG 9.16.1 <<>> @localhost www.example.local
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; QUESTION SECTION:
;www.example.local.		IN	A

;; ANSWER SECTION:
www.example.local.	604800	IN	A	192.168.1.20

;; AUTHORITY SECTION:
example.local.		604800	IN	NS	ns1.example.local.
example.local.		604800	IN	NS	ns2.example.local.

;; ADDITIONAL SECTION:
ns1.example.local.	604800	IN	A	192.168.1.10
ns2.example.local.	604800	IN	A	192.168.1.11

;; Query time: 1 msec
;; SERVER: 127.0.0.1#53(127.0.0.1)
;; WHEN: Fri Jun 21 15:30:00 UTC 2024
;; MSG SIZE  rcvd: 123
```

**Key sections explained:**
- **QUESTION**: What was asked
- **ANSWER**: Direct response to the question
- **AUTHORITY**: Authoritative name servers for the domain
- **ADDITIONAL**: Extra helpful records

## 📊 Monitoring and Logging

### Viewing Logs

=== "Container Logs"
    ```bash
    # View recent logs
    docker-compose logs bind
    
    # Follow logs in real-time
    docker-compose logs -f bind
    
    # Last 100 lines
    docker-compose logs --tail=100 bind
    
    # Logs with timestamps
    docker-compose logs -t bind
    ```

=== "BIND Log Files"
    ```bash
    # Main BIND log
    docker-compose exec bind tail -f /var/log/bind/named.log
    
    # Security events
    docker-compose exec bind tail -f /var/log/bind/security.log
    
    # Query logs (if enabled)
    docker-compose exec bind tail -f /var/log/bind/queries.log
    
    # All logs together
    docker-compose exec bind tail -f /var/log/bind/*.log
    ```

### Understanding Log Entries

```bash
# Example log entries and their meanings

# Normal query
21-Jun-2024 15:30:00.123 queries: info: client 192.168.1.100#54321 (www.example.local): query: www.example.local IN A + (192.168.1.10)

# TSIG authentication success
21-Jun-2024 15:30:01.456 security: info: client 192.168.1.100#54321: update 'test.local/IN' approved

# TSIG authentication failure
21-Jun-2024 15:30:02.789 security: warning: client 192.168.1.100#54321: request has invalid signature: TSIG tsig-key: signature failed to verify

# Zone transfer
21-Jun-2024 15:30:03.012 xfer-out: info: client 192.168.1.11#53: transfer of 'example.local/IN': AXFR started (serial 2024062101)
```

### Performance Monitoring

```bash
# Check DNS server statistics
docker-compose exec bind rndc stats

# View statistics file
docker-compose exec bind cat /var/log/bind/named_stats.txt

# Query current status
docker-compose exec bind rndc status

# Check memory usage
docker-compose exec bind rndc recursing
```

## 🔧 Configuration Management

### Validating Configuration

```bash
# Check main configuration syntax
docker-compose exec bind named-checkconf /etc/bind/named.conf

# Check specific zone file
docker-compose exec bind named-checkzone example.local /var/lib/bind/db.example.local

# Validate all zones
docker-compose exec bind named-checkconf -z /etc/bind/named.conf
```

### Reloading Configuration

```bash
# Reload configuration (preserves cache)
docker-compose exec bind rndc reload

# Reload specific zone
docker-compose exec bind rndc reload example.local

# Restart BIND (clears cache)
docker-compose restart bind

# Reread configuration (same as reload)
docker-compose exec bind rndc reconfig
```

### Cache Management

```bash
# Flush entire cache
docker-compose exec bind rndc flush

# Flush specific domain from cache
docker-compose exec bind rndc flushname www.example.local

# Flush reverse lookup cache
docker-compose exec bind rndc flushname 192.168.1.20

# View cache contents (dump to file)
docker-compose exec bind rndc dumpdb -cache
docker-compose exec bind cat /var/log/bind/cache_dump.db
```

## 🔑 TSIG Key Operations

### Testing TSIG Authentication

```bash
# Test query with TSIG key
dig @localhost -k tsig-key:dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24= www.example.local

# Expected success indicators:
# - Response includes TSIG section
# - No TSIG error in response
# - Status: NOERROR
```

### TSIG Troubleshooting

Common TSIG errors and solutions:

| Error | Meaning | Solution |
|-------|---------|----------|
| `TSIG error with server: signature failed to verify` | Wrong key or algorithm | Check key and algorithm match |
| `TSIG error with server: clock skew too great` | Time difference too large | Sync server clocks (NTP) |
| `TSIG error with server: TSIG key not found` | Key name not recognized | Verify key name in configuration |

```bash
# Debug TSIG issues
# 1. Check time synchronization
docker-compose exec bind date
date

# 2. Verify key configuration
docker-compose exec bind named-checkconf -p | grep -A 5 "key.*tsig-key"

# 3. Test with verbose output
dig @localhost +trace +dnssec -k tsig-key:dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24= www.example.local
```

## 📝 Dynamic DNS Updates

### Using nsupdate

=== "Basic Update"
    ```bash
    # Create update script
    cat > update.txt << EOF
    server localhost
    key tsig-key dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24=
    zone test.local
    update add newhost.test.local 300 A 10.0.0.100
    send
    EOF
    
    # Apply update
    nsupdate update.txt
    ```

=== "Interactive Update"
    ```bash
    # Start interactive session
    nsupdate -k tsig-key:dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24=
    > server localhost
    > zone test.local
    > update add dynamic.test.local 300 A 10.0.0.200
    > send
    > quit
    ```

=== "Using Update Script"
    ```bash
    # Use provided script
    ./scripts/update-dns.sh add myserver A 10.0.0.150
    
    # Add CNAME record
    ./scripts/update-dns.sh add myalias CNAME myserver
    
    # Delete record
    ./scripts/update-dns.sh delete myserver A
    ```

### Verifying Updates

```bash
# Check if update was successful
dig @localhost newhost.test.local +short

# View zone journal (shows recent changes)
docker-compose exec bind cat /var/lib/bind/db.test.local.jnl

# Check logs for update confirmation
docker-compose logs bind | grep "update.*approved"
```

## 🩺 Health Checks and Troubleshooting

### Quick Health Check

```bash
#!/bin/bash
# DNS Server Health Check Script

echo "=== DNS Server Health Check ==="

# 1. Container status
echo "1. Container Status:"
docker-compose ps bind

# 2. DNS service response
echo "2. DNS Service Response:"
if dig @localhost localhost +short >/dev/null 2>&1; then
    echo "✅ DNS service responding"
else
    echo "❌ DNS service not responding"
fi

# 3. TSIG authentication
echo "3. TSIG Authentication:"
if dig @localhost -k tsig-key:dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24= localhost >/dev/null 2>&1; then
    echo "✅ TSIG authentication working"
else
    echo "❌ TSIG authentication failed"
fi

# 4. Zone loading
echo "4. Zone Status:"
docker-compose exec bind rndc status | grep "zones loaded"

# 5. Recent errors
echo "5. Recent Errors:"
docker-compose logs --tail=10 bind | grep -i error || echo "No recent errors"

echo "=== Health Check Complete ==="
```

### Common Issues and Solutions

| Problem | Symptoms | Solution |
|---------|----------|----------|
| DNS not resolving | `SERVFAIL` or timeout | Check configuration, restart service |
| TSIG errors | Authentication failures | Verify keys, check time sync |
| Zone not loading | Zone queries fail | Validate zone file syntax |
| Permission denied | Container fails to start | Check file permissions |
| Port conflicts | Bind fails on port 53 | Stop conflicting services |

### Performance Tuning Tips

```bash
# 1. Monitor query performance
dig @localhost www.example.local | grep "Query time"

# 2. Check cache hit ratio
docker-compose exec bind rndc stats
docker-compose exec bind grep -E "(cache|hits|misses)" /var/log/bind/named_stats.txt

# 3. Monitor memory usage
docker-compose exec bind rndc status | grep memory

# 4. Optimize for your workload
# - Increase cache size for high query volume
# - Adjust TTL values for your needs
# - Consider secondary servers for load distribution
```

This covers the essential day-to-day operations for managing your BIND DNS server with TSIG. For more advanced topics, see the specialized guides in this documentation.
