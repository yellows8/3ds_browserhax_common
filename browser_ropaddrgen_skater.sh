./browser_ropaddrgen_common.sh $1
ropgadget_patternfinder $1/*exefs/code.bin --script=browser_ropgadget_script_skaterext --baseaddr=0x100000 --patterntype=sha256
