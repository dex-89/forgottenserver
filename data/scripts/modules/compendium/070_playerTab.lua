function sendCompendiumPlayerInfo(playerId, creatureId, infoType, entriesPerPage, page)
	-- to do: implement permission logic for inspecting other creatures
	local player = Player(playerId)
	if not player then
		return
	end
	
	if playerId ~= creatureId then
		sendCompendiumError(player, infoType, COMPENDIUM_RESPONSETYPE_ACCESSDENIED)
		return
	end

	local creature = Creature(creatureId)
	if not creature or creature:isRemoved() then
		sendCompendiumError(player, infoType, COMPENDIUM_RESPONSETYPE_NODATA)
		return
	end

	local isPlayer = creature:isPlayer()
	local creatureType = "unknown"
	if isPlayer then
		if creature:getGroup():getAccess() then
			creatureType = creature:getGroup():getName()
		else
			creatureType = creature:getVocation():getName()
		end
	elseif creature:isMonster() then
		creatureType = "monster"
	elseif creature:isNpc() then
		creatureType = "Non-Player Character"
	end
	
	local response = NetworkMessage()
	response:addByte(COMPENDIUM_RESPONSE_PLAYERDATA)
	response:addByte(infoType)
	response:addByte(COMPENDIUM_RESPONSETYPE_OK)
		
	if infoType == COMPENDIUM_PLAYER_BASEINFORMATION then
		response:addString(creature:getName())
		response:addString(creatureType:gsub("^%l", string.upper))
		response:addU16(isPlayer and creature:getLevel() or 1)
		response:addOutfit(creature:getOutfit(), false)
		response:addByte(0x00) -- hide stamina (hidden if 0x01)
		response:addByte(0x01) -- enable store summary and character titles
		response:addString("") -- character title
		response:sendToPlayer(player)
		return
	elseif infoType == COMPENDIUM_PLAYER_GENERAL then
		if not isPlayer then
			sendCompendiumError(player, infoType, COMPENDIUM_RESPONSETYPE_NODATA)
			return
		end
		
		local currentLevel = creature:getLevel()
		local currentLevelXP = Game.getExperienceForLevel(currentLevel)
		local currentXP = creature:getExperience()
		local goalXP = Game.getExperienceForLevel(currentLevel + 1) - currentLevelXP
		local progress = (currentXP - currentLevelXP) * 100 / goalXP
		response:addU64(creature:getExperience())
		response:addU16(creature:getLevel())
		response:addByte(progress)
	
		response:addU16(100) -- base XP rate
		response:addU32(0) -- tournament XP factor
		response:addU16(0) -- low level bonus
		response:addU16(0) -- XP boost
		response:addU16(100) -- stamina boost
		response:addU16(0) -- XP boost remaining time
		response:addByte(0) -- can buy XP boost

		local HP = creature:getHealth()
		local maxHP = creature:getMaxHealth()
		
		if maxHP > 65535 then
			HP = math.floor(HP * 100 / maxHP)
			maxHP = 100
		end

		response:addU16(math.min(HP, maxHP))
		response:addU16(maxHP)

		local MP = creature:getMana() or 0
		local maxMP = creature:getMaxMana() or 0
		
		if maxMP > 65535 then
			MP = math.floor(MP * 100 / maxMP)
			maxMP = 100
		end

		response:addU16(math.min(MP, maxMP))
		response:addU16(maxMP)

		response:addByte(creature:getSoul())
		response:addU16(creature:getStamina())
		
		local condition = creature:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)
		response:addU16(condition and condition:getTicks() / 1000 or 0)
		response:addU16(creature:getOfflineTrainingTime() / 60 / 1000)
		response:addU16(math.min(0xFFFF, creature:getSpeed() / 2))
		response:addU16(math.min(0xFFFF, creature:getBaseSpeed() / 2))
		response:addU32(creature:getCapacity())
		response:addU32(creature:getCapacity())
		response:addU32(creature:getFreeCapacity())

		-- skill amount
		response:addByte(8)
		-- u8: skill compendium id
		-- u16: bonus, base, loyalty, percent
		
		local baseML = creature:getBaseMagicLevel()
		local voc = creature:getVocation()
		local manaCost = voc:getRequiredManaSpent(baseML + 1) - voc:getRequiredManaSpent(baseML)		
		local manaSpent = creature:getManaSpent()
		local progress = manaSpent * 10000 / manaCost
		
		response:addByte(COMPENDIUM_SKILL_MAGIC)
		response:addU16(creature:getMagicLevel())
		response:addU16(baseML)
		response:addU16(baseML)
		response:addU16(progress)
		
		for skillId = SKILL_FIST, SKILL_FISHING do
			local baseSkill = creature:getSkillLevel(skillId)
		
			response:addByte(compendiumSkillMap[skillId])
			response:addU16(creature:getEffectiveSkillLevel(skillId))
			response:addU16(baseSkill)
			response:addU16(baseSkill) -- loyalty bonus
			response:addU16(creature:getSkillPercent(skillId)*100)
		end

		-- element magic level boosts
		response:addByte(0) -- elements count
		-- element structure:
		-- u8 element type
		-- u16 bonus magic levels
		
		response:sendToPlayer(player)
		return
	elseif infoType == COMPENDIUM_PLAYER_COMBAT then
		for skillId = SPECIALSKILL_CRITICALHITCHANCE, SPECIALSKILL_MANALEECHAMOUNT do
			response:addU16(isPlayer and creature:getSpecialSkill(skillId) or 0)
			response:addU16(0)
		end

		-- fatal, dodge, momentum
		for i = 1, 3 do
			response:addU16(0)
			response:addU16(0)		
		end
		
		response:addU16(0) -- cleave (bonus percent damage to nearby enemies)
		response:addU16(0) -- bonus magic shield capacity (flat)
		response:addU16(0) -- bonus magic shield capacity (percent)

		-- perfect shot flat damage bonus at 1-5 range
		for i = 1, 5 do
			response:addU16(0)
		end

		response:addU16(0) -- damage reflection (flat, one value for all combat types)
		response:addByte(0) -- blesssings used
		response:addByte(8) -- blessings count

		-- weapon
		response:addU16(0) -- base max damage
		response:addByte(CLIENT_COMBAT_PHYSICAL) -- base element type
		response:addByte(0) -- percent damage conversion
		response:addByte(CLIENT_COMBAT_PHYSICAL) -- conversion element type

		response:addU16(0) -- armor
		response:addU16(0) -- defense

		-- element resistances count
		response:addByte(0)
		-- structure:
		-- u8 clientcombat
		-- u8 value
		
		-- active potions count
		response:addByte(0)
		-- structure:
		-- item clientId
		-- u16 duration
		
		response:sendToPlayer(player)
		return
	elseif infoType == COMPENDIUM_PLAYER_DEATHS then
		if not isPlayer then
			sendCompendiumError(player, infoType, COMPENDIUM_RESPONSETYPE_NODATA)
			return
		end
		
		local deathList = getDeathList(creature:getGuid())
		local pageCount = math.max(1, math.ceil(#deathList / entriesPerPage))
		if page > pageCount then
			sendCompendiumError(player, infoType, COMPENDIUM_RESPONSETYPE_NODATA)
			return
		end
		
		local responseCount = page < pageCount and entriesPerPage or #deathList - (page-1) * entriesPerPage
		
		response:addU16(page)
		response:addU16(pageCount)
		response:addU16(responseCount)
		for i = (page-1) * entriesPerPage + 1, math.min(page * entriesPerPage, #deathList) do
			response:addU32(deathList[i].at)
			response:addString(deathList[i].msg)
		end
		
		response:sendToPlayer(player)
		return
	elseif infoType == COMPENDIUM_PLAYER_PVPKILLS then
		if not isPlayer then
			sendCompendiumError(player, infoType, COMPENDIUM_RESPONSETYPE_NODATA)
			return
		end
		
		local fragList = getFragList(creature:getGuid())
		local pageCount = math.max(1, math.ceil(#fragList / entriesPerPage))
		if page > pageCount then
			sendCompendiumError(player, infoType, COMPENDIUM_RESPONSETYPE_NODATA)
			return
		end
		
		-- begin extra info
		local extraInfoCount = 2 -- unjustified count + separator
		local fragStatus = getFragStatus(creature)
		
		if fragStatus.duration > 0 then
			extraInfoCount = extraInfoCount + 1
		end
		if fragStatus.totalDuration > 0 then
			extraInfoCount = extraInfoCount + 1
		end
		
		local pzLockDuration = 0
		if creature:isPzLocked() then
			pzLockDuration = math.floor(creature:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT):getTicks() / 1000)
			extraInfoCount = extraInfoCount + 1
		end
		entriesPerPage = entriesPerPage - extraInfoCount
		-- end extra info
		
		local responseCount = page < pageCount and entriesPerPage or #fragList - (page-1) * entriesPerPage
		response:addU16(page)
		response:addU16(pageCount)
		response:addU16(responseCount + extraInfoCount) -- add extra info

		-- begin extra info (again)
		local ost = os.time()
		
		-- unjustified kills
		response:addU32(ost)
		response:addString(string.format("You have %d active unjustified kill%s.", fragStatus.unjustified, (fragStatus.unjustified == 1 and "" or "s")))
		response:addByte(COMPENDIUM_KILLTYPE_ARENA)
		
		-- single frag duration
		if fragStatus.duration > 0 then
			response:addU32(ost)
			response:addString(string.format("Next kill expires in: %s", Game.getCountdownString(fragStatus.duration)))
			response:addByte(COMPENDIUM_KILLTYPE_ARENA)
		end
	
		-- total frag duration
		if fragStatus.totalDuration > 0 then
			response:addU32(ost)
			response:addString(string.format("All kills expire in: %s", Game.getCountdownString(fragStatus.totalDuration)))
			response:addByte(COMPENDIUM_KILLTYPE_ARENA)
		end
		
		if pzLockDuration > 0 then
			response:addU32(ost)
			response:addString(string.format("PZ lock expires in: %s", Game.getCountdownString(pzLockDuration)))
			response:addByte(COMPENDIUM_KILLTYPE_ARENA)
		end
		
		response:addU32(ost)
		response:addString("----------------")
		response:addByte(COMPENDIUM_KILLTYPE_ARENA)
		-- end extra info (again)

		-- display kills on page
		for i = (page-1) * entriesPerPage + 1, math.min(page * entriesPerPage, #fragList) do
			response:addU32(fragList[i].at)
			response:addString(fragList[i].victim)
			response:addByte(fragList[i].killType)
		end
		
		response:sendToPlayer(player)
		return
	elseif infoType == COMPENDIUM_PLAYER_ACHIEVEMENTS then
		local achievements = {
			--{id = 2, extended = false, unlockedAt = os.time()},
			--{id = 3, extended = true, grade = 9, title = "Crashed!", description = "After sleepless night and countless client crashes you got what you wanted. No client tab is safe from you!"}
		}

		response:addU16(0) -- achievement points
		response:addU16(0) -- secret achievements amount
		
		response:addU16(#achievements) -- achievements count
		for i = 1, #achievements do
			local extended = achievements[i].extended
			
			response:addU16(achievements[i].id) -- achievement id (will show hardcoded values if byte after timestamp is disabled)
			response:addU32(achievements[i].unlockedAt or 0) -- unlock timestamp
			response:addByte(extended and 1 or 0)

			if extended then
				response:addString(achievements[i].title)
				response:addString(achievements[i].description) -- achievement description
				response:addByte(achievements[i].grade) -- achievement grade (1-?)
			end
		end
		response:sendToPlayer(player)
		return
	elseif infoType == COMPENDIUM_PLAYER_INVENTORY then
		-- to do: show loot if inspecting monster?
		-- shoplist if npc?
		if not isPlayer then
			sendCompendiumError(player, infoType, COMPENDIUM_RESPONSETYPE_NODATA)
			return
		end
		
		-- send each category
		for location = LOCATION_FIRST, LOCATION_LAST do
			local categoryItems, categoryCount = creature:getItemsByLocation(location)
			response:addU16(categoryCount) -- items to send
			for itemInfo, count in pairs(categoryItems) do
				local itemId, tier = unhashItemInfo(itemInfo)
				local itemType = ItemType(itemId)
				response:addU16(itemType:getClientId()) -- item clientId
				if itemType:getClassification() > 0 then
					response:addByte(tier) -- item tier
				end
				response:addU32(count) -- item amount
			end
		end
		
		response:sendToPlayer(player)
		return
	elseif infoType == COMPENDIUM_PLAYER_COSMETICS then
		-- This tab shows player unlocked outfits.
		-- Displaying premium only cosmetics for free accounts
		-- is intentional and 100% accurate.
		
		if not isPlayer then
			sendCompendiumError(player, infoType, COMPENDIUM_RESPONSETYPE_NODATA)
			return
		end
		
		-- get current outfit
		local currentOutfit = creature:getOutfit()
		
		-- add outfits
		local playerSex = creature:getSex()
		local displayOutfits = {}
		if #COMPENDIUM_CACHE.outfitLookTypes[playerSex] > 0 then
			if creature:getGroup():getAccess() then
				-- GM outfit not included because it causes issues when clicking on mounts
				for cacheIndex = 1, #COMPENDIUM_CACHE.outfitLookTypes[playerSex] do
					displayOutfits[#displayOutfits + 1] = {COMPENDIUM_CACHE.outfitLookTypes[playerSex][cacheIndex], 3}
				end
			else
				for cacheIndex = 1, #COMPENDIUM_CACHE.outfitLookTypes[playerSex] do
					local lookType = COMPENDIUM_CACHE.outfitLookTypes[playerSex][cacheIndex]
					if creature:hasOutfit(lookType, 0) then
						local outfitData = {lookType, 0}
						for i = 1, 2 do
							if creature:hasOutfit(lookType, 1) then
								outfitData[2] = outfitData[2] + i
							end
						end
						
						displayOutfits[#displayOutfits + 1] = outfitData
					end
				end
			end
			
			response:addU16(#displayOutfits)
			if #displayOutfits > 0 then
				for i = 1, #displayOutfits do
					local outfit = Outfit(displayOutfits[i][1])
					-- lookType, name, addons, isStore/isQuest
					response:addU16(displayOutfits[i][1])
					if outfit then
						response:addString(outfit.name)
						response:addByte(displayOutfits[i][2])
						response:addByte(outfit.unlocked == 1 and OUTFIT_TYPE_NORMAL or OUTFIT_TYPE_QUEST)
					else
						response:addString("")
						response:addByte(displayOutfits[i][2])
						response:addByte(OUTFIT_TYPE_NORMAL)
					end

					response:addU32(0) -- store offer id?
				end
				
				response:addByte(currentOutfit.lookHead)
				response:addByte(currentOutfit.lookBody)
				response:addByte(currentOutfit.lookLegs)
				response:addByte(currentOutfit.lookFeet)
			end
		else
			response:addU16(0)
		end

		-- add mounts
		if #COMPENDIUM_CACHE.mountLookTypes > 0 then
			local displayMounts = {}
			for i = 1, #COMPENDIUM_CACHE.mountLookTypes do
				if creature:hasMount(COMPENDIUM_CACHE.mountLookTypeToId[COMPENDIUM_CACHE.mountLookTypes[i]]) then
					displayMounts[#displayMounts + 1] = COMPENDIUM_CACHE.mountLookTypes[i]
				end
			end

			response:addU16(#displayMounts)
			if #displayMounts > 0 then
				for i = 1, #displayMounts do
					response:addU16(displayMounts[i])
					response:addString("")
					response:addByte(OUTFIT_TYPE_NORMAL)
					response:addU32(0) -- store offer id?
				end
				
				response:addByte(currentOutfit.lookMountHead)
				response:addByte(currentOutfit.lookMountBody)
				response:addByte(currentOutfit.lookMountLegs)
				response:addByte(currentOutfit.lookMountFeet)
			end
		else
			response:addU16(0)
		end

		-- add familiars (placeholder)
		response:addU16(0)
		-- same structure as mounts
		-- colors not included at the end of familiars block
		
		response:sendToPlayer(player)
		return
	elseif infoType == COMPENDIUM_PLAYER_STORE then
		return
	elseif infoType == COMPENDIUM_PLAYER_INSPECTION then
		-- this tab shows player eq, outfit and short character summary
		local playerEQ = {}
		local eqCount = 0
		for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
			local slotItem = creature:getSlotItem(slot)
			if slotItem then
				playerEQ[slot] = slotItem
				eqCount = eqCount + 1
			end
		end
		
		response:addByte(eqCount)		
		for slot, slotItem in pairs(playerEQ) do
			response:addByte(slot)
			response:addString(slotItem:getName())
			response:addItem(slotItem)
			
			-- imbuing slots
			response:addByte(0)
			
			-- use inspection module if loaded
			if getItemDetails then
				local descriptions = getItemDetails(slotItem)
				if descriptions and #descriptions > 0 then
					response:addByte(#descriptions)
					for i = 1, #descriptions do
						response:addString(descriptions[i][1])
						response:addString(descriptions[i][2])
					end
				else
					response:addByte(0)
				end
			else
				response:addByte(0)
			end

		end
		
		response:addString(creature:getName())
		
		local playerOutfit = creature:getOutfit()
		response:addOutfit(playerOutfit, false)
		
		local outfitType = Outfit(playerOutfit.lookType)
		local outfitName = outfitType and outfitType.name or "other"
		local playerInfo = {
			{"Level", creature:getLevel()},
			{"Vocation", creature:getVocation():getName()},
			{"Outfit", outfitName},
			-- title
			-- active preys
		}
		
		response:addByte(#playerInfo)
		for infoId = 1, #playerInfo do
			response:addString(playerInfo[infoId][1])
			response:addString(playerInfo[infoId][2])
		end
		
		response:sendToPlayer(player)
		return
	elseif infoType == COMPENDIUM_PLAYER_BADGES then
		return
	elseif infoType == COMPENDIUM_PLAYER_TITLES then
		return
	end

	sendCompendiumError(player, infoType, COMPENDIUM_RESPONSETYPE_NODATA)
end

function onRequestPlayerData(player, recvbyte, networkMessage)
	local targetPlayerId = networkMessage:getU32()
	if targetPlayerId == 0 then
		targetPlayerId = player:getId()
	end
	
	local infoType = networkMessage:getByte()
	local entriesPerPage = 5
	local currentPage = 1
	if (infoType == COMPENDIUM_PLAYER_DEATHS or infoType == COMPENDIUM_PLAYER_PVPKILLS) then
		entriesPerPage = math.min(30, math.max(5, networkMessage:getU16()))
		currentPage = math.max(1, networkMessage:getU16());
	end
	
	player:addDispatcherTask(sendCompendiumPlayerInfo, infoType + 1, player:getId(), targetPlayerId, infoType, entriesPerPage, currentPage)
	return true
end

local callback = onRequestPlayerData
setPacketEvent(COMPENDIUM_REQUEST_PLAYERDATA, callback)