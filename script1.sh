
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
RESOURCE_ID="$1"
MARKETPLACE_SUBSCRIPTION_ID="$2"

if [ -z "$RESOURCE_ID" ]; then
    echo "Error: Resource ID not provided"
    exit 1
fi

# Create admin user
useradd -m -s /bin/bash jwdillonAdmin

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
# mkdir -p /opt/verametrics
cat > /home/jwdillonAdmin/.env << EOF
AZURE_RESOURCE_ID=${RESOURCE_ID}
MARKETPLACE_SUBSCRIPTION_ID=${MARKETPLACE_SUBSCRIPTION_ID}
EOF

# Set ownership of the environment file
chown jwdillonAdmin:jwdillonAdmin /home/jwdillonAdmin/.env
chmod 600 /home/jwdillonAdmin/.env

echo "SSH access setup complete for jwdillonAdmin"
echo "VM configured with Resource ID: $RESOURCE_ID"
