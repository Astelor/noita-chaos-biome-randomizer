dofile_once( "data/scripts/lib/utilities.lua" )
dofile_once("mods/astelor_chaos_biome/files/biome_list.lua")
-- dofile_once("mods/astelor_chaos_biome/files/newseed.lua")

-- SetWorldSeed(123) -- set seed

-- user defined functions below
-- Astelor: does this work in nightmare mode?
--          we can make it available to be configured in the mod settings
-- finding any mod init setting biome_map magic_number
local function find_biome_script()
	local mod_ids = ModGetActiveModIDs()
	for _, id in pairs(mod_ids)do
		if(id ~= "astelor_chaos_biome")then
			local content = ModTextFileGetContent("mods/"..id.."/init.lua")
			if(content ~= nil)then
				content = string.gsub(content, "%-%-%[%[[^%[%]]*%]%]", "")
				local lines = {}
				for s in content:gmatch("[^\r\n]+") do
					table.insert(lines, s)
				end
				content = ""
				for i, line in ipairs(lines) do
					line = string.gsub(line, "%-%-(.*)", "")
					content = content..line..string.char(10)
				end
				local arguments = string.gmatch(content, "ModMagicNumbersFileAdd%(%s*\"([^()]+)\"%s*%)")
				for argument in arguments do
					--print(argument)
					local magic_numbers_file = ModTextFileGetContent(argument)
					local magic_numbers = string.gmatch(magic_numbers_file, [[BIOME_MAP="([^"]+)]])
					for magic_number in magic_numbers do
						return magic_number
					end
				end
			end
		end
	end
end

print("Biome Randmizer - finding existing biome script...")

Biome_script_cbr = find_biome_script()

if(Biome_script_cbr ~= nil) then
	ModLuaFileAppend(Biome_script_cbr, "mods/astelor_chaos_biome/files/chaos_biome_random.lua")
else
	ModMagicNumbersFileAdd( "mods/astelor_chaos_biome/files/magic_numbers.xml" )
end

-- solution to make coalmine lone chunks generate properly
-- Astelor: I tried to put the original coalmine.png in the original folder, in some lone chunks it does not generate
--          But pointing the file to a copy in the mod folder somehow works fine, there must be something hardcoded in the engine
-- local coal_xml = ModTextFileGetContent( "data/biome/coalmine.xml" )
-- coal_xml = coal_xml:gsub( [[wang_template_file="data/wang_tiles/coalmine.png"]], [[wang_template_file="mods/astelor_chaos_biome/wang_tiles/coalmine.png"]] )
-- ModTextFileSetContent( "data/biome/coalmine.xml", coal_xml )

-- local tower_1_xml = ModTextFileGetContent("data/biome/tower/solid_wall_tower_1.xml")
-- tower_1_xml = tower_1_xml:gsub( [[wang_template_file="data/wang_tiles/coalmine.png"]], [[wang_template_file="mods/astelor_chaos_biome/wang_tiles/coalmine.png"]] )
-- ModTextFileSetContent( "data/biome/tower/solid_wall_tower_1.xml", tower_1_xml )

function get_biome_name_from_path(path)
	local t1 = 1 + string.len(path) - string.find(string.reverse(path), "/")
	local t2 = string.find(path, "%.")
	local t3 = string.sub(path, t1 + 1, t2 - 1)
	return t3
end

-- local test_image = "mods/astelor_chaos_biome/test/endgame_test_1.png"
local test_image = "mods/astelor_chaos_biome/wang_tiles/coalmine.png"

function fix_biome_xml(biome_xml)
	local xml2lua = dofile("mods/astelor_chaos_biome/lib/xml2lua/xml2lua.lua")
	local handler = dofile("mods/astelor_chaos_biome/lib/xml2lua/xmlhandler/tree.lua")

	local biomes = ModTextFileGetContent(biome_xml)
	local parser = xml2lua.parser(handler)
	parser:parse(biomes)
	if(biome_xml == "data/biome/winter_caves.xml")then -- snowy chasm does not like being changed
		return
	end
	print("Biome Randomizer - Fixing biome file: "..biome_xml)

	for i1, p1 in pairs(handler.root.Biome) do
		if i1 == "Topology" then
			local biome = get_biome_name_from_path(biome_xml)
			if(p1._attr ~= nil) then
				p1._attr.limit_background_image = "0"
				p1._attr.background_edge_priority = "0"
				p1._attr.fat_biome_edges = "1"
				if(biome == "coalmine" or biome == "solid_wall_tower_1") then
					-- print("[+] coalmine changed :>")
					p1._attr.wang_template_file = "mods/astelor_chaos_biome/wang_tiles/coalmine.png"
				end
			end
		end
	end
	ModTextFileSetContent(biome_xml, xml2lua.toXml(handler.root, "Biome", 0))
