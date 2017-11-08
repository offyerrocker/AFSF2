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
--previously blacklisted: "saw", "saw_secondary", "flamethrower_mk2", "mg42"


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
