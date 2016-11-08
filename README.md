This repo is for intended for any 3DS title which has some form of web browser. This repo is for generating ROP-chains for use with the previously mentioned targets: no browser exploit(s) are contained in this repo. Browser exploits seperate from this repo can use this for the actual ROP-chain + any required ROP gadgets etc.

# Supported titles and versions
The versions below are listed in the following format: browserver titlever sysver. Which browserver(target title + version of the title) to use is automatically determined by checking the user-agent. Due to this, when accessing hax with this, the New3DS system web-browser must be set to use the normal user-agent, not the mobile user-agent(the mobile user-agent is the same for all versions).

Also note that with the system web-browser, only the last number in the system-version(X.X.X-NUPVER) actually matters for the browser version. Loading arm11code with the Old3DS browser is only supported with >=v5.0 NATIVE_FIRM, if you want to use pre-v5.0 NATIVE_FIRM with this you would have to modify the source. Normally doing so isn't needed since the \*hax payloads don't support system-versions that old anyway.

Only the USA, EUR, and JPN browsers are supported(with the exception listed below): the main ExeFS codebin are all identical for these regions, unlike the other regions.

Note that for CHN and TWN the loader(with 3ds_arm11code_chntwn.s) is broken(the menustub fails to auto-locate APT_GetServHandle due to older homemenu/ctrsdk code).

