#!/bin/sh

DIRNAME=`dirname $0`
cd $DIRNAME
USAGE="$0 [ --update ]"
if [ `id -u` != 0 ]; then
echo 'You must be root to run this script'
exit 1
fi

if [ ! -f /usr/share/selinux/devel/Makefile ]; then
echo 'selinux-policy-devel not installed, package required for building policy'
echo '# yum install selinux-policy-devel'
exit 1
fi

if [ $# -eq 1 ]; then
	if [ "$1" = "--update" ] ; then
		time=`ls -l --time-style="+%x %X" snort.te | awk '{ printf "%s %s", $6, $7 }'`
		rules=`ausearch --start $time -m avc --raw -se snort`
		if [ x"$rules" != "x" ] ; then
			echo "Found avc's to update policy with"
			echo -e "$rules" | audit2allow -R
			echo "Do you want these changes added to policy [y/n]?"
			read ANS
			if [ "$ANS" = "y" -o "$ANS" = "Y" ] ; then
				echo "Updating policy"
				echo -e "$rules" | audit2allow -R >> snort.te
				# Fall though and rebuild policy
			else
				exit 0
			fi
		else
			echo "No new avcs found"
			exit 0
		fi
	else
		echo -e $USAGE
		exit 1
	fi
elif [ $# -ge 2 ] ; then
	echo -e $USAGE
	exit 1
fi

echo "Building and Loading Policy"
set -x
make -f /usr/share/selinux/devel/Makefile
/usr/sbin/semodule -i snort.pp

/sbin/restorecon -F -R -v /usr/sbin/snort*
/sbin/restorecon -F -R -v /etc/rc.d/init.d/snortd
/sbin/restorecon -F -R -v /usr/lib/snort*
/sbin/restorecon -F -R -v /var/log/snort
/sbin/restorecon -F -R -v /etc/snort
