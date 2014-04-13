;Initialization
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
  if ($exists($+($fiqbot.tyrant.directory,tables\users.fht))) {
    var %hload = fiqbot.tyrant.hload
    %hload users 1000
    %hload userdata 10000
    %hload factions 10000
    %hload factiondata 10000
    %hload conquest 1000
    %hload targets 500
    %hload wars 1000
    %hload wardata 10000
    return
  }
  if (!$hget(users)) hmake users 1000
  if (!$hget(userdata)) hmake userdata 10000
  if (!$hget(factions)) hmake factions 10000
  if (!$hget(factiondata)) hmake factiondata 10000
  if (!$hget(conquest)) hmake conquest 1000
  if (!$hget(targets)) hmake targets 500
  if (!$hget(wars)) hmake wars 1000
  if (!$hget(wardata)) hmake wardata 10000
}

;Helpers
alias fiqbot.tyrant.factionid return %fiqbot_tyrant_fid [ $+ [ %usertarget ] ]
alias fiqbot.tyrant.factionname return %fiqbot_tyrant_fname [ $+ [ %usertarget ] ]
alias fiqbot.tyrant.factionfp return %fiqbot_tyrant_fp [ $+ [ %usertarget ] ]
alias fiqbot.tyrant.addfaction fiqbot.tyrant.db.add factions $1-
alias fiqbot.tyrant.addplayer fiqbot.tyrant.db.add users $1-
alias fiqbot.tyrant.directory {
  if (!$exists($fiqbot.tyrant.directoryconfig)) return $+($scriptdir,tyrant\)
  return $fiqbot.tyrant.directoryconfig
}
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
alias fiqbot.tyrant.bg {
  if ($1 == 1) return Time Surge
  if ($1 == 2) return Copycat
  if ($1 == 3) return Quicksilver
  if ($1 == 4) return Decay
  if ($1 == 5) return High Skies
  if ($1 == 6) return Impenetrable
  if ($1 == 7) return Invigorate
  if ($1 == 8) return Clone Project
  if ($1 == 9) return Friendly Fire
  if ($1 == 10) return Genesis
  if ($1 == 11) return Artillery Strike
  if ($1 == 12) return Photon Shield
  if ($1 == 13) return Decrepit
  if ($1 == 14) return Forcefield
  if ($1 == 15) return Chilling Toucħ
  if ($1 == 16) return Clone Experiment
  if ($1 == 17) return Toxic
  if ($1 == 18) return Haunt
  if ($1 == 19) return United Front
  if ($1 == 20) return Harsh Conditions
  return [Unknown battleground ID: $1 $+ $chr(93)
}
alias fiqbot.tyrant.cqcoordinates {
  var %x = $1, %y = $2
  if ($2 == $null) || ($2 == x) || ($2 == y) {
    var %return = $2
    tokenize 44 $1

    var %1 = $iif($1,$left($1,-1),0)
    var %2 = $iif($2,$left($2,-1),0)
    if (!%return) {
      if ($right($1,1) != W) && ($right($1,1) != E) && ($1 != 0) return $false
      if ($right($2,1) != N) && ($right($2,1) != S) && ($2 != 0) return $false
      if (%1 !isnum) || (. isin %1) || (%2 !isnum) || (. isin %2) return $false
      if (%1 > 16) || (%2 > 16) return $false

      return $true
    }

    var %1 = $iif($1,$left($1,-1),0)
    var %2 = $iif($2,$left($2,-1),0)

    if ($right($1,1) == W) %1 = $calc(%1 * -1)    
    if ($right($2,1) == N) %2 = $calc(%2 * -1)

    if (%return == x) return %1
    return %2
  }

  var %buffer, %x_result, %y_result
  %x_result = %x
  if (%x) %x_result = $+(%x_result,E)
  %y_result = %y
  if (%y) %y_result = $+(%y_result,S)
  if (%x < 0) %x_result = $+($calc(%x * -1),W)
  if (%y < 0) %y_result = $+($calc(%y * -1),N)
  return ( $+ $+(%x_result,$chr(44),%y_result) $+ )
}
alias fiqbot.tyrant.db.add {
  var %table, %id, %name, %nextid
  if (!%send) set -u0 %send echo -s
  %table = $1
  %id = $2
  if (!%id) return
  %name = $3-
  if (%id !isnum) || (. isin %id) {
    %send [DB error] Attempted to add a non-numeric ID! ID: %id :: Non-fixed name: %name :: Fixed name: $remove(%name,\)
    %send [Socket info] Task: %task :: Msg: %msg :: Params: %params :: Parsed lines until error: %headers_completed :: Metadata: %metadata1 - %metadata2 - %metadata3 - %metadata4
    halt
  }
  %name = $remove(%name,\)
  if (!%name) {
    %send [DB warning] Unknown name for ID: %id :: Caused by task: %task
    %name = ???
  }
  if (!$hget(%table,$+(name,%id))) {
    hadd %table $+(name,%id) %name

    %name = $remove(%name,$chr(32))

    %nextid = $hget(%table,$+(nextid,%name))
    if (!%nextid) {
      %nextid = 1
      hadd %table $+(nextid,%name) %nextid
    }
    hinc %table $+(nextid,%name)
    hadd %table $+(id_,%name,_,%nextid) %id
  }
  else {
    fiqbot.tyrant.db.update %table %id
  }
}
alias fiqbot.tyrant.db.repair {
  ;repairs DBs corrupted by previous id erasing bug.
  if ($hget(tmp)) hfree tmp
  hmake tmp 1000
  if (!%send) set -u0 %send echo -s
  var %table = $1
  if (%table != users) && (%table != factions) {
    %send Not a tyrant-DB: %table
    return
  }

  var %i = 0
  var %name = ???
  var %itemtarget
  while (%i < $hfind(%table,name*,0,w)) {
    inc %i
    %itemtarget = $hfind(%table,name*,%i,w)
    %id = $remove(%itemtarget,name)

    %name = $hget(%table,$+(name,%id))
    if (!%name) %name = ???
    hadd tmp %id %name
  }

  hfree %table
  hmake %table 1000

  var %i = 0
  while (%i < $hfind(tmp,*,0,w)) {
    inc %i
    %id = $hfind(tmp,*,%i,w)

    %name = $hget(tmp,%id)
    if (!%name) %name = ???

    fiqbot.tyrant.db.add %table %id %name
  }
  hfree tmp
}
alias fiqbot.tyrant.db.select {
  var %table, %name, %buffer
  %table = $1
  %name = $remove($2-,\)
  %name = $remove(%name,$chr(32))
  var %i = 0
  while (%i < $hget(%table,$+(nextid,%name))) {
    inc %i
    %buffer = %buffer $hget(%table,$+(id_,%name,_,%i))
  }
  return %buffer
}
alias fiqbot.tyrant.db.update {
  if (!%send) set -u0 %send echo -s
  var %table, %id, %name, %id_move
  %table = $1
  %id = $2
  if (!$hget(%table,$+(name,%id))) {
    %send [DB error] Trying to set priority status for an unknown ID in %table for: %id
    halt
  }
  %name = $remove($hget(%table,$+(name,%id)),\)
  %name = $remove(%name,$chr(32))
  %id_move = $hget(%table,$+(id_,%name,_1))

  var %i = 0
  while (%i < $hget(%table,$+(nextid,%name))) {
    inc %i
    if ($hget(%table,$+(id_,%name,_,%i)) == %id) {
      hadd %table $+(id_,%name,_,%i) %id_move
      hadd %table $+(id_,%name,_1) %id
      break
    }
  }
}
alias fiqbot.tyrant.downloadfactions {
  if (!%fiqbot_tyrant_currentfaction) {
    %fiqbot_tyrant_currentfaction = $fiqbot.tyrant.firstfaction

    ;last known faction is stored in case of morons who name their faction "???", ruining faction storing.
    %fiqbot_tyrant_lastfaction = $fiqbot.tyrant.lastfaction
  }
  else {
    if ($hget(factions,$+(name,%fiqbot_tyrant_currentfaction))) || (%fiqbot_tyrant_currentfaction < %fiqbot_tyrant_lastfaction) {
      var %id = %fiqbot_tyrant_currentfaction
      if (%id < 70001) inc %id
      else inc %id 1000

      if (%id == 69177) %id = 70001
      if (%id == 1015001) %id = 3843003
      if (%id == 8325003) %id = 125002
      %fiqbot_tyrant_currentfaction = %id
    }
  }
  fiqbot.tyrant.checkfactionname %fiqbot_tyrant_currentfaction
}
alias fiqbot.tyrant.energy {
  var %max_time = $1, %cap = $2
  var %max_time = %max_time - $ctime
  if (%max_time < 0) %max_time = 0
  var %current_use = %max_time / 60
  %current_use = %cap - %current_use
  %current_use = $round(%current_use,0)
  if ($prop == showcap) return $+(%current_use,/,%cap)
  return %current_use
}
alias fiqbot.tyrant.factionrank {
  if ($1 == 0) return Applicant
  if ($1 == 1) return Member
  if ($1 == 2) return Officer
  if ($1 == 3) return Leader
  if ($1 == 4) return Warmaster
  return $+(FactionRank<,$1,>)
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

  %time_hash = $fiqbot.tyrant.salt
  if ($md5(%time_hash) != d1fcc25cc6fff42e6de99bc94c831e88) {
    %send [API warning] Likely incorrect salt. If the salt is correct, file a bug report to FIQ. If this warning is correct, API queries will not work!
  }
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
  var %size = $2
  if (!%size) %size = 1000
  if (!$hget($1)) {
    hmake $1 %size
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
  set -u0 %send noop
  fiqbot.tyrant.updatefactioninfo
  
  fiqbot.tyrant.login 1
  if (%bruteforcing1) return
  inc %interval 1

  fiqbot.tyrant.downloadfactions

  fiqbot.tyrant.checkvault
  fiqbot.tyrant.checkconquestmap
  if (!$calc(%interval % 20)) {
    var %hsave = fiqbot.tyrant.hsave
    %hsave users
    %hsave userdata
    %hsave factions
    %hsave factiondata
    %hsave conquest
    %hsave targets
    %hsave wars
    %hsave wardata
    %hsave cards
    %hsave raids

    fiqbot.tyrant.downloadxml cards
  }
}
alias fiqbot.tyrant.updatefactioninfo {
  var %i = 1
  while (%fiqbot_tyrant_userid [ $+ [ %i ] ]) {
    if (%fiqbot_tyrant_fname [ $+ [ %i ] ]) && (!%bruteforcing [ $+ [ %i ] ]) {
      
      ;Faction chat
      fiqbot.tyrant.checkfactionchat %i %last.post.id. [ $+ [ %i ] ]
      
      ;Member tracking
      fiqbot.tyrant.checkfactionmembers %i
      
      ;Unfinished, for CQ assist
      ;fiqbot.tyrant.checkinvasion %i
      
      ;For updating of target lists
      fiqbot.tyrant.checktargets %i
      
      ;War tracking
      fiqbot.tyrant.checkwarinfo %i
      
      ;Check new wars
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
  if (!%fiqbot_tyrant_clientcode) {
    %send [API error] No initial clientcode is set. Please retrieve current clientcode for the user, and set it with !clientcode. (If the account is unused, just set an arbitrary clientcode)
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
  fiqbot.tyrant.login 1
  set -u0 %task checkconquestmap
  set -u0 %msg getConquestMap
  set -u0 %metadata1 2
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.checkfactionchat {
  if (!%fiqbot_tyrant_chat_ [ $+ [ $1 ] ]) return
  set -u0 %send echo -s factionchatchecking:
  fiqbot.tyrant.login $1
  unset %params
  if ($2) set -u0 %params last_post= $+ $2
  set -u0 %task checkfactionchat
  set -u0 %msg getNewFactionMessages
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.checkfactionmembers {
  fiqbot.tyrant.login $1
  set -u0 %task checkfactionmembers
  set -u0 %msg getFactionMembers
  set -u0 %metadata1 1
  set -u0 %metadata2 0
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.checkfactionname {
  fiqbot.tyrant.login 1
  set -u0 %task checkfactionname
  set -u0 %msg getFactionName
  set -u0 %params $+(faction_id=,$1)
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.checkinvasion {
  var %faction = %fiqbot_tyrant_fid [ $+ [ $1 ] ]
  var %tile = $hget(invasions,$+(tile_,%faction))
  if (!%tile) return

  fiqbot.tyrant.login $1
  set -u0 %task checkinvasion
  set -u0 %msg getConquestTileInfo
  set -u0 %params $+(system_id=,%tile)
  set -u0 %metadata1 1
  set -u0 %metadata2 %faction
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.checkplayername {
  fiqbot.tyrant.login 1
  set -u0 %user $1
  set -u0 %task checkplayername
  set -u0 %msg getName
  set -u0 %params $+(target_id=,%user)
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
  fiqbot.tyrant.login 1
  set -u0 %send echo -s vaultchecking:
  set -u0 %task checkvault
  set -u0 %msg getMarketInfo
  fiqbot.tyrant.runsocket
}
alias fiqbot.tyrant.checkwarinfo {
  var %user_faction = %fiqbot_tyrant_fid [ $+ [ $1 ] ]
  fiqbot.tyrant.login $1
  if (!$hget(wars,$+(nextid,%user_faction))) return
  
  set -u0 %send echo -s warinfochecking:
  var %i = $hget(wars,$+(start,%user_faction))
  while (%i < $hget(wars,$+(nextid,%user_faction))) {
    var %id = $hget(wars,$+(id_,%user_faction,_,%i))
    set -u0 %task checkwarinfo
    set -u0 %msg getFactionWarInfo
    set -u0 %params $+(faction_war_id=,%id)
    fiqbot.tyrant.runsocket
    set -u0 %task checkwarrankings
    set -u0 %msg getFactionWarRankings
    fiqbot.tyrant.runsocket
    inc %i
  }
}
alias fiqbot.tyrant.checkwars {
  fiqbot.tyrant.login $1
  set -u0 %send echo -s warschecking:
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
  fiqbot.tyrant.setsocketvars $1
  echo -s [retrysocket] user %usertarget clientcode %clientcode task %task msg %msg params %params
  fiqbot.tyrant.runsocket $1
}
alias fiqbot.tyrant.runkongsocket {
  ;kill switch in case of mess up
  if (%killsockets) {
    .timers off
    halt
  }

  if (%task != showid) {
    var %db_user = $fiqbot.tyrant.db.select(users,%user)
    if ((%user isnum) && (. !isin %user) || (%db_user)) {
      if (%db_user) {
        if ($gettok(%db_user,0,32) > 1) {
          %send There are several players with this name. The most likely option has been selected. Options are: %db_user (query by ID to get those)
        }
        set -u0 %user $gettok(%db_user,1,32)
      }
      set -u0 %params $+(%params,%user)
      fiqbot.tyrant.runsocket
      return
    }
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
    while (%metadata [ $+ [ %i ] ] != $null) {
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
  set -u0 %task showid
  set -u0 %msg queryUser
  fiqbot.tyrant.runkongsocket
}
alias fiqbot.tyrant.showfaction {
  var %f_id = $int($1)
  set -u0 %metadata1 %f_id
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
  set -u0 %metadata2 $2
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
  set -u0 %metadata2 no
  set -u0 %metadata3 1
  if ($1) set -u0 %metadata1 $1
  if ($2) set -u0 %metadata2 $2-
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
    var %error = Unable to open connection
    %send [API error] Error loading %msg ( $+ %error $+ ) :: Reason for error: $error
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
  %send Error: $error
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
    %send [API error] Error loading %msg ( $+ %error $+ ) :: Reason for error: $error
    return
  }
  if (!%send) set -u0 %send echo -s no-send:
  var %sockcount = 0
  while ($true) {
    inc %sockcount
    if (%sockcount >= 300) {
      %send [Bot error] Likely infinite loop detected, forcing halt. Triggered by $upper(%task)
      return
    }
    if (!%headers_completed) {
      sockread 3000 &temp
      if (!$sockbr) return
      if (%task == raw) echo -s Initial chunk: $bvar(&temp,1,3000).text
      var %headers, %temp
      %temp = $bvar(&temp,$bfind(&temp,1,123),3000).text
      var %headers_completed = 1
      if (!$bfind(&temp,1,123)) {
        if (%task == raw) {
          echo -s Incomplete headers!
          echo -s 
        }
        %headers_completed = 0
        goto done
      }
      %headers = $left($bvar(&temp,1,3000).text,$+(-,$calc($len(%temp) + 2)))
      if (%task == raw) && (%headers_completed) {
        echo -s Headers: %headers
        echo -s 
      }
    }
    else {
      inc %headers_completed
      sockread 2000 &temp
      if (!$sockbr) return
      var %tempold = %temp
      hadd socketdata $+(tempold,%sockid) %temp
      %temp = $bvar(&temp,1,2000).text
    }
    
    if (!%headers_completed) goto done

    hadd socketdata $+(temp,%sockid) %temp
    hadd socketdata $+(headers_completed,%sockid) %headers_completed

    if ($left(%temp,21) == {"duplicate_client":1) && (!%noreidentify) {
      var %clientcode = %fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ]
      if (!%bruteforcing [ $+ [ %usertarget ] ]) {
        echo -s [reidentify] started!
        %fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ] = 0
        set %bruteforcing [ $+ [ %usertarget ] ] %sockid
        hadd socketdata $+(bruteforcing,%sockid) %sockid
        set -u0 %bruteforcing 1
      }
      hdel socketdata $+(temp,%sockid)
      hdel socketdata $+(headers_completed,%sockid)
      sockclose $sockname
      if (%bruteforcing != %sockid) {
        .timer 1 1 fiqbot.tyrant.retrysocket %sockid
        return
      }
      inc %fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ]
      echo -s [reidentify] attempted code %fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ]
      if (%forcedcode [ $+ [ %usertarget ] ]) %fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ] = %clientcode
      if (%fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ] > 1000) {
        echo -s [API warning] Failed to re-identify (did you refresh page twice?)! Re-trying...
        %fiqbot_tyrant_clientcode [ $+ [ %usertarget ] ] = 0
      }
      fiqbot.tyrant.runsocket %sockid
      return
    }
    elseif (%bruteforcing) || (%bruteforcing [ $+ [ %usertarget ] ]) {
      unset %bruteforcing [ $+ [ %usertarget ] ]
      unset %bruteforcing
      set -u5 %forcedcode [ $+ [ %usertarget ] ] 1
      hdel socketdata $+(bruteforcing,%sockid)
    }
    if (!$sockbr) goto done
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
    echo -s returned data: %temp
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
    set -u0 %metadata1 $json(%temp,username)
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
    if (%headers_completed == 1) %send User %usertarget :: %temp
    goto done
    :CHECKCONQUESTMAP
    var %id, %x, %y, %owner_id, %owner_name, %attacker_id, %attacker_name, %attacker_start, %attacker_end, %cr, %protection_end, %bg, %nextid
    var %atk_check, %bg_check, %id_check
    var %trackerchannel = $fiqbot.tyrant.trackerchannel
    var %cqinfo = msg $fiqbot.tyrant.trackerchannel [CONQUEST]
    if (!%trackerchannel) %cqinfo = noop
    %temp = %tempold $+ %temp
    tokenize 44 %temp
    %counter = 0
    %first = %metadata1
    %nextid = $hget(conquest,nextid)
    if (!%nextid) %nextid = 0
    while ($18) {
      inc %counter 17
      if (%first) {
        if (%first == 2) {
          dec %first
          %counter = 1
          tokenize 44 $right(%temp,- $+ $len($gettok(%temp,1- $+ %counter,44)))
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
      if (%id_check != system_id) || (!%id) {
        tokenize 44 $right(%temp,- $+ $len($gettok(%temp,1- $+ %counter,44)))
        continue
      }
      %x = $noqt($gettok($2,2,58))
      %y = $noqt($gettok($3,2,58))
      %cr = $noqt($gettok($7,2,58))
      %owner_id = $noqt($gettok($4,2,58))
      %owner_name = $noqt($remove($gettok($11,2,58),\))
      %protection_end = $noqt($gettok($12,2,58))
      /*
      default JSON is:
      13 - attacker_id
      14 - attacker_name
      15 - attacker_end
      16 - attacker_start
      17 - bg

      if owner is AI, owner_name is missing (shifting everything past it by 1)
      if none is attacking, attacker_* (besides ID) is missing, shift bg by 3
      */

      var %13 = 13

      if (%owner_id == null) {
        dec %counter
        dec %13
        %owner_id = 0
        %owner_name = $null
        %protection_end = 0
      }
      var %14 = %13 + 1, %15 = %13 + 2, %16 = %13 + 3, %17 = %13 + 4
      %attacker_id = $noqt($gettok($ [ $+ [ %13 ] ],2,58))
      %attacker_name = $noqt($remove($gettok($ [ $+ [ %14 ] ],2,58),\))
      %attacker_start = $noqt($remove($gettok($ [ $+ [ %16 ] ],2,58),$chr(125),$chr(93)))
      %attacker_end = $noqt($remove($gettok($ [ $+ [ %15 ] ],2,58),$chr(125),$chr(93)))
      %bg = $noqt($remove($gettok($ [ $+ [ %17 ] ],2,58),$chr(125),$chr(93)))

      %atk_check = $noqt($gettok($ [ $+ [ %14 ] ],1,58))
      %bg_check = $noqt($gettok($ [ $+ [ %17 ] ],1,58))
      if (%atk_check != attacking_faction_name) {
        dec %counter 3
        %attacker_id = 0
        %attacker_name = $null
        %attacker_start = 0
        %attacker_end = 0
        %bg = $noqt($remove($gettok($ [ $+ [ %14 ] ],2,58),$chr(125)))
        %bg_check = $noqt($gettok($ [ $+ [ %14 ] ],1,58))
      }
      if (%bg_check != effect) {
        dec %counter
        %bg = 0
      }

      if (%nextid <= %id) {
        %nextid = %id + 1
        hadd conquest nextid %nextid
      }
      if ($hget(conquest,$+(cr,%id))) {
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

          if (%owner_id) {
            fiqbot.tyrant.addfaction %owner_id %owner_name
          }
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

          if (%attacker_id) {
            if (%attacker_name != ???) fiqbot.tyrant.addfaction %attacker_id %attacker_name
            else {
              %cqinfo Triggered bug: bad faction name received. See http://www.kongregate.com/forums/65-tyrant/topics/148198-tyrant-errors?page=194#posts-7692295-row
            }
          }
        }
      }
      else {
        hadd conquest $+(x,%id) %x
        hadd conquest $+(y,%id) %y
        hadd conquest $+(cr,%id) %cr
        hadd conquest $+(bg,%id) %bg
      }
      if (!$hget(conquest,$+(id,%x,_,%y))) {
        hadd conquest $+(id,%x,_,%y) %id
      }
      

      tokenize 44 $right(%temp,- $+ $len($gettok(%temp,1- $+ %counter,44)))
    }
    %temp = $right(%temp,- $+ $calc($len($gettok(%temp,1- $+ %counter,44)) + 1))
    hadd socketdata $+(temp,%sockid) %temp
    goto done
    :CHECKFACTIONCHAT
    tokenize 44 %temp
    set %fm.message. $+ %usertarget $+ . $+ %headers_completed %temp
    goto done
    :CHECKFACTIONMEMBERS
    var %id, %level, %name, %faction_id, %applicant, %rank, %active, %lp, %cq_claimed, %items, %spam_counter
    var %trackerchannel = $fiqbot.tyrant.trackerchannel
    var %finfo = msg $fiqbot.tyrant.trackerchannel [FACTION]
    var %minfo = msg $fiqbot.tyrant.trackerchannel [MEMBER]
    if (!%trackerchannel) {
      %finfo = noop
      %minfo = noop
    }
    %temp = %tempold $+ %temp
    tokenize 44 %temp
    %counter = 0
    var %first = %metadata1
    var %members = %metadata2
    while ($11) {
      inc %counter 8
      %id = $noqt($gettok($1,3,58))
      if (%first) {
        %id = $noqt($gettok($1,4,58))
        %first = 0
        hadd socketdata $+(metadata1_,%sockid) 0
        set -u0 %metadata1 0
      }
      %level = $noqt($gettok($8,2,58))
      %name = $noqt($gettok($9,2,58))
      %faction_id = $noqt($gettok($2,2,58))
      %applicant = $noqt($gettok($3,2,58))
      %rank = $noqt($gettok($4,2,58))
      %active = $noqt($gettok($5,2,58))
      %lp = $noqt($gettok($6,2,58))
      %cq_claimed = $noqt($gettok($7,2,58))
      var %foundnext, %nextcheck, %nextid
      %foundnext = 0
      var %i = 9
      while (%i < $0) {
        inc %i
        inc %counter
        %nextcheck = $noqt($remove($gettok($ [ $+ [ %i ] ],2,58),$chr(123)))
        %nextid = $noqt($gettok($ [ $+ [ %i ] ],3,58))

        if (%nextcheck == user_id) && (%nextid isnum) {
          %foundnext = 1
          break
        }
        elseif ($noqt($gettok($ [ $+ [ %i ] ],1,58)) == applicants) {
          %foundnext = 2
          break
        }
      }
      if (!%foundnext) {
        dec %i
        dec %counter %i
        break
      }
      if (%id) {
        inc %members
        fiqbot.tyrant.addplayer %id %name

        var %faction_name = Faction ID %faction_id
        if ($hget(factions,$+(name,%faction_id))) %faction_name = $hget(factions,$+(name,%faction_id))

        var %idx = $+(_,%faction_id,_,%id)
        var %fc = %fiqbot_tyrant_factionchannel_ [ $+ [ %usertarget ] ]
        var %fc.send = msg %fc [FACTION]
        var %newmember = $false

        var %usercheck = $hget(factiondata,$+(usercheck,%faction_id))
        if (!%usercheck) %usercheck = 0
        if (%members != 1) dec %usercheck
        var %usercheck_current = $hget(userdata,$+(usercheck,%idx))
        if (!%usercheck_current) %usercheck_current = -11
        if (%usercheck_current < $calc(%usercheck - 10)) {
          if (%spam_counter < 5) {
            if (%spam_counter < 4) {
              %finfo %name joined %faction_name
              %fc.send %name joined the faction
            }
            else {
              %finfo (...)
              %fc.send (...)
            }
            inc %spam_counter
          }
          %newmember = $true
        }
        else {
          var %rank_old = $hget(userdata,$+(rank,%idx))
          if (%rank_old != %rank) {
            %finfo %name in %faction_name changed faction rank: $fiqbot.tyrant.factionrank(%rank_old) -> $fiqbot.tyrant.factionrank(%rank)
            %fc.send %name changed faction rank: $fiqbot.tyrant.factionrank(%rank_old) -> $fiqbot.tyrant.factionrank(%rank)
          }

          var %level_old = $hget(userdata,$+(level,%id))
          if (%level_old != %level) {
            %minfo %name reached level %level
          }
        }
        inc %usercheck
        hadd factiondata $+(usercheck,%faction_id) %usercheck

        hadd userdata $+(name,%id) %name
        hadd userdata $+(level,%id) %level
        hadd userdata $+(faction,%id) %faction_id
        var %stamina = $hget(userdata,$+(stamina,%id))
        if (!%stamina) {
          %stamina = $ctime
          hadd userdata $+(stamina,%id) %stamina
        }

        hadd userdata $+(usercheck,%idx) %usercheck
        hadd userdata $+(member_until,%idx) $ctime
        hadd userdata $+(applicant,%idx) %applicant
        hadd userdata $+(rank,%idx) %rank
        hadd userdata $+(active,%idx) %active
        hadd userdata $+(lp,%idx) %lp
        hadd userdata $+(cq_claimed,%idx) %cq_claimed
      }
      if (%foundnext == 2) {
        hdel socketdata $+(temp,%sockid)
        %temp = $null
        sockclose $sockname
        return
      }
      tokenize 44 $right(%temp,- $+ $len($gettok(%temp,1- $+ %counter,44)))
    }
    %temp = $right(%temp,- $+ $calc($len($gettok(%temp,1- $+ %counter,44)) + 1))
    set -u0 %metadata2 %members
    hadd socketdata $+(metadata2_,%sockid) %metadata2
    hadd socketdata $+(temp,%sockid) %temp
    goto done
    :CHECKFACTIONNAME
    var %id, %name, %timecheck, %nextid
    tokenize 44 %temp
    var %trackerchannel = $fiqbot.tyrant.trackerchannel
    var %finfo = msg $fiqbot.tyrant.trackerchannel [FACTION]
    if (!%trackerchannel) %finfo = noop
    %id = $noqt($gettok($1,2,58))
    %name = $noqt($gettok($2,2,58))
    %timecheck = $noqt($gettok($3,1,58))

    if (%timecheck != time) return
    if (%name == ???) return

    %finfo %name was recently created.
    fiqbot.tyrant.addfaction %id %name
    goto done
    :CHECKINVASION
    var %tile, %slot, %id, %hp, %commander, %commandername, %oldhp, %oldcommander, %oldcommandername, %systemcheck, %counter, %maxhp

    var %fc = %fiqbot_tyrant_factionchannel_ [ $+ [ %usertarget ] ]
    var %fc.send = msg %fc [INVASION]

    var %user_faction = %fiqbot_tyrant_fid [ $+ [ %usertarget ] ]

    %temp = %tempold $+ %temp
    tokenize 44 %temp
    %counter = 0
    while ($7) || ($right(%temp,4) == }}}}) {
      %systemcheck = $noqt($gettok($2,1,58))
      echo -s debug: %systemcheck
      if (%systemcheck == system) {
        if (!$20) break
        inc %counter 19
        %tile = $noqt($gettok($2,3,58))
        %maxhp = $noqt($gettok($19,2,58))
        if (!$hget(invasions,$+(maxhp,%tile))) hadd invasions $+(maxhp,%tile) %maxhp
        if ($hget(invasions,$+(maxhp,%tile)) != %maxhp) {
          %fc.send Max HP changed: $hget(invasions,$+(maxhp,%tile)) -> %maxhp
          hadd invasions $+(maxhp,%tile) %maxhp
        }
        tokenize 44 $right(%temp,- $+ $calc($len($gettok(%temp,1- $+ %counter,44)) + 1))
        continue
      }
      echo -s debug: $1-6
      inc %counter 6
      %tile = $noqt($gettok($1,4,58))
      if (!%tile) %tile = $noqt($gettok($1,3,58))
      %slot = $noqt($gettok($2,2,58))
      %hp = $noqt($gettok($3,2,58))
      %commander = $noqt($gettok($5,2,58))
      tokenize 44 $right(%temp,- $+ $calc($len($gettok(%temp,1- $+ %counter,44)) + 1))

      %id = $+(_,%tile,_,%slot)
      %maxhp = $hget(invasions,$+(maxhp,%tile))

      if (!$hget(invasions,$+(active,%id))) {
        if (!$hget(invasions,$+(slots,%tile))) hadd invasions $+(slots,%tile) 0
        hinc invasions $+(slots,%tile)
        hadd invasions $+(active,%id) 1
        hadd invasions $+(hp,%id) %hp
        hadd invasions $+(commander,%id) %commander
        hadd invasions $+(changed,%id) 0
      }
      %oldhp = $hget(invasions,$+(hp,%id))
      %oldcommander = $hget(invasions,$+(commander,%id))
      %commandername = $hget(cards,$+(name,%commander))
      %oldcommandername = $hget(cards,$+(name,%oldcommandername))

      if (%oldhp) && (!%hp) {
        %fc.send Slot %slot has been defeated!
      }
      if (%oldcommander != %commander) {
        %fc.send Slot %slot changed commander: %oldcommandername -> %commandername
        hadd invasions $+(changed,%id) $ctime
      }
      hadd invasions $+(hp,%id) %hp
      hadd invasions $+(commander,%id) %commander
    }
    %temp = $right(%temp,- $+ $calc($len($gettok(%temp,1- $+ %counter,44)) + 1))
    hadd socketdata $+(temp,%sockid) %temp
    goto done
    :CHECKPLAYERNAME
    var %id, %name, %timecheck, %nextid
    tokenize 44 %temp
    %id = %user
    %name = $gettok($1,2,58)
    if (%name == null) return

    %name = $noqt(%name)
    %timecheck = $noqt($gettok($2,1,58))

    if (%timecheck != time) return
    if (%name == ???) return

    fiqbot.tyrant.addplayer %id %name
    goto done
    :CHECKTARGETS
    var %id, %idp, %idx, %name, %namecheck, %fp, %infamy, %infamy_old %nerf, %targetcounter, %pointer, %nextid, %own_id
    if ($left(%temp,11) != {"rivals":[) continue
    tokenize 44 %temp
    %own_id = %fiqbot_tyrant_fid [ $+ [ %usertarget ] ]
    %targets = $false
    %targetcounter = 0
    while ($5) {
      inc %targetcounter
      %id = $noqt($gettok($1,3,58))
      if (!%id) %id = $noqt($gettok($1,2,58))
      %idx = $+(_,%own_id,_,%id)
      %name = $remove($noqt($gettok($2,2,58)),\)
      %namecheck = $noqt($gettok($2,1,58))
      if (%namecheck != name) {
        tokenize 44 $right(%temp,- $+ $len($gettok(%temp,1- $+ $calc(5 * %targetcounter),44)))
        continue
      }
      if (!%name) {
        %name = ???
      }
      %fp = $noqt($gettok($3,2,58))
      %infamy = $gettok($4,2,58)
      %infamy_old = $hget(factiondata,$+(infamy_gain,%id))
      %nerf = $noqt($remove($gettok($5,2,58),$chr(125),$chr(93)))

      fiqbot.tyrant.addfaction %id %name

      hadd factiondata $+(fp,%id) %fp
      hadd factiondata $+(infamy_gain,%id) %infamy
      hadd factiondata $+(nerf,%idx) %nerf

      if (%infamy_old != %infamy) {
        hadd factiondata $+(upcomingtarget,%id) $calc($ctime + 3600*6)
        if (%infamy == 0) { hadd factiondata $+(upcomingtarget,%id) 0 }
        elseif (%infamy > %infamy_old) hadd factiondata $+(upcomingtarget,%id) $calc($ctime + 3600*6)
      }

      if (!$hget(targets,$+(pointer,%idx))) {
        %nextid = $hget(targets,$+(nextid,%own_id))
        if (!%nextid) {
          %nextid = 1
          hadd targets $+(nextid,%own_id) %nextid
        }
        hinc targets $+(nextid,%own_id)

        %idp = $+(_,%own_id,_,%nextid)
        hadd targets $+(id,%idp) %id
        hadd targets $+(pointer,%idx) %nextid
      }

      if (($hget(factiondata,$+(upcomingtarget,%id)) < $ctime) && (%infamy)) {
        hinc factiondata $+(upcomingtarget,%id) $calc(3600 * 6)
      }
      tokenize 44 $right(%temp,- $+ $len($gettok(%temp,1- $+ $calc(5 * %targetcounter),44)))
    }
    goto done
    
    :CHECKWARINFO
    var %id, %idcheck, %idx, %friend, %opponent, %friend_name, %opponent_name %start, %completed, %atk, %def, %diff, %end, %atkfp, %deffp

    var %user_faction = %fiqbot_tyrant_fid [ $+ [ %usertarget ] ]
    tokenize 44 %temp

    %idcheck = $noqt($remove($gettok($1,1,58),$chr(123)))
    if (%idcheck != faction_war_id) goto done
    
    %id = $noqt($gettok($1,2,58))
    %idx = $+(_,%user_faction,_,%id)
    %friend = $noqt($gettok($2,2,58))
    %opponent = $noqt($gettok($3,2,58))
    %friend_name = $hget(factions,$+(name,%friend))
    %opponent_name = $hget(factions,$+(name,%opponent))
    %start = $noqt($gettok($4,2,58))
    %completed = $noqt($gettok($6,2,58))
    %atk = $noqt($gettok($7,2,58))
    %def = $noqt($gettok($8,2,58))
    %atkfp = $noqt($gettok($11,2,58))
    %deffp = $noqt($gettok($12,2,58))
    %diff = %atk - %def
    %end = Ended $fiqbot.tyrant.duration($calc($ctime - ( %start + 3600 * 6 ) )) ago
    if (%friend != %user_faction) {
      %diff = $calc(%diff * -1)
      var %atkfptmp = %atkfp
      %atkfp = %deffp
      %deffp = %atkfptmp
    }
    if (- !isin %diff) %diff = + $+ %diff
    if (- !isin %atkfp) %atkfp = + $+ %atkfp
    if (- !isin %deffp) %deffp = + $+ %deffp
    if (%completed) {
      if (!$hget(wardata,$+(completed,%idx))) {
        hadd wardata $+(completed,%idx) 1
        msg %fiqbot_tyrant_factionchannel_ [ $+ [ %usertarget ] ] War finished! %id :: $+(%friend_name,-,%opponent_name) :: $+(%atk,-,%def) ( $+ %diff $+ ) :: FP gains: $+(Us,%atkfp) $+(Them,%deffp) :: %end
      }
    }
    goto done
    
    :CHECKWARRANKINGS
    var %id, %idx, %war, %win.off, %win.def, %win.pts, %loss.off, %loss.def, %loss.pts, %net, %faction, %fights
    var %defstat.win, %defstat.loss, %defstat.winpts, %defstat.losspts, %defstat.net

    ;check if the request is finished
    var %timecheck

    var %user_faction = %fiqbot_tyrant_fid [ $+ [ %usertarget ] ]

    %temp = %tempold $+ %temp
    tokenize 44 %temp
    %counter = 0
    while ($12) {
      inc %counter 11
      %id = $noqt($gettok($1,4,58))
      if (!%id) %id = $noqt($gettok($1,3,58))
      if (!%id) %id = $noqt($gettok($1,2,58))
      %war = $noqt($gettok($2,2,58))
      %win.off = $noqt($gettok($3,2,58))
      %loss.off = $noqt($gettok($4,2,58))
      %win.pts = $noqt($gettok($5,2,58))
      %faction = $noqt($gettok($7,2,58))
      %loss.pts = $noqt($gettok($8,2,58))
      %win.def = $noqt($gettok($10,2,58))
      %loss.def = $noqt($remove($gettok($11,2,58),$chr(125),$chr(93)))
      tokenize 44 $right(%temp,- $+ $calc($len($gettok(%temp,1- $+ %counter,44)) + 1))
      %net = %win.pts - %loss.pts
      %fights = %win.off + %loss.off
      %timecheck = $noqt($gettok($12,1,58))
      if (%timecheck == time) {
        var %idy = $+(_,%user_faction,_,%war)
        var %pointer = $hget(wars,$+(pointer,%idy))
        if (%pointer == $hget(wars,$+(start,%user_faction))) && ($hget(wardata,$+(completed,%idy))) {
          hinc wars $+(start,%user_faction)
        }
      }
      %idx = $+(_,%war,_,%id)
      if (!$hget(wardata,$+(log,%idx))) {
        hadd wardata $+(log,%idx) 1
        hadd wardata $+(winoff,%idx) 0
        hadd wardata $+(lossoff,%idx) 0
        hadd wardata $+(winpts,%idx) 0
        hadd wardata $+(losspts,%idx) 0
        hadd wardata $+(windef,%idx) 0
        hadd wardata $+(lossdef,%idx) 0
        hadd wardata $+(faction,%idx) %faction
        hadd wardata $+(net,%idx) 0
        hadd wardata $+(fights,%idx) 0
        hadd wardata $+(defstatwin,%idx) 0
        hadd wardata $+(defstatloss,%idx) 0
        hadd wardata $+(defstatwinpts,%idx) 0
        hadd wardata $+(defstatlosspts,%idx) 0
        hadd wardata $+(defstatnet,%idx) 0
      }
      if (%win.pts == $hget(wardata,$+(winpts,%idx))) && (%loss.pts == $hget(wardata,$+(losspts,%idx))) {
        continue
      }
      %defstat.win = $iif($hget(wardata,$+(defstatwin,%idx)),$v1,0)
      %defstat.loss = $iif($hget(wardata,$+(defstatloss,%idx)),$v1,0)
      %defstat.winpts = $iif($hget(wardata,$+(defstatwinpts,%idx)),$v1,0)
      %defstat.losspts = $iif($hget(wardata,$+(defstatlosspts,%idx)),$v1,0)
      %defstat.net = $iif($hget(wardata,$+(defstatnet,%idx)),$v1,0)

      if (%win.off == $hget(wardata,$+(winoff,%idx))) && (%loss.off == $hget(wardata,$+(lossoff,%idx))) {
        inc %defstat.win $calc(%win.def - $hget(wardata,$+(windef,%idx)))
        inc %defstat.loss $calc(%loss.def - $hget(wardata,$+(lossdef,%idx)))
        inc %defstat.winpts $calc(%win.pts - $hget(wardata,$+(winpts,%idx)))
        inc %defstat.losspts $calc(%loss.pts - $hget(wardata,$+(losspts,%idx)))
        inc %defstat.net $calc(%net - $hget(wardata,$+(net,%idx)))
      }
      elseif (%fights != $hget(wardata,$+(fights,%idx))) {
        var %stamina = $hget(userdata,$+(stamina,%id))
        if (%stamina) {
          if (%stamina < $ctime) %stamina = $ctime
          inc %stamina $calc( ( %fights - $hget(wardata,$+(fights,%idx)) ) * 600)
          hadd userdata $+(stamina,%id) %stamina
        }
        hadd userdata $+(waractivity,%id) $ctime
      }
      hadd wardata $+(winoff,%idx) %win.off
      hadd wardata $+(lossoff,%idx) %loss.off
      hadd wardata $+(winpts,%idx) %win.pts
      hadd wardata $+(losspts,%idx) %loss.pts
      hadd wardata $+(windef,%idx) %win.def
      hadd wardata $+(lossdef,%idx) %loss.def
      hadd wardata $+(net,%idx) %net
      hadd wardata $+(fights,%idx) %fights
      hadd wardata $+(defstatwin,%idx) %defstat.win
      hadd wardata $+(defstatloss,%idx) %defstat.loss
      hadd wardata $+(defstatwinpts,%idx) %defstat.winpts
      hadd wardata $+(defstatlosspts,%idx) %defstat.losspts
      hadd wardata $+(defstatnet,%idx) %defstat.net
    }
    %temp = $right(%temp,- $+ $calc($len($gettok(%temp,1- $+ %counter,44)) + 1))
    hadd socketdata $+(temp,%sockid) %temp
    goto done

    :SHOWFACTION
    var %bufferfounder, %founder, %name, %public, %activity, %active, %members, %cap, %level, %fp, %wins, %losses, %infamy, %totalinfamy, %description
    tokenize 44 %temp
    %id = $noqt($gettok($1,2-,58))
    %founder = $noqt($gettok($2,2-,58))
    %bufferfounder = Founder:
    if (!$hget(users,$+(name,%founder))) %bufferfounder = Founder's user ID:
    else %founder = $hget(users,$+(name,%founder))
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
    %description = $gettok($18,2-,58)

    %name = $remove(%name,\)

    %cap = $calc(%level * 5)
    inc %cap 10
    if (%cap > 50) %cap = 50
    %active = $round($calc(%members * %activity * 0.01),0)

    fiqbot.tyrant.addfaction %id %name
    var %buffer
    %buffer = %name
    %buffer = %buffer (Level %level $+ , $+(%fp,FP) $+ )
    %buffer = %buffer :: %bufferfounder %founder
    %buffer = %buffer :: Recruitment: $iif(%public,Public,Private)
    %buffer = %buffer :: Members: $+(%members,/,%cap) ( $+ %active active)
    %buffer = %buffer :: Wars: $+(%wins,/,%losses) W/L
    %buffer = %buffer :: Infamy: $+(%infamy,/,%totalinfamy) current/total
    if (%description != $null) && (%description != null) {

      ;fix for "," in faction description
      if ($left(%description,1) == ") && ($right(%description,1) != ") {
        var %i = 18
        while (%i < $0) {
          inc %i
          %description = %description $+ , $ [ $+ [ %i ] ]
          if ($right(%description,1) == ") break
        }
      }
      %description = $noqt(%description)
      %description = $remove(%description,\)
      %buffer = %buffer :: Message: %description
    }
    if ((%access >= 3) || ((%public) && (%access == 2))) {
      %buffer = %buffer :: Join link: $&
        http://www.kongregate.com/games/synapticon/tyrant?source=finv&kv_apply= $+ %id
    }

    if (%level) %send %buffer
    else {
      %name = $hget(factions,$+(name,%metadata1))
      if (%name != $null) %send %name has been disbanded.
      else %send No such faction ID.
    }
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
      fiqbot.tyrant.addplayer %p_id %p_name
      if (!$hget(userdata)) {
        hmake userdata 10000
      }
      var %p_updated = $hget(userdata,$+(updated,%p_id))
      if (!%p_updated) %p_updated = 0
      if (%p_updated < $calc($ctime - 7200)) hadd userdata $+(updated,%p_id) $ctime
      set -u0 %metadata1 %p_updated
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
          var %trackerchannel = $fiqbot.tyrant.trackerchannel
          if (%trackerchannel) msg %trackerchannel [VAULT] New cards: %buffer :: %end
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
    var %id, %off_id, %friend, %opponent, %end, %atk, %def, %diff, %counter
    %temp = %tempold $+ %temp
    tokenize 44 %temp
    %counter = 0
    while ($15) && (%metadata1) {
      inc %counter 14
      %id = $noqt($gettok($1,3,58))
      if (!%id) %id = $noqt($gettok($1,2,58))
      %off_id = $noqt($gettok($2,2,58))
      %friend = $fiqbot.tyrant.factionname
      %opponent = $noqt($gettok($13,2,58))
      %opponent = $remove(%opponent,\)
      if (!%opponent) %opponent = (none)
      %end = Ended $fiqbot.tyrant.duration($calc(%ctime - ( $noqt($gettok($4,2,58)) + 3600 * 6 ) )) ago
      %atk = $noqt($gettok($7,2,58))
      %def = $noqt($gettok($8,2,58))
      tokenize 44 $right(%temp,- $+ $calc($len($gettok(%temp,1- $+ %counter,44)) + 1))
      if ((%metadata2 != no) && (%metadata2 != %opponent)) {
        continue
      }
      %diff = %atk - %def
      if (%off_id != $fiqbot.tyrant.factionid) {
        %friend = %opponent
        %opponent = $fiqbot.tyrant.factionname
        %diff = $calc( %diff * -1 )
      }
      if (- !isin %diff) %diff = + $+ %diff
      %send %id :: $+(%friend,-,%opponent) :: $+(%atk,-,%def) ( $+ %diff $+ ) :: %end
      dec %metadata1
      hdec socketdata $+(metadata1_,%sockid)
      set -u0 %metadata3 0
      hadd socketdata $+(metadata3_,%sockid) 0
    }
    %temp = $right(%temp,- $+ $calc($len($gettok(%temp,1- $+ %counter,44)) + 1))
    hadd socketdata $+(temp,%sockid) %temp
    if (!%metadata1) {
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
    if (%noalert_settings == global) && (%task == checkwars) return
    var %user_faction = %fiqbot_tyrant_fid [ $+ [ %usertarget ] ]
    %first = $true
    while ($10) {
      inc %warcounter
      if (%first) %id = $noqt($gettok($1,4,58))
      else %id = $noqt($gettok($1,3,58))
      var %idx = $+(_,%user_faction,_,%id)
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
        return
      }
      if (%task == showwars) %send %id :: $+(%friend,-,%opponent) :: $+(%atk,-,%def) ( $+ %diff $+ ) :: %end
      elseif (!$hget(wars,$+(pointer,%idx))) {
        var %nextid = $hget(wars,$+(nextid,%user_faction))
        if (!%nextid) {
          hadd wars $+(start,%user_faction) 1
          %nextid = 1
          hadd wars $+(nextid,%user_faction) %nextid
        }
        hinc wars $+(nextid,%user_faction)

        var %nextidx = $+(_,%user_faction,_,%nextid)
        hadd wars $+(pointer,%idx) %nextid
        hadd wars $+(id,%nextidx) %id
        hadd wardata $+(started,%id) $noqt($gettok($4,2,58))

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
      }
      tokenize 44 $right(%temp,- $+ $len($gettok(%temp,1- $+ $calc(15 * %warcounter),44)))
    }
    if ((!%wars) && (%task == showwars)) { %send No wars! }
    goto done
    :done
    unset %bruteforcing
    if ($sockbr == 0) {
      echo @fiqbot [Bot error] no clean exit
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
  %send Error: $error
  if (!%scriptline) var %scriptline = error
  echo @fiqbot Line %line contains the following: %scriptline
  echo @fiqbot Temp: %temp
  echo @fiqbot Tempold: %tempold
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

  :CHECKFACTIONCHAT
  var %l.count = 1
  var -n %pos.end = }],"time":
  var -n %pos.endline = "},{"
  var -n %pos.nomessage = {"messages":[],"time":
  var -n %temp.f = %fm.message. [ $+ [ $+(%usertarget,.,%l.count) ] ]
  var -n %pos.f = $pos(%temp.f,"faction_id":",1)
  while (!%pos.e) {
    if ($pos(%temp.f,%pos.nomessage,1)) return 
    if (%fm.message. [ $+ [ $+(%usertarget,.,$calc(%l.count + 1)) ] ]) && ($len(%temp.f) <= 315) { var %temp.f = %temp.f $+ %fm.message. [ $+ [ $+(%usertarget,.,$calc(%l.count +1)) ] ] | inc %l.count } 
    var -n %pos.f = $pos(%temp.f,"faction_id":",1)
    var -n %pos.p = $pos(%temp.f,"post_id":",1)
    var -n %pos.m = $pos(%temp.f,"message":",1)
    var -n %pos.t = $pos(%temp.f,"time":",1)
    var -n %pos.u = $pos(%temp.f,"user_id":",1)
    var -n %pos.eol = $pos(%temp.f,%pos.endline,1)
    if (!%pos.eol) var -n %pos.e = $pos(%temp.f,%pos.end,1)
    ;List of positions
    ;faction: $mid(%temp.f,$calc(%pos.f +14),$calc(%pos.p - %pos.f -16)) Postid: $mid(%temp.f,$calc(%pos.p +11),$calc(%pos.m - %pos.p -13)) message: $remove($mid(%temp.f,$calc(%pos.m +11),$calc(%pos.t - %pos.m -13)),\) time: $mid(%temp.f,$calc(%pos.t +8),$calc(%pos.u - %pos.t -10)) userid: $iif($hget(users,name $+ $mid(%temp.f,$calc(%pos.u +11),$iif(%pos.eol,$calc(%pos.eol - %pos.u - 11),$calc(%pos.e - %pos.u -12)))),$ifmatch,$mid(%temp.f,$calc(%pos.u +11),$iif(%pos.eol,$calc(%pos.eol - %pos.u - 11),$calc(%pos.e - %pos.u -12)))))
    var -n %x = [FACTIONCHAT] $iif($hget(users,name $+ $mid(%temp.f,$calc(%pos.u +11),$iif(%pos.eol,$calc(%pos.eol - %pos.u - 11),$calc(%pos.e - %pos.u -12)))),$ifmatch,$mid(%temp.f,$calc(%pos.u +11),$iif(%pos.eol,$calc(%pos.eol - %pos.u - 11),$calc(%pos.e - %pos.u -12))))) $+ $chr(58) $remove($mid(%temp.f,$calc(%pos.m +11),$calc(%pos.t - %pos.m -13)),\) 
    if (last_post= isin %params) && (%pos.f) msg %fiqbot_tyrant_factionchannel_ [ $+ [ %usertarget ] ] %x 
    if (%pos.eol) var %temp.f = $remove(%temp.f,$left(%temp.f,$calc(%pos.eol +3)))
  }
  if ($mid(%temp.f,$calc(%pos.p +11),$calc(%pos.m - %pos.p -13)) isnum) set %last.post.id. $+ %usertarget $mid(%temp.f,$calc(%pos.p +11),$calc(%pos.m - %pos.p -13))
  unset %fm.*
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
    %f_access = $fiqbot.tyrant.factionrank(%f_access)
    %f_lp = $left(%f_lp,-2)
    if (%f_lp >= 0) {
      %buffer = %buffer :: %f_access of %f_name (Level %f_level $+ , %f_fp $+ FP, $+(%f_wins,/,%f_losses) W/L) with %f_lp $+ LP

      fiqbot.tyrant.addfaction %f_id %f_name
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
  var %user_faction = %fiqbot_tyrant_fid [ $+ [ %usertarget ] ]
  var %idx = $+(_,%user_faction,_,%p_id)
  var %usercheck_faction = $hget(factiondata,$+(usercheck,%user_faction))
  var %usercheck_player = $hget(userdata,$+(usercheck,%idx))
  if (%usercheck_player) {
    var %rank, %active, %ctime_days, %lp, %cq_claimed, %items, %member_until, %stamina, %waractivity, %waractivity_timer
    %rank = $hget(userdata,$+(rank,%idx))
    %active = $hget(userdata,$+(active,%idx))
    %lp = $hget(userdata,$+(lp,%idx))
    %cq_claimed = $hget(userdata,$+(cq_claimed,%idx))
    %member_until = $hget(userdata,$+(member_until,%idx))
    %stamina = $hget(userdata,$+(stamina,%p_id))
    %waractivity = $hget(userdata,$+(waractivity,%p_id))
    %waractivity_timer = $fiqbot.tyrant.duration($calc($ctime - %waractivity)) ago
    if (!%waractivity) %waractivity_timer = (never)

    %ctime_days = $int($calc($ctime / 86400))
    %active = %ctime_days - %active
    if (!%active) %active = today
    else %active = $+(%active,d ago)

    if (%usercheck_faction == %usercheck_player) {
      %buffer = Stamina: $fiqbot.tyrant.energy(%stamina,300).showcap
      %buffer = %buffer :: Last active: %active (last war fight was %waractivity_timer $+ )
      %buffer = %buffer :: Tokens last claimed: $fiqbot.tyrant.duration($calc($ctime - %cq_claimed)) ago
    }
    else {
      %buffer = Former $fiqbot.tyrant.factionrank(%rank) of $hget(factions,$+(name,%user_faction))
      %buffer = %buffer :: LP: %lp
      %buffer = %buffer :: Left faction: $fiqbot.tyrant.duration($calc($ctime - %member_until)) ago
    }
    %send %buffer
    if (%usercheck_faction == %usercheck_player) {
      var %win.off, %win.def, %win.pts, %loss.off, %loss.def, %loss.pts, %fights, %net
      var %defstat.win, %defstat.winpts, %defstat.loss, %defstat.losspts, %defstat.net
      var %days = %metadata2
      var %daystime = $calc($ctime - %days * 86400)
      var %i = 1
      while (%i < $hget(wars,$+(nextid,%user_faction))) {
        var %war = $hget(wars,$+(id_,%user_faction,_,%i))
        if ($hget(wardata,$+(started,%war)) < %daystime) {
          inc %i
          continue
        }
        %idx = $+(_,%war,_,%p_id)
        %win.off = $calc(%win.off + $hget(wardata,$+(winoff,%idx)))
        %win.def = $calc(%win.def + $hget(wardata,$+(windef,%idx)))
        %win.pts = $calc(%win.pts + $hget(wardata,$+(winpts,%idx)))
        %loss.off = $calc(%loss.off + $hget(wardata,$+(lossoff,%idx)))
        %loss.def = $calc(%loss.def + $hget(wardata,$+(lossdef,%idx)))
        %loss.pts = $calc(%loss.pts + $hget(wardata,$+(losspts,%idx)))
        %defstat.win = $calc(%defstat.win + $hget(wardata,$+(defstatwin,%idx)))
        %defstat.winpts = $calc(%defstat.winpts + $hget(wardata,$+(defstatwinpts,%idx)))
        %defstat.loss = $calc(%defstat.loss + $hget(wardata,$+(defstatloss,%idx)))
        %defstat.losspts = $calc(%defstat.losspts + $hget(wardata,$+(defstatlosspts,%idx)))
        inc %i
      }
      %fights = %win.off + %loss.off
      %net = %win.pts - %loss.pts
      %defstat.net = %defstat.winpts - %defstat.losspts
      if (- !isin %net) %net = + $+ %net
      if (- !isin %defstat.net) %defstat.net = + $+ %defstat.net
      %buffer = Netscore over $+(%days,d)
      if (!%win.pts) && (!%loss.pts) %buffer = %buffer :: No data
      else {
        %buffer = %buffer :: %fights fights total
        %buffer = %buffer :: Offensive: $+(%win.off,/,%loss.off) W/L
        %buffer = %buffer :: Defensive: $+(%win.def,/,%loss.def) W/L
        %buffer = %buffer :: Netscore: $+(%win.pts,-,%loss.pts) ( $+ %net $+ )
        if (!%defstat.winpts) && (!%defstat.losspts) var %defstat = No data
        else var %defstat = $+(%defstat.winpts,-,%defstat.losspts) ( $+ %defstat.net $+ ), accounted for $+(%defstat.win,/,%defstat.loss) defense W/L
        %buffer = %buffer :: Defensive netscore: %defstat
      }
      %send %buffer
    }
  }
  return

  :SHOWWARLOG
  if (%metadata3) {
    var %buffer = No earlier wars
    if (%metadata2 != no) %buffer = %buffer with %metadata3
    %send %buffer
    return
  }

  ;unused labels
  :CHECKCONQUESTMAP
  :CHECKFACTIONMEMBERS
  :CHECKFACTIONNAME
  :CHECKPLAYERNAME
  :CHECKTARGETS
  :CHECKVAULT
  :CHECKWARINFO
  :CHECKWARRANKINGS
  :CHECKWARS
  :SHOWFACTION
  :SHOWID
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
  %send Error: $error
  if (!%scriptline) var %scriptline = error
  %send Line %line contains the following: %scriptline
  .reseterror
}
