/*-------------------------------------------------------------------------------------------------------------------------
	Force a map vote
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Force RTV"
PLUGIN.Description = "Forces a map vote"
PLUGIN.Author = "Boopington"
PLUGIN.ChatCommand = "forcertv"
PLUGIN.Usage = ""
PLUGIN.Privileges = { "Force RTV" }

function PLUGIN:Call( ply, args )
	if ( ply:EV_HasPrivilege( "Force RTV" ) ) then
		StartVote()
		evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " has forced a map vote." )
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

evolve:RegisterPlugin( PLUGIN )