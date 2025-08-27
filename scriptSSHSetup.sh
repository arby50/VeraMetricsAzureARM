#!/bin/bash

# this script is used to setup the ssh access for the admin user
# it is run inside the mainTemplate.json file, base64 encoded
# microsoft requires ssh uid:pwd auth to be enabled when creatig from a template
# this script disables it and sets up ssh key auth
# it also changes the ownership of the flask app to the admin user
# and restarts the ssh service
# it is run as a custom script extension on the vm
# it copes the ssh key from a safe location (/usr/local/support/) to the admin user's .ssh directory

# Parse parameters
RESOURCE_GROUP_ID="$1"
SUBSCRIPTION_ID="$2"

# TODO: add this check back in
# 20250815:Ryan->
#      az login
#      az group create --name test-template-rg --location eastus
#      az deployment group validate --resource-group test-template-rg --template-file mainTemplate.json --parameters parameters.json
#      az deployment group create --resource-group test-template-rg --template-file mainTemplate.json --parameters parameters.json --name test-deployment
#      Resource: -c: line 18: syntax error: unexpected end of file\n'
#      az group delete --name test-template-rg --yes --no-wait
# if [ -z "$RESOURCE_GROUP_ID" ]; then
#     echo "Error: Resource ID not provided"
#     exit 1
# fi
# if [ -z "$SUBSCRIPTION_ID" ]; then
#     echo "Error: Resource ID not provided"
#     exit 1
# fi

# Create admin user
useradd -m -s /bin/bash jwdillonAdmin

# Ensure home directory has correct ownership
chown -R jwdillonAdmin:jwdillonAdmin /home/jwdillonAdmin

# Create .ssh directory
mkdir -p /home/jwdillonAdmin/.ssh
chmod 700 /home/jwdillonAdmin/.ssh

# Copy pre-placed SSH key from safe location
if [ -f /usr/local/support/authorized_keys ]; then
    cp /usr/local/support/authorized_keys /home/jwdillonAdmin/.ssh/authorized_keys
    echo "SSH key copied from pre-placed location"
else
    echo "No pre-placed SSH key found at /usr/local/support/authorized_keys"
fi

# Set correct permissions
chmod 600 /home/jwdillonAdmin/.ssh/authorized_keys
chown -R jwdillonAdmin:jwdillonAdmin /home/jwdillonAdmin/.ssh

# Change ownership of Flask app to jwdillonAdmin
chown -R jwdillonAdmin:jwdillonAdmin /var/www/html/
chown -R jwdillonAdmin:jwdillonAdmin /opt/spark/

# Ensure SSH config allows key authentication only
sed -i 's/#PubKeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/PubKeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart ssh

# Create environment file for the application
# cant create in jwdillonAdmin folder, perm problem, no idea why we can create a folder via mkdir but not a file
#cat > /home/jwdillonAdmin/.env << EOF
cat > /tmp/.env << EOF
AZURE_RESOURCE_GROUP_ID=${RESOURCE_GROUP_ID}
SUBSCRIPTION_ID=${SUBSCRIPTION_ID}
EOF
cp /tmp/.env /home/jwdillonAdmin/.env/

# Set ownership of the environment file
chmod 600 /home/jwdillonAdmin/.env
chown -R jwdillonAdmin:jwdillonAdmin /home/jwdillonAdmin/.env

echo "SSH access setup complete for jwdillonAdmin"
echo "VM configured with Resource Group ID: $RESOURCE_GROUP_ID"
echo "VM configured with Subscription ID: $SUBSCRIPTION_ID"