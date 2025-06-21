# TSIG Security Design

This document provides an in-depth look at the TSIG (Transaction Signature) security implementation, covering the cryptographic foundations, key management strategies, and security best practices.

## 🔐 TSIG Overview

TSIG (Transaction Signature) is a mechanism for securing DNS transactions using shared secret keys and message authentication codes (MACs). It provides:

- **Authentication**: Verifies the identity of the sender
- **Integrity**: Ensures messages haven't been tampered with
- **Replay Protection**: Prevents malicious replay attacks
- **Non-repudiation**: Provides proof of message origin

## 🧮 Cryptographic Foundation

### Hash Algorithms

```mermaid
graph TB
    subgraph "Supported Algorithms"
        HMAC_SHA256[HMAC-SHA256]
        HMAC_SHA224[HMAC-SHA224] 
        HMAC_SHA512[HMAC-SHA512]
        HMAC_MD5[HMAC-MD5]
    end
    
    subgraph "Security Level"
        HIGH[High Security]
        MEDIUM[Medium Security]
        LOW[Legacy Support]
    end
    
    subgraph "Use Cases"
        PROD[Production]
        DEV[Development]
        LEGACY[Legacy Systems]
    end
    
    HMAC_SHA256 --> HIGH
    HMAC_SHA224 --> HIGH
    HMAC_SHA512 --> HIGH
    HMAC_MD5 --> LOW
    
    HIGH --> PROD
    MEDIUM --> DEV
    LOW --> LEGACY
```

### Key Properties

| Algorithm | Key Size | MAC Size | Security Level | Recommended |
|-----------|----------|----------|----------------|-------------|
| HMAC-SHA256 | 256 bits | 256 bits | High | ✅ Yes |
| HMAC-SHA224 | 224 bits | 224 bits | High | ✅ Yes |
| HMAC-SHA512 | 512 bits | 512 bits | High | ⚠️ Overkill |
| HMAC-MD5 | 128 bits | 128 bits | Low | ❌ Legacy only |

## 🗝️ Key Management Architecture

### Key Hierarchy

```mermaid
graph TD
    subgraph "Master Key"
        MK[Master Key]
        MK_PURPOSE[Zone Transfers<br/>Critical Operations]
    end
    
    subgraph "Administrative Keys"
        AK[Admin Key]
        AK_PURPOSE[Zone Management<br/>Configuration]
    end
    
    subgraph "Service Keys"
        SK1[Service Key 1]
        SK2[Service Key 2]
        SK3[Service Key N]
        SK_PURPOSE[Application Updates<br/>Dynamic DNS]
    end
    
    subgraph "Control Keys"
        RK[RNDC Key]
        RK_PURPOSE[Remote Control<br/>Server Management]
    end
    
    MK --> MK_PURPOSE
    AK --> AK_PURPOSE
    SK1 --> SK_PURPOSE
    SK2 --> SK_PURPOSE
    SK3 --> SK_PURPOSE
    RK --> RK_PURPOSE
```

### Key Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Generation
    Generation --> Distribution
    Distribution --> Active
    Active --> Rotation_Warning
    Rotation_Warning --> Rotation
    Rotation --> Active
    Active --> Revoked
    Revoked --> [*]
    
    Generation : Key Generation<br/>Secure Random<br/>Algorithm Selection
    Distribution : Secure Distribution<br/>Encrypted Channels<br/>Access Control
    Active : Normal Operation<br/>Authentication<br/>Monitoring
    Rotation_Warning : Pre-rotation Notice<br/>30 days before expiry
    Rotation : Key Rotation<br/>Gradual Migration<br/>Overlap Period
    Revoked : Emergency Revocation<br/>Immediate Termination
```

### Key Storage and Distribution

#### Secure Key Generation
```python
# Example key generation process
import secrets
import base64
import hashlib

def generate_tsig_key(algorithm='hmac-sha256', key_name='generated-key'):
    """
    Generate a cryptographically secure TSIG key
    """
    # Determine key length based on algorithm
    key_lengths = {
        'hmac-sha256': 32,  # 256 bits
        'hmac-sha224': 28,  # 224 bits
        'hmac-sha512': 64,  # 512 bits
        'hmac-md5': 16      # 128 bits (legacy)
    }
    
    key_length = key_lengths.get(algorithm, 32)
    
    # Generate cryptographically secure random key
    key_bytes = secrets.token_bytes(key_length)
    
    # Encode in base64 for BIND configuration
    key_b64 = base64.b64encode(key_bytes).decode('ascii')
    
    return {
        'name': key_name,
        'algorithm': algorithm,
        'secret': key_b64,
        'key_bytes': key_bytes
    }
