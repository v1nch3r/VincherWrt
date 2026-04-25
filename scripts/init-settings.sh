#!/bin/sh

## other config
otherconfig() {
    # Set timezone
    uci set system.@system[0].timezone='WIB-7'
    uci set system.@system[0].zonename='Asia/Jakarta'
    uci commit system
    
    # Set Hostname
    uci set system.@system[0].hostname='VincherWrt'
    uci commit system
}

# Run
otherconfig

exit 0