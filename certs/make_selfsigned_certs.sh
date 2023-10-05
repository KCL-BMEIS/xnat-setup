## ./make_selfsigned_certs.sh [url (minus https//)] [IP]

# generate dhparem
openssl dhparam -out dhparam.pem 4096

# generate the private key for your CA
openssl genrsa -aes256 -out xnatca.key 4096

# generate the CA certificate (root certificate)
openssl req -new -key xnatca.key -x509 -out xnatca.crt -days 3650

#  create your domain/server certificate request
openssl req -new -nodes -newkey rsa:4096 -keyout xnat.key -out xnat.req -batch -subj "/C=GB/ST=England/L=London/O=KingsCollegeLondon CA/OU=xnat/CN=$1" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:$1,IP:$2"))

# sign the certificate request
openssl x509 -req -in xnat.req -CA xnatca.crt -CAkey xnatca.key -CAcreateserial -out xnat.crt -days 3650 -sha256 -extfile <(printf "subjectAltName=DNS:$1,IP:$2")

# build a chain file
cat xnat.key > xnatchain.pem
cat xnat.crt >> xnatchain.pem
cat xnatca.crt >> xnatchain.pem