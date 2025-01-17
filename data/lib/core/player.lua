do
	local foodCondition = Condition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)
	function Player:feed(food)
		local condition = self:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)
		if condition then
			condition:setTicks(condition:getTicks() + (food * 1000))
		else
			local vocation = self:getVocation()
			if not vocation then
				return nil
			end

			foodCondition:setTicks(food * 1000)
			foodCondition:setParameter(CONDITION_PARAM_HEALTHGAIN, vocation:getHealthGainAmount())
			foodCondition:setParameter(CONDITION_PARAM_HEALTHTICKS, vocation:getHealthGainTicks() * 1000)
			foodCondition:setParameter(CONDITION_PARAM_MANAGAIN, vocation:getManaGainAmount())
			foodCondition:setParameter(CONDITION_PARAM_MANATICKS, vocation:getManaGainTicks() * 1000)

			self:addCondition(foodCondition)
		end
		return true
	end
end

function Player:getClosestFreePosition(position, extended)
	if self:getGroup():getAccess() and self:getAccountType() >= ACCOUNT_TYPE_GOD then
		return position
	end
	return Creature.getClosestFreePosition(self, position, extended)
end

function Player:getDepotItems(depotId)
	return self:getDepotChest(depotId, true):getItemHoldingCount()
end

function Player:hasFlag(flag)
	return self:getGroup():hasFlag(flag)
end

function Player:getLossPercent()
	local blessings = 0
	local lossPercent = {
		[0] = 100,
		[1] = 70,
		[2] = 45,
		[3] = 25,
		[4] = 10,
		[5] = 0
	}

	for i = 1, 5 do
		if self:hasBlessing(i) then
			blessings = blessings + 1
		end
	end
	return lossPercent[blessings]
end

function Player:getTotalMoney()
	return self:getMoney() + self:getBankBalance()
end

function Player:getPremiumTime()
	return math.max(0, self:getPremiumEndsAt() - os.time())
end

function Player:setPremiumTime(seconds)
	self:setPremiumEndsAt(os.time() + seconds)
	return true
end

function Player:addPremiumTime(seconds)
	self:setPremiumTime(self:getPremiumTime() + seconds)
	return true
end

function Player:removePremiumTime(seconds)
	local currentTime = self:getPremiumTime()
	if currentTime < seconds then
		return false
	end

	self:setPremiumTime(currentTime - seconds)
	return true
end

function Player:getPremiumDays()
	return math.floor(self:getPremiumTime() / 86400)
end

function Player:addPremiumDays(days)
	return self:addPremiumTime(days * 86400)
end

function Player:removePremiumDays(days)
	return self:removePremiumTime(days * 86400)
end

function Player:isPremium()
	return self:getPremiumTime() > 0 or configManager.getBoolean(configKeys.FREE_PREMIUM) or self:hasFlag(PlayerFlag_IsAlwaysPremium)
end

function Player:sendCancelMessage(message)
	if type(message) == "number" then
		message = Game.getReturnMessage(message)
	end
	return self:sendTextMessage(MESSAGE_STATUS_SMALL, message)
end

function Player:isUsingOtClient()
	return self:getClient().os >= CLIENTOS_OTCLIENT_LINUX
end

function Player:sendExtendedOpcode(opcode, buffer)
	if not self:isUsingOtClient() then
		return false
	end

	local networkMessage = NetworkMessage()
	networkMessage:addByte(0x32)
	networkMessage:addByte(opcode)
	networkMessage:addString(buffer)
	networkMessage:sendToPlayer(self)
	networkMessage:delete()
	return true
end

do
	APPLY_SKILL_MULTIPLIER = true
	local addSkillTriesFunc = Player.addSkillTries
	function Player:addSkillTries(...)
		APPLY_SKILL_MULTIPLIER = false
		local ret = addSkillTriesFunc(...)
		APPLY_SKILL_MULTIPLIER = true
		return ret
	end
end

do
	local addManaSpentFunc = Player.addManaSpent
	function Player:addManaSpent(...)
		APPLY_SKILL_MULTIPLIER = false
		local ret = addManaSpentFunc(...)
		APPLY_SKILL_MULTIPLIER = true
		return ret
	end
end

