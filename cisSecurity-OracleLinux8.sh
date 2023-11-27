#!/bin/sh

###############################################################################
#	Informatics Services Corporation 
#	write by M.Aghayari
#	edited by BaHaDoR Pajouhesh NiA		27-11-2023
###############################################################################

###############################################################################
#	get rpm lists
###############################################################################
rpm_List=`rpm -qa`

> /etc/modprobe.d/CIS.conf

###############################################################################
# disable CramFS
###############################################################################
if ( modprobe -n -v cramfs &> /dev/null ) ; then
        echo "install cramfs /bin/true" >> /etc/modprobe.d/CIS.conf
        if ( lsmod | grep cramfs &> /dev/null ) ; then
                rmmod cramfs
        fi
        echo "cramfs blocked"
fi

###############################################################################
# disable squashfs
# prevent the use of snap package manager
###############################################################################
if ( modprobe -n -v squashfs &> /dev/null ) ; then
        echo "install squashfs /bin/true" >> /etc/modprobe.d/CIS.conf
        if ( lsmod | grep squashfs &> /dev/null ) ; then
                rmmod squashfs
        fi
        echo "squashfs blocked"
fi

###############################################################################
# disable udf
###############################################################################
if ( modprobe -n -v udf | grep -E '(udf|install)' &> /dev/null ) ; then
        echo "install udf /bin/true" >> /etc/modprobe.d/CIS.conf
        if ( lsmod | grep udf &> /dev/null ) ; then
                rmmod udf
        fi
        echo "udf filesystem blocked"
fi

###############################################################################
# disable vfat
# prevent boot on UEFI systems
###############################################################################
if ( modprobe -n -v vfat &> /dev/null ) ; then
        echo "install vfat /bin/true" >> /etc/modprobe.d/CIS.conf
        if ( lsmod | grep vfat &> /dev/null ) ; then
                rmmod vfat
        fi
        echo "vfat blocked"
fi

###############################################################################
# disable fat
# prevent boot on UEFI systems
###############################################################################
if ( modprobe -n -v fat &> /dev/null ) ; then
        echo "install fat /bin/true" >> /etc/modprobe.d/CIS.conf
        if ( lsmod | grep fat &> /dev/null ) ; then
                rmmod fat
        fi
        echo "fat blocked"
fi

###############################################################################
# disable msdos
# prevent boot on UEFI systems
###############################################################################
if ( modprobe -n -v msdos &> /dev/null ) ; then
        echo "install msdos /bin/true" >> /etc/modprobe.d/CIS.conf
        if ( lsmod | grep msdos &> /dev/null ) ; then
                rmmod msdos
        fi
        echo "msdos blocked"
fi

###############################################################################
# configure  /tmp partition              
###############################################################################
cp -vf /etc/fstab /etc/fstab.cis
if [ $? -eq 0 ] ; then
        echo "fstab Backup done successfully"
else
        echo "fstab Backup Failed"
        exit
fi

##if ( mount | grep -E '\s/tmp\s' ) ; then 
##echo there is
##fi

if ( grep -E '\s/tmp\s' /etc/fstab | grep -E -v '^\s*#' ) ; then
   sed -i "/tmpfs.*\/tmp\|\/tmp.*tmpfs/d" /etc/fstab
   echo "tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0 in fstab file" 
   echo "tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
   mount -o remount,noexec,nodev,nosuid /tmp
   if [ $? != 0 ] ; then 
      echo "mount /tmp is failed" 
      exit
   fi
fi


stat_tmp=`systemctl is-enabled tmp.mount`
if [ "$stat_tmp" = "enabled" ]; then 
   echo "create and config tmp.mount service"
   [ ! -f /etc/systemd/system/tmp.mount ] && cp -vf /usr/lib/systemd/system/tmp.mount /etc/systemd/system/
   sed -i "s/^#\? \?What=.*/What=tmpfs/g" /etc/systemd/system/tmp.mount
   sed -i "s/^#\? \?Where=.*/Where=tmp/g" /etc/systemd/system/tmp.mount
   sed -i "s/^#\? \?Type=.*/Type=tmpfs/g" /etc/systemd/system/tmp.mount
   sed -i "s/^#\? \?Options=.*/Options=mode=1777,strictatime,noexec,nodev,nosuid/g" /etc/systemd/system/tmp.mount
   systemctl daemon-reload
   systemctl unmask tmp.mpunt
   systemctl restart tmp.mount
   systemctl enable --now tmp.mount
   if [ $? != 0 ] ; then
      echo "service tmp.mount is failed"
      exit
   fi
fi

###############################################################################
# configure  /dev/shm mount point
###############################################################################
if ( mount | grep -E '\s/dev/shm\s' &> /dev/null ) ; then
   echo "there is /dev/shm"
   sed -i "/tmpfs.*\/dev\/shm\|\/dev\/shm.*tmpfs/d" /etc/fstab
   echo "tmpfs /dev/shm tmpfs defaults,noexec,nodev,nosuid,seclabel 0 0"  >> /etc/fstab
   mount -o remount,noexec,nodev,nosuid /dev/shm
   if [ $? != 0 ] ; then
      echo "mount /tmp is failed"
      exit
   fi
fi

if ( grep -E '\s/dev/shm\s' /etc/fstab &> /dev/null ) ; then
   echo "there is /dev/shm on /etc/fstab"
   sed -i "/tmpfs.*\/dev\/shm\|\/dev\/shm.*tmpfs/d" /etc/fstab
   echo "tmpfs /dev/shm tmpfs defaults,noexec,nodev,nosuid,seclabel 0 0 in fstab file"
   echo "tmpfs /dev/shm tmpfs defaults,noexec,nodev,nosuid,seclabel 0 0"  >> /etc/fstab
   mount -o remount,noexec,nodev,nosuid /dev/shm
   if [ $? != 0 ] ; then
      echo "mount /tmp is failed"
      exit
   fi
