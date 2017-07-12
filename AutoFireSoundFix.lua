-- Header comment that will likely be deleted. This was made by 90e.
--24 June 2017, fixed Little Friend 7.62/contrabandm203 using single fire bullet shot when using underbarrel grenade launcher mode
-- <3 Offy
-- Don't play a sound conventionally (unless using the saw which lacks a single fire sound)

local base_fire_sound = RaycastWeaponBase._fire_sound

function RaycastWeaponBase:_fire_sound()
	if self:get_name_id() == "saw" or self:get_name_id() == "saw_secondary" or self:get_name_id() == "m134" or self:get_name_id() == "flamethrower_mk2" or self:get_name_id() == "mg42" then
		base_fire_sound(self)
	end --to delete?
end

-- Instead play the single fire noise here

local old_fire = RaycastWeaponBase.fire
function RaycastWeaponBase:fire(...)
    local result = old_fire(self, ...)

    -- Don't try playing the single fire sound with the saw; minigun = m134
    if self:get_name_id() == "saw" or self:get_name_id() == "saw_secondary" or self:get_name_id() == "m134" or self:get_name_id() == "flamethrower_mk2" or self:get_name_id() == "mg42" then
        return result
    end


-- this is the crashy bit!
    if result and not self:gadget_overrides_weapon_functions() then
        self:play_tweak_data_sound("fire_single", "fire")
	elseif self:gadget_overrides_weapon_functions() then
		self:play_tweak_data_sound(self:fire_mode() == "auto" and "fire_auto" or "fire_single", "fire")
	end
    return result
end

--this is the non-crashy stock bit
function RaycastWeaponBase:play_tweak_data_sound(event, alternative_event)
	local sounds = tweak_data.weapon[self._name_id].sounds
	
	--overrides and uses vanilla method to determine "event" if using the little friend underbarrel mode
	--clumsy method of determining which way to get event and play_sound, will fix that later probably 
	if self:gadget_overrides_weapon_functions() then
	local event = self:_get_sound_event(event, alternative_event)
		self:play_sound(event)
--		managers.game_play_central:announcer_say("g23") --lol

--		managers.player:local_player():sound():say(g43,true,true) --!
--		--managers.game_play_central:announcer_say("cpa_a02_01") --lol
	elseif event then
		local event = (sounds and (sounds[event] or sounds[alternative_event])) --otherwise uses AFSF's singlefire override
		self:play_sound(event)
	end
end
