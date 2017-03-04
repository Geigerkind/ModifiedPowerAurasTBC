BuffLibDebug = 0
BuffLibDB = BuffLibDB or { sync = true}
local function log(msg)
	if BuffLibDebug == 1 then
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	elseif BuffLibDebug == 0 then
		return
	end
end -- alias for convenience

local DR_RESET_TIME = 15
local DRLib

local logDelay = 0.05

local applyEvents = {
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REFRESH",
	"SPELL_AURA_APPLIED_DOSE",
	"SPELL_CAST_SUCCESS",
}

local removeEvents = {
	"SPELL_AURA_REMOVE",
	"SPELL_AURA_DISPEL",
	"SPELL_AURA_STOLEN",
}

local _UnitBuff = UnitBuff
local _UnitDebuff = UnitDebuff

local function firstToUpper(str)
	if (str~=nil) then
		return (str:gsub("^%l", string.upper));
	else
		return nil;
	end
end

local function wipe(t)
	for k,v in pairs(t) do
		t[k]=nil
	end
end

local BuffLib = CreateFrame("Frame", nil, UIParent);
function BuffLib:OnEvent(event, ...) -- functions created in "object:method"-style have an implicit first parameter of "self", which points to object
	self[event](self, ...) -- route event parameters to LoseControl:event methods
end
BuffLib:SetScript("OnEvent", BuffLib.OnEvent)
BuffLib:RegisterEvent("PLAYER_ENTERING_WORLD")
BuffLib:RegisterEvent("PLAYER_LOGIN")

function BuffLib:InitDR(destGUID, spellID, event)
	if type(self.guids[destGUID]) ~= "table" then
		self.guids[destGUID] = { }
	end
	local drCat = DRLib:GetSpellCategory(spellID)
	if drCat then
		local tracked = self.guids[destGUID][drCat]
		--first AURA_APPLIED - initialize DR
		if not self.guids[destGUID][drCat] then
			self.guids[destGUID][drCat] = { reset = 99999999, diminished = 1.0, lastDR = 0 }
		--another AURA_APPLIED - reset DR if run out of time
		elseif tracked and tracked.reset <= GetTime() then -- reset DR because timer ran out
			tracked.diminished = 1.0
			tracked.reset = 99999999
			tracked.lastDR = 0
			log(DR_RESET_TIME.." seconds DR timer ran out, resetting "..drCat)
		elseif event == "SPELL_AURA_REMOVED" then
			tracked.reset = GetTime() + DR_RESET_TIME
			tracked.lastDR = 0
			log("start "..DR_RESET_TIME.." seconds DR timer "..GetSpellInfo(spellID))
		end	
	end
	
end

function BuffLib:NextDR(destGUID, spellID, event)
	local tracked
	local drCat
	if self.guids[destGUID] then
		drCat = DRLib:GetSpellCategory(spellID)
		tracked = self.guids[destGUID][drCat]
	end
	if tracked and tracked.lastDR+0.5 <= GetTime() then
		tracked.diminished = DRLib:NextDR(tracked.diminished)
		tracked.lastDR = GetTime()
		log("next DR: "..GetSpellInfo(spellID).. "  "..drCat)
	end
end

function BuffLib:CreateFrames(destGUID, spellName, spellID)
	-- don't create any more frames than necessary to avoid memory overload
	if self.guids[destGUID] and self.guids[destGUID][spellName] then
		self:UpdateFrames(destGUID, spellName, spellID)
	else
		local diminished = 1.0
		local tracked
		if( self.guids[destGUID] ) then
			local drCat = DRLib:GetSpellCategory(spellID)
			tracked = self.guids[destGUID][drCat]
			if (tracked) then
				diminished = tracked.diminished
				--log(spellName.."  "..self.abilities[spellName]*diminished)
			end
		end
		if type(self.guids[destGUID]) ~= "table" then
			self.guids[destGUID] = { }
		end
		
		--self.guids[destGUID][spellName] = CreateFrame("Frame", spellName .. "_" .. destGUID)
		self.guids[destGUID][spellName] = {}
		-- create information other addons can read using getglobal(spellName_GUIDTarget)
		self.guids[destGUID][spellName].startTime = GetTime()
		self.guids[destGUID][spellName].endTime = self.abilities[spellName]*diminished
		
		--log(spellName.."  "..self.abilities[spellName]*diminished.." CreateFrames")
	end
end

