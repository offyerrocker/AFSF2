local base_fire_sound = RaycastWeaponBase._fire_sound

function RaycastWeaponBase:_fire_sound()
	if self:get_name_id() == "saw" or self:get_name_id() == "saw_secondary" or self:get_name_id() == "m134" or self:get_name_id() == "flamethrower_mk2" or self:get_name_id() == "mg42" then
		base_fire_sound(self)
	end
end

-- Instead play the single fire noise here
local old_fire = RaycastWeaponBase.fire
function RaycastWeaponBase:fire(...)
    local result = old_fire(self, ...)

    -- Don't try playing the single fire sound with the saw; minigun = m134
    if self:get_name_id() == "saw" or self:get_name_id() == "saw_secondary" or self:get_name_id() == "m134" or self:get_name_id() == "flamethrower_mk2" or self:get_name_id() == "mg42" then
        return result
    end

    if result and not self:gadget_overrides_weapon_functions() then
        self:play_tweak_data_sound("fire_single", "fire")
	elseif self:gadget_overrides_weapon_functions() then
		self:play_tweak_data_sound(self:fire_mode() == "auto" and "fire_auto" or "fire_single", "fire")
	end
    return result
end

function RaycastWeaponBase:play_tweak_data_sound(event, alternative_event)
	local sounds = tweak_data.weapon[self._name_id].sounds
	--overrides and uses vanilla method to determine "event" if using the little friend underbarrel mode
	if self:gadget_overrides_weapon_functions() then
	local event = self:_get_sound_event(event, alternative_event)
		self:play_sound(event) --play sound method normally, as with underbarrel 
	elseif event then
		local event = (sounds and (sounds[event] or sounds[alternative_event])) --otherwise uses AFSF's singlefire override
		self:play_sound(event)
	end
end
