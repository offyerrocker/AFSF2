--Original mod by 90e, uploaded by DarKobalt.
--Reverb fixed by Doctor Mister Cool, aka Didn'tMeltCables, aka DinoMegaCool
--New version uploaded and maintained by Offyerrocker.

--[[ this is here for debugging reasons, ignore it
local function dbug(...)
	OffyLib:c_log(...)
end
--]]

_G.AutoFireSoundFixBlacklist = {
	["saw"] = true,
	["saw_secondary"] = true,
	["flamethrower_mk2"] = true,
	["m134"] = true,
	["mg42"] = true,
	["shuno"] = true,
	["system"] = true
}

--Allows users/modders to easily edit this blacklist from outside of this mod
Hooks:Register("AFSF2_OnWriteBlacklist")
Hooks:Add("BaseNetworkSessionOnLoadComplete","AFSF2_OnLoadComplete",function()
	Hooks:Call("AFSF2_OnWriteBlacklist",AutoFireSoundFixBlacklist)
end)
--if you would like to edit this blacklist, you can use the following example:
--[[

Hooks:Add("AFSF2_OnWriteBlacklist","PlaceholderHookIdGoesHere",function(blacklist_table)
	blacklist_table.mg42 = false --"nil" (no quotation marks) would also work instead of false
	blacklist_table.peacemaker = true
end)

--]]
--(in this example, i remove the mg42 and add the peacekeeper .45 revolver)
--You can hook this basically anywhere. I recommend "lib/units/weapons/raycastweaponbase" (same as AFSF2) if you don't know where to hook it. You could also change this version and uncomment it here, but then your changes would be removed when you update AFSF2. 

--This blacklist defines which weapons are prevented from playing their single-fire sound in AFSF.
	--Weapons not on this list will repeatedly play their single-fire sound rather than their auto-fire loop.
	--Weapons on this list will play their sound as normal
	-- either due to being an unconventional weapon (saw, flamethrower, other saw, other flamethrower), or lacking a singlefire sound (minigun, mg42, other minigun).
--I could define this in the function but meh	
	

--Check for if AFSF's fix code should apply to this particular weapon
function RaycastWeaponBase:_soundfix_should_play_normal()
	local name_id = self:get_name_id() or "xX69dank420blazermachineXx" --if somehow get_name_id() returns nil, crashing won't be my fault. though i guess you'll have bigger problems in that case. also you'll look dank af B)
	if not self._setup.user_unit == managers.player:player_unit() then
		--don't apply fix for NPCs or other players
		return true
	elseif tweak_data.weapon[name_id].use_fix ~= nil then 
		--for custom weapons
		return tweak_data.weapon[name_id].use_fix
	elseif AutoFireSoundFixBlacklist[name_id] then
		--blacklisted sound
		return true
	elseif not self:weapon_tweak_data().sounds.fire_single then
		--no singlefire sound; should play normal
		return true
	end
	return false
	--else, AFSF2 can apply fix to this weapon
end

--Prevent playing sounds except for blacklisted weapons
local orig_fire_sound = RaycastWeaponBase._fire_sound
function RaycastWeaponBase:_fire_sound(...)
	if self:_soundfix_should_play_normal() then
		return orig_fire_sound(self,...)
	end
end

--Play sounds here instead for fix-applicable weapons; or else if blacklisted, use original function and don't play the fixed single-fire sound
--U200: there goes AFSF2's compatibility with other mods
Hooks:PreHook(RaycastWeaponBase,"fire","autofiresoundfix2_raycastweaponbase_fire",function(self,...)
	if not self:_soundfix_should_play_normal() then
		self._bullets_fired = 0
		self:play_tweak_data_sound(self:weapon_tweak_data().sounds.fire_single,"fire_single")
	end
end)

--stop_shooting is only used for fire sound loops, so playing individual single-fire sounds means it doesn't need to be called
local orig_stop_shooting = RaycastWeaponBase.stop_shooting
function RaycastWeaponBase:stop_shooting(...)
	if self:_soundfix_should_play_normal() then
		return orig_stop_shooting(self,...)
	end
--	if self._sound_fire then 
--		self._sound_fire:stop() --stops sounds immediately and without a reverb. unfortunately this cuts off the fire sound prematurely because it is VERY immediate.
--	end
end