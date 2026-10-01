#!/bin/bash

INPUT=$(echo $1 | sed -r 's/(.*)%40/\1@/')
USERNAME=$(echo $INPUT | awk -F@ '{print $1}')

#LDAPSERVER="ldap://<ldapserver>"
#LDAPDN="dc=<host>,dc=<institute>,dc=<edu or com>"
#LDAPGROUP="cryoem"
LOCALUSER=""
LDAPUSER="null"

if [ $? -eq 0  ]; then

	#Can check ldap here if ldap is configured
        if [ -d /etc/pam.d ]; then
            if [ -f /etc/sssd/sssd.conf ] || [ -f /etc/nslcd.conf ] || [ -f /etc/ldap.conf ]; then
	        LDAPUSER=$(ldapsearch -x mail=$INPUT | grep "uid:" | awk '{print $2}')
#       	LDAPUSER=$(ldapsearch -ZZ -x -H $LDAPSERVER -b $LDAPDN uid=$USERNAME | grep "uid:" | awk '{print $2}')
            fi
        fi


        # getent passwd is inside the container and therefor will only return local users from the volume mounted passwd and group files 	
	LOCALUSER=$(getent passwd $USERNAME | awk -F ":" '{print $1}')

	if [[ "$LDAPUSER" == "$LOCALUSER" ]]; then
		echo $LOCALUSER
		exit 0
	fi
	# test this against local users or usermap
	# if true, return mapped username with $(echo "USERNAME")


	# If LDAPSEARCH fails then fallback to local usermap file
	for line in $(cat /etc/ood/bin/usermap); do
		email=$(echo $line | awk -F, '{print $1}')
		local_user=$(echo $line | awk -F, '{print $2}')

		if [[ "$email" == "$INPUT" ]]; then
			echo "$local_user"
			exit 0
		fi
	done

else
        echo "$1,$INPUT,$USERNAME" >> /var/log/apache_testing/output
        exit 1
fi

