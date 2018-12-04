local _G = getglobal
local tinsert = table.insert
local tremove = table.remove
local UN = UnitName
local strform = string.format
local flr = floor
local strgfind = string.gfind
local strfind = string.find
local GT = GetTime
local tnbr = tonumber
local GetNumPartyMembers = GetNumPartyMembers
local UnitInRaid = UnitInRaid
local GetBattlefieldStatus = GetBattlefieldStatus

function MPOWA:IsMounted()
	self.mounted = IsMounted();
end

local UnitInParty = UnitInParty
function MPOWA:InParty()
	return GetNumPartyMembers() > 0 or UnitInRaid("player") or UnitInParty("player")
end

function MPOWA:InBG()
	for i=1, 5 do
		local status = GetBattlefieldStatus(i)
		if status == "active" then
			self.bg = true
			break
		end
	end
	self.bg = false
end

function MPOWA:InInstance()
	self.instance = IsInInstance()
end