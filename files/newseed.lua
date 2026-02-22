dofile_once("data/scripts/lib/utilities.lua")

-- local seed = StatsGetValue("world_seed")
-- SetRandomSeed(seed, seed)
-- SetWorldSeed(Random(seed, seed*100))
-- print("[+] new need")

-- SetRandomSeed(StatsGetValue("world_seed"), StatsGetValue("world_seed"))

local test_image = "mods/astelor_chaos_biome/wang_tiles/coalmine.png"
local material_table = {
	4283453522, -- ff505052, --coal 
    4279505941, -- ff141415, --sulphur 
    4292993506, -- ffe1e1e2, --salt 
    4287627264, -- ff900000, --plastic_red
    4286766050, -- ff82DBE2, --diamond
    4293569195, -- ffEAAAAB  --wax
}

local last_changed = material_table[1]
-- local wang_tile_table = {}
local counter = 0
local id, w, h = ModImageIdFromFilename(test_image)
print("[+] w: "..tostring(w).." h: "..tostring(h))

local function profile_wang_tiles(biome_wang)
	counter = counter + 1
	local change_material
	change_material = material_table[Random(1,6)]
	for x = 0, w - 1 do
		for y = 2, h - 1 do
			if(ModImageGetPixel(id, x, y) == last_changed) then
				print("[+] pixel found")
				ModImageSetPixel(id, x, y, change_material)
			end
		end
	end
	print("[+] counter: "..tostring(counter).." "..tostring(last_changed))
	last_changed = change_material
end
function OnPausedChanged()
	profile_wang_tiles(test_image)
end
function OnWorldPreUpdate()
    -- print("[+] world pre update "..tostring(Random(1,6)))
end