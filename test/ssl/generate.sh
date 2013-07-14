#! /usr/bin/env sh

openssl genrsa -out server.orig.key 2048
openssl rsa -in server.orig.key -out server.key
openssl req -new -key server.key -out server.csr
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

openssl genrsa -out client.orig.key 2048
openssl rsa -in client.orig.key -out client.key
openssl req -new -key client.key -out client.csr
openssl x509 -req -days 365 -in client.csr -signkey client.key -out client.crt