function BuffLib:UpdateFrames(destGUID, spellName, spellID)
	if self.guids[destGUID] and self.guids[destGUID][spellName] and self.abilities[spellName] then
		local diminished = 1.0
		local tracked
		if( self.guids[destGUID] ) then
			local drCat = DRLib:GetSpellCategory(spellID)
			tracked = self.guids[destGUID][drCat]
			if (tracked) then
				diminished = tracked.diminished
				--log(spellName.."  "..self.abilities[spellName]*diminished)
			end
		end	
		-- update "library"
		self.guids[destGUID][spellName].startTime = GetTime()
		self.guids[destGUID][spellName].endTime = self.abilities[spellName]*diminished
		
		--log(spellName.."  "..self.abilities[spellName]*diminished.." UpdateFrames")
	end
end

function BuffLib:HideFrames(destGUID, spellName, spellID)
	if self.guids[destGUID] and self.guids[destGUID][spellName] and self.abilities[spellName] then
		-- combatLog
		self.guids[destGUID][spellName].startTime = 0
		self.guids[destGUID][spellName].endTime = 0
		-- sync
		self.guids[destGUID][spellName].timeLeft = 0
		self.guids[destGUID][spellName].getTime = 0
	end
end

function BuffLib:PLAYER_LOGIN(...)
	self:CreateOptions()
end

function BuffLib:PLAYER_ENTERING_WORLD(...)
	-- clear frames, just to be sure
	if type(self.guids) == "table" then
		for k,v in pairs(self.guids) do
			for ke,va in pairs(self.abilities) do
				local frame = getglobal(ke.."_"..k)
				if frame then
					frame = nil
				end
			end
			self.guids[k]=nil
		end
	end
	
	self.guids = {}
	self.abilities = {}
	for k,v in pairs(BuffLibabilityIDs) do
		self.abilities[GetSpellInfo(k)]=v;
	end
	
	DRLib = LibStub("DRData-1.0")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("CHAT_MSG_ADDON")
	if BuffLibDB.sync == true then
		self:RegisterEvent("UNIT_AURA")
	end
	
end

