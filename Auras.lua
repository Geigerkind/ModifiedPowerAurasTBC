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
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitAffectingCombat = UnitAffectingCombat
local UnitInRaid = UnitInRaid
local UnitBuff = UnitBuff 
local UnitDebuff = UnitDebuff
local UnitMana = UnitMana
local strsub = strsub
local strlower = strlower
local GetComboPoints = GetComboPoints
local GetSpellCooldown = GetSpellCooldown
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetContainerItemCooldown = GetContainerItemCooldown
local GetContainerItemLink = GetContainerItemLink
local GetInventoryItemLink = GetInventoryItemLink
local GetContainerNumSlots = GetContainerNumSlots
local GetSpellName = GetSpellName
local UnitIsFriend = UnitIsFriend

local UpdateTime, LastUpdate = 0.05, 0
local cdset = {}

function MPOWA:OnUpdate(elapsed)
	LastUpdate = LastUpdate + elapsed
	if LastUpdate >= UpdateTime then
		local p1, p2
		for cat, val in pairs(self.NeedUpdate) do
			if val then
				local path = self.SAVE[cat]
				if path["enemytarget"] and not UN("target") and not UnitIsFriend("player", "target") then return end
				p1, p2 = self:TernaryReturn(cat, "inparty", self:InParty()), self:TernaryReturn(cat, "inraid", UnitInRaid("player"))
				if not self.active[cat] and self:TernaryReturn(cat, "alive", self:Reverse(UnitIsDeadOrGhost("player"))) 
				and self:TernaryReturn(cat, "mounted", self.mounted) and self:TernaryReturn(cat, "incombat", UnitAffectingCombat("player")) 
				and (((p1 or p2) and ((path["inparty"]==0 or path["inparty"]==true) and (path["inraid"]==0 or path["inraid"]==true))) or (p1 and p2))
				and self:TernaryReturn(cat, "inbattleground", self.bg) and self:TernaryReturn(cat, "inraidinstance", self.instance) then
					self.frames[cat][4]:Hide()
					if path["cooldown"] then
						local duration = self:GetCooldown(path["buffname"]) or 0
						if path["cdclockanimout"] and duration<=path["animduration"]+0.4 and duration>=path["animduration"] and (not cdset[cat] or cdset[cat]+0.5<GT()) then
							cdset[cat] = GT()
							self.frames[cat][5]:SetCooldown(GT(), path["animduration"])
						end
						if path["timer"] then
							if duration > 0 then
								self.frames[cat][3]:SetText(self:FormatDuration(duration, path))
								if path["inverse"] then
									self:FHide(cat)
									self.frames[cat][3]:Hide()
								else
									if path["secsleft"] then
										if duration<=path["secsleftdur"] then
											self:FShow(cat)
											self.frames[cat][3]:Show()
										else
											self:FHide(cat)
											self.frames[cat][3]:Hide()
										end
									else
										self:FShow(cat)
										self.frames[cat][3]:Show()
									end
								end
							else
								if path["inverse"] then
									self:FShow(cat)
								else
									self:FHide(cat)
								end
								self.frames[cat][3]:Hide()
							end
						else
							if path["inverse"] then
								if duration > 0 then
									self:FHide(cat)
								else
									self:FShow(cat)
								end
							else
								if path["secsleft"] then
									if duration<=path["secsleftdur"] then
										self:FShow(cat)
									else
										self:FHide(cat)
									end
								else
									if duration > 0 then
										self:FShow(cat)
									else
										self:FHide(cat)
									end
								end
							end
						end
					else
						self:FShow(cat)
					end
				else
					if path["inverse"] or path["cooldown"] then
						self:FHide(cat)
					end
				end
			end
		end
		for cat, val in pairs(self.active) do
			if val then
				local path = self.SAVE[cat]
				local text, count, timeLeft = "", 0, 0, 0
				if val[3] then
					_, _, text, count, _, _, timeLeft  =  UnitDebuff(val[1], val[2]);
				else
					_, _, text, count, _, timeLeft = UnitBuff(val[1], val[2]);
				end
				self:SetTexture(cat, text)
				if self:IsStacks(count or 0, cat, "stacks") then
					if (count or 0)>1 and not path["hidestacks"] then
						self.frames[cat][4]:SetText(count)
						self.frames[cat][4]:Show()
					else
						self.frames[cat][4]:Hide()
					end
					-- Duration
					timeLeft = timeLeft or 0
					if path["cdclockanimout"] and timeLeft<=path["animduration"]+0.4 and timeLeft>=path["animduration"] and (not cdset[cat] or cdset[cat]+0.5<GT()) then
						cdset[cat] = GT()
						self.frames[cat][5]:SetCooldown(GT(), path["animduration"])
					end
					if path["timer"] then
						if timeLeft > 0 then
							self.frames[cat][3]:SetText(self:FormatDuration(timeLeft, path))
						else
							self.frames[cat][3]:Hide()
						end
					end
					self:Flash(elapsed, cat, timeLeft)
					if (path["inverse"] and path["buffname"] ~= "unitpower") then
						self:FHide(cat)
					else
						if path["secsleft"] then
							if timeLeft<=path["secsleftdur"] then
								self:FShow(cat)
							else
								self:FHide(cat)
							end
						else
							self:FShow(cat)
						end
					end
				else
					self:FHide(cat)
				end
			else
				if not self.NeedUpdate[cat] then
					self:FHide(cat)
				end
			end
		end
		LastUpdate = 0
	end
