#!/bin/bash

./autogen.sh

./configure --prefix=/usr/local --sysconfdir=/etc \
    --enable-kernel-libipsec --enable-openssl \
    --disable-aes --disable-des --disable-curve25519  \
    --disable-md5 --disable-sha1 --disable-sha2  \
    --disable-hmac \
    --disable-gmp --disable-drbg \
    --disable-constraints  \
    --disable-pkcs1 --disable-pkcs12

make -j 

sudo make install

# must x509 pem 

# aes des rc2 sha2 sha1 md5 mgf1 random nonce x509 revocation constraints pubkey pkcs1 pkcs7 pkcs8 pkcs12 pgp dnskey sshkey pem openssl fips-prf gmp curve25519 xcbc cmac hmac drbg