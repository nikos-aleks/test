<?php
include 'phpagi.php';
class Dir{
	//agi class handler
	public $agi;
	//inital agi pased variables
	public $agivar;
	//pear::db database object handel
	public $db;
	//options of the directory that we are currently working with
	public $dir;
	//the current directory that we are working with
	public $directory;
	//string we are searching for
	public $searchstring;
	//voicemail base directory
	public $vmbasedir = '';

	// determine if annoucement is default so we can choose whether or not to play the
	// "welcome-to-the-directory" recording
	public $default_annoucement = false;

	//this function is run by php automatically when the class is initalized
	public function __construct(){
		global $db;
		$this->agi = $this->construct_agi();
		$this->db = $db;
		$this->directory = $this->agivar['dir'];
		$this->dir = $this->construct_dir_opts();
	}

	//get agi handel/inital agi vars, called by __construct()
	private function construct_agi(){
		$agi = new AGI();
		foreach($agi->request as $key => $value){//strip agi_ prefix from keys
			if(substr($key,0,4) == 'agi_'){
				$opts[substr($key,4)] = $value;
			}
		}

		foreach($opts as $key => $value){//get passed in vars
			if(substr($key,0,4) == 'arg_'){
				$expld=explode('=',$value);
				$opts[$expld[0]] = $expld[1];
				unset($opts[$key]);
			}
		}

		array_shift($_SERVER['argv']);
		foreach($_SERVER['argv'] as $arg){
			$arg=explode('=',$arg);
			//remove leading '--'
			if(substr($arg['0'],0,2) == '--'){$arg['0']=substr($arg['0'],2);}
			$opts[$arg['0']]=isset($arg['1'])?$arg['1']:null;
		}
		$this->agivar=$opts;
		return $agi;
	}

	//get options associated with the current dir
	// TODO: handle getRow failures
	private function construct_dir_opts(){
		$sql='SELECT * FROM directory_details WHERE ID = ?';
		$row=$this->db->getRow($sql,array($this->directory),DB_FETCHMODE_ASSOC);
		//TODO: Error Checking

		$this->default_annoucement = $row['announcement'] === '0' ? true : false;

		// If any non-defaults (non-zero id) then lookup files
		//
		if ($row['announcement'] || $row['repeat_recording'] || $row['invalid_recording']) {
			$sql='SELECT id, filename from recordings where id in ('.$row['announcement'].','.$row['repeat_recording'].','.$row['invalid_recording'].')';
			$res=$this->db->getAll($sql,DB_FETCHMODE_ASSOC);
			if(DB::IsError($res)) {
				dbug("FATAL: got error from getAll query",1);
				dbug($res->getDebugInfo());
			}
			$rec_file = array();
			foreach ($res as $entry) {
				//TODO: check if file exists, which means splitting on & and checkking all
				$rec_file[$entry['id']] = $entry['filename'];
			}
			unset($res);
		}
		$row['announcement'] = $row['announcement']&&isset($rec_file[$row['announcement']])?$rec_file[$row['announcement']]:'cdir-please-enter-first-three';
		$row['repeat_recording'] = $row['repeat_recording']&&isset($rec_file[$row['repeat_recording']])?$rec_file[$row['repeat_recording']]:'cdir-sorry-no-entries';
		$row['invalid_recording'] = $row['invalid_recording']&&isset($rec_file[$row['invalid_recording']])?$rec_file[$row['invalid_recording']]:'cdir-transferring-further-assistance';
		return $row;
	}

	public function default_annoucement() {
		return $this->default_annoucement;
	}

	//get a channel varibale
	public function agi_get_var($var){
		global $agi_cache;
		if (isset($agi_cache[$var])) {
			return $agi_cache[$var];
		}
		$ret=$this->agi->get_variable($var);
		if($ret['result']==1){
			$result=$ret['data'];
			$agi_cache[$var] = $result;
			return $result;
		}else{
			return '';
		}
	}

	// Return null on nothing pressed, false on error, otherwise the key
	// TODO: make it so you can pass in an array:
	//
	public function getKeypress($filename, $pressables='', $timeout=2000){
		if (!is_array($filename)) {
			$filename = array($filename);
		}
		foreach ($filename as $chunk) {
			$ret=is_int($chunk)?$this->agi->say_number($chunk,$pressables):$this->agi->stream_file($chunk,$pressables);
			if(!empty($ret['result'])) {break;}
		}
		if(empty($ret['result'])){
			$ret=$this->agi->wait_for_digit($timeout);
		}
		switch ($ret['result']) {
			case 0:
				return null;
			case -1:
				return false;
			default:
				return chr($ret['result']);
		}
	}

