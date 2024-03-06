#!/bin/bash

# Ensure the script is executed with two arguments.
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <certificate-file> <key-file>"
    exit 1
fi

CERT_FILE="$1"
KEY_FILE="$2"

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
    echo "OpenSSL could not be found. Please install OpenSSL."
    exit 1
fi

# Function to check certificate expiration
check_cert_expiration() {
    if ! openssl x509 -noout -checkend 0 -in "$CERT_FILE"; then
        echo "The certificate has expired or will expire soon."
        return 1
    else
        echo "The certificate has not expired."
    fi
}

# Function to check file permissions
check_file_permissions() {
    local file="$1"
    local expected_perms="$2"

    local perms
    perms=$(stat -c "%a" "$file")

    if [ "$perms" -ne "$expected_perms" ]; then
        echo "Permissions for $file are not secure. Expected $expected_perms, got $perms."
        return 1
    else
        echo "Permissions for $file are secure."
    fi
}

# Function to check if the certificate and key match
check_cert_key_match() {
    local cert_modulus
    local key_modulus

    cert_modulus=$(openssl x509 -noout -modulus -in "$CERT_FILE" | openssl md5)
    key_modulus=$(openssl rsa -noout -modulus -in "$KEY_FILE" | openssl md5)

    if [ "$cert_modulus" = "$key_modulus" ]; then
        echo "The certificate and key match."
    else
        echo "The certificate and key do not match."
        return 1
    fi
}

# Perform checks
echo "Starting certificate and key file checks..."
check_cert_expiration || exit 1
check_file_permissions "$CERT_FILE" 400 || exit 1
check_file_permissions "$KEY_FILE" 400 || exit 1
check_cert_key_match || exit 1

echo "All checks passed successfully."
