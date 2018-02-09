-- This data is for Spacewar
-- https://steamdb.info/app/480/stats/

return {

	achievements = {
		-- Achievements linked to stats will auto unlock when stat_amount is reached (same or higher) of that stat
		ACH_WIN_ONE_GAME = {stat = "NumGames", stat_amount = 1},
		ACH_WIN_100_GAMES = {stat = "NumGames", stat_amount = 100},
		ACH_TRAVEL_FAR_ACCUM = {stat = "FeetTraveled", stat_amount = 5280},
		ACH_TRAVEL_FAR_SINGLE = {},
		NEW_ACHIEVEMENT_0_4 = {}
		
	},
	stats = {
		NumGames = 0,
		NumWins = 0,
		NumLosses = 0,
		FeetTraveled = 0,
		AverageSpeed = 0,
		Unused2 = 0,
		MaxFeetTraveled = 0
	}	
	
}