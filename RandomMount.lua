local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

function frame:OnEvent(event, arg1)
	if event == "ADDON_LOADED" and arg1 == "RandomMount" then
		if RandomMountsDB == nil then
			RandomMountsDB = {
				fly = {},
				swim = {},
				normal = {},
				pets = {}
			}
		end
		
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_COLLECTED, true)
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_NOT_COLLECTED, false)
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_FAVORITES, false)
		C_PetJournal.AddAllPetTypesFilter()
		C_PetJournal.AddAllPetSourcesFilter()
		C_PetJournal.ClearSearchFilter()
	end
end

local function defaultFunc(L, key)
	return key
end
local L = setmetatable({}, {__index=defaultFunc})
if (GetLocale() == "frFR") then
	L["Usage:"] = "Utilisation"
	L["/%s option"] = "/%s options"
	L["Options:"] = "Options"
	L[" - mount: Mount or dismount"] = " - mount: Monte ou descend"
	L[" - pet: Invoke or dismiss your pet"] = " - pet: Invoque ou renvoie un compagnon"
	L[" - list: List your saved mounts and pets"] = " - list: Liste vos montures et compagnons enregistrées"
	L[" - add type spellID: add a mount/pet (type=F,S,N,P for fly,swim,normal,pet)"] = " - add type sortID: ajoute une monture/un compagnon (type=F,S,N,P pour volante,nage,normale,compagnon)"
	L[" - del type spellID: remove a mount/pet from the specified type"] = " - del type sortID: supprime une monture/un compagnon pour le type spécifié"
	L["   - %s (spellID: %s)"] = "   - %s (sortID: %s)"
	L["|cffff0000Invalid type : %s|r"] = "|cffff0000Type invalide : %s|r"
	L["Valid types are : F (fly), S (swim), N (normal) and P (pet)"] = "Les types valides sont F (volante), S (nage), N (normale) et P (compagnon)"
	L["%s already added to %s %s"] = "%s est déjà ajoutée aux %s %s"
	L["%s added to %s %s"] = "%s a été ajoutée aux %s %s"
	L["%s removed from %s %s"] = "%s a été supprimée des %s %s"
	L["%s was not in %s %s"] = "%s ne se trouve pas dans les %s %s"
	L["Invoking %s"] = "Invocation de %s"
	L["Missing type and/or spellID"] = "type et/ou sortID manquant"
	L["On a flying mount !"] = "Sur une monture volante !"
	L["No mounts saved"] = "Aucune monture sauvegardée"
	L["No pets saved"] = "Aucun compagnon sauvegardé"
	L["You don't own mount ID : %s"] = "Vous ne possédez pas la monture : %s"
	L["You don't own pet ID : %s"] = "Vous ne possédez pas le compagnon : %s"
	L["fly"] = "volante"
	L["swim"] = "nage"
	L["normal"] = "normale"
	L["pets"] = "compagnons"
	L["mounts"] = "montures"
else
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
		print(L[" - list: List your saved mounts and pets"])
		print(L[" - add type spellID: add a mount/pet (type=F,S,N,P for fly,swim,normal,pet)"])
		print(L[" - del type spellID: remove a mount/pet from the specified type"])
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
		elseif args[1] == "save" then
			RandomMount:savePetList()
		elseif args[1] == "list" then
			RandomMount:listMounts()
		elseif args[1] == "add" then
			if args[2] == nil or args[3] == nil then
				UIErrorsFrame:AddMessage(L["Missing type and/or spellID"], 1.0, 0.0, 0.0, 53, 5)
				return
			end
			RandomMount:addMount(args[2], tonumber(args[3]))
		elseif args[1] == "del" then
			if args[2] == nil or args[3] == nil then
				UIErrorsFrame:AddMessage(L["Missing type and/or spellID"], 1.0, 0.0, 0.0, 53, 5)
				return
			end
			RandomMount:delMount(args[2], tonumber(args[3]))
		end
	end
end

function RandomMount:savePetList()
	RandomMountsDB["debug"] = {}
	
	--[[
	local _, o = C_PetJournal.GetNumPets(false)
	for i = 1, o do
		index, _, _, _, _, _, _, name, _, _, id = C_PetJournal.GetPetInfoByIndex(i, false)
		table.insert(RandomMountsDB["debug"], name)
	end	
	]]--
end

function RandomMount:getMountName(type, spellID)
	if type == "pets" then
		local _, o = C_PetJournal.GetNumPets(false)
	
		for i = 1, o do
			index, _, _, _, _, _, _, name, _, _, id = C_PetJournal.GetPetInfoByIndex(i, false)
			--print(id, name, spellID)
			if id == spellID then
				--print(name, index, id)
				return name, index
			end
		end		
	else
		for i = 1, GetNumCompanions("MOUNT") do
			creatureID, name, creatureSpellID, _, _ = GetCompanionInfo("MOUNT", i)
			--print(name)
		
			if creatureSpellID == spellID then
				return name, i
			end	
		end
	end
	
	return nil, nil