fi

###############################################################################
# ignored configure /var /var/tmp /var/log /var/log/audit /home mount point
###############################################################################

###############################################################################
# set the sticky bit on all world writable directories
###############################################################################
echo "set the sticky bit on all world writable directories"
df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | xargs -I '{}' chmod a+t '{}'


###############################################################################
# Disable Automounting CD/DVD and usb deices 
###############################################################################
if ( systemctl is-enabled autofs &> /dev/null  ) ; then
   echo "Disable Automounting CD/DVD and usb deices"
   systemctl --now mask autofs
else
   echo "autofs is not enabled"
fi

###############################################################################
# Disable USB Storage
###############################################################################
if ( modprobe -n -v usb-storage &> /dev/null ) ; then
        echo "install usb-storage /bin/true" >> /etc/modprobe.d/CIS.conf
        if ( lsmod | grep usb-storage &> /dev/null ) ; then
                rmmod usb-storage
        fi
        echo "usb-storage blocked"
fi

###############################################################################
# Ensure sudo is installed
###############################################################################
if ( echo "$rpm_List" | grep sudo &> /dev/null ) ; then 
   echo "there is sudo packages" 
else
   echo "there is no sudo packages, so installing that"   
   yum install -y sudo
   if [ $? != 0 ] ; then
      echo "install sudo package is failed"
      exit
   fi
fi

###############################################################################
# Ensure sudo commands use pty
###############################################################################
if ( egrep 'Defaults.*use_pty' /etc/sudoers &> /dev/null ) ; then
   echo "sudo use pty by default"
else
   chmod u+w /etc/sudoers
   echo "Defaults use_pty" >> /etc/sudoers
   if [ $? != 0 ] ; then
      echo "set pty by sudo failed"
      exit
   fi
   chmod u-w /etc/sudoers
   echo "set sudo use pty successfully"
fi

###############################################################################
# Ensure sudo log file exists
###############################################################################
if ( egrep 'Defaults.*logfile' /etc/sudoers &> /dev/null ) ; then
   echo "there is log file for sudoers"
else
   chmod u+w /etc/sudoers
   echo 'Defaults logfile="/var/log/sudo.log"' >> /etc/sudoers
   if [ $? != 0 ] ; then
      echo "set log file for sudoers failed"
      exit
   fi
   chmod u-w /etc/sudoers
   echo "set log file for sudoers successfully"
fi

###############################################################################
# install and configure aide
###############################################################################
if ( echo "$rpm_List" | grep aide &> /dev/null ) ; then
   echo "aide package is installed before"
else
   rpm -hiv ./packages/aide/aide-0.15.1-11.el7.x86_64.rpm
   echo "initilize aide"
   /usr/sbin/aide --init
   if [ $? -eq 0 ] ; then
      mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
      echo "0 5 * * * /usr/sbin/aide --check" >> /etc/crontab
      systemctl restart crond
   else
      echo "could not intilize AIDE"
   fi
fi

###############################################################################
# secure boot setting
###############################################################################
chown root:root /boot/grub2/grub.cfg
chmod og-rwx /boot/grub2/grub.cfg
echo " grub.conf secured"

echo "set password for grub"
## the  password is mySecr3tPwd unsing grub-md5-crypt command
cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.cis
if [ $? -eq 0 ] ; then
   echo "GRUB2_PASSWORD=grub.pbkdf2.sha512.10000.DC579E4337D2CC04089CA916702508A7EE93AEAB346AC2B2940D2F1511C2C78518316E21B480CA459FD68E754589D41392D98A30025ECD1D54AE0BE61A3A2168.9E9A77414B1C566F16E7F3D93760BE2AC21D16DE8680D201A0D318155DD587F1EE3F45D28B2A4F6BF31809E9C2DB89242C8A9316DF05AADB9495F966A4499385"  > /boot/grub2/user.cfg

   chown root:root /boot/grub2/user.cfg
   chmod og-rwx /boot/grub2/user.cfg
   echo " user.conf secured"
else
   echo "failed to backup grub.conf and set password"
fi

###############################################################################
# Ensure core dumps are restricted
###############################################################################
cp /etc/security/limits.conf /etc/security/limits.conf.cis
echo "restricit core dump, set core file size to 0 in /etc/security/limits.conf"
echo "* hard core 0" >> /etc/security/limits.conf
cp /etc/sysctl.conf /etc/sysctl.conf.cis
cat /etc/sysctl.conf | uniq | tee /etc/sysctl.conf
# ready sysctl.conf file
sed -i '/Ensure/d' /etc/sysctl.conf
echo "" >> /etc/sysctl.conf
echo "restricit core dump, set fs.suid_dumpable to 0 in /etc/sysctl.conf"
echo "# Ensure core dumps are restricted " >> /etc/sysctl.conf
sed -i '/fs.suid_dumpable/d' /etc/sysctl.conf
echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf

###############################################################################
# Ensure address space layout randomization (ASLR) is enabled
###############################################################################
echo "" >> /etc/sysctl.conf
echo "enable ASLR, set randomize_va_space to 2 in /etc/sysctl.conf "
echo "# Ensure address space layout randomization (ASLR) is enabled" >> /etc/sysctl.conf
sed -i '/kernel.randomize_va_space/d' /etc/sysctl.conf
echo "kernel.randomize_va_space = 2"  >> /etc/sysctl.conf

###############################################################################
# Ensure prelink is disabled 
###############################################################################
if ( echo "$rpm_List" | grep prelink  &> /dev/null ) ; then
   echo "prelink is installed so restore binaries to normal and remove it"
   prelink -ua
   yum remove -y prelink
else
   echo "there is no prelink package"
fi

###############################################################################
# ignore selinux ????????????????????????
###############################################################################



