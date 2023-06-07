#!/bin/sh

#!/bin/bash

KEY_FILE=${PWD}/private.key
CERT_FILE=${PWD}/certificate.crt

JVM_KEY_STORE=${PWD}/trustStore.jks

if [ ! -f "${KEY_FILE}" ]; then
    # Generate a private key
    openssl genpkey -algorithm RSA -out $KEY_FILE
fi

if [ ! -f "${CERT_FILE}" ]; then
    # Generate a certificate signing request (CSR)
    # TODO: replace CN=localhost with CN=www.mydomain.com
    openssl req -new -key $KEY_FILE -subj "/C=DE/L=Munich/O=Company/CN=localhost" -out certificate.csr

    # Generate a self-signed certificate using the CSR and private key
    openssl x509 -req -days 365 -in certificate.csr -signkey $KEY_FILE -out $CERT_FILE
fi

# populate a JVM keystore file with certificate for external service
if [ ! -f "$JVM_KEY_STORE" ]; then
    openssl req -new -key $KEY_FILE -subj "/C=DE/L=Munich/O=Company/CN=host.docker.internal" -out ext.csr
    openssl x509 -req -days 365 -in ext.csr -signkey $KEY_FILE -out ext.crt
    keytool -import -alias host.docker.internal -file ext.crt -storetype JKS -storepass changeme -noprompt -keystore $JVM_KEY_STORE
fi

# launch a python https webserver to simulate external service
#python externalService.py &

docker run --rm \
--name neo4j44 \
-e NEO4J_AUTH=neo4j/123 \
-e NEO4J_ACCEPT_LICENSE_AGREEMENT=yes \
-e NEO4J_dbms_connector_https_enabled=true \
-e NEO4J_dbms_connector_http_enabled=false \
-e NEO4J_dbms_connector_bolt_tls__level="REQUIRED" \
-e NEO4J_dbms_ssl_policy_https_enabled="true" \
-e NEO4J_dbms_ssl_policy_https_base__directory="certificates" \
-e NEO4J_dbms_ssl_policy_bolt_enabled="true" \
-e NEO4J_dbms_ssl_policy_bolt_base__directory="certificates" \
-e NEO4JLABS_PLUGINS='["apoc"]' \
-e NEO4J_dbms_jvm_additional="-Djavax.net.ssl.trustStore=/var/lib/neo4j/trustStore.jks -Djavax.net.ssl.trustStorePassword=changeme " \
-p 7474:7474 \
-p 7473:7473 \
-p 7687:7687 \
-v $CERT_FILE:/var/lib/neo4j/certificates/public.crt \
-v $KEY_FILE:/var/lib/neo4j/certificates/private.key \
-v $JVM_KEY_STORE:/var/lib/neo4j/trustStore.jks \
--user=$(id -u):$(id -g) \
--add-host=host.docker.internal:host-gateway \
neo4j:4.4.8-enterprise

# to connect via cypher-shell use
# -Djavax.net.ssl.keyStore=/var/lib/neo4j/trustStore.jks -Djavax.net.ssl.keyStorePassword=changeme
# cypher-shell -a "neo4j+ssc://localhost:7687" 

# for apoc:
#-e NEO4JLABS_PLUGINS='["apoc"]' 