end

function get_biome_xml_files()
	local biomes_all = ModTextFileGetContent("data/biome/_biomes_all.xml")
	local xml2lua = dofile("mods/astelor_chaos_biome/lib/xml2lua/xml2lua.lua")
	local handler = dofile("mods/astelor_chaos_biome/lib/xml2lua/xmlhandler/tree.lua")
	local parser = xml2lua.parser(handler)
	parser:parse(biomes_all)
	local xml_files = {}
	for i, p in pairs(handler.root.BiomesToLoad) do
		if i == "Biome" then
			for i2, p2 in pairs(handler.root.BiomesToLoad[i]) do
				if(p2._attr ~= nil)then
					local filename = p2._attr.biome_filename
					local color = p2._attr.color
					for k, v in pairs(biome_list)do
						if string.match(filename, "/"..v) then
							table.insert(xml_files, filename)
						end
					end
				end
			end
		end
	end
	return xml_files
end

-- wall hax 
-- print("[+] wall hax: "..tostring(ModSettingGet("astelor_chaos_biome.hax")))
if(ModSettingGet("astelor_chaos_biome.hax")) then
	ModMagicNumbersFileAdd("mods/astelor_chaos_biome/test/debug_magic_numbers.xml")
end

-- new game plus loads its own biome script, so this code is necessary
ModLuaFileAppend("data/biome_impl/biome_map_newgame_plus.lua", "mods/astelor_chaos_biome/files/chaos_biome_random.lua")

function OnPlayerSpawned( player_entity ) -- This runs when player entity has been created
	GamePrint("Chaos Biome Randomizer loaded, Good Luck!")
end


function OnMagicNumbersAndWorldSeedInitialized() -- this is the last point where the Mod* API is available. after this materials.xml will be loaded.
	-- print( "[+] THE MOD LOADS!!")
	if(Biome_script_cbr ~= nil)then
		print("Biome Randomizer - Active biome script found: "..Biome_script_cbr)
	else
		print("Biome Randomizer - No biome script found, using internal")
	end
end

function OnModInit()
	local biome_xml_files = get_biome_xml_files()
	for k, v in pairs(biome_xml_files)do
		fix_biome_xml(v)
	end
	if(ModImageDoesExist(test_image) == true) then
		print("[+] image exist! "..test_image)
		ModImageMakeEditable(test_image, 512, 512)
	else
		print("[+] images does not exist "..test_image)
		return nil
	end
end

function OnPausedChanged()
	
end

function OnWorldPreUpdate()
	-- print("[+] world pre update "..tostring(Random(1,6)))
	-- for x = 0, image_w - 1 do
	-- 	for y = 0, image_h -1 do
	-- 		if(ModImageGetPixel(image_id, x, y) ==)
	-- 	end
	-- end 

	-- StatsBiomeReset()
	-- local crypt_xml = ModTextFileGetContent( "data/biome/crypt.xml" )
	-- if(ProceduralRandom(0,0) == 1) then
	-- 	crypt_xml = crypt_xml:gsub( [[wang_template_file="data/wang_tiles/crypt.png"]], 
	-- 	[[wang_template_file="mods/astelor_chaos_biome/test/endgame_test_1.png"]] )
	-- else
	-- 	crypt_xml = crypt_xml:gsub( [[wang_template_file="mods/astelor_chaos_biome/test/endgame_test_1.png"]], 
	-- 	[[wang_template_file="data/wang_tiles/crypt.png"]] )
	-- end
	-- ModTextFileSetContent( "data/biome/crypt.xml", crypt_xml )
	
	-- the game does not like you changing the seed in run time
	-- print("[+] World Pre Update")
	-- SetWorldSeed(ProceduralRandom(0,0,300))
end