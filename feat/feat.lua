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
M.enable_obfuscation = false -- if true then all data saved and loaded will be XOR obfuscated - FASTER
M.obfuscation_key = "feat" -- pick a unique obfuscation key, the longer the key for obfuscation the better

-- xor key based obfuscation
local function obfuscate(input, key)
	if M.enable_obfuscation == false then return input end
	key = key or M.obfuscation_key
	local output = ""
	local key_iterator = 1

	local input_length = #input
	local key_length = #key

	for i=1, input_length do
		local character = string.byte(input:sub(i,i))
		if key_iterator >= key_length then key_iterator = 1 end -- cycle
		local key_byte = string.byte(key:sub(key_iterator,key_iterator))
		output = output .. string.char(bit.bxor( character , key_byte))

		key_iterator = key_iterator + 1

	end
	return output
end

-- We don't want achievement data easy to edit
-- So we use simple zlib inflate/deflate to make it
-- just a little harder to edit
local function decompress(buffer)
	if buffer == nil then return {} end
	buffer = zlib.inflate(buffer)
	buffer = obfuscate(buffer, obfuscation_key)
	buffer = json.decode(buffer)
	return buffer
end

local function compress(buffer)
	buffer = json.encode(buffer)
	buffer = obfuscate(buffer, obfuscation_key)
	buffer = zlib.deflate(buffer)
	return buffer
end

function M.init()
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

function M.update(dt)
	if M.use_timer == true then
		M.timer = M.timer + dt
		if M.timer > M.update_frequency then
			M.timer = M.timer - M.update_frequency
			M.check_data()
			
		end
	end
end

function M.check_data()
	if M.verbose == true then print("Feat: Checking Feat Data! ") end
	for i,v in pairs(M.achievements) do
		if v.stat ~= nil then
			if v.unlocked == false and M.check_stat(v.stat, v.stat_amount) then
				M.unlock_achievement(i)
			end
		end
	end
end

function M.check_stat(stat, value)
	if M.stats[stat].value >= value then return true else return false end
end
function M.get_stat(stat)
	return M.stats[stat].value
end

-- You should save data with feat.save() whenever you do normal game saves
function M.save()
	M.update_defsave()
	defsave.save_all()	
end

-- You can update data into DefSave without saving right now
function M.update_defsave()
	defsave.set(M.defsave_filename, "achievements", compress(M.achievements))
	defsave.set(M.defsave_filename, "stats", compress(M.stats))	
end

function M.final()
	M.save()
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

	defsteam.userstats.SetStat(M.stats[stat].id, M.stats[stat].value)
	defsteam.userstats.StoreStats()	
end

function M.set_stat(stat, value)
	if M.super_verbose == true then print("Feat: Setting stat " .. stat  .. " with value " .. value) end
	if M.stats[stat] == nil then M.create_stat(stat, value) return end
	M.stats[stat].value = value

	defsteam.userstats.SetStat(M.stats[stat].id, M.stats[stat].value)
	defsteam.userstats.StoreStats()
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

-- manually unlock an achivement
function M.unlock_achievement(achievement)
	if M.achievements[achievement] == nil then M.create_achievement(achievement) end
	if M.achievements[achievement].unlocked == true then return end
	if M.verbose == true then print("Feat: Unlocking achievement " .. achievement) end
	M.achievements[achievement].unlocked = true
	
	defsteam.userstats.SetAchievement(achievement)
	defsteam.userstats.StoreStats()

end

-- You generally DON'T want to allow users to do this
-- Use it for testing only
function M.reset_all_stats(flag)
	if M.verbose == true then print("Feat: Resetting all stats") end
	flag = flag or false
	defsteam.userstats.ResetAllStats(flag)
	defsteam.userstats.StoreStats()
	M.stats = {}
	M.achievements = {}
end

return M