end

function MPOWA:SetTexture(key, texture)
	local p = self.SAVE[key]
	if texture and p["texture"] == "Interface\\AddOns\\zzzModifiedPowerAuras\\images\\dummy.tga" then
		p["texture"] = texture
		self.frames[key][2]:SetTexture(texture)
	end
end

function MPOWA:FormatDuration(duration, path)
	if path["minutes"] and duration >60 then
		return ceil(duration/60).."m"
	elseif path["hundredth"] then
		return strform("%.2f", duration)
	end
	return flr(duration)
end

function MPOWA:GetCooldown(buff)
	-- Get Spellcooldown
	local start, duration, enabled = GetSpellCooldown(self:GetSpellSlot(buff), "spell")
	-- Get Inventory Cooldown
	if start == 0 and duration == 0 then
		for i=1, 22 do
			start, duration, enable = GetInventoryItemCooldown("player", i)
			local _,_,name = strfind(GetInventoryItemLink("player",i) or "","^.*%[(.*)%].*$")
			if (name) then
				if strfind(strlower(buff), strlower(name)) then
					if duration>2 then
						return ((start or 0)+(duration or 0))-GT()
					else
						return 0
					end
				elseif i == 22 and start == 0 and duration == 0 then
					-- Get Container Item Cooldown
					for p=0, 4 do
						for u=1, GetContainerNumSlots(p) do
							start, duration, enable = GetContainerItemCooldown(p,u)
							_,_,name=strfind(GetContainerItemLink(p,u) or "","^.*%[(.*)%].*$")
							if (not name) then break end
							if strfind(strlower(buff), strlower(name)) then
								if duration>2 then
									return ((start or 0)+(duration or 0))-GT()
								else
									return 0
								end
							elseif p == 4 and u == GetContainerNumSlots(p) then
								if duration>2 then
									return ((start or 0)+(duration or 0))-GT()
								else
									return 0
								end
							else
								return 0
							end
						end
					end
				end
			end
		end
	else
		if duration>2 then
			return ((start or 0)+(duration or 0))-GT()
		else
			return 0
		end
	end
end

function MPOWA:GetSpellSlot(buff)
	if not buff then 
		return 0 
	end
	local i = 1
	while true do
		local name, rank = GetSpellName(i, "spell")
		if (not name) or strfind(strlower(name), strlower(buff)) then 
			return i
		end
		if i > 1000 then
			return 0 -- Lets give up at this point
		end
		i = i + 1
	end
	return 0
end

local BuffExist = {}
function MPOWA:Iterate(unit)
	BuffExist = {}
	if unit=="player" then
		self:IsMounted()
		--self:InParty()
		self:InBG()
		self:InInstance()
	end
	
	for cat, val in pairs(self.SAVE) do
		if (val["buffname"] == "unitpower") then
			local unit = arg1
			if (unit == "target") then 
				self:Push("unitpower", unit, 45, false)
			elseif (string.find(unit,"raid")) then
				local st = string.sub(unit, 5)
				if st and tonumber(st) then
					self:Push("unitpower", unit, (tonumber(st) or 0)+45, false)
				end
			elseif (string.find(unit,"party")) then
				local st = string.sub(unit, 6)
				if st and tonumber(st) then
					self:Push("unitpower", unit, (tonumber(st) or 0)+45, false)
				end
			end
		end
	end

	for i=1, 40 do
		local buff, debuff, castbyme
		buff,_,_,_,_,_,castbyme = UnitBuff(unit, i)
		self:Push(buff, unit, i, false, castbyme)
		if i<17 then
			debuff,_,_,_,_,_,_,castbyme = UnitDebuff(unit, i)
			self:Push(debuff, unit, i, true,castbyme)
		end
		if not buff and not debuff then break end
	end
	for cat, val in pairs(self.active) do
		if val then
			if not BuffExist[cat] then
				local p = self.SAVE[cat]
				if ((p["friendlytarget"] or p["enemytarget"]) and unit=="target") or (not p["raidgroupmember"] and not p["friendlytarget"] and not p["enemytarget"] and unit=="player") or p["raidgroupmember"] then
					self.active[cat] = false
					self.frames[cat][3]:Hide()
					if not p["inverse"] and not p["cooldown"] then
						self.frames[cat][1]:SetAlpha(p["alpha"])
						self:FHide(cat)
					end
				end
			end
		end
	end
