This repo is for intended for any 3DS title which has some form of web browser. This repo is for generating ROP-chains for use with the previously mentioned targets: no browser exploit(s) are contained in this repo. Browser exploits seperate from this repo can use this for the actual ROP-chain + any required ROP gadgets etc.

# Supported titles and versions
The versions below are listed in the following format: browserver titlever sysver.

Old3DS system Internet Browser(spider) (see also http://3dbrew.org/wiki/Internet_Browser#User-Agent_and_Browser_Versions_2):
* 1.7498 v2050/4.0.0-7
* 1.7552 v3075/5.0.0-11 / v3088/7.0.0-13 (v3088 main ncch is the same as v3075, only the manual CFA was updated)
* 1.7567 v4096/7.1.0-16
* 1.7585 v5121/9.5.0-23
* TODO: Implement support for system-version >=v9.9 with spider.

New3DS system Internet Browser(SKATER) (see also http://3dbrew.org/wiki/Internet_Browser#User-Agent_and_Browser_Versions):
* 1.0.9934 v10 9.0.0-20
* 1.1.9996 v1027 9.3.0-21
* TODO: Implement support for system-version >=v9.6/v9.9 with SKATER.

# Usage with seperate exploits
With php, this repo can be used with the following:
* Include config based on browserhax_cfg_example.php, see that file for details. Include 3dsbrowserhax_common.php.
* Set the global $ROPHEAP variable to an address under the process which the ROP-chain can use for storing arbitrary data(for example, this could be memory where data was sprayed for non-ROP-chain data, since that data isn't needed anymore at this point).
* Call generate_ropchain().
* The ROP-chain data can now be used for generating the final html/js, for example: "var ropchain = unescape($ROPCHAIN);"

# Configuration
See above regarding the cfg file.

By default, when $ropchainselect wasn't initialized by browserhaxcfg_handle_urlparams(), it will set $ropchainselect to value0 and $arm11code_loadfromsd to value2. When this is with a spider version prior to system-version v7.1, $ropchainselect will be set to value1. Next, regardless of browser-version, it then calls browserhaxcfg_handledefault().

Values for $ropchainselect:
* 0: This "ROP-chain" is just an address for THROW_FATALERR. Hence, throw_fatalerr() will be triggered when the above browserhaxcfg_handledefault() path is executed when browserhaxcfg_handledefault() doesn't initialize $ropchainselect.
* 1: <=v4.x arm9hax also implemented by oot3dhax(https://github.com/yellows8/oot3dhax) under EXECHAX=3, see 3dsbrowserhax_common.php generateropchain_type1().
* 2: ARM11-code loading via gspwn, see $arm11code_loadfromsd below. The payload should be position-independent-code without any GOT, since the payload is loaded to R-X memory where the address varies per title version. The payload is called with r0 set to an address of a structure mainly containing funcptrs for various functions in the process, see generateropchain_type2(). At the start of this ROP-chain, the sub-screen colorfill is set to display yellow, at the end it's set to display white.
* 3: Read the contents of a file then dump it to SD. This uses OPENFILEDIRECTLY. 3dsbrowserhax_common.php must be modified in order to use this, see generateropchain_type3(). At the start of this ROP-chain, the sub-screen colorfill is set to display red, at the end it's set to display blue.
* 4: This uses the service-access-control bypass fixed with system-version v7.0, then it uses NSS:RebootSystem. This can be used for region-free on system-versions below v7.0. This was originally implemented a while after the regionfree method with NSS:RebootSystem was originally discovered: http://3dbrew.org/wiki/3DS_System_Flaws#Standalone_Sysmodules

Values for $arm11code_loadfromsd:
* 0: The arm11code payload is embedded in the ROP-chain data itself.
* 1: The arm11code payload is loaded from SD via this filepath: "sdmc:/arm11code.bin".
* 2: The arm11code payload is downloaded by requesting a binary with http, see the above example config and ropgen_httpdownload_binary() in 3dsbrowserhax_common.php. The binary is downloaded to SD, once it's finished with that the file has all-zeros written to it, then it attempts to delete the file(which doesn't actually delete the file, unknown why).

