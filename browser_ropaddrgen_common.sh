ropgadget_patternfinder $1/*exefs/code.bin --script=browser_ropgadget_script --baseaddr=0x100000 --patterntype=sha256
ropgadget_patternfinder $2/webkit.cro --patterntype=sha256 --patterndata=17f19cd8b8896468edbad52b1a47862f432c6f7b119e7f5b2f4458d3a9009795 --patternsha256size=0x8 "--plainout=\$ROP_STR_R0TOR1 = \$WEBKITCRO_MAPADR+"
echo -n -e "\n"
