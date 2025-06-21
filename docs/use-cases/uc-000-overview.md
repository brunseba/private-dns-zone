# UC-000: Use Cases Overview

This section provides a comprehensive overview of the different ways to integrate with your BIND DNS server setup. Each use case addresses specific needs and deployment scenarios.

## Integration Context Diagram

```mermaid
graph TB
    subgraph "BIND DNS Server Environment"
        DNS[BIND DNS Server<br/>Docker Compose]
        TSIG[TSIG Keys<br/>env-manager.sh]
        ENV[Environment Files<br/>.env, .env.prod, .env.dev]
        DNS --> TSIG
        TSIG --> ENV
    end

    subgraph "Kubernetes Ecosystem"
        K8S[Kubernetes Cluster]
        ING[Ingress Controllers]
        SVC[Services]
        EXT[External-DNS]
        
        K8S --> ING
        K8S --> SVC
        ING --> EXT
        SVC --> EXT
    end

    subgraph "DNS Management Tools"
        DNSCTL[DNSControl<br/>JavaScript DSL]
        OCTODNS[octoDNS<br/>Python YAML]
        
        subgraph "Configuration Files"
            DNSCONFIG[dnsconfig.js]
            OCTOYAML[config.yaml<br/>zone.yaml]
        end
        
        DNSCTL --> DNSCONFIG
        OCTODNS --> OCTOYAML
    end

    subgraph "CI/CD & Automation"
        GHA[GitHub Actions]
        GITLAB[GitLab CI]
        JENKINS[Jenkins]
        
        GHA --> DNSCTL
        GHA --> OCTODNS
        GITLAB --> DNSCTL
        GITLAB --> OCTODNS
        JENKINS --> DNSCTL
        JENKINS --> OCTODNS
    end

    %% Connections to DNS Server
    EXT -.->|TSIG Auth<br/>Dynamic Updates| DNS
    DNSCTL -.->|TSIG Auth<br/>Zone Updates| DNS
    OCTODNS -.->|TSIG Auth<br/>Record Sync| DNS

    %% Security layer
    TSIG -.->|Secure Keys| EXT
    TSIG -.->|Secure Keys| DNSCTL
    TSIG -.->|Secure Keys| OCTODNS

    classDef dnsServer fill:#263238,stroke:#37474f,stroke-width:2px,color:#ffffff
    classDef k8s fill:#1a237e,stroke:#283593,stroke-width:2px,color:#ffffff
    classDef tools fill:#bf360c,stroke:#d84315,stroke-width:2px,color:#ffffff
    classDef cicd fill:#1b5e20,stroke:#2e7d32,stroke-width:2px,color:#ffffff
    classDef security fill:#b71c1c,stroke:#c62828,stroke-width:2px,color:#ffffff

    class DNS,TSIG,ENV dnsServer
    class K8S,ING,SVC,EXT k8s
    class DNSCTL,OCTODNS,DNSCONFIG,OCTOYAML tools
    class GHA,GITLAB,JENKINS cicd
```

## Use Case Comparison

| Feature | External-DNS | DNSControl | octoDNS |
|---------|-------------|------------|---------|
| **Primary Use Case** | Kubernetes DNS automation | Declarative DNS management | Multi-provider DNS sync |
| **Configuration Language** | Kubernetes annotations | JavaScript DSL | YAML |
| **Automation Level** | Fully automatic | Semi-automatic | Semi-automatic |
| **Multi-Provider Support** | Yes (limited) | Yes (extensive) | Yes (extensive) |
| **Kubernetes Integration** | Native | Manual | Manual |
| **Validation** | Basic | Advanced | Advanced |
| **Rollback Support** | Limited | Yes | Yes |
| **Learning Curve** | Low | Medium | Medium |
| **Best For** | K8s-native workflows | Infrastructure as Code | Multi-cloud DNS |

## Integration Scenarios

### 1. External-DNS Integration
**When to use:** Kubernetes-native environments where DNS records should automatically reflect service and ingress changes.

```mermaid
sequenceDiagram
    participant K8s as Kubernetes
    participant ExtDNS as External-DNS
    participant BIND as BIND Server
    
    K8s->>ExtDNS: Service/Ingress created
    ExtDNS->>ExtDNS: Generate DNS records
    ExtDNS->>BIND: TSIG authenticated update
    BIND->>BIND: Update zone records
    Note over K8s,BIND: Automatic DNS management
```

