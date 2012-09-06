local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

function frame:OnEvent(event, arg1)
	if event == "ADDON_LOADED" and arg1 == "RandomMount" then
		if RandomMountsDB == nil then
			RandomMountsDB = {
				fly = {},
				swim = {},
				normal = {}
			}
		end
	end
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
		print("Usage:")
		print("/"..slash.." option")
		print("Options:")
		print(" - mount: Mount or dismount")
		print(" - add type mountSpellID: add a mount (type=F,S,N for fly,swim,normal)")
	else
		local args = split(msg, " ")
		if table.getn(args) < 1 then
			return
		end
				
		if args[1] == "mount" then
			RandomMount:mountOrDismount()
		elseif args[1] == "add" then
			if args[2] == nil or args[3] == nil then
				UIErrorsFrame:AddMessage("Missing mountType and/or mountSpellID", 1.0, 0.0, 0.0, 53, 5)
				return
			end
			RandomMount:addMount(args[2], args[3])
		end
	end
end

function RandomMount:addMount(type, id)
	localType = ""
	if type == "F" then localType = "fly"
	elseif type == "S" then localType = "swim"
	else localType = "normal" end
	table.insert(RandomMountsDB[localType], id)
end

function RandomMount:mountOrDismount()
	if IsMounted() then
		if IsFlying() then
			UIErrorsFrame:AddMessage("Mounted and Flying", 1.0, 0.0, 0.0, 53, 5)
		else
			Dismount()
		end
	else
		
		if IsIndoors() == 1 then 
			-- we are indoor, let's check if we have a journey form
			
		else
			local mounts = nil
			if IsSwimming() then
				mounts = RandomMountsDB["swim"]
			end
				
			if IsFlyableArea() and (mounts == nil or table.getn(mounts) == 0) then
				mounts = RandomMountsDB["fly"]
			end
		
			if mounts == nil or table.getn(mounts) == 0 then
				mounts = RandomMountsDB["normal"]
			end
		
			if table.getn(mounts) == 0 then
				UIErrorsFrame:AddMessage("No mounts saved", 1.0, 0.0, 0.0, 53, 5)
			else
				local spellID
				while true do
					spellID = mounts[random(#mounts)]
					if IsUsableSpell(tonumber(spellID)) then
						break;
					end
				end
				
				for i = 1, GetNumCompanions("MOUNT") do
					creatureID, creatureName, creatureSpellID, _, _ = GetCompanionInfo("MOUNT", i)
					--print("searching "..spellID.." -> "..creatureSpellID.." "..creatureName)
		
					if creatureSpellID == tonumber(spellID) then
						CallCompanion("MOUNT", i)
						break
					end	
				end
			end
		end
	end
end