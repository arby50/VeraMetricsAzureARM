#!/bin/bash

# this script is used to setup the ssh access for the admin user
# it is run inside the mainTemplate.json file, base64 encoded
# microsoft requires ssh uid:pwd auth to be enabled when creatig from a template
# this script disables it and sets up ssh key auth
# it also changes the ownership of the flask app to the admin user
# and restarts the ssh service
# it is run as a custom script extension on the vm
# it copes the ssh key from a safe location (/usr/local/support/) to the admin user's .ssh directory

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

# Ensure SSH config allows key authentication only
sed -i 's/#PubKeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/PubKeyAuthentication no/PubKeyAuthentication yes/g' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart ssh

echo "SSH access setup complete for jwdillonAdmin"