-- Always pass the number through the isValidMoney function first before using the transferMoneyTo
function Player:transferMoneyTo(target, amount)
	if not target then
		return false
	end

	-- See if you can afford this transfer
	local balance = self:getBankBalance()
	if amount > balance then
		return false
	end

	-- See if player is online
	local targetPlayer = Player(target.guid)
	if targetPlayer then
		targetPlayer:setBankBalance(targetPlayer:getBankBalance() + amount)
	else
		db.query("UPDATE `players` SET `balance` = `balance` + " .. amount .. " WHERE `id` = '" .. target.guid .. "'")
	end

	self:setBankBalance(self:getBankBalance() - amount)
	return true
end

function Player:canCarryMoney(amount)
	-- Anyone can carry as much imaginary money as they desire
	if amount == 0 then
		return true
	end

	local totalWeight = 0
	local inventorySlots = 0
	local currencyItems = Game.getCurrencyItems()
	for index = #currencyItems, 1, -1 do
		local currency = currencyItems[index]
		-- Add currency coins to totalWeight and inventorySlots
		local worth = currency:getWorth()
		local currencyCoins = math.floor(amount / worth)
		if currencyCoins > 0 then
			amount = amount - (currencyCoins * worth)
			while currencyCoins > 0 do
				local count = math.min(100, currencyCoins)
				totalWeight = totalWeight + currency:getWeight(count)
				currencyCoins = currencyCoins - count
				inventorySlots = inventorySlots + 1
			end
		end
	end

	-- If player don't have enough capacity to carry this money
	if self:getFreeCapacity() < totalWeight then
		return false
	end

	-- If player don't have enough available inventory slots to carry this money
	local backpack = self:getSlotItem(CONST_SLOT_BACKPACK)
	if not backpack or backpack:getEmptySlots(true) < inventorySlots then
		return false
	end
	return true
end

function Player:withdrawMoney(amount)
	local balance = self:getBankBalance()
	if amount > balance or not self:addMoney(amount) then
		return false
	end

	self:setBankBalance(balance - amount)
	return true
end

function Player:depositMoney(amount)
	if not self:removeMoney(amount) then
		return false
	end

	self:setBankBalance(self:getBankBalance() + amount)
	return true
end

function Player:removeTotalMoney(amount)
	local moneyCount = self:getMoney()
	local bankCount = self:getBankBalance()
	if amount <= moneyCount then
		self:removeMoney(amount)
		return true
	elseif amount <= (moneyCount + bankCount) then
		if moneyCount ~= 0 then
			self:removeMoney(moneyCount)
			local remains = amount - moneyCount
			self:setBankBalance(bankCount - remains)
			self:sendTextMessage(MESSAGE_INFO_DESCR, ("Paid %d from inventory and %d gold from bank account. Your account balance is now %d gold."):format(moneyCount, amount - moneyCount, self:getBankBalance()))
			return true
		else
			self:setBankBalance(bankCount - amount)
			self:sendTextMessage(MESSAGE_INFO_DESCR, ("Paid %d gold from bank account. Your account balance is now %d gold."):format(amount, self:getBankBalance()))
			return true
		end
	end
	return false
end

function Player:addLevel(amount, round)
	round = round or false
	local level, amount = self:getLevel(), amount or 1
	if amount > 0 then
		return self:addExperience(Game.getExperienceForLevel(level + amount) - (round and self:getExperience() or Game.getExperienceForLevel(level)))
	else
		return self:removeExperience(((round and self:getExperience() or Game.getExperienceForLevel(level)) - Game.getExperienceForLevel(level + amount)))
	end
end

function Player:addMagicLevel(value)
	local currentMagLevel = self:getBaseMagicLevel()
	local sum = 0

	if value > 0 then
		while value > 0 do
			sum = sum + self:getVocation():getRequiredManaSpent(currentMagLevel + value)
			value = value - 1
		end

		return self:addManaSpent(sum - self:getManaSpent())
	else
		value = math.min(currentMagLevel, math.abs(value))
		while value > 0 do
			sum = sum + self:getVocation():getRequiredManaSpent(currentMagLevel - value + 1)
			value = value - 1
		end

		return self:removeManaSpent(sum + self:getManaSpent())
	end
end

