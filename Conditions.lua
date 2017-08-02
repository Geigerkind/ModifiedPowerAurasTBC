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
	MPowa_Tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	for i=0,40 do
		MPowa_Tooltip:ClearLines()
		MPowa_Tooltip:SetPlayerBuff(GetPlayerBuff(i, "HELPFUL|PASSIVE"))
		local desc = MPowa_TooltipTextLeft2:GetText()
		if (not desc) then break end
		if strfind(desc, MPOWA_SCRIPT_MOUNT_100) or strfind(desc, MPOWA_SCRIPT_MOUNT_60) then
			self.mounted = true
			return
		end
	end
	self.mounted = false
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