# IPsec with SM2/3/4

Using plugin `openssl` to provide SM2/3/4 algorithm for IKE & ESP

## Environment Require

```
sudo apt-get install build-essential automake autoconf libtool pkg-config gettext gperf flex
 bison perl openssl libssl-dev
```


## Build

``` 
./sm-scrits/build.sh
```
Or

```
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
```

## Cert & Key

### Generate Key && Issue Cert

CA Key & Cert

```
psec pki --gen --type sm2 > caKey.sm2.der

ipsec pki --self --ca --type sm2 --digest sm3 \
        --lifetime 1460 --in caKey.sm2.der \
        --dn "C=CH, O=strongSwan, CN=strongSwan Root CA" \
        > caCert.sm2.der
ipsec pki --print --in caCert.sm2.der
```

Using CA Cert to issue Sun Cert

Replace your host `Sun` ip in `--san YOUR_IP` 

```
ipsec pki --gen --type sm2 > sunKey.sm2.der
ipsec pki --pub --in sunKey.sm2.der --type sm2 > sunPub.sm2.der
ipsec pki --issue --in sunKey.sm2.der \
          --type sm2 --digest sm3 \
          --cacert caCert.sm2.der --cakey caKey.sm2.der \
          --lifetime 730 \
          --dn "C=CH, O=strongSwan, CN=sun.strongswan.org" \
          --san sun.strongswan.org --san 192.168.116.129 \
          --crl http://crl.strongswan.org/strongswan.crl \
          > sunCert.sm2-sm3.der
```

Using CA Cert to issue Moon Cert

Replace your host `Moon` ip in `--san YOUR_IP` 

```
ipsec pki --gen --type sm2 > moonKey.sm2.der
ipsec pki --pub --in moonKey.sm2.der --type sm2 > moonPub.sm2.der
ipsec pki --issue --in moonKey.sm2.der \
          --type sm2 --digest sm3 \
          --cacert caCert.sm2.der --cakey caKey.sm2.der \
          --lifetime 730 \
          --dn "C=CH, O=strongSwan, CN=moon.strongswan.org" \
          --san moon.strongswan.org --san 192.168.116.130 \
          --crl http://crl.strongswan.org/strongswan.crl \
          > moonCert.sm2-sm3.der
```

Using `--debug [level(1/2/3/4)]` to show detailed logs

### Copy Cert & Key

Host Sun

```
sudo cp -r caCert.sm2.der /etc/ipsec.d/cacerts/
sudo cp -r sunCert.sm2-sm3.der /etc/ipsec.d/certs/
sudo cp -r sunKey.sm2.der /etc/ipsec.d/private/
```

Host Moon

```
sudo cp -r caCert.sm2.der /etc/ipsec.d/cacerts/
sudo cp -r moonCert.sm2-sm3.der /etc/ipsec.d/certs/
sudo cp -r moonKey.sm2.der /etc/ipsec.d/private/
```


## Configuration for stroke

`/etc/strongswan.conf`: 

```
charon {

    load_modular = yes
    # accpet sm4
    accept_private_algs = yes

    plugins {
        include strongswan.d/charon/*.conf

        kernel-libipsec {
            load = yes
            allow_peer_ts = yes
        }
        kernel-netlink {
            load = yes
            fwmark = !0x42
        }
        socket-default {
            load = yes
            fwmark = 0x42
        }
    }

    # two defined file loggers
    filelog {
        charon {
            # path to the log file, specify this as section name in versions prior to 5.7.0
            path = /var/log/charon.log
            # add a timestamp prefix
            time_format = %b %e %T
            # prepend connection name, simplifies grepping
            ike_name = yes
            # overwrite existing files
            append = no
            # flush each line to disk
            flush_line = yes
            # increase default loglevel for all daemon subsystems
            default = 2
            # loglevel for special subsystems
            lib = 3
            knl = 3
            enc = 1
        }
        stderr {
            # more detailed loglevel for a specific subsystem, overriding the
            # default loglevel.
            enc = 1
            ike = 2
            knl = 3
        }
    }
}
```

### Host-Host configuration

#### Sun host

`/etc/ipsec.conf`:

```
# ipsec.conf - strongSwan IPsec configuration file

# basic configuration

config setup
	# strictcrlpolicy=yes
	# uniqueids = no

# Add connections here.

conn host-host
    leftcert=sunCert.sm2-sm3.der
    right=192.168.116.130
    rightid="C=CH, O=strongSwan, CN=moon.strongswan.org"

    keyexchange=ikev1
    ike=sm4-sm3-sm2dh
    esp=sm4-sm3
    auto=add
```


`/etc/ipsec.secrets`:

```
: SM2 sunKey.sm2.der
```

#### Moon host

`/etc/ipsec.conf`:

```
# ipsec.conf - strongSwan IPsec configuration file

# basic configuration

config setup
	# strictcrlpolicy=yes
	# uniqueids = no

# Add connections here.

conn host-host
    leftcert=moonCert.sm2-sm3.der
    right=192.168.116.129
    rightid="C=CH, O=strongSwan, CN=sun.strongswan.org"

    keyexchange=ikev1
    ike=sm4-sm3-sm2dh
    esp=sm4-sm3
    auto=add
```


`/etc/ipsec.secrets`:

```
: SM2 moonKey.sm2.der
```