function Player:addSkillLevel(skillId, value)
	local currentSkillLevel = self:getSkillLevel(skillId)
	local sum = 0

	if value > 0 then
		while value > 0 do
			sum = sum + self:getVocation():getRequiredSkillTries(skillId, currentSkillLevel + value)
			value = value - 1
		end

		return self:addSkillTries(skillId, sum - self:getSkillTries(skillId))
	else
		value = math.min(currentSkillLevel, math.abs(value))
		while value > 0 do
			sum = sum + self:getVocation():getRequiredSkillTries(skillId, currentSkillLevel - value + 1)
			value = value - 1
		end

		return self:removeSkillTries(skillId, sum + self:getSkillTries(skillId), true)
	end
end

function Player:addSkill(skillId, value, round)
	if skillId == SKILL_LEVEL then
		return self:addLevel(value, round or false)
	elseif skillId == SKILL_MAGLEVEL then
		return self:addMagicLevel(value)
	end
	return self:addSkillLevel(skillId, value)
end

function Player:getWeaponType()
	local weapon = self:getSlotItem(CONST_SLOT_LEFT)
	if weapon then
		return weapon:getType():getWeaponType()
	end
	return WEAPON_NONE
end

-- player's client take screenshot
-- can also be disabled in client settings
-- screenshot types are defined in constants.lua
do
	local screenshotConfig = {
		[SCREENSHOT_TYPE_ACHIEVEMENT] = true,
		[SCREENSHOT_TYPE_BESTIARYENTRYCOMPLETED] = true,
		[SCREENSHOT_TYPE_BESTIARYENTRYUNLOCKED] = true,
		[SCREENSHOT_TYPE_BOSSDEFEATED] = true,
		[SCREENSHOT_TYPE_DEATHPVE] = true,
		[SCREENSHOT_TYPE_DEATHPVP] = true,
		[SCREENSHOT_TYPE_LEVELUP] = true,
		[SCREENSHOT_TYPE_PLAYERKILLASSIST] = true,
		[SCREENSHOT_TYPE_PLAYERKILL] = true,
		[SCREENSHOT_TYPE_PLAYERATTACKING] = true,
		[SCREENSHOT_TYPE_TREASUREFOUND] = true,
		[SCREENSHOT_TYPE_SKILLUP] = true,
	}

	function Player:takeScreenshot(screenshotType, ignoreConfig)
		if not screenshotConfig[screenshotType] and not ignoreConfig then
			return false
		end
		
		if screenshotType and screenshotType >= SCREENSHOT_TYPE_FIRST and screenshotType < SCREENSHOT_TYPE_LAST then
			local m = NetworkMessage()
			m:addByte(0x75)
			m:addByte(screenshotType)
			m:sendToPlayer(self)
			return true
		end
		
		return false
	end
end

-- Send message colors to the player
function Player:sendMessageColorTypes()
    local msg = NetworkMessage()
    msg:addByte(0xCD)
    msg:addU16(MESSAGE_COLOR_LAST + 1)
    for color = MESSAGE_COLOR_FIRST, MESSAGE_COLOR_LAST do
        msg:addU16(color) -- made up client id for color
        msg:addU64(messageColorToValueMap[color]) -- price
    end
    
    msg:sendToPlayer(self)
end

function Player:sendColorMessage(message, color)
	self:sendTextMessage(MESSAGE_LOOT, string.format("{%d|%s}", color, message))
end

-- Unlock tiers at the market + send forge info to the player
do
	-- these are the defaults that will replace the forge system
	-- if nothing overrides it

	-- if you want to build your own system
	-- override the function from a module instead of editing it here

	-- the function is overridden from a module by default
	-- see forge module in data/scripts/modules
	
	-- defaults in case forge system is not initialized
	local maxClass = 4
	local maxTier = 10
	
	function Player:sendItemClasses()
		local msg = NetworkMessage()
		msg:addByte(0x86)
		msg:addByte(maxClass)
		if maxClass > 0 then
			for classId = 1, maxClass do
				msg:addByte(classId)
				
				msg:addByte(maxTier)
				if maxTier > 0 then
					for tierId = 0, maxTier-1 do
						msg:addByte(tierId)
						msg:addU64(0) -- fusion cost
					end
				end
			end
		end
		
		-- cost for each tier (?)
		for tierId = 0, maxTier do
			msg:addByte(0)
		end
		
		msg:sendToPlayer(self)
	end
end

