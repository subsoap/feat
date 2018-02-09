local defsave = require("defsave.defsave")
local defsteam = require("defsteam.defsteam")
local json = require("feat.json")

local M = {}

M.defsave_filename = "feat" -- filename to use with defsave
M.feat_data_filename = "/feat/blank_data.lua" -- required feat template data
M.update_frequency = 1 -- amount of time in seconds between auto checks
M.timer = 0 -- current timer value (loops)
M.use_timer = false -- set to true to auto check over time
M.verbose = false -- set to true to get way more information printed to console
M.super_verbose = false -- if true enables printing modify / set of stats (which can clog up console otherwise)
M.achievements = {} -- table of active achievements
M.stats = {} -- table of active stats

-- We don't want achievement data easy to edit
-- So we use simple zlib inflate/deflate to make it
-- just a little harder to edit
local function decompress(buffer)
	if buffer == nil then return {} end
	buffer = zlib.inflate(buffer)
	return json.decode(buffer)
end

local function compress(buffer)
	buffer = json.encode(buffer)
	return zlib.deflate(buffer)
end

function M.init(self)
	M.feat_data = assert(loadstring(sys.load_resource(M.feat_data_filename)))()
	--pprint(M.feat_data)
	if not defsave.is_loaded(M.defsave_filename) then
		defsave.load(M.defsave_filename)
	end
	M.achievements = decompress(defsave.get(M.defsave_filename, "achievements"))
	M.stats = decompress(defsave.get(M.defsave_filename, "stats"))
	
	defsteam.init()
	defsteam.userstats.RequestCurrentStats()
	M.setup()
	--pprint(M.stats)
	--pprint(M.achievements)
end

-- Resets ALL achivement and stat data
function M.reset()
	defsave.reset_to_default(M.defsave_filename)
end

function M.update(self, dt)
	if M.use_timer == true then
		M.timer = M.timer + dt
		if M.timer > M.update_frequency then
			M.timer = M.timer - M.update_frequency
			M.check_data()
			if M.verbose == true then print("Feat: Checking Feat Data!") end
		end
	end
end

function M.check_data()
	for i,v in pairs(M.achievements) do
		if v.stat == nil then return end
		if v.unlocked == false and M.check_stat(v.stat, v.stat_amount) then
			M.unlock_achievement(i)
		end
	end
end

function M.check_stat(stat, value)
	if M.stats[stat] >= value then return true else return false end
end

function M.final(self)
	defsave.set(M.defsave_filename, "achievements", compress(M.achievements))
	defsave.set(M.defsave_filename, "stats", compress(M.stats))
	defsave.save_all()
end

-- Sets up achievements/stats based on JSON file, creates any missing
function M.setup()
	for i,v in pairs(M.feat_data.achievements) do
		if M.achievements[i] == nil then
			if M.verbose == true then print("Feat: Setting up new achievement " .. i) end
			M.create_achievement(i, v.stat, v.stat_amount)
		end
	end
	for i,v in pairs(M.feat_data.stats) do
		if M.stats[i] == nil then
			if M.verbose == true then print("Feat: Setting up new stat " .. i) end
			M.create_stat(i, v)
		end
	end	
end

function M.create_stat(stat, value)
	if M.verbose == true then print("Feat: Creating stat " .. stat .. " with value " .. value) end
	M.stats[stat] = {}
	M.stats[stat].id = stat
	M.stats[stat].value = value
end

function M.modify_stat(stat, value)
	if M.super_verbose == true then print("Feat: Modifying stat " .. stat  .. " with value " .. value) end
	if M.stats[stat] == nil then M.create_stat(stat, value) return end
	M.stats[stat].value = M.stats[stat].value + value
end

function M.set_stat(stat, value)
	if M.super_verbose == true then print("Feat: Setting stat " .. stat  .. " with value " .. value) end
	if M.stats[stat] == nil then M.create_stat(stat, value) return end
	M.stats[stat].value = value
end

function M.create_achievement(achievement, stat, stat_amount)
	if M.verbose == true then print("Feat: Creating achievement " .. achievement) end
	if stat ~= nil then
		M.achievements[achievement] = {}
		M.achievements[achievement].id = achievement
		M.achievements[achievement].stat = stat
		M.achievements[achievement].stat_amount = stat_amount
		M.achievements[achievement].unlocked = false
	else
		M.achievements[achievement] = {}
		M.achievements[achievement].id = achievement
		M.achievements[achievement].unlocked = false
	end
end

-- manually unlock an achivement (not linked to a stat)
function M.unlock_achievement(achievement)
	if M.achievements[achievement] == nil then M.create_achievement(achievement) end
	if M.achievements[achievement].unlocked == true then return end
	if M.verbose == true then print("Feat: Unlocking achievement " .. achievement) end
	M.achievements[achievement].unlocked = true
	
	defsteam.userstats.SetAchievement(achievement)
	defsteam.userstats.StoreStats()

end


return M