```

#### Key Configuration Template
```yaml
# TSIG Key Configuration Template
key_configuration:
  master_key:
    name: "master-transfer-key"
    algorithm: "hmac-sha256"
    secret: "{{ MASTER_KEY_SECRET }}"
    purpose: "zone_transfers"
    rotation_days: 365
    
  admin_key:
    name: "admin-management-key"
    algorithm: "hmac-sha256"
    secret: "{{ ADMIN_KEY_SECRET }}"
    purpose: "zone_management"
    rotation_days: 90
    
  service_keys:
    - name: "app1-update-key"
      algorithm: "hmac-sha256"
      secret: "{{ APP1_KEY_SECRET }}"
      purpose: "dynamic_updates"
      rotation_days: 30
      
    - name: "app2-update-key"
      algorithm: "hmac-sha256" 
      secret: "{{ APP2_KEY_SECRET }}"
      purpose: "dynamic_updates"
      rotation_days: 30
```

## 🔒 Security Implementation

### TSIG Message Flow

```mermaid
sequenceDiagram
    participant Client
    participant DNS_Server
    participant TSIG_Module
    participant Key_Store
    
    Note over Client, Key_Store: DNS Update with TSIG
    
    Client->>Client: Prepare DNS Message
    Client->>Client: Calculate TSIG MAC
    Client->>DNS_Server: DNS Message + TSIG
    
    DNS_Server->>TSIG_Module: Validate TSIG
    TSIG_Module->>Key_Store: Lookup Key
    Key_Store-->>TSIG_Module: Return Key
    TSIG_Module->>TSIG_Module: Verify MAC
    TSIG_Module->>TSIG_Module: Check Timestamp
    TSIG_Module-->>DNS_Server: Validation Result
    
    alt Valid TSIG
        DNS_Server->>DNS_Server: Process DNS Request
        DNS_Server->>DNS_Server: Prepare Response
        DNS_Server->>TSIG_Module: Sign Response
        TSIG_Module->>TSIG_Module: Calculate Response MAC
        DNS_Server-->>Client: DNS Response + TSIG
    else Invalid TSIG
        DNS_Server-->>Client: REFUSED (TSIG Error)
    end
```

### MAC Calculation Process

The TSIG MAC is calculated over:
1. **DNS Message**: The entire DNS message being authenticated
2. **Key Name**: The name of the TSIG key
3. **Timestamp**: Current time (prevents replay attacks)
4. **Fudge**: Time window for clock skew tolerance
5. **Algorithm**: The HMAC algorithm identifier

```
MAC = HMAC(key, message + key_name + timestamp + fudge + algorithm)
```

### Time-based Security

```mermaid
graph LR
    subgraph "Time Windows"
        T1[Request Time]
        T2[Server Time]
        T3[Fudge Window]
    end
    
    subgraph "Validation"
        V1[Time Check]
        V2[Replay Check]
        V3[MAC Verification]
    end
    
    T1 --> V1
    T2 --> V1
    T3 --> V1
    V1 --> V2
    V2 --> V3
    
    V1 -.-> ACCEPT[Accept]
    V1 -.-> REJECT[Reject - Time]
    V2 -.-> REJECT2[Reject - Replay]
    V3 -.-> ACCEPT2[Accept - Valid]
    V3 -.-> REJECT3[Reject - Invalid MAC]
```

## 🛡️ Security Controls

### Access Control Matrix

| Operation | Master Key | Admin Key | Service Key | RNDC Key |
|-----------|------------|-----------|-------------|----------|
| Zone Transfer | ✅ | ❌ | ❌ | ❌ |
| Zone Update | ✅ | ✅ | ✅ | ❌ |
| Zone Management | ✅ | ✅ | ❌ | ❌ |
| Server Control | ❌ | ❌ | ❌ | ✅ |
| Query Resolution | ✅ | ✅ | ✅ | ❌ |

### Network Security Integration

```mermaid
graph TB
    subgraph "Network Layer"
        FW[Firewall]
        ACL[Access Control Lists]
        VPN[VPN Gateway]
    end
    
    subgraph "Application Layer"
        TSIG[TSIG Authentication]
        RBAC[Role-Based Access]
        AUDIT[Audit Logging]
    end
    
    subgraph "Data Layer"
        ENCRYPT[Data Encryption]
        INTEGRITY[Integrity Checks]
        BACKUP[Secure Backup]
    end
    
    FW --> TSIG
    ACL --> RBAC
    VPN --> TSIG
    TSIG --> ENCRYPT
    RBAC --> INTEGRITY
    AUDIT --> BACKUP
```

## 🔄 Key Rotation Strategy

### Rotation Schedule

```mermaid
gantt
    title TSIG Key Rotation Schedule
    dateFormat  YYYY-MM-DD
    section Master Keys
    Generate New Key     :mk1, 2024-01-01, 7d
    Distribute New Key   :mk2, after mk1, 7d
    Activate New Key     :mk3, after mk2, 1d
    Deactivate Old Key   :mk4, after mk3, 30d
    
    section Admin Keys
    Generate New Key     :ak1, 2024-03-01, 3d
    Distribute New Key   :ak2, after ak1, 3d
    Activate New Key     :ak3, after ak2, 1d
    Deactivate Old Key   :ak4, after ak3, 7d
    
    section Service Keys
    Generate New Key     :sk1, 2024-01-15, 1d
    Distribute New Key   :sk2, after sk1, 1d
    Activate New Key     :sk3, after sk2, 1d
    Deactivate Old Key   :sk4, after sk3, 1d
