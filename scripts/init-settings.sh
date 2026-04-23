#!/bin/sh
#==========================================================
# VincherWrt - Init Settings (First Boot)
# Applied automatically on first boot via uci-defaults
#==========================================================

LOG_FILE="/tmp/init-settings.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

error_msg() {
    echo "[ERROR] $1" >> "$LOG_FILE"
    exit 1
}

#==========================================================
# PHP Configuration - Fix upload limits
#==========================================================
phpfix() {
    log "Configuring PHP..."
    
    local php_path="/etc/php.ini"
    [ -f "$php_path" ] || return
    
    # Increase upload limits
    sed -i "s|post_max_size = 8M|post_max_size = 2048M|g" ${php_path}
    sed -i "s|upload_max_filesize = 2M|upload_max_filesize = 2048M|g" ${php_path}
    
    log "PHP configured"
}

#==========================================================
# LuCI / uhttpd Configuration
#==========================================================
lucifix() {
    log "Configuring LuCI..."
    
    # Clear LuCI caches
    rm -f /tmp/luci-indexcache
    rm -rf /tmp/luci-modulecache/*
    
    # Fix permissions
    chmod -R 755 /usr/lib/lua/luci/controller/* 2>/dev/null || true
    chmod -R 755 /usr/lib/lua/luci/view/* 2>/dev/null || true
    chmod -R 755 /www/* 2>/dev/null || true
    
    # TinyFM fix
    [ -d /www/tinyfm ] && {
        chmod -R 755 /www/tinyfm/* 2>/dev/null || true
        [ ! -d /www/tinyfm/rootfs ] && ln -s / /www/tinyfm/rootfs
    }
    
    # uhttpd PHP interpreter
    uci set uhttpd.main.ubus_prefix='/ubus'
    uci set uhttpd.main.interpreter='.php=/usr/bin/php-cgi'
    uci set uhttpd.main.index_page='cgi-bin/luci'
    uci add_list uhttpd.main.index_page='index.html'
    uci add_list uhttpd.main.index_page='index.php'
    uci commit uhttpd
    
    # Restart uhttpd
    /etc/init.d/uhttpd restart 2>/dev/null || true
    
    # PHP8 symlink if exists
    [ -d /usr/lib/php8 ] && [ ! -d /usr/lib/php ] && ln -sf /usr/lib/php8 /usr/lib/php
    
    log "LuCI configured"
}

#==========================================================
# System Configuration
#==========================================================
sysconfig() {
    log "Configuring system..."
    
    # Timezone - WIB (Jakarta)
    uci set system.@system[0].timezone='WIB-7'
    uci set system.@system[0].zonename='Asia/Jakarta'
    
    # Hostname
    uci set system.@system[0].hostname='VincherWrt'
    uci commit system
    
    log "System configured"
}

#==========================================================
# Permissions Fix
#==========================================================
fix_perms() {
    log "Fixing permissions..."
    
    # luci-app-atinout-mod
    chmod +x /usr/bin/luci-app-atinout 2>/dev/null || true
    chmod +x /sbin/set_at_port.sh 2>/dev/null || true
    
    # Neofetch
    chmod +x /bin/neofetch 2>/dev/null || true
    
    # Cloudflared
    chmod +x /usr/bin/cloudflared 2>/dev/null || true
    
    # Clear cache script
    chmod +x /sbin/clearcache.sh 2>/dev/null || true
    
    log "Permissions fixed"
}

#==========================================================
# Cron Jobs
#==========================================================
setup_cron() {
    log "Setting up cron jobs..."
    
    # Auto clear cache every hour
    if ! grep -q "clearcache.sh" /etc/crontabs/root 2>/dev/null; then
        echo "0 * * * * /sbin/clearcache.sh" >> /etc/crontabs/root
    fi
    
    log "Cron jobs configured"
}

#==========================================================
# Main
#==========================================================
main() {
    log "=== VincherWrt Init Settings Started ==="
    
    phpfix
    lucifix
    sysconfig
    fix_perms
    setup_cron
    
    log "=== Init Settings Completed ==="
}

main "$@"
exit 0
