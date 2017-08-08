local stf = strfind
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
local GetNumRaidMembers = GetNumRaidMembers
local GetNumPartyMembers = GetNumPartyMembers
local ceil = ceil

function MPOWA:Reverse(bool)
	return not bool
end

function MPOWA:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("MPOWA: "..msg)
end

function MPOWA:GetGroup()
	if UnitInRaid("player") then
		for i=1, 40 do
			local name = UN("raid"..i)
			if name and self.RaidGroupMembers[name] then
				self.groupByNames[name] = "raid"..i
				self.groupByUnit["raid"..i] = name
			end
		end
	elseif self:InParty() then
		for i=1, 5 do
			local name = UN("party"..i)
			if name and self.RaidGroupMembers[name] then
				self.groupByNames[name] = "party"..i
				self.groupByUnit["party"..i] = name
			end
		end
	end
end

function MPOWA:GetTablePosition(tab, value)
	for cat, val in pairs(tab) do
		if val == value then
			return cat
		end
	end
	return false
end

function MPOWA:GetMaxValues(val)
	val = tnbr(val)
	return ceil(val)+50
end

function MPOWA:GetMinValues(val)
	val = tnbr(val)
	return ceil(val)-50
end