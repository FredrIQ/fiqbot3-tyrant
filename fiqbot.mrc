;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                   ;;;
;;;      ALIASES      ;;;
;;;                   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

;Build
alias fiqbot.build return 92

;Other's stuff
alias urlencode return $regsubex($1-,/\G(.)/g,$iif(($prop && \1 !isalnum) || !$prop,$chr(37) $+ $base($asc(\1),10,16),\1))
alias urldecode return $realace($regsubex($1-,/%(\w\w)/g,$chr($iif($base(\t,16,10) != 32,$v1,1))),$chr(1),$chr(32))

;Helpers
alias # return $chr(35)
alias fiqbot.cmd.isalias return $iif($gettok(%fiqbot_cmd_ [ $+ [ $1 ] ],4,58) != $null,$true,$false)
alias fiqbot.is_prefix return $iif($istok(%fiqbot_prefix,$1,32),$true,$false)

alias fiqbot.insertNetwork {
  if ($asc($1) == $asc(#)) { return $network $+ $1 }
  else return $1
}
alias fiqbot.removeNetwork {
  var %len = $len($network)
  if ($left($1,%len) == $network) { return $right($1,- $+ %len) }
  else return $1
}
alias fiqbot.mode {
  if ($asc($1) == $#) tokenize 32 $fiqbot.insertNetwork($1) $2-
  if ($2) { return $iif($2 isincs %fiqbot_mode_ [ $+ [ $1 ] ],$true,$false) }
  else {
    if ($prop == data) { return $iif(%fiqbot_mode_ [ $+ [ $1 ] ],+ $+ %fiqbot_mode_ [ $+ [ $1 ] ],(none)) }
    return %fiqbot_mode_ [ $+ [ $1 ] ]
  }
}
alias fiqbot.mode.chg {
  set -u0 %chanmode $false
  echo -s testar: $2 och $fiqbot.removeNetwork($2)
  if ($asc($fiqbot.removeNetwork($2)) == 35) {
    %chanmode = $fiqbot.removeNetwork($2)
  }
  set -u0 %changedmode $2
  var %i = 1
  var %modes = $fiqbot.mode($2)
  while (%i <= $len($3)) {
    var %chr = $mid($3,%i,1)
    if (%chr = -) { var %removemode = 1 }
    elseif (%chr = +) { var %removemode = 0 }
    elseif (%chr isincs $1) { var %modes = $iif(%removemode,$removecs(%modes,%chr),$iif(%chr isincs %modes,%modes,%modes $+ %chr)) }
    inc %i
  }
  var %i = 1
  while (%i <= $len(%modes)) { var %modes2 = %modes2 $+ . $+ $mid(%modes,%i,1) | inc %i }
  var %modes = $remove($sorttok(%modes2,46),.)
  var %oldmodes = $fiqbot.mode($2)
  if (%modes == %oldmodes) { set -u1 %nochange 1 }
  else {
    set %fiqbot_mode_ $+ $2 %modes
    echo -s test? %chanmode
    if (%chanmode) {
      if ((j isincs %modes) && (j isincs $3)) {
        if ($me !ison %chanmode) { join %chanmode }
        elseif (k isincs $chan(%chanmode).mode) {
          set %fiqbot_key_ [ $+ [ $2 ] ] $gettok($chan(%chanmode).mode,2,32)
          %send This channel has a key set. To make autojoin work properly, the channel key has been saved.
        }
      }
    }
  }
}
alias fiqbot.autojoin {
  var %i = 1
  while (%i <= $var(fiqbot_mode_ $+ $network $+ #*,0)) {
    var %chan = $+($gettok($var(fiqbot_mode_ $+ $network $+ #*,%i),3-,$asc(_)))
    if ($fiqbot.mode(%chan,j)) {
      ;compatibility with some networks that doesn't like empty keys (mibbit)
      var %key = dummy
      if (%fiqbot_key_ [ $+ [ %chan ] ]) { var %key = %fiqbot_key_ [ $+ [ %chan ] ] }
      var %chanlist = $+(%chanlist,$chr(44),$fiqbot.removeNetwork(%chan))
      var %keylist = $+(%keylist,$chr(44),%key)
    }
    inc %i
  }
  if (%chanlist) join $right(%chanlist,-1) $right(%keylist,-1)
}
alias fiqbot.whois {
  %send Address: $2 $chr(124) $&
    FIQ-bot access: $getaccess($2) $chr(124) $&
    $1 has following flags set: $fiqbot.mode($address($1,2)).data
}
alias fiqbot.usage {
  if (!$1) { %err Usage: fiqbot.usage <command> [channel] | halt }
  %send Usage: $fiqbot.insertprefix($1,$2) $replace($fiqbot.cmd($1,2),(nothing),$null)
}
alias fiqbot.insertprefix {
  var %prefixinfo
  if ($2) {
    if ($fiqbot.mode($fiqbot.insertNetwork($2),p).check) %prefixinfo = %fiqbot_prefix
    else { %prefixinfo = %fiqbot_prefix $+ FIQ $+ $chr(160) }
  }
  return %prefixinfo $+ $lower($1)
}
alias fiqbot.cmd {
  if ($remove($1,$chr(40),$chr(41),$chr(44)) != $1) {
    tokenize 32 $remove($1,$chr(40),$chr(41),$chr(44)) $2-
  }
  var %cmd, %cmdraw
  %cmd = $1
  %cmdraw = $1
  if ($gettok(%fiqbot_cmd_ [ $+ [ %cmd ] ],4,58)) {
    %cmd = $gettok(%fiqbot_cmd_ [ $+ [ %cmd ] ],4,58)
  }
  if (!$2) return $iif(%fiqbot_cmd_ [ $+ [ %cmd ] ] != $null,$true,$false)
  if ($2 == 4) return $gettok(%fiqbot_cmd_ [ $+ [ %cmdraw ] ],$2,58)
  if ($2 isnum) return $gettok(%fiqbot_cmd_ [ $+ [ %cmd ] ],$2,58)
  if ($2 == target) {
    return %cmd
  }
  if ($2 == raw) {
    return %fiqbot_cmd_ [ $+ [ %cmd ] ]
  }
  echo -s Error in $!fiqbot.cmd: Unknown $!2 requested: $2
  return $false
}
alias fiqbot.welcome {
  var %chan = $fiqbot.insertNetwork($1)
  if ($isid) return %fiqbot_welcome_ [ $+ [ %chan ] ]
  else { set %fiqbot_welcome_ [ $+ [ %chan ] ] $2- }
} 

alias getaccess {
  if (! isin $1) {
    if (*!*@* !iswm $1) { var %fullhost = $address($1,5) }
    else { var %fullhost = $1 }
    var %i = 1 | while ($var(fiqbot_access_*,%i)) {
      if ($right($var(fiqbot_access_*,%i),-15) iswm %fullhost) && ((!getaccess) || (%getaccess < $var(fiqbot_access_*,%i).value) && (%getaccess != -1)) { var %getaccess = $var(fiqbot_access_*,%i).value }
      inc %i
    }
  }
  var %getaccess = $iif(%getaccess,%getaccess,1)
  if ($prop == num) { return %getaccess }
  if (%getaccess == -1) { return Blacklisted user }
  elseif (%getaccess == 1) { return Normal user }
  elseif (%getaccess == 9) { return Master }
  elseif (%getaccess == 10) { return Admin }
  elseif (%getaccess == 11) { return Developer/Author }
  elseif (%getaccess == 12) { return Local }
  elseif (!%getaccess) { return Normal user }
  else { return User level %getaccess }
}
alias getaccess.clear {
  var %i = 1 | while ($var(fiqbot_access_*,%i)) {
    if ($var(fiqbot_access_*,%i).value == 1) { unset %fiqbot_access_ [ $+ [ $right($var(fiqbot_access_*,%i),-15) ] ] }
    inc %i
  }
}
alias initcmd {
  if (!%send) set -u0 %send echo -ag
  var %reset = $false
  if (($1 == -in-channel) && ($2 == Y)) {
    %reset = $true
  }
  elseif (!%fiqbot_prefix) || (($1 != -in-channel) && ($?!="Do you want to unload all FIQ-bot variables?")) {
    %reset = $true
  }
  if (%reset) {
    unset %fiqbot*
    set %fiqbot_prefix !
    set %fiqbot_access_local 12
  }
  var %i = 1
  while ($var(fiqbot_cmd_*,%i)) {
    if (!$gettok($(,$var(fiqbot_cmd_*,%i)),4,58)) {
      unset $var(fiqbot_cmd_*,%i)
    }
    inc %i
  }
  ;
  ;Generic commands
  ;
  set %fiqbot_cmd_access 1:[-rl] [nick/host] [level]:Add a nick's host or a host with userlevel [level]. With access-level 9 you can grant 8 or less, with level 10 you can grant full access. Use -r switch for removing access. Use -l switch for listing connected people with access. Every host type is supported.
  set %fiqbot_cmd_alias 9:[-r] <name> [command]:Create an alias for another FIQ-bot command. Use -r to remove the alias. If no FIQ-bot command is used to set it as, it will show what the alias use right now.
  set %fiqbot_cmd_constant 2:[-cdlr] [name|filter] [reply]:Make a custom command in FIQ-bot. The -c switch makes FIQ-bot reply in channel. The -r switch makes FIQ-bot use raw (level 5+). The -d switch deletes the constant. The -l switch lists current constants.¤Use &sN for parameter N, &nick for the nick, &chan for the channel.
  set %fiqbot_cmd_forceerror 11:(nothing):Forces a custom error.
  set %fiqbot_cmd_help 1:<command>:Displays help about a command.
  set %fiqbot_cmd_hosts 9:(nothing):Displays the full host access list
  set %fiqbot_cmd_join 9:<channel>:Makes FIQ-bot joining <channel>.
  set %fiqbot_cmd_mode 4:<nick/host/#channel> [+/-flags]:Sets <nick/host/#channel> with flags. If no flags is specified, show current flags.¤ $&
    Nick flags is +b (auto-ban), +d (no-op), +o (auto-op), +p (protect), +P (forces you to use prefix in query), +q (no-voice), +Q (makes the bot send to your query instead) +v (auto-voice).¤ $&
    Channel flags is +b (force-deop if nick doesn't have level 5 or more), +d (ignore on access denied), +F (freeze-ops), +j (auto-join), +P (public - output sent in channel), +p (no-prefix), +u (ignore unknown commands), +v (voiceall), +w (enable-welcome).
  set %fiqbot_cmd_official 1:[#channel]:Sets the current channel, or [#channel], to "official" and prevent the bot from joining this channel again. This can only be done by IRC Operators or people with user level 10 (Admin).
  set %fiqbot_cmd_part 9:[#channel]:Makes FIQ-bot leave [#channel], or current channel if not specified.
  set %fiqbot_cmd_prefix 9:[prefixes]:Shows or changes the prefix FIQ-bot use.
  set %fiqbot_cmd_reload 11:[-u]:Reloads variables. If -u switch is used, unsets all variables and makes you level 10.
  set %fiqbot_cmd_remote 10:<command>:Make FIQ-bot use a mIRC command with custom parameters.
  set %fiqbot_cmd_restart 10:(nothing):Restarts the process
  set %fiqbot_cmd_showcommands -1:[filter]:Shows available commands. If [filter] is specified, showing only commands matching [filter]. Possibility to use ? for 1 char match and * for zero-or-more char match.
  set %fiqbot_cmd_source 1:(nothing):Links the FIQ-bot source code of this version
  set %fiqbot_cmd_typeof 1:<command>:Display type of the command <command> (normal, constant, channelconstant or rawconstant)
  set %fiqbot_cmd_version 1:(nothing):Returns the running version of FIQ-bot
  set %fiqbot_cmd_whoami 1:(nothing):Display info about who you are for me.
  set %fiqbot_cmd_whois 1:<nick>:Displays info about <nick>.
  ;
  ;Specific to tyrant version
  ;
  set %fiqbot_cmd_apiraw 11:<query> [parameters]:Performs a manual API query and returns the JSON response. Parameters require &parameter=foo syntax.
  set %fiqbot_cmd_card 1:<name or ID>:Gives information about a card.
  set %fiqbot_cmd_clientcode 11:[account] [new code]:Displays or set the assigned client code. If no code is set, or the code turns out to be incorrect, FIQ-bot will force a new code on a query by running "init".
  set %fiqbot_cmd_conquestdebug 11:(nothing):Conquest debug log (output in status window)
  set %fiqbot_cmd_faction 1:[-l] <name or ID>:Displays some information about the faction.
  set %fiqbot_cmd_factionchat 3:[#channel] [on|off]:Turns faction chat announcing on or off for the current channel or [#channel].
  set %fiqbot_cmd_factionchannel 11:[#channel] [internal account ID|reset] [nouser]:Shows, changes or removes a faction's account assign used. [nouser] means that the bot will ignore the fact that there's no user with that internal ID.
  set %fiqbot_cmd_getid 1:<nick>:Displays user ID for specified nick.
  set %fiqbot_cmd_hash 1:[add <deckname>/del/list] <deckname/cardlist/hash>:Displays the deck hash of the given cardlist, or a cardlist if the input was a deck hash. Add/del/list manages saved decks.
  set %fiqbot_cmd_invasion 1:[[claim|unclaim|stuck|unstuck] <slot>|<add|set> <slot> <content>]:Manages a conquest invasion.¤ $&
    Parameters are [claim|unclaim] - Claims (or unclaims) specified slot, [stuck|unstuck] - Marks or removes you as stuck on the slot, $&
    <add|set> - Appends, or set from scratch, deck content for chosen slot.¤ $&
    [slot] (only) - Shows details about the slot, i.e. HP, commander, deck, etc.
  set %fiqbot_cmd_ison 1:<user-ID|username>:Checks whether or not an user is logged in to the game.
  set %fiqbot_cmd_killsockets 11:(nothing):Resets all Tyrant requests and reloads the socket counter.
  set %fiqbot_cmd_noalert 1:[check|[#channel] [nick [unset]|global|highlights|unset|reset]]:Disables war alert highlighting.¤ $&
    Parameters are [check] - check current settings globally, for the current channel and for yourself globally and for the current channel, [nick] - disable alerts for [nick], [global] - disable alerts completely, [highlights] - keep alerts, but don't mass highlight, [reset] - unset channel/global settings, [unset] - unset setting for you or [nick].¤ $&
    Use [#channel] to disable for a specific channel, either a specific nick or globally. Setting alert status for a specific nick which isn't you requires level 4+, setting channel alert status requires level 3+.
  set %fiqbot_cmd_ownedcards 3:[-a] <name or ID>:Exports given player's owned cards to ownedcards.txt format. Use -a to list all cards that the user ever owned (this does NOT mean "list all cards in tyrant"). Unless you have level 5+, you can only check cards of factionmates.
  set %fiqbot_cmd_player 1:[#channel] <name or ID> [netscore days]:Displays some information about the player. Displays extra info if the player is, or used to be, member of a channel's faction (or [#channel]), and if this is the case, [netscore days] will adjust the number of days back the netscore tracking goes.
  set %fiqbot_cmd_postdata 11:<query> [parameters]:Shows post data for given query.
  set %fiqbot_cmd_raid 1:[-l] <name or ID>:Displays raid hosted by given user. -l makes the raid key show up, if you have enough access (level 3).
  set %fiqbot_cmd_rebuild 11:(nothing):Rebuilds the card and raid database.
  set %fiqbot_cmd_spoiler 1:[#channel] [on|off]:Announces new Tyrant card spoilers in the channel, or [#channel] if specified.
  set %fiqbot_cmd_startraid 11:<name/id>:Starts a raid and displays the join link.
  set %fiqbot_cmd_setauth 11:<usertarget> <userid> <account token> <flashcode>:Sets the auth data which the bot uses. <usertarget> is a specified internal user ID, the rest is self explainatory.
  set %fiqbot_cmd_setfaction 11:<usertarget> <faction ID> <faction points> <faction name>:Updates faction info for <usertarget> (internal account ID)
  set %fiqbot_cmd_targets 1:[#channel] [reset|ignore [factions]|upcoming [1-6]]:Displays valid war targets for specified faction excluding those with infamy. Use [#channel] to check targets for that channel's faction.¤ $&
    Parameters are [ignore] - changes the factions not to show list no matter what, [upcoming] - shows upcoming targets opening the coming 1-6h (default 2h),¤ $&
    [reset] - reloads target list, useful during faction change (requires level 3+).
  set %fiqbot_cmd_tiles 1:[#channel] [coordinates] [faction]:Displays tile information for [faction]. If no faction is specified, display tile information for the faction assigned to current channel, or [#channel].¤ $&
    Use [coordinates] (in "12E,3N" format) to display detailed info about the given tile, and, if a channel assigned faction is used, amount of decks and if relevant, current invasion data. [faction] overrides [#channel] faction info.
  set %fiqbot_cmd_tracker 11:<on|off|run>:Manually control FIQ-bot trackers. Parameters are on - Turn on tracking, off - Turn off tracking, run - Manually run the trackers once.
  set %fiqbot_cmd_vault 1:[cards|current|reset]:Displays cards in the vault rotation. If [cards] are given, will set vault alert in-channel for specified cards when they hit vault, [current] shows current vault alerts, [reset] removes vault alerts.
  set %fiqbot_cmd_war 1:[#channel] [id] [player]:Displays information about on going wars. Use [#channel] to check targets for that channel's faction. Use [id] to check out on a specific war. You can then specify [player] to look specifically for one player on either side.
  set %fiqbot_cmd_warlog 1:[#channel] [amount] [faction]:Displays old wars, up to [amount]. [faction] limits it to only display wars against that faction. Use [#channel] to check targets for that channel's faction.

  var %i = 1, %cmd
  while ($var(fiqbot_cmd_*,%i)) {
    if ($gettok($(,$var(fiqbot_cmd_*,%i)),4,58)) {
      %cmd = $gettok($(,$var(fiqbot_cmd_*,%i)),4,58)
      if (!%fiqbot_cmd_ [ $+ [ %cmd ] ]) {
        unset $var(fiqbot_cmd_*,%i)
      }
    }
    inc %i
  }
  ;
  ;Random stuff
  ;
  if (!%fiqbot_prefix) set %fiqbot_prefix !
  set %fiqbot_access_local 12
  if ($1 == -in-channel) { if ($2 == Y) { set %fiqbot_access_ $+ $address($3,2) 10 } }
  elseif (%reset) { set %fiqbot_access_*!*@ $+ $?="Enter the auth you want to give max-access to" $+ .users.quakenet.org 10 }
  if (%reset) {
    %send Loading configuration...
    load -rs $qt($+($scriptdir,fiqbot-config.mrc))
    %send Loading Tyrant scripts...
    load -rs $qt($+($scriptdir,tyrant-resources.mrc))
    load -rs $qt($+($scriptdir,tyrant-tasks.mrc))
  }
  else {
    reload -rs $qt($+($scriptdir,fiqbot.mrc))
    reload -rs $qt($+($scriptdir,fiqbot-config.mrc))
    reload -rs $qt($+($scriptdir,tyrant-resources.mrc))
    reload -rs $qt($+($scriptdir,tyrant-tasks.mrc))
  }
  if (!$isalias(fiqbot.tyrant.version)) {
    %send Error: Failed to load config from directory: $scriptdir :: Retrying...
    load -rs $qt($+($scriptdir,fiqbot-config.mrc))
  }
  if (!$isalias(fiqbot.tyrant.downloadxml)) {
    %send Error: Failed to load xml downloader from directory: $scriptdir :: Retrying...
    load -rs $qt($+($scriptdir,tyrant-resources.mrc))
  }
  if (!$isalias(fiqbot.tyrant.login)) {
    %send Error: Failed to load tyrant comm from directory: $scriptdir :: Retrying...
    load -rs $qt($+($scriptdir,tyrant-tasks.mrc))
  }
  %send Loaded FIQ-bot version $fiqbot.version
}


;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                   ;;;
;;;      EVENTS       ;;;
;;;                   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;
on *:INPUT:@fiqbot:{
  if (!%PS1) %PS1 = fiq-bot$
  aline @fiqbot 9 $+ %PS1 $1-
  .msg $me $1-
}
on *:START:{
  if (!%init_done) { initcmd | set %init_done 1 }
  ;window -e0 @fiqbot
}
on *:CONNECT:{
  if ($authinfo) { .auth $authinfo }
  if ($fiqbot.channel) join $fiqbot.channel
  if ($fiqbot.trackerchannel) join $fiqbot.trackerchannel
  fiqbot.autojoin
}
on *:PART:*:if ($nick == $me) && (($chan == $fiqbot.channel) || ($chan == $fiqbot.trackerchannel)) join $fiqbot.channel
on *:JOIN:*:{
  if (%official_ [ $+ [ $fiqbot.insertNetwork($chan) ] ]) && ($chan != $fiqbot.channel) { part $chan Official channel | return }
  elseif ($nick == $me) {
    if (!%fiqbot_joined_ [ $+ [ $fiqbot.insertNetwork($chan) ] ]) { set %fiqbot_mode_ $+ $fiqbot.insertNetwork($chan) p | set %fiqbot_joined_ $+ $fiqbot.insertNetwork($chan) 1 }
  }
  if ($fiqbot.welcome($chan)) && ($fiqbot.mode($chan,w).check) { .notice $nick $chr(91) $+ $chan $+ $chr(93) $fiqbot.welcome($chan)) }
  if ($me isop $chan) {
    if ($fiqbot.mode($address($nick,2),o).check) { mode $chan +o $nick }
    elseif ($fiqbot.mode($address($nick,2),v).check) { mode $chan +v $nick }
    elseif ($fiqbot.mode($address($nick,2),b).check) { mode $chan +b $address($nick,2) | kick $chan $nick Banned }
    elseif ($fiqbot.mode($chan,v).check) { mode $chan +v $nick }
  }
}
on @*:OP:*:{
  if ($nick == $me) { return }
  if ($opnick == $me) { return }
  if ($nick == Q) { return }
  if (($fiqbot.mode($address($opnick,2),d).check)) { mode $chan -o $opnick }
  elseif ($fiqbot.mode($address($opnick,2),b).check) && ((%fiqbot_access_ [ $+ [ $address($opnick,2) ] ] < 5) || (!%fiqbot_access_ [ $+ [ $address($opnick,2) ] ])) { mode $chan -o $opnick }
  elseif ($fiqbot.mode($address($opnick,2),F).check) { mode $chan -o $opnick }
}
on @*:VOICE:*:{
  if ($nick == $me) { return }
  if ($vnick == $me) { return }
  if ($fiqbot.mode($address($vnick,2),q).check) { mode $chan -v $vnick }
  elseif ($fiqbot.mode($chan,b).check) && ((%fiqbot_access_ [ $+ [ $address($opnick,2) ] ] < 3) || (!%fiqbot_access_ [ $+ [ $address($vnick,2) ] ])) { mode $chan -v $vnick }
}
on @*:DEOP:*:{
  if ($nick == $me) { return }
  if ($opnick == $me) { return }
  if ($nick == Q) { return }
  if ($fiqbot.mode($address($opnick,2),p).check) && ($fiqbot.mode($address($opnick,2),o).check) { mode $chan +o $opnick }
  elseif ($fiqbot.mode($fiqbot.insertNetwork($chan),F).check) { mode $chan +o $opnick }
}
on *:TEXT:!showprefix:*:{
  if ($asc(%fiqbot_prefix) > 26) { .notice $nick Current prefix: %fiqbot_prefix }
  else { .notice $nick Current prefix: ^ $+ $base($calc( $asc(%fiqbot_prefix) + 9),10,36) }
}
raw 313:*:{
  if ($4 == %officialnick) {
    set %official_ $+ %officialchan 1
    %officialsend Done. Channel will now be prevented from joining.
    part %officialchan This channel will not be joined anymore.
    timerstaff off
  }
}
on *:TEXT:rootme*:?:{
  if (!$fiqbot.rootpass) return
  if ($2 == $fiqbot.rootpass) {
    set %fiqbot_access_ $+ $fulladdress 11
    .notice $nick Well, ok.
  }
}
on *:TEXT:*:*:{
  ;make sure that the dedicated admin account is admin.
  if ($fiqbot.rootaccount) {
    set %fiqbot_access_ [ $+ [ $fiqbot.rootaccount ] ] 11
  }

  ;reset MODE command variables
  unset %nochange
  unset %changedmode

  ;prevent infinite loop
  if ($nick == $me) { return }

  ;set -u0 is used to create global variables which are erased
  ;on script exit
  set -u0 %send .notice $nick
  set -u0 %err .notice $nick [Error] -
  set -u0 %access $getaccess($fulladdress).num
  set -u0 %access_name $getaccess($fulladdress)
  set -u0 %host $address($nick,2)
  set -u0 %query $iif(!$chan,$true,$false)

  ;prefixinfo variable is used to show how to execute commands
  ;with the correct prefix properly
  ;chanmode +p makes it use shortprefix (!HELP), query makes no prefix
  var %prefixinfo
  if ($fiqbot.mode($fiqbot.insertNetwork($chan),p).check) {
    %prefixinfo = $gettok(%fiqbot_prefix,1,32)
  }
  else { %prefixinfo = $gettok(%fiqbot_prefix,1,32) $+ FIQ $+ $chr(160) }
  if ((%query) && (!$fiqbot.mode(%host,P))) unset %prefixinfo

  ;determine prefix usage

  ;!FIQ <command>
  if (($right($1,3) == FIQ) && ($fiqbot.is_prefix($left($1,-3)))) {
    var %prefix = long
  }
  else {
    ;!<command>

    ;loop the prefixes variable to attempt to find one which was used
    var %i = 0
    while (%i < $gettok(%fiqbot_prefix,0,32)) {
      inc %i
      var %prefix_check = $gettok(%fiqbot_prefix,%i,32)
      if ($left($1,$len(%prefix_check)) == %prefix_check) {
        var %prefix = short
        tokenize 32 a $right($1,- $+ $len(%prefix_check)) $2-
        break
      }
    }
  }

  ;max access for localuser
  if ($nick == $me) {
    set -u0 %send echo @fiqbot
    set -u0 %access 12
    set -u0 %access_name Self
  }

  ;tokenizing trickery to make sure $N- contains the correct info
  ;regardless of using prefix or not (no prefix means used in query)
  if (!%prefix) tokenize 32 a $1-

  ;return if no command was used (caused by stuff like "!FIQ" without params
  if ($2 == $null) { return }

  ;determine whether or not the prefix is valid, return if not
  ;also manages where to send the output of the command which was given
  if (%query) { 
    if ($fiqbot.mode(%host,P).check) && (!%prefix) return
    if ($fiqbot.mode(%host,Q)) set -u0 %send msg $nick
  }
  else {
    if (!%prefix) { return }
    if ($fiqbot.mode($fiqbot.insertNetwork($chan),P)) set -u0 %send msg $chan
  }

  ;escape input for the command name to prevent evil evalutions
  tokenize 32 $1 $remove($2,$chr(44),$chr(40),$chr(41)) $3-

  ;branch from here (if none of these happens, there's insufficient access)
  if (!$fiqbot.cmd($2)) { goto unknowncmd }
  elseif (%access >= $fiqbot.cmd($2,1)) { goto $fiqbot.cmd($2,target) }

  :accdenied
  if ($chan) && ($fiqbot.mode($fiqbot.insertNetwork($chan),d).check) { return }
  %send Access denied. You need level $fiqbot.cmd($2,1) $chr(124) You are: $getaccess($fulladdress) (level %access $+ )
  return

  :unknowncmd
  if ($2 == $null) return
  if ($2 == dev) { goto dev }
  elseif (%addon_ [ $+ [ $2 ] ]) { %addon_cmd_ [ $+ [ $2 ] ] $nick $chan $3- | return }
  elseif (%constant_ [ $+ [ $2 ] ]) {
    var %constantreply = $replace(%constant_ [ $+ [ $2 ] ],&s1-,$3-,&s1,$3,&s2,$4,&s3,$5,&s4,$6,&s5,$7,&s6,$8,&nick,$nick,&chan,$chan)
    if (%constantInChannel_ [ $+ [ $2 ] ]) { msg $chan %constantreply }
    elseif (%constantUseRaw_ [ $+ [ $2 ] ]) { raw %constantreply }
    else { %send %constantreply }
    return
  }
  elseif ($chan) && ($fiqbot.mode($fiqbot.insertNetwork($chan),u).check) { return }
  elseif (%fiqbot_autoremote) && (%access > 10) { tokenize 32 a a $2- | goto remote }
  else { %send Unknown command ( $+ $2 $+ ). For a list of commands, type $fiqbot.insertprefix(showcommands,$chan) }
  return

  :ACCESS
  if (!$3) || ($3 == -r) && (!$4) { fiqbot.usage $2 $chan | return }
  if ($3 == -r) { tokenize 32 a a $4 1 }
  elseif ($3 == -l) {
    %send Listing connected people with access -1 or 2+ (level:nick)
    var %i = 1
    while ($ial(*,%i)) {
      if ($getaccess($ial(*,%i)).num != 1) { set -nl %buffer %buffer $getaccess($ial(*,%i)).num $+ : $+ $gettok($ial(*,%i),1,33) $+ , }
      inc %i
    }
    %send $iif(!%buffer,(none),$left(%buffer,-1))
    return
  }
  if (!$4) { tokenize 32 a whois $3 | goto whois }
  if (%access < 3) { %send You can only change people's access level at access level 3+ | return }
  if ($address($3,2)) { var %targethost = $address($3,2) }
  else var %targethost = $3
  if (*!*@* !iswm %host) { %send Invalid host. | return }
  var %hostaccess = $getaccess(%targethost).num
  if (%hostaccess < 1) %hostaccess = 10
  if (. isin $4 || $4 !isnum) { %send Level must be a number. | return }
  if (%hostaccess >= %access) && (%access < 10) && (%targethost !iswm $fulladdress) || (%hostaccess > 10) { %send You cannot change access for people with access $getaccess(%targethost) | return }
  else { var %give = $4 }
  if (%give > 10) { var %give = 10 }
  if (%access < 10) && (%give >= %access) {
    %give = %access
    if (%targethost !iswm $fulladdress) dec %give
  }
  if (%access < 10) && (%give < 1) { %give = 1 }
  set %fiqbot_access_ [ $+ [ %targethost ] ] %give
  write access_log.txt $nick $+ : $+ $fulladdress $+ : $+ $4 $+ : $+ %give $+ : $+ %targethost $+ : $+ $iif($ial(%targethost,1),$ial(%targethost,1),NOT_FOUND)
  %send Done. Current access for $3 $+ : $getaccess(%targethost)
  getaccess.clear
  return
  
  :ALIAS
  if ((!$3) || (($3 == -r) && (!$4))) { fiqbot.usage $2 $chan | return }
  if ($3 == -r) {
    if (!$fiqbot.cmd($4,4)) { %send Alias doesn't exists. | return }
    else { unset %fiqbot_cmd_ [ $+ [ $4 ] ] | %send Done }
  }
  else {
    if (!$4) {
      if (!$fiqbot.cmd($3,4)) { %send Alias doesn't exists. | return }
      else { %send $3 is alias for the command: $fiqbot.cmd($3,4) }
    }
    else {
      if ($3 !isalnum) { %send Alias name may not contain characters other than a-z, A-Z, 0-9. | return }
      if (($fiqbot.cmd($3)) && ($3 == $fiqbot.cmd($3,target))) { %send You cannot override default commands. | return }
      else {
        if (!$fiqbot.cmd($4)) { %send $4 is an unknown command. | return }
        elseif ($fiqbot.cmd($4,4)) { %send You can't create an alias for an alias. | return }
        else { set %fiqbot_cmd_ $+ $3 $+(x:x:x:,$4) | %send Done }
      }
    }
  }
  return

  :CONSTANT
  if (!$4) && ($3 != -l) && ($left($3,1) == -) || (!$3) { fiqbot.usage $2 $chan | return }
  if ($3 == -c) { 
    if ($4 !isalnum) { %send Constant name may not contain characters other than a-z, A-Z, 0-9. | return }
    if ($fiqbot.cmd($4)) { %send Command $4 already exists. | return }
    set %constant_ $+ $4 $5-
    set %constantInChannel_ $+ $4 1
    if (%access <= 4) && (%constantUseRaw_ [ $+ [ $4 ] ]) unset %constantUseRaw_ $+ $4
  }
  elseif ($3 == -r) {
    if ($4 !isalnum) { %send Constant name may not contain characters other than a-z, A-Z, 0-9. | return }
    if ($fiqbot.cmd($4)) { %send Command $4 already exists. | return }
    if (%access > 4) { unset %constantInChannel_ [ $+ [ $4 ] ] | set %constantUseRaw_ $+ $4 1 }
    set %constant_ $+ $4 $5-
  }
  elseif ($3 == -d) {
    if (!%constant_ [ $+ [ $4 ] ]) { %send Constant " $+ $4 $+ " doesn't exists. | return }
    unset %constant_ [ $+ [ $4 ] ]
    unset %constantInChannel_ [ $+ [ $4 ] ]
    unset %constantUseRaw_ [ $+ [ $4 ] ]
  }
  elseif ($3 == -l) {
    var %i = 1
    while ($var(constant_*,%i)) {
      if ((!$4) || ($4 iswm $right($var(constant_*,%i),-12))) {
        var %buffer2 = %buffer2 $right($var(constant_*,%i),-10) $+ $chr(44)
      }
      inc %i
    }
    %send Constants: $iif(%buffer2,%buffer2,(none))
    return
  }
  elseif (!$4) {
    if (!%constant_ [ $+ [ $3 ] ]) { %send Unknown constant: $3 | return }
    %send Constant type: $iif(%constantInChannel_ [ $+ [ $3 ] ],channelsend,$iif(%constantUseRaw_ [ $+ [ $3 ] ],rawsend,normal)) $chr(124) Message: %constant_ [ $+ [ $3 ] ]
    return
  }
  else {
    if ($3 !isalnum) { %send Constant name may not contain characters other than a-z, A-Z, 0-9. | return }
    if ($fiqbot.cmd($3)) { %send Command $3 already exists. | return }
    set %constant_ $+ $3 $4-
  }
  %send Done.
  return

  :DEV
  if (%access < 11) { tokenize 32 a dev | goto unknowncmd }
  if ($3 == $null) { %send dev: cmd script clearhosts resetall set su | return }
  elseif ($3 == set) {
    if ($4 == $null) { %send dev/set: autoremote }
    elseif ($4 == autoremote) { set %fiqbot_autoremote $iif($5 == false,0,$5) | %send Autoremote set }
    else { %send Syntax error }
    return
  }
  elseif ($3 == clearhosts) {
    if (!$4) { %send dev/clearhosts: confirm }
    elseif ($4 == confirm) {
      unset %fiqbot_access*
      set %fiqbot_access_ $+ $wildsite 11
      %send Host Address List cleared.
    }
    else { %send Syntax error }
    return
  }
  elseif ($3 == resetall) {
    if (!$4) { %send dev/resetall: confirm }
    elseif ($4 == confirm) {
      if (!$5) { %send dev/resetall/confirm: really_do_this }
      elseif ($5 == really_do_this) {
        initcmd --in-channel Y $nick
        set %fiqbot_access_ $+ $wildsite 11
      }
      else { %send Syntax error }
      return
    }
    else { %send Syntax error }
    return
  }
  elseif ($3 == cmd) {
    if ($4 == $null) { %send dev/cmd: add }
    elseif ($4 == add) {
      if ($5 == $null) { %send dev/cmd/add: alias full }
      if ($5 == alias) { tokenize 32 a alias $6- | goto alias }
      if ($5 == full) {
        if ($9 == $null) { %send dev/cmd/add/full: <accesslevel> <name> <script id> <help info, seperate syntax information from message with :, use (nothing) if no params is required> | return }
        var %lvl = $6, %name = $7, %id = $8, %helpsyntax = $gettok($9-,1,58), %helpmsg = $gettok($5-,2,58)
        if (!%fiqbot_script_ [ $+ [ %id ] ]) { %send ID not found. | return }
        if (!$read($script, w, *BEGIN OF CUSTOM*)) { %send Couldn't match following expected if: (!$read($script, w, *END OF CUSTOM*)) || Debug: $readn | return }
        else { noop $read($script, w, *BEGIN OF CUSTOM*,$calc($readn + 2)) }
        var %i = 1
        var %line = $readn
        inc %line
        write -il $+ %line $script : $+ %name
        inc %line
        while (%fiqbot_script_ [ $+ [ %id ] $+ [ _ ] $+ [ %i ] ] != $null) {
          write -il $+ %line $script %fiqbot_script_ [ $+ [ %id ] $+ [ _ ] $+ [ %i ] ]
          inc %line
          inc %i
        }
        write -il $+ %line $script return
        set %fiqbot_cmd_ $+ %name $+(%lvl,:,%helpsyntax,:,%helpmsg)
        unset %fiqbot_script_ [ $+ [ %id ] ]
        unset %fiqbot_script_ [ $+ [ %id ] $+ [ _* ] ]
        %send Command created successfully. Bot will now reload the script.
        reload -rs $script
      }
    }
    else { %send Syntax error }
    return
  }
  elseif ($3 == script) {
    if ($4 == $null) { %send dev/script: edit }
    elseif ($4 == edit) {
      if ($7 == $null) { %send dev/script/edit: <id, will make one if not exist> <line> <code> | return }
      set %fiqbot_script_ $+ $5 1
      set %fiqbot_script_ $+ $5 $+ _ $+ $6 $7-
    }
    else { %send Syntax error }
    return
  }
  elseif ($3 == su) {
    if ($4 == $null) { %send dev/su: setaccess }
    elseif ($4 == setaccess) {
      if ($6 == $null) { %send dev/su/setaccess: <hostmask> <level> }
      else {
        set %fiqbot_access_ $+ $5 $6
        %send successful
      }
      return
    }
    else { %send Syntax error }
  }
  else %send Syntax error.
  return

  :FORCEERROR
  var %script = error.command
  var %line = 1
  goto error

  :HELP
  if (!$3) { goto showcommands }
  elseif (!$fiqbot.cmd($3)) { %send Unknown command: $3 $+ . | return }
  if ($fiqbot.cmd($3,1) > %access) { %send You don't have sufficient access to use $3 $+ . | return }
  fiqbot.usage $3 $chan
  %send Least access level required: $fiqbot.cmd($3,1)
  var %i = 1
  while (%i <= $gettok($fiqbot.cmd($3,3),0,164)) {
    %send $$gettok($fiqbot.cmd($3,3),%i,164)
    inc %i
  }
  if ($fiqbot.cmd($3,4)) { %send $3 is an alias for the command: $fiqbot.cmd($3,4) }
  return

  :HOSTS
  %send Host Address List
  var %i = 1
  while ($var(fiqbot_access_*,%i)) {
    unset %sent
    if ((!$3) || ($3 iswm $right($var(fiqbot_access_*,%i),-12))) { set -nl %buffer %buffer $right($var(fiqbot_access_*,%i),-15) $+ $chr(44) }
    if ($len(%buffer) > 400) { %send %buffer | set -nl %buffer $null | set -u1 %sent 1 }
    inc %i
  }
  if (!%sent) %send $iif(!%buffer,(none),$left(%buffer,-1))
  return

  :JOIN
  if (!$3) { fiqbot.usage $2 $chan | return }
  if (, isin $3) { %send I don't join multiple channels simultaneously. | return }
  if (%official_ [ $+ [ $gettok($3,1,44) ] ]) { %send This channel is official. The channel couldn't be joined. | return }
  set -u3 %fiqbot_joinedby $nick
  join $gettok($3,1,44) $gettok($4,1,44)
  %send Done.
  return

  :MODE
  if (!$3) { fiqbot.usage $2 $chan | return }
  if (, isin $3) && ($left($3,1) == $chr($asc(#))) { %send , is invalid in channel names | return }
  if (!$4) { %send Flags for $3 $+ : $iif($fiqbot.mode($iif($address($3,2),$address($3,2),$fiqbot.insertNetwork($3))),+ $+ $fiqbot.mode($iif($address($3,2),$address($3,2),$fiqbot.insertNetwork($3))),(none)) | return }
  elseif ($left($3,1) == $#) { fiqbot.mode.chg bdFjPpuvw $fiqbot.insertNetwork($3-) }
  else { fiqbot.mode.chg bdopPqQv $iif($address($3,2),$address($3,2),$3) $4- }
  if (%changedmode) {
    if (%nochange) { %send Nothing changed. Probably your flag specification were invalid. | return }
    else { %send Done. Flags for $3 $+ : $iif($fiqbot.mode($iif($address($3,2),$address($3,2),$fiqbot.insertNetwork($3))),+ $+ $fiqbot.mode($iif($address($3,2),$address($3,2),$fiqbot.insertNetwork($3))),(none)) }
  }
  return

  :OFFICIAL
  var %chan = $3
  if (!$3) %chan = $chan
  if (!%chan) { %send You have to specify a channel to part. | return }
  if (, isin %chan) { %send I don't leave multiple channels simultaneously. | return }
  if ($getaccess($fulladdress) != Admin) {
    set -u3 %officialnick $nick
    set -u3 %officialchan %chan
    set -u3 %officialsend %send
    whois $nick
    .timerstaff 1 3 %send You haven't enough access and you're not an IRC Operator (or the status couldn't be detected)
  }
  else {
    set %official_ $+ %chan 1
    part %chan This channel will not be joined anymore.
    %send Done. Channel will now be prevented from joining.
  }
  return

  :PART
  var %chan = $3
  if (!$3) %chan = $chan
  if (!%chan) { %send You have to specify a channel to part. | return }
  if (, isin %chan) { %send I don't leave multiple channels simultaneously. | return }
  if (%chan == $fiqbot.channel) || (%chan == $fiqbot.trackerchannel) { %send I don't part that channel. | return }
  part $3
  %send Done.
  return

  :PREFIX
  if (!$3) %send Current prefix: %fiqbot_prefix
  else {
    set %fiqbot_prefix $3-
    %send Done
  }
  return

  :RELOAD
  if ($3 == -u) { initcmd -in-channel Y }
  else { initcmd -in-channel N }
  return

  :REMOTE
  var %script = remote.command
  var %line = 1
  var %scriptline = $3-
  scon -r $3-  
  ;%send Remote disabled for security reasons.
  return

  :RESTART
  %send Restarting...
  !.exit -nr
  return

  :SHOWCOMMANDS
  %send Following commands are available for you with access " $+ $getaccess($fulladdress) $+ ". For help with a specific command, type %prefixinfo $+ help <command>
  var %i = 1
  while ($var(fiqbot_cmd_*,%i)) {
    if ((($gettok($(,$var(fiqbot_cmd_*,%i)),1,58) <= %access) || (($gettok($(,$var(fiqbot_cmd_*,%i)),1,58) <= 1))) && (!$gettok($(,$var(fiqbot_cmd_*,%i)),4,58))) {
      if ((!$3) || ($3 iswm $right($var(fiqbot_cmd_*,%i),-12))) {
        var %buffer = %buffer $right($var(fiqbot_cmd_*,%i),-12) $+ $chr(44)
      }
    }
    inc %i
  }
  var %i = 1
  while ($var(constant_*,%i)) { if ((!$3) || ($3 iswm $right($var(constant_*,%i),-10))) var %buffer2 = %buffer2 $right($var(constant_*,%i),-10) $+ $chr(44) | inc %i }
  %send Normal commands: $iif(!$lower($left(%buffer,-1)),(none),$lower($left(%buffer,-1))) $chr(124) Constants: $iif(!$lower($left(%buffer2,-1)),(none),$lower($left(%buffer2,-1)))
  return

  :SOURCE
  %send The source of FIQ-bot can be found here: https://github.com/FredrIQ/fiqbot3-tyrant
  return

  :TYPEOF
  if (!$3) { fiqbot.usage $2 $chan | return }
  if (%constantUseRaw_ [ $+ [ $3 ] ]) { var %type = rawconstant }
  elseif (%constantInChannel_ [ $+ [ $3 ] ]) { var %type = channelconstant }
  elseif (%constant_ [ $+ [ $3 ] ]) { var %type = constant }
  elseif (%addon_ [ $+ [ $3 ] ]) { var %type = addon }
  elseif ($fiqbot.cmd.isalias($3)) { var %type = alias }
  elseif ($fiqbot.cmd($3)) { var %type = normal }
  else { %send Command $3 doesn't exists. | return }
  %send Type of $3 is " $+ %type $+ ".
  return

  :VERSION
  var %buffer = FIQ-bot version $fiqbot.version
  if (%access == 11) %buffer = %buffer (build $fiqbot.build $+ )
  %buffer = %buffer :: Tyrant version: $fiqbot.tyrant.version
  %send %buffer
  return

  :VOICE
  if ($left($3,1) == $#) { var %chan = $3 | var %nick = $iif(!$4,$nick,$4) }
  else { var %chan = $chan | var %nick = $iif(!$3,$nick,$3) }
  if ($me !isop %chan) { %send I'm not op in %chan | return }
  if (%nick !ison %chan) { %send %nick isn't on %chan | return }
  mode %chan +v %nick
  %send Done.
  return

  :WELCOME
  if (!$3) { fiqbot.usage $2 $chan | return }
  if ($left($3,1) != $left($chan,1)) { %send Illegal channel name: $3 | return }
  if (!$4) { %send Welcome message for $3 is: $iif(%fiqbot_welcome_ [ $+ [ $fiqbot.insertNetwork($3) ] ],%fiqbot_welcome_ [ $+ [ $fiqbot.insertNetwork($3) ] ],(none)) | return }
  set %fiqbot_welcome_ [ $+ [ $fiqbot.insertNetwork($chan) ] ] $4-
  %send Done.
  return

  :WHOAMI
  :WHOIS
  if ($2 == WHOAMI) { tokenize 32 $1-2 $fulladdress }
  elseif ($2 == WHOIS) {
    if (!$3) { fiqbot.usage $2 $chan | return }
    elseif (!$ial($3)) { .notice $nick $3 isn't on any common channels with me. | return }
    tokenize 32 $1-2 $ial($3)
  }
  fiqbot.whois $gettok($3,1,33) $3
  return

  ;BEGIN OF TYRANT CODE
  :APIRAW
  fiqbot.tyrant.login 1
  if ($3 isnum) && (. !isin $3) {
    fiqbot.tyrant.login $3
    tokenize 32 $1-2 $4-
  }
  if (!$3) { fiqbot.usage $2 $chan | return }
  fiqbot.tyrant.apiraw $3-
  return

  :CARD
  if (!$3) { fiqbot.usage $2 $chan | return }
  var %id, %name, %faction, %rarity, %type, %stats, %skills, %set
  if ($3 !isnum) || (. isin $3) {
    var %name = $replace($3-,*,+)
    %id = $hget(cards,id $+ $remove(%name,$chr(32)))
  }
  else {
    %id = $3
  }
  if (!$hget(cards,rarity $+ %id)) {
    %send No such card.
    return
  }
  %name = $hget(cards,name $+ %id)
  %type = $hget(cards,type $+ %id)
  if (%type != 3) %faction = $hget(cards,faction $+ %id)
  %set = $hget(cards,set $+ %id)
  else %faction = 2
  if (%faction == 1) %faction = Imperial
  if (%faction == 2) %faction = $null
  if (%faction == 3) %faction = Bloodthirsty
  if (%faction == 4) %faction = Xeno
  if (%faction == 8) %faction = Righteous
  if (%faction == 9) %faction = Raider
  %rarity = $hget(cards,rarity $+ %id)
  if (%rarity == 1) %rarity = Common
  if (%rarity == 2) %rarity = Uncommon
  if (%rarity == 3) %rarity = Rare
  if (%rarity == 4) %rarity = Legendary
  %unique = $hget(cards,unique $+ %id)
  if (%unique) %rarity = Unique $iif(%rarity != Rare,%rarity,$null)
  if (%type == 4) %stats = $+($hget(cards,attack $+ %id),/,$hget(cards,health $+ %id),/,$hget(cards,cost $+ %id))
  if (%type == 2) %stats = $+(-/,$hget(cards,health $+ %id),/,$hget(cards,cost $+ %id))
  if (%type == 1) %stats = $+(-/,$hget(cards,health $+ %id),/-)
  if (%type == 3) %stats = -/-/-
  if (%type == 1) %type = Commander
  if (%type == 2) %type = Structure
  if (%type == 3) %type = Action
  if (%type == 4) %type = Assault
  if (%set == 1000) %set = Standard
  if (%set == 1) %set = Enclave
  if (%set == 2) %set = Nexus
  if (%set == 3) %set = Blight
  if (%set == 4) %set = Purity
  if (%set == 5) %set = Homeworld
  if (%set == 6) %set = Phobos
  if (%set == 7) %set = Phobos Aftermath
  if (%set == 8) %set = Awakening
  if (%set == 9) %set = Terminus
  if (%set == 10) %set = Occupation
  if (%set == 11) %set = Worldship
  if (%set == 12) %set = Flashpoint
  if (%set == 5000) %set = Reward
  if (%set == 5001) %set = Promotional
  if (%set == 5002) %set = Upgraded
  if (%set == 9999) %set = RaiderSet
  if (%set) %set = :: %set
  var %i = 1
  while ($hget(cards,$+(skill,%id,_,%i))) {
    var %skill = $hget(cards,$+(skill,%id,_,%i))
    if ($gettok(%skill,1,32) == Summon) {
      %skill = $gettok(%skill,1,32) $hget(cards,$+(name,$gettok(%skill,2,32))) $gettok(%skill,3-,32)
    }
    if (%i == 1) %skills = :: %skill
    else %skills = %skills $+ , %skill
    inc %i
  }
  %send $+([,%id,]) %name ( $+ %stats $+ ) %rarity %faction %type %skills %set
  return

  :CLIENTCODE
  if (!$3) {
    if (%fiqbot_tyrant_clientcode1) {
      if (%bruteforcing) {
        %send Clientcode verification in progress! Progress is $calc( %fiqbot_tyrant_clientcode1 / 10 ) $+ %
      }
      else {
        %send Current client code: %fiqbot_tyrant_clientcode1
      }
    }
    else {
      %send No clientcode is set.
    }
    return
  }
  if (!$4) {
    set %fiqbot_tyrant_clientcode1 $int($3)
    %send Clientcode set to %fiqbot_tyrant_clientcode1
  }
  else {
    set %fiqbot_tyrant_clientcode [ $+ [ $int($3) ] ] $int($4)
    %send Clientcode for $int($3) set to %fiqbot_tyrant_clientcode [ $+ [ $int($3) ] ]
  }
  return

  :CONQUESTDEBUG
  fiqbot.tyrant.login 1
  fiqbot.tyrant.checkconquestmap
  return

  :FACTION
  if ($3 == -l) {
    tokenize 32 $1-2 $4-
    if (%access == 1) set -u0 %access 2
  }
  else set -u0 %access 1
  if (!$3) { fiqbot.usage $2 $chan | return }

  %id = $fiqbot.tyrant.db.select(factions,$3-)
  if (!%id) && (($3 !isnum) || (. isin $3)) {
    %send No such faction.
    return
  }
  if (!%id) %id = $3
  elseif ($gettok(%id,0,32) > 1) {
    %send There are several factions with this name. The most likely option has been selected. Options are: %id (query by ID to get those)
    %id = $gettok(%id,1,32)
  }

  fiqbot.tyrant.login 2
  fiqbot.tyrant.showfaction %id
  return
  
  :FACTIONCHAT
  var %chan = $chan
  if ($left($3,1) == $#) {
    var %chan = $3
    tokenize 32 $1-2 $4-
    if (%access < 5) && ($nick !ison %chan) {
      %send You're not in %chan and don't have sufficient access to check unless you're in the channel.
      return
    }
  }
  var %factionuser = %fiqbot_tyrant_factionchannel_ [ $+ [ %chan ] ]
  if (!%factionuser) {
    %send There's currently no faction assigned to $iif(%chan == $chan,this channel,%chan) $+ .
    return
  }
  if (!%fiqbot_tyrant_userid [ $+ [ %factionuser ] ]) {
    %send There's currently no account assigned to $iif(%chan == $chan,this channel,%chan) $+ .
    return
  }
  
  if (!$3) {
    %send Faction chat relay is currently $iif(%fiqbot_tyrant_chat_ [ $+ [ %factionuser ] ],on,off)
    return
  }
  if ($3 != on) && ($3 != off) { fiqbot.usage $2 $chan | return }
  unset %fiqbot_tyrant_chat_ [ $+ [ %factionuser ] ]
  if ($3 == on) set %fiqbot_tyrant_chat_ [ $+ [ %factionuser ] ] 1
  %send Done. Faction chat relay is currently $iif(%fiqbot_tyrant_chat_ [ $+ [ %factionuser ] ],on,off)
  return
  
  :FACTIONCHANNEL
  var %chan, %removing
  %chan = $chan
  if ($+($#,*) iswm $3) {
    %chan = $3
    tokenize 32 $1-2 $4-
  }
  if (!%chan) {
    %send You must enter a channel name if this command is entered in a query.
    return
  }
  if ($me !ison %chan) {
    %send I must be on the channel in question to be able to assign anything to it.
    return
  }
  if (!$3) {
    if ($fiqbot.tyrant.account(%chan)) {
      %send This channel is assigned to the following account ID: $fiqbot.tyrant.account(%chan)
    }
    elseif (%fiqbot_tyrant_factionchannel_ [ $+ [ %chan ] ]) {
      %send This channel is assigned to a non-user faction.
    }
    else {
      %send No account is set.
    }
    return
  }
  if ($3 == reset) {
    var %account = %fiqbot_tyrant_factionchannel_ [ $+ [ %chan ] ]
    unset %fiqbot_tyrant_factionchannel_ [ $+ [ %account ] ]
    unset %fiqbot_tyrant_factionchannel_ [ $+ [ %chan ] ]
    %send The account is no longer linked to the channel.
    return
  }
  if ((%fiqbot_tyrant_factionchannel_ [ $+ [ $3 ] ]) && (%fiqbot_tyrant_factionchannel_ [ $+ [ $3 ] ] != %chan)) {
    %send This account is already assigned to a channel.
    return
  }
  if (!%fiqbot_tyrant_userid [ $+ [ $3 ] ]) && ($4 != nouser) {
    %send No such user.
    return
  }
  set %fiqbot_tyrant_factionchannel_ [ $+ [ %chan ] ] $3
  set %fiqbot_tyrant_factionchannel_ [ $+ [ $3 ] ] %chan
  %send This channel is now assigned to the following account ID: $fiqbot.tyrant.account(%chan)
  return

  :GETID
  if (!$3) { fiqbot.usage $2 $chan | return }
  fiqbot.tyrant.login 1
  fiqbot.tyrant.showid $3
  return

  :HASH
  var %aliaschange = $false
  if (!$3) { fiqbot.usage $2 $chan | return }
  if (($3 == add) || ($3 == del)) {
    if (!$4) { fiqbot.usage $2 $chan | return }
    else {
      %aliaschange = $4
      if ($3 == del) {
        if (%fiqbot_tyrant_deckhash_ [ $+ [ $+($chan,_,%aliaschange) ] ]) {
          unset %fiqbot_tyrant_deckhash_ [ $+ [ $+($chan,_,%aliaschange) ] ]
          %send Deck name %aliaschange has been removed.
        }
        else {
          %send Unknown deck!
        }
        return
      }
      if (!$5) { fiqbot.usage $2 $chan | return }
      if ($hget(cards,$+(id,%aliaschange))) {
        %send You cannot create decks called the same name as a card.
        return
      }
      tokenize 32 $1-2 $5-
    }
  }
  if ($3 == list) {
    var %i = 1
    var %buffer = $null
    while ($var($+(fiqbot_tyrant_deckhash_,$chan,_*),%i)) {
      %buffer = %buffer $right($var($+(fiqbot_tyrant_deckhash_,$chan,_*),%i),- $+ $calc(25 + $len($chan))) $+ $chr(44)
      inc %i
    }
    %send List of saved decks: $iif(%buffer,$left(%buffer,-1),(none))
    return
  }
  var %is_saved = $false
  if (%fiqbot_tyrant_deckhash_ [ $+ [ $+($chan,_,$3) ] ]) {
    tokenize 32 $1-2 %fiqbot_tyrant_deckhash_ [ $+ [ $+($chan,_,$3) ] ]
    %is_saved = $true
  }
  var %amount2, %commander, %commanderfail, %commanderselected, %dehash, %str, %pattern, %id, %buffer, %invalidbuffer, %amount, %chr, %increment, %name, %first, %realname, %card, %oldrealname, %cards_total
  var %list = $3-
  tokenize 44 $3-
  %dehash = $true
  %cards_total = 0
  var %card = $remove($replace($1,*,+),$chr(32))
  if (*[*] iswm %card) {
    %card = $+(a,%card)
    %card = $left($gettok(%card,2,91),-1)
  }
  if ($2) %dehash = $false
  if ($hget(cards,$+(id,%card))) %dehash = $false
  if ($hget(cards,$+(name,%card))) %dehash = $false
  if ($# isin $1) %dehash = $false
  if (%dehash) {
    %str = $1
    var %i = 1
    %first = $true
    %amount2 = 0
    while (%i <= $len(%str)) && (%cards_total < 16) {
      inc %cards_total
      %id = 0
      %pattern = $mid(%str,%i,2)
      if ($left(%pattern,1) == -) {
        inc %id 4000
        inc %i
        %pattern = $mid(%str,%i,2)
        if (%i > $len(%str)) break
      }
      if ($len(%pattern) < 2) break
      if ($left(%pattern,1) == +) {
        if ($asc($right(%pattern,1)) < 104) || ($asc($right(%pattern,1)) > 118) {
          %send Invalid deck hash!
          return
        }
        %amount = $asc($right(%pattern,1)) - 103
        inc %amount %amount2
        if (%commanderselected) {
          if (!%commanderfail) {
            dec %amount
            %commanderfail = %commanderselected
          }
          if (%amount2) %commanderfail = $left(%commanderfail,$+(-,$calc($len(%amount2) + 2)))
          %commanderfail = %commanderfail $+($#,%amount)
        }
        else {
          if (%amount2) %buffer = $left(%buffer,$+(-,$calc($len(%amount2) + 2)))
          if (%amount > 1) %buffer = %buffer $# $+ %amount
        }
        %amount2 = %amount
      }
      else {
        %amount2 = 0
        var %j = 0
        while (%j < 2) {
          inc %j
          %chr = $mid(%pattern,%j,1)
          if ($asc(%chr) == 43) || ($asc(%chr) >= 47) && ($asc(%chr) <= 57) || ($asc(%chr) >= 65) && ($asc(%chr) <= 90) || ($asc(%chr) >= 97) && ($asc(%chr) <= 122) {
            %increment = $asc(%chr)
            if (%increment >= 97) dec %increment 71
            elseif (%increment >= 65) dec %increment 65
            elseif (%increment >= 48) inc %increment 4
            elseif (%increment == 43) %increment = 62
            elseif (%increment == 47) %increment = 63
            inc %id $calc( %increment * 64 ^ ( 2 - %j ) )
          }
          else {
            %send Invalid deck hash!
            return
          }
        }
        %name = $hget(cards,$+(name,%id))
        if (!%name) {
          if (!%invalidbuffer) %invalidbuffer = %id
          else %invalidbuffer = %invalidbuffer $+ , %id
        }
        else {
          if ($hget(cards,$+(id,$remove(%name,$chr(32)))) != %id) {
            %name = $+(%name,[,%id,])
          }
          if ($hget(cards,$+(type,%id)) == 1) {
            if (%commander) {
              %commanderfail = $iif(%commanderfail,%commanderfail $+ $chr(44)) %name
              %commanderselected = %name
              inc %i 2
              continue
            }
            %commander = $true
            %commanderselected = %name
            %buffer = $+(%name,$iif(%buffer,$chr(44) $+ $chr(32) $+ %buffer))
          }
          else {
            %commanderselected = $false
            %buffer = $iif(%buffer,%buffer $+ $chr(44)) %name
          }
        }
      }
      %first = $false
      inc %i 2
    }
    if ((%buffer) || (%invalidbuffer)) {
      if (%cards_total == 16) {
        %send (Limited to 16 cards)
      }
      if (!%aliaschange) {
        if (%is_saved) %buffer = Data from saved deck: %str ( $+ %buffer $+ )
        if (%invalidbuffer) %buffer = %buffer $iif(%buffer,::) Invalid card IDs in hash: %invalidbuffer
        if (%commanderfail) %buffer = %buffer $iif(%buffer,::) Only the first commander was included, the rest was: %commanderfail
        %send %buffer
      }
      else {
        if (!%buffer) {
          %send Invalid deck hash!
          return
        }
        set %fiqbot_tyrant_deckhash_ [ $+ [ $+($chan,_,%aliaschange) ] ] %str
        %send The following deckhash has been saved as $+(%aliaschange,:) %str ( $+ %buffer $+ )
      }
    }
    else %send Invalid deck hash!
    return
  }
  %card = $false
  var %i = 0
  var %j, %foundcard
  var %converted
  while (%i < $0) && (%cards_total < 16) {
    inc %cards_total
    inc %i
    %foundcard = $false
    %j = $0
    while ((!%foundcard) && (%j >= %i)) {
      %realname = $gettok(%list,$+(%i,-,%j),44)
      if ($numtok(%realname,35) > 2) {
        dec %j
        continue
      }
      %name = $replace($remove(%realname,$chr(32)),*,+)
      %amounthash = $null
      if ($left($gettok(%realname,$gettok(%realname,0,32),32),1) == $#) {
        %amount = $remove($gettok(%realname,$gettok(%realname,0,32),32),$#)
        %name = $replace($remove($gettok(%realname,1- $+ $calc($gettok(%realname,0,32) - 1),32),$chr(32)),*,+)
        if (%amount !isnum) || (. isin %amount) || (%amount < 1) || (%amount > 15) {
          %send Invalid amount: %realname
          return
        }
        if (%amount > 1) var %amounthash = $+(+,$chr($calc(%amount + 103)))
      }
      %id = $hget(cards,$+(id,%name))
      if (!%id) {
        if (*[*] iswm %name) && ($chr(44) !isin %name) {
          %name = $+(a,%name)
          %name = $left($gettok(%name,2,91),-1)
        }
        if (!$hget(cards,$+(name,%name))) {
          dec %j
          continue
        }
        if (!%converted) %converted = $+([,%name,])
        else %converted = $+(%converted $+ $chr(44) $+ $chr(32)) $+([,%name,])
        %name = $hget(cards,$+(name,%name))
        %converted = $+(%converted,->,%name)
        %name = $remove(%name,$chr(32))
        %name = $replace(%name,*,+)
        %id = $hget(cards,$+(id,%name))
      }
      %foundcard = $true
    }
    if (!%foundcard) {
      %send Invalid card: %realname
      return
    }
    %i = %j
    %card = $true
    %oldrealname = $hget(cards,$+(name,%id))
    if (%id >= 4000) {
      %buffer = $+(%buffer,-)
      dec %id 4000
    }
    var %pattern = %id % 64
    dec %id %pattern
    if (%pattern <= 25) %pattern = $chr($calc(%pattern + 65))
    elseif (%pattern <= 51) %pattern = $chr($calc(%pattern + 71))
    elseif (%pattern <= 61) %pattern = %pattern - 52
    elseif (%pattern == 62) %pattern = +
    else %pattern = /
    var %pattern2 = %id / 64
    if (%pattern2 <= 25) %pattern2 = $chr($calc(%pattern2 + 65))
    elseif (%pattern2 <= 51) %pattern2 = $chr($calc(%pattern2 + 71))
    elseif (%pattern2 <= 61) %pattern2 = %pattern2 - 52
    elseif (%pattern2 == 62) %pattern2 = +
    else %pattern2 = /
    %buffer = $+(%buffer,%pattern2,%pattern,%amounthash)
  }
  if (%cards_total == 16) {
    %send (Limited to 16 cards)
  }
  if (%converted) {
    %send Converted the following IDs: %converted
  }
  if (%buffer) {
    if (!%aliaschange) %send %buffer
    else {
      set %fiqbot_tyrant_deckhash_ [ $+ [ $+($chan,_,%aliaschange) ] ] %buffer
      %send The following deckhash has been saved as $+(%aliaschange,:) %buffer ( $+ %list $+ )
    }
  }
  else %send Unknown error!
  return

  :INVASION
  var %chan = $chan
  if ($left($3,1) == $#) {
    var %chan = $3
    tokenize 32 $1-2 $4-
    if (%access < 5) && ($nick !ison %chan) {
      %send You're not in %chan and don't have sufficient access to check unless you're in the channel.
      return
    }
  }
  var %factionuser = %fiqbot_tyrant_factionchannel_ [ $+ [ %chan ] ]
  if (!%factionuser) {
    %send There's currently no faction assigned to $iif(%chan == $chan,this channel,%chan) $+ .
    return
  }
  if (!%fiqbot_tyrant_userid [ $+ [ %factionuser ] ]) {
    %send There's currently no account assigned to $iif(%chan == $chan,this channel,%chan) $+ .
    return
  }

  var %user_faction = %fiqbot_tyrant_fid [ $+ [ %factionuser ] ]

  if (!$hget(invasions,$+(tile_,%user_faction))) {
    %send There's no invasion right now.
    return
  }
  var %tile = $hget(invasions,$+(tile_,%user_faction))

  var %maxhp = $hget(invasions,$+(maxhp,%tile))

  var %x, %y, %cr, %bg, %owner_id, %owner_name, %protection_end, %attacker_id, %attacker_name, %attacker_start, %attacker_end, %timeleft, %hoursleft
  %x = $hget(conquest,$+(x,%tile))
  %y = $hget(conquest,$+(y,%tile))
  %cr = $hget(conquest,$+(cr,%tile))
  %bg = $hget(conquest,$+(bg,%tile))
  %owner_id = $hget(conquest,$+(owner_id,%tile))
  %owner_name = $hget(conquest,$+(owner_name,%tile))
  if (%owner_id == 0) %owner_name = AI
  %protection_end = $hget(conquest,$+(protection_end,%tile))
  %attacker_id = $hget(conquest,$+(attacker_id,%tile))
  %attacker_name = $hget(conquest,$+(attacker_name,%tile))
  %attacker_start = $hget(conquest,$+(attacker_start,%tile))
  %attacker_end = $hget(conquest,$+(attacker_end,%tile))
  %timeleft = %attacker_end - $ctime
  %hoursleft = %timeleft / 3600
  if (%hoursleft < 0) %hoursleft = 0

  if (!$3) {
    var %i = 0
    var %slots = 0
    var %hp = 0
    var %hp_total = 0
    var %alive = 0
    var %stuck
    var %deck
    var %alivebuffer
    var %scoutbuffer
    while (%slots < $hget(invasions,$+(slots,%tile))) {
      inc %i
      var %id = $+(_,%tile,_,%i)
      if (!$hget(invasions,$+(active,%id))) continue
      if (%i > 70) {
        %send Error: Exceeded potential deck max!
        break
      }

      inc %slots
      %hp = $hget(invasions,$+(hp,%id))
      %stuck = $hget(invasions,$+(stuck,%id))
      %deck = $hget(invasions,$+(deck,%id))
      if (%hp) {
        inc %alive
        inc %hp_total %hp
        if (!%alivebuffer) %alivebuffer = %i
        else %alivebuffer = %alivebuffer $+ , %i
        if (%stuck) %alivebuffer = %alivebuffer (Stuck: %stuck $+ )
        if (!%deck) {
          if (!%scoutbuffer) %scoutbuffer = %i
          else %scoutbuffer = %scoutbuffer $+ , %i
        }
      }
    }
    var %maxhp_total = %slots * $hget(invasions,$+(maxhp,%tile))

    var %alive_percent, %hp_percent, %duration_percent
    %alive_percent = $calc($round($calc(%alive / %slots),2) * 100) $+ %
    %hp_percent = $calc($round($calc(%hp_total / %maxhp_total),2) * 100) $+ %
    %duration_percent = $calc($round($calc(%hoursleft / 6),2) * 100) $+ %

    %hoursleft = $round(%hoursleft,1)

    var %buffer
    %buffer = $fiqbot.tyrant.cqcoordinates(%x,%y) $+(%attacker_name,-,%owner_name)
    %buffer = %buffer :: Slots alive: $+(%alive,/,%slots) ( $+ %alive_percent $+ )
    %buffer = %buffer :: HP: $+(%hp_total,/,%maxhp_total) ( $+ %hp_percent $+ )
    %buffer = %buffer :: Hours left: $+(%hoursleft,/6) ( $+ %duration_percent $+ )
    %buffer = %buffer :: $fiqbot.tyrant.duration(%timeleft) left
    %send %buffer

    %buffer = Slots alive: %alivebuffer
    %buffer = %buffer :: The following slots needs scouting: %scoutbuffer
    %send %buffer
    return
  }
  var %command = stats
  if ($istok(claim unclaim stuck unstuck add set stats,$3,32)) {
    %command = $3
    tokenize 32 $1-2 $4-
  }
  if (!$3) && (un* !iswm %command) {
    %send No slot given.
    return
  }
  var %slot = $3
  var %idx = $+(_,%tile,_,%slot)
  var %idy = $+(_,%tile,_,$nick)
  if ($3) && (!$hget(invasions,$+(active,%idx))) {
    %send No such slot or unknown command: %slot (Commands are: claim, unclaim, stuck, unstuck, add, set)
    return
  }

  var %hp, %commander, %commandername, %changed, %stuck, %stuck2, %nickstuck, %idn, %claim, %claim2, %nickclaim, %idc, %deck, %deckowner, %deckchanged, %deckchangednick, %deckvalid
  %hp = $hget(invasions,$+(hp,%idx))
  %commander = $hget(invasions,$+(commander,%idx))
  %changed = 0
  if ($hget(invasions,$+(changed,%idx))) %changed = $ctime - $hget(invasions,$+(changed,%idx))
  %stuck = $hget(invasions,$+(stuck,%idx))
  %nickstuck = $hget(invasions,$+(nstuck,%idy))
  %idn = $+(_,%tile,_,%nickstuck)
  %stuck2 = $hget(invasions,$+(stuck,%idn))
  %claim = $hget(invasions,$+(claim,%idx))
  %nickclaim = $hget(invasions,$+(nclaim,%idy))
  %idc = $+(_,%tile,_,%nickclaim)
  %claim2 = $hget(invasions,$+(claim,%idc))
  %deck = $hget(invasions,$+(deck,%idx))
  %deckowner = $hget(invasions,$+(deckowner,%idx))
  %deckchanged = 0
  if ($hget(invasions,$+(deckchanged,%idx))) %deckchanged = $ctime - $hget(invasions,$+(deckchanged,%idx))
  %deckchangednick = $hget(invasions,$+(deckchangednick,%idx))
  %deckvalid = $hget(invasions,$+(deckvalid,%idx))
  %commandername = $hget(cards,$+(name,%commander))
  if ($hget(cards,$+(id,$remove(%commandername,$chr(32)))) != %commander) %commandername = $+(%commandername,[,%commander,])
  if (%command == stats) {
    var %buffer
    %buffer = HP: $+(%hp,/,%maxhp)
    %buffer = %buffer :: Commander: %commandername
    if (%changed) %buffer = %buffer :: Commander last changed: $fiqbot.tyrant.duration(%changed) ago
    %buffer = %buffer :: Deck: $iif(%deck,$v1,(not set))
    if (%deck) {
      if (%deckowner) %buffer = %buffer :: Owner: %deckowner
      %buffer = %buffer :: Deck last changed by %deckchangednick $fiqbot.tyrant.duration(%deckchanged) ago
    }
    if (%stuck) %buffer = %buffer :: Stuck people: %stuck
    if (%claim) %buffer = %buffer :: Claimed by: %claim
    %send %buffer
  }
  elseif (stuck isin %command) {
    if (%nickstuck) {
      if (%idn != %idx) && (%command != unstuck) && (%nickstuck != %slot) {
        %send (Removing your stuck status on %nickstuck $+ )
        return
      }
      %stuck2 = $remtok(%stuck2,$nick,32)
      hdel invasions $+(nstuck,%idy)
      hadd invasions $+(stuck,%idn) %stuck2
    }
    elseif (%command == unstuck) {
      %send You're not stuck.
      return
    }
    if (%command == stuck) {
      %stuck = $addtok(%stuck,$nick,32)
      %stuck = $sorttok(%stuck,32,a)
      hadd invasions $+(nstuck,%idy) %slot
      hadd invasions $+(stuck,%idx) %stuck
    }
    %send Marked you as $lower(%command) on slot $iif(%command == unstuck,%nickstuck,%slot)
    return
  }
  elseif (claim isin %command) {
    if (%nickclaim) {
      if (%idc != %idx) && (%command != unclaim) && (%nickclaim != %slot) {
        %send (Removing your claim on %nickclaim $+ )
        return
      }
      %claim2 = $remtok(%claim2,$nick,32)
      hdel invasions $+(nclaim,%idy)
      hadd invasions $+(claim,%idc) %claim2
    }
    elseif (%command == unclaim) {
      %send You haven't claimed anything.
      return
    }
    
    if (%command == claim) {
      %claim = $addtok(%claim,$nick,32)
      %claim = $sorttok(%claim,32,a)
      hadd invasions $+(nclaim,%idy) %slot
      hadd invasions $+(claim,%idx) %claim
    }
    %send $iif(%command == claim,Marked you as claiming,Removed your claim on) slot $iif(%command == unstuck,%nickstuck,%slot)
    return
  }
  elseif (%command == set) {
    ;FIXME: make =hash into a helper function to reuse functionality here, don't make ADD until then
    %send (Decklist autodetection not implemented - will not autoadjust for now)
    if ($right($4,1) == :) {
      %deckowner = $left($4,-1)
      tokenize 32 $1-3 $5-
    }
    if (!$4) {
      %send Please enter deck content!
      return
    }
    %deck = $4-
    hadd invasions $+(deck,%idx) %deck
    hadd invasions $+(deckowner,%idx) %deckowner
    hadd invasions $+(deckchanged,%idx) $ctime
    hadd invasions $+(deckchangednick,%idx) $nick

    %buffer = Deck changed.
    if (!%deckowner) %buffer = %buffer Owner is not set. You can set owner with SET %slot owner: content
    %send %buffer
  }
  else {
    %send Command unimplented
  }
  return

  :ISON
  if (!$3) { fiqbot.usage $2 $chan | return }
  fiqbot.tyrant.login 1
  fiqbot.tyrant.showonlinestatus $3
  return

  :KILLSOCKETS
  hfree socketdata
  while ($sock(*,1)) {
    sockclose $sock(*,1)
  }
  set -u5 %killsockets 1
  unset %needlock
  unset %fiqbot_tyrant_socklock
  unset %forcedcode*
  unset %bruteforcing*
  fiqbot.tyrant.init

  %send Socket handlers has been reset.
  return

  :NOALERT
  if ($3 == check) {
    var %buffer
    var %global = %fiqbot_tyrant_noalert
    if (!%global) %global = unset
    %buffer = Global noalert setting: %global
    %global_you = %fiqbot_tyrant_noalert_ [ $+ [ $address($nick,2) ] ]
    if (!%global_you) %global_you = unset
    %buffer = %buffer :: Your global noalert setting: %global_you
    if ($chan) {
      var %local = %fiqbot_tyrant_noalert_ [ $+ [ $chan ] ]
      if (!%local) %local = unset
      %buffer = %buffer :: $chan setting: %local
      var %local_you = %fiqbot_tyrant_noalert_ [ $+ [ $+($chan,_,$address($nick,2)) ] ]
      if (!%local_you) %local_you = unset
      %buffer = %buffer :: Your $chan setting: %local_you
    }
    %send %buffer
    return
  }
  var %setchannel = $null
  if ($left($3,1) == $#) {
    %setchannel = $+(_,$3)
    tokenize 32 $1-2 $4-
  }
  var %setchannelstatus = %fiqbot_noalert [ $+ [ %setchannel ] ]
  var %nick = $false
  var %unset = $false
  if (($3 == global) || ($3 == highlights) || ($3 == reset)) {
    var %setchannelstatus = $3
    if (%setchannelstatus == reset) %setchannelstatus = $null
    if (%access < 3) {
      %send You don't have sufficient access to manipulate channel settings
      return
    }
  }
  elseif ($3 != unset) && ($3) {
    %nick = $3
    if (!$address(%nick,2)) {
      %send %nick isn't known to me.
      return
    }
    if ($address(%nick,2) != $address($nick,2)) && (%access < 4) {
      %send You don't have sufficient access to manipulate nick noalert settings
      return
    }
    tokenize 32 $1-2 $4-
  }
  else {
    %nick = $nick
  }
  if ($3 == unset) %unset = $true
  var %buffer
  if (%nick) {
    if (%unset) {
      unset %fiqbot_tyrant_noalert [ $+ [ $+(%setchannel,_,$address(%nick,2)) ] ]
      %buffer = Settings has been removed
    }
    else {
      set %fiqbot_tyrant_noalert [ $+ [ $+(%setchannel,_,$address(%nick,2)) ] ] 1
      %buffer = Settings has been set
    }
    if (%setchannel) %buffer = %buffer in $right(%setchannel,-1)
    if (%nick == $nick) %nick = you
    %buffer = %buffer for $+(%nick,.)
    %send %buffer
    return
  }
  var %changed
  if (%unset) {
    unset %fiqbot_tyrant_noalert [ $+ [ %setchannel ] ]
  }
  else {
    set %fiqbot_tyrant_noalert [ $+ [ %setchannel ] ] $lower(%setchannelstatus)
    %changed = $lower(%setchannelstatus)
  }
  %buffer = Global settings
  if (%setchannel) %buffer = %buffer in $right(%setchannel,-1) is
  else %buffer = %buffer are
  if (%unset) %buffer = %buffer now unset
  else %buffer = %buffer now $qt(%changed)
  %buffer = $+(%buffer,.)
  %send %buffer
  return

  :OWNEDCARDS
  var %time = $ticks
  if (!$3) { fiqbot.usage $2 $chan | return }
  var %all = $false
  if ($3 == -a) {
    %all = $true
    tokenize 32 $1-2 $4-
  }
  if (!$hget(usercards)) {
    %send Please query the player first with PLAYER
    return
  }

  var %user = $fiqbot.tyrant.db.select(users,$3)
  if ($gettok(%user,0,32) > 1) {
    %send There are several players with this name. The most likely option has been selected. Options are: %user (query by ID to get those)
    %user = $gettok(%user,1,32)
  }
  if (!%user) {
    %user = $3
  }
  noop $hget(usercards,%user,&cardlist)
  if (!$bvar(&cardlist,0)) {
    %send Please query the player first with PLAYER
    return
  }
  
  ;check access
  if (%access < 5) {
    ;only factionmates, this is checked by verifying that the specific user is in the associated faction channel.
    var %faction = $hget(userdata,$+(faction,%user))
    var %ownfactionuser = %fiqbot_tyrant_faccount [ $+ [ %faction ] ]
    var %factionchannel = %fiqbot_tyrant_factionchannel_ [ $+ [ %ownfactionuser ] ]
    if (!%factionchannel) || ($nick !ison %factionchannel) {
      %send Specified player is not a factionmate, isn't assigned to a faction known to FIQ-bot or you're not in the assigned FIQ-bot faction channel and you're not level 5.
      return
    }
  }
  var %inpos, %outpos, %bytes, %card, %name, %owned
  %inpos = 1

  while (%inpos < $bvar(&cardlist,0)) {
    tokenize 32 $bvar(&cardlist,%inpos,5)
    %card = $2
    if ($1) inc %card $calc($1 * 256)
    %name = $hget(cards,$+(name,%card))
    %owned = $4
    if ($3) inc %owned $calc($3 * 256)
    if ($5) inc %owned $5
    if (%owned) || (%all) {
      %outpos = $bvar(&cardlist_out,0)
      if (!%outpos) %outpos = 0
      inc %outpos
      bset -t &cardlist_out %outpos $+([,%card,]) %name ( $+ %owned $+ )
      %outpos = $bvar(&cardlist_out,0)
      inc %outpos
      bset &cardlist_out %outpos 13 10
    }
    inc %inpos 5
  }
  .remove ownedcards.txt
  bwrite ownedcards.txt 0 -1 &cardlist_out
  var %name = $rand(1,16777216)
  
  var %directory = $+(/tyrant/ownedcards_,%name,.txt)
  
  /*
  FIXME: make an uploader, currently this relies on local setup!
  
  rename ownedcards.txt $+(Z:/srv/http,%directory)
  */
  
  var %site = http://home.fiq.se
  
  %time = $ticks - %time
  %send %time ms :: Card list can be viewed at $+(%site,%directory)
  return

  :PLAYER
  var %chan = $chan
  if ($left($3,1) == $#) {
    var %chan = $3
    tokenize 32 $1-2 $4-
    if (%access < 5) && ($nick !ison %chan) {
      %send You're not in %chan and don't have sufficient access to check unless you're in the channel.
      return
    }
  }
  var %factionuser = %fiqbot_tyrant_factionchannel_ [ $+ [ %chan ] ]
  if (!%factionuser) {
    %factionuser = 2
  }
  elseif (!%fiqbot_tyrant_userid [ $+ [ %factionuser ] ]) {
    %factionuser = 2
  }
  set -u0 %usertarget %factionuser

  if (!$3) { fiqbot.usage $2 $chan | return }

  var %days = 7
  if ($4 != $null) %days = $4
  if (%days !isnum) || (. isin %days) || (%days < 1) {
    %send Days must be an integer above 0.
    return
  }
  
  fiqbot.tyrant.login %usertarget
  fiqbot.tyrant.showplayer $3 %days
  return

  :POSTDATA
  if (!%query) { %send Do not use this command in public. | return }
  if (!$3) { fiqbot.usage $2 $chan | return }
  fiqbot.tyrant.login 1
  fiqbot.tyrant.apiraw2 $3-
  return

  :RAID
  if ($3 == -l) {
    tokenize 32 $1-2 $4-
  }
  else {
    set -u0 %access 1
  }
  if (!$3) { fiqbot.usage $2 $chan | return }
  fiqbot.tyrant.login 1
  fiqbot.tyrant.showraid $3
  return

  :RAIDINFO
  if (!$3) { fiqbot.usage $2 $chan | return }
  return

  :REBUILD
  %send Rebuilding databases. Please wait a few minutes. The bot will become unresponsive.
  .timer 1 0 fiqbot.tyrant.downloadresources
  return

  :SETAUTH
  if (!%query) { %send Do not use this command in public. | return }
  if (!$6) { fiqbot.usage $2 $chan | return }
  var %1 = $int($3)
  set %fiqbot_tyrant_userid $+ %1 $4
  set %fiqbot_tyrant_token $+ %1 $5
  set %fiqbot_tyrant_flashcode $+ %1 $6
  %send Done.
  return

  :SETFACTION
  if (!$6) { fiqbot.usage $2 $chan | return }
  var %1 = $int($3)
  set %fiqbot_tyrant_faccount [ $+ [ $4 ] ] %1
  set %fiqbot_tyrant_fid [ $+ [ %1 ] ] $4
  set %fiqbot_tyrant_fp [ $+ [ %1 ] ] $5
  set %fiqbot_tyrant_fname [ $+ [ %1 ] ] $6-
  %send Done.
  return

  :SPOILER
  var %subscriptions = %fiqbot_tyrant_spoiler_subscriptions
  var %chan = $chan
  if ($left($3,1) == $#) {
    %chan = $3
    tokenize 32 $1-2 $4-
  }
  if (!%chan) {
    %send This command cannot be used in query without a channel parameter.
    return
  }
  var %old_subscribed = $false
  if ($findtok(%subscriptions,%chan,0,44)) %old_subscribed = $true
  if (!$3) {
    %send Spoiler alert settings for this channel is currently $iif(!%old_subscribed,not) subscribed.
    return
  }

  var %new_subscribed = $false
  if ($3 == on) %new_subscribed = $true
  elseif ($3 != off) {
    %send You must set it either on or off (to check current status, just don't give any value at all).
    return
  }

  if (%old_subscribed == %new_subscribed) {
    %send Spoiler alert settings for this channel is already $iif(!%old_subscribed,not) subscribed.
    return
  }
  if (%new_subscribed) %fiqbot_tyrant_spoiler_subscriptions = $addtok(%subscriptions,%chan,44)
  else %fiqbot_tyrant_spoiler_subscriptions = $remtok(%subscriptions,%chan,0,44)

  %send Spoiler alert settings for this channel was $iif(%old_subscribed,on,off) and is now turned $+($iif(%new_subscribed,on,off),.)
  return

  :STARTRAID
  if (!$3) { fiqbot.usage $2 $chan | return }
  fiqbot.tyrant.login 1
  var %raid, %confirm
  %confirm = $false
  if ($ [ $+ [ $0 ] ] == go-ahead) {
    %confirm = $true
    tokenize 32 $1- [ $+ [ $calc($0 - 1) ] ]
  }
  %raid = $3-
  %fiqbot_tyrant_raids = Arctis Vanguard:Xeno Walker:Siege on Kor: $+ $&
    Imperial Purger:Enclave Flagship:Oluth:Tartarus Swarm:Behemoth: $+ $&
    Miasma:Blightbloom:Gore Typhon:Jotun, Sacred Guardian: $+ $&
    Pantheon Perfect:Sentinel Reborn:Lithid:Lernaean Hydra: $+ $&
    Epic Imperial Purger:Scythos:Epic Siege on Kor:Arachis: $+ $&
    Epic Jotun:Karkinos
  if ((%raid !isnum) || (. isin %raid)) {
    if ($findtok(%fiqbot_tyrant_raids,%raid,58)) {
      %raid = $findtok(%fiqbot_tyrant_raids,%raid,58)
    }
    else {
      %send Invalid raid ID or name!
      return
    }
  }
  if ((%raid < 1) || (%raid > $gettok(%fiqbot_tyrant_raids,0,58))) {
    %send Invalid Raid ID
  }
  var %raid_name = $gettok(%fiqbot_tyrant_raids,%raid,58)
  if (!%confirm) {
    %send Start raid? Raid: %raid_name (id: %raid $+ ) $chr(124) To start, type $2- go-ahead
  }
  else {
    fiqbot.tyrant.startraid %raid
    %send Raid started! Raid: %raid_name $chr(124) Join Link: http://kongregate.com/games/synapticon/tyrant?kv_joinraid= $+ %fiqbot_tyrant_userid
  }
  return

  :TARGETS
  var %chan = $chan
  if ($left($3,1) == $#) {
    var %chan = $3
    tokenize 32 $1-2 $4-
    if (%access < 5) && ($nick !ison %chan) {
      %send You're not in %chan and don't have sufficient access to check unless you're in the channel.
      return
    }
  }
  var %factionuser = %fiqbot_tyrant_factionchannel_ [ $+ [ %chan ] ]
  if (!%factionuser) {
    %send There's currently no faction assigned to $iif(%chan == $chan,this channel,%chan) $+ .
    return
  }
  if (!%fiqbot_tyrant_userid [ $+ [ %factionuser ] ]) {
    %send There's currently no account assigned to $iif(%chan == $chan,this channel,%chan) $+ .
    return
  }
  set -u0 %usertarget %factionuser
  if ($3 == ignore) {
    var %ignores = %fiqbot_tyrant_ignoretargets [ $+ [ %usertarget ] ]
    if (!$4) {
      %send Current ignore list: $iif(%ignores,$replace(%ignores,$chr(44),$+($chr(44),$chr(32))),(none))
      return
    }
    %ignores = $replace($4-,$+($chr(44),$chr(32)),$chr(44))
    set %fiqbot_tyrant_ignoretargets [ $+ [ %usertarget ] ] %ignores
    %send Target ignores has been set.
    return
  }
  var %fid = %fiqbot_tyrant_fid [ $+ [ %usertarget ] ]
  var %showupcoming = $false
  var %hours = 0
  var %showinfamy = $false
  var %shownerfed = $false
  if ($3 == upcoming) {
    %showupcoming = $true
    %hours = 2
    %showinfamy = $true
    if ($4) %hours = $int($4)
    if ((%hours < 1) || (%hours > 6)) {
      %send You may only request upcoming target openings for 1-6h from now.
      return
    }
  }
  if ($3 == reset) {
    if (%access < 3) {
      %send You don't have sufficient access to reset the target list.
      return
    }
    hdel targets $+(nextid,%fid)
    hdel -w targets $+(*_,%fid,_*)
    %send Target list cleared.
    return
  }

  if (%target_recent > $ctime) {
    %send You requested a target list recently, please try again in $fiqbot.tyrant.duration($calc(%target_recent - $ctime))
    return
  }
  set %target_recent $ctime + 30

  var %suffixinfo = targets
  if (%showupcoming) %suffixinfo = targets opening in $+(%hours,h) or less

  var %id, %name, %fp, %points, %infamy, %upcoming, %nerf
  var %ownfp = $fiqbot.tyrant.factionfp
  var %targets = $false
  var %showinfamed = $false
  var %i = 0
  while (%i < $hget(targets,$+(nextid,%fid))) {
    inc %i
    %id = $hget(targets,$+(id_,%fid,_,%i))

    %name = $hget(factions,$+(name,%id))
    %fp = $hget(factiondata,$+(fp,%id))
    %points = $fiqbot.tyrant.gainedfp(%ownfp,%fp)
    %upcoming = $calc($hget(factiondata,$+(upcomingtarget,%id)) - $ctime)
    %infamy = $hget(factiondata,$+(infamy_gain,%id))
    %nerf = $hget(factiondata,$+(nerf,_,%fid,_,%id))

    if ($findtok(%fiqbot_tyrant_ignoretargets,%name,44)) continue

    if ((%infamy) && (!%showinfamy)) continue
    elseif (%infamy) {
      if ((%showupcoming) && ($calc(%hours * 3600) < %upcoming)) continue
      if (%upcoming >= 0) %upcoming = $duration(%upcoming,3)
      else %upcoming = <30s
      %name = $+(%name,+,%infamy,$chr(32),[,%upcoming,])
      if (!%showinfamed) %suffixinfo = %suffixinfo :: +N = infamy count :: [] = infamy reset time
      %showinfamed = $true
    }
    elseif (%showupcoming) continue
    if (%nerf) {
      %points = $ceil($calc(%points / 2))
      %name = $+(%name,*)
      if (!%shownerfed) %suffixinfo = %suffixinfo :: * = FP gain nerfed (shows nerfed FP)
      %shownerfed = $true
    }
    if (!%buffer [ $+ [ %points ] ]) %buffer [ $+ [ %points ] ] = %name
    else %buffer [ $+ [ %points ] ] = %buffer [ $+ [ %points ] ] $+ , %name
    %targets = $true
  }
  if (!%targets) {
    %send No %suffixinfo
    return
  }
  %send Showing %suffixinfo
  var %i = 11
  while (%i > 1) {
    dec %i
    if (%buffer [ $+ [ %i ] ]) {
      if ($len(%buffer [ $+ [ %i ] ]) > 300) {
        %buffer [ $+ [ %i ] ] = $left(%buffer [ $+ [ %i ] ],300) $+ (...)
      }
      %send $+(%i,:,$chr(32),%buffer [ $+ [ %i ] ])
    }
  }
  unset %buffer*
  return

  :TILES
  var %chan = $chan
  if ($left($3,1) == $#) {
    var %chan = $3
    tokenize 32 $1-2 $4-
    if (%access < 5) && ($nick !ison %chan) {
      %send You're not in %chan and don't have sufficient access to check unless you're in the channel.
      return
    }
  }
  var %factionuser = %fiqbot_tyrant_factionchannel_ [ $+ [ %chan ] ]
  var %fid = %fiqbot_tyrant_fid [ $+ [ %factionuser ] ]

  var %tile = $false
  if (?*,?* iswm $3) {
    if (!$fiqbot.tyrant.cqcoordinates($3)) {
      %send Invalid conquest coordinates: $3
      return
    }
    var %x, %y
    %x = $fiqbot.tyrant.cqcoordinates($3,x)
    %y = $fiqbot.tyrant.cqcoordinates($3,y)
    %tile = $true
    tokenize 32 $1-2 $4-
  }

  if ($3 != $null) {
    %fid = $fiqbot.tyrant.db.select(factions,$3-)
    if (!%fid) && (($3 !isnum) || (. isin $3)) {
      %send There's no faction named $3- on the conquest board right now.
      return
    }
    if (!%fid) %fid = $3
    elseif ($gettok(%fid,0,32) > 1) {
      %send There are several factions with this name. The most likely option has been selected. Options are: %fid (query by ID to get those)
      %fid = $gettok(%fid,1,32)
    }
  }
  if (%fid == $null) && (!%tile) {
    %send No faction specified.
    return
  }

  var %id, %cr, %bg, %owner_id, %owner_name, %protection_end, %attacker_id, %attacker_name, %attacker_start, %attacker_end, %buffer, %timeleft
  if (%tile) {
    %id = $hget(conquest,$+(id,%x,_,%y))
    %cr = $hget(conquest,$+(cr,%id))
    %bg = $hget(conquest,$+(bg,%id))
    %owner_id = $hget(conquest,$+(owner_id,%id))
    %owner_name = $hget(conquest,$+(owner_name,%id))
    %protection_end = $hget(conquest,$+(protection_end,%id))
    %attacker_id = $hget(conquest,$+(attacker_id,%id))
    %attacker_name = $hget(conquest,$+(attacker_name,%id))
    %attacker_start = $hget(conquest,$+(attacker_start,%id))
    %attacker_end = $hget(conquest,$+(attacker_end,%id))
    %buffer = Tile $fiqbot.tyrant.cqcoordinates(%x,%y) is

    if (%bg) %bg = $fiqbot.tyrant.bg(%bg)

    if (!%owner_id) %buffer = %buffer neutral
    else {
      %buffer = %buffer owned by %owner_name
      if ($calc(%protection_end - $ctime) > 0) {
        %timeleft = $fiqbot.tyrant.duration($calc(%protection_end - $ctime))
        %buffer = %buffer (Protection: %timeleft left)
      }
    }
    if (%attacker_id) {
      %buffer = %buffer and is attacked by %attacker_name
      %timeleft = $fiqbot.tyrant.duration($calc(%attacker_end - $ctime))
      %buffer = %buffer ( $+ %timeleft left)
    }
    %buffer = %buffer :: CR: %cr
    if (%bg) %buffer = %buffer :: Battleground: %bg
    %send %buffer
    return
  }

  var %totaltiles, %totalcr, %factionname, %buffer, %tilebuffer, %attacks, %attacking, %defending, %attackbuffer, %defensebuffer
  %factionname = $hget(factions,$+(name,%fid))

  %totaltiles = 0
  %totalcr = 0
  %id = 0
  %attacks = 0
  %attacking = $false
  %defending = $false
  while (%id < $hget(conquest,nextid)) {
    inc %id
    if ($hget(conquest,$+(owner_id,%id)) != %fid) && ($hget(conquest,$+(attacker_id,%id)) != %fid) continue

    %x = $hget(conquest,$+(x,%id))
    %y = $hget(conquest,$+(y,%id))
    %cr = $hget(conquest,$+(cr,%id))
    %bg = $hget(conquest,$+(bg,%id))
    %owner_id = $hget(conquest,$+(owner_id,%id))
    %owner_name = $hget(conquest,$+(owner_name,%id))
    %protection_end = $hget(conquest,$+(protection_end,%id))
    %attacker_id = $hget(conquest,$+(attacker_id,%id))
    %attacker_name = $hget(conquest,$+(attacker_name,%id))
    %attacker_start = $hget(conquest,$+(attacker_start,%id))
    %attacker_end = $hget(conquest,$+(attacker_end,%id))
    if (!%factionname) {
      if (%owner_id == %fid) %factionname = %owner_name
      else %factionname = %attacker_name
    }
    if (%owner_id == %fid) {
      inc %totaltiles
      inc %totalcr %cr
      %tilebuffer = $iif(%tilebuffer,$+(%tilebuffer,$chr(44))) $fiqbot.tyrant.cqcoordinates(%x,%y)
    }
    if (%attacker_id) {
      inc %attacks
      if (%owner_id != %fid) {
        %attacking = $fiqbot.tyrant.cqcoordinates(%x,%y)
        %attackbuffer = Invading $fiqbot.tyrant.cqcoordinates(%x,%y) owned by %owner_name
      }
      else {
        %defending = $true
        %defensebuffer = $iif(%defensebuffer,$+(%defensebuffer,$chr(44))) $fiqbot.tyrant.cqcoordinates(%x,%y)
        %attackbuffer = Defending $fiqbot.tyrant.cqcoordinates(%x,%y) against %attacker_name
      }

      %timeleft = $fiqbot.tyrant.duration($calc(%attacker_end - $ctime))
      %attackbuffer = %attackbuffer ( $+ %timeleft left)
      var %attackbuffer $+ %attacks %attackbuffer
    }
  }

  %buffer = Faction ID %fid
  if (%factionname) %buffer = %factionname

  if (!%totaltiles) && (!%attacking) && (!%defending) {
    %buffer = %buffer isn't on the conquest board.
    %send %buffer
    return
  }
  %buffer = %buffer has %totaltiles $+(tile,$iif(%totaltiles != 1,s))
  %buffer = $iif((%attacking) || (%defending),$+(%buffer,$chr(44)),%buffer and) $+(%totalcr,CR)
  if (%attacking) %buffer = $iif(%defending,$+(%buffer,$chr(44)),%buffer and) is attacking %attacking
  if (%defending) %buffer = %buffer and $iif(!%attacking,is) defending %defensebuffer
  if (%totaltiles > 5) {
    %send %buffer
    %send Tiles: %tilebuffer
  }
  elseif (%totaltiles) {
    %buffer = %buffer :: Tiles: %tilebuffer
    %send %buffer
  }
  else {
    %send %buffer
  }

  %buffer = $null
  var %i = 1
  var %sendlimit = 0
  while (%attackbuffer [ $+ [ %i ] ]) {
    %attackbuffer = %attackbuffer [ $+ [ %i ] ]
    inc %i
    inc %sendlimit
    %buffer = $iif(%buffer,%buffer ::) %attackbuffer
    if (%sendlimit == 3) || (!%attackbuffer [ $+ [ %i ] ]) {
      %sendlimit = 0
      %send %buffer
      %buffer = $null
    }
  }
  return

  :TRACKER
  if ($3 == on) {
    .timertyranttasks 0 30 fiqbot.tyrant.runinterval
    %send Tracking enabled.
  }
  elseif ($3 == off) {
    .timertyranttasks off
    %send Tracking disabled.
  }
  elseif ($3 == run) {
    %send Running trackers.
    fiqbot.tyrant.runinterval
  }
  else {
    fiqbot.tyrant.usage $2 $chan
  }
  return

  :VAULT
  fiqbot.tyrant.login 1
  if (!$3) {
    fiqbot.tyrant.showvault
    return
  }

  if (%query) {
    %send This command doesn't work in query.
    return
  }

  var %buffer
  if ($3 == reset) {
    unset %fiqbot_tyrant_vaultalert_ [ $+ [ $chan ] ]
    %buffer = Vault alert settings has been set.
  }
  elseif ($3 != current) {
    var %list = $3-
    tokenize 44 $3-
    var %buffer, %card, %realname, %name, %id, %set, %rarity
    %card = $false
    var %i = 0
    var %j, %foundcard
    var %converted
    while (%i < $0) {
      inc %i
      %foundcard = $false
      %j = $0
      while ((!%foundcard) && (%j >= %i)) {
        %realname = $gettok(%list,$+(%i,-,%j),44)
        if ($numtok(%realname,35) > 2) {
          dec %j
          continue
        }
        %name = $replace($remove(%realname,$chr(32)),*,+)
        %id = $hget(cards,$+(id,%name))
        if (!%id) {
          if (*[*] iswm %name) && ($chr(44) !isin %name) {
            %name = $+(a,%name)
            %name = $left($gettok(%name,2,91),-1)
          }
          if (!$hget(cards,$+(name,%name))) {
            dec %j
            continue
          }
          if (!%converted) %converted = $+([,%name,])
          else %converted = $+(%converted $+ $chr(44) $+ $chr(32)) $+([,%name,])
          %name = $hget(cards,$+(name,%name))
          %converted = $+(%converted,->,%name)
          %name = $remove(%name,$chr(32))
          %name = $replace(%name,*,+)
          %id = $hget(cards,$+(id,%name))
        }
        %realname = $hget(cards,$+(name,%id))
        %foundcard = $true
      }
      if (!%foundcard) {
        %send Invalid card: %realname
        return
      }
      else {
        %rarity = $hget(cards,$+(rarity,%id))
        if (%rarity != 3) {
          %send %realname is not a Rare.
          return
        }
        %set = $hget(cards,$+(set,%id))
        if ((%set != 1000) && ((%set > 12) || (%set < 1))) {
          %send %realname is part of a set which doesn't show up in the vault.
          return
        }
        %card = $true
        %buffer = %buffer %id
      }
      %i = %j
      %card = $true
    }
    if (%converted) {
      %send Converted: %converted
    }
    if (%buffer) {
      set %fiqbot_tyrant_vaultalert_ [ $+ [ $chan ] ] %buffer
      %buffer = Vault alert settings has been set.
    }
    else {
      %send Unknown error!
      return
    }
  }

  tokenize 32 %fiqbot_tyrant_vaultalert_ [ $+ [ $chan ] ]
  var %buffer2
  var %i = 0
  while (%i < $0) {
    inc %i
    var %name = $hget(cards,$+(name,$ [ $+ [ %i ] ]))
    %buffer2 = %buffer2 $+ , %name
  }
  %buffer2 = $right(%buffer2,-2)
  %buffer = %buffer Current vault alerts: $iif(%buffer2,%buffer2,(none))
  %send %buffer
  return

  :WAR
  var %chan = $chan
  if ($left($3,1) == $#) {
    var %chan = $3
    tokenize 32 $1-2 $4-
    if (%access < 5) && ($nick !ison %chan) {
      %send You're not in %chan and don't have sufficient access to check unless you're in the channel.
      return
    }
  }
  var %factionuser = %fiqbot_tyrant_factionchannel_ [ $+ [ %chan ] ]
  if (!%factionuser) {
    %send There's currently no faction assigned to $iif(%chan == $chan,this channel,%chan) $+ .
    return
  }
  if (!%fiqbot_tyrant_userid [ $+ [ %factionuser ] ]) {
    %send There's currently no account assigned to $iif(%chan == $chan,this channel,%chan) $+ .
    return
  }
  if (!$3) {
    fiqbot.tyrant.login %factionuser
    fiqbot.tyrant.showwars
    return
  }
  var %war, %player, %playername, %amount, %faction
  %war = 0
  %player = 0
  %playername = $null
  %amount = 3
  %faction = %fiqbot_tyrant_fid [ $+ [ %factionuser ] ]
  if ($hget(wars,$+(pointer_,%faction,_,$3))) {
    %war = $3
    %amount = 1
    tokenize 32 $1-2 $4-
  }
  if ($3) {
    if ($3 !isnum) || (. isin $3) {
      %player = $fiqbot.tyrant.db.select(users,$3)
      
      if ($gettok(%player,0,32) > 1) {
        %send There are several players with this name. The most likely option has been selected. Options are: %player (query by ID to get those)
        %player = $gettok(%player,1,32)
      }
      if (!%player) {
        %send No such player.
        return
      }
    }
    else {
      %player = $3
    }
    if ($4) && (!%war) {
      if ($4 < 1) || ($4 !isnum) || (. isin $4) {
        %send Invalid war amount: $4
        return
      }
      %amount = $4
      if (%amount > 10) %amount = 10
    }
  }
  if (%player) {
    %playername = $hget(users,$+(name,%player))
    if (!%playername) {
      %send No such player.
      return
    }
    var %win.off, %win.def, %win.pts, %loss.off, %loss.def, %loss.pts, %fights, %net
    var %defstat.win, %defstat.winpts, %defstat.loss, %defstat.losspts, %defstat.net
    var %idx, %nextid, %nextidx, %sent
    
    %nextid = $hget(wars,$+(nextid,%faction))
    %sent = $false
    if (!%war) {
      %send Showing performance for %playername for the latest %amount $iif(%amount == 1,war,wars)
    }
    while (%amount) {
      dec %nextid
      dec %amount

      %nextidx = $+(_,%faction,_,%nextid)
      if (!%war) {
        %war = $hget(wars,$+(id,%nextidx))
      }
      if (!%war) {
        break
      }
      %idx = $+(_,%war,_,%player)
      %win.off = $hget(wardata,$+(winoff,%idx))
      %win.def = $hget(wardata,$+(windef,%idx))
      %win.pts = $hget(wardata,$+(winpts,%idx))
      %loss.off = $hget(wardata,$+(lossoff,%idx))
      %loss.def = $hget(wardata,$+(lossdef,%idx))
      %loss.pts = $hget(wardata,$+(losspts,%idx))
      %fights = %win.off + %loss.off
      %net = %win.pts - %loss.pts
      %defstat.win = $hget(wardata,$+(defstatwin,%idx))
      %defstat.winpts = $hget(wardata,$+(defstatwinpts,%idx))
      %defstat.loss = $hget(wardata,$+(defstatloss,%idx))
      %defstat.losspts = $hget(wardata,$+(defstatlosspts,%idx))
      %defstat.net = %defstat.winpts - %defstat.losspts
      if (- !isin %net) %net = $+(+,%net)
      if (- !isin %defstat.net) %defstat.net = $+(+,%defstat.net)
      if (!%win.pts) && (!%loss.pts) {
        unset %war
        continue
      }
      var %buffer = $null
      %buffer = %war
      %buffer = %buffer :: %playername
      %buffer = %buffer :: Points: $+(%win.pts,-,%loss.pts) ( $+ %net $+ )
      %buffer = %buffer :: Attack: $+(%win.off,/,%loss.off)
      %buffer = %buffer :: Defense: $+(%win.def,/,%loss.def)
      %buffer = %buffer :: Defense points: $+(%defstat.winpts,-,%defstat.losspts) ( $+ %defstat.net $+ ), accounted for $+(%defstat.win,/,%defstat.loss) defense W/L
      %send %buffer
      %sent = $true
      unset %war
    }
    if (!%sent) %send No data.
    return
  }
  return
  :WARLOG
  var %chan = $chan
  if ($left($3,1) == $#) {
    var %chan = $3
    tokenize 32 $1-2 $4-
    if (%access < 5) && ($nick !ison %chan) {
      %send You're not in %chan and don't have sufficient access to check unless you're in the channel.
      return
    }
  }
  var %factionuser = %fiqbot_tyrant_factionchannel_ [ $+ [ %chan ] ]
  if (!%factionuser) {
    %send There's currently no faction assigned to $iif(%chan == $chan,this channel,%chan) $+ .
    return
  }
  if (!%fiqbot_tyrant_userid [ $+ [ %factionuser ] ]) {
    %send There's currently no account assigned to $iif(%chan == $chan,this channel,%chan) $+ .
    return
  }
  set -u0 %usertarget %factionuser
  fiqbot.tyrant.login %factionuser
  var %amount = 1
  if (($3 isnum) && (. !isin $3)) {
    if (($3 >= 1) && ($3 <= 5)) %amount = $3
    else {
      %send Amount must be 1-5 only.
      return
    }
    tokenize 32 $1-2 $4-
  }
  var %faction
  if ($3) %faction = $3-
  fiqbot.tyrant.showwarlog %amount %faction
  return

  ;END OF TYRANT CODE


  ;BEGIN OF CUSTOM CODE
  ;END OF CUSTOM CODE


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