-- aggregator for player tiered items info
do
	function unhashItemInfo(itemInfo)
		local tier = bit.rshift(itemInfo, 16)
		return itemInfo - tier * ITEMTIER_HASH, tier
	end

	local function parseItem(item, response, onlyMarketable)
		local responseIndex = item:getType():getId() + item:getTier() * ITEMTIER_HASH
		if not response[responseIndex] then
			response[responseIndex] = 0
		end
		
		if not onlyMarketable or item:isMarketable() then
			response[responseIndex] = response[responseIndex] + item:getCount()
		end
	end

	function Player:getItemsByLocation(location, onlyMarketable)
		local response = {}
		local responseCount = 0
		
		if location == LOCATION_BACKPACK then
			local bp = self:getSlotItem(CONST_SLOT_BACKPACK)
			if bp then
				for _, containerItem in pairs(bp:getItems(true)) do
					parseItem(containerItem, response, onlyMarketable)
				end
			end
		elseif location == LOCATION_EQUIPPED then
			for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
				local slotItem = self:getSlotItem(slot)
				if slotItem then
					parseItem(slotItem, response, onlyMarketable)
					
					if slotItem:isContainer() then
						for _, containerItem in pairs(slotItem:getItems(true)) do
							parseItem(containerItem, response, onlyMarketable)
						end
					end
				end
			end
		elseif location == LOCATION_PURSE then
			local purse = self:getSlotItem(CONST_SLOT_STORE_INBOX)
			if purse then
				for _, containerItem in pairs(purse:getItems(true)) do
					parseItem(containerItem, response, onlyMarketable)
				end
			end
		elseif location == LOCATION_STASH then
			-- not implemented yet
		elseif location == LOCATION_DEPOT then
			local towns = Game.getTowns()
			for _, town in pairs(towns) do
				local depotBox = self:getDepotChest(town:getId())
				if depotBox then
					for containerIndex, containerItem in pairs(depotBox:getItems(true)) do
						parseItem(containerItem, response, onlyMarketable)
					end
				end
			end
		elseif location == LOCATION_MAILBOX then
			local inbox = self:getInbox()
			if inbox then
				for containerIndex, containerItem in pairs(inbox:getItems(true)) do
					parseItem(containerItem, response, onlyMarketable)
				end
			end
		end
		
		for _ in pairs(response) do
			responseCount = responseCount + 1
		end
		
		return response, responseCount
	end
end

-- kill tracker
function Player.updateKillTracker(self, monster, corpse)
    local monsterType = monster:getType()
    if not monsterType then
        return false
    end

    local monsterOutfit = monsterType:getOutfit()

    local networkMessage = NetworkMessage()
    networkMessage:addByte(0xD1)
    networkMessage:addString(monster:getName())
    networkMessage:addU16(monsterOutfit.lookType or 19)
    networkMessage:addByte(monsterOutfit.lookHead)
    networkMessage:addByte(monsterOutfit.lookBody)
    networkMessage:addByte(monsterOutfit.lookLegs)
    networkMessage:addByte(monsterOutfit.lookFeet)
    networkMessage:addByte(monsterOutfit.lookAddons)
    networkMessage:addByte(corpse:getSize())

    for i = corpse:getSize() - 1, 0, -1 do
        local item = corpse:getItem(i)
        networkMessage:addItem(item)
    end

    if self:getParty() then
        networkMessage:sendToPlayer(self:getParty():getLeader())
        local membersList = self:getParty():getMembers()
        for i = 1, #membersList do
            local player = membersList[i]
            if player then
                networkMessage:sendToPlayer(player)
            end
        end
        networkMessage:delete()
        return true 
    end

    networkMessage:sendToPlayer(self)
    networkMessage:delete()
    return true
end

-- force add store item
-- safely adds item to player store inbox
-- ignores cap and other limitations

-- player:addStoreItemEx(item)
function Player:addStoreItemEx(storeItem)
	storeItem:setStoreItem(true)
	return self:getStoreInbox():addItemEx(storeItem, -1, FLAG_NOLIMIT)
end

-- player:addStoreItem(id or name, subType)
function Player:addStoreItem(itemId, subType)
	local storeItem = Game.createItem(itemId, subType)
	if storeItem then
		self:addStoreItemEx(storeItem)
	end
	return storeItem
end
