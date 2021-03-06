SHELL := /bin/bash
CC = gcc
CFLAGS = -fPIC -fno-stack-protector -c -I/usr/local/ssl/include -DHASH_ROUNDS=1000
EDITOR = $${FCEDIT:-$${VISUAL:-$${EDITOR:-nano}}}

pam_duress: pam_duress.c adduser.c
	$(CC) $(CFLAGS) pam_duress.c
	$(CC) $(CFLAGS) adduser.c
install: pam_duress.c adduser.c
	if [ ! -e /lib/security ]; then \
		mkdir /lib/security; \
	fi
	$(CC) -shared pam_duress.o -o /lib/security/pam_duress.so -L/usr/local/ssl/lib -lcrypto; \
	$(CC) adduser.o -o adduser -L/usr/local/ssl/lib -lcrypto; \
	chmod 744 /lib/security/pam_duress.so; \
	chmod +x ./decoyscripts.sh; \
	chmod +x ./deluser.sh; \
	if [ ! -e /usr/share/duress ]; then \
		mkdir /usr/share/duress; \
                chmod -R 777 /usr/share/duress; \
	fi
	if [ ! -e /usr/share/duress/hashes ]; then \
		touch /usr/share/duress/hashes; \
	fi
	if [ ! -e /usr/share/duress/actions ]; then \
		mkdir /usr/share/duress/actions; \
		chmod -R 777 /usr/share/duress/actions; \
		bash decoyscripts.sh $$(( $${RANDOM} % 128 )); \
	fi
	if  whiptail --yesno "Edit /etc/pam.d/common-auth?" 10 50 ; then \
		$(EDITOR) /etc/pam.d/common-auth; \
	fi
clean:
	rm pam_duress.o
	rm adduser.o