end

function RandomMount:clear()
	RandomMountsDB = {
		fly = {},
		swim = {},
		normal = {},
		pets = {}
	}
end

function RandomMount:listMounts()
	for type, mounts in pairs(RandomMountsDB) do
		print(string.format("|cffffff00- %s|r", L[type]))
		for m, id in pairs(mounts) do
			spellID = id
			if type == "pets" then
				spellID = id[1]
			end
			--print(id, type, spellID)
			name, _ = self:getMountName(type, spellID)
			if name ~= nil then
				print(string.format(L["   - %s (spellID: %s)"], name, spellID))
			end
		end
	end
end

function RandomMount:addMount(type, id)
	localType = ""
	if type == "F" then localType = "fly"
	elseif type == "S" then localType = "swim"
	elseif type == "N" then localType = "normal" 
	elseif type == "P" then localType = "pets"
	else
		print(string.format(L["|cffff0000Invalid type : %s|r"], L[type]))
		print(L["Valid types are : F (fly), S (swim), N (normal) and P (pet)"])
		return
	end
	
	name, index = self:getMountName(localType, id)
	-- check if we own the mount
	if nil == name then
		if localType == "pets" then
			print(string.format(L["You don't own pet ID : %s"], id))
		else
			print(string.format(L["You don't own mount ID : %s"], id))
		end
		return
	end
	
	companion = "mounts"
	if localType == "pets" then
		companion = "pets"
	end
	
	if RandomMountsDB[localType] == nil then
		RandomMountsDB[localType] = {}
	end
	
	-- check if mount no yet added
	for i, v in ipairs(RandomMountsDB[localType]) 
	do
		if v == id then
			print(string.format(L["%s already added to %s %s"], name, L[companion], L[localType]))
			return
		end
	end
	
	-- add the mount
	print(string.format(L["%s added to %s %s"], name, L[companion], L[localType]))
	
	if localType == "pets" then
		table.insert(RandomMountsDB[localType], { id, index })
	else
		table.insert(RandomMountsDB[localType], id)
	end
end

function RandomMount:delMount(type, id)
	localType = ""
	if type == "F" then localType = "fly"
	elseif type == "S" then localType = "swim"
	elseif type == "N" then localType = "normal"  
	elseif type == "P" then localType = "pets"
	else
		print(string.format(L["|cffff0000Invalid type : %s|r"], L[type]))
		print(L["Valid types are : F (fly), S (swim), N (normal) and P (pet)"])		
		return
	end
	
	name, index = self:getMountName(localType, id)
	-- check if we own the mount
	if nil == name then
		print(string.format(L["You don't own mount ID : %s"], id))
		return
	end	
	
	if RandomMountsDB[localType] == nil then
		RandomMountsDB[localType] = {}
	end
	
	companion = "mounts"
	if localType == "pets" then
		companion = "pets"
	end
	
	for i, v in ipairs(RandomMountsDB[localType]) 
	do
		spellID = v
		if localType == "pets" then
			spellID = v[1]
		end
		
		if spellID == id then
			print(string.format(L["%s removed from %s %s"], name, L[companion], L[localType]))
			table.remove(RandomMountsDB[localType], i)
			return
		end
	end
	
	companion = "mounts"
	if localType == "pets" then
		companion = "pets"
	end
	print(string.format(L["%s was not in %s %s"], name, L[companion], L[localType]))
end

function RandomMount:invokePet()
	if IsMounted() and IsFlying() then
		UIErrorsFrame:AddMessage(L["On a flying mount !"], 1.0, 0.0, 0.0, 53, 5)
	else
		local pets = RandomMountsDB["pets"]
		
		if table.getn(pets) == 0 then
			UIErrorsFrame:AddMessage(L["No pets saved"], 1.0, 0.0, 0.0, 53, 5)
		else
			local spell = pets[random(#pets)]
			name, _ = self:getMountName("pets", spell[1])
			print(string.format(L["Invoking %s"], name))
			C_PetJournal.SummonPetByID(spell[2])
		end
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
		
		if IsIndoors() == 1 then 
			-- we are indoor, let's check if we have a journey form
			
		else
			local mounts = nil
			if IsSwimming() and "Vashj'ir" == GetRealZoneText() then
				mounts = RandomMountsDB["swim"]
			end
			
			if IsFlyableArea() and (mounts == nil or table.getn(mounts) == 0) and self:canFly() then
				mounts = RandomMountsDB["fly"]
			end
		
			if mounts == nil or table.getn(mounts) == 0 then
				mounts = RandomMountsDB["normal"]
			end
		
			if table.getn(mounts) == 0 then
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
				
				name, index = self:getMountName(localType, spellID)
				if index ~= nil then
					print(string.format(L["Invoking %s"], name))
					CallCompanion("MOUNT", index)
				end
			end
		end
	end
end