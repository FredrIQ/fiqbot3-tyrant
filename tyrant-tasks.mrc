on *:START:{
  fiqbot.tyrant.init
}
on *:CONNECT:{
  .timertyranttasks 0 30 fiqbot.tyrant.runinterval
}
alias fiqbot.tyrant.init {
  .timertyranttasks 0 30 fiqbot.tyrant.runinterval
  if (!$hget(socketdata)) {
    hmake socketdata 100
    hadd socketdata nextid 1
  }
  if ($exists(tables\users.fht)) {
    var %hload = fiqbot.tyrant.hload
    %hload users
    %hload factions
    %hload userdata
    %hload wars
    %hload conquest
    return
  }
  if (!$hget(users)) hmake users 1000
  if (!$hget(factions)) {
    hmake factions 100
    hadd factions nextid 1
  }
  if (!$hget(wars)) hmake wars 10
  if (!$hget(conquest)) hmake conquest 1000
}

;Helpers
alias fiqbot.tyrant.version return 2.17.09
alias fiqbot.tyrant.directory return $+($scriptdir,tyrant\)
alias fiqbot.tyrant.trackerchannel return #botfarm
alias fiqbot.tyrant.factionid return %fiqbot_tyrant_fid [ $+ [ %usertarget ] ]
alias fiqbot.tyrant.factionname return %fiqbot_tyrant_fname [ $+ [ %usertarget ] ]
alias fiqbot.tyrant.factionfp return %fiqbot_tyrant_fp [ $+ [ %usertarget ] ]
alias fiqbot.tyrant.duration {
  var %duration = $replace($duration($1),wks,w $+ $chr(44),wk,w $+ $chr(44),days,d $+ $chr(44),day,d $+ $chr(44),hrs,h $+ $chr(44),mins,m $+ $chr(44),secs,s,hr,h $+ $chr(44),min,m $+ $chr(44),sec,s)
  if ($right(%duration,1) == ,) {
    %duration = $left(%duration,-1)
  }
  return %duration
}

alias fiqbot.tyrant.account {
  var %usertarget = %fiqbot_tyrant_factionchannel_ [ $+ [ $1 ] ]
  if (!%usertarget) return 0
  return %fiqbot_tyrant_userid [ $+ [ %usertarget ] ]
}
alias fiqbot.tyrant.cqcoordinates {
  var %x = $1, %y = $2
  var %buffer, %x_result, %y_result
  %x_result = %x
  if (%x) %x_result = $+(%x_result,E)
  %y_result = %y
  if (%y) %y_result = $+(%y_result,S)
  if (%x < 0) %x_result = $+($calc(%x * -1),W)
  if (%y < 0) %y_result = $+($calc(%y * -1),N)
  return $+(%x_result,$chr(44),%y_result)
}
alias fiqbot.tyrant.freelock {
  unset %fiqbot_tyrant_socklock
}
alias fiqbot.tyrant.gainedfp {
  var %ownfp = $1, %fp = $2
  if (%fp < $calc(%ownfp - 299)) return 1
  elseif (%fp < $calc(%ownfp - 199)) return 2
  elseif (%fp < $calc(%ownfp - 99)) return 3
  elseif (%fp < $calc(%ownfp - 33)) return 4
  elseif (%fp < $calc(%ownfp + 34)) return 5
  elseif (%fp < $calc(%ownfp + 100)) return 6
  elseif (%fp < $calc(%ownfp + 200)) return 7
  elseif (%fp < $calc(%ownfp + 300)) return 8
  elseif (%fp < $calc(%ownfp + 500)) return 9
  else return 10
}
alias fiqbot.tyrant.hash {
  var %time_hash, %msg, %time, %userid

  ;This has been intentionally left out to prevent critical info from being seen in public.
  ;I do not endorse botting the game to make the game play for you. By inserting the proper
  ;information here, you agree that I have no responsibility for your use of the code.
  ;You're on your own for finding what you want to insert here.
  %time_hash = TYRANT_STATIC_SALT
  %msg = $1
  %time = $int($2)
  if ($prop == unixreal) {
    %time = $int(%time / 900)
  }
  %userid = $3
  if (($prop == ccache) || ($prop == unixreal.ccache)) {
    return $md5($+(%time,%userid))
  }
  return $md5($+(%msg,%time,%time_hash))
}
alias -l fiqbot.tyrant.setsocketvars {
  var %id = $remove($1,tyranttask)
  set -u0 %sockid %id
  set -u0 %send $hget(socketdata,$+(send,%id))
  set -u0 %user $hget(socketdata,$+(user,%id))
  set -u0 %task $hget(socketdata,$+(task,%id))
  set -u0 %msg $hget(socketdata,$+(msg,%id))
  set -u0 %params $hget(socketdata,$+(params,%id))
  set -u0 %headers_completed $hget(socketdata,$+(headers_completed,%id))
  set -u0 %temp $hget(socketdata,$+(temp,%id))
  set -u0 %tempold $hget(socketdata,$+(tempold,%id))
  set -u0 %access $hget(socketdata,$+(access,%id))
  set -u0 %delay $hget(socketdata,$+(delay,%id))
  set -u0 %bruteforcing $hget(socketdata,$+(bruteforcing,%id))
  set -u0 %noreidentify $hget(socketdata,$+(noreidentify,%id))
  set -u0 %noclientcode $hget(socketdata,$+(noclientcode,%id))
  set -u0 %usertarget $hget(socketdata,$+(usertarget,%id))
  set -u0 %userid %fiqbot_tyrant_userid [ $+ [ %usertarget ] ]
  set -u0 %token %fiqbot_tyrant_token [ $+ [ %usertarget ] ]
  set -u0 %flashcode %fiqbot_tyrant_flashcode [ $+ [ %usertarget ] ]
  set -u0 %clientcode $hget(socketdata,$+(clientcode,%id))

  var %metadata = $hget(socketdata,$+(metadata_,%id))
  var %i = 0
  while (%i < %metadata) {
    inc %i
    if (%i == 50) {
      %send [Bot error] Infinite loop forcibly halted.
      halt
    }
    set -u0 %metadata $+ %i $hget(socketdata,$+(metadata,%i,_,%id))
  }
}
alias fiqbot.tyrant.hload {
  if (!$hget($1)) {
    hmake $1 1000
  }
  var %dir = $+($fiqbot.tyrant.directory,tables\)
  var %file = $+(%dir,$1,.fht)
  if ($exists(%file)) !hload -i $1 %file $1
}
alias fiqbot.tyrant.hsave {
  if (!$hget($1)) return
  var %dir = $+($fiqbot.tyrant.directory,tables\)
  var %file = $+(%dir,$1,.fht)
  .remove %file
  !hsave -oi $1 %file $1
}
;Continous commands
alias fiqbot.tyrant.runinterval {
  inc %interval 1
  fiqbot.tyrant.checkvault
  fiqbot.tyrant.updatefactioninfo
  fiqbot.tyrant.checkconquestmap
  if (!$calc(%interval % 20)) {
    var %hsave = fiqbot.tyrant.hsave
    %hsave users
    %hsave factions
    %hsave userdata
    %hsave wars
    %hsave conquest
    %hsave cards
    %hsave raids

    fiqbot.tyrant.downloadxml cards
  }
}
alias fiqbot.tyrant.updatefactioninfo {
  var %i = 1
  while (%fiqbot_tyrant_userid [ $+ [ %i ] ]) {
    if (%fiqbot_tyrant_fname [ $+ [ %i ] ]) {
      fiqbot.tyrant.checktargets %i
      fiqbot.tyrant.checkwars %i
    }
    inc %i
  }
}