	public function readContact($con, $keys='#'){
		switch($con['audio']){
			case 'vm':
				$vm_dir = $this->agi->database_get('AMPUSER',$con['dial'].'/voicemail');
				$vm_dir = $vm_dir['data'];
				dbug('got directory ' . $vm_dir . ' for user ' . $con['dial']);
				//check to see if we have a greet.* and play it. otherwise, try speaking the name

				if ($vm_dir && $vm_dir != 'novm') {
					if (!$this->vmbasedir) {
						$this->vmbasedir = $this->agi_get_var('ASTSPOOLDIR').'/voicemail/';
					}

					$dir=scandir($this->vmbasedir.$vm_dir.'/'.$con['dial']);
					foreach($dir as $file){
						dbug("looking for vm file $file using: ".basename($file),6);
						if(substr($file,0,5) == 'greet' && is_file($this->vmbasedir.$vm_dir.'/'.$con['dial'].'/'.$file)){
							$ret=$this->agi->stream_file($this->vmbasedir.$vm_dir.'/'.$con['dial'].'/greet',$keys);
							if ($ret['result']) {
								$ret['result']=chr($ret['result']);
							}
							break 2;
						}
					}
				}
				//fallthough if not successfull
			case 'tts':
				// speak the name if possible, otherwise move on to spell it
				$temporaryAudioFile = $this->agi_get_var('ASTSPOOLDIR') . '/tmp/directory-tts-' . time() . rand(100, 999);
				system('flite -t "' . escapeshellarg($con['name']) .'" -o ' . $temporaryAudioFile . '.wav', $exitCode);
				if (file_exists($temporaryAudioFile . '.wav') && $exitCode === 0) {
					$ret = $this->agi->stream_file($temporaryAudioFile, $keys);
					$ret['result'] = isset($ret['result']) ? chr($ret['result']) : NULL;
					unlink($temporaryAudioFile . '.wav');
					break;
				} else {
					$ret = array('result' => '');
				}
				//fallthough if not successfull
			case 'spell':
				foreach(str_split(strtolower($this->strip_accent($con['name'])),1) as $char){
					dbug('saying '.$char.' from string '.strtolower($con['name']));
					switch(true){
						case ctype_alpha($char):
							$ret = $this->agi->evaluate('SAY ALPHA '.$char.' '.$keys);
							dbug("returned from SAY ALPHA with code/result {$ret['code']}/{$ret['result']}",6);
							break;
						case ctype_digit($char):
							$ret = $this->agi->say_digits($char, $keys);
							break;
						case ctype_space($char)://pause
							$ret = $this->agi->wait_for_digit(750);
							break;
					}
					if(trim($ret['result'])) {
						$ret['result'] = chr($ret['result']);
						break;
					}
				}
				break;
				//TODO: BUG: hardcoded to Flite, needs to either check what is there or be configurable
				//we dont call the flite app cirectly as it still uses | as a parameter separator

			default:
				if(is_numeric($con['audio'])){
					$sql='SELECT filename from recordings where id = ?';
					$rec=$this->db->getOne($sql, array($con['audio']));
					dbug("got record id: {$con['audio']} file(s): $rec");
					if($rec){
						$rec=explode('&',$rec);
						foreach($rec as $r){
							$ret=$this->agi->stream_file($r,$keys);
							if(trim($ret['result'])){$ret['result']=chr($ret['result']);break;}
						}
					} else {
						//TODO: handle error
						dbug("ERROR: unknown/undefined sound file");
					}
				}
				break;
			}
			return $ret;
		}

