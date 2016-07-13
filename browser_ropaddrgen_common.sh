titledir=$1
crodir=$2
curlprefix=$3
procname=$4
serveradr=$5

function getimport
{
	offset=$(ctrtool-plutoo --intype=cro $crodir/$1 | grep -w -A 2 $2 | tail -n 1 | cut "-d=" -f2 | cut "-d " -f1)
	echo "${3}0x${offset}-0x4;"
}

function getexport
{
	offset=$(ctrtool-plutoo --intype=cro $crodir/$1 | grep -w -A 1 $2 | tail -n 1 | cut "-d " -f3)
	echo "${3}${offset};"
}

if [ $# -ge 5 ]; then
	textmaxsize=$(grep -h "Code text max pages" $1/00*.info | cut "-d(" -f2 | cut "-d)" -f1)
	romaxsize=$(grep -h "Code ro max pages" $1/00*.info | cut "-d(" -f2 | cut "-d)" -f1)
	datamaxsize=$(grep -h "Code data size" $1/00*.info | cut "-d:" -f2 | tr -s " " | cut "-d " -f2)
	bsssize=$(grep -h "Code bss size" $1/00*.info | cut "-d:" -f2 | tr -d " ")
	echo "\$CODEBLK_ENDADR = ((0x00100000 + $textmaxsize + $romaxsize + $datamaxsize + ${bsssize}) + 0xfff) & ~0xfff;"

	physaddr=$(3dshaxclient --serveradr=$serveradr "--customcmd=getprocinfo:addrconv $procname 0x08000000" | grep Output | cut "-d " -f2)
	memdump_path=${procname}_x08000000.bin
	3dshaxclient --serveradr=$serveradr "--customcmd=readmem:11usr=$procname 0x08000000 0x800000 @$memdump_path" > ${procname}_x08000000_toolstdout
	ropgadget_patternfinder $memdump_path --patterntype=datacmp --patterndata=$(xxd -l 32 -p $crodir/oss.cro) --patternsha256size=0x20 --baseaddr=0x08000000 "--plainout=\$OSSCRO_HEAPADR = " "--plainsuffix=;"
	ropgadget_patternfinder $memdump_path --patterntype=datacmp --patterndata=$(xxd -l 32 -p $crodir/webkit.cro) --patternsha256size=0x20 --baseaddr=0x08000000 "--plainout=\$WEBKITCRO_HEAPADR = " "--plainsuffix=;"
	if [[ -f $crodir/peer.cro ]]; then
		ropgadget_patternfinder $memdump_path --patterntype=datacmp --patterndata=$(xxd -l 32 -p $crodir/peer.cro) --patternsha256size=0x20 --baseaddr=0x08000000 "--plainout=\$PEERCRO_HEAPADR = " "--plainsuffix=;"
	fi
	echo "\$APPHEAP_PHYSADDR = $physaddr;"

	echo -e "init_mapaddrs_cro();\n"
fi

ropgadget_patternfinder $titledir/*exefs/code.bin --script=browser_ropgadget_script --baseaddr=0x100000 --patterntype=sha256 "--plainsuffix=;" --disablelocatehalt
ropgadget_patternfinder $crodir/webkit.cro --patterntype=sha256 --patterndata=17f19cd8b8896468edbad52b1a47862f432c6f7b119e7f5b2f4458d3a9009795 --patternsha256size=0x8 "--plainout=\$ROP_STR_R0TOR1 = \$WEBKITCRO_MAPADR+" "--plainsuffix=;"
echo -n -e "\n"
getimport oss.cro wkc_fopen "\$WKC_FOPEN = \$OSSCRO_MAPADR+"
getimport oss.cro wkc_fclose "\$WKC_FCLOSE = \$OSSCRO_MAPADR+"
getimport oss.cro wkc_fread "\$WKC_FREAD = \$OSSCRO_MAPADR+"
getimport oss.cro wkc_fwrite "\$WKC_FWRITE = \$OSSCRO_MAPADR+"
if [[ -f $crodir/peer.cro ]]; then
	getexport peer.cro wkc_fseek "\$WKC_FSEEK = \$PEERCRO_MAPADR+"
else
	getimport oss.cro wkc_fseek "\$WKC_FSEEK = \$OSSCRO_MAPADR+"
fi
echo -n -e "\n"
getimport webkit.cro ${curlprefix}curl_easy_cleanup "\$ROP_curl_easy_cleanup = \$WEBKITCRO_MAPADR+"
getimport webkit.cro ${curlprefix}curl_easy_init "\$ROP_curl_easy_init = \$WEBKITCRO_MAPADR+"
getimport webkit.cro ${curlprefix}curl_easy_perform "\$ROP_curl_easy_perform = \$WEBKITCRO_MAPADR+"
getimport webkit.cro ${curlprefix}curl_easy_setopt "\$ROP_curl_easy_setopt = \$WEBKITCRO_MAPADR+"
echo -n -e "\n"
getimport webkit.cro __aeabi_memcpy "\$ROP_MEMCPY = \$WEBKITCRO_MAPADR+"
getimport webkit.cro __aeabi_memclr4 "\$ROP_MEMSETOTHER = \$WEBKITCRO_MAPADR+"
echo -n -e "\n"
getimport oss.cro __2snprintf "\$ROP_snprintf = \$OSSCRO_MAPADR+"
echo -n -e "\n"

