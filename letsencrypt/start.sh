#!/bin/bash

# Azure Login
echo "Login to Azure CLI..."
az login --identity --username $USERNAME --allow-no-subscriptions 2> azcli.err
while [ $? -ne 0 ]
do
  echo "User Managed Identity not yet propagated. Waiting 10 seconds"
  sleep 10s
  az login --identity --username $USERNAME --allow-no-subscriptions 2> azcli.err
done

# Execute Let's Encrypt cert issuing process
if [ $PRODUCTION -eq 0 ]; then
  echo "Try issuing certificate from Let's Encrypt (Staging)..."
  certbot certonly --authenticator dns-azure --preferred-challenges dns --dns-azure-config azuredns.ini --non-interactive --agree-tos --email $YOUR_CERTIFICATE_EMAIL --domains *.$YOUR_DOMAIN --dns-azure-propagation-seconds 20 --staging 
else
    echo "Try issuing certificate from Let's Encrypt (Production)..."
  certbot certonly --authenticator dns-azure --preferred-challenges dns --dns-azure-config azuredns.ini --non-interactive --agree-tos --email $YOUR_CERTIFICATE_EMAIL --domains *.$YOUR_DOMAIN --dns-azure-propagation-seconds 20 
fi

# Create Temp Password
PFX_EXPORT_PASSWORD=$(pwgen 14 1 -c -n -y)
# Create PFX file
echo "Try create certificate..."
cp /etc/letsencrypt/live/$YOUR_DOMAIN/* .
openssl pkcs12 -inkey /privkey.pem -in /fullchain.pem -export -out /sslcert.pfx -passout pass:"$PFX_EXPORT_PASSWORD"
echo "Done"

# Upload to KeyVault
echo "Import SSL Certificate to KeyVault..."
az keyvault certificate import --vault-name $KEY_VAULT_NAME -n $KEY_VAULT_CERT_NAME -f /sslcert.pfx --password $PFX_EXPORT_PASSWORD 2> azkeyvault.err
while [ $? -ne 0 ]
do
  echo "Rights not available. Waiting 10 seconds"
  sleep 10s
  az keyvault certificate import --vault-name $KEY_VAULT_NAME -n $KEY_VAULT_CERT_NAME -f /sslcert.pfx --password $PFX_EXPORT_PASSWORD 2> azkeyvault.err
done
echo "Import successful."