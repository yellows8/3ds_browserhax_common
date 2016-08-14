<?php

function browserhaxcfg_handle_urlparams()
{
	global $ropchainparam, $ropchainselect, $arm11code_loadfromsd;

	//From here one can initialize $ropchainselect and $arm11code_loadfromsd by optionally checking the value of $ropchainparam which comes from URL param "rop".
}

function browserhaxcfg_handledefault()
{
	global $ropchainselect, $arm11code_loadfromsd;

	//This is the main config init function: from here one can initialize $ropchainselect and $arm11code_loadfromsd.
}

function browserhaxcfg_getbinparam_type3()
{
	//Return a string for the value of the "getbin" URL param for use with $getbinselect value3, which is used by browserhaxcfg_parsebinparam(). This is also the getbin URL param value used by the ROP generation code in 3dsbrowserhax_common.php for generating the arm11code payload URL(when $arm11code_loadfromsd is value 2). This is just an ID, the value doesn't matter(on the host server this is just a random ASCII string).
	return "<someid>";
}

function browserhaxcfg_parsebinparam()
{
	global $getbinparam, $getbinselect;

	//This parses $getbinparam which comes from the "getbin" URL param, and initializes $getbinselect when matching value(s) for $getbinparam are found.

	if($getbinparam==browserhaxcfg_getbinparam_type3())
	{
		$getbinselect = 3;//3dsbrowserhax_common.php only uses $getbinselect value3 currently.
	}
}

function browserhaxcfg_getbinpath_val3()
{
	//Return a filepath string which will be loaded by 3dsbrowserhax_common.php itself, when a binary is requested via the "getbin" URL param with the $getbinselect variable set to value 3 (see browserhaxcfg_parsebinparam). This should be the built 3ds_arm11code.bin from running 'make'.
	return "<somefilepath>";
}

function browserhaxcfg_getbinpath_ropchain2()
{
	//Return a filepath string which will be loaded by 3dsbrowserhax_common.php itself, for loading arm11code which will be embedded in the ROP when $arm11code_loadfromsd==0. With the normal configuration this isn't used.
	return "<somefilepath>";
}

?>
