#!/usr/bin/env bash

TSHARK='/Users/jhartman/Tools/Internet/Wireshark/Wireshark.app/Contents/MacOS/tshark'
INPUT="/Users/jhartman/Documents/Documents/Oracle/Telia/!Local/Logs and config/Diameter/!Production/spikes - 2020-02-17/dgw-spikes-tr001prdgw11-20200217-02.snoop"
# INPUT="/Users/jhartman/Documents/Documents/Oracle/Telia/!Local/Logs and config/Diameter/!Production/spikes - 2020-02-17/short.pcap"

if [[ -f ~/.local/lib/wireshark/plugins/reportingReason-gui.lua ]]
then
    rm ~/.local/lib/wireshark/plugins/reportingReason-gui.lua
    REINSTALL_PLUGIN=y
fi

$TSHARK -r "$INPUT" -X lua_script:reportingReason-gui.lua -w /dev/null

if [[ -n "$REINSTALL_PLUGIN" ]]
then
    ln -s /Users/jhartman/Documents/GitHub/wiresharkLUA/reportingReason-gui.lua ~/.local/lib/wireshark/plugins/reportingReason-gui.lua
fi