-- 800000-809999 - compendium tabs cooldown
COMPENDIUM_COOLDOWNS_BASE = 800000
COMPENDIUM_COOLDOWN_DURATION = 5 -- in seconds

-- compendium tabs
-- Note: items tab is handled by inspection module and eventCallback lib
-- COMPENDIUM_REQUEST_ITEMDATA = 0xCD
-- COMPENDIUM_RESPONSE_ITEMDATA = 0x76

COMPENDIUM_REQUEST_CHARMS = 0xE1
COMPENDIUM_RESPONSE_CHARMS = 0xD8

COMPENDIUM_REQUEST_BESTIARY = 0xE1
COMPENDIUM_RESPONSE_BESTIARY = 0xD5

COMPENDIUM_REQUEST_BESTIARY_SPECIES = 0xE2
COMPENDIUM_RESPONSE_BESTIARY_SPECIES = 0xD6

COMPENDIUM_REQUEST_PLAYERDATA = 0xE5
COMPENDIUM_RESPONSE_PLAYERDATA = 0xDA

--[[

COMPENDIUM_REQUEST_MAP = 0xDB
COMPENDIUM_REQUEST_HOUSES = 0xAD
COMPENDIUM_REQUEST_FRIEND = 0x81

]]

-- 0xCE - inspect creature
-- 0xED?

INSPECTION_ITEM_NORMAL = 0
INSPECTION_ITEM_NPCTRADE = 1
INSPECTION_ITEM_PLAYERTRADE = 2
INSPECTION_ITEM_COMPENDIUM = 3

-- bestiary
MONSTERGROUP_NONE = 0

MONSTERGROUP_AMPHIBIC = 1
MONSTERGROUP_AQUATIC = 2
MONSTERGROUP_BIRD = 3
MONSTERGROUP_CONSTRUCT = 4
MONSTERGROUP_DEMON = 5
MONSTERGROUP_DRAGON = 6
MONSTERGROUP_ELEMENTAL = 7
MONSTERGROUP_EXTRA_DIMENSIONAL = 8
MONSTERGROUP_FEY = 9
MONSTERGROUP_GIANT = 10
MONSTERGROUP_HUMAN = 11
MONSTERGROUP_HUMANOID = 12
MONSTERGROUP_LYCANTHROPE = 13
MONSTERGROUP_MAGICAL = 14
MONSTERGROUP_MAMMAL = 15
MONSTERGROUP_PLANT = 16
MONSTERGROUP_REPTILE = 17
MONSTERGROUP_SLIME = 18
MONSTERGROUP_UNDEAD = 19
MONSTERGROUP_VERMIN = 20

MONSTERGROUP_FIRST = MONSTERGROUP_AMPHIBIC
MONSTERGROUP_LAST = MONSTERGROUP_VERMIN

-- images are hardcoded in the client
monsterGroupNames = {
	[MONSTERGROUP_AMPHIBIC] = "Amphibic",
	[MONSTERGROUP_AQUATIC] = "Aquatic",
	[MONSTERGROUP_BIRD] = "Bird",
	[MONSTERGROUP_CONSTRUCT] = "Construct",
	[MONSTERGROUP_DEMON] = "Demon",
	[MONSTERGROUP_DRAGON] = "Dragon",
	[MONSTERGROUP_ELEMENTAL] = "Elemental",
	[MONSTERGROUP_EXTRA_DIMENSIONAL] = "Extra Dimensional",
	[MONSTERGROUP_FEY] = "Fey",
	[MONSTERGROUP_GIANT] = "Giant",
	[MONSTERGROUP_HUMAN] = "Human",
	[MONSTERGROUP_HUMANOID] = "Humanoid",
	[MONSTERGROUP_LYCANTHROPE] = "Lycanthrope",
	[MONSTERGROUP_MAGICAL] = "Magical",
	[MONSTERGROUP_MAMMAL] = "Mammal",
	[MONSTERGROUP_PLANT] = "Plant",
	[MONSTERGROUP_REPTILE] = "Reptile",
	[MONSTERGROUP_SLIME] = "Slime",
	[MONSTERGROUP_UNDEAD] = "Undead",
	[MONSTERGROUP_VERMIN] = "Vermin"
}

-- player info tabs
COMPENDIUM_PLAYER_BASEINFORMATION = 0
COMPENDIUM_PLAYER_GENERAL = 1
COMPENDIUM_PLAYER_COMBAT = 2
COMPENDIUM_PLAYER_DEATHS = 3
COMPENDIUM_PLAYER_PVPKILLS = 4
COMPENDIUM_PLAYER_ACHIEVEMENTS = 5
COMPENDIUM_PLAYER_INVENTORY = 6
COMPENDIUM_PLAYER_COSMETICS = 7
COMPENDIUM_PLAYER_STORE = 8
COMPENDIUM_PLAYER_INSPECTION = 9
COMPENDIUM_PLAYER_BADGES = 10
COMPENDIUM_PLAYER_TITLES = 11

