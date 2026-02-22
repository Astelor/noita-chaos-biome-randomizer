dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/astelor_chaos_biome/files/biome_list.lua")

if(MagicNumbersGetValue("BIOME_MAP") == "mods/astelor_chaos_biome/files/chaos_biome_random.lua"
 and SessionNumbersGetValue("NEW_GAME_PLUS_COUNT") == "0") then
    BiomeMapSetSize(70, 48) -- this is required to generate biomemap from scratch
    BiomeMapLoadImage(0,0,"data/biome_impl/biome_map.png")
end

print("[+] session number NEW_GAME_PLUS_COUNT = "..tostring(SessionNumbersGetValue("NEW_GAME_PLUS_COUNT")))
print("[+] biome map: "..MagicNumbersGetValue("BIOME_MAP"))

local w, h = BiomeMapGetSize()
print("[+] Biome map size: w: "..tostring(w).." h: "..tostring(h))

SetRandomSeed(StatsGetValue("world_seed"), StatsGetValue("world_seed"))

-- get available biome colors
local function generate_biome_colors(name_table)
	local biomes_all = ModTextFileGetContent("data/biome/_biomes_all.xml")

    local xml2lua = dofile("mods/astelor_chaos_biome/lib/xml2lua/xml2lua.lua")
    local handler = dofile("mods/astelor_chaos_biome/lib/xml2lua/xmlhandler/tree.lua")

    local parser = xml2lua.parser(handler)
    parser:parse(biomes_all)

    local color_table = {}

    for i, p in pairs(handler.root.BiomesToLoad) do
        if i == "Biome" then
            for i2, p2 in pairs(handler.root.BiomesToLoad[i]) do
                if(p2._attr ~=nil) then
                    local filename = p2._attr.biome_filename
                    local color = p2._attr.color
                    if(color ~= nil) then
                        -- print("color = "..tonumber(color,16))
                        for k, v in pairs(name_table) do
                            if string.match(filename, "/"..v) then
                                table.insert(color_table, tonumber(color,16))
								print('Biome Randomizer - Inserted color "'..color..'" from biome "'..filename..'"')
                            end
                        end
                    end
                end
            end
        end
    end
    print("Total number of colors in the table: "..#color_table)
    return color_table
end

-- helper function
local function intToByte(n)
	n = (n < 0) and (4294967296 + n) or n
	return (math.modf(n/16777216))%256, (math.modf(n/65536))%256, (math.modf(n/256))%256, n%256
end
-- helper function
local function byteToInt(b1, b2, b3, b4)
	local n = b1*16777216 + b2*65536 + b3*256 + b4
	n = (n > 2147483647) and (n - 4294967296) or n
	return n
end

local function real_BiomeMapGetPixel(x, y)
	local wrong = BiomeMapGetPixel(x, y)
	local a,r,g,b = intToByte(wrong)
	local right = byteToInt(a,b,g,r)+2^32
	return right
end

-- helper function
local function has_value (tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

-- set random colors to the biome map
local function randomize_biome_colors(color_table)
    local color_count = 0
    
    for x = 0, w-1 do
        for y = 0, h-2 do
            local pixel_color = real_BiomeMapGetPixel(x, y)
            -- for coalmine
            -- if(pixel_color == 4292180247) then
            --     -- print("color found")
            --     BiomeMapSetPixel(x, y, color)
            -- end
            if(has_value(color_table, pixel_color)) then
                local num = Random(1, #color_table)
                local color = color_table[num]
                color_count = color_count + 1
                BiomeMapSetPixel(x, y, color)
            end
        end
    end

    -- prevent the bottom row of hell chunks to be randomized
    for x = 0, w-1 do
        local pixel_color = real_BiomeMapGetPixel(x, h-1)
        if(has_value(color_table, pixel_color) and pixel_color ~= 4282126090) then -- if the pixel not hell
            local num = Random(1, #color_table)
            local color = color_table[num]
            color_count = color_count + 1
            BiomeMapSetPixel(x, h-1, color)
        end
    end
    print("Randomized "..tostring(color_count).." pixels")
end

randomize_biome_colors(generate_biome_colors(biome_list))