local defsave = require("defsave.defsave")
local defsteam = require("defsteam.defsteam")
local json = require("feat.json")

local M = {}

M.defsave_filename = "feat"
M.feat_data_filename = "/example/example_data.lua"
M.update_frequency = 1
M.timer = 0
M.use_timer = true
M.verbose = false
M.achievements = {}
M.stats = {}

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
	pprint(M.feat_data)
	if not defsave.is_loaded(M.defsave_filename) then
		defsave.load(M.defsave_filename)
	end
	M.achievements = decompress(defsave.get(M.defsave_filename, "achievements"))
	M.stats = decompress(defsave.get(M.defsave_filename, "stats"))
	defsteam.init()
	M.setup()
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
	
end

function M.final(self)
	defsave.set(M.defsave_filename, "achievements", compress(M.achievements))
	defsave.set(M.defsave_filename, "achievements", compress(M.achievements))
	defsave.save_all()
end

-- Sets up achievements/stats based on JSON file, creates any missing
function M.setup()
	for i,v in pairs(M.feat_data.achievements) do
		if M.achievements[i] == nil then
			M.create_achievement(i, v.stat, v.stat_amount)
		end
	end
end

function M.create_stat(stat, value)
end

function M.modify_stat(stat, value)
end

function M.create_achievement(achievement, stat, stat_amount)
	if stat == nil then
		M.achievements[achievement] = {}
		M.achievements[achievement].id = achievement
		M.achievements[achievement].stat = stat
		M.achievements[achievement].stat_amount = stat_amount
	else
		M.achievements[achievement] = {}
		M.achievements[achievement].id = achievement		
	end
end

-- manually unlock an achivement (not linked to a stat)
function M.unlock_achievement(achivement)
end


return M