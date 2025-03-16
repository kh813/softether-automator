#!/bin/sh

FLAG_EXIT=1
TODAY=$(date "+%Y%m%d")

systemd_check(){
if ! which systemctl > /dev/null 2>&1; then
    echo "sytemctl not found"
    exit
elif [ -e /etc/wsl.conf ]; then 
    echo "WSL not supported"
    exit
fi
}

download_softether(){
git clone https://github.com/SoftEtherVPN/SoftEtherVPN_Stable.git
#mv -i SoftEtherVPN_Stable SoftEtherVPN-$TODAY
}

clean_softether() {
#cd SoftEtherVPN-$TODAY
cd SoftEtherVPN_Stable
make clean
}

build_softether() {
#cd SoftEtherVPN-$TODAY
#./configure --prefix=/usr/local
cd SoftEtherVPN_Stable
./configure
make -s
cd ../
}

unlock_features() {
#cd SoftEtherVPN-$TODAY
cd SoftEtherVPN_Stable
if [ -e ./src/Cedar/Server.c ]; then
        if [ ! -e ./src/Cedar/Server.c.orig ]; then
                cp ./src/Cedar/Server.c ./src/Cedar/Server.c.orig
        fi
        LINE=`grep -n "StrCmpi(region,\ \"JP\")" ./src/Cedar/Server.c | awk -F ":" '{print $1}'`
        TARGET_LINE=`echo $LINE+2 | bc`
        sed -i -e "$TARGET_LINE s/ret/\/\/ret/g " ./src/Cedar/Server.c
        diff ./src/Cedar/Server.c ./src/Cedar/Server.c.orig
fi
}

install_softether() {
#cd SoftEtherVPN-$TODAY
cd SoftEtherVPN_Stable
sudo make install
cd ../
}

setup_dev_tools() {
if [ 0 = `grep Ubuntu /etc/os-release | wc -c` -o ! -e /etc/debian_version ]; then
  echo "Unsupported OS/Distro"
  exit
elif [ -e /etc/wsl.conf ]; then 
  echo "WSL unsupported"
  exit
else	
  sudo apt install -y build-essential libssl-dev libreadline-dev libncurses5-dev zlib1g-dev
  sudo apt install -y bridge-utils dnsutils net-tools
fi
}

setup_systemd() {
echo "Wrting /etc/systemd/system/vpnserver.service"
cat <<EOT > /etc/systemd/system/vpnserver.service
[Unit]
Description=SoftEther VPN Server
After=network.target auditd.service
ConditionPathExists=!/usr/vpnserver/do_not_run

[Service]
Type=forking
EnvironmentFile=-/usr/vpnserver
ExecStart=/usr/vpnserver/vpnserver start
ExecStop=/usr/vpnserver/vpnserver stop
KillMode=process
Restart=on-failure

# Hardening
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full
ReadOnlyDirectories=/
ReadWriteDirectories=-/usr/vpnserver
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_SYS_NICE CAP_SYS_ADMIN CAP_SETUID

[Install]
WantedBy=multi-user.target
EOT

echo "systemd : add, enable & start"
sudo systemctl daemon-reload
sudo systemctl enable vpnserver
sudo systemctl start vpnserver
}

backup_softether() {
#sudo systemctl stop vpnserver
sudo cp -r /usr/vpnserver /usr/vpnserver_$TODAY
#sudo systemctl start vpnserver
}

remove_logs() {
sudo find /usr/vpnserver -name *.log -mtime +90 -exec ls -l {} \;  # Test
#sudo find /usr/vpnserver -name *.log -mtime +90 -exec rm {} \;
}

setup_vpnlogtimer() {
if [ ! -e /opt/softether-automator.sh ]; then 
  echo "/opt/softether-automator.sh not found"
  exit
fi

echo "Wrting /etc/systemd/system/vpnlog.service"
cat <<EOT > /etc/systemd/system/vpnlog.service
[Unit]
Description=Remove old VPN logs

[Service]
Type=simple
ExecStart=/opt/softether-automator.sh -r

[Install]
WantedBy=multi-user.target
EOT

echo "Wrting /etc/systemd/system/vpnlog.timer"
cat <<EOT > /etc/systemd/system/vpnlog.timer
[Unit]
Description=VPN log timer

[Timer]
OnCalendar=Sun *-*-* 18:00
Persistent=true

[Install]
WantedBy=timers.target
EOT

echo "Running systemctl daemon-reload"
sudo systemctl enable vpnlog.service
sudo systemctl start vpnlog.service
sudo systemctl daemon-reload
}

show_help() {
cat <<EOT
Usage:

 -- Build / install / update --
 -d   | download           : download the latest stable src from git repository
 -u   | unlock             : unlock features, such as LDAP/AD authentication
 -b   | build              : configure & make SoftEther
 -c   | clean              : make clean
 -i   | install            : install or update SoftEther
      | setup-devtool      : setup development tools on Ubuntu/Debian
      | setup-systemd      : setup init / systemd

 -- Operation --
 -z   | backup             : backup softether
 -r   | remove-old-logs    : remove old logs
      | setup-vpnlogtimer  : setup systemd timer for VPN log

 -- etc. --
 -h   | help               : show help
EOT
}

for OPT in "$@"
do
    case $OPT in
                -h | help)
                        FLAG_H=1
                        FLAG_EXIT=0
                        ;;
                -d | download)
                        FLAG_D=1
                        FLAG_EXIT=0
                        ;;
                -u | unlock)
                        FLAG_U=1
                        FLAG_EXIT=0
                        ;;
                -b | build)
                        FLAG_B=1
                        FLAG_EXIT=0
                        ;;
                -c | clean)
                        FLAG_C=1
                        FLAG_EXIT=0
                        ;;
                -i | install)
                        FLAG_I=1
                        FLAG_EXIT=0
                        ;;
                -z | backup)
                        FLAG_Z=1
                        FLAG_EXIT=0
                        ;;
                -r | remove-logs)
                        FLAG_R=1
                        FLAG_EXIT=0
                        ;;
                setup-devtool)
                        FLAG_ST=1
                        FLAG_EXIT=0
                        ;;
                setup-systemd)
                        FLAG_SS=1
                        FLAG_EXIT=0
                        ;;
                setup-vpnlogtimer)
                        FLAG_SL=1
                        FLAG_EXIT=0
                        ;;
    esac
    shift
done

if [ "$FLAG_H" ]; then
        show_help
fi

if [ "$FLAG_D" ]; then
        download_softether
fi

if [ "$FLAG_I" ]; then
        install_softether
fi

if [ "$FLAG_B" ]; then
        build_softether
fi

if [ "$FLAG_U" ]; then
        echo -n "Do you really unlock features, such as LDAP/AD auth., at your own risk? [Y/n]: "
        read RES
        case $RES in
        "" | [Yy]* ) # YES
                unlock_features
        ;;
        * ) # NO
                exit 0
        ;;
        esac
fi

if [ "$FLAG_C" ]; then
        clean_softether
fi

if [ "$FLAG_Z" ]; then
        backup_softether
fi

if [ "$FLAG_R" ]; then
        remove_logs
fi

if [ "$FLAG_ST" ]; then
        setup_dev_tools
fi

if [ "$FLAG_SS" ]; then
	systemd_check   # Exit unless systemd running as expected
        setup_systemd
fi

if [ "$FLAG_SL" ]; then
	systemd_check   # Exit unless systemd running as expected
        setup_vpnlogtimer
fi

if [ "$FLAG_EXIT" -eq 1 ]; then
        show_help
fi

