# File Tools
This folder contains scripts to ease certain operations on the OS environment.

- [File Tools](#file-tools)
  - [Add Custom headers to files with extension](#add-custom-headers-to-files-with-extension)
  - [Check if a script is used sourced](#check-if-a-script-is-used-sourced)
  - [Use of opts as arguments](#use-of-opts-as-arguments)
  - [How to start VSCode with a certificate key](#how-to-start-vscode-with-a-certificate-key)
  - [Certificates](#certificates)
    - [Analyze a pfx certificate (extract pieces)](#analyze-a-pfx-certificate-extract-pieces)
    - [Analyze certificates](#analyze-certificates)

## Add Custom headers to files with extension
This utility can help to add copyright or other relevant info on top of the files. A demo is shown at script **fTools/addHeadersDemo.sh**  


## Check if a script is used sourced
```shell
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi

# To exit the program due to an error for example without closing the terminal, just add this check
if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
```

## Use of opts as arguments
To use opts as arguments in your scripts: eg. sh userReg-flags.sh -f 'John Smith' -a 25 -u john
Check the kTools/exec.sh as a reference
```shell
function help() {
    HELP=""
    if test "$#" -ge 1; then
        HELP="${1}\n"
    fi
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] ..."
    echo $HELP
}

# getopts arguments
while true; do
    case "$1" in
        -v | --verbose ) 
            VERBOSE=true; shift ;;
        -h | --help ) 
            help;
            # echo "help rc=$?"
            return 1;
            break ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            fi
            break ;;
```

## How to start VSCode with a certificate key
The benefit of this approach is to avoid being asked for your user passwords by Visual Studio code once and again.  
The scenario is that you are remotely connecting to server A from a windows PC W.
```shell
# 1- Generate a keypair at the desired server A: 
CERTFILENAME=~/.ssh/ed25519-vscode
ssh-keygen -t ed25519 -f $CERTFILENAME 
# Previous command creates the ed25519 certificate keys at the ~/.ssh folder named ed25519-vscode and ed25519-vscode.pub.

# 2- Add the certificate into the authorized_key file: 
cat $CERTFILENAME.pub >> ~/.ssh/authorized_keys

# 3- Copy the content of the $CERTFILENAME (cat $CERTFILENAME) into a file of the Windows PC W (e.g. C:\Users\<user>\.ssh\zerowaste.itainova.es.key) and restrict the permissions to read only (multiline certificate must end with a newline after the “-----END OPENSSH PRIVATE KEY-----”)
cat $CERTFILENAME
```
4- At the VSCode of the Windows PC W, edit the Remote Explorer config file (Open SSH config file) and describe the connection to the desired server.
```
Host zerowaste.itainnova.es
    HostName <host name of the server A: eg. zerowaste.itainnova.es>
    User <username: eg. cgonzalez>
    IdentityFile <Path to the key certificate at the Windows PC W. eg: C:\Users\cgonzalez\.ssh\zerowaste.itainova.es.key>
```

## Certificates
### Analyze a pfx certificate (extract pieces)
```shell
# Taken from https://support.kaspersky.com/KSMG/2.1/en-US/239064.htm
# Used to analyze the certificate info. eg. Its alias name
# Show cert.pfx info (requires secret) 
keytool -list -v -keystore cert.pfx -storetype PKCS12
    Keystore type: PKCS12
    Keystore provider: SUN

    Your keystore contains 1 entry

    Alias name: ita.es
    Creation date: Oct 29, 2024
    Entry type: PrivateKeyEntry
    Certificate chain length: 1
    Certificate[1]:
    Owner: OU=BDSC, O=ITA, L=Zaragoza, ST=Zaragoza, C=ES, CN=ita.es
    Issuer: OU=BDSC, O=ITA, L=Zaragoza, ST=Zaragoza, C=ES, CN=ita.es
    Serial number: 1
    Valid from: Tue Oct 29 15:01:45 CET 2024 until: Sun Oct 29 15:01:45 CET 2124
    Certificate fingerprints:
            SHA1: 16:46:A8:E0:4D:0C:3B:15:E7:DA:2E:4E:13:FD:01:C0:66:55:E1:F7
            SHA256: 56:98:E6:49:C9:41:7B:49:AA:93:F0:02:4C:21:58:DB:E7:B3:A2:3C:EF:C5:8B:54:7C:29:57:FA:CE:46:0B:24
    Signature algorithm name: SHA256withRSA
    Subject Public Key Algorithm: 2048-bit RSA key
    Version: 3


    *******************************************
    *******************************************
# Extract the certificate
openssl pkcs12 -in cert.pfx -clcerts -nokeys -out cert.pem

# Extract the private key
openssl pkcs12 -in cert.pfx -nocerts -nodes -out key.pem
```

### Analyze certificates
- To see the validity of a public certificate:
```shell
PUBLIC_CERT=fullchain.pem
openssl x509 -enddate -noout -in $PUBLIC_CERT
```