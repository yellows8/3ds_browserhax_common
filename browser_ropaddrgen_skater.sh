./browser_ropaddrgen_common.sh $1
ropgadget_patternfinder $1/*exefs/code.bin --script=browser_ropgadget_script_skaterext --baseaddr=0x100000 --patterntype=sha256
echo -n -e "\n"
ropgadget_patternfinder $1/peer.cro --baseaddr=0x7 --patterntype=sha256 --patterndata=6279580b19de16e57488d944436459e2dfbc8b35d704f371bc5fcec660aa4a6c --patternsha256size=0xe --stride=0x2 "--plainout=\$ROP_STMR0_R0PC = \$PEERCRO_MAPADR+"
