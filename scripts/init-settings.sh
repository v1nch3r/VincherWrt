#!/bin/sh

## fix upload php
phpfix() {
    local php_path="/etc/php.ini"
    [ -f "${php_path}" ] || return 1
    sed -i "s|post_max_size = 8M|post_max_size = 2048M|g" "${php_path}"
    sed -i "s|upload_max_filesize = 2M|upload_max_filesize = 2048M|g" "${php_path}"
}

## fix download index.php
phpindexfix() {
    rm -f /tmp/luci-indexcache
    rm -rf /tmp/luci-modulecache/*
    chmod -R 755 /usr/lib/lua/luci/controller/* 2>/dev/null || true
    chmod -R 755 /usr/lib/lua/luci/view/* 2>/dev/null || true
    chmod -R 755 /www/* 2>/dev/null || true
    
    # Link root to tinyfm
    [ ! -L /www/tinyfm/rootfs ] && ln -sf / /www/tinyfm/rootfs 2>/dev/null || true
    
    # Auto-fix download index.php, index.html
    uci set uhttpd.main.ubus_prefix='/ubus'
    uci set uhttpd.main.interpreter='.php=/usr/bin/php-cgi'
    uci add_list uhttpd.main.index_page='cgi-bin/luci'
    uci add_list uhttpd.main.index_page='index.html'
    uci add_list uhttpd.main.index_page='index.php'
    uci commit uhttpd
    /etc/init.d/uhttpd restart 2>/dev/null || true
    
    # Fix php symlink
    [ -d /usr/lib/php8 ] && [ ! -d /usr/lib/php ] && ln -sf /usr/lib/php8 /usr/lib/php
}

## other config
otherconfig() {
    # Set timezone
    uci set system.@system[0].timezone='WIB-7'
    uci set system.@system[0].zonename='Asia/Jakarta'
    uci commit system
    
    # Set Hostname
    uci set system.@system[0].hostname='VincherWrt'
    uci commit system
    
    # Fix luci-app-atinout-mod permissions
    [ -f /usr/bin/luci-app-atinout ] && chmod +x /usr/bin/luci-app-atinout
    [ -f /sbin/set_at_port.sh ] && chmod +x /sbin/set_at_port.sh
    
    # Fix neofetch permissions
    [ -f /bin/neofetch ] && chmod +x /bin/neofetch
    
    # Add auto clearcache crontab
    if [ -f /sbin/clearcache.sh ]; then
        chmod +x /sbin/clearcache.sh
        grep -q "clearcache.sh" /etc/crontabs/root || echo "0 * * * * /sbin/clearcache.sh" >> /etc/crontabs/root
    fi
}

# Run all functions
phpfix
phpindexfix
otherconfig

exit 0