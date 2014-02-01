on *:START:{
  var %dir = $fiqbot.tyrant.directory
  if ($exists($+(%dir,tables\cards.fht))) {
    var %hload = fiqbot.tyrant.hload
    %hload cards
    %hload raids
    return
  }
  timer 1 30 fiqbot.tyrant.downloadresources
}
alias fiqbot.tyrant.downloadresources {
  ;cards.xml
  if (!$hget(cards)) hmake cards 1000
  if ($sock(tyrantcards)) sockclose tyrantcards
  sockopen tyrantcards kg-dev.tyrantonline.com 80

  ;raids.xml
  if (!$hget(raids)) hmake raids 10
  if ($sock(tyrantraids)) sockclose tyrantraids
  sockopen tyrantraids kg-dev.tyrantonline.com 80
}
alias fiqbot.tyrant.downloadxml {
  if (!%send) set -u0 %send echo -s downloadxml:
  var %dir = $+($fiqbot.tyrant.directory,xml\)
  if (.. isin $1) || (/ isin $1) {
    %send [DownloadXML error] Bad filename
    halt
  }

  var %file = $+(%dir,$1,.xml)
  if ($exists(%file)) {
    if ($1 == cards) {
      %fiqbot_tyrant_cards_md5 = $md5($1,2)
    }
    .remove %file
  }
  var %socket = $+(tyrantxml_,$1)
  if ($sock(%socket)) sockclose %socket
  sockopen %socket kg-dev.tyrantonline.com 80
}
alias -l fiqbot.tyrant.setsocketvars {
  set -u0 %name $remove($1,tyrantxml_)
  set -u0 %dir $+($fiqbot.tyrant.directory,xml\)
  set -u0 %file $+(%dir,%name,.xml)
}
on *:SOCKOPEN:tyrantxml_*:{
  fiqbot.tyrant.setsocketvars $sockname
  sockwrite -n $sockname GET $+(/assets/,%name,.xml) HTTP/1.0
  sockwrite -n $sockname Host: kg-dev.tyrantonline.com
  sockwrite -n $sockname user-agent: fiqbot/3
  sockwrite -n $sockname Connection: Keep-Alive
  sockwrite -n $sockname $crlf
}
on *:SOCKREAD:tyrantxml_*:{
  fiqbot.tyrant.setsocketvars $sockname
  var %read
  while ($true) {
    if (!$sock($sockname).mark) {
      sockread %read

      if (%read == $null) {
        sockmark $sockname 1
      }
    }
    else {
      sockread &temp
      .bwrite %file -1 -1 &temp
    }
    if (!$sockbr) return
  }
}
on *:SOCKCLOSE:tyrantxml_*:{
  fiqbot.tyrant.setsocketvars $sockname
  if (%name == cards) {
    var %old_md5 = %fiqbot_tyrant_cards_md5
    var %new_md5 = $md5(%file,2)
    set %fiqbot_tyrant_cards_md5 %new_md5
    if (!%old_md5) return
    var %amsg_chans = %fiqbot_tyrant_spoiler_subscriptions
    if (%old_md5 != %new_md5) && (%amsg_chans) {
      msg %amsg_chans [SPOILER] New card spoilers are up! See http://haileon.com/TyrantDEV for details. $me will rebuild databases shortly, and will become unresponsive. :: Debug: %old_md5 != %new_md5
      timer 1 60 fiqbot.tyrant.downloadresources
    }
  }
}
on *:SOCKOPEN:tyrantcards:{
  sockwrite -n $sockname GET /assets/cards.xml HTTP/1.0
  sockwrite -n $sockname Host: kg-dev.tyrantonline.com
  sockwrite -n $sockname user-agent: fiqbot/3
  sockwrite -n $sockname Connection: Keep-Alive
  sockwrite -n $sockname $crlf
}
on *:SOCKOPEN:tyrantraids:{
  sockwrite -n $sockname GET /assets/raids.xml HTTP/1.0
  sockwrite -n $sockname Host: kg-dev.tyrantonline.com
  sockwrite -n $sockname user-agent: fiqbot/3
  sockwrite -n $sockname Connection: Keep-Alive
  sockwrite -n $sockname $crlf
}  
on *:SOCKREAD:tyrantcards:{
  if ($sockerr > 0) return
  var %ignore, %unit, %id, %type, %name, %attack, %health, %cost, %rarity, %faction, %set, %skillid, %skillname, %skillcount, %skillall, %skilltarget, %skillonplay, %skillondeath, %skillonattack, %skillonkill, %unique, %hidden
  while ($true) {
    sockread %temp
    if (<!-- isin %temp) {
      %ignore = $true
    }
    if (--> isin %temp) {
      %ignore = $false
    }
    if (<unit> isin %temp) {
      %unit = $true
      %id = 0
      %skillid = 1
      %hidden = 0
      %set = 0
    }
    if (</unit> isin %temp) {
      %unit = $false
      %hidden = 0
      if (!$hget(cards,$+(id,$remove(%name,$chr(32))))) {
        hadd cards $+(id,$remove(%name,$chr(32))) %id
      }
      if (, isin %name) && (!$hget(cards,$+(id,$remove(%name,$chr(32),$chr(44))))) {
        hadd cards $+(id,$remove(%name,$chr(32),$chr(44))) %id
      }
      %id = 0
      %skillid = 0
    }
    set %temp $remove(%temp,	)
    if (%unit) && (!%ignore) {
      if (<id> isin %temp) {
        %id = $remove(%temp,<id>,</id>)
      }
      elseif (<name> isin %temp) {
        %name = $remove(%temp,<name>,</name>)
        hadd cards $+(name,%id) %name
        if (%id < 1000) || (%id >= 4000) %type = 4
        elseif (%id < 2000) %type = 1
        elseif (%id < 3000) %type = 2
        else %type = 3
        hadd cards $+(type,%id) %type
      }
      elseif (<hidden> isin %temp) {
        %hidden = $remove(%temp,<hidden>,</hidden>)
        hadd cards $+(hidden,%id) %hidden
      }
      elseif (<attack> isin %temp) {
        %attack = $remove(%temp,<attack>,</attack>)
        hadd cards $+(attack,%id) %attack
      }
      elseif (<health> isin %temp) {
        %health = $remove(%temp,<health>,</health>)
        hadd cards $+(health,%id) %health
      }
      elseif (<cost> isin %temp) {
        %cost = $remove(%temp,<cost>,</cost>)
        hadd cards $+(cost,%id) %cost
      }
      elseif (<unique> isin %temp) {
        %unique = $remove(%temp,<unique>,</unique>)
        hadd cards $+(unique,%id) %unique
      }
      elseif (<rarity> isin %temp) {
        %rarity = $remove(%temp,<rarity>,</rarity>)
        hadd cards $+(rarity,%id) %rarity
      }
      elseif (<type> isin %temp) {
        %faction = $remove(%temp,<type>,</type>)
        hadd cards $+(faction,%id) %faction
      }
      elseif (<set> isin %temp) {
        %set = $remove(%temp,<set>,</set>)
        hadd cards $+(set,%id) %set
        if (%set == 5002) hadd cards $+(name,%id) $+(%name,+)
        if (!%hidden) {
          if (%set == 5002) {
            hadd cards $+(id,$remove(%name,$chr(32)),+) %id
            if (, isin %name) {
              hadd cards $+(id,$remove(%name,$chr(32),$chr(44)),+) %id
            }
          }
          else {
            hadd cards $+(id,$remove(%name,$chr(32))) %id
            if (, isin %name) {
              hadd cards $+(id,$remove(%name,$chr(32),$chr(44))) %id
            }
          }
        }
      }
      elseif (<skill isin %temp) && (/> isin %temp) {
        tokenize 32 %temp
        %skillname = $noqt($remove($gettok($2,2,61),'))
        %skillcount = 0
        %skillall = $false
        %skilltarget = $false
        %skillonplay = $false
        %skillondeath = $false
        %skillonattack = $false
        %skillonkill = $false
        var %i = 3
        while (/> !isin $ [ $+ [ $calc(%i - 1) ] ]) {
          var %str = $remove($ [ $+ [ %i ] ],/>)
          var %key = $gettok(%str,1,61)
          var %value = $noqt($remove($gettok(%str,2,61),'))
          if (%key == x) %skillcount = %value
          if (%key == y) %skilltarget = %value
          if (%key == all) %skillall = $true
          if (%key == played) %skillonplay = $true
          if (%key == died) %skillondeath = $true
          if (%key == attacked) %skillonattack = $true
          if (%key == kill) %skillonkill = $true
          inc %i
        }
        var %str = $upper($left(%skillname,1)) $+ $lower($right(%skillname,-1))

        ;why devs, why...
        %str = $replacecs(%str,Antiair,AntiAir)

        if (%skillall) %str = %str All
        if (%skilltarget) {
          if (%skilltarget == 1) %str = %str Imperial
          elseif (%skilltarget == 3) %str = %str Bloodthirsty
          elseif (%skilltarget == 4) %str = %str Xeno
          elseif (%skilltarget == 8) %str = %str Righteous
          elseif (%skilltarget == 9) %str = %str Raider
          else %str = %str ?Faction
        }
        if (%skillcount) %str = %str %skillcount
        if (%skillonplay) %str = %str on Play
        if (%skillondeath) %str = %str on Death
        if (%skillonattack) %str = %str on Attacked
        if (%skillonkill) %str = %str on Kill
        hadd cards $+(skill,%id,_,%skillid) %str
        %str = $null
        inc %skillid
      }
    }
    if ($sockbr == 0) { return }
  }
}
on *:SOCKREAD:tyrantraids:{
  if ($sockerr > 0) return
  var %ignore, %raid, %reward, %id, %name, %players, %time, %health
  while ($true) {
    sockread %temp
    if (<!-- isin %temp) {
      %ignore = $true
    }
    if (--> isin %temp) {
      %ignore = $false
    }
    if (<raid> isin %temp) {
      %raid = $true
      %id = 0
    }
    if (</raid> isin %temp) {
      %raid = $false
      %id = 0
    }
    if (<reward> isin %temp) {
      %reward = $true
    }
    if (</reward> isin %temp) {
      %reward = $false
    }
    set %temp $remove(%temp,	)
    if ((%raid) && (!%ignore) && (!%reward)) {
      if (<id> isin %temp) {
        %id = $remove(%temp,<id>,</id>)
      }
      elseif (<name> isin %temp) {
        %name = $remove(%temp,<name>,</name>)
        hadd raids $+(name,%id) %name
        hadd raids $+(id,$remove(%name,$chr(32))) %id
      }
      elseif (<num_players> isin %temp) {
        %players = $remove(%temp,<num_players>,</num_players>)
        %players = $gettok(%players,1,32)
        hadd raids $+(players,%id) %players
      }
      elseif (<time> isin %temp) {
        %time = $remove(%temp,<time>,</time>)
        %time = $gettok(%time,1,32)
        hadd raids $+(time,%id) %time
      }
      elseif (<health> isin %temp) {
        %health = $remove(%temp,<health>,</health>)
        %health = $gettok(%health,1,32)
        hadd raids $+(health,%id) %health
      }
    }
    if ($sockbr == 0) { return }
  }
}
