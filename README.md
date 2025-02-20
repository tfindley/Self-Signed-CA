# Self Signed CA

## TLDR

Run the scripts in this order:

- genca.sh
- gencnf.sh
- gencrt.sh

For a faster run:

- genca.sh
- gencnf.sh
- gencrt.sh

## How to use

First, create a new working directory in which you can store all your Certs. For the example we will just use 'ssl'. Do not have any spaces in the paths otherwise the bootstrap script will break.

```bash
mkdir ssl
```

cd into that directory and create a new file called 'generate.sh'

```bash
cd ssl
```

Clone the following repository:

{{< github repo="tfindley/Self-Signed-CA" >}}

```bash
git clone https://github.com/tfindley/Self-Signed-CA.git
```

You should now see the following files inside your SSL Directry:

```plaintext
ssl
├── config.json.sample
├── default.json
├── genca.sh
├── gencnf.sh
├── gencrt.sh
├── README.md
```

At this point it is a good idea to review the three .sh files for their content. Never just run a script that you've downloaded from the internet. Whatever you do, do not run this with root privilages!

Ensure the three .sh files are all executable

```bash
chmod +x *.sh
```

Now you can go ahead and create your Certificate Authority

You can quickly boostrap this process by creating a `config.json` file based on the `config.json.sample` file I provided.

```json
{
    "domain": "my.awesome.domain.tld",
    "country": "GB",
    "state": "Farnborough",
    "locality": "Hampshire",
    "organization": "My Awesome Company",
    "organizational_unit": "IT Wizards",
    "common_name": "My Awesome CA"
}
```

Once you've edited the above fields, run the genca.sh script to generate your certificate authority

```bash
./genca.sh
```

Choose a passphrase and enter it to secure your key when prompted (twice). Then when prompted enter the passphrase again to use that key to generate your certificate.

```plaintext
./genca.sh
config.json detected - loading variables... done.
Building CA Key
+........+.......+...+..+.+......+.....+......+.......+...+........+.+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
Building CA Certificate
Enter pass phrase for /path/to/ssl/my.awesome.domain.tld/ca/myCA.key:

Finished

  ------------------------------------------------------------------------
                 Domain Configuration: /path/to/ssl/my.awesome.domain.tld/config.json
            Certificate Authority PEM: /path/to/ssl/my.awesome.domain.tld/ca/myCA.pem
            Certificate Authority Key: /path/to/ssl/my.awesome.domain.tld/ca/myCA.key
  Certificate Authority Configuration: /path/to/ssl/my.awesome.domain.tld/ca/myCA.cnf
  ------------------------------------------------------------------------
```

You now have a working Certificate Authority.

Inside your ssl directory you should now see a directory with the name of the domain you entered (in this example, `my.awesome.domain.tld`). You should have the following directory structure:

```plaintext
ssl
├── config.json.sample
├── default.json
├── genca.sh
├── gencnf.sh
├── gencrt.sh
└── my.awesome.domain.tld
   ├── ca
   │   ├── myCA.cnf
   │   ├── myCA.key
   │   └── myCA.pem
   ├── cnf
   ├── config.json
   ├── crt
   │   ├── archive
   │   └── live
   └── csr
```

### Generate CSR

Now you can generate your first Certificate Signing Request.

Run the `gencsr.sh` script and it will guide you through the process

```bash
./gencnf.sh
```

You can optionally pass the domain name, or the domain name and subdomain to it to speed up the process

```bash
./gencnf.sh my.awesome.domain.tld
```

or

```bash
./gencnf.sh my.awesome.domain.tld service
```