;Socket stuff
alias fiqbot.tyrant.login {
  if (!%send) var %send = echo -s
  if (%bruteforcing) { %send [API error] Clientcode verification in progress, your request has been ignored. | halt }
  var %1 = 1
  if ($1) { %1 = $int($1) }

  set %fiqbot_tyrant_userid %fiqbot_tyrant_userid [ $+ [ %1 ] ]
  set %fiqbot_tyrant_token %fiqbot_tyrant_token [ $+ [ %1 ] ]
  set %fiqbot_tyrant_clientcode %fiqbot_tyrant_clientcode [ $+ [ %1 ] ]
  set %fiqbot_tyrant_flashcode %fiqbot_tyrant_flashcode [ $+ [ %1 ] ]
  if (!%fiqbot_tyrant_userid) {
    %send [API error] Auth info is missing for user %1
    halt
  }
  set -u3 %usertarget %1
  if (!$1) {
    %send [API warning] No user specified. Assuming %fiqbot_tyrant_userid
  }
}
alias fiqbot.tyrant.apiraw {
  set -u0 %task raw
  set -u0 %msg $1
  set -u0 %params $2-
  set -u0 %noreidentify 1
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.apiraw2 {
  set -u0 %task raw2
  set -u0 %msg $1
  set -u0 %params $2-
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.checkconquestmap {
  set -u0 %task checkconquestmap
  set -u0 %msg getConquestMap
  set -u0 %metadata1 2
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.checktargets {
  set -u0 %task checktargets
  fiqbot.tyrant.login $1
  %msg = getFactionRivals
  %params = rating_low=0&rating_high=3000
  fiqbot.tyrant.runsocket
  %params = rating_low=3000&rating_high=0
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.checkvault {
  set -u0 %send echo -s vaultchecking:
  fiqbot.tyrant.login 1
  set -u0 %task checkvault
  set -u0 %msg getMarketInfo
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.checkwars {
  set -u0 %send echo -s warschecking:
  fiqbot.tyrant.login $1
  set -u0 %task checkwars
  set -u0 %msg getActiveFactionWars
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.raidinfo {
  ;syntax: name:users:health:duration
  var %raid0 = No raid:--:-------:--
  var %name, %players, %health, %time
  var %i = 1
  while ($hget(raids,$+(name,%i))) {
    %name = $hget(raids,$+(name,%i))
    %players = $hget(raids,$+(players,%i))
    %health = $hget(raids,$+(health,%i))
    %time = $hget(raids,$+(time,%i))
    var %raid [ $+ [ %i ] ] $+(%name,:,%players,:,%health,:,%time)
    inc %i
  }

  var %1 = $1
  if (!%raid [ $+ [ %1 ] ]) %1 = 0
  var %raid = %raid [ $+ [ %1 ] ]
  if ($2 == name) return $gettok(%raid,1,58)
  if ($2 == users) return $gettok(%raid,2,58)
  if ($2 == health) return $gettok(%raid,3,58)
  if ($2 == duration) return $gettok(%raid,4,58)
  return $gettok(%raid,$2,58)
}
alias fiqbot.tyrant.retrysocket {
  if ($2 == needlock) set -u0 %needlock $true
  fiqbot.tyrant.runsocket $1
}
alias fiqbot.tyrant.runkongsocket {
  ;kill switch in case of mess up
  if ((%user isnum) && (. !isin %user) || ($hget(users,$+(id,%user)))) {
    if ($hget(users,$+(id,%user))) {
      set -u0 %user $hget(users,$+(id,%user))
    }
    set -u0 %params $+(%params,%user)
    fiqbot.tyrant.runsocket
    return
  }
  if (%killsockets) {
    .timers off
    halt
  }
  var %i = 0
  while (%metadata [ $+ [ $calc(%i + 1) ] ]) {
    inc %i
    set -u0 %metadata [ $+ [ $calc(%i + 6) ] ] %metadata [ $+ [ %i ] ]
  }
  if (!%needlock) set -u0 %needlock -1
  if (!%delay) set -u0 %delay -1
  if (!%params) set -u0 %params noparams&
  set -u0 %metadata1 %user
  set -u0 %metadata2 %task
  set -u0 %metadata3 %msg
  set -u0 %metadata4 %params
  set -u0 %metadata5 %needlock
  set -u0 %metadata6 %delay
  unset %needlock
  unset %delay

  set -u0 %task getkongid
  set -u0 %msg queryPlayer

  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.runsocket {
  ;kill switch in case of mess up
  if (%killsockets) {
    .timers off
    halt
  }
  if (!%send) set -u0 %send echo -s no-send:
  if (%needlock == -1) set -u0 %needlock 0
  if (%delay == -1) set -u0 %delay 0

  var %id = $hget(socketdata,nextid)
  if ($1) var %id = $1
  if (!$1) {
    if (!%usertarget) {
      %send [API error] No user data found, failed in runsocket for %msg (task: %task $+ )
      halt
    }
    hinc socketdata nextid
    hadd socketdata $+(send,%id) %send
    hadd socketdata $+(user,%id) %user
    hadd socketdata $+(task,%id) %task
    hadd socketdata $+(msg,%id) %msg
    hadd socketdata $+(params,%id) %params
    hadd socketdata $+(access,%id) %access
    hadd socketdata $+(delay,%id) %delay
    hadd socketdata $+(usertarget,%id) %usertarget
    hadd socketdata $+(bruteforcing,%id) %bruteforcing
    hadd socketdata $+(noreidentify,%id) %noreidentify
    hadd socketdata $+(noclientcode,%id) %noclientcode
    var %i = 1
    while (%metadata [ $+ [ %i ] ]) {
      hadd socketdata $+(metadata_,%id) %i
      hadd socketdata $+(metadata,%i,_,%id) %metadata [ $+ [ %i ] ]
      inc %i
    }
  }
  hadd socketdata $+(clientcode,%id) %fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ]

  var %socket = $+(tyranttask,%id)

  if ((%needlock) && (%fiqbot_tyrant_socklock) && (%fiqbot_tyrant_socklock != %id)) {
    inc %fiqbot_tyrant_socklock_count
    if (%fiqbot_tyrant_socklock_count > 30) {
      %send Error: A request took too long, or too many requests -- throttled.
      return
    }
    .timer 1 1 fiqbot.tyrant.retrysocket %id needlock
    return
  }
  if (%bruteforcing [ $+ [ %usertarget ] ]) && (!$hget(socketdata,$+(bruteforcing,%id))) {
    .timer 1 1 fiqbot.tyrant.retrysocket %id
    return
  }
  if (%needlock) {
    unset %fiqbot_tyrant_socklock_count
    set %fiqbot_tyrant_socklock %id
  }
  var %host = kg.tyrantonline.com
  if (%task == getkongid) %host = kongregate.com
  if ($sock(%socket)) sockclose %socket
  sockopen %socket %host 80
}
alias fiqbot.tyrant.showid {
  set -u0 %user $1
  if ((%user isnum) && (. !isin %user) || ($hget(users,$+(id,%user)))) {
    if ($hget(users,$+(id,%user))) {
      set -u0 %user $hget(users,$+(id,%user))
    }
    %send User ID: %user
    return
  }
  set -u0 %task showid
  set -u0 %msg queryUser
  fiqbot.tyrant.runkongsocket
}
alias fiqbot.tyrant.showfaction {
  var %f_id = $int($1)
  set -u0 %task showfaction
  set -u0 %msg applyToFaction
  set -u0 %params $+(faction_id=,%f_id)
  set -u0 %needlock $true
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.showonlinestatus {
  set -u0 %metadata1 1
  set -u0 %user $1
  set -u0 %task showonlinestatus

  ;Utilizes a bug within Tyrant to bypass proper authentication. This cannot be
  ;abused (anymore) for evil use since the query gives no response if it was
  ;executed correctly. It does allow you to check other's online status due to
  ;clientcode identification, though.
  set -u0 %msg initProfile
  set -u0 %params user_id=
  set -u0 %noclientcode 1
  set -u0 %noreidentify 1
  fiqbot.tyrant.runkongsocket
}
alias fiqbot.tyrant.showownedcards {
  %send No.
  return

  set -u0 %user $1
  set -u0 %task showownedcards
  set -u0 %msg getProfileData
  set -u0 %params target_user_id=
  fiqbot.tyrant.runkongsocket
}
alias fiqbot.tyrant.showplayer {
  set -u0 %metadata1 1
  set -u0 %user $1
  set -u0 %task showplayer
  set -u0 %msg getProfileData
  set -u0 %params target_user_id=
  set -u0 %needlock $true
  set -u0 %delay 3
  fiqbot.tyrant.runkongsocket
}
alias fiqbot.tyrant.showraid {
  set -u0 %user $1
  set -u0 %task showraid
  set -u0 %msg getRaidInfo
  set -u0 %params user_raid_id=
  fiqbot.tyrant.runkongsocket
}
alias fiqbot.tyrant.showvault {
  set -u0 %task showvault
  set -u0 %msg getMarketInfo
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.showwarlog {
  set -u0 %task showwarlog
  set -u0 %msg getOldFactionWars
  set -u0 %metadata1 1
  set -u0 %metadata2 1
  set -u0 %metadata3 no
  set -u0 %metadata4 1
  if ($1) set -u0 %metadata2 $1
  if ($2) set -u0 %metadata3 $2-
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.showwars {
  set -u0 %task showwars
  set -u0 %msg getActiveFactionWars
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.startraid {
  var %raid = $1
  set %task startraid
  set -u0 %msg startRaid
  set -u0 %params $+(raid_id=,%raid)
  fiqbot.tyrant.runsocket
}

on *:sockopen:tyranttask*:{
  fiqbot.tyrant.setsocketvars $sockname
  if (!%usertarget) {
    %send [API error] No user data found, failed in sockopen for %msg (task: %task $+ )
    halt
  }
  if ($sockerr > 0) {
    if (%task == getkongid) var %msg = getKongregateData
    %send [API error] Error loading %msg (Unable to open connection)
    return
  }
  if (%task == getkongid) {
    sockwrite -n $sockname GET /api/user_info.json?username= $+ $urlencode(%metadata1) HTTP/1.0
    sockwrite -n $sockname Host: www.kongregate.com
    sockwrite -n $sockname user-agent: fiqbot/3
    sockwrite -n $sockname Connection: Keep-Alive
    sockwrite -n $sockname $crlf
    return
  }

  var %time, %hash
  %ctime = $ctime
  %time = %ctime
  %time = %time / 900
  %time = $int(%time)
  %hash = $fiqbot.tyrant.hash(%msg,%time)
  %post_data = ?& $+ $&
    %params $+ $&
    &flashcode= $+ %flashcode $+ $&
    &time= $+ %time $+ $&
    &version= $+ $fiqbot.tyrant.version $+ $&
    &hash= $+ %hash $+ $&
    &ccache= $+ $null $+ $&
    $iif(!%noclientcode,&client_code= $+ %clientcode) $+ $&
    &game_auth_token= $+ %token $+ $&
    &rc=2

  if (%task == raw2) {
    %send POST $+(/api.php?user_id=,%userid,&message=,%msg) HTTP/1.0
    %send %post_data
    return
  }
  if (%task == raw) {
    echo -s Postdata: %post_data
    echo -s 
  }
  sockwrite -n $sockname POST $+(/api.php?user_id=,%userid,&message=,%msg) HTTP/1.0
  sockwrite -n $sockname Host: kg.tyrantonline.com
  sockwrite -n $sockname user-agent: fiqbot/3
  sockwrite -n $sockname Content-Type: application/x-www-form-urlencoded
  sockwrite -n $sockname Content-Length: $len(%post_data)
  sockwrite -n $sockname 
  sockwrite -n $sockname %post_data
  sockwrite -n $sockname $crlf
  return

  :error
  if ($error) var %error = $error
  else var %error = /error: unknown error
  tokenize 40 %error
  if (!%script) {
    var %script = $script
    var %line = $left($gettok($2,2,32),-1)
    var %scriptline = $read($script,n,%line)
  }
  if (%fiqconfig_phpLikeErrors) { %send $iif(c isincs $chan(#).mode,Error: $1 in %script on line %line,Error: $1 in %script on line %line) }
  else { %sendType Error: $error }
  if (!%scriptline) var %scriptline = error
  %send Line %line contains the following: %scriptline
  .reseterror
}
on *:sockread:tyranttask*:{
  var %raw_sent = $false
  fiqbot.tyrant.setsocketvars $sockname
  if ($sockerr > 0) {
    if (%task == getkongid) var %msg = getKongregateData
    var %error = Unable to receive data
    if (%headers_completed) %error = Connection was lost
    %send [API error] Error loading %msg ( $+ %error $+ )
    return
  }
  if (!%send) set -u0 %send echo -s no-send:
  if ($sockerr > 0) return
  var %sockcount = 0
  while ($true) {
    inc %sockcount
    if (%sockcount >= 300) {
      %send [Bot error] Likely infinite loop detected, forcing halt. Triggered by $upper(%task)
      return
    }
    if (!%headers_completed) {
      sockread 3000 &temp
      if (%task == raw) echo -s Initial chunk: $bvar(&temp,1,3000).text
      var %headers, %temp
      %temp = $bvar(&temp,$bfind(&temp,1,123),3000).text
      %headers = $left($bvar(&temp,1,3000).text,$+(-,$calc($len(%temp) + 2)))
      if (%task == raw) {
        echo -s Headers: %headers
        echo -s 
      }
      var %headers_completed = 1
    }
    else {
      inc %headers_completed
      sockread 2000 &temp
      if (!$sockbr) return
      var %tempold = %temp
      hadd socketdata $+(tempold,%sockid) %temp
      %temp = $bvar(&temp,1,2000).text
    }

    hadd socketdata $+(temp,%sockid) %temp
    hadd socketdata $+(headers_completed,%sockid) %headers_completed

    if ($left(%temp,21) == {"duplicate_client":1) && (!%noreidentify) {
      var %clientcode = %fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ]
      if (!%bruteforcing [ $+ [ %usertarget ] ]) {
        %fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ] = 0
        %bruteforcing [ $+ [ %usertarget ] ] = $true
        hadd socketdata $+(bruteforcing,%sockid) 1
        set -u0 %bruteforcing 1
      }
      hdel socketdata $+(temp,%sockid)
      hdel socketdata $+(headers_completed,%sockid)
      sockclose $sockname
      if (!%bruteforcing) {
        .timer 1 1 fiqbot.tyrant.retrysocket %sockid
        return
      }
      inc %fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ]
      if (%forcedcode [ $+ [ %usertarget ] ]) %fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ] = %clientcode
      fiqbot.tyrant.runsocket %sockid
      return
    }
    elseif (%bruteforcing) {
      unset %bruteforcing [ $+ [ %usertarget ] ]
      set -u5 %forcedcode [ $+ [ %usertarget ] ] 1
      hdel socketdata $+(bruteforcing,%sockid)
    }
    if ((!%headers_completed) || (!$sockbr)) goto done
    if (!%task) goto done
    goto %task
    :GETKONGID
    tokenize 44 %temp
    if ($gettok($1,2,58) == false) {
      %send Error: $noqt($left($gettok($3,2,58),-1))
      unset %task
      sockclose $sockname
      return
    }
    var %id = $noqt($gettok($5,2,58))
    if (%metadata2 == showid) {
      %send User ID: %id
      unset %task
      sockclose $sockname
      return
    }
    set -u0 %user %id
    set -u0 %task %metadata2
    set -u0 %msg %metadata3
    set -u0 %params $+(%metadata4,%id)
    set -u0 %needlock %metadata5
    set -u0 %delay %metadata6
    hadd users $+(id,%metadata1) %id
    hadd users $+(name,%id) %metadata1
    var %i = 0
    while (%metadata [ $+ [ $calc(%i + 7) ] ]) {
      inc %i
      set -u0 %metadata [ $+ [ %i ] ] %metadata [ $+ [ $calc(%i + 6) ] ]
    }
    while (%metadata [ $+ [ $calc(%i + 1) ] ]) {
      inc %i
      unset %metadata [ $+ [ %i ] ]
    }
    fiqbot.tyrant.runsocket
    unset %task
    sockclose $sockname
    return
    :RAW
    if (%headers_completed >= 1) {
      echo -s Debug: Line %headers_completed :: Sockbr $sockbr :: Length $len(%temp) :: Content %temp
      echo -s 
    }
    if ($len(%temp) > 300) {
      %temp = $left(%temp,300) $+ ...
      %temp = $remove(%temp,$chr(10),$chr(13))
    }
    if (%headers_completed == 1) %send %temp
    goto done
    :CHECKCONQUESTMAP
    var %id, %x, %y, %owner_id, %owner_name, %attacker_id, %attacker_name, %attacker_start, %attacker_end, %cr, %protection_end, %bg, %atk_check, %bg_check, %id_check
    var %cqinfo = msg $fiqbot.tyrant.trackerchannel [CONQUEST]
    %temp = %tempold $+ %temp
    tokenize 44 %temp
    %counter = 0
    %first = %metadata1
    while ($18) {
      inc %counter 17
      if (%first) {
        if (%first == 2) {
          dec %first
          %counter = 1
          tokenize 44 %temp
          tokenize 44 $right(%temp,- $+ $len($1- [ $+ [ %counter ] ]))
          continue
        }
        %id = $noqt($gettok($1,4,58))
        %id_check = $noqt($remove($gettok($1,3,58),$chr(91),$chr(123)))
      }
      else {
        %id = $noqt($gettok($1,2,58))
        %id_check = $noqt($remove($gettok($1,1,58),$chr(91),$chr(123)))
      }
      if (%first) {
        %first = 0
        hadd socketdata $+(metadata1_,%sockid) 0
        set -u0 %metadata1 0
      }
      elseif (%id_check != system_id) {
        tokenize 44 %temp
        tokenize 44 $right(%temp,- $+ $len($1- [ $+ [ %counter ] ]))
        continue
      }
      %x = $noqt($gettok($2,2,58))
      %y = $noqt($gettok($3,2,58))
      %owner_id = $noqt($gettok($4,2,58))
      %owner_name = $noqt($gettok($11,2,58))
      %attacker_id = $noqt($gettok($13,2,58))
      %attacker_name = $noqt($gettok($14,2,58))
      %attacker_start = $noqt($gettok($15,2,58))
      %attacker_end = $noqt($remove($gettok($16,2,58),$chr(125)))
      %cr = $noqt($gettok($7,2,58))
      %protection_end = $noqt($gettok($12,2,58))
      %bg = $noqt($remove($gettok($17,2,58),$chr(125)))

      %atk_check = $noqt($gettok($14,1,58))
      %bg_check = $noqt($gettok($17,1,58))
      if (%atk_check != attacking_faction_name) {
        dec %counter 3
        %attacker_id = 0
        %attacker_name = $null
        %attacker_start = 0
        %attacker_end = 0
        %bg = $noqt($remove($gettok($14,2,58),$chr(125)))
        %bg_check = $noqt($gettok($14,1,58))
      }
      if (%bg_check != effect) {
        dec %counter
        %bg = 0
      }

      if ($hget(conquest,$+(x,%id))) {
        var %h.owner = $hget(conquest,$+(owner_id,%id))
        var %h.ownername = $hget(conquest,$+(owner_name,%id))
        var %h.attacker = $hget(conquest,$+(attacker_id,%id))
        var %h.attackername = $hget(conquest,$+(attacker_name,%id))
        var %fc.owner = %fiqbot_tyrant_factionchannel_ [ $+ [ %fiqbot_tyrant_faccount [ $+ [ %h.owner ] ] ] ]
        var %fc.newowner = %fiqbot_tyrant_factionchannel_ [ $+ [ %fiqbot_tyrant_faccount [ $+ [ %owner_id ] ] ] ]
        var %fc.attacker = %fiqbot_tyrant_factionchannel_ [ $+ [ %fiqbot_tyrant_faccount [ $+ [ %h.attacker ] ] ] ]
        var %fc.newattacker = %fiqbot_tyrant_factionchannel_ [ $+ [ %fiqbot_tyrant_faccount [ $+ [ %attacker_id ] ] ] ]

        if (%owner_id != %h.owner) {
          if (%owner_id) {
            %cqinfo %owner_name successfully conquered $fiqbot.tyrant.cqcoordinates(%x,%y) $+ , previously owned by $iif(%h.ownername,%h.ownername,AI)
            if (%fc.owner) {
              msg %fc.owner [CONQUEST] Lost $fiqbot.tyrant.cqcoordinates(%x,%y) to %owner_name
            }
            if (%fc.newowner) {
              msg %fc.newowner [CONQUEST] Successfully conquered $fiqbot.tyrant.cqcoordinates(%x,%y) from $iif(%h.ownername,%h.ownername,AI)
            }
          }
          else {
            %cqinfo %h.ownername abandoned $fiqbot.tyrant.cqcoordinates(%x,%y)
            if (%fc.owner) {
              msg %fc.owner [CONQUEST] Abandoned $fiqbot.tyrant.cqcoordinates(%x,%y)
            }
          }
          hadd conquest $+(protection_end,%id) %protection_end
          hadd conquest $+(owner_id,%id) %owner_id
          hadd conquest $+(owner_name,%id) %owner_name
        }
        if (%attacker_id != %h.attacker) {
          if (%attacker_id) {
            %cqinfo %attacker_name is invading $fiqbot.tyrant.cqcoordinates(%x,%y) $+ , owned by $iif(%owner_name,%owner_name,AI)
            if (%fc.newowner) {
              msg %fc.newowner [CONQUEST] Defending $fiqbot.tyrant.cqcoordinates(%x,%y) against %attacker_name
            }
            if (%fc.newattacker) {
              msg %fc.newattacker [CONQUEST] Attacking $fiqbot.tyrant.cqcoordinates(%x,%y) owned by $iif(%owner_name,%owner_name,AI)
            }
          }
          if (%h.attacker != %owner_id) && (%h.attacker) {
            %cqinfo %h.attackername failed to conquer $fiqbot.tyrant.cqcoordinates(%x,%y) $+ , owned by $iif(%owner_name,%owner_name,AI)
            if (%fc.newowner) {
              msg %fc.newowner [CONQUEST] Successfully defended $fiqbot.tyrant.cqcoordinates(%x,%y) against %h.attackername
            }
            if (%fc.attacker) {
              msg %fc.attacker [CONQUEST] Failed to conquer $fiqbot.tyrant.cqcoordinates(%x,%y) from %h.ownername
            }
          }
          hadd conquest $+(attacker_id,%id) %attacker_id
          hadd conquest $+(attacker_name,%id) %attacker_name
          hadd conquest $+(attacker_start,%id) %attacker_start
          hadd conquest $+(attacker_end,%id) %attacker_end
        }
      }

      if (!$hget(conquest,$+(x,%id))) {
        hadd conquest $+(x,%id) %x
        hadd conquest $+(y,%id) %y
        hadd conquest $+(cr,%id) %cr
        hadd conquest $+(bg,%id) %bg
      }

      if (%owner_id) {
        hadd factions $+(name,%owner_id) %owner_name
        var %trim_name = $remove(%owner_name,$chr(32))
        if (!$hget(factions,$+(id,%trim_name))) hadd factions $+(id,%trim_name) %owner_id
      }
      if (%attacker_id) {
        hadd factions $+(name,%attacker_id) %attacker_name
        var %trim_name = $remove(%attacker_name,$chr(32))
        if (!$hget(factions,$+(id,%trim_name))) hadd factions $+(id,%trim_name) %attacker_id
      }

      tokenize 44 %temp
      var %temp_fix = $right(%temp,- $+ $len($1- [ $+ [ %counter ] ]))
      if ($left(%temp_fix,1) != $chr(125)) tokenize 44 %temp_fix
      else tokenize 44 $right(%temp_fix,-1)
    }
    tokenize 44 %temp
    var %temp_add = $right(%temp,- $+ $calc($len($1- [ $+ [ %counter ] ]) + 1))
    %temp = %temp_add
    hadd socketdata $+(temp,%sockid) %temp
    goto done
    :CHECKTARGETS
    var %id, %name, %fp, %infamy, %nerf, %targetcounter, %pointer
    if ($left(%temp,11) != {"rivals":[) continue
    tokenize 44 %temp
    %targets = $false
    %targetcounter = 0
    while ($5) {
      inc %targetcounter
      %id = $noqt($gettok($1,3,58))
      if (!%id) %id = $noqt($gettok($1,2,58))
      %name = $remove($noqt($gettok($2,2,58)),\)
      if (!%name) {
        %name = ???
      }
      %fp = $noqt($gettok($3,2,58))
      %infamy = $gettok($4,2,58)
      %nerf = $noqt($left($gettok($5,2,58),-1))
      %nerf = $remove(%nerf,$chr(125))
      if ($hget(factions,$+(name,%id))) {
        if ($hget(factions,$+(infamy,%id)) != %infamy) {
          hadd factions $+(upcomingtarget,%id) $calc($ctime + 3600*6)
          if (%infamy == 0) { hadd factions $+(upcomingtarget,%id) 0 }
        }
      }
      else {
        %pointer = $hget(factions,nextid)
        hadd factions $+(pointer,%pointer) %id
        hinc factions nextid
        hadd factions $+(id,$remove(%name,$chr(32))) %id
        if (%infamy) {
          hadd factions $+(upcomingtarget,%id) $calc($ctime + 3600*6)
        }
      }
      hadd factions $+(name,%id) %name
      hadd factions $+(fp,%id) %fp
      hadd factions $+(infamy,%id) %infamy
      hadd factions $+(nerf,%id,_,%usertarget) %nerf
      var %validtarget = $hget(factions,$+(validtarget,%id))
      if (!%validtarget) {
        hadd factions $+(validtarget,%id) %usertarget
      }
      elseif (!$findtok(%validtarget,%usertarget,0,58)) {
        hadd factions $+(validtarget,%id) $instok(%validtarget,%usertarget,1,58)
      }
      if (($hget(factions,$+(upcomingtarget,%id)) < $ctime) && (%infamy)) {
        hinc factions $+(upcomingtarget,%id) $calc(3600 * 6)
      }
      tokenize 44 %temp
      tokenize 44 $right(%temp,- $+ $len($1- [ $+ [ $calc(5 * %targetcounter) ] ]))
    }
    goto done

    :SHOWFACTION
    var %name, %public, %activity, %active, %members, %cap, %level, %fp, %wins, %losses, %infamy, %totalinfamy, %description
    tokenize 44 %temp
    %id = $noqt($gettok($1,2-,58))
    %name = $noqt($gettok($3,2-,58))
    %public = $noqt($gettok($4,2-,58))
    %activity = $noqt($gettok($5,2-,58))
    %members = $noqt($gettok($6,2-,58))
    %level = $noqt($gettok($8,2-,58))
    %fp = $noqt($gettok($9,2-,58))
    %wins = $noqt($gettok($10,2-,58))
    %losses = $noqt($gettok($11,2-,58))
    %infamy = $noqt($gettok($14,2-,58))
    %totalinfamy = $noqt($gettok($16,2,58))
    %description = $noqt($gettok($18,2-,58))

    %name = $remove(%name,\)
    %description = $remove(%description,\)

    %cap = $calc(%level * 5)
    inc %cap 10
    if (%cap > 50) %cap = 50
    %active = $round($calc(%members * %activity * 0.01),0)

    var %buffer
    %buffer = %name
    %buffer = %buffer (Level %level $+ , $+(%fp,FP) $+ )
    %buffer = %buffer :: Recruitment: $iif(%public,Public,Private)
    %buffer = %buffer :: Members: $+(%members,/,%cap) ( $+ %active active)
    %buffer = %buffer :: Wars: $+(%wins,/,%losses) W/L
    %buffer = %buffer :: Infamy: $+(%infamy,/,%totalinfamy) current/total
    if (%description) %buffer = %buffer :: Message: %description
    if ((%access >= 3) || ((%public) && (%access == 2))) {
      %buffer = %buffer :: Join link: $&
        http://www.kongregate.com/games/synapticon/tyrant?source=finv&kv_apply= $+ %id
    }

    if (%level) %send %buffer
    else %send No such faction.
    fiqbot.tyrant.login 2
    set -u0 %task $null
    unset %fiqbot_tyrant_socklock
    set -u0 %msg leaveFaction
    set -u0 %needlock $true
    fiqbot.tyrant.runsocket
    unset %message
    goto done

    :SHOWONLINESTATUS
    var %buffer = This user is currently
    if ($chr(123) isin %temp) %buffer = %buffer online
    else %buffer = %buffer offline
    %buffer = $+(%buffer,.)
    %send %buffer
    return

    :SHOWPLAYER
    var %p_id = %user
    if (%headers_completed == 1) {
      tokenize 44 %temp
      %p_name = $noqt($gettok($2,2,58))
      %p_xp = $noqt($gettok($3,2,58))
      %p_level = $noqt($gettok($4,2,58))
      if (!%p_level) {
        %send Specified player doesn't have a Tyrant account.
        unset %fiqbot_tyrant_socklock
        hdel socketdata $+(temp,%sockid)
        sockclose $sockname
        return
      }
      hadd users $+(id,%p_name) %p_id
      hadd users $+(name,%p_id) %p_name
      if (!$hget(userdata)) {
        hmake userdata 10000
      }
      var %p_updated = $hget(userdata,$+(updated,%p_id))
      if (!%p_updated) %p_updated = 0
      if (%p_updated < $calc($ctime - 7200)) hadd userdata $+(updated,%p_id) $ctime
      set -u0 %metadata1 %p_updated
      hadd socketdata $+(metadata_,%sockid) 1
      hadd socketdata $+(metadata1_,%sockid) %metadata1
      %p_elo = $noqt($gettok($5,2,58))
      %p_arena = $noqt($gettok($6,2,58))
      %p_tournament = $noqt($gettok($7,2,58))
      %p_wins = $noqt($gettok($8,2,58))
      %p_losses = $noqt($left($gettok($9,2,58),-1))
    }
    if (%metadata1 < $calc($ctime - 7200)) {
      noop
    }
    goto done
    :SHOWRAID
    var %userid, %raidid, %start, %health, %users, %joinkey, %duration
    var %end, %ended, %raidname, %raidhp, %raidusers, %raidtime
    var %hoursleft, %healthpercent, %hoursleftpercent
    tokenize 44 %temp
    if (!$4) {
      %send That user hasn't started any raids.
      return
    }
    unset %task
    %userid = $noqt($gettok($2,3,58))
    %raidid = $noqt($gettok($3,2,58))
    %start = $noqt($gettok($4,2,58))
    %health = $noqt($gettok($7,2,58))
    %users = $noqt($gettok($8,2,58))
    if (%users == 0) %users = --
    %joinkey = %userid $+ $right(%start,4)
    if (%access < 3) %joinkey = *
    %ended = $false
    %raidname = $fiqbot.tyrant.raidinfo(%raidid,name)
    %raidhp = $fiqbot.tyrant.raidinfo(%raidid,health)
    %healthpercent = $calc($round($calc(%health / %raidhp),2) * 100) $+ %
    %raidusers = $fiqbot.tyrant.raidinfo(%raidid,users)
    %raidtime = $fiqbot.tyrant.raidinfo(%raidid,duration)
    %duration = $calc(%start + 3600 * %raidtime - %ctime)
    %hoursleft = $calc(%duration / 3600)
    if (%hoursleft < 0) %hoursleft = 0
    %hoursleftpercent = $calc($round($calc(%hoursleft / %raidtime),2) * 100) $+ %
    %hoursleft = $round(%hoursleft,1)
    if (%duration <= 0) {
      %ended = $true
      %duration = $calc( %duration * -1 )
    }
    %status = Running
    if (%ended) && (%health > 0) %status = Defeat
    if (%health <= 0) %status = Victory
    if (%status != Running) {
      if (%ended == $true) {
        %ended = $false
        %duration = $calc( %duration * -1 )
      }
      inc %duration 86400
      if (%duration <= 0) {
        %ended = $true
        %duration = $calc( %duration * -1 )
      }
    }
    %end = $fiqbot.tyrant.duration(%duration)
    if (%status == Running) {
      %send Raid: %raidname :: Status: %status :: Players: $+(%users,/,%raidusers) :: Health: $+(%health,/,%raidhp $chr(40),%healthpercent,$chr(41)) :: Hours left: $+(%hoursleft,/,%raidtime $chr(40),%hoursleftpercent,$chr(41)) :: Join key: %joinkey :: %end left
    }
    else {
      var %timepassed
      if (%ended) %timepassed = Ended %end ago
      else %timepassed = %end left
      %send Raid: %raidname :: Status: %status :: Players: $+(%users,/,%raidusers) :: Health: $+(%health,/,%raidhp $chr(40),%healthpercent,$chr(41)) :: Hours left: $+(%hoursleft,/,%raidtime $chr(40),%hoursleftpercent,$chr(41)) :: Cooldown time: %timepassed
    }
    unset %task
    hdel socketdata $+(temp,%sockid)
    sockclose $sockname
    return
    :CHECKVAULT
    :SHOWVAULT
    var %id, %name, %end, %buffer, %first
    tokenize 44 %temp
    var %vaultend = $noqt($gettok($20,2,58))
    %end = $fiqbot.tyrant.duration($calc(%vaultend + 3600 * 3 - %ctime)) left
    %first = $true
    var %i = 0
    while (%i < 8) {
      inc %i
      %id = $noqt($remove($ [ $+ [ $calc(%i + 3) ] ],]))
      if (%first) %id = $noqt($right($gettok($ [ $+ [ $calc(%i + 3) ] ],2,58),-1))
      %name = $hget(cards,$+(name,%id))
      if (!%name) {
        %send Found unknown card: %id :: Bailing out!
        hdel socketdata $+(temp,%sockid)
        sockclose $sockname
        halt
      }
      if (%first) %buffer = %name
      else %buffer = %buffer $+ , %name
      %first = $false
      if (%task == checkvault) {
        var %buffer2 = %buffer2 %id
      }
    }
    if (%buffer) {
      if (%task == showvault) {
        %send Cards: %buffer :: %end
      }
      else {
        if (%vaultend != %fiqbot_tyrant_vaultend) {
          msg $fiqbot.tyrant.trackerchannel [VAULT] New cards: %buffer :: %end
          %fiqbot_tyrant_vaultend = %vaultend
        }
        var %i = 0
        while (%i < $var(fiqbot_tyrant_vaultalert_*,0)) {
          inc %i
          var %key = $var(fiqbot_tyrant_vaultalert_*,%i)
          var %value = $var(fiqbot_tyrant_vaultalert_*,%i).value
          var %chan = $right(%key,-26)
          if (%fiqbot_tyrant_vaultmentioned_ [ $+ [ %chan ] ]) continue
          var %j = 0
          while (%j < $gettok(%buffer2,0,32)) {
            inc %j
            var %idcheck = $gettok(%buffer2,%j,32)
            if ($findtok(%value,%idcheck,32)) {
              msg %chan [VAULT ALERT] $hget(cards,$+(name,%idcheck)) in vault!
              msg %chan Full vault: %buffer :: %end
              inc %j 8
              set -z %fiqbot_tyrant_vaultmentioned_ [ $+ [ %chan ] ] 3600
            }
          }
        }
      }
    }
    goto done
    :SHOWWARLOG
    var %id, %off_id, %friend, %opponent, %end, %atk, %def, %diff, %wars, %warcounter, %first
    %temp = %tempold $+ %temp
    tokenize 44 %temp
    %wars = $false
    %warcounter = 0
    %first = %metadata1
    while (($14) && (%metadata2)) {
      inc %warcounter
      if (%first) %id = $noqt($gettok($1,3,58))
      else %id = $noqt($gettok($1,2,58))
      if (%first) {
        %first = 0
        hadd socketdata $+(metadata1_,%sockid) 0
        set -u0 %metadata1 0
      }
      %wars = $true
      %off_id = $noqt($gettok($2,2,58))
      %friend = $fiqbot.tyrant.factionname
      %opponent = $noqt($gettok($13,2,58))
      %opponent = $remove(%opponent,\)
      if ((%metadata3 != no) && (%metadata3 != %opponent)) {
        tokenize 44 %temp
        tokenize 44 $right(%temp,- $+ $len($1- [ $+ [ $calc(14 * %warcounter) ] ]))
        continue
      }
      %end = Ended $fiqbot.tyrant.duration($calc(%ctime - ( $noqt($gettok($4,2,58)) + 3600 * 6 ) )) ago
      %atk = $noqt($gettok($7,2,58))
      %def = $noqt($gettok($8,2,58))
      %diff = %atk - %def
      if (%off_id != $fiqbot.tyrant.factionid) {
        %friend = %opponent
        %opponent = $fiqbot.tyrant.factionname
        %diff = $calc( %diff * -1 )
      }
      if (- !isin %diff) %diff = + $+ %diff
      %send %id :: $+(%friend,-,%opponent) :: $+(%atk,-,%def) ( $+ %diff $+ ) :: %end
      dec %metadata2
      hdec socketdata $+(metadata2_,%sockid)
      set -u0 %metadata4 0
      hadd socketdata $+(metadata4_,%sockid) 0
      tokenize 44 %temp
      tokenize 44 $right(%temp,- $+ $len($1- [ $+ [ $calc(14 * %warcounter) ] ]))
    }
    tokenize 44 %temp
    var %temp_add = $right(%temp,- $+ $calc($len($1- [ $+ [ $calc(14 * %warcounter) ] ]) + 1))
    if (!%metadata2) {
      var %temp_add = $null
    }
    %temp = %temp_add
    hadd socketdata $+(temp,%sockid) %temp
    if (!%metadata2) {
      sockclose $sockname
      return
    }
    goto done
    :CHECKWARS
    :SHOWWARS
    var %id, %off_id, %friend, %opponent, %end, %atk, %def, %diff, %wars, %warcounter, %first
    tokenize 44 %temp
    %wars = $false
    %warcounter = 0
    var %chan = %fiqbot_tyrant_factionchannel_ [ $+ [ %usertarget ] ]
    var %noalert_settings = %fiqbot_tyrant_noalert_ [ $+ [ %chan ] ]
    if (!%noalert_settings) %noalert_settings = %fiqbot_tyrant_noalert
    if (%noalert_settings == global) return
    %first = $true
    while ($10) {
      inc %warcounter
      if (%first) %id = $noqt($gettok($1,4,58))
      else %id = $noqt($gettok($1,3,58))
      %first = $false
      %wars = $true
      %off_id = $noqt($gettok($2,2,58))
      %friend = $fiqbot.tyrant.factionname
      %opponent = $noqt($gettok($13,2,58))
      %opponent = $remove(%opponent,\)
      %end = $fiqbot.tyrant.duration($calc($noqt($gettok($4,2,58)) + 3600 * 6 - %ctime)) left
      %atk = $noqt($gettok($7,2,58))
      %def = $noqt($gettok($8,2,58))
      %diff = %atk - %def
      if (%off_id != $fiqbot.tyrant.factionid) {
        %friend = %opponent
        %opponent = $fiqbot.tyrant.factionname
        %diff = $calc( %diff * -1 )
      }
      if (- !isin %diff) %diff = + $+ %diff
      if (!%opponent) {
        if (%task == showwars) %send No wars!
        if ($hget(wars,detected)) {
          hfree wars
          hmake wars 10
        }
        return
      }
      if (%task == showwars) %send %id :: $+(%friend,-,%opponent) :: $+(%atk,-,%def) ( $+ %diff $+ ) :: %end
      elseif (!$hget(wars,%id)) {
        var %buffer, %nick
        var %i = 0
        while ((%noalert_settings != highlights) && (%i < $nick(%chan,0))) {
          inc %i
          %nick = $nick(%chan,%i)
          if (%fiqbot_tyrant_noalert_ [ $+ [ $address(%nick,2) ] ]) continue
          if (%fiqbot_tyrant_noalert_ [ $+ [ $+(%chan,_,$address(%nick,2)) ] ]) continue
          if (!%buffer) %buffer = :: Attention:
          var %buffer = %buffer $nick(%fiqbot_tyrant_factionchannel_ [ $+ [ %usertarget ] ],%i)
        }
        msg %fiqbot_tyrant_factionchannel_ [ $+ [ %usertarget ] ] New war started! %id :: $+(%friend,-,%opponent) :: $+(%atk,-,%def) ( $+ %diff $+ ) :: %end %buffer
        hadd wars %id 1
        hadd wars detected 1
      }
      tokenize 44 %temp
      tokenize 44 $right(%temp,- $+ $len($1- [ $+ [ $calc(15 * %warcounter) ] ]))
    }
    if ((!%wars) && (%task == showwars)) { %send No wars! }
    goto done
    :done
    unset %bruteforcing
    if ($sockbr == 0) {
      msg #fiq-bot [Bot error] no clean exit
      return
    }
  }

  :error
  if ($error) var %error = $error
  else var %error = /error: unknown error
  tokenize 40 %error
  if (!%script) {
    var %script = $script
    var %line = $left($gettok($2,2,32),-1)
    var %scriptline = $read($script,n,%line)
  }
  if (%fiqconfig_phpLikeErrors) { echo @fiqbot $iif(c isincs $chan(#).mode,Error: $1 in %script on line %line,Error: $1 in %script on line %line) }
  else { %sendType Error: $error }
  if (!%scriptline) var %scriptline = error
  echo @fiqbot Line %line contains the following: %scriptline
  .reseterror
}
on *:sockclose:tyranttask*:{
  fiqbot.tyrant.setsocketvars $sockname
  if (!%delay) set -u0 %delay 0
  if (%fiqbot_tyrant_socklock == %sockid) {
    .timer 1 %delay fiqbot.tyrant.freelock
  }
  if (!%temp) return
  if (%task) goto %task
  else return

  :RAW
  echo -s --------------- EOF ---------------
  return

  :SHOWPLAYER
  var %p_id = %user
  set -l %buffer %p_name (Level %p_level $+ , $+(%p_xp,XP) $+ )
  %temp = %tempold $+ %temp
  if (faction isin %temp) {
    tokenize 44 %temp
    var %i = 1
    while ($noqt($gettok($ [ $+ [ %i ] ],1,58)) != faction_data) inc %i
    var %f_id, %f_name, %f_level, %f_fp, %f_wins, %f_losses, %f_access, %f_lp
    %f_id = $noqt($gettok($ [ $+ [ $calc(%i + 0) ] ],3,58))
    %f_name = $noqt($gettok($ [ $+ [ $calc(%i + 1) ] ],2,58))
    if (!%f_name) %f_name = ???
    %f_level = $noqt($gettok($ [ $+ [ $calc(%i + 2) ] ],2,58))
    %f_fp = $noqt($gettok($ [ $+ [ $calc(%i + 3) ] ],2,58))
    %f_wins = $noqt($gettok($ [ $+ [ $calc(%i + 4) ] ],2,58))
    %f_losses = $noqt($gettok($ [ $+ [ $calc(%i + 5) ] ],2,58))
    %f_access = $noqt($gettok($ [ $+ [ $calc(%i + 6) ] ],2,58))
    %f_lp = $noqt($remove($gettok($ [ $+ [ $calc(%i + 7) ] ],2,58),},"))
    if (%f_access == 1) %f_access = Member
    elseif (%f_access == 2) %f_access = Officer
    elseif (%f_access == 3) %f_access = Leader
    elseif (%f_access == 4) %f_access = Warmaster
    else %f_access = Applicant
    %f_lp = $left(%f_lp,-2)
    if (%f_lp >= 0) {
      %buffer = %buffer :: %f_access of %f_name (Level %f_level $+ , %f_fp $+ FP, $+(%f_wins,/,%f_losses) W/L) with %f_lp $+ LP

      if (!$hget(factions,$+(name,%f_id))) {
        var %pointer = $hget(factions,nextid)
        hadd factions $+(pointer,%pointer) %f_id
        hinc factions nextid
        hadd factions $+(id,$remove(%f_name,$chr(32))) %f_id
        hadd factions $+(name,%f_id) %f_name
      }
    }
    unset %task
  }
  else {
    %buffer = %buffer :: Not in a faction
  }
  %buffer = %buffer :: Arena: %p_elo elo, %p_arena points :: Tournament rating: %p_tournament $+ , $+(%p_wins,/,%p_losses) W/L
  var %updated = (never)
  if (%metadata1 > 1) var %updated = $fiqbot.tyrant.duration($calc($ctime - %metadata1)) ago
  if (%access >= 3) %buffer = %buffer :: Latest update: %updated
  %send %buffer
  return

  :SHOWWARLOG
  if (%metadata4) {
    var %buffer = No earlier wars
    if (%metadata3 != no) %buffer = %buffer with %metadata3
    %send %buffer
    return
  }

  ;unused labels
  :CHECKCONQUESTMAP
  :CHECKTARGETS
  :CHECKVAULT
  :CHECKWARS
  :SHOWFACTION
  :SHOWONLINESTATUS
  :SHOWOWNEDCARDS
  :SHOWRAID
  :SHOWVAULT
  :SHOWWARS
  return

  :error
  if ($error) var %error = $error
  else var %error = /error: unknown error
  tokenize 40 %error
  if (!%script) {
    var %script = $script
    var %line = $left($gettok($2,2,32),-1)
    var %scriptline = $read($script,n,%line)
  }
  if (%fiqconfig_phpLikeErrors) { %send $iif(c isincs $chan(#).mode,Error: $1 in %script on line %line,Error: $1 in %script on line %line) }
  else { %sendType Error: $error }
  if (!%scriptline) var %scriptline = error
  %send Line %line contains the following: %scriptline
  .reseterror
}
