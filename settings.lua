dofile("data/scripts/lib/mod_settings.lua") -- see this file for documentation on some of the features.
dofile("mods/astelor_chaos_biome/files/biome_list.lua")
-- dofile("mods/astelor_chaos_biome/files/init.lua")

-- This file can't access other files from this or other mods in all circumstances.
-- Settings will be automatically saved.
-- Settings don't have access unsafe lua APIs.

-- Use ModSettingGet() in the game to query settings.
-- For some settings (for example those that affect world generation) you might want to retain the current value until a certain point, even
-- if the player has changed the setting while playing.
-- To make it easy to define settings like that, each setting has a "scope" (e.g. MOD_SETTING_SCOPE_NEW_GAME) that will define when the changes
-- will actually become visible via ModSettingGet(). In the case of MOD_SETTING_SCOPE_NEW_GAME the value at the start of the run will be visible
-- until the player starts a new game.
-- ModSettingSetNextValue() will set the buffered value, that will later become visible via ModSettingGet(), unless the setting scope is MOD_SETTING_SCOPE_RUNTIME.

function mod_setting_bool_custom( mod_id, gui, in_main_menu, im_id, setting )
	local value = ModSettingGetNextValue( mod_setting_get_id(mod_id,setting) )
	local text = setting.ui_name .. " - " .. GameTextGet( value and "$option_on" or "$option_off" )

	if GuiButton( gui, im_id, mod_setting_group_x_offset, 0, text, 1, "data/fonts/font_pixel_runes.xml", true ) then
		ModSettingSetNextValue( mod_setting_get_id(mod_id,setting), not value, false )
	end

	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

function mod_setting_change_callback( mod_id, gui, in_main_menu, setting, old_value, new_value  )
	print( tostring(new_value) )
end

local mod_id = "astelor_chaos_biome" -- This should match the name of your mod's folder.
mod_settings_version = 1 -- This is a magic global that can be used to migrate settings to new mod versions. call mod_settings_get_version() before mod_settings_update() to get the old value. 
mod_settings = 
{
	-- {
	-- 	id = "hax",
	-- 	ui_name = "[DEBUG] Enable wall hax",
	-- 	ui_description = "",
	-- 	value_default = false,
	-- 	scope = MOD_SETTING_SCOPE_NEW_GAME
	-- },
	{
		id = "fat_biome_edges",
		ui_name = "Fat biome edges",
		ui_description = "a biome setting that makes the edges of the biome not carvable",
		value_default = true,
		scope = MOD_SETTING_SCOPE_NEW_GAME
	}
}

-- This function is called to ensure the correct setting values are visible to the game via ModSettingGet(). your mod's settings don't work if you don't have a function like this defined in settings.lua.
-- This function is called:
--		- when entering the mod settings menu (init_scope will be MOD_SETTINGS_SCOPE_ONLY_SET_DEFAULT)
-- 		- before mod initialization when starting a new game (init_scope will be MOD_SETTING_SCOPE_NEW_GAME)
--		- when entering the game after a restart (init_scope will be MOD_SETTING_SCOPE_RESTART)
--		- at the end of an update when mod settings have been changed via ModSettingsSetNextValue() and the game is unpaused (init_scope will be MOD_SETTINGS_SCOPE_RUNTIME)
function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id ) -- This can be used to migrate some settings between mod versions.
	mod_settings_update( mod_id, mod_settings, init_scope )
	-- print("[+] wall hax?????: "..tostring(ModSettingGetNextValue("minibosses_enabled")))
end

-- This function should return the number of visible setting UI elements.
-- Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
-- If your mod changes the displayed settings dynamically, you might need to implement custom logic.
-- The value will be used to determine whether or not to display various UI elements that link to mod settings.
-- At the moment it is fine to simply return 0 or 1 in a custom implementation, but we don't guarantee that will be the case in the future.
-- This function is called every frame when in the settings menu.
function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