```plaintext
./gencnf.sh my.awesome.domain.tld service

Domain is: my.awesome.domain.tld
Subdomain is: service

CSR will be created for service.my.awesome.domain.tld

 Would you like localhost/127.0.0.1 to be added to the certificate?
  (yes/no) [yes]:

 Optional:
 Enter alternate DNS names (Subject Alternate Names)
 These must be Fully Qualified Domain Names (FQDN)
   e.g:
        something.my.awesome.domain.tld
    or:
        something.somewhere.my.awesome.domain.tld

 You do not need to enter service.my.awesome.domain.tld again
 (press enter after each, leave empty to finish):

DNS.1 = service.my.awesome.domain.tld
DNS.2 = localhost
DNS.3 =

 Recommended:
 Enter IP address for each server or adapter
 (press enter after each, leave empty to finish):

IP.1 = 127.0.0.1
IP.2 =

Finished

  ------------------------------------------------------------------------
    Certificate generated for: service.my.awesome.domain.tld
            Alternative Names:
                               DNS.1 = service.my.awesome.domain.tld
                               DNS.2 = localhost
                                IP.1 = 127.0.0.1
  ------------------------------------------------------------------------
         Domain Configuration: /path/to/ssl/my.awesome.domain.tld/config.json
    Certificate Configuration: /path/to/ssl/my.awesome.domain.tld/cnf/service.my.awesome.domain.tld.cnf
  ------------------------------------------------------------------------
```

## Generate CRT

Now that you have your Certificate Signing Request ready to go, you can generate your certificate.

Run the `gencrt.sh` script and it will guide you through the process

```bash
./gencrt.sh
```

Again, you can optionally pass the domain name, or the domain name and subdomain to it to speed up the process

```bash
./gencrt.sh my.awesome.domain.tld
```

or

```bash
./gencrt.sh my.awesome.domain.tld service
```

When prompted, enter the passphrase you used to secure your CA Key. This is used to sign the certificate.

```plaintext
./gencrt.sh my.awesome.domain.tld service

Domain is: my.awesome.domain.tld
Subdomain is: service

Cert will be created for service.my.awesome.domain.tld

Creating new cert directory
Generating Key... done
Generating CSR... done
Generating CRT...
Certificate request self-signature ok
subject=C = GB, ST = Farnborough, L = Hampshire, O = My Awesome Company, OU = IT Wizards, CN = service.my.awesome.domain.tld
Enter pass phrase for /path/to/ssl/my.awesome.domain.tld/ca/myCA.key:
done
Create Chain... done
Assemble Full Chain... done

Finished

  ------------------------------------------------------------------------
              Certificate PEM: /path/to/ssl/my.awesome.domain.tld/crt/live/service.my.awesome.domain.tld/cert.pem
              Certificate Key: /path/to/ssl/my.awesome.domain.tld/crt/live/service.my.awesome.domain.tld/privkey.pem
            Certificate Chain: /path/to/ssl/my.awesome.domain.tld/crt/live/service.my.awesome.domain.tld/chain.pem
       Certiticate Full Chain: /path/to/ssl/my.awesome.domain.tld/crt/live/service.my.awesome.domain.tld/fullchain.pem
  ------------------------------------------------------------------------
```

Your new certificates will appear under `ssl/my.awesome.domain.tld/crt/live/name.subdomain.domain.tld/`

If a certificate existed by that name previously, it will be moved to `ssl/my.awesome.domain.tld/crt/archive/name.subdomain.domain.tld.YYYYMMDD-HHMMSS/`

You will have the following files (these filenames will match LetsEncrypt / Certbot generated certs):

- cert.pem - your certificate
- chain.pem - the chain for the certificate, also known as your CA or Certificate Authority
- fullchain.pem - Your certificate plus your CA
- privkey.pem - The private key for your certificate

By the end of this, your tree will look like the following (including two domain examples with one service each which has had its certificate re-issued once):

```plaintext
ssl
├── config.json.sample
├── default.json
├── genca.sh
├── gencnf.sh
├── gencrt.sh
└── my.awesome.domain.tld
   ├── ca
   │   ├── myCA.cnf
   │   ├── myCA.key
   │   └── myCA.pem
   ├── cnf
   |   └── service.my.awesome.domain.tld.cnf
   ├── config.json
   ├── crt
   │   ├── archive
   │   │   └── service.my.awesome.domain.tld.20240826-152506
   │   │       ├── cert.pem
   │   │       ├── chain.pem
   │   │       ├── fullchain.pem
   │   │       └── privkey.pem
   │   └── live
   │       └── service.my.awesome.domain.tld
   │           ├── cert.pem
   │           ├── chain.pem
   │           ├── fullchain.pem
   │           └── privkey.pem
   └── csr
       └── service.my.awesome.domain.tld.csr
```

## Author Information

**Tristan Findley**

Find out more about me [here](https://tfindley.co.uk).

If you're fan of my work and would like to show your support:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Z8Z016573P)
