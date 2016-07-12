echo -e "<?php\n"

./browser_ropaddrgen_common.sh $1 $1 wkc_ SKATER $2
ropgadget_patternfinder $1/*exefs/code.bin --script=browser_ropgadget_script_skaterext --baseaddr=0x100000 --patterntype=sha256 "--plainsuffix=;"
echo -n -e "\n"
ropgadget_patternfinder $1/webkit.cro --patterntype=sha256 --patterndata=f3e5d9688528c7d3fc7aa5df10758995a8c1c93e03576514501663672083e3e0 --patternsha256size=0x4 "--plainout=\$ROP_POP_R0IPPC = \$WEBKITCRO_MAPADR+" "--plainsuffix=;"
echo -n -e "\n"
ropgadget_patternfinder $1/oss.cro --patterntype=sha256 --patterndata=e6e33146879a0d0da9c6f0545a467d4ccb80c1a75fc3a28eca14746764ff53c0 --patternsha256size=0x8 "--plainout=\$ROP_LDR_R0_FROMR0_SHIFTR1 = \$OSSCRO_MAPADR+" "--plainsuffix=;"
echo -n -e "\n"
ropgadget_patternfinder $1/peer.cro --baseaddr=0x7 --patterntype=sha256 --patterndata=6279580b19de16e57488d944436459e2dfbc8b35d704f371bc5fcec660aa4a6c --patternsha256size=0xe --stride=0x2 "--plainout=\$ROP_STMR0_R0PC = \$PEERCRO_MAPADR+" "--plainsuffix=;"

echo -e -n "\n?>"
