FROM ubuntu

# Update repository
RUN apt-get -y update
# Install Certbot
RUN apt-get -y install certbot
# Install Certbot DNS plugin for Azure
RUN apt-get -y install python3-pip
RUN pip3 install --break-system-packages certbot certbot-dns-azure
# Install PWGEN
RUN apt-get -y install pwgen
# Install cURL
RUN apt-get -y install curl
# Install Azure CLI with one command
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash -

# WORKDIR
WORKDIR /

# Copy scripts
COPY start.sh /
COPY azuredns.ini /

# Environment Variables/Parameters which can be set
# Mandatory
ENV YOUR_CERTIFICATE_EMAIL=yourcertificatemail 
# Mandatory
ENV YOUR_DOMAIN=yourdomainvalue
# Mandatory
ENV KEY_VAULT_NAME=keyvaultname
# Mandatory
ENV KEY_VAULT_CERT_NAME=mycertname
# Mandatory for issuing a real SSL certificate (0 = Testing)
ENV PRODUCTION=0
# Mandatory User Manage Identity
ENV USERNAME=usermanagedidentityclientid

CMD [ "/bin/bash", "/start.sh"]