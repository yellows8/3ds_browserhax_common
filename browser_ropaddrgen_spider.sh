./browser_ropaddrgen_common.sh $1 $1/*romfs/cro
ropgadget_patternfinder $1/*exefs/code.bin --script=browser_ropgadget_script_spiderext --baseaddr=0x100000 --patterntype=sha256
