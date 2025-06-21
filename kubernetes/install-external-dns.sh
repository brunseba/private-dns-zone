#!/bin/bash

# External-DNS Installation Script for BIND DNS Server
# This script deploys external-dns in Kubernetes to connect to BIND DNS running via Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}==== $1 ====${NC}"
}

# Configuration
NAMESPACE="external-dns"
HELM_RELEASE_NAME="external-dns"
HELM_CHART_REPO="https://kubernetes-sigs.github.io/external-dns/"
HELM_CHART_NAME="external-dns/external-dns"

# BIND DNS server configuration (adjust these for your setup)
BIND_HOST="${BIND_HOST:-host.docker.internal}"  # Default for Docker Desktop
BIND_PORT="${BIND_PORT:-53}"
BIND_ZONE="${BIND_ZONE:-k8s.local}"
TSIG_KEY_NAME="${TSIG_KEY_NAME:-tsig-key}"

# Get TSIG key from .env file or environment
if [[ -f "../.env" ]]; then
    source ../.env
    TSIG_KEY_SECRET="${TSIG_KEY_SECRET}"
else
    print_warning ".env file not found. Using environment variable TSIG_KEY_SECRET"
    if [[ -z "$TSIG_KEY_SECRET" ]]; then
        print_error "TSIG_KEY_SECRET not found in environment or .env file"
        exit 1
    fi
fi

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we can connect to Kubernetes cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_info "All prerequisites met"
}

# Function to add Helm repository
add_helm_repo() {
    print_header "Adding External-DNS Helm Repository"
    
    helm repo add external-dns ${HELM_CHART_REPO}
    helm repo update
    
    print_info "Helm repository added and updated"
}

# Function to create namespace
create_namespace() {
    print_header "Creating Namespace"
    
    kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    print_info "Namespace ${NAMESPACE} created/updated"
}

# Function to create TSIG secret
create_tsig_secret() {
    print_header "Creating TSIG Secret"
    
    # Encode the TSIG key
    TSIG_KEY_B64=$(echo -n "${TSIG_KEY_SECRET}" | base64)
    
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: external-dns-tsig-secret
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: external-dns
    app.kubernetes.io/component: tsig-config
type: Opaque
data:
  tsig-secret: ${TSIG_KEY_B64}
EOF
    
    print_info "TSIG secret created"
}

# Function to install external-dns
install_external_dns() {
    print_header "Installing External-DNS with Helm"
    
    # Create temporary values file with current configuration
    cat > /tmp/external-dns-values.yaml <<EOF
# Helm values for external-dns with BIND DNS (RFC2136) provider
provider: rfc2136

# RFC2136 (BIND DNS) specific configuration
rfc2136:
  host: "${BIND_HOST}"
  port: ${BIND_PORT}
  zone: "${BIND_ZONE}"
  tsigKeyname: "${TSIG_KEY_NAME}"
  tsigSecret: ""  # Will be set via secret
  tsigSecretAlg: "hmac-sha256"
  tsigAxfr: true

# Domain filtering
domainFilters:
  - "${BIND_ZONE}"
  - "*.${BIND_ZONE}"

# Source configuration
sources:
  - service
  - ingress

# Registry configuration
registry: "txt"
txtOwnerId: "external-dns-k8s"
txtPrefix: "external-dns-"

# Policy configuration
policy: "sync"

# Logging configuration
logLevel: "info"
logFormat: "text"

# Synchronization settings
interval: "1m"

# Metrics and monitoring
metrics:
  enabled: true
  port: 7979

serviceMonitor:
  enabled: false  # Set to true if you have Prometheus Operator

# Security context
securityContext:
  fsGroup: 65534
  runAsNonRoot: true
  runAsUser: 65534

containerSecurityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 65534
  capabilities:
    drop:
      - ALL

# Resource configuration
resources:
  limits:
    cpu: 250m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

# Environment variables
env:
  - name: EXTERNAL_DNS_RFC2136_TSIG_SECRET
    valueFrom:
      secretKeyRef:
        name: external-dns-tsig-secret
        key: tsig-secret

# Extra arguments
extraArgs:
  - --events
  - --log-level=debug  # Remove in production

# RBAC
rbac:
  create: true

# Service account
serviceAccount:
  create: true
  name: "external-dns"
EOF
    
    # Install or upgrade external-dns
    helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_NAME} \
        --namespace ${NAMESPACE} \
        --values /tmp/external-dns-values.yaml \
        --wait \
        --timeout 300s
    
    # Clean up temporary file
    rm -f /tmp/external-dns-values.yaml
    
    print_info "External-DNS installed successfully"
}

