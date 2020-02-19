#!/usr/bin/env bash

# ZeroBrane IDE for remote debugging

export ZBS=/Users/jhartman/Tools/Utilities/Developing/ZeroBraneStudio.app/Contents/ZeroBraneStudio
export LUA_PATH="./?.lua;$ZBS/lualibs/?/?.lua;$ZBS/lualibs/?.lua;$ZBS/../lualibs/moddebug/?.lua"
export LUA_CPATH="$ZBS/bin/?.so;$ZBS/bin/clibs52/?.so;$ZBS/bin/?.dylib;$ZBS/bin/clibs52/?.dylib"

TSHARK='/Users/jhartman/Tools/Internet/Wireshark/Wireshark.app/Contents/MacOS/tshark'
INPUT="/Users/jhartman/Documents/Documents/Oracle/Telia/!Local/Logs and config/Diameter/!Production/spikes - 2020-02-03/Diameter-tr001prdgw12-20200207133306-filtered.pcap"

if [[ -f ~/.local/lib/wireshark/plugins/reportingReason-gui.lua ]]
then
    rm ~/.local/lib/wireshark/plugins/reportingReason-gui.lua
    REINSTALL_PLUGIN=y
fi

$TSHARK -d tcp.port==3868,diameter -r "$INPUT" -X lua_script:extractDCCA.lua -w /dev/null

if [[ -n "$REINSTALL_PLUGIN" ]]
then
    ln -s /Users/jhartman/Documents/GitHub/wiresharkLUA/reportingReason-gui.lua ~/.local/lib/wireshark/plugins/reportingReason-gui.lua
fi