###############################################################################
# Ensure SETroubleshoot is not installed
###############################################################################
if ( echo "$rpm_List" | grep setroubleshoot  &> /dev/null ) ; then
   echo "setroubleshoot is installed so remove it"
   yum remove -y setroubleshoot
else
   echo "there is no setroubleshoot package"
fi

###############################################################################
# Ensure mcstrans is not installed
###############################################################################
if ( echo "$rpm_List" | grep mcstrans  &> /dev/null ) ; then
   echo "mcstrans is installed so remove it"
   yum remove -y mcstrans
else
   echo "there is no mcstrans package"
fi

###############################################################################
#  Ensure local|remote login warning banner is configured properly
###############################################################################
echo "Ensure local|remote login warning banner is configured properly"
echo "Authorized uses only. All activity may be monitored and reported." > /etc/issue
echo "Authorized uses only. All activity may be monitored and reported." > /etc/issue.net

###############################################################################
# Ensure message of the day is configured properly motd
###############################################################################
echo "remove message ofthe day"
rm /etc/motd


###############################################################################
# Ensure permissions on passwd* and group* and shadow* and gshadow* are configured
###############################################################################
echo "set owner and permission on /etc/passwd*"
chown root:root /etc/passwd*
chmod u-x,g-wx,o-wx /etc/passwd*

echo "set owner and permission on /etc/group*"
chown root:root /etc/group*
chmod u-x,g-wx,o-wx /etc/group*

echo "set owner and permission on /etc/shadow*"
chown root:root /etc/shadow*
chmod 0000 /etc/shadow*

echo "set owner and permission on /etc/gshadow*"
chown root:root /etc/gshadow*
chmod 0000 /etc/gshadow*

###############################################################################
# Ensure permissions on /etc/issue and /etc/issue.net are configured
###############################################################################
echo "set owner and permission on /etc/issue"
chown root:root /etc/issue
chmod u-x,go-wx /etc/issue
echo "set owner and permission on /etc/issue.net"
chown root:root /etc/issue.net
chmod u-x,go-wx /etc/issue.net

###############################################################################
#  Ensure GDM login banner is configured
###############################################################################
echo "Ensure GDM login banner is configured"
systemctl is-enabled gdm &> /dev/null
if [ $? -eq 0 ] ; then
	echo -e "user-db:user\nsystem-db:gdm\nfile-db:/usr/share/gdm/greeter-dconf-defaults" > /etc/dconf/profile/gdm
	echo -e "[org/gnome/login-screen]\nbanner-message-enable=true\nbanner-message-text='Authorized uses only. All activity may be monitored and reported.'" > /etc/dconf/db/gdm.d/01-banner-message
	dconf update
	if [ $? -eq 0 ] ; then
		echo "GDM login banner has configured sucsessfully"
	else
		echo "GDM login banner has configured FAILED"
	fi
else
	echo "There is no GDM service available on the server"
fi

###############################################################################
# Ensure xinetd is not installed ?????????
###############################################################################
if ( echo "$rpm_List" | grep xinetd  &> /dev/null ) ; then
   echo "xinetd is installed so remove it"
   yum remove -y xinetd
else
   echo "there is no xinetd package"
fi

###############################################################################
# Ensure ntp is not installed 
###############################################################################
if ( echo "$rpm_List" | grep "ntp-"  &> /dev/null ) ; then
   echo "ntp is installed so remove it"
   yum remove -y ntp 
else
   echo "there is no ntp package"
fi

###############################################################################
# Ensure chrony is not installed
###############################################################################
if ( echo "$rpm_List" | grep "chrony"  &> /dev/null ) ; then
   echo "chrony is installed so remove it"
   yum remove -y chrony
else
   echo "there is no chrony package"
fi

###############################################################################
# Ensure X11 Server components are not installed 
###############################################################################
if ( echo "$rpm_List" | grep "xorg-x11-server*"  &> /dev/null ) ; then
   echo "xorg-x11-server* are installed so remove it"
   yum remove -y xorg-x11-server*
else
   echo "there are no xorg-x11-server* packages"
fi

###############################################################################
# Ensure avahi-autoipd and avahi are not installed
###############################################################################
if ( echo "$rpm_List" | egrep "avahi-autoipd|avahi"  &> /dev/null ) ; then
   echo "avahi-autoipd and avahi are installed so remove it"
   yum remove -y avahi-autoipd avahi
else
   echo "there are no avahi-autoipd avahi packages"
fi

###############################################################################
# Ensure Cups is not installed
###############################################################################
if ( echo "$rpm_List" | grep cups  &> /dev/null ) ; then
   echo "cups is installed so remove it"
   yum remove -y cups
else
   echo "there is no cups package"
fi

###############################################################################
# Ensure DHCP Server is not installed 
###############################################################################
if ( echo "$rpm_List" | grep dhcp  &> /dev/null ) ; then
   echo "dhcp is installed so remove it"
   yum remove -y dhcp
else
   echo "there is no dhcp package"
fi

###############################################################################
# Ensure LDAP server is not installed
###############################################################################
if ( echo "$rpm_List" | grep openldap-servers  &> /dev/null ) ; then
   echo "openldap-servers is installed so remove it"
   yum remove -y openldap-servers
else
   echo "there is no openldap-servers package"
fi

if ( echo "$rpm_List" | grep openldap-clients  &> /dev/null ) ; then
   echo "openldap-clients is installed so remove it"
   yum remove -y openldap-clients
else
   echo "there is no openldap-clients package"
fi

###############################################################################
# Ensure the nfs-server service is masked ????????????? nfs-utils
###############################################################################
if ( systemctl is-enabled nfs-server &> /dev/null  ) ; then
   echo "Disable nfs-server "
   systemctl --now mask nfs-server
else
   echo "nfs-server is not enabled"
fi