function mod_setting_number_custom( mod_id, gui, in_main_menu, im_id, setting )
	local value = ModSettingGetNextValue( mod_setting_get_id(mod_id,setting) )
	if type(value) ~= "number" then value = setting.value_default or 0.0 end

	if setting.value_min == nil or setting.value_max == nil or setting.value_default == nil then
		GuiText( setting.ui_name .. " - not all required values are defined in setting definition" )
		return
	end

	local value_new = GuiSlider( gui, im_id, 0, 5, setting.ui_name, value, setting.value_min, setting.value_max, setting.value_default, setting.value_display_multiplier or 1, setting.value_display_formatting or "", 80 )
	if value ~= value_new then
		ModSettingSetNextValue( mod_setting_get_id(mod_id,setting), value_new, false )
		mod_setting_handle_change_callback( mod_id, gui, in_main_menu, setting, value, value_new )
	end

	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

local function sum_all_prob(mod_id)
	local val = 0
	for k,v in pairs(biome_list) do
		val = val + tonumber(math.floor(ModSettingGetNextValue( mod_id.."."..v)))
	end
	return val
end

local function generate_biome_setting(mod_id, default_num, is_default)
	for k,v in pairs(biome_list) do
		ModSettingSetNextValue( mod_id.."."..v, default_num, is_default)
	end
	ModSettingSetNextValue(mod_id..".".."biome_sum", sum_all_prob(mod_id), false)
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

-- list_changed = false

-- function list_changed()
-- 	list_changed = true
-- end

