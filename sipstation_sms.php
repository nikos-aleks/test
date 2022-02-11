#!/usr/bin/php -q
<?php
//	License for all code of this FreePBX module can be found in the license file inside the module directory
//	Copyright 2013 Schmooze Com Inc.
//

// Bootstrap FreePBX but don't include any modules (so you won't get anything
// from the functions.inc.php files of all the modules.)
//
$restrict_mods = true;
if (!@include_once(getenv('FREEPBX_CONF') ? getenv('FREEPBX_CONF') : '/etc/freepbx.conf')) {
	include_once('/etc/asterisk/freepbx.conf');
}

// Connect to AGI:
//
require_once "phpagi.php";

global $astman;

$AGI = new AGI();
$action	= strtoupper(trim($argv[1]));

global $db;
global $astman;

$from_raw = get_var('MESSAGE(from)');
$to_raw = get_var('MESSAGE(to)');
$body = get_var('MESSAGE(body)');

$matches = array();
if(!preg_match('/^.*sip:\+?(\d*)@.*$/', $from_raw, $matches)) {
	agi_verbose("Unable to parse $from_raw");
	return;
}
$from = formatNumber($matches[1]);

preg_match('/^"(.*)".*$/', $from_raw, $match);
if (isset($match[1]) && trim($match[1]) != "") {
	$cnam = $match[1];
} else {
	$cnam = null;
}

$matches = array();
if(!preg_match('/^.*sip:\+?(\d*)@.*$/', $to_raw, $matches)) {
	agi_verbose("Unable to parse $to_raw");
	return;
}
$to = formatNumber($matches[1]);

$adaptor = FreePBX::Sms()->getAdaptor($to);
if(!is_object($adaptor) || !is_a($adaptor, 'FreePBX\modules\Sipstation\sms\SipstationSMS')) {
	agi_verbose("$to is not owned by SIPStation, returning");
	return;
}
try {
	if($adaptor->getMessage($to,$from,$cnam,$body)) {
		$status = 'SUCCESS';
	} else {
		$status = 'FAILURE';
	}
} catch(\Exception $e) {
	$status = $e->getMessage();
}
agi_verbose("SMS RESULT: $status");
// helper functions
//

function get_var($var) {
	global $AGI;
	$r = $AGI->get_variable($var);

	if ($r['result'] == 1) {
		$result = $r['data'];
		return $result;
	} else
		return '';
}

function agi_verbose($string, $level=3) {
	global $AGI;
	$AGI->verbose($string, $level);
}

function formatNumber($number) {
		if(strlen($number) == 10) {
			$number = '1'.$number;
		}
		return $number;
}
