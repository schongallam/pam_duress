# pam\_duress
A pam module written in C for duress codes in linux authentication.
Using this pam module, you can set up for any user as many [duress codes](http://en.wikipedia.org/wiki/Duress_code) as you want.
Basically what it does is if you access your account using a particular password, a script is run (so you can erase all your files if you are caught by the NSA for example...)
This project was inspired by [pam\_confused](https://code.google.com/p/confused/), but since that was written in python and was quite outdated (to the point of being unusable for me), I decided to write a similar pam module in C.

## Configuration

### common-auth et cetera
In order to use this module, you need to add it in one of the files in /etc/pam.d/ (for example in common-auth). You need to be careful on how you will add it so that it works properly. It is recommended that you put it in the primary block, right after the normal authentication module. It catches the last given password so in case the first module returns an authentication error, the authentication token goes right into the pam\_duress module.
Be sure to learn how the pam configuration files are structured so that the module works correctly.

For example, the primary block of my common-auth, before configuring it for this module was:

```
# here are the per-package modules (the "Primary" block)
auth	[success=2 default=ignore]	pam_unix.so nullok_secure
auth	[success=1 default=ignore]	pam_winbind.so krb5_auth krb5_ccache_type=FILE cached_login try_first_pass
```

The problem is that `success=2` and `success=1` mean to skip the next two or one modules (respectively). So when I added the module I had to change that as well:

```
# here are the per-package modules (the "Primary" block)
auth	[success=3 default=ignore]	pam_unix.so nullok_secure
auth	[success=2 default=ignore]	pam_winbind.so krb5_auth krb5_ccache_type=FILE cached_login try_first_pass
auth    sufficient                      pam_duress.so
```

So I changed these values so that if the first two modules succeed, the duress module is not called, but if those two fail, the duress module is `sufficient` to provide authentication.

If you want your configuration so that the duress module does not provide authentication, change the return value of `pam_sm_authenticate` to always be `PAM_AUTH_ERR`.

ATTENTION! If you allow authentication using the duress password, you should find a way to hide the fact that this was a duress password, because using it someone may be able to elevate to root permissions and, even if you change the permissions of `/usr/share/duress/hashes`, still be able to find whether you provided a duress password. A way to fix this is to delete (or alter) in your script your `hashes` file. Of course you'll need to rebuild it each time, but given that you'll be in a state of duress, it would be a good idea.

### Adding a user-password combination

Each user can have as many duress passwords as he/she wants, and each one with a different script to be run on startup. Each user/password combination is concatenated and the SHA256 of this user-password concatenation is written in `/usr/share/duress/hashes`. The structure of this file is a hash in hexadecimal format per line. You can do this using the script `adduser.sh` by doing `sudo bash ./adduser.sh username password` where you replace `username` with your username and `password` with your password. For example if your username is `foo` and your password is `bar` you should type `sudo bash ./adduser.sh foo bar`.

### Creating a script

Scripts for each hash are located at `/usr/share/duress/scripts/<hashgoeshere>` where this is supposed to be executable by root. Beware that this will be run as root, so many things will not work, while others can be dangerous. Since the permissions under `usr/share/` are `-rw-r--r--`, you need to chmod your scripts so that they become `-rwxr--r--`. This can be done using `sudo bash ./cpyscript.sh username password script` where you replace `username` with your username and `password` with the password that you have set as duress password and `script` with the path to your script. For example if your username is `foo`, your password is `bar`, and your script is at `~/script.sh` you should run `sudo bash ./cpyscript.sh foo bar /home/foo/script.sh`.

## Compilation

As usual:
```
make
sudo make install
make clean
```