end

function MPOWA:Push(aura, unit, i, isdebuff, castbyme)
	if self.auras[aura] then
		for cat, val in pairs(self.auras[aura]) do
			local path = self.SAVE[val]
			local bypass = self.active[val]
			local tex = ""
			if path["secondspecifier"] then
				if path["isdebuff"] then
					_,_,tex = UnitDebuff(unit, i)
				else
					_,_,tex = UnitBuff(unit, i)
				end
				tex = strlower(strsub(tex, strfind(tex, "Icons")+6))
			end
			BuffExist[val] = true
			if (not path["castbyme"] or (path["castbyme"] and castbyme)) and path["isdebuff"]==isdebuff and ((path["secondspecifier"] and (strlower(path["secondspecifiertext"])==tex)) or not path["secondspecifier"]) then
				local p1, p2 = self:TernaryReturn(val, "inparty", self:InParty()), self:TernaryReturn(val, "inraid", UnitInRaid("player"))
				if self:TernaryReturn(val, "alive", self:Reverse(UnitIsDeadOrGhost("player"))) and self:TernaryReturn(val, "mounted", self.mounted) 
				and self:TernaryReturn(val, "incombat", UnitAffectingCombat("player")) 
				and (((p1 or p2) and ((path["inparty"]==0 or path["inparty"]==true) and (path["inraid"]==0 or path["inraid"]==true))) or (p1 and p2))
				and self:TernaryReturn(val, "inbattleground", self.bg) and self:TernaryReturn(val, "inraidinstance", self.instance) 
				and not path["cooldown"] and self:IsStacks(GetComboPoints("player", "target"), val, "cpstacks") then
					if path["enemytarget"] and unit == "target" then
						self.active[val] = {unit, i, isdebuff}
					elseif path["friendlytarget"] and unit == "target" then
						self.active[val] = {unit, i, isdebuff}
					elseif path["raidgroupmember"] then -- have to check those vars
						self.active[val] = {unit, i, isdebuff}
					elseif not path["enemytarget"] and not path["friendlytarget"] and not path["raidgroupmember"] and unit == "player" then
						self.active[val] = {unit, i, isdebuff}
					end
					if self.active[val] and not bypass then
						if tnbr(self.frames[val][1]:GetAlpha())<=0.1 then
							self.frames[val][1]:SetAlpha(tnbr(path["alpha"]))
						end
						self:FShow(val)
						if path["timer"] then
							self.frames[val][3]:Show()
						end
					end
				end
			end
		end
	end
end

function MPOWA:IsStacks(count, id, kind)
	if self.SAVE[id][kind] ~= "" then
		local con = strsub(self.SAVE[id][kind], 1, 2)
		local amount = tnbr(strsub(self.SAVE[id][kind], 3))
		if not con then
			con = strsub(self.SAVE[id][kind], 1, 1)
			amount = tnbr(strsub(self.SAVE[id][kind], 2))
		end

		if self.SAVE[id]["buffname"] == "unitpower" then
			count = UnitMana(self.SAVE[id]["unit"] or "player")
			if self.SAVE[id]["inverse"] then
				if (con == ">=") then
					con = "<"
				elseif (con == "<=") then
					con = ">"
				elseif con == ">" then
					con = "<="
				elseif (con == "<") then
					con = ">="
				elseif (con == "=") then
					con = "!"
				elseif (con == "!") then
					con = "="
				end	
			end
		end

		if amount ~= nil and con ~= nil then
			if con == ">=" and count >= amount then
				return true
			elseif con == "<=" and count <= amount then
				return true
			elseif con == "<" and count < amount then
				return true
			elseif con == ">" and count > amount then
				return true
			elseif con == "=" and count == amount then
				return true
			elseif con == "!" and count ~= amount then
				return true
			end
		end
		con = strfind(self.SAVE[id][kind], "-")
		if con then
			local amount1 = tnbr(strsub(self.SAVE[id][kind], 1, con-1))
			local amount2 = tnbr(strsub(self.SAVE[id][kind], con+1))
			if con and amount1 and amount2 and ((count >= amount1 and count <= amount2) or (count >= amount2 and count <= amount1)) then
				return true
			end
		else
			return false
		end
	end
	return false
end