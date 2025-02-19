#!/bin/bash

# To execute this script:
# ./generate.sh sub.domain.tld
# where sub.domain.tld is the domain name you wish to generate certificates for.

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

if  [ -f $SCRIPTPATH/config.json ]; then
    echo -n "config.json detected - loading variables..."
    DOMAIN=$(cat $SCRIPTPATH/config.json | jq -r '.domain')
    REQ_CN=$(cat $SCRIPTPATH/config.json | jq -r '.country')
    REQ_ST=$(cat $SCRIPTPATH/config.json | jq -r '.state')
    REQ_L=$(cat $SCRIPTPATH/config.json | jq -r '.locality')
    REQ_O=$(cat $SCRIPTPATH/config.json | jq -r '.organization')
    REQ_OU=$(cat $SCRIPTPATH/config.json | jq -r '.organizational_unit')
    REQ_ROOT_CN=$(cat $SCRIPTPATH/config.json | jq -r '.common_name')
    echo " done."
else
    # Load defaults
    DEFAULT_REQ_CN=$(cat $SCRIPTPATH/default.json | jq -r '.country')
    DEFAULT_REQ_ST=$(cat $SCRIPTPATH/default.json | jq -r '.state')
    DEFAULT_REQ_L=$(cat $SCRIPTPATH/default.json | jq -r '.locality')
    DEFAULT_REQ_O=$(cat $SCRIPTPATH/default.json | jq -r '.organization')
    DEFAULT_REQ_OU=$(cat $SCRIPTPATH/default.json | jq -r '.organizational_unit')
    DEFAULT_REQ_ROOT_CN=$(cat $SCRIPTPATH/default.json | jq -r '.common_name')

    if [ -z $1 ]; then
        echo -n "Enter Domain Name: "
        read DOMAIN
    else
        DOMAIN=$1
        echo "Domain is: $DOMAIN"
    fi
    if [ -z $DOMAIN ]; then
        echo "Cannot continue - Domain cannot be blank"
        exit 1
    fi

    echo -n "Enter Country Code [$DEFAULT_REQ_CN]: "
    read REQ_CN
    if [ -z $REQ_CN ]; then
        REQ_CN=$DEFAULT_REQ_CN
    fi

    echo -n "Enter State [$DEFAULT_REQ_ST]: "
    read REQ_ST
    if [ -z $REQ_ST ]; then
        REQ_ST=$DEFAULT_REQ_ST
    fi

    echo -n "Enter Locality [$DEFAULT_REQ_L]: "
    read REQ_L
    if [ -z $REQ_L ]; then
        REQ_L=$DEFAULT_REQ_L
    fi

    echo -n "Enter Organization [$DEFAULT_REQ_O]: "
    read REQ_O
    if [ -z $REQ_O ]; then
        REQ_O=$DEFAULT_REQ_O
    fi

    echo -n "Enter Organization Unit [$DEFAULT_REQ_OU]: "
    read REQ_OU
    if [ -z $REQ_OU ]; then
        REQ_OU=$DEFAULT_REQ_OU
    fi

    echo -n "Enter Common Name [$DEFAULT_REQ_ROOT_CN] "
    read REQ_ROOT_CN
    if [ -z $REQ_ROOT_CN ]; then
        REQ_ROOT_CN=$DEFAULT_REQ_ROOT_CN
    fi

    echo -n "Storing new configuration... "
    cat <<EOF > $SCRIPTPATH/config.json
{
    "domain": "$DOMAIN",
    "country": "$REQ_CN",
    "state": "$REQ_ST",
    "locality": "$REQ_L",
    "organization": "$REQ_O",
    "organizational_unit": "$REQ_OU",
    "common_name": "$REQ_ROOT_CN"
}
EOF
    echo "done."
fi

DOMAIN_CONFIG=$SCRIPTPATH/$DOMAIN/config.json
CA_PATH=$SCRIPTPATH/$DOMAIN/ca
CA_KEY=$CA_PATH/myCA.key
CA_PEM=$CA_PATH/myCA.pem
CA_CNF=$CA_PATH/myCA.cnf

CSR_PATH=$SCRIPTPATH/$DOMAIN/csr

CNF_PATH=$SCRIPTPATH/$DOMAIN/cnf

LIVE_PATH=$SCRIPTPATH/$DOMAIN/crt/live

ARCH_PATH=$SCRIPTPATH/$DOMAIN/crt/archive


# Create directory structure for the new domain
mkdir $DOMAIN
mkdir -p $CA_PATH
mkdir -p $CNF_PATH
mkdir -p $CSR_PATH
mkdir -p $LIVE_PATH
mkdir -p $ARCH_PATH
mv $SCRIPTPATH/config.json $DOMAIN_CONFIG

cat <<EOF > $CA_CNF
[ req ]
default_bits            = 4096
prompt                  = no
default_md              = sha256
distinguished_name      = req_distinguished_name
x509_extensions         = v3_ca

[ req_distinguished_name ]
countryName             = $REQ_CN
stateOrProvinceName     = $REQ_ST
localityName            = $REQ_L
organizationName        = $REQ_O
organizationalUnitName  = $REQ_OU
commonName              = $REQ_ROOT_CN

[ v3_ca ]
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always,issuer
basicConstraints        = critical,CA:true
keyUsage                = critical,keyCertSign,cRLSign
EOF


# Build your domain RSA key - you will be prompted for a password to protect the key.
echo "Building CA Key"
openssl genpkey -algorithm RSA -aes256 -out $CA_KEY -pkeyopt rsa_keygen_bits:4096

# Build your domain certificate. You will be prompted for the key password that you just entered.
echo "Building CA Certificate"
openssl req -x509 -new -key $CA_KEY -sha256 -days 3650 -out $CA_PEM -extensions v3_ca -reqexts v3_ca -config $CA_CNF

echo ""
echo "Finished"

echo ""
echo "  ------------------------------------------------------------------------"
echo "                 Domain Configuration: $DOMAIN_CONFIG"
echo "            Certificate Authority PEM: $CA_PEM"
echo "            Certificate Authority Key: $CA_KEY"
echo "  Certificate Authority Configuration: $CA_CNF"
echo "  ------------------------------------------------------------------------"
echo ""

exit 0