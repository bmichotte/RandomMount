local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

function frame:OnEvent(event, arg1)
	if event == "ADDON_LOADED" and arg1 == "RandomMount" then
		if RandomMountsDB == nil then
			RandomMountsDB = {
				mounts = {},
				db_version = 51000
			}
		end
		
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_COLLECTED, true)
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_NOT_COLLECTED, false)
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_FAVORITES, false)
		C_PetJournal.AddAllPetTypesFilter()
		C_PetJournal.AddAllPetSourcesFilter()
		C_PetJournal.ClearSearchFilter()
		
		frame:initPetBattleFrame()
	end
end

local L = setmetatable(GetLocale() == "frFR" and {
	["Usage:"] = "Utilisation",
	["/%s option"] = "/%s options",
	["Options:"] = "Options",
	[" - mount: Mount or dismount"] = " - mount: Monte ou descend",
	[" - pet: Invoke or dismiss your pet"] = " - pet: Invoque ou renvoie un compagnon",
	["Invoking %s"] = "Invocation de %s",
	["On a flying mount !"] = "Sur une monture volante !",
	["No mounts saved"] = "Aucune monture sauvegardée",
	["No pets saved"] = "Aucun compagnon sauvegardé",
	["Add or remove this mount for favorites"] = "Ajoute ou supprime cette monture des favoris",
	["Favorite mount"] = "Monture favorite"
} or {}, {__index=function(t,i) return i end})


function frame:initPetBattleFrame()
	local checkbox = CreateFrame("CheckButton", "randomMount_FavoriteMount", MountJournal.MountDisplay, "ChatConfigCheckButtonTemplate")
	checkbox:SetPoint("TOPLEFT", 10, -10)
	checkbox.tooltip = L["Add or remove this mount for favorites"]
	_G[checkbox:GetName() .. "Text"]:SetText(L["Favorite mount"]);
	checkbox:SetScript("OnClick", function()
		for i = 1, #MountJournal.ListScrollFrame.buttons do
			local b = _G["MountJournalListScrollFrameButton"..i]
			if b.selectedTexture:IsShown() then
				local spellID = b.spellID
				--local _, creatureName, spellID, _, _ = GetCompanionInfo("MOUNT", i)
				
				if checkbox:GetChecked() then
					found = false
					for i,v in pairs(RandomMountsDB['mounts']) do
						if v == spellID then
							found = true
						end
					end
					if not found then
						table.insert(RandomMountsDB['mounts'], spellID)
					end
				else
					for i,v in pairs(RandomMountsDB['mounts']) do
						print(i.." "..v)
						if v == spellID then
							table.remove(RandomMountsDB['mounts'], i)
						end
					end
				end
			end
		end
	end)
	local function setSelectedCheckbox()
		for i = 1, #MountJournal.ListScrollFrame.buttons do
			local b = _G["MountJournalListScrollFrameButton"..i]
			if b.selectedTexture:IsShown() then
				local spellID = b.spellID
				found = false
				for i,v in pairs(RandomMountsDB['mounts']) do
					if v == spellID then
						found = true
					end
				end
				randomMount_FavoriteMount:SetChecked(found)
			end
		end
	end  
	hooksecurefunc("MountJournal_UpdateMountList", setSelectedCheckbox)
	MountJournalListScrollFrame:HookScript("OnVerticalScroll", setSelectedCheckbox)
	MountJournalListScrollFrame:HookScript("OnMouseWheel", setSelectedCheckbox)
end
frame:SetScript("OnEvent", frame.OnEvent)

local _G = _G
local slash = "rm"
local name = "RANDOMMONT_"..slash:upper()

local RandomMount = {}

local function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

_G["SLASH_"..name.."1"] = "/"..slash
SlashCmdList[name] = function(msg, editbox)
	if msg == "" then
		print("|cffffff00RandomMount|r")
		print(L["Usage:"])
		print(string.format(L["/%s option"], slash))
		print(L["Options:"])
		print(L[" - mount: Mount or dismount"])
		print(L[" - pet: Invoke or dismiss your pet"])
	else
		local args = split(msg, " ")
		if table.getn(args) < 1 then
			return
		end
				
		if args[1] == "mount" then
			RandomMount:mountOrDismount()
		elseif args[1] == "pet" then
			RandomMount:invokePet()
		elseif args[1] == "clear" then
			RandomMount:clear()
		elseif args[1] == "test" then
			RandomMount:test()
		end
	end
