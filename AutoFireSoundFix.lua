--Original mod by 90e, uploaded by DarKobalt.
--Reverb fixed by Doctor Mister Cool, aka Didn'tMeltCables, aka DinoMegaCool
--New version uploaded and maintained by Offyerrocker.
--At this point all of my previous code is bad and obsolete yay


_G.AutoFireSoundFixBlacklist = {
	["saw"] = true,
	["saw_secondary"] = true,
	["flamethrower_mk2"] = true,
	["m134"] = true,
	["mg42"] = true,
	["shuno"] = true,
	["system"] = true
}
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
	elseif tweak_data.weapon[name_id].use_fix == true then 
		--for custom weapons
		return false
	elseif AutoFireSoundFixBlacklist[name_id] then
		--blacklisted sound
		return true
	elseif not tweak_data.weapon[name_id].sounds.fire_single then
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

--Play sounds here instead for fix-applicable weapons; or else if blacklisted, use original function and don't play the fixed fire sound
--U200: there goes AFSF2's compatibility with other mods
local orig_fire = RaycastWeaponBase.fire
function RaycastWeaponBase:fire(from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul, target_unit,...)

	if managers.player:has_activate_temporary_upgrade("temporary", "no_ammo_cost_buff") then
		managers.player:deactivate_temporary_upgrade("temporary", "no_ammo_cost_buff")

		if managers.player:has_category_upgrade("temporary", "no_ammo_cost") then
			managers.player:activate_temporary_upgrade("temporary", "no_ammo_cost")
		end
	end

	if self._bullets_fired then
	--i've commented and preserved the vanilla code that caused the need for this AFSF2 update:
	--the game plays starts the firesound when firing, in addition to calling _fire_sound()
	--this causes some firesounds to play twice, while also not playing the correct fire sound.
	--so U200 both broke AutoFireSoundFix, made the existing problem worse, and then added a new problem on top of that
	
--		if self._bullets_fired == 1 and self:weapon_tweak_data().sounds.fire_single then
--			self:play_tweak_data_sound("stop_fire")
--			self:play_tweak_data_sound("fire_auto", "fire")
--		end
		self:play_tweak_data_sound(self:weapon_tweak_data().sounds.fire_single,"fire_single")
		
		self._bullets_fired = self._bullets_fired + 1
	end

	local is_player = self._setup.user_unit == managers.player:player_unit()
	local consume_ammo = not managers.player:has_active_temporary_property("bullet_storm") and (not managers.player:has_activate_temporary_upgrade("temporary", "berserker_damage_multiplier") or not managers.player:has_category_upgrade("player", "berserker_no_ammo_cost")) or not is_player

	if consume_ammo and (is_player or Network:is_server()) then
		local base = self:ammo_base()

		if base:get_ammo_remaining_in_clip() == 0 then
			return
		end

		local ammo_usage = 1

		if is_player then
			for _, category in ipairs(self:weapon_tweak_data().categories) do
				if managers.player:has_category_upgrade(category, "consume_no_ammo_chance") then
					local roll = math.rand(1)
					local chance = managers.player:upgrade_value(category, "consume_no_ammo_chance", 0)

					if roll < chance then
						ammo_usage = 0
--						print("NO AMMO COST")
					end
				end
			end
		end

		local mag = base:get_ammo_remaining_in_clip()
		local remaining_ammo = mag - ammo_usage

		if mag > 0 and remaining_ammo <= (self.AKIMBO and 1 or 0) then
			local w_td = self:weapon_tweak_data()

			if w_td.animations and w_td.animations.magazine_empty then
				self:tweak_data_anim_play("magazine_empty")
			end

			if w_td.sounds and w_td.sounds.magazine_empty then
				self:play_tweak_data_sound("magazine_empty")
			end

			if w_td.effects and w_td.effects.magazine_empty then
				self:_spawn_tweak_data_effect("magazine_empty")
			end

			self:set_magazine_empty(true)
		end

		base:set_ammo_remaining_in_clip(base:get_ammo_remaining_in_clip() - ammo_usage)
		self:use_ammo(base, ammo_usage)
	end

	local user_unit = self._setup.user_unit

	self:_check_ammo_total(user_unit)

	if alive(self._obj_fire) then
		self:_spawn_muzzle_effect(from_pos, direction)
	end

	self:_spawn_shell_eject_effect()

	local ray_res = self:_fire_raycast(user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul, target_unit)

	if self._alert_events and ray_res.rays then
		self:_check_alert(ray_res.rays, from_pos, direction, user_unit)
	end

	if ray_res.enemies_in_cone then
		for enemy_data, dis_error in pairs(ray_res.enemies_in_cone) do
			if not enemy_data.unit:movement():cool() then
				enemy_data.unit:character_damage():build_suppression(suppr_mul * dis_error * self._suppression, self._panic_suppression_chance)
			end
		end
	end

	managers.player:send_message(Message.OnWeaponFired, nil, self._unit, ray_res)

	return ray_res

end

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