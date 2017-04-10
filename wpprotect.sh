#!/bin/bash
# Find wp-login files to protect
test -e /tmp/found-wp-instances || find /home/ -type f -name "wp-login.php" > /tmp/found-wp-instances

# For every result in the wp locations do
time while read -r wp; do
	#Set variables
	user=$(echo "$wp"|cut -d/ -f3)
	domain=$(echo "$wp"|cut -d/ -f5)
	wp_htaccess=${wp//wp-login.php/.htaccess}
	wp_htpasswd=${wp//wp-login.php/.htpasswd}
	password=$(openssl rand -base64 12)

	#Generate htpassword file
	echo "Securing $domain"
	#Sanity check to see if the file exists
	if [ -f "$wp_htpasswd" ]; then
		htpasswd -b "$wp_htpasswd" "$user" "$password"
	else
		htpasswd -bc "$wp_htpasswd" "$user" "$password"
	fi

	#Append directives to htaccess file
	cat <<- HTACCESS >> "$wp_htaccess"
	<FilesMatch "wp-login.php">
	AuthType Basic
	AuthName "Secure Area"
	AuthUserFile "$wp_htpasswd"
	require valid-user
	</FilesMatch>
	HTACCESS

	#Add details to password list
	echo "$domain $user $password" >> /root/wp-pass-list

done < /tmp/found-wp-instances