### 2. DNSControl Integration
**When to use:** Infrastructure as Code approach with version-controlled DNS configurations and team collaboration.

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as Git Repository
    participant CI as CI/CD Pipeline
    participant BIND as BIND Server
    
    Dev->>Git: Push dnsconfig.js changes
    Git->>CI: Trigger pipeline
    CI->>CI: dnscontrol check
    CI->>CI: dnscontrol preview
    CI->>BIND: dnscontrol push (TSIG auth)
    BIND->>BIND: Apply DNS changes
    Note over Dev,BIND: Controlled DNS deployment
```

### 3. octoDNS Integration
**When to use:** Multi-provider environments requiring DNS synchronization and advanced validation capabilities.

```mermaid
sequenceDiagram
    participant Admin as DNS Admin
    participant octoDNS as octoDNS
    participant BIND as BIND Server
    participant Cloud as Cloud Provider
    
    Admin->>octoDNS: octodns-sync --plan
    octoDNS->>BIND: Query current state
    octoDNS->>Cloud: Query current state
    octoDNS->>Admin: Show diff/plan
    Admin->>octoDNS: octodns-sync
    octoDNS->>BIND: Apply changes (TSIG auth)
    octoDNS->>Cloud: Apply changes (API auth)
    Note over Admin,Cloud: Multi-provider sync
```

## Security Architecture

All integrations leverage the same security foundation:

```mermaid
graph LR
    subgraph "Security Layer"
        ENVMGR[env-manager.sh]
        TSIGKEY[TSIG Keys]
        ENVFILE[Environment Files]
        
        ENVMGR --> TSIGKEY
        TSIGKEY --> ENVFILE
    end
    
    subgraph "DNS Clients"
        EXT[External-DNS]
        DNSCTL[DNSControl]
        OCTODNS[octoDNS]
    end
    
    subgraph "BIND Server"
        BIND[BIND DNS]
        ZONES[DNS Zones]
        
        BIND --> ZONES
    end
    
    TSIGKEY -.->|Secure Auth| EXT
    TSIGKEY -.->|Secure Auth| DNSCTL
    TSIGKEY -.->|Secure Auth| OCTODNS
    
    EXT -.->|Authenticated Updates| BIND
    DNSCTL -.->|Authenticated Updates| BIND
    OCTODNS -.->|Authenticated Updates| BIND
    
    classDef security fill:#b71c1c,stroke:#c62828,stroke-width:2px,color:#ffffff
    classDef client fill:#bf360c,stroke:#d84315,stroke-width:2px,color:#ffffff
    classDef server fill:#263238,stroke:#37474f,stroke-width:2px,color:#ffffff
    
    class ENVMGR,TSIGKEY,ENVFILE security
    class EXT,DNSCTL,OCTODNS client
    class BIND,ZONES server
```

## Choosing the Right Integration

### For Kubernetes Environments
- **Start with External-DNS** if you want automatic DNS management
- **Add DNSControl or octoDNS** for manual DNS records and infrastructure

### For Traditional Infrastructure
- **Use DNSControl** for JavaScript-familiar teams and simple setups
- **Use octoDNS** for complex multi-provider environments

### For Hybrid Environments
- **Combine External-DNS + DNSControl/octoDNS** for comprehensive DNS management
- Use External-DNS for dynamic K8s resources
- Use DNSControl/octoDNS for static infrastructure records

## Getting Started

1. **Set up your BIND DNS server** using the provided Docker Compose setup
2. **Generate TSIG keys** using `env-manager.sh generate-keys`
3. **Choose your integration approach** based on your requirements
4. **Follow the specific integration guide** for detailed setup instructions

## Next Steps

- [UC-001: External-DNS Integration](uc-001-external-dns.md) - Kubernetes-native DNS automation
- [UC-002: DNSControl Integration](uc-002-dnscontrol.md) - JavaScript-based DNS management
- [UC-003: octoDNS Integration](uc-003-octodns.md) - Python-based multi-provider DNS sync

Each integration guide provides detailed setup instructions, configuration examples, and best practices for secure DNS management.
