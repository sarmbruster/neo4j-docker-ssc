#!/usr/bin/env python3
import http.server
import ssl

# Set up the server address and port
address = ('', 8080)

# Generate a self-signed certificate
certfile = 'ext.crt'
keyfile = 'private.key'

# Create an HTTP request handler
handler = http.server.SimpleHTTPRequestHandler

# Create an SSL context
context = ssl.SSLContext(ssl.PROTOCOL_TLS)
context.load_cert_chain(certfile, keyfile)

# Start the web server
httpd = http.server.HTTPServer(address, handler)
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

print("Starting the server on https://localhost:8080...")
httpd.serve_forever()
