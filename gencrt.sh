#!/bin/bash
DATETIME=$(date "+%Y%m%d-%H%M%S")
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
DOMAIN=$1
SUB=$2
echo ""

if [ -z $DOMAIN ]; then
	echo "Enter Domain that you wish to create a certificate for: "
    echo ""
    read -rp "Domain: " DOMAIN
    echo ""
    if [ -z $DOMAIN ]; then
        echo "Cannot continue - Domain cannot be blank"
        exit 1
    fi
else
    echo "Domain is: $DOMAIN"
fi

if [ ! -d $SCRIPTPATH/$DOMAIN ]; then
    echo "Domain directory not found - please run genca.sh first"
    exit 1
fi


if [ -z $SUB ]; then
	echo "Enter the Service Name / Subdomain that you wish to create a Cert for."
    echo "Do not enter the fqdn as this will be added automatically"
    echo ""
    read -rp "SubDomain: " SUB
    echo ""
    if [ -z $SUB ]; then
        echo "Cannot continue - Subdomain cannot be blank"
        exit 1
    fi
else
    echo "Subdomain is: $SUB"
fi

DOMAIN_CONFIG=$SCRIPTPATH/$DOMAIN/config.json

CA_PATH=$SCRIPTPATH/$DOMAIN/ca
CA_KEY=$CA_PATH/myCA.key
CA_PEM=$CA_PATH/myCA.pem
CA_CNF=$CA_PATH/myCA.cnf

CSR_PATH=$SCRIPTPATH/$DOMAIN/csr
CSR_FILE=$CSR_PATH/$SUB.$DOMAIN.csr

CNF_PATH=$SCRIPTPATH/$DOMAIN/cnf
CNF_FILE=$CNF_PATH/$SUB.$DOMAIN.cnf

LIVE_PATH=$SCRIPTPATH/$DOMAIN/crt/live
LIVE_WORKING=$LIVE_PATH/$SUB.$DOMAIN
KEY_FILE=$LIVE_WORKING/privkey.pem
CRT_FILE=$LIVE_WORKING/cert.pem
CHAIN_FILE=$LIVE_WORKING/chain.pem
FCHAIN_FILE=$LIVE_WORKING/fullchain.pem

ARCH_PATH=$SCRIPTPATH/$DOMAIN/crt/archive
ARCH_WORKING=$ARCH_PATH/$SUB.$DOMAIN.$DATETIME

if [ ! -f $CNF_FILE ]; then
    echo "cnf not found for $SUB.$DOMAIN in $CNF_PATH"
    echo "Please run gencsr.sh to create a new CSR"
    exit 1
fi

echo ""
echo "Cert will be created for $SUB.$DOMAIN"
echo ""

if [ ! -d $LIVE_WORKING ]; then
	echo "Creating new cert directory"
	mkdir $LIVE_WORKING
else
	echo "Certificate already exists - moving to archive"
	mv $LIVE_WORKING $ARCH_WORKING
	echo "Creating new cert directory"
	mkdir $LIVE_WORKING
fi

echo -n "Generating Key... "
openssl genrsa -out $KEY_FILE
echo "done"

echo -n "Generating CSR... "
openssl req -new -key $KEY_FILE -out $CSR_FILE -config $CNF_FILE -extensions v3_req
echo "done"

echo "Generating CRT..."
openssl x509 -req -in $CSR_FILE -CA $CA_PEM -CAkey $CA_KEY -CAcreateserial -out $CRT_FILE -days 365 -sha256 -extfile $CNF_FILE -extensions v3_req
echo "done"

echo -n "Create Chain... "
cp $CA_PEM $CHAIN_FILE
echo "done"

echo -n "Assemble Full Chain... "
cat $CRT_FILE $CA_PEM > $FCHAIN_FILE
echo "done"

echo ""
echo "Finished"

echo ""
echo "  ------------------------------------------------------------------------"
echo "              Certificate PEM: $CRT_FILE"
echo "              Certificate Key: $KEY_FILE"
echo "            Certificate Chain: $CHAIN_FILE"
echo "       Certiticate Full Chain: $FCHAIN_FILE"
echo "  ------------------------------------------------------------------------"
echo ""

exit 0