###############################################################################
# Ensure rpcbind is not installed or the rpcbind services are masked
###############################################################################
if ( systemctl is-enabled rpcbind &> /dev/null  ) ; then
   echo "Disable rpcbind "
   systemctl --now mask rpcbind
   systemctl --now mask rpcbind.socket
else
   echo "rpcbind is not enabled"
fi

###############################################################################
# Ensure DNS Server is not installed
###############################################################################
if ( rpm -q bind  &> /dev/null ) ; then
   echo "bind is installed so remove it"
   yum remove -y bind
else
   echo "there is no bind package"
fi

###############################################################################
# Ensure FTP Server is not installed 
###############################################################################
if ( echo "$rpm_List" | grep vsftpd  &> /dev/null ) ; then
   echo "vsftpd is installed so remove it"
   yum remove -y vsftpd
else
   echo "there is no vsftpd package"
fi

###############################################################################
# Ensure HTTP server is not installed ???????????????????
###############################################################################
if ( echo "$rpm_List" | grep httpd  &> /dev/null ) ; then
   echo "httpd is installed so remove it"
   yum remove -y httpd
else
   echo "there is no httpd package"
fi

###############################################################################
# Ensure IMAP and POP3 server is not installed
###############################################################################
if ( echo "$rpm_List" | grep dovecot &> /dev/null ) ; then
   echo "dovecot is installed so remove it"
   yum remove -y dovecot
else
   echo "there is no dovecot package"
fi

###############################################################################
# Ensure Samba is not installed 
###############################################################################
if ( echo "$rpm_List" | grep samba &> /dev/null ) ; then
   echo "samba is installed so remove it"
   yum remove -y samba
else
   echo "there is no samba package"
fi

###############################################################################
# Ensure HTTP Proxy Server is not installed
###############################################################################
if ( echo "$rpm_List" | grep squid &> /dev/null ) ; then
   echo "squid is installed so remove it"
   yum remove -y squid
else
   echo "there is no squid package"
fi

###############################################################################
# Ensure net-snmp is not installed 
###############################################################################
if ( echo "$rpm_List" | grep net-snmp &> /dev/null ) ; then
   echo "net-snmp is installed so remove it"
   yum remove -y net-snmp
else
   echo "there is no net-snmp package"
fi

###############################################################################
# Ensure mail transfer agent is configured for local-only mode 
###############################################################################
cp /etc/postfix/main.cf /etc/postfix/main.cf.cis

oldConfig=$(grep "inet_interfaces = localhost" /etc/postfix/main.cf)
newConfig="inet_interfaces = loopback-only"
sed -i "s/$oldConfig/$newConfig/" /etc/postfix/main.cf
if [ $? -eq 0 ] ; then 
   systemctl  restart postfix
   if [ $? -eq 0 ] ; then
      echo "mail transfer agent is configured for local-only mode SUCCESSFULLY"
   else
      echo "mail transfer agent is configured for local-only mode FAILED"
   fi
else
   echo "Could not update /etc/postfix/main.cf"
fi

###############################################################################
# Ensure rsync is not installed or the rsyncd service is masked  ?????
###############################################################################
#if ( echo "$rpm_List" | grep rsync &> /dev/null ) ; then
#   echo "rsync is installed so remove it"
#   yum remove -y rsync
#else
#   echo "there is no rsync package"
#fi

if ( systemctl is-enabled rsyncd &> /dev/null  ) ; then
   echo "Disable rsyncd service"
   systemctl --now mask rsyncd
else
   echo "rsyncd is not enabled"
fi

###############################################################################
# Ensure NIS server and client is not installed
###############################################################################
if ( echo "$rpm_List" | grep ypserv &> /dev/null ) ; then
   echo "ypserv is installed so remove it"
   yum remove -y ypserv
else
   echo "there is no ypserv package"
fi

if ( echo "$rpm_List" | grep ypbind &> /dev/null ) ; then
   echo "ypbind is installed so remove it"
   yum remove -y ypbind
else
   echo "there is no ypbind package"
fi

###############################################################################
# Ensure telnet-server and client is not installed
###############################################################################
if ( echo "$rpm_List" | grep telnet-server &> /dev/null ) ; then
   echo "telnet-server is installed so remove it"
   yum remove -y telnet-server
else
   echo "there is no telnet-server package"
fi

if ( echo "$rpm_List" | grep telnet &> /dev/null ) ; then
   echo "telnet is installed so remove it"
   yum remove -y telnet
else
   echo "there is no telnet package"
fi

###############################################################################
# Ensure rsh client is not installed
###############################################################################
if ( echo "$rpm_List" | grep rsh &> /dev/null ) ; then
   echo "rsh is installed so remove it"
   yum remove -y rsh
else
   echo "there is no rsh package"
fi

###############################################################################
# Ensure talk client is not installed
###############################################################################
if ( echo "$rpm_List" | grep talk &> /dev/null ) ; then
   echo "talk is installed so remove it"
   yum remove -y talk
else
   echo "there is no talk package"
fi

###############################################################################
# Ensure remove extra Dependencies 
###############################################################################
echo "remove extra Dependencies"
yum autoremove -y

###############################################################################
# Ensure IPv6 is disabled
###############################################################################
echo "Disable IPv6"
cp /etc/default/grub /etc/default/grub.cis

