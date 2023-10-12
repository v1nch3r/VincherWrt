#!/bin/sh

## fix upload php
php_path="/etc/php.ini"
phpfix () {
    sed -i "s|post_max_size = 8M|post_max_size = 2048M|g" ${php_path}
    sed -i "s|upload_max_filesize = 2M|upload_max_filesize = 2048M|g" ${php_path}
}

## fix downlad index.php
phpindexfix () {
	rm -f /tmp/luci-indexcache
	rm -f /tmp/luci-modulecache/*
	chmod -R 755 /usr/lib/lua/luci/controller/*
	chmod -R 755 /usr/lib/lua/luci/view/*
	chmod -R 755 /www/*
	chmod -R 755 /www/tinyfm/*
	chmod -R 755 /www/tinyfm/assets/*
	[ ! -d /www/tinyfm/rootfs ] && ln -s / /www/tinyfm/rootfs
	# Autofix download index.php, index.html
	if ! grep -q ".php=/usr/bin/php-cgi" /etc/config/uhttpd; then
		echo -e "  helmilog : system not using php-cgi, patching php config ..."
		logger "  helmilog : system not using php-cgi, patching php config..."
		uci set uhttpd.main.ubus_prefix='/ubus'
		uci set uhttpd.main.interpreter='.php=/usr/bin/php-cgi'
		uci set uhttpd.main.index_page='cgi-bin/luci'
		uci add_list uhttpd.main.index_page='index.html'
		uci add_list uhttpd.main.index_page='index.php'
		uci commit uhttpd
		echo -e "  helmilog : patching system with php configuration done ..."
		echo -e "  helmilog : restarting some apps ..."
		logger "  helmilog : patching system with php configuration done..."
		logger "  helmilog : restarting some apps..."
		/etc/init.d/uhttpd restart
	fi
	[ -d /usr/lib/php8 ] && [ ! -d /usr/lib/php ] && ln -sf /usr/lib/php8 /usr/lib/php
}

## patch ui openclash
clientui_path="/usr/lib/lua/luci/model/cbi/openclash/client.lua"
patchuiopenclash () {
    sed -i "101s|^|-- |" ${clientui_path}
    sed -i "131s|^|-- |" ${clientui_path}
    sed -i "132s|^|-- |" ${clientui_path}
    sed -i "133s|^|-- |" ${clientui_path}
    sed -i "134s|^|-- |" ${clientui_path}
    sed -i "135s|^|-- |" ${clientui_path}
    sed -i "137s|^|-- |" ${clientui_path}
    sed -i "138s|^|-- |" ${clientui_path}
    sed -i "139s|^|-- |" ${clientui_path}
    sed -i "140s|^|-- |" ${clientui_path}
}

## hide header name
headerpath="/usr/lib/lua/luci/view/admin_status/index.htm"
hideheader () {
    sed -i "9d" ${headerpath}
    sed -i "9i <!-- <h2 name=content><%:Status%></h2> -->" ${path}
}

## set interface
setiface () {
    # iface
    uci set network.wan1=interface
    uci set network.wan1.proto='dhcp'
    uci set network.wan1.device='eth1'
    uci set network.wan2=interface
    uci set network.wan2.proto='dhcp'
    uci set network.wan2.device='wwan0'
    uci set network.wan3=interface
    uci set network.wan3.proto='dhcp'
    nuci set network.wan3.device='usb0'
    uci commit network
    
    # firewall
    uci add_list firewall.@zone[1].network='wan1'
uci add_list firewall.@zone[1].network='wan2'
uci add_list firewall.@zone[1].network='wan3'
    uci commit firewall
}

## other config
otherconfig () {
    uci set system.@system[0].timezone='WIB-7'
    uci set system.@system[0].zonename='Asia/Jakarta'

    # Set Hostname to VincherWrt
    uci set system.@system[0].hostname='VincherWrt'
    uci commit system

    # Fix luci-app-atinout-mod
    chmod +x /usr/bin/luci-app-atinout
    chmod +x /sbin/set_at_port.sh

    # Fix neofetch Permissions
    chmod +x /bin/neofetch

    # Add auto clearcache crontabs
    chmod +x /sbin/clearcache.sh
    echo "0 * * * * /sbin/clearcache.sh" >> /etc/crontabs/root
}

phpfix
phpindexfix
patchuiopenclash
hideheader
setiface
otherconfig

exit 0