--[[
	first: initialize DR with 1.0 (full duration), if timestamp older than 15 seconds, reset to 1.0
	next: AFTER calculating spell duration, divide DR by 2 (0.5, 0.25, ...) IF a CC is applied
	next: on REMOVE, set a timestamp as "DR timer"
--]]
function BuffLib:COMBAT_LOG_EVENT_UNFILTERED(...)
	local timestamp, eventType, sourceGUID,sourceName,sourceFlags,destGUID,destName,destFlags,spellID,spellName,spellSchool,auraType = select ( 1 , ... );
	
	-- DR can be applied by all spells, therefore outside of self.abilities[name]
	if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" or eventType == "SPELL_AURA_REMOVED" or (eventType == "SPELL_CAST_SUCCESS" and spellSchool == "0x1") then
		self:InitDR(destGUID, spellID, eventType)
	end
	
	if self.abilities[spellName] and (eventType == "SPELL_AURA_APPLIED") then -- check if spell just used is in list
		-- filter multiple incorrect combatlog events || don't want to trigger spell timer twice if SUCCESS+REFRESH or SUCCESS+APPLIED
		if self.guids[destGUID] and self.guids[destGUID][spellName] and self.guids[destGUID][spellName].lastTime and self.guids[destGUID][spellName].lastTime+logDelay <= GetTime() then
			self:CreateFrames(destGUID, spellName, spellID)
		elseif not self.guids[destGUID] or not self.guids[destGUID][spellName] or not self.guids[destGUID][spellName].lastTime then
			self:CreateFrames(destGUID, spellName, spellID)
		end
	-- have to also take CAST_SUCCESS because it's the only way to get refreshed spells like MS, Harmstring etc	
	elseif self.abilities[spellName] and (eventType == "SPELL_AURA_REFRESH" or eventType == "SPELL_AURA_APPLIED_DOSE" or eventType == "SPELL_CAST_SUCCESS") then	
		if self.guids[destGUID] and self.guids[destGUID][spellName] and self.guids[destGUID][spellName].lastTime and self.guids[destGUID][spellName].lastTime+logDelay <= GetTime() then
			self:CreateFrames(destGUID, spellName, spellID)
		elseif not self.guids[destGUID] or not self.guids[destGUID][spellName] or not self.guids[destGUID][spellName].lastTime then
			self:CreateFrames(destGUID, spellName, spellID)
		end
	elseif self.abilities[spellName] and removeEvents[eventType] then
		self:HideFrames(destGUID, spellName, spellID)
	end
	
	-- some spells do not have AURA_REFRESH because they are physical, CAST_SUCCESS works though
	-- could technically catch even more by just using CAST_SUCCESS without spellSchool
	if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" or (eventType == "SPELL_CAST_SUCCESS" and spellSchool == "0x1") then
		self:NextDR(destGUID, spellID, eventType)
	end
	
	
	-- hack for Wound Poison
	if spellName == GetSpellInfo(13220) and eventType == "SPELL_DAMAGE" then
		self:CreateFrames(destGUID, spellName, spellID)
	end
	
	-- call UNIT_AURA on any units where the player COULD see buff/debuff durations
	-- UNIT_AURA does not fire automatically when a spell is refreshed :(
	-- the self:UNIT_AURA() sends sync messages
	if eventType == "SPELL_AURA_REFRESH" and BuffLibDB.sync == true then
		if destGUID == UnitGUID("player") then
			self:UNIT_AURA("player")
		end	
	end

	--[[
		timer of last update on this spell, this is to ensure that multiple combatlog events will not overwrite the current timer
		for example CAST_SUCCESS and AURA_APPLIED fire at the SAME time (or virtually same time)
		only do this for spells which can actually DR - anything else doesn't matter
	--]]
	if self.abilities[spellName] and DRLib:GetSpellCategory(spellID) then
		if self.guids[destGUID] and self.guids[destGUID][spellName] and eventType ~= "SPELL_AURA_REMOVE" then
			self.guids[destGUID][spellName].lastTime = GetTime() 
			--log("setting lastTime")
		end
	end
	
end

function BuffLib:CHAT_MSG_ADDON(prefix, message, channel, sender)
	if prefix == "BuffLib" and sender ~= UnitName("player") then
		local guid, name, duration, timeLeft = strsplit(",", message)
		--local EBFrame = getglobal(name.."_"..guid)
		local EBFrame
		if self.guids[guid] then
			EBFrame = self.guids[guid][name]
		end
		if EBFrame ~= nil then
			EBFrame.timeLeft = tonumber(timeLeft)
			EBFrame.duration = tonumber(duration)
			EBFrame.getTime = GetTime()
			--[[delete combatlog data
			EBFrame.startTime = nil
			EBFrame.endTime = nil]]
		else
			--self.guids[guid][name] = CreateFrame("Frame", name.."_"..guid, UIParent)
			if not self.guids[guid] then return end
			self.guids[guid][name] = {}
			self.guids[guid][name].timeLeft = tonumber(timeLeft)
			self.guids[guid][name].duration = tonumber(duration)
			self.guids[guid][name].getTime = GetTime()
		end
		
		--instant buff/debuff timer update for default UnitFrames
		if TargetFrame:IsVisible() and guid == UnitGUID("target") then
			TargetDebuffButton_Update()
		end
		
		if FocusFrame and FocusFrame:IsVisible() and guid == UnitGUID("focus") then
			FocusDebuffButton_Update()
		end
		
		-- code below can only be used if these functions are made global
		--[[if XPerl_Target and XPerl_Target:IsVisible() and guid == UnitGUID("target") then
			XPerl_Targets_BuffUpdate(getglobal("XPerl_Target"))
			XPerl_Target_DebuffUpdate(getglobal("XPerl_Target"))
		end
		if XPerl_Focus and XPerl_Focus:IsVisible() and guid == UnitGUID("focus") then
			XPerl_Targets_BuffUpdate(getglobal("XPerl_Focus"))
			XPerl_Target_DebuffUpdate(getglobal("XPerl_Focus"))
		end
		for i=1,GetNumPartyMembers() do
			if guid == UnitGUID("party"..i) and XPerl_Target then
				XPerl_Party_Buff_UpdateAll(getglobal("XPerl_party"..i))
			end
		end]]
	end
end

function BuffLib:UNIT_AURA(unitID, eventType)
	if unitID == "player" or unitID == "target" or unitID == "focus" then
		for i=1, 40 do
			local name, rank, icon, count, duration, timeLeft = _UnitBuff(unitID, i, castable)		
			if timeLeft ~= nil then -- can see timer, perfect
				self:SendSync(UnitGUID(unitID)..","..name..","..duration..","..timeLeft)
			end

			local name, rank, icon, count, debuffType, duration, timeLeft = _UnitDebuff(unitID, i, castable)
			if timeLeft ~= nil then
				self:SendSync(UnitGUID(unitID)..","..name..","..duration..","..timeLeft)
			end	
		end
	end	
end

function BuffLib:SendSync(message)
	local inInstance, instanceType = IsInInstance()
	if instanceType == "pvp" then
		SendAddonMessage("BuffLib", message, "BATTLEGROUND")
	elseif instanceType == "raid" then
		SendAddonMessage("BuffLib", message, "RAID")
	elseif instanceType == "arena" or instanceType == "party" then
		SendAddonMessage("BuffLib", message, "PARTY")
	elseif instanceType == "none" then
		if UnitGUID("party1") then
			SendAddonMessage("BuffLib", message, "PARTY")
		elseif UnitGUID("raid1") then
			SendAddonMessage("BuffLib", message, "RAID")
		end
	end
	
end

local SO = LibStub("LibSimpleOptions-1.0")
function BuffLib:CreateOptions()
	local panel = SO.AddOptionsPanel("BuffLib", function() end)
	self.panel = panel
	SO.AddSlashCommand("BuffLib","/bufflib")
	SO.AddSlashCommand("BuffLib","/bl")
	local title, subText = panel:MakeTitleTextAndSubText("Buff Library Addon", "General settings")
	local sync = panel:MakeToggle(
	     'name', 'Synchronize timers',
	     'description', 'Turns off synchronizing timers with your teammates. Could prevent lags.',
	     'default', false,
	     'getFunc', function() return BuffLibDB.sync end,
	     'setFunc', function(value) BuffLibDB.sync = value BuffLib:PLAYER_ENTERING_WORLD() end)
	     
	sync:SetPoint("TOPLEFT",subText,"TOPLEFT",16,-32)
end	

-------- HOOKING FUNCTIONS -------

-- endTime is equal to duration
-- startTime is GetTime() when the spell was found in CombatLog
-- endTime-(GetTime()-startTime) is therefore timeLeft

function UnitBuff(unitID, index, castable)
	local name, rank, icon, count, duration, timeLeft, isMine = _UnitBuff(unitID, index, castable)
	if not name then return name, rank, icon, count, duration, timeLeft, isMine end
	--local EBFrame = getglobal(name.."_"..UnitGUID(unitID))
	local EBFrame
	if BuffLib.guids and BuffLib.guids[UnitGUID(unitID)] then
		EBFrame = BuffLib.guids[UnitGUID(unitID)][name]
	end
	
	-- if duration can be seen by the player (provided by the server) return original duration and end function here
	if timeLeft ~= nil or duration ~=nil then -- can see timer, perfect
		if unitID ~= "player" then
			isMine = true
		else
			isMine = false
		end
		return name, rank, icon, count, duration, timeLeft, isMine
	end	
	
	if timeLeft == nil and EBFrame ~=nil and EBFrame.timeLeft ~= nil and EBFrame.timeLeft-(GetTime()-EBFrame.getTime) > 0 then -- can't see timer but someone in party/raid/bg can
		--log(name.. " reading from snyc")
		duration = EBFrame.duration
		timeLeft = EBFrame.timeLeft-(GetTime()-EBFrame.getTime)
		isMine = false
	elseif timeLeft == nil and EBFrame ~=nil and EBFrame.timeLeft == nil then -- have to load timer from combatlog :(
		--log(name.. " reading from combatlog")
		duration = EBFrame.endTime
		timeLeft = EBFrame.endTime-(GetTime()-EBFrame.startTime)
		isMine = false		
	end

	if timeLeft and timeLeft <= 0 then
		timeLeft = nil
		duration = nil
		--log(name.." resetting timeLeft "..unitID)
	end	
	return name, rank, icon, count, duration, timeLeft, isMine
end

function UnitDebuff(unitID, index, castable)
	local name, rank, icon, count, debuffType, duration, timeLeft, isMine = _UnitDebuff(unitID, index, castable)
	if not name then return name, rank, icon, count, debuffType, duration, timeLeft, isMine end
	--local EBFrame = getglobal(name.."_"..UnitGUID(unitID))
	local EBFrame
	if BuffLib.guids and BuffLib.guids[UnitGUID(unitID)] then
		EBFrame = BuffLib.guids[UnitGUID(unitID)][name]
	end
	
	
	if timeLeft ~= nil or duration ~= nil then
		if unitID ~= "player" then
			isMine = true
		else
			isMine = false
		end
		return name, rank, icon, count, debuffType, duration, timeLeft, isMine
	end	
	
	if timeLeft == nil and EBFrame ~=nil and EBFrame.timeLeft ~= nil and EBFrame.timeLeft-(GetTime()-EBFrame.getTime) > 0 then
		--log(name.. " reading from snyc")
		duration = EBFrame.duration
		timeLeft = EBFrame.timeLeft-(GetTime()-EBFrame.getTime)
		isMine = false
	elseif timeLeft == nil and EBFrame ~=nil and EBFrame.timeLeft == nil then
		--log(name.. " reading from combatlog")
		duration = EBFrame.endTime
		timeLeft = EBFrame.endTime-(GetTime()-EBFrame.startTime)
		isMine = false
	end
	
	if timeLeft and timeLeft <= 0 then
		timeLeft = nil
		duration = nil
		--log(name.." resetting timeLeft "..unitID)
	end	
	
	return name, rank, icon, count, debuffType, duration, timeLeft, isMine
end