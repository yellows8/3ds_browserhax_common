echo -e "<?php\n"

./browser_ropaddrgen_common.sh $1 $1/*romfs/cro "" spider $2
ropgadget_patternfinder $1/*exefs/code.bin --script=browser_ropgadget_script_spiderext --baseaddr=0x100000 --patterntype=sha256 "--plainsuffix=;" --disablelocatehalt
echo -n -e "\n"
ropgadget_patternfinder $1/*romfs/cro/webkit.cro --patterntype=sha256 --patterndata=5c8d43feb12e99ae542558d85328f2372ab5949bf74db40c36b20a51abf4e01c --patternsha256size=0x20 "--plainout=\$ROP_LDRR0R4_LDRR0_R0OFF4_LDRR0_R0OFF34_OBJVTABLECALL_5C_POPR4LR = \$WEBKITCRO_MAPADR+" "--plainsuffix=;"

echo -e -n "\n?>"

