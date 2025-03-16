# About / 概要

Softether VPN automation script; such as installation.
Softether VPNのセットアップ等を自動化するスクリプトです。


# Running the app / 実行方法

The script can be anywhere,
but we expact it to be under /opt

スクリプトは任意のフォルダに保存して実行できますが、
/opt 直下に配置することを想定しています。

Run the script
以下を実行
```
./softether-automator.sh <option>
```

Options
オプション
```
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
```

実行例
Example

```
cd /opt

# Download the source code
sudo ./softether-automator.sh -d

# [Optional] Unlock/enable advanced features
sudo ./softether-automator.sh -u
Do you really unlock features, such as LDAP/AD auth., at your own risk? [Y/n]: Y

# Build Sofether
sudo ./softether-automator.sh -b

# Then, install
sudo ./softether-automator.sh -i

```

# 動作確認 / Status check

You can check on the status with the following commands
以下のコマンドで実行状況を確認できます

```
# VPN Server
sudo systemctl status vpnserver

# VPN log autoremove
sudo systemctl status vpnlog

```


# テスト環境 / Test environment
- Ubuntu 24.04