end

function RandomMount:test()

end

function RandomMount:clear()
	RandomMountsDB = {
		mounts = {},
		db_version = 51000
	}
end

function RandomMount:invokePet()
	if IsMounted() and IsFlying() then
		UIErrorsFrame:AddMessage(L["On a flying mount !"], 1.0, 0.0, 0.0, 53, 5)
	else
		_, numOwned = C_PetJournal.GetNumPets(false)
		summonedPetGUID = C_PetJournal.GetSummonedPetGUID()
		local pets = {}
		for i = 1, numOwned do
			petID, _, _, customName, _, favorite, _, speciesName, _, _, _, _, _, _, _, _, _ = C_PetJournal.GetPetInfoByIndex(i, false)
			if summonedPetGUID ~= nil and summonedPetGUID ~= petID then	
				if favorite then
					table.insert(pets, { petID, customName or speciesName })
				end
			end
		end
		local pet = pets[random(#pets)]
		print(string.format(L["Invoking %s"], pet[2]))
		C_PetJournal.SummonPetByGUID(pet[1])
	end
end

function RandomMount:canFly()
	if UnitLevel("player") < 60 then
		return false
	end
	
	if IsSpellKnown(90267) then
		return true
	end
	
	--[[
	0 - Azeroth
	1 - Kalimdor
	2 - Eastern Kingdoms
	3 - Outland
	4 - Northrend
	5 - The Maelstrom
	]]--
	
	continent = GetCurrentMapContinent()
	if IsSpellKnown(34090) and continent == 3 then
		return true
	end
	if IsSpellKnown(54197) and continent == 4 then
		return true
	end
	
	return false
end

function RandomMount:mountOrDismount()
	if IsMounted() then
		if IsFlying() then
			UIErrorsFrame:AddMessage(L["On a flying mount !"], 1.0, 0.0, 0.0, 53, 5)
		else
			Dismount()
		end
	else
		local mounts = {}
		if IsSwimming() then
			if "Vashj'ir" == GetRealZoneText() then
				if IsUsableSpell(75207) then
					table.insert(mounts, 75207)
				end
			end
			local aquatics = { 98718, 64731 }
			for _, v in pairs(aquatics) do
				if IsUsableSpell(v) then
					table.insert(mounts, v)
				end
			end			
		elseif IsFlyableArea() and self:canFly() then
			for i = 1, #RandomMountsDB['mounts'] do
				spellID = RandomMountsDB['mounts'][i]
				for i = 1, GetNumCompanions("MOUNT") do
					creatureID, creatureName, creatureSpellID, icon, issummoned, mountType = GetCompanionInfo("MOUNT", i)
					if creatureSpellID == spellID then
						if bit.band(mountType, 0x2) == 0x2 then
							table.insert(mounts, spellID)
						end
						
					end	
				end
			end
		else
			for i = 1, #RandomMountsDB['mounts'] do
				spellID = RandomMountsDB['mounts'][i]
				for i = 1, GetNumCompanions("MOUNT") do
					creatureID, creatureName, creatureSpellID, icon, issummoned, mountType = GetCompanionInfo("MOUNT", i)
					if creatureSpellID == spellID then
						if bit.band(mountType, 0x1) == 0x1 then
							table.insert(mounts, spellID)
						end
					end	
				end
			end			
		end
		
		if #mounts == 0 then
			UIErrorsFrame:AddMessage(L["No mounts saved"], 1.0, 0.0, 0.0, 53, 5)
		else
			local spellID
			local max = #mounts
			local count = 0
				
			while true do
				spellID = mounts[random(#mounts)]
				if IsUsableSpell(spellID) then
					break;
				end
				if max == count then
					break;
				end
				count = count + 1
			end
				
			name, index = self:getMountName(spellID)
			if index ~= nil then
				print(string.format(L["Invoking %s"], name))
				CallCompanion("MOUNT", index)
			end
		end
		
	end
end

function RandomMount:getMountName(spellID)
	for i = 1, GetNumCompanions("MOUNT") do
		creatureID, name, creatureSpellID, _, _ = GetCompanionInfo("MOUNT", i)
		if creatureSpellID == spellID then
			return name, i
		end	
	end
	
	return nil, nil
end