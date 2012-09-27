RandomMount
===========

World of Warcraft addon to mount/dismount with some random

Commands
--------
**/rm add TYPE SPELL_ID**
	where TYPE is F for flying mounts, S for swimming mounts, N for ground mounts, P for pets
	you can find SPELL_ID on wowhead, blizz armory, ...
	For mounts, you have to get the spellID (as for http://www.wowhead.com/spell=40192)
	For pets, you have to get the npcID (as for http://www.wowhead.com/npc=26119)
	  
**/rm del TYPE SPELL_ID**
	remove the mount or pet specified by the type and the spellID from your collection
	
**/rm mount**
	invoke a random mount from your collection

**/rm pet**
	invoke a random pet from your collection

**/rm list**
	list your collection
	
There's also a hidden **/rm clear** command which allows you to clean your entire collection. **No warning, no confirmation. Use with caution.**
	
Information
-----------
This addon perfectly fit my needs but it may be bugged. Use at your own risk. If you find a bug, feel free to report an issue.

License
-------
This addon is under the MIT license. (see [License File](https://github.com/bmichotte/RandomMount/blob/master/LICENSE))