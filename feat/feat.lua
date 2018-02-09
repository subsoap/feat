local defsave = require("defsave.defsave")
local defsteam = require("defsteam.defsteam")

local M = {}

M.defsave_filename = "feat"
M.feat_data_filename = "/example/example_data.lua"
--M.feat_data = require("example.example_data")

-- We don't want achievement data easy to edit
-- So we use simple zlib inflate/deflate to make it
-- just a little harder to edit
local function inflate(buffer)
	return zlib.inflate(buffer)
end

local function deflate(buffer)
	return zlib.deflate(buffer)
end

function M.init(self)
	M.feat_data = assert(loadstring(sys.load_resource(M.feat_data_filename)))()
	pprint(M.feat_data)
	if not defsave.is_loaded(M.defsave_filename) then
		defsave.load(M.defsave_filename)
	end
	defsteam.init()
end

-- Resets ALL achivement and stat data
function M.reset()
	defsave.reset_to_default(M.defsave_filename)
end

function M.update(self, dt)
end

function M.final(self)
	defsave.save_all()
end

-- Sets up achievements/stats based on JSON file, creates any missing
function M.setup()
end

function M.modify_stat(stat, value)
end

function M.create_stat(stat, value)
end

function M.create_achievement(achievement, linked_stat, stat_unlock)
end

-- manually unlock an achivement (not linked to a stat)
function M.unlock_achievement(achivement)
end

return M