	public function search($key,$count=0){
		if($key == ''){return false;}//requre search term

		if(strstr($key,'0') !== false) {
			dbug("user pressed 0 - bailing out");
			$this->bail();
		}

		//the regex in the query will match the searchstring at the beging of the string or after a space
		$num= array('1','2','3','4','5','6','7','8','9','0','#');
		$alph=array("[ \s@,-\!/+=\.']",'[aàâäáãåbcçAÀÂÄÁÃÅBCÇ]','[deéèêëfDEÉÈÊËF]','[ghiîïìíGHIÎÏÌÍ]','[jklJKL]','[mnñoôöòóõøMNÑOÔÖÒÓÕØ]','[pqrsPQRS]','[tuùûüúvTUÙÛÜÚV]','[wxyÿzWXYŸZ]','','');
		$this->searchstring=$this->db->escapeSimple(str_replace($num,$alph,$key));
		dbug("search string for regex: {$this->searchstring}");

		//TODO: check db results for errors and fail gracefully

		$vtable = '(SELECT DISTINCT a.audio, IF(a.name != "",a.name,b.name) name, IF(a.dial != "",a.dial,b.extension) dial FROM directory_entries a LEFT JOIN users b ON a.foreign_id = b.extension WHERE id = "'.$this->directory.'") v';
		if($count==1){
			$sql="SELECT COUNT(*) FROM $vtable WHERE name REGEXP \"(^| ){$this->searchstring}\"";
			$res=$this->db->getOne($sql);
			if(DB::IsError($res)) {
				dbug("FATAL: got error from COUNT(*) query");
				dbug($res->getDebugInfo());
			}
			dbug("Found $res possible matches from $key");
		}else{
			$sql="SELECT * FROM $vtable WHERE name REGEXP \"(^| ){$this->searchstring}\"";
			$res=$this->db->getAll($sql,DB_FETCHMODE_ASSOC);
			if(DB::IsError($res)) {
				dbug("FATAL: got error from getAll query");
				dbug($res->getDebugInfo());
			} else {
				dbug("Found the following matches:");
				foreach ($res as $ent) {
					dbug("name: {$ent['name']}, audio: {$ent['audio']}, dial: {$ent['dial']}");
				}
			}
		}
		return $res;
	}

	public function bail() {
		//do something if we are exiting due to to many tries
		//
		dbug("User pressed zero, passing back recording of {$this->dir['invalid_recording']}");
		$this->agi->set_variable('DIR_INVALID_RECORDING',$this->dir['invalid_recording']);
		if($this->agivar['retivr'] == 'true' && $this->agi_get_var('IVR_CONTEXT')){
			$this->agi->set_extension('retivr');
		}else{//FREEPBX-14810 :Ringer Volume Override and Alert Info is not working under Directory for Invalid Destination
			if($this->dir['alert_info'] != ''){
				$this->agi->set_variable('ALERT_INFO',$this->dir['alert_info']);
			}
		        if(!empty($this->dir['rvolume'])) {
				 $this->agi->set_variable('RVOL',$this->dir['rvolume']);
			}
			if($dir->dir['callid_prefix'] != ''){
				$callid_name = $this->agi->get_variable('CALLERID(name)');
				$this->agi->set_variable('CALLERID(name)',$this->dir['callid_prefix'].$callid_name['data']);
			}

			$dest = explode(',',$this->dir['invalid_destination']);
			$this->agi->set_variable('DIR_INVALID_CONTEXT',$dest['0']);
			$this->agi->set_variable('DIR_INVALID_EXTEN',$dest['1']);
			$this->agi->set_variable('DIR_INVALID_PRI',$dest['2']);
			$this->agi->set_extension('invalid');
		}
		$this->agi->set_priority('1');
		exit;
	}

	public function strip_accent($texte) {
		$texte = str_replace(
			array(
				'à', 'â', 'ä', 'á', 'ã', 'å',
				'î', 'ï', 'ì', 'í',
				'ô', 'ö', 'ò', 'ó', 'õ', 'ø',
				'ù', 'û', 'ü', 'ú',
				'é', 'è', 'ê', 'ë',
				'ç', 'ÿ', 'ñ',
				'À', 'Â', 'Ä', 'Á', 'Ã', 'Å',
				'Î', 'Ï', 'Ì', 'Í',
				'Ô', 'Ö', 'Ò', 'Ó', 'Õ', 'Ø',
				'Ù', 'Û', 'Ü', 'Ú',
				'É', 'È', 'Ê', 'Ë',
				'Ç', 'Ÿ', 'Ñ',
			),
			array(
				'a', 'a', 'a', 'a', 'a', 'a',
				'i', 'i', 'i', 'i',
				'o', 'o', 'o', 'o', 'o', 'o',
				'u', 'u', 'u', 'u',
				'e', 'e', 'e', 'e',
				'c', 'y', 'n',
				'A', 'A', 'A', 'A', 'A', 'A',
				'I', 'I', 'I', 'I',
				'O', 'O', 'O', 'O', 'O', 'O',
				'U', 'U', 'U', 'U',
				'E', 'E', 'E', 'E',
				'C', 'Y', 'N',
			),
			$texte
		);

		return $texte;
	}
}
