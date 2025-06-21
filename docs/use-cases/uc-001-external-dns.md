# UC-001: External-DNS Integration

## Purpose

External-DNS allows automatic DNS record management in conjunction with Kubernetes clusters. By integrating external-dns with your BIND DNS server setup via Docker Compose, you can automate DNS updates based on Kubernetes resources.

## Setup

### Prerequisites
- A running Kubernetes cluster.
- Docker and Docker Compose configured as per your current setup.
- External-DNS access to your Kubernetes cluster.

### Configuration

1. **External-DNS Deployment:** Create a Deployment for External-DNS in your Kubernetes cluster. Ensure it has the necessary permissions to access Kubernetes resources and your DNS server.

2. **Docker Compose:** Ensure your `docker-compose.yml` uses the appropriate environment variables to configure the BIND DNS server. Environment variables can be managed using the provided `env-manager.sh` script.

3. **Environment Files:** Create or update `.env` and related environment files using templates in your repository.

### Example

Below is an example snippet for your `external-dns` configuration:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
spec:
  # specifications
```

## Security Considerations

- **TSIG Keys:** Generate and manage secure TSIG keys using `env-manager.sh`. Ensure they are not exposed or committed to your repository.
- **Access Control:** Restrict access to the DNS server to authorized services only.

## Usage

- **Automatic Updates:** External-DNS will create/delete DNS records automatically based on Kubernetes Ingresses and Services.
- **Validation and Management:** Use `env-manager.sh` to validate and manage environment files, ensuring consistent deployment.

For further details, refer to the existing scripts and configuration files in your repository.