-- kill types
COMPENDIUM_KILLTYPE_JUSTIFIED = 0
COMPENDIUM_KILLTYPE_UNJUSTIFIED = 1
COMPENDIUM_KILLTYPE_GUILDWAR = 2
COMPENDIUM_KILLTYPE_ASSISTED = 3
COMPENDIUM_KILLTYPE_ARENA = 4

-- compendium response types
COMPENDIUM_RESPONSETYPE_OK = 0
COMPENDIUM_RESPONSETYPE_NODATA = 1
COMPENDIUM_RESPONSETYPE_ACCESSDENIED = 2
COMPENDIUM_RESPONSETYPE_INSPECTIONDENIED = 3

-- compendium skill ids
COMPENDIUM_SKILL_MAGIC = 1
COMPENDIUM_SKILL_FIST = 11
COMPENDIUM_SKILL_CLUB = 9
COMPENDIUM_SKILL_SWORD = 8
COMPENDIUM_SKILL_AXE = 10
COMPENDIUM_SKILL_DISTANCE = 7
COMPENDIUM_SKILL_SHIELDING = 6
COMPENDIUM_SKILL_FISHING = 13

compendiumSkillMap = {
	[SKILL_FIST] = COMPENDIUM_SKILL_FIST,
	[SKILL_CLUB] = COMPENDIUM_SKILL_CLUB,
	[SKILL_SWORD] = COMPENDIUM_SKILL_SWORD,
	[SKILL_AXE] = COMPENDIUM_SKILL_AXE,
	[SKILL_DISTANCE] = COMPENDIUM_SKILL_DISTANCE,
	[SKILL_SHIELD] = COMPENDIUM_SKILL_SHIELDING,
	[SKILL_FISHING] = COMPENDIUM_SKILL_FISHING
}

-- client combat types
CLIENT_COMBAT_PHYSICAL = 0
CLIENT_COMBAT_FIRE = 1
CLIENT_COMBAT_EARTH = 2
CLIENT_COMBAT_ENERGY = 3
CLIENT_COMBAT_ICE = 4
CLIENT_COMBAT_HOLY = 5
CLIENT_COMBAT_DEATH = 6
CLIENT_COMBAT_HEALING = 7
CLIENT_COMBAT_DROWN = 8
CLIENT_COMBAT_LIFEDRAIN = 9
CLIENT_COMBAT_MANADRAIN = 10

clientCombatMap = {
	CLIENT_COMBAT_PHYSICAL = COMBAT_PHYSICALDAMAGE,
	CLIENT_COMBAT_FIRE = COMBAT_FIREDAMAGE,
	CLIENT_COMBAT_EARTH = COMBAT_EARTHDAMAGE,
	CLIENT_COMBAT_ENERGY = COMBAT_ENERGYDAMAGE,
	CLIENT_COMBAT_ICE = COMBAT_ICEDAMAGE,
	CLIENT_COMBAT_HOLY = COMBAT_HOLYDAMAGE,
	CLIENT_COMBAT_DEATH = COMBAT_DEATHDAMAGE,
	CLIENT_COMBAT_HEALING = COMBAT_HEALING,
	CLIENT_COMBAT_DROWN = COMBAT_DROWN,
	CLIENT_COMBAT_LIFEDRAIN = COMBAT_LIFEDRAIN,
	CLIENT_COMBAT_MANADRAIN = COMBAT_MANADRAIN
}

OUTFIT_TYPE_NORMAL = 0
OUTFIT_TYPE_QUEST = 1
OUTFIT_TYPE_STORE = 2
	
-- begin compendium cache
COMPENDIUM_CACHE = {
	outfitLookTypes = {
		[PLAYERSEX_FEMALE] = {},
		[PLAYERSEX_MALE] = {}
	},
	mountLookTypes = {},
	mountLookTypeToId = {},
}

-- init compendium cache
for playerSex = PLAYERSEX_FEMALE, PLAYERSEX_MALE do
	for _, outfit in pairs(Game.getOutfits(playerSex)) do
		COMPENDIUM_CACHE.outfitLookTypes[playerSex][#COMPENDIUM_CACHE.outfitLookTypes[playerSex] + 1] = outfit.lookType
	end
end

for _, mount in pairs(Game.getMounts()) do
	COMPENDIUM_CACHE.mountLookTypes[#COMPENDIUM_CACHE.mountLookTypes + 1] = mount.clientId
	COMPENDIUM_CACHE.mountLookTypeToId[mount.clientId] = mount.id
end
-- end compendium cache