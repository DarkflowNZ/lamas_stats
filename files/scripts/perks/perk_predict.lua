---@diagnostic disable: lowercase-global, unused-local, missing-global-doc

---@class perk_predict
---@field future_perks string[][]
---@field reroll_perks string[][]
---@field current_gamble_perks string[]
---@field future_gamble_perks string[][]
---@field reroll_gamble_perks string[][]
---@field max_perks number
---@field current_perk_index number
---@field private env table
local predict = {
	future_perks = {},
	future_gamble_perks = {},
	max_perks = 0,
	reroll_perks = {},
	reroll_gamble_perks = {},
	current_gamble_perks = {},
	current_perk_index = 1,
	perk_index = 1,
	reroll_index = 1,
	mountain_index = 1,
	mountain_visits = 0,
}

---Returns the two perks Gamble would grant without changing prediction state.
---@param start_index number
---@param perks string[]
---@return string[]
function predict:PredictGamble(start_index, perks)
	local result = {}
	local perk_count = #perks
	if perk_count == 0 then return result end

	local index = tonumber(start_index) or 1
	if index < 1 or index > perk_count then index = 1 end
	local attempts = 0
	local max_attempts = math.max(16, perk_count * 4)

	while #result < 2 and attempts < max_attempts do
		local perk_id = perks[index]
		index = index + 1
		if index > perk_count then index = 1 end
		attempts = attempts + 1

		if perk_id and perk_id ~= "" and perk_id ~= "GAMBLE" then result[#result + 1] = perk_id end
	end

	return result
end

function predict:UpdatePerkList()
	self.max_perks = 0
	self.future_perks = {}
	self.future_gamble_perks = {}
	self.current_perk_index = tonumber(GlobalsGetValue("TEMPLE_NEXT_PERK_INDEX")) or 1
	self.perk_index = self.current_perk_index
	self.mountain_visits = (tonumber(GlobalsGetValue("HOLY_MOUNTAIN_VISITS")) or 0) + 1
	local perks = self.env.perk_get_spawn_order()
	self.current_gamble_perks = self:PredictGamble(self.current_perk_index, perks)
	self.env.perk_spawn = function(x, y, perk_id, dont_remove_other_perks_) ---@diagnostic disable-line: duplicate-set-field
		local arr = predict.future_perks[predict.mountain_index]
		arr[#arr + 1] = perk_id
	end

	for i = 1, 8 do
		self.mountain_index = i
		self.future_perks[i] = {}
		self.env.perk_spawn_many(0, 0)
		self.future_gamble_perks[i] = self:PredictGamble(self.perk_index, perks)
		self.max_perks = math.max(self.max_perks, #self.future_perks[i])
		self.mountain_visits = self.mountain_visits + 1
	end

	self.reroll_perks = {}
	self.reroll_gamble_perks = {}
	self.reroll_index = tonumber(GlobalsGetValue("TEMPLE_REROLL_PERK_INDEX")) or #perks
	self.env.perk_spawn = function(x, y, perk_id, dont_remove_other_perks_) ---@diagnostic disable-line: duplicate-set-field
		local arr = predict.reroll_perks[predict.mountain_index]
		arr[#arr + 1] = perk_id
	end

	for i = 1, 8 do
		self.mountain_index = i
		self.reroll_perks[i] = {}
		self.env.perk_reroll_perks()
		self.reroll_gamble_perks[i] = self:PredictGamble(self.current_perk_index, perks)
	end
end

function predict:Init()
	local make_env = dofile_once("mods/lamas_stats/files/lib/prediction_env.lua")
	local env = make_env()
	self.env = env

	env.GlobalsGetValue = function(key, default_value)
		if key == "TEMPLE_NEXT_PERK_INDEX" then return predict.perk_index end
		if key == "HOLY_MOUNTAIN_VISITS" then return predict.mountain_visits end
		if key == "TEMPLE_REROLL_PERK_INDEX" then return predict.reroll_index end
		return GlobalsGetValue(key, default_value)
	end

	env.GlobalsSetValue = function(key, value)
		if key == "TEMPLE_NEXT_PERK_INDEX" then
			predict.perk_index = tonumber(value) --[[@as number]]
		end
		if key == "TEMPLE_REROLL_PERK_INDEX" then
			predict.reroll_index = tonumber(value) --[[@as number]]
		end
	end

	---Redefined to nil
	env.GameAddFlagRun = function() end

	env.EntityKill = function() end

	---@param tag string
	---@return entity_id[]
	env.EntityGetWithTag = function(tag)
		if tag == "perk" then
			local player = EntityGetWithTag("player_unit")[1]
			if not player then return predict.future_perks[1] end
			local x, y = EntityGetTransform(player)
			local entities = EntityGetInRadiusWithTag(x, y, 250, "item_perk")
			return #entities > 0 and entities or predict.future_perks[1]
		end
		return EntityGetWithTag(tag)
	end

	env.EntityGetTransform = function()
		return 0, 0
	end

	env.dofile_once("data/scripts/perks/perk.lua") -- ugh
end

return predict
