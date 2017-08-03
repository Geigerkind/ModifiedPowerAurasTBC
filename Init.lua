CreateFrame("Frame", "MPOWA", UIParent)
MPOWA.Build = 61
MPOWA.Cloaded = false
MPOWA.loaded = false
MPOWA.selected = 1
MPOWA.CurEdit = 1
MPOWA.Page = 1 

MPOWA.frames = {}
MPOWA.auras = {}
MPOWA.groupByNames = {}
MPOWA.groupByUnit = {}
MPOWA.NumBuffs = 0
MPOWA.NeedUpdate = {}
MPOWA.RaidGroupMembers = {}
MPOWA.testall = false

MPOWA.active = {}
MPOWA.mounted = false
MPOWA.party = false
MPOWA.bg = false
MPOWA.instance = false

MPOWA.SOUND = {
	[0] = "None",
	[1] = "LEVELUP",
	[2] = "LOOTWINDOWCOINMPOWA:SOUND",
	[3] = "MapPing",
	[4] = "HumanExploration",
	[5] = "QUESTADDED",
	[6] = "QUESTCOMPLETED",
	[7] = "WriteQuest",
	[8] = "Fishing Reel in",
	[9] = "igPVPUpdate",
	[10] = "ReadyCheck",
	[11] = "RaidWarning",
	[12] = "AuctionWindowOpen",
	[13] = "AuctionWindowClose",
	[14] = "TellMessage",
	[15] = "igBackPackOpen",
	[16] = "aggro.ogg",
	[17] = "bam.ogg",
	[18] = "cat2.ogg",
	[19] = "cookie.ogg",
	[20] = "moan.ogg",
	[21] = "phone.ogg",
	[22] = "shot.ogg",
	[23] = "sonar.ogg",
	[24] = "splash.ogg",
	[25] = "wilhelm.ogg",
	[26] = "huh_1.ogg",
	[27] = "bear_polar.ogg",
	[28] = "bigkiss.ogg",
	[29] = "BITE.ogg",
	[30] = "PUNCH.ogg",
	[31] = "burp4.ogg",
	[32] = "chimes.ogg",
	[33] = "Gasp.ogg",
	[34] = "hic3.ogg",
	[35] = "hurricane.ogg",
	[35] = "hyena.ogg",
	[36] = "Squeakypig.ogg",
	[37] = "panther1.ogg",
	[38] = "rainroof.ogg",
	[39] = "snakeatt.ogg",
	[40] = "sneeze.ogg",
	[41] = "thunder.ogg",
	[42] = "wickedmalelaugh1.ogg",
	[43] = "wlaugh.ogg",
	[44] = "wolf5.ogg",
	[45] = "swordecho.ogg",	
	[46] = "throwknife.ogg",
	[47] = "yeehaw.ogg",
	[48] = "Fireball.ogg", 
	[49] = "rocket.ogg", 
	[50] = "Arrow_Swoosh.ogg", 
	[51] = "ESPARK1.ogg", 
	[52] = "chant4.ogg", 
	[53] = "chant2.ogg", 
	[54] = "shipswhistle.ogg", 
	[55] = "kaching.ogg", 
	[56] = "heartbeat.ogg",
	[57] = "Hit1.ogg", -- Thanks to Sillywet!
	[58] = "Hit2.ogg", -- Thanks to Sillywet!
	[59] = "Hit3.ogg", -- Thanks to Sillywet!
	[60] = "Hit4.ogg", -- Thanks to Sillywet!
	[61] = "Hit5.ogg", -- Thanks to Sillywet!
	[62] = "Hit6.ogg", -- Thanks to Sillywet!
	[63] = "Hit7.ogg", -- Thanks to Sillywet!
	[64] = "Hit8.ogg", -- Thanks to Sillywet!
}

local function copy(t, inner)
  if type(t) ~= "table" then
    error("table expected, got "..type(t), 2)
  end
  local new = {}
  if inner then
    for i,s in next,t do
      if type(s) == "table" then
        new[i] = copy(s, true)
      else
        new[i] = s
      end
    end
  else
    for i,s in next,t do
      new[i] = s
    end
  end
  return new
end
table.copy = copy

MPOWA.SAVE = table.copy(MPOWA_SAVE or {}, true)

function MPOWA:OnEvent(event, arg1)
	if self.loaded then
		if event == "UNIT_AURA" then
			if arg1 == "target" or self.groupByUnit[arg1] then
				self:Iterate(arg1)
			end
		elseif event == "PLAYER_TARGET_CHANGED" then
			for c, v in pairs(self.auras) do
				if v then
					for cat, val in pairs(v) do
						if self.active[val] or self.frames[val][1]:IsVisible() then
							local p = self.SAVE[val]
							if p["enemytarget"] or p["friendlytarget"] then
								self.active[val] = false
								self:FHide(val)
								self.frames[val][3]:Hide()
								self.frames[val][1]:SetAlpha(p["alpha"])
							end
						end
					end
				end
			end
			self:Iterate("target")
		elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
			self:GetGroup()
		else
			self:Iterate("player")
		end
	elseif event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" then
		if arg1 then
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
	elseif event == "PLAYER_LOGOUT" then
		MPOWA_SAVE = table.copy(self.SAVE, true)
	else
		self:Init()
		self.loaded = true
	end
end