local setting = {
	id = "unknown",
	ui_name = "", -- it's not mono case >:(
	ui_description = "",
	value_default = 5,
	value_display_formatting = " ", -- value
	value_display_multiplier = 1,
	value_max = 10,
	value_min = 0,
	-- change_fn = list_changed()
}
-- This function is called to display the settings UI for this mod. Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
	
	local id = 958958
	local function new_id() id = id + 1; return id end
	-- GuiOptionsAdd( gui, GUI_OPTION.Layout_ForceCalculate )
	GuiText(gui,0,0,"--Configure Probability of Biome Spawn--")
	GuiText(gui,15,0,"Note: The probability is a rough estimate, can be about +-1%")
	-- make a button here that sets all value back to default
	GuiText(gui,15,0, "sum: "..tostring(ModSettingGetNextValue(mod_id..".".."biome_sum")))

	GuiColorSetForNextWidget(gui,0.9,0.3,0.3,1)
	if(GuiButton(gui,new_id(),15,0,"Reset all probabilities below")) then
		generate_biome_setting(mod_id, 5, false)
	end

	GuiLayoutBeginVertical(gui,0,3,false,0,0)
	for k,v in pairs(biome_list) do
		GuiText(gui,0,2,v)
	end
	GuiLayoutEnd(gui)

	GuiLayoutBeginVertical(gui,15,0,false,0,0)
	for k,v in pairs(biome_list) do
		local val = ModSettingGetNextValue(mod_id.."."..v)
		if(val == nil) then
			val = "?"
			generate_biome_setting(mod_id, 5, true)
			-- print("[+] proc")
		else
			if(string.find(val,"%.") ~= nil) then
				val = string.sub(val, 0 , string.find(val,"%.")-1)
			end
		end
		GuiText(gui,0,2,val)
	end
	GuiLayoutEnd(gui)
	GuiLayoutBeginVertical(gui,17,-4,false,0,0)
	for k,v in pairs(biome_list) do
		setting.id = v
		mod_setting_number_custom(mod_id,gui,in_main_menu,new_id(),setting)
	end
	GuiLayoutEnd( gui )
	
	GuiLayoutBeginVertical(gui,31,-6,false,0,0)
	local sum = sum_all_prob(mod_id)
	ModSettingSetNextValue(mod_id..".".."biome_sum", sum, false)
	-- print(tostring(sum))
	for k,v in pairs(biome_list) do
		local val = ModSettingGetNextValue(mod_id.."."..v)
		-- if(val ~= nil and string.find(val,"%.") ~= nil) then
		-- 	val = string.sub(val, 0 , string.find(val,"%.") + 1)
		-- end
		val = math.floor(tonumber(val))
		val = val / sum * 100
		val = truncate_float(val)
		GuiText(gui,0,2,tostring(val).."%")
	end
	GuiLayoutEnd( gui )
	GuiLayoutBeginVertical(gui,35,-9,false,0,0)
	for k,v in pairs(biome_list) do
		local val = math.floor(ModSettingGetNextValue(mod_id.."."..v))
		local str = " "
		if(val ~= 0)then
			str = string.rep("=", val)
		else
			str = " "
		end
		GuiText(gui,0,2,str)
	end
	GuiLayoutEnd( gui )
	for i = 0, #biome_list do
		GuiText(gui,0,1," ")
	end
	-- if(not in_main_menu) then
	-- 	if(list_changed) then
			
		
	-- 	end
	-- end
	
	-- GuiText(gui,0,100,"hi")
	-- I want a pie chart here
	-- GuiText( gui, 0, 0, " " )
	-- local testing = GuiSlider(gui,new_id(),0,0,"", testing ,0,10,5,1.0," ",100)

	-- local biome_prob_list = ModSettingGet("astelor_chaos_biome.biome_prob")
	-- local biome_prob = {}
	-- local counter = 0
	-- local temp  = ""
	-- for i in string.gmatch(biome_prob_list, "[^,]+") do
	-- 	if(counter % 2 == 0) do
	-- 		biome_prob[temp] = i
	-- 	end
	-- 	temp = i
	-- 	counter = counter + 1
	-- end
	-- local new_biome_prob
	-- if(not in_main_menu) then
		-- GuiText(gui, 1, 1, "TEEEEEEEEST")
		-- for k,v in pairs(biome_list) do
		-- 	-- GuiLayoutBeginHorizontal(gui,0,0,false,2,2)
		-- 	GuiColorSetForNextWidget(gui,0.8,0.8,0.8,1)
		-- 	-- print("[+] biomes: "..v)
		-- 	GuiText(gui,1,1,v)
		-- 	-- if(biome_prob[v] ~= nil) then
		-- 	local prob = GuiSlider(gui,new_id(),0,0,"", biome_prob[v],0,10,5,1.0," ",100)
		-- 	biome_prob[v] = prob
		-- 	-- end
		-- end
		-- GuiLayoutEnd(gui)
	-- end
	-- GuiLayoutEndLayer( gui )
	-- GuiColorSetForNextWidget(gui, 0, 1, 0, 1)
	-- local biome_prob_list_new = ""
	-- for k,v in pairs(biome_prob) do
	-- 	biome_prob_list_new = biome_prob_list_new .. k .. "," .. v .. ","
	-- end

	--example usage:

	-- local im_id = 124662 -- NOTE: ids should not be reused like we do below
	-- GuiLayoutBeginLayer( gui )

	-- GuiLayoutBeginHorizontal( gui, 10, 50 )
    -- GuiImage( gui, im_id + 12312535, 0, 0, "data/particles/shine_07.xml", 1, 1, 1, 0, GUI_RECT_ANIMATION_PLAYBACK.PlayToEndAndPause )
    -- GuiImage( gui, im_id + 123125351, 0, 0, "data/particles/shine_04.xml", 1, 1, 1, 0, GUI_RECT_ANIMATION_PLAYBACK.PlayToEndAndPause )
    -- GuiLayoutEnd( gui )

	-- GuiBeginAutoBox( gui )

	-- GuiZSet( gui, 10 )
	-- GuiZSetForNextWidget( gui, 11 )
	-- GuiText( gui, 50, 50, "Gui*AutoBox*")
	-- GuiImage( gui, im_id, 50, 60, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	-- GuiZSetForNextWidget( gui, 13 )
	-- GuiImage( gui, im_id, 60, 150, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )

	-- GuiZSetForNextWidget( gui, 12 )
	-- GuiEndAutoBoxNinePiece( gui )

	-- GuiZSetForNextWidget( gui, 11 )
	-- GuiImageNinePiece( gui, 12368912341, 10, 10, 80, 20 )
	-- GuiText( gui, 15, 15, "GuiImageNinePiece")

	-- GuiBeginScrollContainer( gui, 1233451, 500, 100, 100, 100 )
	-- GuiLayoutBeginVertical( gui, 0, 0 )
	-- GuiText( gui, 10, 0, "GuiScrollContainer")
	-- GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	-- GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	-- GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	-- GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	-- GuiLayoutEnd( gui )
	-- GuiEndScrollContainer( gui )

	-- local c,rc,hov,x,y,w,h = GuiGetPreviousWidgetInfo( gui )
	-- print( tostring(c) .. " " .. tostring(rc) .." " .. tostring(hov) .." " .. tostring(x) .." " .. tostring(y) .." " .. tostring(w) .." ".. tostring(h) )

	
end
