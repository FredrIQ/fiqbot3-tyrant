fiqbot3-tyrant
==============

Data mining bot for War Metal Tyrant, based on FIQ-bot v3

Installing
==========

* Replicate the directory structure. That is, place the scripts in the **same** directory, and make sure to include the tyrant directory etc.
* Once you've done this, edit configurations as you wish in fiqbot-config.mrc.
* When this is all done, type /load -rs \path\to\fiqbot.mrc.
* To set Tyrant info, look at the documentation (!help <command>) for "setfaction" and "setauth". The internal ID starts from 1+.
* To have !faction work, account #2 MUST exist and MUST NOT be part of a faction. This is very important!.
  This is because, for !faction, the bot needs to join the faction. Once this is done, the bot WILL LEAVE it immediately.
  Simply setting an account WITH a faction as #2 will make the bot LEAVE this faction once !faction is used.
* Done!
