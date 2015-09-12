titledir=$1
crodir=$2

function getimport
{
	offset=$(ctrtool-plutoo --intype=cro $crodir/$1 | grep -w -A 2 $2 | tail -n 1 | cut "-d=" -f2 | cut "-d " -f1)
	echo "${3}0x${offset}-0x4;"
}

ropgadget_patternfinder $titledir/*exefs/code.bin --script=browser_ropgadget_script --baseaddr=0x100000 --patterntype=sha256
ropgadget_patternfinder $crodir/webkit.cro --patterntype=sha256 --patterndata=17f19cd8b8896468edbad52b1a47862f432c6f7b119e7f5b2f4458d3a9009795 --patternsha256size=0x8 "--plainout=\$ROP_STR_R0TOR1 = \$WEBKITCRO_MAPADR+"
echo -n -e "\n"
getimport webkit.cro __aeabi_memcpy "\$ROP_MEMCPY = \$WEBKITCRO_MAPADR+"
getimport webkit.cro __aeabi_memclr4 "\$ROP_MEMSETOTHER = \$WEBKITCRO_MAPADR+"
echo -n -e "\n"