oldConfig=$(grep "GRUB_CMDLINE_LINUX" /etc/default/grub )
oldConfigTmp=${oldConfig: : -1}
newConfig=$(echo $oldConfigTmp ipv6.disable=1\")

sed -i  "/GRUB_CMDLINE_LINUX/d"  /etc/default/grub
if [ $? -eq 0 ] ; then 
	echo $newConfig >> /etc/default/grub
	grub2-mkconfig > /boot/grub2/grub.cfg
	
else
	echo "Disabling IPv6 FAILED"
fi

###############################################################################
# Ensure IP forwarding is disabled 
# Ensure packet redirect sending is disabled and ICMP redirects are not accepted
# Ensure source routed packets are not accepted
# Ensure ICMP redirects are not accepted
# Ensure secure ICMP redirects are not accepted
# Ensure suspicious packets are logged
# Ensure broadcast ICMP requests are ignored 
# Ensure bogus ICMP responses are ignored
# Ensure Reverse Path Filtering is enabled
# Ensure TCP SYN Cookies is enabled
# Ensure IPv6 router advertisements are not accepted
# Ensure IPv6 redirects are not accepted
###############################################################################
echo ""
echo "" >> /etc/sysctl.conf
echo "disable IP forwarding , net.ipv4.ip_forward to 0 in /etc/sysctl.conf"
echo "# Ensure IP forwarding is disabled "  >> /etc/sysctl.conf
sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo "net.ipv4.ip_forward=0" >> /etc/sysctl.conf

echo ""
echo "" >> /etc/sysctl.conf
echo "Ensure packet redirect sending is disabled"
echo "# Ensure packet redirect sending is disabled" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.send_redirects/d' /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.send_redirects/d' /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf

echo ""
echo "" >> /etc/sysctl.conf
echo "Ensure source routed packets are not accepted"
echo "# Ensure source routed packets are not accepted" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.accept_source_route/d' /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.accept_source_route/d' /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_source_route = 0" >> /etc/sysctl.conf

echo ""
echo "" >> /etc/sysctl.conf
echo "Ensure ICMP redirects are not accepted"
echo "# Ensure ICMP redirects are not accepted" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.accept_redirects/d' /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.accept_redirects/d' /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf

echo ""
echo "" >> /etc/sysctl.conf
echo "Ensure Secure ICMP redirects are not accepted"
echo "# Ensure Secure ICMP redirects are not accepted" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.secure_redirects/d' /etc/sysctl.conf
echo "net.ipv4.conf.all.secure_redirects = 0" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.secure_redirects/d' /etc/sysctl.conf
echo "net.ipv4.conf.default.secure_redirects = 0" >> /etc/sysctl.conf

echo ""
echo "" >> /etc/sysctl.conf
echo "Ensure suspicious packets are logged"
echo "# Ensure suspicious packets are logged" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.log_martians/d' /etc/sysctl.conf
echo "net.ipv4.conf.all.log_martians = 1" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.log_martians/d' /etc/sysctl.conf
echo "net.ipv4.conf.default.log_martians = 1" >> /etc/sysctl.conf
 
echo ""
echo "" >> /etc/sysctl.conf
echo "Ensure broadcast ICMP requests are ignored" 
echo "# Ensure broadcast ICMP requests are ignored" >> /etc/sysctl.conf
sed -i '/net.ipv4.icmp_echo_ignore_broadcasts/d' /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf

echo ""
echo "" >> /etc/sysctl.conf
echo "Ensure bogus ICMP responses are ignored"
echo "# Ensure bogus ICMP responses are ignored" >> /etc/sysctl.conf
sed -i '/net.ipv4.icmp_ignore_bogus_error_responses/d' /etc/sysctl.conf
echo "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> /etc/sysctl.conf

echo ""
echo "" >> /etc/sysctl.conf
echo "Ensure Reverse Path Filtering is enabled"
echo "# Ensure Reverse Path Filtering is enabled" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.rp_filter/d' /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.rp_filter/d' /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter = 1" >> /etc/sysctl.conf

echo ""
echo "" >> /etc/sysctl.conf
echo "Ensure TCP SYN Cookies is enabled"
echo "# Ensure TCP SYN Cookies is enabled" >> /etc/sysctl.conf
sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf

echo ""
echo "" >> /etc/sysctl.conf
echo "Ensure IPv6 router advertisements are not accepted"
echo "# Ensure IPv6 router advertisements are not accepted" >> /etc/sysctl.conf
sed -i '/net.ipv6.conf.all.accept_ra/d' /etc/sysctl.conf
echo "net.ipv6.conf.all.accept_ra = 0" >> /etc/sysctl.conf
sed -i '/net.ipv6.conf.default.accept_ra/d' /etc/sysctl.conf
echo "net.ipv6.conf.default.accept_ra = 0" >> /etc/sysctl.conf

echo ""
echo "" >> /etc/sysctl.conf
echo "Ensure IPv6 redirects are not accepted"
echo "# Ensure IPv6 redirects are not accepted" >> /etc/sysctl.conf
sed -i '/net.ipv6.conf.all.accept_redirects/d' /etc/sysctl.conf
echo "net.ipv6.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
sed -i '/net.ipv6.conf.default.accept_redirects/d' /etc/sysctl.conf
echo "net.ipv6.conf.default.accept_redirects = 0" >> /etc/sysctl.conf

sysctl -p
echo "flush ipv4 route"
sysctl -w net.ipv4.route.flush=1

###############################################################################
# Ensure Uncommon Network Protocols is disabled 
###############################################################################

###############################################################################
# disable DCCP
###############################################################################
if ( modprobe -n -v dccp &> /dev/null ) ; then
        echo "install dccp /bin/true" >> /etc/modprobe.d/CIS.conf
        if ( lsmod | grep dccp &> /dev/null ) ; then
                rmmod dccp
        fi
        echo "dccp blocked"
fi

###############################################################################
# disable SCTP 
###############################################################################
if ( modprobe -n -v sctp &> /dev/null ) ; then
        echo "install sctp /bin/true" >> /etc/modprobe.d/CIS.conf
        if ( lsmod | grep sctp &> /dev/null ) ; then
                rmmod sctp
        fi
        echo "sctp blocked"
fi

###############################################################################
# check firewalld ???????????????????
###############################################################################

###############################################################################
# check rsyslog ???????????????????
###############################################################################

###############################################################################
# Ensure journald is configured to compress large log files
# Ensure journald is configured to write logfiles to persistent disk
###############################################################################
cp /etc/systemd/journald.conf /etc/systemd/journald.conf_cis
if [ $? -eq 0 ] ; then
        echo "compress journal large log files"
        sed -i '/Compress=/d' /etc/systemd/journald.conf
        echo "Compress=yes" >> /etc/systemd/journald.conf
        echo "write journal logfiles to persistent disk"
        sed -i '/Storage=/d' /etc/systemd/journald.conf
        echo "Storage=persistent" >> /etc/systemd/journald.conf
else
        echo "journald.conf Backup Failed"
        exit
fi

###############################################################################
# Ensure permissions on all logfiles are configured 
###############################################################################
find /var/log -type f -exec chmod g-wx,o-rwx "{}" + -o -type d -exec chmod g-wx,o-rwx "{}" \;
if [ $? -eq 0 ] ; then
	echo "set correct permissons on /var/log/ files done successfully"
else
	echo "set correct permissons on /var/log/ files done Failed"
	exit
fi

###############################################################################
# Ensure permissions on /etc/crontab and /etc/cron files are configured
###############################################################################
mv /etc/cron.deny /etc/cron.deny.cis
touch /etc/cron.allow
chown root:root /etc/crontab
chmod u-x,og-rwx /etc/crontab
chown root:root /etc/cron.*
chmod og-rwx /etc/cron.*
echo "/etc/crontab is secure now."

##################### check man-db.cron ??????????????????????

###############################################################################
# Ensure at is not installed
###############################################################################
if ( rpm -q at  &> /dev/null ) ; then
   echo "at is installed so remove it"
   yum remove -y at
else
   echo "there is no at package"
fi

###############################################################################
# secure sshd service
###############################################################################
chown root:root /etc/ssh/sshd_config
chmod og-rwx /etc/ssh/sshd_config
echo "/etc/ssh/sshd_config is secure now."

echo "Ensure permissions on SSH private host key files are configured"
find /etc/ssh -xdev -type f -name "ssh_host_*_key" -exec chmod u-x,g-wx,o-rwx {} \;
find /etc/ssh -xdev -type f -name "ssh_host_*_key" -exec chown root:ssh_keys {} \;

echo "Ensure permissions on SSH public host key files are configured"
find /etc/ssh -xdev -type f -name "ssh_host_*_key.pub" -exec chmod u-x,g-wx,o-rwx {} \;
find /etc/ssh -xdev -type f -name "ssh_host_*_key.pub" -exec chown root:ssh_keys {} \;

echo "Make a backup from /etc/ssh/sshd_config"
cp -vf /etc/ssh/sshd_config /etc/ssh/sshd_config.cis

if ( grep Protocol /etc/ssh/sshd_config  &> /dev/null ) ; then
   echo "set SSH Protocol is set to 2"
   sed -i 's/#Protocol 2/Protocol 2/' /etc/ssh/sshd_config
else
   echo "Add SSH Protocol to 2"
   echo "Protocol 2" >> /etc/ssh/sshd_config
fi

echo "set log level INFO for sshd"
sed -i 's/^#\? \?LogLevel.*/LogLevel INFO/g' /etc/ssh/sshd_config

echo "Ensure SSH X11 forwarding is disabled"
sed -i 's/^#\? \?X11Forwarding.*/X11Forwarding no/g' /etc/ssh/sshd_config

echo "Ensure SSH MaxAuthTries is set to 4 or less"
sed -i 's/^#\? \?MaxAuthTries.*/MaxAuthTries 4/g' /etc/ssh/sshd_config

echo "Ensure SSH IgnoreRhosts is enabled"
sed -i 's/^#\? \?IgnoreRhosts.*/IgnoreRhosts yes/g' /etc/ssh/sshd_config

echo "Ensure SSH HostbasedAuthentication is disabled"
sed -i 's/^#\? \?HostbasedAuthentication.*/HostbasedAuthentication no/g' /etc/ssh/sshd_config

echo "Ensure SSH root login is disabled"
sed -i 's/^#\? \?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config

echo "Ensure SSH PermitEmptyPasswords is disabled"
sed -i 's/^#\? \?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config

echo "Ensure SSH PermitUserEnvironment is disabled"
sed -i 's/^#\? \?PermitUserEnvironment.*/PermitUserEnvironment no/g' /etc/ssh/sshd_config

sed -i '/^Ciphers/d' /etc/ssh/sshd_config
if [ $? -eq 0 ] ; then
        echo "Ensure only strong Ciphers are used"
        echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr" >> /etc/ssh/sshd_config
else
        echo "set strong Ciphers is failed"
        exit
fi

#echo "Ensure only approved MAC algorithms are used"
#echo "MACs hmac-sha2-512,hmac-sha2-256" >> /etc/ssh/sshd_config

sed -i '/^kexalgorithms/d' /etc/ssh/sshd_config
if [ $? -eq 0 ] ; then
        echo "Ensure only strong Key Exchange algorithms are used"
        echo "kexalgorithms curve25519-sha256,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256" >> /etc/ssh/sshd_config
else
        echo "set strong Key Exchange algorithms is failed"
        exit
fi

echo "Ensure SSH Idle Timeout Interval is configured"
sed -i 's/^#\? \?ClientAliveInterval.*/ClientAliveInterval 300/g' /etc/ssh/sshd_config
sed -i 's/^#\? \?ClientAliveCountMax.*/ClientAliveCountMax 0/g' /etc/ssh/sshd_config

echo "Ensure SSH LoginGraceTime is set to one minute or less"
sed -i 's/^#\? \?LoginGraceTime.*/LoginGraceTime 60/g' /etc/ssh/sshd_config

echo "Ensure SSH access is limited"
echo "AllowGroups wheel" >> /etc/ssh/sshd_config

echo "Ensure SSH warning banner is configured"
sed -i 's/^#\? \?Banner.*/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config

echo "Ensure SSH PAM is enabled"
sed -i 's/^#\? \?UsePAM.*/UsePAM yes/g' /etc/ssh/sshd_config

echo "Ensure SSH AllowTcpForwarding is disabled	"
sed -i 's/^#\? \?AllowTcpForwarding.*/AllowTcpForwarding no/g' /etc/ssh/sshd_config

echo "Ensure SSH MaxStartups is configured"
sed -i 's/^#\? \?MaxStartups.*/MaxStartups 10:30:60/g' /etc/ssh/sshd_config

echo "Ensure SSH MaxSessions is limited"
sed -i 's/^#\? \?MaxSessions.*/MaxSessions 10/g' /etc/ssh/sshd_config

systemctl restart sshd
if [ $? -eq 0 ] ; then
        echo "secure sshd is done successfully"
else
        echo "secure sshd is failed"
        exit
fi

###############################################################################
# Configure PAM
###############################################################################

###############################################################################
# Ensure lockout for failed password attempts is configured
###############################################################################
cp /etc/pam.d/password-auth /etc/pam.d/password-auth_cis
if [ $? -eq 0 ] ; then
        echo "set lockout user after login failed in password-auth file"
        sed -i '/auth.*pam_faillock.so/d' /etc/pam.d/password-auth 
        sed -i '/pam_env.so/a auth        required      pam_faillock.so preauth  silent audit  deny=5  unlock_time=900' /etc/pam.d/password-auth
        sed -i '/auth.*try_first_pass/a auth        [default=die] pam_faillock.so authfail        audit  deny=5  unlock_time=900' /etc/pam.d/password-auth
        sed -i '/account.*required.*pam_faillock.so/d' /etc/pam.d/password-auth
        sed -i '/^account.*required.*pam_unix.so/i account     required      pam_faillock.so' /etc/pam.d/password-auth
else
        echo "set lockout user after login failed in password-auth file is failed"
        exit
fi

cp /etc/pam.d/system-auth /etc/pam.d/system-auth_cis
if [ $? -eq 0 ] ; then
        echo "set lockout user after login failed in system-auth file"
        sed -i '/auth.*pam_faillock.so/d' /etc/pam.d/system-auth
        sed -i '/pam_env.so/a auth        required      pam_faillock.so preauth  silent audit  deny=5  unlock_time=900' /etc/pam.d/system-auth
        sed -i '/auth.*try_first_pass/a auth        [default=die] pam_faillock.so authfail        audit  deny=5  unlock_time=900' /etc/pam.d/system-auth
        sed -i '/account.*required.*pam_faillock.so/d' /etc/pam.d/system-auth
        sed -i '/^account.*required.*pam_unix.so/i account     required      pam_faillock.so' /etc/pam.d/system-auth
else
        echo "set lockout user after login failed in system-auth file is failed"
        exit
fi

###############################################################################
# Ensure default group for the root account is GID 0
###############################################################################
GID_ROOT=`grep "^root:" /etc/passwd | cut -f4 -d:`
if [ "$GID_ROOT" -eq 0 ] ; then
        echo "GID of root is 0"
else
        usermod -g 0 root
        echo "set 0 to GID of root"
fi  

###############################################################################
# Ensure access to the su command is restricted
###############################################################################
cp /etc/pam.d/su /etc/pam.d/su_cis
if [ $? -eq 0 ] ; then
        echo "Ensure access to the su command is restricted"
        sed -i '/auth.*required.*pam_wheel.so.*use_uid/d' /etc/pam.d/su 
        sed -i '/auth.*substack.*system-auth/i auth            required        pam_wheel.so use_uid' /etc/pam.d/su
else
        echo "restriction to su access is failed !!!"
        exit
fi

###############################################################################
# Ensure no world writable files exist
###############################################################################
echo "Ensure no world writable files exist"
find / -xdev -type f -perm /o=w -exec chmod o-w {} \;

###############################################################################
# Ensure no unowned and ungrouped files or directories exist      ??????????????????
###############################################################################
echo "Ensure no unowned and ungrouped files or directories exist"
NOOWNER=`find / -xdev -nouser |wc -l` 
NOGROUP=`find / -xdev -nogroup| wc -l`
if [[ $NOOWNER -gt 0 ]] || [[ $NOGROUP -gt 0 ]] ; then
        echo "There is/are $NOOWNER unowned and $NOGROUP ungrouped file/s , so check that with bellow commands : "
        echo "   find / -xdev -nouser"
        echo "   find / -xdev -nogroup"
        sleep 10;
else
        echo "There is no any unowned and ungrouped files"
fi

###############################################################################
# Audit SUID executables           ??????????????????????
###############################################################################
echo "     Ensure that no rogue SUID programs, so check below :          "
find / -xdev -type f -perm -4000
sleep 5

###############################################################################
# Audit SGID executables           ??????????????????????
###############################################################################
echo "     Ensure that no rogue SGID programs, so check below :          "
find / -xdev -type f -perm -2000
sleep 5

###############################################################################
# Ensure accounts in /etc/passwd use shadowed passwords
###############################################################################
USER_SHADOW=`awk -F: '($2 != "x" ) { print $1 " is not set to shadowed passwords "}' /etc/passwd`
if [ -z "$USER_SHADOW" ] ; then
         echo "All users use a shadow password" 
else
         echo "force user/s to using shadow password "      
         sed -e 's/^\([a-zA-Z0-9_]*\):[^:]*:/\1:x:/' -i /etc/passwd
fi

###############################################################################
# Ensure /etc/shadow and /etc/passwd password fields are not empty
###############################################################################
SHADOW_EMPTY=`awk -F: '($2 == "" ) { print $1 }' /etc/shadow`
PASSWD_EMPTY=`awk -F: '($2 == "" ) { print $1 }' /etc/passwd`
if [[ -z "$SHADOW_EMPTY" ]] && [[ -z "$PASSWD_EMPTY" ]] ; then
         echo "all users have a password"
else
         echo "force bellow user/s to using a password"
         echo "$SHADOW_EMPTY" "$PASSWD_EMPTY"
         echo ""
         exit
fi

###############################################################################
# Ensure root is the only UID 0 account
###############################################################################
UID_0=`awk -F: '($3 == 0) { print $1 }' /etc/passwd | grep -vw root`
if [ -z "$UID_0" ] ; then 
        echo "Just root user has 0 UID"
else
        echo -e "\n$UID_0 \nabove user/s has/have 0 uid, change uid of that user/s !!!"
        exit
fi

###############################################################################
#  Ensure root PATH Integrity
###############################################################################
if echo "$PATH" | grep -q "::" ; then
        echo "Empty Directory in PATH (::), so correct that !!!"
        exit
else
        echo "there is not Empty Directory in PATH"
fi

if echo "$PATH" | grep -q ":$" ; then
        echo "Trailing : in PATH, so correct that !!!"
        exit
else
        echo "there is not Trailing : in PATH"
fi


for x in $(echo "$PATH" | tr ":" " ") ; do
	if [ -d "$x" ] ; then
		ls -ldH "$x" | awk '
		$9 == "." {print "PATH contains current working directory (.) !!!"}
		$3 != "root" {print $9, "is not owned by root !!!"}
		substr($1,6,1) != "-" {print $9, "is group writable !!!"}
		substr($1,9,1) != "-" {print $9, "is world writable !!!"}'
	else
		echo "$x is not a directory"
	fi
done

###############################################################################
# Ensure all users' home directories exist 
###############################################################################
echo "Ensure all users' home directories exist."
CHK_TMP="/tmp/chk_home"
grep -E -v '^(halt|sync|shutdown)' /etc/passwd | grep -v "/sbin/nologin" | grep -v "/bin/false$" | awk -F: '{ print $1 " " $6 }' > "$CHK_TMP"

while read -r user dir; do
        if [ ! -d "$dir" ]; then
                echo "The home directory ($dir) of user $user does not exist."
                rm -rf "$CHK_TMP"
                exit
        else
                echo "$user has a home directory."
        fi
done < "$CHK_TMP"

###############################################################################
# Ensure users' home directories permissions are 750 or more restrictive
# Ensure users own their home directories
# Ensure users' dot files are not group or world writable
# Ensure no users have .forward files
# Ensure no users have .netrc files
# Ensure no users have .rhosts files
###############################################################################
echo "set permissions and correct owner of home directories."
CHK_TMP="/tmp/chk_home"
grep -E -v '^(halt|sync|shutdown)' /etc/passwd | grep -v "/sbin/nologin" | grep -v "/bin/false$" | awk -F: '{ print $1 " " $6 }' > "$CHK_TMP"

while read -r user dir; do
        if [ ! -d "$dir" ]; then
                echo "The home directory ($dir) of user $user does not exist."
                rm -rf "$CHK_TMP"
                exit
        else
                chmod -vR go-wx $dir
		chown -vR $user $dir
                echo "$user do not have .forward file"
                rm -rfv "$dir/.forward" 
		echo "$user do not have .netrc files"
                rm -rfv "$dir/.netrc" 
		echo "$user do not have .rhosts files"
                rm -rfv "$dir/.rhosts" 
        fi
done < "$CHK_TMP"
rm -rf "$CHK_TMP"

###############################################################################
# Ensure all groups in /etc/passwd exist in /etc/group 
###############################################################################
echo "Ensure all groups in /etc/passwd exist in /etc/group"
GID=`cut -s -d: -f4 /etc/passwd | sort -u `
for i in `echo $GID`; do
        grep -q -P "^.*?:[^:]*:$i:" /etc/group
        if [ $? -ne 0 ]; then
                echo "Group $i is referenced by /etc/passwd but does not exist in /etc/group, so please check it."
                exit
        fi
done

###############################################################################
#  Ensure no duplicate UIDs exist
###############################################################################
echo "check no duplicate UIDs exist"
cut -f3 -d":" /etc/passwd | sort -n | uniq -c | while read x ; do
	[ -z "$x" ] && break
	set - $x
	if [ $1 -gt 1 ]; then
		users=$(awk -F: '($3 == n) { print $1 }' n=$2 /etc/passwd | xargs)
		echo "Duplicate UID ($2): $users, so please check it."
		exit
	fi
done

###############################################################################
# Ensure no duplicate GIDs exist 
###############################################################################
echo "check no duplicate GIDs exist"
cut -d: -f3 /etc/group | sort | uniq -d | while read x ; do
	echo "Duplicate GID ($x) in /etc/group, so please check it."
	exit
done

###############################################################################
# Ensure no duplicate user names exist
###############################################################################
echo "check no duplicate user names exist."
cut -d: -f1 /etc/passwd | sort | uniq -d | while read x
        do echo "Duplicate login name ${x} in /etc/passwd, so please check it."
	exit
done

###############################################################################
# Ensure no duplicate group names exist 
###############################################################################
echo "check no duplicate group names exist."
cut -d: -f1 /etc/group | sort | uniq -d | while read x
        do echo "Duplicate group name ${x} in /etc/group, so please check it."
	exit
done

###############################################################################
# Ensure shadow group is empty
###############################################################################
SHADOW_GID=`grep "^shadow:" /etc/group | awk -F: '{print $3}'`
SHADOW_GROUP=`awk -F: '($4 == "$SHADOW_GID") { print }' /etc/passwd`
if [ -z "$SHADOW_GROUP" ] ; then
         echo "shadow group is empty"
else
         echo "shadow group is not empty, so please check it."
         exit
fi









