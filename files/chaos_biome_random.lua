dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/astelor_chaos_biome/files/biome_list.lua")

mod_id = "astelor_chaos_biome"

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
                            if string.match(filename, "/"..v..".xml") then
                                -- table.insert(color_table, tonumber(color,16))
								color_table[v] = tonumber(color,16)
                                print('Biome Randomizer - Inserted color "'..color..'" from biome "'..filename..'"')
                            end
                        end
                    end
                end
            end
        end
    end
    -- print("Total number of colors in the table: "..#color_table)
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
	for index, value in pairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

local function make_prob_table(name_table)
    local table = {}
    -- local sum = ModSettingGet(mod_id..".".."biome_sum")
    local counter = 0
    for k,v in pairs(name_table) do
        local val = ModSettingGetNextValue(mod_id.."."..v)
        print("[+] prob: "..tostring(val).." "..v)
        val = math.floor(tonumber(val))
        for i = counter, counter + val - 1 do
            table[i] = v
        end
        counter = counter + val
    end
    return table
end

local function truncate_float(val)
	local out
	if(val ~= nil and string.find(val,"%.") ~= nil) then
		out = string.sub(val, 0 , string.find(val,"%.") + 1)
	else
		out = val
	end
	return out
end
-- set random colors to the biome map
local function randomize_biome_colors(color_table, prob_table, sum)
    local total_count = 0
    local color_count = {}
    -- if( sum == 0) then
    --     return 0
    -- end
    -- print("[+] sum "..tostring(sum).." type:  "..type(sum))

    local function increment_count(biome)
        if(color_count[biome]~=nil) then
            color_count[biome] = color_count[biome] + 1
        else
            color_count[biome] = 1
        end
        total_count = total_count + 1
    end
    
    for x = 0, w-1 do
        for y = 0, h-2 do
            local pixel_color = real_BiomeMapGetPixel(x, y)
            if(has_value(color_table, pixel_color)) then
                local num = Random(0, sum-1)
                -- print(num)
                local biome = prob_table[num]
                local color = color_table[biome]
                increment_count(biome)
                BiomeMapSetPixel(x, y, color)
            end
        end
    end

    -- prevent the bottom row of hell chunks to be randomized
    for x = 0, w-1 do
        local pixel_color = real_BiomeMapGetPixel(x, h-1)
        if(has_value(color_table, pixel_color) and pixel_color ~= 4282126090) then -- if the pixel not hell
            local num = Random(0, sum-1)
            local biome = prob_table[num]
            local color = color_table[biome]
            increment_count(biome)

            BiomeMapSetPixel(x, h-1, color)
        end
    end
    print("[+] randomized biomes")
    for k,v in pairs(biome_list) do
        local count = color_count[v]
        if(count == nil) then
            count = 0
        end
        local percentage = count / total_count * 100
        percentage = truncate_float(tostring(percentage))
        print("[+] pixels: "..count.." "..percentage.."% "..v)
    end
    return 1
end

local function randomize_wall(color_table, prob_table, sum)
    -- prevent the top and bottom row of wall to be randomized (it's buggy)
    for x = 0, w-1 do
        for y = 1, h-2 do
            local pixel_color = real_BiomeMapGetPixel(x, y)
            if(pixel_color == 4282203453) then
                local num = Random(0, sum-1)
                -- print(num)
                local biome = prob_table[num]
                local color = color_table[biome]
                -- increment_count(biome)
                BiomeMapSetPixel(x, y, color)
            end
        end
    end
end

-- for k, v in pairs(biome_list) do
--     local val = ModSettingGetNextValue(mod_id.."."..v)
--     val = tostring(val)
--     print("[+] prob: "..val.." "..v)    
-- end

local sum = ModSettingGetNextValue(mod_id..".".."biome_sum")
local wall_rand = ModSettingGet(mod_id..".".."do_wall_rand")

-- local name_table = biome_list
-- table.insert(name_table, "solid_wall")
-- table.insert(name_table, "solid_wall_tower")

local color_table = generate_biome_colors(biome_list)

if(sum ~= 0) then
    local prob_table = make_prob_table(biome_list)
    randomize_biome_colors(color_table, prob_table,sum)
    if(wall_rand == true) then
        randomize_wall(color_table, prob_table, sum)
    end
end