# Function to verify installation
verify_installation() {
    print_header "Verifying Installation"
    
    # Check if pod is running
    print_info "Checking pod status..."
    kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=external-dns
    
    # Check logs
    print_info "Checking logs (last 10 lines)..."
    kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/name=external-dns --tail=10
    
    # Check if external-dns is ready
    kubectl wait --for=condition=available --timeout=300s deployment/${HELM_RELEASE_NAME} -n ${NAMESPACE}
    
    print_info "External-DNS is running and ready"
}

# Function to show connection info
show_connection_info() {
    print_header "Connection Information"
    
    echo "External-DNS Configuration:"
    echo "  BIND Host: ${BIND_HOST}"
    echo "  BIND Port: ${BIND_PORT}"
    echo "  BIND Zone: ${BIND_ZONE}"
    echo "  TSIG Key Name: ${TSIG_KEY_NAME}"
    echo "  Namespace: ${NAMESPACE}"
    echo ""
    echo "To check status:"
    echo "  kubectl get pods -n ${NAMESPACE}"
    echo "  kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/name=external-dns -f"
    echo ""
    echo "To test with a service:"
    echo "  kubectl annotate service my-service external-dns.alpha.kubernetes.io/hostname=my-service.${BIND_ZONE}"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
  install     Install external-dns (default)
  uninstall   Uninstall external-dns
  upgrade     Upgrade external-dns
  status      Show external-dns status
  logs        Show external-dns logs

Environment Variables:
  BIND_HOST         BIND DNS server host (default: host.docker.internal)
  BIND_PORT         BIND DNS server port (default: 53)
  BIND_ZONE         DNS zone to manage (default: k8s.local)
  TSIG_KEY_NAME     TSIG key name (default: tsig-key)
  TSIG_KEY_SECRET   TSIG key secret (required, from .env file)

Examples:
  $0 install
  BIND_HOST=192.168.1.100 $0 install
  $0 status
  $0 logs
  $0 uninstall
EOF
}

# Function to uninstall external-dns
uninstall_external_dns() {
    print_header "Uninstalling External-DNS"
    
    helm uninstall ${HELM_RELEASE_NAME} -n ${NAMESPACE}
    kubectl delete secret external-dns-tsig-secret -n ${NAMESPACE} --ignore-not-found
    kubectl delete namespace ${NAMESPACE} --ignore-not-found
    
    print_info "External-DNS uninstalled"
}

# Function to show status
show_status() {
    print_header "External-DNS Status"
    
    echo "Helm Release:"
    helm status ${HELM_RELEASE_NAME} -n ${NAMESPACE}
    echo ""
    
    echo "Pods:"
    kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=external-dns
    echo ""
    
    echo "Services:"
    kubectl get svc -n ${NAMESPACE}
}

# Function to show logs
show_logs() {
    print_info "Showing External-DNS logs (press Ctrl+C to exit)..."
    kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/name=external-dns -f
}

# Main execution
main() {
    case "${1:-install}" in
        "install")
            check_prerequisites
            add_helm_repo
            create_namespace
            create_tsig_secret
            install_external_dns
            verify_installation
            show_connection_info
            ;;
        "uninstall")
            uninstall_external_dns
            ;;
        "upgrade")
            check_prerequisites
            add_helm_repo
            install_external_dns
            verify_installation
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
