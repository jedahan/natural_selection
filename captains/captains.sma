/* vim: set filetype=c : */ 

// Captains v0.1 Copyright 2008 `svc_bad
// Distributed under the terms of the GNU General Public License v2

#include <amxmodx>
#include <amxmisc>
#include <ns>

#define PLUGIN "Captains"
#define VERSION "0.1"
#define AUTHOR "`svc_bad"

#define MAX_PUGGERS 12

new pMenu // Menu
new pMenuCallback

new puggers[MAX_PUGGERS] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}
new captains[2] = {-1, -1}
new puggerIndex = 0
new captainIndex = 0

new commands[][2][] = {	{ "help", "printHelp" },
			{ "join", "joinPug" },
			{ "leave", "leavePug" },
			{ "captain", "captainPug" },
			{ "show", "showPuggers" },
			{ "uncaptain", "uncaptainPug" },
			{ "random", "randomPug" } }

new temp[32] // used for various strings with formatex
new curTeam[] = "amx_marines"

// Register the plugin, commands, cvars, etc
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	registerCommands()
	register_cvar("amx_ready_timeout","10")	
}

// Register all the commands
registerCommands() 
{
	for(int i = 0; i < (sizeof commands); i++) {
		addCommand(commands[i][0], commands[i][1] }
}

// Add four aliases for one command to a single function
addCommand(command[], function) 
{
	formatex(temp,"say .%s", command) 
	register_clcmd(temp, function) // say .command
	formatex(temp,"say .%s", command[0]) 
	register_clcmd(temp, function) // say .c
	formatex(temp,"say_team .%s", command) 
	register_clcmd(temp, function) // say_team .command
	formatex(temp,"say_team .%s", command[0]) 
	register_clcmd(temp, function) // say_team .c
}



// Show all the commands
public printHelp(id, command) 
{
	client_print(id, print_chat, "[CAPTAINS] v0.1 by `svc_bad")
	client_print(id, print_chat, "[CAPTAINS] commands are .join  .leave  .captain  .uncaptain  .show  .assign  .random  .help")
	client_print(id, print_chat, "[CAPTAINS] you can also use shortened aliases, like .h for .help")
	return PLUGIN_HANDLED
}

// Return the index of 'id' in array, if it is found
public getIndex(id, array[], index) 
{
	for (new i=0; i<index; i++)
		if( array[i] == id )
			return i;
	return -1
}

// Helper functions
public inArray(id, array[], index) { return getIndex(id, array, index) != -1; }
public getPuggerIndex(id)  { return getIndex(id, puggers,  puggerIndex); }
public isPugger(id)  { return inArray (id, puggers,  puggerIndex); }
public getCaptainIndex(id)  { return getIndex(id, captains, captainIndex); }
public isCaptain(id) { return inArray (id, captains, captainIndex); }

// Simplify messages meant to 
public capSay(id, mymessage[]) 
{
	client_print(id, print_chat, "[CAPTAINS] %s", mymessage)
	return PLUGIN_CONTINUE
}

// Add a player to the puggers array
public joinPug(id) 
{
	if (isPugger(id))
		capSay(id, "You are already in the pug!")
	else {
		get_user_name(id, temp, 31)
		client_print(id, print_chat, "[CAPTAINS] %s has joined the pug!", temp)
		puggers[puggerIndex++] = id 		// add pugger to list, increment counter
		if ( puggerIndex == MAX_PUGGERS ) {	// when the final pugger has joined
			capSay(0, "The final player has joined!")
			if ( captains[0] != -1 ) {
				if ( captains[1] != -1 ) // if there are two captains and 12 puggers
					pickTeams
				get_user_name(captains[0], temp, 31)
				capSay(0, "Waiting for second captain to volunteer with .c[aptain]")
				client_print(0, print_chat, "[CAPTAINS] %s can use .p[ick] to randomly select a second captain", temp)
				capSay(0, "Or, if 5 people use .random, both teams will be randomly assigned")
			}
		}
	}
	return PLUGIN_HANDLED
}

// Remove a captain
public uncaptainPug(id) {
	if (isCaptain(id)) {
		get_user_name(id,temp,31)
		captains[getCaptainIndex(id)] = captains[captainIndex--]
		client_print(0, print_chat, "[CAPTAINS] %s is no longer a captain", temp)
	} else 
		capSay(id, "You aren't a captain!")
		
	return PLUGIN_HANDLED
}

// Remove a pugger
public leavePug(id) {
	if(isCaptain(id))
		uncaptainPug(id)
	if (isPugger(id)) {
		get_user_name(id,temp,31)
		puggers[getPuggerIndex(id)] = puggers[puggerIndex--]
		client_print(0, print_chat, "[CAPTAINS] %s has left the pug!", temp)
	} else
		capSay(id, "You are not yet in the pug!")

	return PLUGIN_HANDLED
}

// Add a captain
public captainPug(id) {
	if (!isPugger(id))
		joinPug(id)
		
	if (!isCaptain(id)) {
		get_user_name(id,temp,31)
		captains[captainIndex++] = id
		client_print(0, print_chat, "[CAPTAINS] %s is now a captain!", temp)
		if (captainIndex == 2)
			pickTeams
	} else
		capSay(id, "You are already a captain!")	
	
	return PLUGIN_HANDLED
	
}

// Show a list of puggers, * indicates captain
public showPuggers(id) {
	new capstr[1] = ""
	
	for( new i=0; i<puggerIndex; i++ ) {
		get_user_name(puggers[i],temp,31)
		capstr[0] = isCaptain(puggers[i]) ? '*' : ''
		client_print(id, print_chat, "[%d] %s %s", i+1, temp, capstr)
	}
	
	return PLUGIN_HANDLED
}

// Initialize team choosing
public pickTeams() {
	new firstPick = random_num(0, 1)
	new secondPick = 0
	if (firstPick == 0) { secondPick = 1; }
	new teams[2][];

	teams[0][] = "marines"
	teams[1][] = "aliens"

	new firstTeam[] = "marines"
	new secondTeam
	
	if ( random_num(0,1) > 0) {
		teams[0][] = "aliens"
		teams[1][] = "marines"
	}

	get_user_name(captains[firstPick], temp,31)
	client_print(0, print_chat, "%s gets to pick first for %s", temp, teams[0])
	
	pMenu = menu_create("Choose a Pugger", "PuggerMenuHandler")
	pMenuCallback = menu_makecallback("PuggerMenuCallback");
	
	
	formatex(curTeam, "amx_%s", teams[0])
	showPuggerMenu(captains[firstPick])
	formatex(curTeam, "amx_%s", teams[1])
	showPuggerMenu(captains[secondPick])
	formatex(curTeam, "amx_%s", teams[1])
	showPuggerMenu(captains[secondPick])
	for (new i=0; i<puggerIndex-3; i++) {
		formatex(curTeam, "amx_%s", teams[0])
		showPuggerMenu(captains[firstPick])
		formatex(curTeam, "amx_%s", teams[1])
		showPuggerMenu(captains[secondPick])
	}
	
	 
	menu_setprop(puggerMenu, MPROP_EXIT, MEXIT_ALL)

	return PLUGIN_HANDLED
}


// redraw the pugger menu - this might be handled by the callback function
public showPuggerMenu(id) {
	for (new i=0; i<puggerIndex; i++) {
		if(!isCaptain(puggers[i])) {
			get_user_name(puggers[i],temp,31)
			menu_additem(pMenu, temp, puggers[i] , 0, pMenuCallback)
		}
	}
	menu_addblack(pMenu, 0)
	menu_display(id, pMenu, 0)	
}

// call this before every item to see if it is enabled
public pMenuCallback(id, menu, item)
	return access(id, MENU_ACCESS_FLAG) ? ITEM_ENABLED : ITEM_DISABLED;

// Run when an item is selected from the pugger menu
public pMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
		return 1;
	
	static pMenuCallback, sData[6];
	menu_item_getinfo(menu, item, iAccess, sData, sizeof sData - 1, _, _, pMenuCallback);

	static pId;
	pId = str_to_num(sData);

	choosePugger(pId)
}

// Assign random captains
public pickCaptains(id) {
	if (puggerIndex != MAX_PUGGERS)
		capSay(id, "Wait until there are 12 puggers before executing .assign")
	else {
		while(captainIndex != 2)
			captainPug(puggers[random_num(0,11)])
		pickTeams
	}
	return PLUGIN_HANDLED
}

// Run command curTeam on pugger id
public choosePugger(id) {
	get_user_name(puggers[i],temp,31)
	client_cmd(id, curTeam)
	puggers[id] = puggers[puggerIndex--]
}
