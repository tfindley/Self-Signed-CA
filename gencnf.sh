#!/bin/bash

# To execute this script:
# ./generate.sh sub.domain.tld
# where sub.domain.tld is the domain name you wish to generate certificates for.

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
	echo "Enter the Service Name / Subdomain that you wish to create a CSR for."
    echo "Do not enter the fqdn as this will be added automatically"
    echo "e.g. to create service.something.$DOMAIN - enter 'service.something'"
    echo ""
    read -rp "Subdomain: " SUB
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


if [ -f $CNF_FILE ]; then
    echo "cnf already exists for $SUB.$DOMAIN in $CNF_PATH"
    echo "Please delete this file and try again"
    echo "Or run gencsr to use this cnf to generate a certificate"
    exit 1
fi

echo ""
echo "CSR will be created for $SUB.$DOMAIN"
echo ""

# Initialize DNS list, then increment automatically by 1 after adding the CN
dns_counter=1
dns_list=()
dns_list+=("$SUB.$DOMAIN")
((dns_counter++))

# Initialize IP list starting at 1
ip_counter=1
ip_list=()

if  [ -f $DOMAIN_CONFIG ]; then
    DOMAIN=$(cat $DOMAIN_CONFIG | jq -r '.domain')
    REQ_CN=$(cat $DOMAIN_CONFIG | jq -r '.country')
    REQ_ST=$(cat $DOMAIN_CONFIG | jq -r '.state')
    REQ_L=$(cat $DOMAIN_CONFIG | jq -r '.locality')
    REQ_O=$(cat $DOMAIN_CONFIG | jq -r '.organization')
    REQ_OU=$(cat $DOMAIN_CONFIG | jq -r '.organizational_unit')
else
    echo "Configuration file not found at $DOMAIN_CONFIG"
    echo "Cannot continue"
    exit 1
fi

echo " Would you like localhost/127.0.0.1 to be added to the certificate?"
read -rp "  (yes/no) [yes]: " add_localhost
if [ -z $add_localhost ]; then
    add_localhost=yes
fi
if [[ "$add_localhost" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    dns_list+=("localhost")
    ((dns_counter++))
    ip_list+=("127.0.0.1")
    ((ip_counter++))
fi
echo ""

echo " Optional:"
echo " Enter alternate DNS names (Subject Alternate Names)"
echo " These must be Fully Qualified Domain Names (FQDN)"
echo "   e.g:"
echo "        something.$DOMAIN"
echo "    or:"
echo "        something.somewhere.$DOMAIN"
echo ""
echo " You do not need to enter $SUB.$DOMAIN again"
echo " (press enter after each, leave empty to finish):"
echo ""

for i in "${!dns_list[@]}"; do
    echo "DNS.$((i+1)) = ${dns_list[i]}"
done
while true; do
    read -rp "DNS.$dns_counter = " dns
    [[ -z "$dns" ]] && break
    dns_list+=("$dns")
    ((dns_counter++))
done
echo ""

echo " Recommended:"
echo " Enter IP address for each server or adapter"
echo " (press enter after each, leave empty to finish):"
echo ""

for i in "${!ip_list[@]}"; do
    echo "IP.$((i+1)) = ${ip_list[i]}"
done
while true; do
    read -rp "IP.$ip_counter = " ip
    [[ -z "$ip" ]] && break
    ip_list+=("$ip")
    ((ip_counter++))
done
echo ""

# Generate a sample subdomain configuration
cat > "$CNF_FILE" << EOF
[ req ]
default_bits            = 4096
prompt                  = no
default_md              = sha256
distinguished_name      = req_distinguished_name
req_extensions          = v3_req

[ req_distinguished_name ]
countryName             = $REQ_CN
stateOrProvinceName     = $REQ_ST
localityName            = $REQ_L
organizationName        = $REQ_O
organizationalUnitName  = $REQ_OU
commonName              = $SUB.$DOMAIN

[ v3_req ]
subjectAltName          = @alt_names
extendedKeyUsage        = serverAuth
basicConstraints        = CA:FALSE
keyUsage                = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment

[ alt_names ]
EOF

for i in "${!dns_list[@]}"; do
    echo "DNS.$((i+1)) = ${dns_list[i]}" >> "$CNF_FILE"
done

for i in "${!ip_list[@]}"; do
    echo "IP.$((i+1)) = ${ip_list[i]}" >> "$CNF_FILE"
done

echo "Finished"

echo ""
echo "  ------------------------------------------------------------------------"
echo "    Certificate generated for: $SUB.$DOMAIN"
echo "            Alternative Names:"
for i in "${!dns_list[@]}"; do
    echo "                               DNS.$((i+1)) = ${dns_list[i]}"
done
for i in "${!ip_list[@]}"; do
    echo "                                IP.$((i+1)) = ${ip_list[i]}"
done
echo "  ------------------------------------------------------------------------"
echo "         Domain Configuration: $DOMAIN_CONFIG"
echo "    Certificate Configuration: $CNF_FILE"
echo "  ------------------------------------------------------------------------"
echo ""

exit 0