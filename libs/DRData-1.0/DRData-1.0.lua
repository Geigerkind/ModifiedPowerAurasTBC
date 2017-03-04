local major = "DRData-1.0"
local minor = tonumber(string.match("$Revision: 793$", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local Data = LibStub:NewLibrary(major, minor)
if( not Data ) then return end

-- How long before DR resets
Data.RESET_TIME = 18

-- List of spellID -> DR category
Data.spells = {
	--[[ DISORIENTS ]]--
	-- Maim
	[22570] = "disorient",
	[49802] = "disorient",

	-- Sap
	[6770] = "disorient",
	[2070] = "disorient",
	[11297] = "disorient",
	[51724] = "disorient",
	
	-- Gouge
	[1776] = "disorient",
		
	-- Polymorph
	[118] = "disorient",
	[12824] = "disorient",
	[12825] = "disorient",
	[28272] = "disorient",
	[28271] = "disorient",
	[12826] = "disorient",
	[61305] = "disorient",
	[61025] = "disorient",
	
	-- Repentance
	[20066] = "disorient",

	--[[ FEARS ]]--
	-- Fear (Warlock)
	[5782] = "fear",
	[6213] = "fear",
	[6215] = "fear",
	
	-- Seduction (Pet)
	[6358] = "fear",
	
	-- Howl of Terror
	[5484] = "fear",
	[17928] = "fear",

	-- Psychic scream
	[8122] = "fear",
	[8124] = "fear",
	[10888] = "fear",
	[10890] = "fear",
	
	-- Scare Beast
	[1513] = "fear",
	[14326] = "fear",
	[14327] = "fear",
	
	-- Turn Evil
	[10326] = "fear",
	
	-- Intimidating Shout
	[5246] = "fear",
			
	--[[ CONTROL STUNS ]]--
	-- Hammer of Justice
	[853] = "ctrlstun",
	[5588] = "ctrlstun",
	[5589] = "ctrlstun",
	[10308] = "ctrlstun",

	-- Bash
	[5211] = "ctrlstun",
	[6798] = "ctrlstun",
	[8983] = "ctrlstun",
	
	-- Pounce
	[9005] = "ctrlstun",
	[9823] = "ctrlstun",
	[9827] = "ctrlstun",
	[27006] = "ctrlstun",
	[49803] = "ctrlstun",
	
	-- Intimidation
	[19577] = "ctrlstun",

	-- Charge
	[7922] = "ctrlstun",

	-- Cheap Shot
	[1833] = "ctrlstun",

	-- War Stomp
	[20549] = "ctrlstun",

	-- Intercept
	[20252] = "ctrlstun",
		
	-- Shadowfury
	[30283] = "ctrlstun", 
	[30413] = "ctrlstun",
	[30414] = "ctrlstun",
	
	-- Impact
	[12355] = "ctrlstun",
	
	-- Gnaw (Ghoul)
	[47481] = "ctrlstun",

	--[[ RANDOM STUNS ]]--
	-- Stoneclaw Stun
	[39796] = "rndstun",
	
	-- Starfire Stun
	[16922] = "rndstun",
	
	-- Mace Stun
	[5530] = "rndstun",
	
	-- Stormherald/Deep Thunder
	[34510] = "rndstun",
	
	-- Seal of Justice
	[20170] = "rndstun",
	
	-- Blackout
	[15269] = "rndstun",
	
	-- Revenge Stun
	[12798] = "rndstun",
	
	--[[ CYCLONE ]]--
	-- Blind
	[2094] = "cyclone",
	
	-- Cyclone
	[33786] = "cyclone",
	
	--[[ ROOTS ]]--
	-- Freeze (Water Elemental)
	[33395] = "root",
	
	-- Frost Nova
	[122] = "root",
	[865] = "root",
	[6131] = "root",
	[10230] = "root",
	[27088] = "root",
	[42917] = "root",
	
	-- Entangling Roots
	[339] = "root",
	[1062] = "root",
	[5195] = "root",
	[5196] = "root",
	[9852] = "root",
	[9853] = "root",
	[26989] = "root",
	[53308] = "root",

	--[[ RANDOM ROOTS ]]--
	-- Improved Hamstring
	[23694] = "rndroot",
	
	-- Frostbite
	[12494] = "rndroot",

	--[[ SLEEPS ]]--
	-- Hibernate
	[2637] = "sleep",
	[18657] = "sleep",
	[18658] = "sleep",
	
	-- Wyvern Sting
	[19386] = "sleep",
	[24132] = "sleep",
	[24133] = "sleep",
	[27068] = "sleep",
	[49011] = "sleep",
	[49012] = "sleep",
	
	--[[ MISC ]]--
	-- Chastise (Maybe this shares DR with Imp HS?)
	[44041] = "chastise",
	[44043] = "chastise",
	[44044] = "chastise",
	[44045] = "chastise",
	[44046] = "chastise",
	[44047] = "chastise",

	-- Freezing Trap
	[3355] = "freezetrap",
	[14308] = "freezetrap",
	[14309] = "freezetrap",
	
	-- Improved Conc Shot
	[19410] = "impconc",
	[22915] = "impconc",
	[28445] = "impconc",
	
	-- Death Coil
	[6789] = "dc",
	[17925] = "dc",
	[17926] = "dc",
	[27223] = "dc",
	[47859] = "dc",
	[47860] = "dc",

	-- Mind Control
	[605] = "charm",
	[10911] = "charm",
	[10912] = "charm",
}

-- DR Category names
Data.typeNames = {
	["disorient"] = "Disorients",
	["fear"] = "Fears",
	["ctrlstun"] = "Controlled Stuns",
	["rndstun"] = "Random Stuns",
	["cyclone"] = "Cyclone/Blind",
	["chastise"] = "Chastise",
	["freezetrap"] = "Freeze Trap",
	["rndroot"]  = "Random Roots",
	["dc"] = "Death Coil",
	["sleep"] = "Sleep",
	["root"] = "Controlled Roots",
	["impconc"] = "Imp Concussive Shot",
	["charm"] = "Charms",
}

-- Categories that have DR in PvE as well as PvP
Data.pveDRs = {
	["ctrlstun"] = true,
	["rndstun"] = true,
	["cyclone"] = true,
}

-- List of DRs
Data.categories = {}
for _, cat in pairs(Data.spells) do
	Data.categories[cat] = true
end

-- Public APIs
-- Category name in something usable
function Data:GetCategoryName(cat)
	return cat and Data.typeNames[cat] or nil
end

-- Spell list
function Data:GetSpells()
	return Data.spells
end

-- Seconds before DR resets
function Data:GetResetTime()
	return Data.RESET_TIME
end

-- Get the category of the spellID
function Data:GetSpellCategory(spellID)
	return spellID and Data.spells[spellID] or nil
end

-- Does this category DR in PvE?
function Data:IsPVE(cat)
	return cat and Data.pveDRs[cat] or nil
end

-- List of categories
function Data:GetCategories()
	return Data.categories
end

-- Next DR, if it's 1.0, next is 0.50, if it's 0.50 next is 0.25 and such
function Data:NextDR(diminished)
	if( diminished == 1.0 ) then
		return 0.50
	elseif( diminished == 0.50 ) then
		return 0.25
	end
	
	return 0
end

--[[ EXAMPLES ]]--
--[[
	This is how you would track DR easily, you're welcome to do whatever you want with the below 4 functions.

	Does not include tracking for PvE, you'd need to hack that in yourself but it's not (too) hard.
]]

--[[
local trackedPlayers = {}
local function debuffGained(spellID, destName, destGUID, isEnemy)
	if( not trackedPlayers[destGUID] ) then
		trackedPlayers[destGUID] = {}
	end

	-- See if we should reset it back to undiminished
	local drCat = DRData:GetSpellCae
	local tracked = trackedPlayers[destGUID][drCat]
	if( tracked and tracked.reset <= GetTime() ) then
		tracked.diminished = 1.0
	end	
end

local function debuffFaded(spellID, destName, destGUID, isEnemy)
	local drCat = DRData:GetSpellCategory(spellID)
	if( not trackedPlayers[destGUID] ) then
		trackedPlayers[destGUID] = {}
	end

	if( not trackedPlayers[destGUID][drCat] ) then
		trackedPlayers[destGUID][drCat] = { reset = 0, diminished = 1.0 }
	end
	
	local time = GetTime()
	local tracked = trackedPlayers[destGUID][drCat]
	
	tracked.reset = time + DRData:GetResetTime()
	tracked.diminished = nextDR(tracked.diminished)
end

local function resetDR(destGUID)
	-- Reset the tracked DRs for this person
	if( trackedPlayers[destGUID] ) then
		for cat in pairs(trackedPlayers[destGUID]) do
			trackedPlayers[destGUID][cat].reset = 0
			trackedPlayers[destGUID][cat].diminished = 1.0
		end
	end
end

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER

local eventRegistered = {["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true, ["PARTY_KILL"] = true, ["UNIT_DIED"] = true}
local function COMBAT_LOG_EVENT_UNFILTERED(self, event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType)
	if( not eventRegistered[eventType] or ( bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= COMBATLOG_OBJECT_TYPE_PLAYER and bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= COMBATLOG_OBJECT_CONTROL_PLAYER ) ) then
		return
	end
	
	-- Enemy gained a debuff
	if( eventType == "SPELL_AURA_APPLIED" ) then
		if( auraType == "DEBUFF" and Data.Spells[spellID] ) then
			debuffGained(spellID, destName, destGUID, (bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE))
		end
	
	-- Buff or debuff faded from an enemy
	elseif( eventType == "SPELL_AURA_REMOVED" ) then
		if( auraType == "DEBUFF" and Data.Spells[spellID] ) then
			debuffFaded(spellID, destName, destGUID, (bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE))
		end
		
	-- Don't use UNIT_DIED inside arenas due to accuracy issues, outside of arenas we don't care too much
	elseif( ( eventType == "UNIT_DIED" and select(2, IsInInstance()) ~= "arena" ) or eventType == "PARTY_KILL" ) then
		resetDR(destGUID)
	end
end
]]