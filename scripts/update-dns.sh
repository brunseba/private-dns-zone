#!/bin/bash

# Dynamic DNS Update Script with TSIG Authentication
# This script demonstrates how to perform dynamic DNS updates using nsupdate with TSIG keys

set -e

# Configuration
DNS_SERVER="localhost"
TSIG_KEY_NAME="tsig-key"
TSIG_KEY_SECRET="dGhpc2lzYXNhbXBsZWtleWZvcnRlc3RpbmdwdXJwb3Nlc29ubHlkb25vdHVzZWluZXByb2R1Y3Rpb24="
ZONE="test.local"
TTL=300

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to add a DNS record
add_record() {
    local name="$1"
    local type="$2"
    local value="$3"
    
    print_info "Adding $type record: $name.$ZONE -> $value"
    
    cat > /tmp/nsupdate_add.txt << EOF
server $DNS_SERVER
key $TSIG_KEY_NAME $TSIG_KEY_SECRET
zone $ZONE
update add $name.$ZONE $TTL $type $value
send
EOF
    
    if nsupdate /tmp/nsupdate_add.txt; then
        print_info "Successfully added record"
    else
        print_error "Failed to add record"
        return 1
    fi
    
    rm -f /tmp/nsupdate_add.txt
}

# Function to delete a DNS record
delete_record() {
    local name="$1"
    local type="$2"
    
    print_info "Deleting $type record: $name.$ZONE"
    
    cat > /tmp/nsupdate_del.txt << EOF
server $DNS_SERVER
key $TSIG_KEY_NAME $TSIG_KEY_SECRET
zone $ZONE
update delete $name.$ZONE $type
send
EOF
    
    if nsupdate /tmp/nsupdate_del.txt; then
        print_info "Successfully deleted record"
    else
        print_error "Failed to delete record"
        return 1
    fi
    
    rm -f /tmp/nsupdate_del.txt
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 <action> <name> <type> [value]

Actions:
  add     - Add a DNS record
  delete  - Delete a DNS record
  test    - Run test operations

Examples:
  $0 add myserver A 10.0.0.100
  $0 add myservice CNAME myserver
  $0 delete myserver A
  $0 test

Supported record types: A, AAAA, CNAME, TXT, MX
EOF
}

# Function to run tests
run_tests() {
    print_info "Running DNS update tests..."
    
    # Test A record
    add_record "testserver" "A" "10.0.0.200"
    sleep 2
    
    # Test CNAME record
    add_record "testalias" "CNAME" "testserver"
    sleep 2
    
    # Test TXT record
    add_record "testtext" "TXT" "\"This is a test TXT record\""
    sleep 2
    
    # Verify records
    print_info "Verifying added records..."
    dig @$DNS_SERVER testserver.$ZONE A +short
    dig @$DNS_SERVER testalias.$ZONE CNAME +short
    dig @$DNS_SERVER testtext.$ZONE TXT +short
    
    # Clean up test records
    print_info "Cleaning up test records..."
    delete_record "testserver" "A"
    delete_record "testalias" "CNAME"
    delete_record "testtext" "TXT"
    
    print_info "Test completed successfully!"
}

# Main script logic
case "${1:-}" in
    add)
        if [ $# -ne 4 ]; then
            print_error "Add action requires: name, type, and value"
            usage
            exit 1
        fi
        add_record "$2" "$3" "$4"
        ;;
    delete)
        if [ $# -ne 3 ]; then
            print_error "Delete action requires: name and type"
            usage
            exit 1
        fi
        delete_record "$2" "$3"
        ;;
    test)
        run_tests
        ;;
    *)
        usage
        exit 1
        ;;
esac
