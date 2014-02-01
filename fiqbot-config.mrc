;FIQ-bot configuration
;Syntax: alias <setting> return <value>

;Version number
;Default: 3.3-tyrant
alias fiqbot.version return 3.3-tyrant

;Root password - if you want a straight forward way to give yourself max access (11) by using "rootme <password>" in query.
;Security issue if someone knows about this password, keep this in mind.
;Default: not set (commented out)
;Uncomment to use
;alias fiqbot.rootpass return VeryGoodPassword

;Default admin account. The address of this account is enforced to be 11.
;Default: FIQ (commented out)
;Uncomment to use
;alias fiqbot.rootaccount return FIQ!*@*

;System channel - if you want a dedicated channel that this bot always joins.
;Default: #FIQ-bot (commented out)
;Uncomment to use
;alias fiqbot.channel return #FIQ-bot

;TYRANT CONFIGURATIONS

;Tyrant version. Set this to the current version for Tyrant.
;Default: 2.17.09
alias fiqbot.tyrant.version return 2.17.09

;Tyrant "time hash" salt. This must be changed to the actual salt.
;The salt can be retrieved only if you know what you're doing.
;The reason this is censored is to prevent you from being able to
;understand and use Tyrant's API from this script alone and thus
;be able to bot easily. By replacing the content here, you accept that I have
;no responsibility for what you do with API access.
alias fiqbot.tyrant.salt return TYRANT_STATIC_SALT

;Directory to save Tyrant XMLs and databases (hash tables) in.
;Default: (the script directory)\tyrant
alias fiqbot.tyrant.directoryconfig return $+($scriptdir,tyrant\)

;Tracker channel - if you want to give general CQ info and such.
;Default: #botfarm
alias fiqbot.tyrant.trackerchannel return #botfarm

;Faction range - for scanning faction names.
;You should have gotten a starting point by factions.fht if imported correctly.
;This way, you don't have to re-scan the entire faction list.
alias fiqbot.tyrant.firstfaction return 25543002
alias fiqbot.tyrant.lastfaction return 25544002


on *:LOAD:{
  ;verify that $fiqbot.tyrant.directory exists
  if (!$exists($fiqbot.tyrant.directoryconfig)) {
    %send [Loading error] Dedicated Tyrant directory doesn't exist! Falling back to default.
    mkdir $+($scriptdir,tyrant\)
    mkdir $+($scriptdir,tyrant\tables)
    mkdir $+($scriptdir,tyrant\xml)
  }
}