dofile_once("data/scripts/lib/utilities.lua")
local seed = StatsGetValue("world_seed")

SetRandomSeed(seed, seed)
SetWorldSeed(Random(seed, seed*100))
print("[+] new need")