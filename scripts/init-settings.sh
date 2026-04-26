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
# 3. CLEANUP (free space)
#==============================================
log "Cleaning up..."

rm -f /tmp/opkg-lists/* 2>/dev/null
rm -f /tmp/luci-indexcache 2>/dev/null
rm -rf /tmp/luci-modulecache/* 2>/dev/null
rm -f /var/lock/* 2>/dev/null

#==============================================
# 4. MARK AS DONE (prevent re-run)
#==============================================
touch /etc/config_init_done

log "First boot setup complete!"
exit 0