
\#!/bin/bash

echo "===================================="
echo "   ADB Wireless Pairing Assistant"
echo "===================================="
echo ""
echo "On your phone:"
echo "Settings → System → Developer options → Wireless debugging"
echo "Tap: 'Pair device with pairing code'"
echo ""
read -p "Enter pairing IP:PORT (example 192.168.1.13:41237): " PAIRIP
echo ""
adb pair "$PAIRIP"



