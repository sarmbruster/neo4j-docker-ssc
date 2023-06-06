#!/bin/sh

#!/bin/bash

# Generate a private key
openssl genpkey -algorithm RSA -out private.key

# Generate a certificate signing request (CSR)
openssl req -new -key private.key -out certificate.csr

# Generate a self-signed certificate using the CSR and private key
openssl x509 -req -days 365 -in certificate.csr -signkey private.key -out certificate.crt
