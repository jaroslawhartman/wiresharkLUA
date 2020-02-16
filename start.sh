#!/usr/bin/env bash

TSHARK='/Users/jhartman/Tools/Internet/Wireshark/Wireshark.app/Contents/MacOS/tshark'
INPUT='/Users/jhartman/Documents/Documents/Oracle/Telia/!Local/Logs and config/Diameter/!Production/spikes - 2020-02-03/dgw-spikes-tr001prdgw11.snoop'

$TSHARK -r "$INPUT" -X lua_script:reportingReason-gui.lua -w /dev/null