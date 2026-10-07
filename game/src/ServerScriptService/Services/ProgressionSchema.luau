-- Reserved progression records in the existing player store. No eggs/PvP grants yet.
local Schema = { Version = 3 }
local fields = { "BirdStats", "OwnedBirds", "OwnedEggs", "Breeding", "RewardState" }
function Schema.Read(data)
	local future = {}
	for _, key in ipairs(fields) do
		future[key] = type(data) == "table" and type(data[key]) == "table" and data[key] or {}
	end
	future.PvPRating = type(data) == "table" and tonumber(data.PvPRating) or 0
	return future
end
function Schema.Write(old, profile, bird)
	old.Schema = Schema.Version
	local future = profile.Future or Schema.Read(old)
	for _, key in ipairs(fields) do old[key] = future[key] end
	old.PvPRating = future.PvPRating
	-- Current derived indicator; per-owned-bird inherited stats remain reserved.
	old.BodyPower = bird.BodyPower
	return old
end
return Schema
