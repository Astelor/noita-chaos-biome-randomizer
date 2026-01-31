dofile_once( "data/scripts/lib/utilities.lua" )
dofile_once("mods/chaos_biome_randomizer/files/biome_list.lua")

-- all functions below are optional and can be left out

-- solution to make coalmine lone chunks generate properly
-- Astelor: I tried to put the original coalmine.png in the original folder, in some lone chunks it does not generate
--          But pointing the file to a copy in the mod folder somehow works fine, there must be something hardcoded in the engine
local coal_xml = ModTextFileGetContent( "data/biome/coalmine.xml" )
coal_xml = coal_xml:gsub( [[wang_template_file="data/wang_tiles/coalmine.png"]], [[wang_template_file="mods/chaos_biome_randomizer/files/coalmine.png"]] )
ModTextFileSetContent( "data/biome/coalmine.xml", coal_xml )

local tower_1_xml = ModTextFileGetContent("data/biome/tower/solid_wall_tower_1.xml")
tower_1_xml = tower_1_xml:gsub( [[wang_template_file="data/wang_tiles/coalmine.png"]], [[wang_template_file="mods/chaos_biome_randomizer/files/coalmine.png"]] )
ModTextFileSetContent( "data/biome/tower/solid_wall_tower_1.xml", tower_1_xml )

-- user defined functions below
-- Astelor: does this work in nightmare mode?
--          we can make it available to be configured in the mod settings
-- finding any mod init setting biome_map magic_number
local function find_biome_script()
	local mod_ids = ModGetActiveModIDs()
	for _, id in pairs(mod_ids)do
		if(id ~= "chaos_biome_randomizer")then
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
	ModLuaFileAppend(Biome_script_cbr, "mods/chaos_biome_randomizer/files/chaos_biome_random.lua")
else
	ModMagicNumbersFileAdd( "mods/chaos_biome_randomizer/files/magic_numbers.xml" )
end

function fix_biome_xml(biome_xml)
	local xml2lua = dofile("mods/chaos_biome_randomizer/lib/xml2lua/xml2lua.lua")
	local handler = dofile("mods/chaos_biome_randomizer/lib/xml2lua/xmlhandler/tree.lua")

	local biomes = ModTextFileGetContent(biome_xml)
	local parser = xml2lua.parser(handler)
	parser:parse(biomes)
	print("Biome Randomizer - Fixing biome file: "..biome_xml)

	-- print("[+] what is i: "..tostring(i).." p: "..tostring(p._attr.lua_script))
	for i1, p1 in pairs(handler.root.Biome) do
		if i1 == "Topology" then
			if(p1._attr ~= nil) then
				p1._attr.limit_background_image = "1"
				p1._attr.background_edge_priority = "0"
				-- testing for more biome wang tile randomness
				p1._attr.fat_biome_edges = "1"
				-- p1._attr.skip_edge_textures = "1"
				-- p1._attr.static_tile = "1" 
				-- p1._attr.wang_map_width  = "0"
				-- p1._attr.wang_map_height = "0"
			end

			for i2, p2 in pairs(handler.root.Biome.Topology) do
				if(i2 == "BitmapCaves") then
					if(p2._attr ~= nil) then
						-- print("[+] modify bitmapcaves")

						local t1 = 1 + string.len(biome_xml) - string.find(string.reverse(biome_xml), "/")
						local t2 = string.find(biome_xml, "%.")
						local t3 = string.sub(biome_xml, t1 + 1, t2 - 1)
						p2._attr.DEBUG_output_image = "mods/chaos_biome_randomizer/debug/"..t3..".png"
						p2._attr.spawn_percent = "1"
						p2._attr.size_x = "-1"
						p2._attr.size_y = "-1"
					end
				end
			end
		end
	end
	ModTextFileSetContent(biome_xml, xml2lua.toXml(handler.root, "Biome", 0))
end

function get_biome_xml_files()
	local biomes_all = ModTextFileGetContent("data/biome/_biomes_all.xml")
	local xml2lua = dofile("mods/chaos_biome_randomizer/lib/xml2lua/xml2lua.lua")
	local handler = dofile("mods/chaos_biome_randomizer/lib/xml2lua/xmlhandler/tree.lua")
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
print("[+] wall hax: "..tostring(ModSettingGet("chaos_biome_randomizer.hax")))
if(ModSettingGet("chaos_biome_randomizer.hax")) then
	ModMagicNumbersFileAdd("mods/chaos_biome_randomizer/test/debug_magic_numbers.xml")
end

-- new game plus loads its own biome script
ModLuaFileAppend("data/biome_impl/biome_map_newgame_plus.lua", "mods/chaos_biome_randomizer/files/chaos_biome_random.lua")

function OnPlayerSpawned( player_entity ) -- This runs when player entity has been created
	GamePrint("Chaos Biome Randomizer loaded, Good Luck!")
end

function OnMagicNumbersAndWorldSeedInitialized() -- this is the last point where the Mod* API is available. after this materials.xml will be loaded.
	print( "[+] THE MOD LOADS!!")
	if(Biome_script_cbr ~= nil)then
		print("Biome Randomizer - Active biome script found: "..Biome_script_cbr)
	else
		print("Biome Randomizer - No biome script found, using internal")
	end
end

function OnModInit()
	SetWorldSeed(123) -- set seed
	local biome_xml_files = get_biome_xml_files()
	for k, v in pairs(biome_xml_files)do
		fix_biome_xml(v)
	end
end

function OnWorldPreUpdate()

	-- StatsBiomeReset()
	-- local crypt_xml = ModTextFileGetContent( "data/biome/crypt.xml" )
	-- if(ProceduralRandom(0,0) == 1) then
	-- 	crypt_xml = crypt_xml:gsub( [[wang_template_file="data/wang_tiles/crypt.png"]], 
	-- 	[[wang_template_file="mods/chaos_biome_randomizer/test/endgame_test_1.png"]] )
	-- else
	-- 	crypt_xml = crypt_xml:gsub( [[wang_template_file="mods/chaos_biome_randomizer/test/endgame_test_1.png"]], 
	-- 	[[wang_template_file="data/wang_tiles/crypt.png"]] )
	-- end
	-- ModTextFileSetContent( "data/biome/crypt.xml", crypt_xml )
	
	-- the game does not like you changing the seed in run time
	-- print("[+] World Pre Update")
	-- SetWorldSeed(ProceduralRandom(0,0,300))
end
-- print("chaos_biome_randomizer mod init done")