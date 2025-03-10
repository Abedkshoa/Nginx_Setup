#!/bin/bash

# Function to check if a package is installed
check_package() {
    dpkg -l | grep -q "^ii  $1 "
}

# Install Nginx if not installed
if ! check_package nginx; then
    echo "Nginx is not installed. Installing..."
    sudo apt update && sudo apt install -y nginx
else
    echo "Nginx is already installed."
fi

# Ensure userdir module is enabled
if [ ! -d /etc/nginx/userdir ]; then
    echo "Setting up user directories..."
    sudo mkdir -p /etc/nginx/userdir
    echo "location ~ ^/~([^/]+)(/.*)?$ {\n    root /home/$1/public_html;\n}" | sudo tee /etc/nginx/userdir.conf
    sudo ln -s /etc/nginx/userdir.conf /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
else
    echo "User directory configuration already exists."
fi

# Configure authentication with PAM
if [ ! -f /etc/nginx/.htpasswd ]; then
    echo "Setting up authentication..."
    sudo apt install -y apache2-utils
    sudo htpasswd -c /etc/nginx/.htpasswd admin
    echo "auth_basic \"Restricted Content\";" | sudo tee -a /etc/nginx/nginx.conf
    echo "auth_basic_user_file /etc/nginx/.htpasswd;" | sudo tee -a /etc/nginx/nginx.conf
    sudo systemctl restart nginx
else
    echo "Authentication is already configured."
fi

# Install CGI support
if ! check_package fcgiwrap; then
    echo "Installing CGI support..."
    sudo apt install -y fcgiwrap
    sudo systemctl enable fcgiwrap --now
    echo "location /cgi-bin/ {\n    gzip off;\n    fastcgi_pass unix:/var/run/fcgiwrap.socket;\n    include fastcgi_params;\n}" | sudo tee /etc/nginx/conf.d/cgi-bin.conf
    sudo systemctl restart nginx
else
    echo "CGI support is already installed."
fi

echo "Nginx setup complete."
