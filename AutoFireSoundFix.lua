-- Unless this weapon should follow standard logic...
function RaycastWeaponBase:_soundfix_should_play_normal()
    local name_id = self:get_name_id()
	--conditions for firesounds to play in normal method:
	--1.lacking a singlefire sound
	--2.currently in gadget override such as underbarrel mode
	--3.minigun and mg42 will have a silent fire sound if not blacklisted
    if tweak_data.weapon[name_id].sounds.fire_single == nil or self:gadget_overrides_weapon_functions() or name_id == "m134" or name_id == "mg42" then
        return true
    end
    return false
end
--previously blacklisted: "saw", "saw_secondary", "flamethrower_mk2", "mg42", "saiga"


-- ...don't play a sound conventionally...
local original_fire_sound = RaycastWeaponBase._fire_sound
function RaycastWeaponBase:_fire_sound()
    if self:_soundfix_should_play_normal() then
        original_fire_sound(self)
    end
end

-- ...and instead play the single fire noise here
local original_fire = RaycastWeaponBase.fire
function RaycastWeaponBase:fire(...)
    local result = original_fire(self, ...)
    -- TODO?: Why should this have to check for result?
    if not self:_soundfix_should_play_normal() and result then
        self:play_tweak_data_sound("fire_single", "fire")
    end
 
    return result
end

--overkill's next_fire_allowed calculations cause duplicated fire noises for the saiga
--so we bypass it, sort of
function RaycastWeaponBase:start_shooting()
--		self:_fire_sound() --so don't play the fire sound here
	self._next_fire_allowed = math.max(self._next_fire_allowed, self._unit:timer():time())
	self._shooting = true
end


function RaycastWeaponBase:trigger_pressed(...)
	local fired = nil

	if self:start_shooting_allowed() then
		fired = self:fire(...)

		if fired then
			self:_fire_sound() -- play generic fire sound here instead of RaycastWeaponBase:start_shooting()
			self:update_next_shooting_time()
		end
	end

	return fired
end

function RaycastWeaponBase:trigger_held(...)
	local fired = nil

	if self:start_shooting_allowed() then
		fired = self:fire(...)
		if fired then
			self:update_next_shooting_time()
			self:_fire_sound() --play generic fire sound here instead of RaycastWeaponBase:start_shooting()
		end
	else
		self:play_tweak_data_sound("stop_fire") --don't play another sound if you're not actually FIRING
	end

	return fired
end
