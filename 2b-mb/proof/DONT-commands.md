install session manager

curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" 

sudo dpkg -i session-manager-plugin.deb

___

ssm flow:

aws ssm start-session --target i-0700ed403343e01ca

see if it exists:

ls -R /opt/rdsapp

___

# 1. Create the folder where Flask expects static assets
sudo mkdir -p /opt/rdsapp/static

# 2. Create the file with the required content
sudo echo "Version 1.0" | sudo tee /opt/rdsapp/static/example.txt

# 3. Verify it exists
ls -l /opt/rdsapp/static/example.txt
Version 1.0