Old3DS system Internet Browser(spider) (see also http://3dbrew.org/wiki/Internet_Browser#User-Agent_and_Browser_Versions_2):
* 1.7412 v6    2.0.0-2..2.1.0-3
* 1.7455 v1024 2.1.0-4..3.0.0-6
* 1.7498 v2050 4.0.0-7..4.5.0-10
* 1.7538 v0    4.2.0-9..4.5.0-10 This is the first version of the CHN+KOR (and probably TWN) browser. This is supported for CHN and KOR.
* 1.7552 v3075 5.0.0-11 / v3088/7.0.0-13 (v3088 main ncch is the same as v3075, only the manual CFA was updated) (that is, 5.0.0-11..7.0.0-13)
* 1.7567 v4096 7.1.0-16..9.5.0-22
* 1.7585 v5121 9.5.0-23..9.8.0-25
* 1.7610 v6149 9.9.0-26..10.1.0-27 CHN, KOR, and TWN are also supported for this.
* 1.7616 v7168 10.2.0-28..10.5.0-30 CHN, KOR, and TWN are also supported for this.
* 1.7622 v8192 10.6.0-31 CHN, KOR, and TWN are also supported for this.
* 1.7625 v9232 10.7.0-32..11.0.0-33 CHN, KOR, and TWN are also supported for this. Handled the same way as 1.7622.
* 1.7630 v10240 11.1.0-34

New3DS system Internet Browser(SKATER) (see also http://3dbrew.org/wiki/Internet_Browser#User-Agent_and_Browser_Versions):
* 1.0.9934 v10    9.0.0-20..9.2.0-20
* 1.1.9996 v1027  9.3.0-21..9.5.0-23
* 1.2.10085 v2051 9.6.0-24..9.8.0-25
* 1.3.10126 v3077 9.9.0-26..10.1.0-27 KOR is also supported for this.
* 1.4.10138 v4096 10.2.0-28..10.3.0-28 KOR is also supported for this.
* 1.5.10143 v5121 10.4.0-29..10.5.0-30 KOR is also supported for this.
* 1.6.10147 v6144 10.6.0-31 KOR is "supported" for this but it's not tested.
* 1.7.10150 v7184 10.7.0-32..11.0.0-33 KOR is also supported for this.
* 1.8.10156 v8192 11.1.0-34

# Exploit testing
If you want to test a browser exploit on an unsupported browser version just to see if it at least crashes, you can use this: "URL?browserver={ver}". Where ver is one of the browservers listed in 3dsbrowserhax_common.php, such as "85" for New3DS or "7" for Old3DS(without quotes), or whatever versions the exploit page supports.

# Usage with seperate exploits
With php, this repo can be used with the following:
* Include config based on browserhax_cfg_example.php, see that file for details. Include 3dsbrowserhax_common.php.
* Set the global $ROPHEAP variable to an address under the process which the ROP-chain can use for storing arbitrary data(for example, this could be memory where data was sprayed for non-ROP-chain data, since that data isn't needed anymore at this point).
* Call generate_ropchain(). This generates a ROP-chain which can be included in JS via the $ROPCHAIN global variable. To generate a binary-only ROP-chain instead, set the $generatebinrop global variable to value 1 before calling generate_ropchain().
* The ROP-chain data can now be used for generating the final html/js, for example: "var ropchain = unescape($ROPCHAIN);"
* This can be used before the above ROP-chain data, for use as a ROP NOP-sled: "unescape($NOPSLEDROP);"
* This can be used for spraying the stack-pivot gadget address, like for vtable funcptrs: "unescape($STACKPIVOT);"
* This can be used when the exploit requires using the "pop {pc}" gadget: "$somestr.= genu32_unicode($POPPC);"

# Configuration
See above regarding the cfg file.

By default, when $ropchainselect wasn't initialized by browserhaxcfg_handle_urlparams(), it will set $ropchainselect to value0 and $arm11code_loadfromsd to value2. When this is with a spider version prior to system-version v7.1, $ropchainselect will be set to value1. Next, regardless of browser-version, it then calls browserhaxcfg_handledefault().

Values for $ropchainselect:
* 0: This "ROP-chain" is just an address for THROW_FATALERR. Hence, throw_fatalerr() will be triggered when the above browserhaxcfg_handledefault() path is executed when browserhaxcfg_handledefault() doesn't initialize $ropchainselect.
* 1: <=v4.x arm9hax also implemented by oot3dhax(https://github.com/yellows8/oot3dhax) under EXECHAX=3, see 3dsbrowserhax_common.php generateropchain_type1().
* 2: ARM11-code loading via gspwn, see $arm11code_loadfromsd below. The payload should be position-independent-code without any GOT, since the payload is loaded to R-X memory where the address varies per title version. The payload is called with r0 set to an address of a structure mainly containing funcptrs for various functions in the process, see generateropchain_type2(). r1 is initialized too for a relocated stack address if the payload needs it. The max payload filesize is 0x8000-bytes. At the start of this ROP-chain, the sub-screen colorfill is set to display yellow, at the end it's set to display gray.
* 3: Read the contents of a file then dump it to SD. This uses OPENFILEDIRECTLY. 3dsbrowserhax_common.php must be modified in order to use this, see generateropchain_type3(). At the start of this ROP-chain, the sub-screen colorfill is set to display red, at the end it's set to display blue.
* 4: This uses the service-access-control bypass fixed with system-version v7.0, then it uses NSS:RebootSystem. This can be used for region-free on system-versions below v7.0. This was originally implemented a while after the regionfree method with NSS:RebootSystem was originally discovered: http://3dbrew.org/wiki/3DS_System_Flaws#Standalone_Sysmodules

Values for $arm11code_loadfromsd:
* 0: The arm11code payload is embedded in the ROP-chain data itself.
* 1: The arm11code payload is loaded from SD via this filepath: "sdmc:/arm11code.bin".
* 2: The arm11code payload is downloaded by requesting a binary with http, see the above example config and ropgen_httpdownload_binary() in 3dsbrowserhax_common.php. The binary is downloaded to SD, once it's finished with that the file has all-zeros written to it, then it attempts to delete the file(which doesn't actually delete the file, unknown why).

# Browserhax usage info
How each exploit is triggered depends on the exploit, see the documentation for the seperate exploit for that. As said below, just triggering the exploit successfully is all that's really needed besides SD "/boot.3dsx".

3DS Webkit exploits can be quite unstable. When a webkit exploit is *very* unstable, formatting the browser savedata is recommended if you haven't done so before with the current exploit URL. If you want, from hblauncher-payload booted via browserhax you could install exploit(s) listed here: http://3dbrew.org/wiki/Homebrew_Exploits

You can have the browser auto-load the exploit page if you return to Home Menu from that page. For exploits which automatically trigger, you may have to disable wifi/etc before attempting to load the page in order to return to Home Menu successfully before the exploit actually triggers.

# Homebrew Launcher
This codebase is mainly intended for loading an arbitrary arm11code payload, at a vaddr which varies per title/version. Homebrew-launcher can be booted via this arm11code payload, with the loader included with this repo. The spider version of this loader automatically locates the required addresses and such on-the-fly. The New3DS web-browser is supported by this too, without anything that's system-version/region specific(besides the data loaded from the payload). The loader determines whether it's running under spider or SKATER by checking the New3DS flag loaded via NS(command 0x01020000 http://3dbrew.org/wiki/NS_and_APT_Services). Therefore, do not use this payload on Old3DS outside of spider, and on New3DS do not use this loader outside of SKATER.

In some cases on Old3DS, a crash/"hang" may occur with an orange or white bottom-screen. If it ever returns to Home Menu when the bottom-screen was orange, then a reboot is *required*.

This loader will initially try to load the hblauncher ropbin payload from SD-card "/browserhax_hblauncher_ropbin_payload.bin". This is separate from the otherapp payload.  
If loading from SD fails, this loader will then automatically detect the required payload, then download it with HTTP. This latter method is highly recommended(unless this method doesn't work well for the user): with a "/boot.3dsx" on SD card, there's zero other setup/user-input needed once the browserhax is triggered successfully.  
When loading the payload with both of the above methods fails, a crash will be triggered.

Hanging/crashing at an gray-bottom-screen means \*hax payload loading failed, normally this is due to network issues(you should reboot your system when this happens).

The loader for Old3DS runs actual native code under the context of Home Menu, if you really want to run your own code under Home Menu you can modify that code in the loader. This code runs very early in the Home Menu process boot.

# Screen colors
When using browserhax the bottom-screen colorfill will be set to various colors in the following order:
* 1) Yellow: Browser ROP started running, this also means the *exploit* *itself* worked fine.
* 2) Gray: This colorfill is set right before jumping to the initial arm11code binary, for running native code for the first time.
* 3) Orange: This is set after the \*hax payload was successfully loaded into memory via HTTP/SD.
* 4) White: This is set by the \*hax payload itself when it starts running.

# Credits
* megazig for helping with APT(for APT stuff once the Home Menu code in the loader starts running) during the initial + eventually successful Old3DS Home Menu takeover implementation.

