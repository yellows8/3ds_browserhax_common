./browser_ropaddrgen_common.sh $1 $1/*romfs/cro "" spider $2
ropgadget_patternfinder $1/*exefs/code.bin --script=browser_ropgadget_script_spiderext --baseaddr=0x100000 --patterntype=sha256 "--plainsuffix=;"