```

### Rotation Process

```bash
#!/bin/bash
# TSIG Key Rotation Script

rotate_tsig_key() {
    local key_name="$1"
    local algorithm="$2"
    
    echo "Starting rotation for key: $key_name"
    
    # Step 1: Generate new key
    new_key=$(generate_new_key "$algorithm")
    
    # Step 2: Distribute to all servers
    distribute_key "$key_name" "$new_key"
    
    # Step 3: Update configuration
    update_bind_config "$key_name" "$new_key"
    
    # Step 4: Reload BIND configuration
    reload_bind_config
    
    # Step 5: Wait for propagation
    sleep 300
    
    # Step 6: Verify new key works
    if test_key "$key_name" "$new_key"; then
        echo "New key verified successfully"
        
        # Step 7: Schedule old key removal
        schedule_key_removal "$key_name" "30d"
    else
        echo "New key verification failed, rolling back"
        rollback_key "$key_name"
    fi
}
```

## 📊 Security Monitoring

### TSIG Event Monitoring

```mermaid
graph TB
    subgraph "Event Sources"
        BIND_LOG[BIND Logs]
        SYSTEM_LOG[System Logs]
        APP_LOG[Application Logs]
    end
    
    subgraph "Event Processing"
        PARSER[Log Parser]
        FILTER[Event Filter]
        CORRELATE[Event Correlation]
    end
    
    subgraph "Alert Triggers"
        FAIL_AUTH[Authentication Failures]
        SUSPICIOUS[Suspicious Patterns]
        KEY_EXPIRE[Key Expiration]
    end
    
    subgraph "Response Actions"
        ALERT[Send Alerts]
        BLOCK[Block Source]
        ROTATE[Force Key Rotation]
    end
    
    BIND_LOG --> PARSER
    SYSTEM_LOG --> PARSER
    APP_LOG --> PARSER
    
    PARSER --> FILTER
    FILTER --> CORRELATE
    
    CORRELATE --> FAIL_AUTH
    CORRELATE --> SUSPICIOUS
    CORRELATE --> KEY_EXPIRE
    
    FAIL_AUTH --> ALERT
    SUSPICIOUS --> BLOCK
    KEY_EXPIRE --> ROTATE
```

### Security Metrics

| Metric | Threshold | Action |
|--------|-----------|--------|
| Authentication Failures | > 10/minute | Alert Security Team |
| Invalid TSIG Signatures | > 5/hour | Investigate Source |
| Key Expiration Warning | 30 days | Schedule Rotation |
| Unusual Update Patterns | Statistical Anomaly | Enhanced Monitoring |
| Time Synchronization Drift | > 5 minutes | Check NTP Service |

## 🚨 Security Incident Response

### Incident Classification

```mermaid
graph TD
    INCIDENT[Security Incident] --> CLASSIFY{Classify Severity}
    
    CLASSIFY -->|High| HIGH[High Severity]
    CLASSIFY -->|Medium| MEDIUM[Medium Severity] 
    CLASSIFY -->|Low| LOW[Low Severity]
    
    HIGH --> IMMEDIATE[Immediate Response<br/>- Revoke compromised keys<br/>- Block source IPs<br/>- Enable enhanced logging]
    
    MEDIUM --> URGENT[Urgent Response<br/>- Investigate source<br/>- Review access logs<br/>- Consider key rotation]
    
    LOW --> ROUTINE[Routine Response<br/>- Log incident<br/>- Monitor patterns<br/>- Schedule review]
```

### Emergency Key Revocation

```bash
#!/bin/bash
# Emergency TSIG Key Revocation

emergency_revoke_key() {
    local key_name="$1"
    local reason="$2"
    
    echo "EMERGENCY: Revoking key $key_name - Reason: $reason"
    
    # Immediate actions
    remove_key_from_config "$key_name"
    reload_bind_immediately
    
    # Block all requests using this key
    add_firewall_block_for_key "$key_name"
    
    # Generate incident report
    generate_incident_report "$key_name" "$reason"
    
    # Notify security team
    send_emergency_alert "$key_name" "$reason"
    
    # Start key replacement process
    initiate_emergency_key_replacement "$key_name"
}
```

## 🎯 Best Practices

### Development Environment
- Use separate keys for development and production
- Implement key rotation testing in development
- Regular security audits of key usage
- Automated testing of TSIG configurations

### Production Environment
- Implement defense in depth (network + TSIG + monitoring)
- Regular key rotation according to policy
- Secure key storage with encryption at rest
- Comprehensive audit logging and monitoring

### Operational Security
- Principle of least privilege for key access
- Secure key distribution channels
- Regular security assessments
- Incident response procedures

This TSIG security design provides a robust foundation for securing DNS operations while maintaining operational flexibility and monitoring capabilities.
