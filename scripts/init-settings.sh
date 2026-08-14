#!/bin/sh
#==============================================
# VincherWrt - First Boot Setup
#==============================================

log() {
    echo "[init-settings] $1"
}

# Run once at first boot only
[ -f /etc/config_init_done ] && exit 0

log "Starting first boot setup..."

#==============================================
# 1. SYSTEM: Timezone, Hostname, NTP
#==============================================
log "Configuring system..."

uci set system.@system[0].timezone='WIB-7'
uci set system.@system[0].zonename='Asia/Jakarta'
uci set system.@system[0].hostname='VincherWrt'

# NTP Client - sync dengan server Indonesia
uci set system.ntp='timeserver'
uci set system.ntp.enabled='1'
uci set system.ntp.enable_server='0'
uci del system.ntp.server 2>/dev/null
uci add_list system.ntp.server='0.id.pool.ntp.org'
uci add_list system.ntp.server='1.id.pool.ntp.org'
uci add_list system.ntp.server='2.id.pool.ntp.org'

#==============================================
# 2. COMMIT
#==============================================
uci commit system

#==============================================
# 2.5. SHELL: Set root shell to bash
#==============================================
sed -i 's|^root:x:0:0:root:/root:/bin/ash|root:x:0:0:root:/root:/bin/bash|' /etc/passwd
sed -i 's|^root:x:0:0:root:/root:/bin/sh|root:x:0:0:root:/root:/bin/bash|' /etc/passwd
log "Shell updated to bash"

#==============================================
# 4. WIFI: Enable USB WiFi (RTL8188FU) as AP
#==============================================
log "Configuring WiFi AP..."

# Enable radio0 (USB WiFi adapter)
uci set wireless.radio0.disabled='0'

# Configure AP interface
uci set wireless.default_radio0.disabled='0'
uci set wireless.default_radio0.network='lan'
uci set wireless.default_radio0.mode='ap'
uci set wireless.default_radio0.ssid='VincherWrt'
uci set wireless.default_radio0.encryption='psk2'
uci set wireless.default_radio0.key='vincherwrt'
uci set wireless.radio0.channel='1'
uci set wireless.radio0.htmode='HT20'

uci commit wireless

#==============================================
# 5. CLEANUP (free space)
#==============================================
log "Cleaning up..."

rm -f /tmp/opkg-lists/* 2>/dev/null
rm -f /tmp/luci-indexcache 2>/dev/null
rm -rf /tmp/luci-modulecache/* 2>/dev/null
rm -f /var/lock/* 2>/dev/null

#==============================================
# 6. MARK AS DONE (prevent re-run)
#==============================================
touch /etc/config_init_done

log "First boot setup complete!"
exit 0