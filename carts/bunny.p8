pico-8 cartridge // http://www.pico-8.com
version 37
__lua__
is_draw = 0

kills = 0

function _init()
	map_setup()
    setup_hair()
	bullet_homing ={}
	enemies = {}
	start_setup()
	music(5)
end

function _update60()
	if ( not show_lvlup) then
		damage_boost_timer()
		obj.x = playerx
		obj.y = playery+4
		enemy_update()
		move_player()
		move_bullets()
		move_particles()
		cooldown_update()
		ring_fire_damage()
		update_lightning()
		move_gems()
		if (not start) update_timer()
		else choose_weapon_buttons() 
	end
end

function _draw()
	cls()
	draw_map()
	draw_gems()
	if (not show_lvlup) then
		facing = 0
		if (playerflip) facing = -4
		if (playerang==.25) facing = -3
		draw_bullets()
	end
	draw_bugs()
	if (playerang ~= .75) draw_player()
		draw_hair(obj, facing)
	if (playerang == .75) draw_player()
	animate_animations()
	ring_fire_damage_draw()
	draw_enemy_bullets()
	draw_particles()
	if (not start) then

		draw_player_bars()
		draw_weapons_ui()
		if (not show_lvlup or game_over) then
			draw_timer()
		end
	end
	if (start) then
		draw_manual()
	end

	draw_items()
	draw_text()
	if (timer >= 580 and not boss_start) then
		boss_start = true
		music(32)
	end
--print("kb"..stat(0),(playerx)-64,(playery)-57,2)
--print("∧"..flr(100*stat(1)).."%",(playerx)-64,(playery)-50,2)
--print(""..playerhp,playerx+42,playery-52,7)
--print("max"..max_exp,playerx+42,playery-46,7)
end

timer = 0
timer_frames = 0

function update_timer()
	timer_frames += 1
	if (timer_frames == 60) then
		timer_frames = 0
		timer += 1
 	end
 	enemy_level = flr(timer / 30)
end

function draw_timer()
	local minutes = flr(timer / 60)
	local seconds = flr(timer  % 60)
 	?minutes..":"..seconds,(playerx-2),(playery)-54,6
end





-- source: https://www.lexaloffle.com/bbs/?tid=29466
-- ~400 tokens

_9 = {}
function point(x,y) return {x=x,y=y} end
for x=-1,1 do for y=-1,1 do add(_9,point(x,y)) end end
--function p_str(p) return p.x+128*p.y end
function p_str(p) return p.x..","..p.y end
function xy_str(x,y) return x..","..y end
function coords(p, s) return point(flr(p.x*(1/s)),flr(p.y*(1/s))) end


function badd(k,e,_b)
	_b[k] = _b[k] or {} 
	add(_b[k], e)
end

function bdell(k,e,_b)
	_b[k] = _b[k] or {} 
	del(_b[k], e)
end

function bstore(_b,e,clear)
	local p = p_str(coords(e[_b.prop],_b.size))
	local k = e._k
	if k then
		if (k != p) then
			local b = _b[k]
			del(b,e)
			if (#b == 0) _b[k]=nil
			if (clear) then
				bdell(p,e,_b)
			else
				badd(p,e,_b)
			end
		end
	else 
		if (clear) then
			bdell(p,e,_b)
		else
			badd(p,e,_b)
		end
	end
	e._k = p
end

function bget(_b, p)
	local p = coords(p, _b.size)
	local _ = {}
	for o in all(_9) do
		local found = _b[p_str(point(p.x+o.x,p.y+o.y))]
		if found then for e in all(found) do add(_,e) end end
	end
	return _
end

-- usage
-- create a data 'store' {size=30,prop="pos"}
-- store.prop should match your entities' position property name, 
-- which should be a 'point' value like {x=0,y=0}
-- store.size should be tuned to the max neighbor distance you'll be finding

-- periodically call bstore(store, entity) to update their bucket membership

-- bget(store, point) returns stored entities from a 3x3 square of buckets around 
-- the given point, filter these by a distance function if you need more precision

-- remember you can maintain multiple stores based on the needs of your game!


-- demo

bugstore = {size=3,prop="pos"}
cam = point(0,0)



function bump_move(me)
	if (me.no_collision) then
		return
	end
	for e in all(bget(bugstore,me.pos)) do
		if (e != me) then
			if rnd(1) < 0.5 then
			--	me.pos.x += sgn(me.pos.x-e.pos.x)*1
				e.pos.x -= sgn(me.pos.x-e.pos.x)*1
			else
			--	me.pos.y += sgn(me.pos.y-e.pos.y)*1
				e.pos.y -= sgn(me.pos.y-e.pos.y)*1
			end
-- pline(me.pos,e.pos, 5)
		end
	end
end



function store_enemies()
	for e in all(bugs) do
		if (e.no_collision) then
			return
		end
		bstore(bugstore, e)
	end
end





level = 0
exp = 0
exp_total = 0
max_exp = 3
draw_lvlup_txt = false

gems = {}

function make_gem(x,y)
    local gem = {sprite=32,x=x,y=y,picked=false,anim = 90,time = 8000, frame = 0, speed=2,dx=0, dy=0, }
    add(gems,gem)
end

function draw_gems()
    for gem in all(gems) do
        gem.anim -= 1
        gem.time -= 1
        if (gem.anim < 10) then
            gem.frame += 1
        end
        if (gem.frame > 4) then
            gem.frame = 0
            gem.anim = 90
        end
        spr(gem.sprite + gem.frame, gem.x,gem.y + sin(t()%2))
        if (gem.time < 0 ) del(gems,gem)
    end
end

function get_exp()
    exp_total += 1
    sfx(8)
    if (p_energy_max <= 0) exp += 5
    exp +=1
    if (exp >= max_exp) then
        level_up()
    end
end

function move_gems()
    for gem in all(gems) do
        if (gem.picked) then
            local p = angle_move(gem.x, gem.y, playerx, playery, gem.speed)
          gem.x+=p.x
          gem.y+=p.y
        end
    end
end


function level_up()
    sfx(16)
    if (show_lvlup) return
    level += 1
    if (level == 1) then
        max_exp = 7
    else
        max_exp = min(max_exp*1.2,90)
    end
    exp = 0
    if (p_energy < p_energy_max) p_energy = p_energy_max
    dash_cooldown = dash_cooldown_max

   -- add_timed_anim(251,playerx-47+(playerhp_max-2)*8,playery+48,3,30)

   --     for i=1,30 do
   --             add_particle(playerx-58+(playerhp_max-2)*8+rnd(12),playery+54 +rnd(12), rnd({14,15}), i*3)
   --     end

    lvlup_txt = 148
    lvlup_speed = 10
    lvlup_speed_reverse = false
    setup_random_weapons(level % 5 == 0 or level == 1)
    choose_window_t = 30
    choose_window_pause_t = 80
    show_lvlup =true
    beam_animation= .1
end


function aoe_damage(x,y,radius,dmg,sprite,dmg_player)
	if (dmg_player and dst(x,y,playerx,playery) < radius) damage_player(35)

	for e in all(bugs) do
		if (dst(x,y,e.pos.x,e.pos.y) < radius) then
			if (not e.exploded) then
				add_timed_anim(sprite,e.pos.x,e.pos.y, 3,9)
				deal_damage(e, dmg,true)
			elseif(not e.is_bomb) then
				e.exploded = false
			end
		end
	end
end

--function is_point_in_rect(x,y,x1,y1,x2,y2)
--	return x > x1 and x < x2 and y > y1 and y < y2
--end

function random_outside_point(angle, radius, centerx, centery)
	a=angle or rnd()
	r=radius or 90
	return {x=r*cos(a)+(centerx or playerx),y=r*sin(a)+(centery or playery)}
end

function rnd_bln()
	return rnd({true,false})
end

function angle_move(x,y, targetx, targety, speed)
          local a=atan2(x-targetx,y-targety)
          return {x=-speed*cos(a), y=-speed*sin(a)}
end


--function log(text)
--	printh(text)
--end


--function dst2(x1,y1,x2,y2)
--	log(""..x2..":"..y2)
--	local l = sqr(x1-x2)+sqr(y1-y2)
--	local l2 = sqrt(sqr(x1-x2)+sqr(y1-y2))
--	log(""..l.."  "..l2)
-- return l2
--end
--
--function sqr(x) return x*x end

function text_bg(t,...) 
	?"\^i"..t.."\^-i\^g\f0"..t,...
end

function dst(x1,y1,x2,y2)
 local x,y=abs(x2-x1),abs(y2-y1)
 if x<y then x,y=y,x end -- accuracy goes down massively if x is much smaller than y so swap them :)
 return x/sin(atan2(y,x))
end

--function dst(x,y,x2,y2)
-- --gets the distance between
-- --two points. faster than
-- --the previous version.
-- local dx, dy = x - x2, y - y2
-- return squaredist(dx,dy)
--end
--
--function squaredist(dx,dy)
-- local sdx,sdy=shr(dx,8),shr(dy,8)
-- return shl(min(0x0.7fff,sdx*sdx+sdy*sdy),16)
--end



--function text_outline(s,...)
--	for i in all(split'\-f\f0,\-h\f0,\|f\f0,\|h\f0') do
--		?i..s,...
--	end
--	?s,...
--end


--#include weapons/weapons_main.lua
function decrease_max_carrots()
	p_energy_max -=.5
	if (p_energy_max < 0) p_energy_max = 0
end

w_fire_d = {sprite=89, 
		name="fIRE dASH", info="dash damages enemies", use =  function() 
		hair_color = 8
		fire_dash = true
		del(ws, w_frost_d) 
		del(ws, w_fire_d) 
		end}

w_frost_d = {sprite=90, 
		name="fROSTY dASH", info="dash freezes enemies", use =  function(self) 
		hair_color = 12
		frosty_dash = true
		del(ws, w_fire_d) 
		del(ws, w_frost_d) 
		end}

w_reroll = {sprite=108, 
		name="rEROLL", info="", reroll = true}

ws = {

	{sprite = 52, name = "cARROT bURGER \f8-15% speed", info = "+1 ♥ and heal", use = function() 
		playeracc -= .006
		playerhp_max +=1
		playerhp = playerhp_max end},

	{sprite = 74, name = "dAMAGE", info = "up damage", use = function () 
		w_damage +=1 end},

	{sprite = 76, name = "cARROT pARFAIT \f8-15% speed", info = "+1 carrot", use = function () 
		playeracc -= .006
		p_energy_max +=1 end},

--{sprite = 73, name = "cARROT cAKE \f8-30% speed", info = "full heal +1 carrot +1 ♥", use = function () 
--	playeracc -= .012
--	playerhp_max +=1
--	p_energy_max +=1
--	playerhp = playerhp_max end},

	{sprite = 77, name = "hASTE", info = "up attack and move speed", use = function (self) 
		w_carrot_cd_max -= 6
		if (w_attack_speed == 5) del(ws, self)
		playeracc += .003
		w_attack_speed +=1 end},

	{sprite = 78, name = "sWIFTNESS LVL", info = "faster movement and dash", use = function (self) 
		w_move_speed += 1
		dash_cooldown_max -= 20
		if (w_move_speed == 4) del(ws, self)
		playeracc += .007 end},

--{sprite=127, 
--		name="pEACH oVERLOAD", info="create peaches", use =  function(self) 
--		for i=0,3 do
--					local p = random_outside_point(i/4,50)
--					make_peach(p.x,p.y)
--				end
--
--		 end},

{sprite=79, 
		name="pIERCING sHOT \f9-0.5 carrot", info="carrots go through enemies ", use =  function() 
		decrease_max_carrots()
		drill_lvl+=1
		--if (drill_lvl == 1) carrot_energy += 2
	--	carrot_energy +=2
		 end},

{sprite=66, 
		name="cROSSFIRE \f9-0.5 carrot", info="shoot more carrots", use =  function(self) 
		decrease_max_carrots()
		--carrot_energy +=2
		split_shot += 1 
		if (split_shot == 5) del(ws, self)
		end},

--{sprite=93, 
--		name="cROSSFIRE \f2-0.5 carrot", info="chance to shoot 4 carrots ", use =  function(self) 
--		carrot_crossfire += 1
--		decrease_max_carrots()
--	--	carrot_energy +=3
--		if (carrot_crossfire == 3) del(ws, self) 
--		end},

{sprite=92, 
		name="sHURIKENS \f9 -20% attack speed", info="throw shurikens ", use =  function() 
		w_carrot_cd_max += 8
	--	carrot_energy +=4
		w_shuriken += 1
		end},


{sprite=91, 
		name="aTTRACTOR", info="pick up range, more bunnies", use =  function() 
			magnet_area+=8
			for i=0,30 do
				bunny(timer+i*45+rnd(30))
			end
			end},

--{sprite=126, 
--		name="aRCANE fOCUS", info="+200% mp regen while standing", use =  function(self) 
--		del(ws, self)
--		w_arcane = true
--	end},

{sprite=85, 
		name="sPLASH \f9 -30% attack speed", info="carrots do splash damage ", use =  function(self) 
		--decrease_max_carrots()
		carrot_splash += 1
		w_carrot_cd_max += 15
		if (carrot_splash == 4) del(ws, self) 
		end},
{sprite=60, 
		name="tHUNDER cLOUD \f8-15% speed", info="summon lightning ", use =  function(self) 
		playeracc -= .006
		if (w_lightning == 0) setup_cloud()
		w_lightning+=1
		end},

{sprite=121, 
		name="rING oF fLAME \f8-20% speed", info="damage nearby enemies ", use =  function()  
		playeracc -= .011
		ring_of_fire += 1
		end},


--{sprite=84, 
--		name="rING oF gREED", info="+30% mp regen \f2-15 hp", use =  function() 
--		p_energy_regen += .14
--		playerhp_max -=15
--		end}
--
--}

w_fire_d,

w_frost_d

}


energy_cd = 0
p_energy_timer = 20
p_energy_timer_max = 30

p_energy_regen = 1

--regen_focus = 0

function cooldown_update()
    if (energy_cd > 0) energy_cd -= 1

   --   if (w_arcane and player_focus < 30) then
   --     regen_focus = 1.5
   --   else
   --     regen_focus = 0
   --   end

    if (energy_cd == 0 and p_energy < p_energy_max)  then
      p_energy_timer -= 1

    if (p_energy_timer == 0) then
      p_energy_timer= p_energy_timer_max
      p_energy += .5
    end
end


  if (w_carrot_cd > 0) then
    w_carrot_cd -= 1
  end

end

function draw_bullets()
  for b in all(bullet_carrots) do
   spr(b.sprite, b.x,b.y, 1, 1, b.is_flipx, b.is_flipy)
  end
end


function deal_damage(enemy, dmg,no_sound)
  if (not no_sound) sfx(rnd({4,5}))
  enemy.hp -=dmg
  if (enemy.hp <= 0) then
    kill_enemy(enemy)
  else
      enemy.damaged = 3
  end
end



show_choose_window = false
selected_upgrade = 0
select_animation = 0
select_animation_reverse = true

main_weapon = w_knife

w_damage = 0
w_move_speed = 0

player_skills = {}

p_energy_regen += .3


function setup_random_weapons(reroll) 
	random_weapons = {}
	local wr = {}
	for w in all(ws) do
		add(wr,w)
	end
	local c = 4
	if (reroll) c = 3
	for i=1,c do
		random = rnd(wr)
	    add(random_weapons, random)
	   del(wr, random)
	end
	if (reroll) then
	    add(random_weapons, w_reroll)
	end
	selected_item = random_weapons[1]
end

function draw_weapons_ui()
	if (show_lvlup) then
		if (game_over) then
			local minutes = flr(timer / 60)
			local seconds = flr(timer  % 60)
			local txt = "yay! you won!"
			local bgclr = 14
			if (not game_won) then
				txt = "you lost"
				bgclr = 7
			end

text_bg(txt.."\n\nsurvived: "..minutes.." min. "..seconds.." sec.\n\nkills: "..kills.."\n\nexp: "..exp_total.."\n\n❎ x to restart",playerx-40 ,playery-30,bgclr)
		else
			choose_window_pause_t -= 1
			if (choose_window_pause_t <= 0) then
				choose_window_pause_t = 0
			end
			if (choose_window_t > 0) then
				choose_window_t-= 1
			else
  				show_choose_window = true
				draw_choose_window()
			end 
		end
		local i = 0
		for w in all(player_skills) do
			local item_y = 0
			local item_x = 0
			if (i > 8) then
				item_y = -16
				item_x = -108
			end
			spr(w.sprite,playerx-62+i*12+item_x,playery+34 + item_y)
			?""..w.lvl,playerx-56+i*12+item_x ,playery+43 + item_y,15
			i+=1
		end
	end
end

function draw_choose_window()
	rectfill(playerx-60,playery-56, playerx+60,playery-4, 7)
--	rectfill(playerx-61,playery-55, playerx+61,playery-5,7)

	draw_weapon_row()

	if (select_animation_reverse) then
		select_animation +=0.1
	else
		select_animation -=0.2
	end
	if (select_animation<=0) then
		select_animation_reverse = true
	end
	if (select_animation>=2) then
		select_animation_reverse = false
	end

	spr(49,playerx-48+30*selected_upgrade,playery-31 + sin(t()%2))
end

function draw_weapon_row()
	local clrs = {12,14,7}

	for i=0,3 do
		local w = random_weapons[i+1]
		rectfill(playerx-55+30*i,playery-50, playerx-34+30*i,playery-30, 13)
		--rectfill(playerx-54+30*i,playery-50, playerx-35+30*i,playery-30, 13)
		--rectfill(playerx-55+30*i,playery-49, playerx-34+30*i,playery-31, 13)
		rect(playerx-57+30*i,playery-52, playerx-32+30*i,playery-28, 13)
		line(playerx-56+30*i,playery-27, playerx-33+30*i,playery-27, 6)
		spr(w.sprite,playerx-48+30*i,playery-43)

	end
	rect(playerx-67+30*selected_upgrade+10,playery-52, playerx-32+30*selected_upgrade,playery-28, 8)
 	?selected_item.name,playerx-56,playery-20,0
	if (selected_item.info) ?selected_item.info,playerx-56,playery-12,13
 		
end

function choose_weapon_buttons() 
	if (game_over) then
		game_over_pause -= 1
		if (game_over_pause <= 0) then
			game_over_pause = 0
			if(btnp(4) or btnp(5)) then
				run()
			end
		end
		return
	end
	if(btnp(0)or btnp(2,1)) then
		if (selected_upgrade >0) selected_upgrade -=1
	elseif(btnp(1)or btnp(3,1)) then
		if (selected_upgrade <3) selected_upgrade +=1
	elseif(btnp(4) or btnp(5)) then
		selected_item = random_weapons[selected_upgrade+1]
		if (selected_item.reroll) then
				setup_random_weapons()
		elseif (choose_window_pause_t == 0) then
			player_damaged += 45
			player_damaged_dash = true
			show_choose_window = false
			show_lvlup = false
			selected_upgrade = 0
			selected_item:use()
			if (selected_item.lvl)then
				selected_item.lvl += 1
			else
				if (selected_item.sprite ~= 127) then
					selected_item.lvl = 1
					add(player_skills,selected_item)
				end
			end
		end
	end
	selected_item = random_weapons[selected_upgrade+1]
end

function draw_player_bars()

	local heart = 215
	for i=0,playerhp_max-1 do
		if (i >= playerhp) then
			heart = 217
		end
		spr(heart,playerx-63+i*8,playery+48)
	end
	
	local carrot = 212
	local max = p_energy_max
	if (p_energy > p_energy_max) max = p_energy
	for i=1,max+1 do
		if (i > p_energy_max) carrot = 249
		if (i > p_energy) then
			carrot = 214
		end
		if (i-p_energy==.5) then
			carrot = 213
		end
		if (i-.5  == max) then
			if (max%1 ==.5) then
				carrot = 198
				if (p_energy-max==0) then
					carrot = 197
					if (i-1 > p_energy_max) carrot = 250
				end
			end
		end
		if (i ~= max +1)  spr(carrot,playerx-71+i*8,playery+55)
	end


--if (hp_to_px <= 0) hp_to_px = 0
--rectfill(barx-1,playery+54, max(barx + playerhp_max/5 + 1,  barx + hp_to_px + 1),playery+56, 1)
--if (playerhp > 1 ) then
--	if (playerhp < 15) barc = 8
--	rectfill(barx,playery+55, barx + hp_to_px ,playery+55, barc)
--	if (playerhp>playerhp_max) then 
--		playerhp=playerhp_max
--	end
--end

--local mp_color = 9
--if (w_arcane and player_focus < 30) mp_color = 12
--rectfill(barx-1,playery+58, barx + p_energy_max/5 + 1 ,playery+60, 1)
--rectfill(barx,playery+59, barx + flr(p_energy /5),playery+59, mp_color)
--pset(playerx-57 + flr(carrot_energy / 5),playery+59,10)

	local exp_to_exp = flr(112/(max_exp/exp))
	rectfill(playerx-57,playery-61, playerx+57,playery-59, 1)
	rect(playerx-56,playery-60, playerx-56+exp_to_exp,playery-60, 14)
   	if (show_lvlup and not game_over) then
   		?"level up",playerx-14,playery-63,7
   	else
   		?"LVL"..level,playerx+44,playery-63,7
   	end
end



--#include weapons/attacks/fire_wand.lua
--#include weapons/attacks/beam.lua
knife_rounds = 1

bullet_tick = 0

w_attack_speed = 0
w_shuriken = 0
split_shot = 0
carrot_splash = 0

cloud_attack = false

drill_lvl = 1

carrot_damage = 10
carrot_damage_boost = 0
carrot_damage_boost_timer = 0

w_carrot_cd = 0
w_carrot_cd_max = 30

bullet_carrots ={}

function damage_boost_timer()
	if (carrot_damage_boost_timer > 0) then
		add_particle(playerx+rnd(8),playery+rnd(8), 10, 15,.1)
		carrot_damage_boost = 40
		carrot_damage_boost_timer -= 1
	else
		carrot_damage_boost = 0
	end
end

function throw_knife()
	if (w_carrot_cd == 0  and p_energy >= .5) then
		energy_cd = 50
		w_carrot_cd = max(w_carrot_cd_max,5)
		p_energy -= .5

		local knife_sprite = 102
		local flip_y = false
		if (playerang > .5 and playerang < 1) then 
			flip_y = true
		end

		if (playerang == .25 or playerang == .75) then 
			knife_sprite = 101
		end

		if (playerang % .125 == 0) then 
			knife_sprite = 100
		end

		if (w_shuriken > 0) then
			local sh = w_shuriken
			for i=0,sh*2 do
				if (i ~= sh) then
					local ang = playerang -.04*sh + i *.04
					make_bullet(ang, 125)
				end
			end
		end

		if (split_shot >= 1) then
			make_bullet(playerang + .5)
		end

		if (split_shot >= 2) then
			make_bullet(playerang + .25)
			make_bullet(playerang + .75)
		end

		if (split_shot >= 3) then
			if(bullet_tick%(6-split_shot) == 0) then
				for i=0,3 do
					make_bullet(playerang + .125+i*.25)
				end
			end
		end

		bullet_tick += 1
		if(bullet_tick > 10) then
			bullet_tick= 1
		end

		make_bullet(playerang)

	end


end

function make_bullet(angle,shuriken,x,y,id,pierce) 
	sfx(3)
	if (angle > 1) angle -= 1
		local sx = x or playerx
		local sy = y or playery
		local ph = random_outside_point(angle, 32, sx, sy)
		local pb = angle_move(sx, sy, ph.x, ph.y, 1.5)

		local sprite = 102
		if (angle >= .15 and angle <= .35) or (angle >=.65 and angle <=.85) then 
			sprite = 101
		end

		if ((flr((angle-0.025)*20)+1)%5~=0) then 
			sprite = 100
		end

		local speed = 1.88
		if (shuriken) speed = 2.5

		local dmg = carrot_damage+5*w_damage

		if (shuriken) dmg = 8+w_damage+w_shuriken*2

			local k = {
				x = sx, 
				y = sy, 
				pb = pb, 
				ang = angle,
				sprite = shuriken or sprite , 
				dmg = dmg+carrot_damage_boost, 
				speed = speed, 
				duration=36, 
				is_flipx = (angle >= .25 and angle <=.75), 
				is_flipy = (angle >= .5 and angle <= 1), 
				go_through= pierce or drill_lvl,
				start_animation = -1,
				bullet_id = id or rnd(10),
				animate_death=false,
				is_carrot = not shuriken
			}
			add(bullet_carrots, k)
end



function move_bullets()
	for b in all(bullet_carrots) do
		b.speed-=0.05
		b.x+=b.pb.x*b.speed
		b.y+=b.pb.y*b.speed

		b.duration -= 1
		local p = point(b.x,b.y)


		for e in all(bget(bugstore, p)) do

			if (e.bullet_id != b.bullet_id) then
					e.bullet_id = b.bullet_id
					deal_damage(e, b.dmg )

					b.go_through -=1
						add_timed_anim(106,b.x,b.y,1,4)
				end
		end


		if (b.duration <= 0 or b.go_through <= 0) then
			add_timed_anim(103,b.x,b.y,3,9)
			del(bullet_carrots,b)

			if (b.is_carrot and carrot_splash > 0) then
				add_explosion(b.x,b.y,4 + carrot_splash*3,2)
				aoe_damage(b.x,b.y, 12 + carrot_splash*3,carrot_damage_boost+(carrot_damage/4+carrot_splash*4),118)
			end

		end
	end
end


--#include weapons/attacks/sword.lua
w_lightning = 0
lightning_time = 180

function setup_cloud()
	cloud = {
		sprite = 37,
		death_sprite = 38,
		speed = .14 + w_lightning *.04, 
		is_cloud = true,
		no_collision = true,
		targetx = playerx,
		targety = playery,
		pos=point(playerx,playery)
	}
	add(enemy_bullets, cloud) 
end

function update_lightning()
	if (w_lightning > 0) then
	--	for e in all(enemy_bullets) do
	--		if (e.is_cloud) then
				lightning_time -= 1
				if (lightning_time <= 0) then
					lightning_time = 200 - w_attack_speed*25
					cloud.sprite = 37
					attack_lightning()
				elseif (lightning_time <= 55) then
					cloud.sprite = 39
				end
	--		end
	--	end
	end
end

function attack_lightning()
	--for e in all(enemy_bullets) do
	--	if (e.is_cloud) then
			local x1 = cloud.pos.x
			local y1 = cloud.pos.y
			
			for i=1,3 do
				add_timed_anim(55+flr(rnd(4)),x1,y1-2+ 8*i, 3,9)
			end
			aoe_damage(x1,y1+24, 10+5*w_lightning,11+3*w_damage+4*w_lightning,56)
			add_explosion(x1, y1+28,10+5*w_lightning,0,false,false,true, .1)
	--	end
	--end
end

ring_of_fire = 0
ring_of_fire_tick = 0

function ring_fire_damage()
	if (ring_of_fire > 0) then
		ring_of_fire_tick+=1
		if (ring_of_fire_tick >= 16-w_attack_speed) then
			ring_of_fire_tick = 0
			aoe_damage(playerx,playery, 20 + 3* ring_of_fire,.9+w_damage/3+ring_of_fire/2,118)
		end
	end

end

function ring_fire_damage_draw()
	if (ring_of_fire > 0) then
		local p = random_outside_point(rnd(),rnd(16)+5* ring_of_fire)
		add_particle(p.x+4,p.y+8, rnd({8,9,10}), ring_of_fire*5)
	end
end
frost_timer = 0
frost_x = 0
frost_y = 0

function frost_dash() 
	if (frosty_dash) then
		frost_x = playerx
		frost_y = playery
		
		for e in all(bugs) do
			if (dst(frost_x,frost_y,e.pos.x,e.pos.y) < 28) then
				e.speed = .01
			end
		end
		add_explosion(frost_x, frost_y,24,0,false,false,true)
	end
end



--#include weapons/unused/cat.lua
player_animation = 0
sprite_x = 0

playerx=0
playery=0
playerhp=3
playerhp_max=3
p_energy = 3
p_energy_max = 3
playerang = .75
player_damaged = 0
beam_animation= .1

hair_color= 14
player_damaged_dash = false

function damage_player(dmg)
	if (dmg and dmg > 0 and player_damaged == 0) then
		sfx(0)
		player_damaged = 80
		playerhp -= 1
		shake = 8
		if (playerhp <= 0) game_lost()
	end
end


function pink_line(i,clr)
	line(playerx+2+i,playery+2, playerx+2+i,playery-65, rnd({14,clr}))
end

function draw_player()
if ( game_over and not game_won) then
	return
end
	if (player_damaged == 0) then
		player_damaged_dash = false
	end
	local p_sprite = 40
	if (show_lvlup) then

		if (beam_animation < 7) then
				beam_animation *=1.2
			else
				beam_animation = 7
			end
			local clr = 14
			local clry = 14
			if (rnd()<0.15) clr = 15
			if (rnd()<0.15) clry = 15
				for i=0,beam_animation do 
					pink_line(i,clr)
					pink_line(-i,clry)
				end

			for i = 1,3 do 
				local xx = i
				if (i==1) then
					for i = 0,15 do 
						pal(i, 8) 
					end
				end
				if (i==2) then
				 	xx = 3
					for i = 0,15 do 
						pal(i, 12) 
					end
				end
				if (i==3) then
				 	xx = 2
					pal() 
				end
				sspr(111,96,18, 11, playerx-4-xx,playery+sin(t()+i/3), 18, 11, playerflip)
			end
			return
	end

	if (player_damaged  > 1) then

		for i = 0,15 do 
			if (player_damaged_dash) then
				pal(i, rnd({15,7}))
			else
				pal(i, rnd({8,14}))
			end
			
		end
	end

	if (playerang == .25) then
		p_sprite = 84
	elseif (playerang == .75) then
		p_sprite = 106
		
	end
						pal(14, hair_color) 
	if (dash_cooldown < dash_cooldown_max - dash_cooldown_max/5 ) then
		if (playerang == .25) then
			p_sprite = 95
		elseif (playerang == .75) then
			p_sprite = 62
		else
			p_sprite = 51
		end

	elseif(dash_cooldown < dash_cooldown_max) then
		if (playerang == .25) then
			p_sprite = 117
		elseif (playerang == .75) then
			p_sprite = 106
		else
			p_sprite = 73
		end
	end
	if (is_moving) then		
		sspr(sprite_x,p_sprite,9, 11, playerx,playery, 9, 11, playerflip)
		player_animation+=1
		if (player_animation<6) then 
			sprite_x = 8
		elseif (player_animation<12) then 
			sprite_x = 17
		elseif (player_animation>12) then 
			player_animation = 0
		end
	else
		sspr(0,p_sprite,8, 11, playerx,playery, 8, 11, playerflip)
	end
			pal() 
	if (player_damaged > 0) then
		player_damaged -= 1
		if (player_damaged <= 0) then
			player_damaged = 0
		end
	end

	--end
end




 obj = {x=0,y=0}
    facing = 1

function setup_hair()
    obj.hair={}
    for i=0,4 do
        add(obj.hair,{x=0,y=0,size=max(1,min(2,3-i))})
    end
end

draw_hair=function(obj,facing)
	if (dash_cooldown < dash_cooldown_max) dash_no_energy = true
	if (dash_cooldown_max > dash_cooldown_max and dash_no_energy) then
	--	sfx(9)
		dash_no_energy = false
	end
	if (show_lvlup) then

	else
    	local last={x=obj.x+2-facing,y=obj.y+3}
    	local clr = 14
    	for i=1,5 do
    		if (player_damaged_dash or dash_cooldown  <   (dash_cooldown_max - ((dash_cooldown_max /6)*i) )) then
    			clr = 7
    		else
    			clr = hair_color
    		end

    			local h =obj.hair[i]
    	    h.x+=(last.x-h.x)/2
    	    h.y+=(last.y-h.y)/2
    	    circfill(h.x,h.y,h.size,clr)
    	    last=h
    	end
	end
end


game_over = false
game_won = false

game_over_pause = 120

function game_lost()
   	sfx(17)
	game_over = true
	show_lvlup = true

	add_explosion(playerx,playery,28,16,false,true)
end

function win_game(x,y)
	add_explosion(x,y,28,16,false,true)
	music(0)
	game_won = true
	game_over = true
	show_lvlup = true
end





playerflip=false
playeracc=.084
playerdx=0
playerdy=0
is_moving=false

dash_energy = 50


dash_dmg = 0
dash_timer = 10
dash = false
dash_cooldown = 180
dash_cooldown_max = 180
magnet_area = 8

player_speed = 0
player_push = 0
--player_focus = 0

function move_player()
	interact(playerx,playery)
    local ph = random_outside_point(playerang, 32)
    local pb = angle_move(playerx, playery, ph.x, ph.y, player_speed)

	playerx+=pb.x
	playery+=pb.y
	if (dash) then
		dash_move()
		return
	end
	player_speed *= .86

	if (dash_cooldown > dash_cooldown_max) then
		dash_cooldown = dash_cooldown_max
	else
		dash_cooldown += 1
	end

	is_moving = false

	--if(btn(4,1)) then
	--	level_up()
	--end
	if(btn(5)) then
	--	fire_slash(w_slash)
		throw_knife()
	end

	 creating_item = false
	 if ( player_push == 0) then
	if(btn(⬅️)) then
		is_moving = true
		playerflip = true
		playerang = .5
	end
	if(btn(➡️)) then
		is_moving = true
		playerflip = false
		playerang = 1
	end
	if(btn(⬆️)) then
		is_moving = true
		if( btn(⬅️)) then
			playerang = .375
		elseif( btn(➡️)) then
			playerang = .125
		else
			playerang = .25
		end
	end
	if(btn(⬇️)) then
		is_moving = true
		if( btn(⬅️)) then
			playerang = .625
		elseif( btn(➡️)) then
			playerang = .875
		else
			playerang = .75
		end
	end
	end
	if (is_moving) then
		--if (player_focus < 100) then
		--	player_focus += 1
		--end
		player_speed += max(playeracc, .01)
	elseif (player_push > 0) then
		player_push -= 1
		player_speed -= max(playeracc, .01)
		if (player_push<=0)player_push=0
		--if (player_focus > 0) then
		--	player_focus -= 1
		--end
	end

	if(btnp(4)) then
			if((dash_cooldown >= dash_cooldown_max)) then
			frost_dash()
--			player_focus = min(100, player_focus + 60)
			player_damaged += 45
			if (frosty_dash) player_damaged += 45
			player_damaged_dash = true
			dash = true
			dash_id = rnd()
			dash_cooldown = 0
			player_speed=.6
	
			if (fire_dash) then
				player_speed*=40
			else
				player_speed*=20
			end
		
			sfx(6)
		else
			sfx(25)
		end
	end


end


function dash_move()
--if (w_magic_wand > 0) then
--	for i = 1, w_magic_wand do
--		attack_magic()
--	end
--end
	if (dash_timer % 1 == 0) then
		if (fire_dash) then
			aoe_damage(playerx,playery, 16,30,118)
			add_explosion(playerx,playery+4,6,0)
		end
		local spr = 22
		if (frosty_dash) spr = 16
		add_timed_anim(spr,playerx,playery,3,9, playerflip)
	end

	dash_timer -= 1

	if (dash_timer <= 0) then
		shake = 0
		dash = false
		frost_dash()
		dash_timer = 5
	end


player_speed*=.6
end


function interact(x,y)
	if (dst(playerx,playery,0,0) > map_size) then
		if (start) then
			player_push = 10
			player_speed-= 3
		else
			damage_player(1)
		end
	end
	--if (not dash) then
		for gem in all(gems) do
			if (dst(playerx,playery, gem.x,gem.y) < magnet_area) then
				gem.picked = true
				if (dst(playerx,playery, gem.x,gem.y) < 4) then
					get_exp()
					del(gems,gem)
				end
			end
		end
		for item in all(items) do
			if (dst(playerx,playery, item.x,item.y) < magnet_area) then
				item:use()
				del(items, item)
			end
		end
	--end
end


bugs = {}

function wave_update()
	for wave in all(enemy_waves) do
		if (timer > wave.start_time) then
			if (wave.count > 0) then
				spawn_wave(wave)
			else
				del(enemy_waves, wave)
			end
		end
	end
end

function spawn_wave(wave)
	if (wave.is_swarm) then
		local p = random_outside_point() 
		local pt = angle_move(p.x, p.y, playerx, playery, 256)
		for i=1,wave.count do
			local e = wave:create_unit()
			setup_enemy(e)
			e.pos.x = p.x
			e.pos.y = p.y
			e.life_time = 300

			e.targetx=pt.x+playerx
			e.targety=pt.y+playery

			e.is_swarm = true

			e.is_flipped = e.pos.x > playerx


			add(bugs,e) 


		end
		wave.count = 0
	else
		wave.timer += 1

		if (wave.timer >= wave.interval) then
			local e = wave:create_unit()
			setup_enemy(e)
			wave.timer = 0
			wave.count -= 1
			if (not wave.is_wall) then
				teleport_enemy_out(e)
			else
				local p = random_outside_point(wave.count/wave.total_count,54)
				e.pos.x=p.x
				e.pos.y=p.y
			end
			add(bugs,e) 
		end
	end
end


function setup_enemy(enemy, life)
	if (enemy.is_bomb) then
		enemy.death_item = function()
   			sfx(12)
			add_explosion(enemy.pos.x,enemy.pos.y,25,8,true)
			enemy.exploded = true
			aoe_damage(enemy.pos.x,enemy.pos.y, 26,100,237,true)
		end
	end
	enemy.frame = 2
	enemy.max_speed = enemy.speed
	enemy.aoe=8
	enemy.dmg=1
	enemy.pos=point(0,0)
	if (not enemy.life_time) enemy.life_time = life or 3600
end

function kill_enemy(enemy)
	if (enemy.death_item) then
		enemy.death_item(enemy.pos.x,enemy.pos.y,enemy.gems) 
	else
		if (enemy.spawn) then
			for i = 1, enemy.spawn_count do
				local e = enemy:spawn()
				e.max_speed = e.speed
				e.bullet_id = enemy.bullet_id
				e.exploded = true
				e.aoe=6
				e.pos=point(enemy.pos.x,enemy.pos.y)
				add(bugs,e) 
			end
		else
			if (rnd() < .9) then
				make_gem(enemy.pos.x,enemy.pos.y)
			else
				if (rnd() < .8) then
					make_carrot(enemy.pos.x,enemy.pos.y)
				else
					make_damage_boost(enemy.pos.x,enemy.pos.y)
				end
			end
		end
	end
	kills += 1
	remove_enemy(enemy)
end

function remove_enemy(enemy)
	add_timed_anim(enemy.death_sprite,enemy.pos.x,enemy.pos.y,3,12)
	enemy.pos.x =0
	enemy.pos.y =0
	bstore(bugstore,enemy,true)
	del(bugs,enemy)
	store_enemies()
end





anim_2frames_dur = 0

enemy_bullets = {}

function enemy_update()
	store_enemies()
	move_enemies()
	move_enemy_bullets()
	wave_update()
end

function draw_enemy_bullets()
	for e in all(enemy_bullets) do
		draw_enemy_object(e)
	end
end

function draw_bugs()
	for e in all(enemy_bullets) do
		if (e.is_cloud) then
				spr(19,e.pos.x,e.pos.y+26)
			end
	end
			
	for e in all(bugs) do
		draw_enemy_object(e)
	end
	anim_2frames_dur+=1
end

function draw_enemy_object(e)
	if (e.damaged and e.damaged > 0) then
		for i = 0,15 do 
			pal(i, 14) 
		end
	end

	if (e.draw_black) then
		palt(0,false)
		palt(1,true)
	end

	if (e.skull and e.hp > 10) then
		local sprite = 11
		if (e.hp == 20) sprite = 12
		if (e.hp == 10) sprite = 13
		spr(sprite,e.pos.x,e.pos.y)
	else
		if (e.sprite == -1) then
				local ssx = e.sx +e.next_sx
				if (anim_2frames_dur <8) then
					ssx = e.sx
				elseif (anim_2frames_dur >=16) then
					anim_2frames_dur=0
				end
					sspr(ssx, e.sy, e.sw, e.sh, e.pos.x-5, e.pos.y-5, e.sw, e.sh, e.is_flipped)
		else
				local an = 0
				if (anim_2frames_dur <8) an = 1
				if (anim_2frames_dur >=16) anim_2frames_dur=0
				spr(e.sprite+an,e.pos.x,e.pos.y,  1, 1, e.is_flipped)
		end
	end

	if (e.draw_black) then
		palt()
	end
	pal() 
	if (e.damaged) then
		e.damaged -= 1
		if (e.damaged <= 0) then
			e.damaged = 0
		end
	end

		if (e.max_speed and e.speed < e.max_speed) then
			e.speed = min(e.max_speed, e.speed*1.01)
			spr(167,e.pos.x,e.pos.y)
		end
end

function remove_bullet(e)
	del(enemy_bullets,e)
	--add_timed_anim(e.death_sprite,e.pos.x,e.pos.y,3,12)
end

function move_enemies()
	for e in all(bugs) do
		move_e(e)
		bump_move(e)
	end
end

function move_enemy_bullets()
	for e in all(enemy_bullets) do
		move_e(e)
	end
end

function move_e(e)
	if (not e.is_cloud and e.life_time <= 0) then
		if (e.no_collision) then
			remove_bullet(e)
		else
			remove_enemy(e)
		end
		return
	end

	if (not e.is_cloud and not e.boss) e.life_time -= 1

	if (not e.no_collision and not e.is_swarm) then
		e.targetx = playerx
		e.targety = playery
	end
	if (e.is_cloud) then
		e.targetx = playerx
		e.targety = playery - 16
	end

     local p = angle_move(e.pos.x, e.pos.y, e.targetx, e.targety, e.speed)

     e.pos.x+=p.x
     e.pos.y+=p.y
       

      if (not e.is_cloud and e.no_collision and e.targetx==e.pos.x and e.targety==e.pos.y) then
		remove_bullet(e)
      end

	if (not e.no_collision and not e.is_swarm) then
 		local is_in_camera = teleport_enemy_out_of_camera(e)

		if (is_in_camera) then
			if (e.pos.x > playerx) then 
				e.is_flipped = true
			end
	
			if (e.pos.x < playerx) then 
				e.is_flipped = false
			end
	
		end

	end

	if (e.can_attack) then
		e:attack(e)
	end
		
	if not e.is_cloud and dst(playerx,playery,e.pos.x,e.pos.y) < e.aoe then
		if (e.is_bomb or e.skull) then
			kill_enemy(e)
		elseif (not e.is_crystal and e.death_item and e.is_bunny) then
			remove_enemy(e)
			make_gems()
   			sfx(23)
			player_damaged = 90
			player_damaged_dash = true
			dash_cooldown = dash_cooldown_max
			use_carrot()
		elseif (not dash and e.no_collision) then
			damage_player(e.dmg)
			remove_bullet(e)
		--elseif (dash and fire_dash and e.dash_id ~= dash_id) then
		--	e.dash_id = dash_id
		--	deal_damage(e, 40)
		else
			playerx += (playerx - e.pos.x)/15
			playery += (playery - e.pos.y)/15
			if (player_damaged_dash) then
				deal_damage(e, .5)
			else
				damage_player(e.dmg)
			end
		end
	end
end

function make_gems(x,y,g)
	local gems = g or 7
	for i=0,gems do
		local p = random_outside_point(i/gems,20,x,y)
		make_gem(p.x,p.y)
	end
end

function teleport_enemy_out_of_camera(e)
	if not e.no_teleport and dst(playerx,playery,e.pos.x,e.pos.y) > 96 then
		teleport_enemy_out(e)
		return false
	else
		return true
	end
end

function teleport_enemy_out(e)
	local p = random_outside_point()
		e.pos.x=p.x
		e.pos.y=p.y
end




function bats_wave(start_time, num, interval, circle, swarm)
	local speed = .15
	if (swarm) speed = .75
	return make_wave(
		function() 
		local hp = 10
		if (timer > 50) hp = 15
		return {
		sprite = 9,
			death_sprite = 70,
			speed = speed, 
			hp = hp,
			draw_black = true
	}  end,
		start_time,
		interval,
		num,
		circle,
		swarm
	)
end

function eye_wave(start_time, num, interval)
	return make_wave(
		function() return {
		sprite = 14,
			death_sprite = 173,
			speed = .1+rnd(.25), 
			hp = 15+enemy_level
	}  end,
		start_time,
		interval,
		num
	)
end

function skeletons_wave(start_time, num, interval, circle)
	return make_wave(
		function() return {
		sprite = 25,
		death_sprite = 86,
		speed = 0.20, 
		hp = 25+enemy_level*2
	}  end,
		start_time,
		interval,
		num,
		circle
	)
end

function crystal_wave(start_time, num,type)
	local spr = 254
	local item = make_gems
	if (type == 1) then
		spr = 252
		item = make_peach
	elseif (type == 2) then
		spr = 220
		item = make_magnet
	end
	return make_wave(
		function() return {
		sprite = spr,
		death_sprite = 173,
		speed = 0.2, 
		hp = 100+enemy_level*20,
		gems = 11,
		is_crystal = true,
		death_item = item
	}  end,
		start_time,
		0,
		num
	)
end

function spirit_wave()
	return {
		sprite = 30,
		death_sprite = 199,
		speed = .3, 
		hp = 10,
		dmg = 2,
		life_time = 600
	}
end


function lich_wave(start_time, num)
	return make_wave(
		function() return {
		sprite = 46,
		death_sprite = 210,
		speed = 0.10, 
		hp = 50, 
		timer = 0,
		interval = 20,
		can_attack = true,
		attack = lich_attack_ice,
		spawn_count = 9,
		spawn = spirit_wave
	} end,
		start_time,
		0,
		num
	)
end
 
function demon_wave(start_time)
	return make_wave(
		function() return {
		sprite = -1,
		death_sprite = 244,
		speed = 0.14, 
		hp = 1900, 
		sx = 64,
		sy = 64,
		sw = 19,
		sh = 17,
		boss = true,
		next_sx = 19,
		red_attack = true,
		can_attack = true,
		timer = 0,
		life_time = 9000,
		interval = 10,
		death_item = win_game,
		attack = lich_attack_ice,
	} end,
		start_time,
		0,
		1
	)
end



function bunny(start_time)
	return make_wave(
		function() return {
		sprite = 203,
		death_sprite = 103,
		speed = 0, 
		hp = 50,
		no_teleport = true,
		is_bunny = true,
		death_item = make_peach
	} end,
		start_time,
		1,
		1
	)
end

function skull_wave(start_time)
	return make_wave(
		function() return {
		sprite = 165,
		death_sprite = 244,
		speed = 0, 
		hp = 30,
		no_teleport = true,
		spawn_count = 8,
		spawn = function()
		return { sprite = 149,
				life_time = 300,
				death_sprite = 173,
				speed = .8, 
				hp = 40
		}
		end
	} end,
		start_time,
		1,
		1
	)
end


function bomb_wave(start_time, num, interval)
	return make_wave(
		function() return {
		sprite = 41,
		death_sprite = 104,
		speed = 0.4, 
		no_teleport = true,
		hp = 1,
		is_bomb = true
	}  end,
		start_time,
		interval,
		num
	)
end

function jellies_acid_wave(start_time, num, interval)
	return make_wave(
		function() return {
		sprite = 181,
		death_sprite = 183,
		speed = 0.23, 
		hp = 50,
		life_time = 1400,
		spawn_count = 2,
		spawn = jelly_acid
	}  end,
		start_time,
		interval,
		num
	)
end


function jelly_acid()
	return {
		dmg = 1,
		sprite = 94,
		death_sprite = 183,
		speed = .2, 
		life_time = 1000,
		hp = 8+enemy_level*2
	}
end

function chick_wave(start_time, num, interval, shine)
	return make_wave(
		function() return {
		sprite = 187,
		death_sprite = 173,
		speed = 0.25+enemy_level/100, 
		hp = 10,
		can_shine = shine
	}  end,
		start_time,
		interval,
		num
	)
end

 
function mushroom_wave(start_time, num)
	return make_wave(
		function() return {
		sprite = 157,
		death_sprite = 61,
		speed = 0.10, 
		hp = 30+enemy_level*5,
		spawn_count = 4,
		spawn = mushroom_small
	}  end,
		start_time,
		0,
		num,
		true
	)
end

function mushroom_small()
	return {
		dmg = 1,
		sprite = 141,
		death_sprite = 173,
		speed = 0.35, 
		life_time = 1800,
		hp = 5
	}
end





enemy_waves = {}
enemy_level = 0
wave_index = 4

function setup_enemy_waves()
	random_waves()
end

function random_waves()
	bats_wave(0, 90, 1.5)
	bats_wave(65, 35,.8)
	bats_wave(65, 6,0,false,true)
	crystal_wave(110,1, flr(rnd(2.6)))
	bomb_wave(120,1)
	for i = 0,3 do
		chick_wave(15+15*i, i)
	end
	lich_wave(185,1)
	bats_wave(260, 40, 0,true)
	bomb_wave(300,6,4)
	crystal_wave(340, 10)

	--for j = 0,3 do
	--	for i = 0,3+j do
	--		bats_wave(200+i*5+j*100, 10, 0,false,true)
	--	end
	--end
	for i = 0,12 do
		lich_wave(380+i*5, 1)
	end
	skeletons_wave(460, 30, 0, true)
	for i = 0,5 do
		bats_wave(580, 7, 0,false,true)
	end
	for i = 0,30 do
		bats_wave(590+i*7, 5+i*2, 0,false,true)
	end
	demon_wave(590)
	skull_wave(600)
	
	wave_chickens = function (time)
		chick_wave(time,20+wave_index*2,1)
	end
	
	wave_jellies = function (time)
		jellies_acid_wave(time, 20+wave_index, 1)
	end
	
	wave_shrooms = function (time)
		mushroom_wave(time, 10+wave_index)
	end
	
	wave_bats_circle = function (time)
		for i=0,1 do
			bats_wave(time+i*8, 10+wave_index, 0,true)
			skeletons_wave(time+i*8,wave_index)
		end
	end

	wave_skeletons = function (time)
		skeletons_wave(time,30+wave_index*2,1.5)
	end

	wave_eye = function (time)
		eye_wave(time,20+wave_index*2,1)
	end

local t = 0
	for i=4,19 do
		t += .5*i
		wave_index += 1
		skull_wave(i*50+rnd(20))
		bunny(i*40+rnd(25))
		crystal_wave((i-1)*50+rnd(30),1, flr(rnd(2.6)))
		bats_wave(i*40+rnd(60), 10+i, 0,false,true)

		bomb_wave(i*60+rnd(30),1)

		local wave = rnd({wave_chickens, wave_jellies, wave_shrooms, wave_bats_circle,wave_skeletons,wave_eye})
		if (i < 12 or i > 13) then
			--log("wave "..i.." : "..(i*35 - t))
			wave(i*35-t)
		end
	end
end


function make_wave(create_unit, start_time, interval, count, circle, is_swarm)
	add(enemy_waves, {
		timer = 0,
		create_unit = create_unit,
		start_time = start_time,
		interval = (interval or 0)*60,
		count = count,
		total_count = count,
		is_swarm = is_swarm,
		is_wall = circle
	})
end



ice_balls = {}

red_attack_time = 160

function lich_attack_ice(enemy)
	enemy.timer += 1
	red_attack_time -= 1
	if enemy.timer == enemy.interval then

		
		local spr = 247
		local spd = .5
		local ii = 0

		if (enemy.red_attack) then
			spr = 231
			spd = .9
			ii = 7
		end

		for i=0,ii do
			local e = {
						sprite = spr,
						death_sprite = 103,
						speed = spd, 
						hp = 1,
						dmg = 15
						} 
			local ph = random_outside_point(1/8*i, 64, enemy.pos.x, enemy.pos.y)
			if (not enemy.red_attack) then
				ph.x = playerx
				ph.y = playery
			else
   				sfx(22)
			end
		    local pt = angle_move(enemy.pos.x, enemy.pos.y, ph.x, ph.y, 256)

			if (enemy.red_attack and red_attack_time < 90) then
				enemy.interval = 320
    			 pt = angle_move(enemy.pos.x, enemy.pos.y, playerx, playery, 256)
				if (enemy.red_attack and red_attack_time <= 0) then
					enemy.interval = 10
					red_attack_time = 160
				end
			end
		
			e.aoe=4
			e.no_collision = true
			e.pos=point(enemy.pos.x,enemy.pos.y)
			e.life_time = 180
			e.targetx = pt.x+playerx
			e.targety = pt.y+playery

			add(enemy_bullets,e) 
		
			enemy.timer = 0
		end

	end
end


--made better music,
--
--Some of the best synergies: 
--explosion + crossfire
--shurikens + piercing
--ring of flame + attack speed and damage
--
--Worst synergy is explosion + shurikens, they are weak at first levels so you must concentrate on upgrading only one.
--Dash upgrade will also make your life easier.--


magnet_effect = false
magnet_timer = 0
magnet_speed = 3

function draw_magnet_effect()
	magnet_speed = magnet_speed *0.9 + 0.03
	magnet_timer += magnet_speed 
	--circ(playerx, playery, magnet_timer*2, 7)
	circ(playerx-1, playery+rnd(3), magnet_timer*2, 12)
	circ(playerx+1, playery+rnd(3), magnet_timer*2, 8)
	if (magnet_timer >= 48) then
		magnet_speed =3
		magnet_timer = 0
		magnet_effect = false
	end
end

		


items = {}

function use_damage_boost(self) 
   	sfx(14)
   	carrot_damage_boost_timer = 500
	delete_item(self)
	use_carrot()
end

function make_damage_boost(x,y) 
	make_item(218,x,y, use_damage_boost)
end

function use_peach(self) 
   			sfx(13)
	player_damaged += 30
	player_damaged_dash = true
	dash_cooldown = dash_cooldown_max
	playerhp += 1
	if (playerhp > playerhp_max) playerhp = playerhp_max
	delete_item(self)
end

function use_carrot(self)
   	if (p_energy < p_energy_max) p_energy = p_energy_max
	p_energy += 1
--	if (p_energy > p_energy_max) p_energy = p_energy_max
	if (self) then
   		sfx(14)
		delete_item(self)
	end
end

function use_magnet(self)
   			sfx(15)
	magnet_effect = true
	for gem in all(gems) do
		gem.picked = true
	end
	delete_item(self)
end

function delete_item(item)
	del(animations, item.anim)
	del(items, item)
end

function make_item(sprite,x,y,use)
	local anim = {sprite = sprite, x = x, y =y, step = 0, interval = 45, frame = 0, frames = 1, timer = false}
	add(animations, anim)
	add(items,  {time = 12000, x = x, y =y, anim = anim, use = use})
end

function make_magnet(x,y) 
	make_item(122,x,y, use_magnet)
end

function make_peach(x,y) 
	make_item(196,x,y, use_peach)
end

function make_carrot(x,y) 
	make_item(68,x,y, use_carrot)
end

function draw_items()
	for i in all(items) do
		i.time -=1
        if (i.time < 0 ) delete_item(i)
	end

	if (magnet_effect) then
		draw_magnet_effect()
	end
end





particles = {}
death_animations = {}

--frame_animations = {}

death_animations = {}

animations = {}

texts = {}

circles = {}

explosions = {}

--function add_frames_animation(x,y,dur,sprite, flip)
--	add(frame_animations,{x=x,y=y,duration=dur,timer=dur,sprite=sprite,is_flip = flip })
--end

--function animate_frames()
--	for f in all(frame_animations) do
--		f.timer -=1
--		if (f.timer>0) then spr(f.sprite, f.x,f.y, 1, 1, f.is_flip)
--		elseif (f.timer==0) then del(frame_animations, f)
--		end
--	end
--end


function add_timed_anim(sprite, x, y, frames, timer, flip)
	add(animations, {sprite = sprite, x = x, y =y, step = 0, interval = timer / frames, frame = 0, frames = frames, timer = timer, flip = flip})
end

function animate_animations()
	for k, a in pairs(animations) do

		if (a.timer) then
			if (a.timer > 0) then
				a.timer -=1
			elseif (a.timer<=0) then 
				del(animations, a)
				a = nil
			end
		end

		if (a) then
			if (a.sprite) then
				spr(a.sprite + a.frame, a.x, a.y, 1,1,a.flip)
			end

			a.step += 1
			if (a.step % a.interval == 0) then
				if (a.frame == a.frames - 1) then
					a.frame = 0
				else
					a.frame += 1
				end
				a.step = 0
			end
		end

	end
end

function add_particle(x,y,color,time,move)
	add(particles, {x=x,y=y,color=color,time=time, speed = 0.5, move=move or .5})
end


function add_text(text, x,y,color)
	add(texts, {text = text,x=x,y=y,color=color, death=100})
end

function move_particles()
 	for b in all(particles) do
 		b.y -= b.move
	end
end

function draw_text()
	for t in all(texts) do
		t.death -= 1
		t.y-=.15
		?t.text, t.x,t.y,t.color
		if (t.death <= 0 ) del(texts, t)
	end
end

function add_explosion(x,y,size,s,enemy,lost,frost,lightning)
	if (lost or enemy or (not enemy and carrot_splash > 2)) shake = s
	local count = 14
	if (frost) count = 40
	for i=0,count do
				local p = random_outside_point()
				local p1 = random_outside_point(rnd(),rnd(size),x,y)
		add(explosions, {x=p1.x,y=p1.y,hx=p.x,hy=p.y,time = lightning or size, black = enemy, lost = lost,frost = frost, is_light = lightning})
	end
end

function draw_particles()
	for k, p in pairs(explosions) do
		local speed = .2
		if (p.frost) speed = .1
        local a = angle_move(p.x, p.y, p.hx, p.hy, speed)
        p.x+=a.x+.5-rnd(1)
        p.y+=a.y+.5-rnd(1)

        local clr = rnd({8,9,10})
		if (p.frost) clr = rnd({12,12,7})

        if (p.black) then
			clr = rnd({8,9,5})
        	if (p.time <=8) clr = 6
        end
        if (p.lost) then
        	clr = rnd({14,7,10})
        end

        local radius = p.time/2
        if (p.frost) radius = rnd(2)
        if (p.is_light) radius = 0
		--circfill(p.x,p.y,rnd(2),clr)
		circfill(p.x,p.y,max(0,radius),clr)

		p.time *=.9
		p.time -=.01
		if (p.time <= 0) del(explosions,p)

	end
	for k, p in pairs(particles) do
		circfill(p.x,p.y,max(0,p.time/9),p.color)
	--	pset(p.x,p.y,p.color)
		p.time -=1
		if (p.time == 0) del(particles,p)
	end
end





starting_time = 120
starting = false

function start_setup()
	start = true
	add(bugs, skull())
end

function start_game()
	music(6)
	starting = true
end

function draw_manual()

	local ay = -120 + starting_time
	
	?"❎ x \f7shoot",-62,6+ay,14
	?"🅾️ z \f7dash",-62,14+ay,14
	
	
	?"\f0\#7start",-6,44+ay,6
	
	?"⬆️",44,2+ay,14
	?"⬅️⬇️➡️",36,8+ay,14
	?"move",40,16+ay,7



    --  for i=0,31/32,1/32 do
	--	local x=0+cos(i+t()/8)*30
	--	local y=-40+sin(i+t()/8)*4+ay
	--	local w=16+cos(i*1+t()/2)*4
	--	local h=12+sin(i*2+t()/2)*6
--
	--	--fillp(pattern[i*32])
	--	ovalfill(x-w,y-h,x+w,y+h, 0)
	--	-- (i*32)%8+8)
--
	--end

?"bunny survivor",-26,-36+ay,14
?"BY unikotoast\n1.9",-64, 48+ay,6
    -- pset(-26,-40+ay,8)
    -- pset(-28,-40+ay,8)

    -- pset(26,-44+ay,8)
    -- pset(28,-44+ay,8)




	for i=1,3 do
		?"\^t\^w\^t\^wbuns",-12+(i+1)%3,-48+sin(t()+i/3)+ay,({12,14,7})[i]
	end --flip()
       -- sspr(105, 64, 19, 6, -32, -48, 57, 18, false, false)

      --  add_particle(rnd(128)-64,-48,8,60)



	if (starting) then
		map_size += 8
		starting_time -= 1
		starting_time *= .90
	end
	if (starting_time <= 0) then
		start = false
		setup_enemy_waves()
	end
end

function skull()
	return {
		sprite = 12,
		death_sprite = 244,
		speed = 0, 
		hp = 30,
		aoe = 6,
		skull = true,
		death_item = start_game,
		life_time = 9999,
		no_teleport = true,
		pos = {x=0, y=34}
	}
end

--pattern={[0]=
--…,∧,░,⧗,▤,✽,★,✽,
--ˇ,░,▤,♪,░,✽,★,☉,
--░,▤,♪,░,✽,★,☉,…,
--∧,░,⧗,▤,✽,★,✽,★
--}



map_tiles = {}

function map_setup()
	for i=-32, 32 do
		map_tiles[i] = {}
		for j=-32, 32 do 
			random_tile(i,j)
		end
	end
end

shake = 0
shaking = 0

map_size = 60


function draw_map()
	mapx=flr(playerx/32)*32
	mapy=flr(playery/32)*32

	if (shake >0) shake -= 1

	if (shake > 0) then
		shaking = rnd(shake) - rnd(shake)
	else
		shaking = 0
	end

	camera((playerx)-64+shaking,(playery)-64+shaking)

	if (start) then
		local p = random_outside_point(rnd(),map_size+4,0,0)
		add_particle(p.x,p.y, 0, 80,.1)
	end
	circfill(0,0,map_size,3)

	for i=flr(playerx/8 -8), flr(playerx/8 + 8) do
		for j=flr(playery/8 -8), flr(playery/8 +8) do 

			if (map_tiles[i]) then
				local tile = map_tiles[i][j]
				if (tile and tile.sprite<10) then
					spr(tile.sprite, i*8, j*8)
				end
			end

		end
	end
end

function random_tile(x,y)
	if (map_tiles[x]==nil) then
		map_tiles[x] = {}
	end
	
	if (map_tiles[x][y]==nil) then
		local r = rnd(100)
		if (r < 7) then
			map_tiles[x][y] = {sprite = flr(rnd(9)), x=x*8, y=y*8}
		else
			map_tiles[x][y] = {sprite = 10} 
		end
	end
end



--#include collissions_spatial_hash.lua


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000011111111111111110777770007777700077777000000000000000000
0b000b00000000000000000000000000000700000000000000070000000000000000000000111100111111117777766077777660777776600000000000000000
00b00b0b00000000000000000000b0000079700000000000007a7000000000000000000020011002100110017117116071171160722722600117711011000011
b1b01b1b0000000000000000000b000000b7b0000000c000000700000000000000b0000012000021020000207117116078878860788788601277872112177121
0000000000aaa000700000000000b00000000000b0b00b00001b000000b0b000090b000011080811210808127771776077717760777877601177871100778700
00000000000a00000b00a00000b1b00b000000001b001b0000000000000b0000000b000011000111110001117766666077666660776666600007700000778700
00000000001b00000b000b0000000000000000000000000000000000001b0000001b000011111111111111110616160006161600068686000000000000077000
00000000000000001b0b1b0b00000000000000000000000000000000000000000000000011111111111111110000000000000000000000000000000000000000
0000000000000000000000000000000000eeeee000eeeee000eeeee000eeeee0000000000077700d000000000005900006777000077770000000000000000000
000000000000000000000000000000000000000000eeeeee00eeeeee00000000000000000717100d0077700d0019a9000d67777000777770000c00c000c00c00
000000000000000000000000000000000eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeee677770d06717100d0114941000d667770000007700ccc0cc00cc0cc0
0000000000000000000000000000000000000000eeeeeeeeeeeeeeee0000000000000000606067d0677770d001d14110000d66770000000700c1cc1c0c1cc1cc
00000000000000000000000000000000ee0eeee0ee0eee00ee0eee00ee0eee00ee0eee0000600000006067d001111d10000dd677000000070c11111c0c11111c
0000000000000000000000000111111000000000e0eeeee0e0eeeee0000000000000000007776000677700000111d11000dd6777000000070c17117c0c17117c
00000000000000000000000011111111000eee00000eee00000eee00000eee00000eee0060000700700060000f1111f00dd677700000007000c1111c00c1111c
0000000000000000000000000111111000000e0000000e0000000e0000000e00000000007000000000007000000000f0dd67700000000000000cccc0000cccc0
00000000000000000000000000000000000000000000000000000000000000000000000007a0000090090000000000000077770000777700000c0c000000000c
0000000000000000000000000000000000000000000660000000000000066000000000000009100000a00000000a5000077777700770007000cccc0c000c0c05
0008700000077000000e7000000e7000000e700007767600000660000776760000066000001d110000a9100000a7a10007766770070000000067670500cccc01
0088e70000ee770000e77700007e770000ee77007667665007767600766766100776760001d1111001d11110014a41107766d677770000000116660100676715
002288000088e70000887e000087ee000088ee006666d6657667665066661661766766c0011111101d11111101d41110776ddd67770000006011111501166605
000280000008e0000008e000000870000008e000dd6d66d56666d665116166616666c66c001111001111111101111d1076d00dd6770000000011110560111105
00000000000000000000000000000000000000000ddddd50dd6d66d501111610cc6c666c00f11f0001f11f100d11d1106d0000dd700000000111d1050111d105
0000000000000000000000000000000000000000000000000ddddd50000000000cccc6c000f0000000000f000d1111d00000000d00000000111dd105111dd100
00000000eee00eee0000000000e000000000000000700000000990000777c0000070000c70000c00770000000007000000067600000000000000000000000000
00000000e7e00e7e000e0000000000000f7ff7f00000700000999900000c7700c070000c7000077c077c0000007c00c000676650000000000000000000000000
00087000e7e00e7e00000000e0000e00ffffffffc00007c0009aa9000c0007c000c700c00770700077c00000c0777c000666c665008008000080000000000000
0088e700e7eeee7e0e07e00000000000777777770cc0007c099aa990000007c0000c707000777c007c00000000c007c00c6c666c087002200870002000000000
00228800e777777e000e700000e0000088bb999b07c0000009aaaa9000000c700000c700000700000777c0000000007005c776c5272008822700008208000000
00028000e7e77e7e00e00e0000000000044499470070000099a77a990c77c770c000c070007c000000c0777000c770c70000c700222008822220008227000002
00000000e777777e000000000e0000e0ffff97ff000000709aa77aa9c70c77000007c00000c7700000007c000c70077000007c70882022228820002222000002
000000000eeeeee000000000000000000f7ffff0000000000a7777a07c000000007000070000c7c0000c700000c00000000c70000ff0fff00f0000f08800f002
00000000000000000000009900000000000000000006da7700000000000000000000000000000000080080800eeee00000000b00a00a00000000000000000000
00000000000000000000b99400000000000b0b00000daa770000000002000000010000010007770000888880e799ee00000f99b00a99a990000000000b0b00a0
000000000000000000000b40b0000000009bb000006dadaa02000000001000010110008007774f708887777879999e6000f7940099a77a99eeeff70000bb9000
0000000000000000000000b00b9799400049bb0000deeaad01200010001108000000000077f4ff700877e7e7e9a5a50007777770a7797979000667000bb940a0
00000000000000000b000000bb7999990499900000d82ddd0011800000000000000000007999997008777777eeaa550006fff9609a7777770eee6677009999a0
000000000000000009b000000b949440099000000551dd000001112010001000000000007fffff70887e7ee702e22560006f96009797997700066667000099a0
0000000000000000994b0000b000000000000000d51000000011000000001012100000007444447000877ee7000002560006600099779977eeee55550a0aaa90
00000000000000009400000000000000001100005100000001000100000100000000100200000000080877770000002500666600099777770000000000000000
00770077077007700000000000000000000000000800800800000000000000000000000000088008000c07077200002700000700000bb0bb0000000000000000
0077007707770777007700770000000000000000000afa000000000000000000000000000800880000ccc777280cc082000056670000bbbb0000000000000000
007feef7007feef700777077700000000000000000af99a000077770000000000000000000000880c00ccc7700c00c0000507660000a3bb00000000000000000
00eeeeee000eeeeee007feef700000000000000008f994f8000717100000000007000000000088800c000cc00c0000c050005070007943bb007cc00000000000
0eeeefee00eeeefee0eeeeeeee0000000000000000bb4fa000077770000777700000000008889880ccc0c0cc0c0000c00005000007aaa40b07d1dc0007cccc00
0eef1f1e0eeef1f1eeeeeeefee00000000000000000bfa006000d0060007171000007770787988000c0ccc0000c00c00000005000aa940000c111c0071d1d1c0
0eeffffeeeeeffffeeeeef1f1e000000000000000800800800006600700777770d01071077788000c0c0c000280cc082050000009a94000000ccc0000ccccc00
0ee22200eeee2220000eeffff000000000000000000000000060000007007000700000d077780000cc0000c07200002700000500a90000000000000000000000
0ef1e1f0000f1e1f0000f2e100000000000000490000900000000000000000000000000000070000900000070000070702200000067770000000000049000099
00e111000000211000000112f000000000009494000494000000000000000000000700000000000009700a700000e777ee2220000d6777700000000093b00b34
000202000000002000000200000000000004999000099400b00000000000000000000000700000000097a700000e07777eee222000d66777000000000b0000b0
0077007707700770000000000000000000999940000499000b499440000000000000070000000000000a700000e0ee0e077eee22000d66770000000000000000
00770077077707770077007700000000bbb9440000099400bb99999900000000007000000000007000a7a7000e0ee0e0077eee22000dd6770000000000000000
007f77f7007f77f7007770777000000000bb9000000499000b9494400000000000000000000000000aa80a7000ee0e007eee222000dd6777000000000b0000b0
00777777000777777007f77f700000000b0b0000000bbb00b0000000000000000000000000000000a00000a90e00e000ee2220000dd677700000000093b00b39
07777f77007777f77077777777000000000b000000b0b0b00000000000000000000000000000a0000000000ae00e000002200000dd6770000000000094000094
077f1f170777f1f17777777f7700000000000000000000000000000000000000900000000009000a0770077000000707000bb0bb000000000000000000000bb0
077ffff77777ffff77777f1f1700000000000000500020200000000009000000000000000900a09a1cc01880000ee7770000bbb3000000000caaa9900bb0e200
077222007777222000077ffff0000000000000005000555000900000000000000000900aa00a90a91cc018800000077700093b3000007000ca000099e2002200
07f171f0000f171f000002710000000000000000050015100000000000090000a00000a09a7aa70a1cc0188000ee0ee00074933300777000c009900922000000
00e11100000021100000f112f0000000000000000500555000090000a00000a0000000000a0000a01ccc8880000000000799990300066600c0090099000000bb
000202000000002000000200000000000000000000551a100a000a0000000a00000000007090090701cc88007e7ee0000999400000060000cc09999000bb0e20
007707700077000770000000000000000000000000555d5000000000000000000000000007a90a70001110007770000049440000000000000cc0000c0e200220
00770770007770777007700077000000000000000020202000000000000000000000000000977a000000000077700000940000000000000000ccccc002200000
007f7f700007f7f70007770777000000000000000080000800080008000800000000000000000000000000100000000000100000000000000000000007600000
007777700007777700077f7f77000000000000000880088000800080000000000001000000000001000000110000000001100000000000000000000076607600
0077f77000077f770000777770000000000060608000880080000800800000000011000000000001100001111000000011110000000799000007990016176670
0771f17700771f17700077f770000000000077700008800800080008000800000011100000000011100011121100000112111000009979900099799051c66766
077fff770077fff7700771f177000000000017100080008000000080000000000011100008000012110011222110001122211000007999700079997066156666
077222770077222770077fff770000000000777008000800080008000800000001111100888001121100112221118111222110000002f2000002f20016ccc6d1
07f171f7007f171770077272f700000007771a10800080008000000080000000011121108f801112110012211118881111221000000fff00000fff000155ccd1
007111700007211f0000f1127000000077676d60000800000008000000080000012121118f811122110012212218f8122122100000000f00000f000000111110
00020200000000200000020000000000000000000000000000000000000000000121211ff2ff1221110012112218f81221121000008228000082280007600000
00770077077007700000000000000000500050500000000000000000000000000121121f222f22112100100221ff2ff122001000087222200872222076607600
0077007707770777007700770000000050005550000000000070700000000000012211f02f20f1122100000001f222f100000000272228822722288226276670
007fe7f7007feef700777077700000000500151000070700007770000000000001221000fff00022210000000f02f20f00000000222228822222288252866766
00eee777000eeee77007feef7000000005005550000777000087800000000000012200002f20000221000000000fff0000000000882222228822222266256666
0eeeef7700eeeef770eeeeee770000000055555007787800077760000000000001220000f2f00002210000000002f200000000000f1ff1f00f1ff1f02688866d
0eef1f170eeef1f17eeeeeef7700000000555d5006777600077600000000000001000000f0f0000001000000000f2f00000000000ffffff00ffffff0015588d1
0eeffff7eeeeffff7eeeef1f17000000006060600006000006000000000000000100000f0f00000001000000000f0f00000000000ff0000000000ff000111110
0ee22200eeee2220000eeffff00000000000000000000000000000000000000000000000000000000000000000f0f00000000000000000000700000000000000
0ef171f0000f171f0000027100000000000000000770770007707700000700700000000000000000000000000000000000000000007000700070007770000007
00e11100000021100000f112f0000000000008000777760007777600000c00c00000000000000000000000000000000000000000000707000000000000000007
00020200000000200000020000000000000880007777776077777760070c00c00000000000000000000000000000000000000000007700000000000000000000
007700770770000770000000000000000008800072272260711711600c0007000000000000000000000000000000000000000000007770007007000000000000
007700770777007770770000770000000080000078878860788788600c0c0c000000000000000000000000000000000000000000000770700007700070000000
0077ee770077ee77007770077700000000000000776866607761666000000c000000000000000000000000000000000000000000070007000700000700077000
00eeeeee00eeeeee0007eeee70000000000000000686860006161600000000000000000000000000000000000000000000000000000000007000070007000007
00eeeeee0eeeeeeee00eeeeee0000000000000000000000000000000000000000000000007c00000000000000008800000000000076000000077700000777000
00eeeeee0eeeeeeee0eeeeeeee000000000d700000cccc0000000000007ccc00007cc0007c000000000000000007770000088000766076000777770007777700
00eeeeee0eeeeeeee0eeeeeeee00000000dd77000c77ccc00000000007ccc00007c00000c0000000000000000771710007777700161766707778777077778770
00eeeeee00eeeeee00eeeeeeee0000000dddd770ccd7cdcc0c77ccc0cc1c00cccc00000c0000000000000000777797007771710051c667666778777067778770
00eeeeee000eeee0000eeeeee00000000555ddd0c1d11d1cccd7cdcccc1001ccc00000cc00000000000000007777870077779700661566666778777067778770
000eeee0000021100000eeee000000000055dd00c111111cc1d11d1ccc00ccccc0000ccc0000000c00000000777770007777800016ccc6d12677772026777720
000202000000002000000200000000000005d000cc1111cccc1111cc000cccc00000ccc0000000cc0000000009770000077900000155ccd10266720002667200
00770077077000077000000000000000000000000cccccc00cccccc0000000000000000000000cc0000000000009000009000000001111101111111011111110
007700770777007770770000770000000000bb0000000000000000000000cc00000c0c00000c0c00000000000000007700000000000000000000077007700000
00777777007777770077700777000000004bbb0000000000000000000c000000000000000000000000000000007707770000007700000000eee0077e077ee0ee
007777770077777700077777700000000224e20000dbdb0000dbdb0000000000c0000000c000000c90000440007e07e00077077700000000eeeee7feef7eeeee
007777770777777770077777700000002e2e7e200d9b35000d1b3500c000000cc000000c000000009900400400777770007e07e000000000eeeeeeeeeeeeeeee
007777770777777770777777770000002e2ee7200d99bb000d11bb000000000000000000c000000cc4909999ff77171700777770000000000eeeeeeefeeeeee0
007777770777777770777777770000002ee2ee200d5445000d511500c000000c0000000c0000000000499799ff7f777fff771717000000000eeeeef7f7eee000
0077777700777777007777777700000002eee2000055500000555000000000000c000000000000c0c0049799f77779b7f77f79bf0000000000eef0ffff0f0000
0077777700077770000777777000000000222000000000000000000000c0c000000c0c0000cc0000000044440777749007777490000000000000012221000000
00077770000021100000777700000000000000000000000000000000000000000000000000000000000bb0bb00000000000c7000000c70000000001e10000000
000202000000002000000200000000000000000000000000000000000000000000000000000000000000bbbb0000007700cc770000cc77000000001110000000
0077077000770007700000000000000000dbdb0000dbdb0000dbdb00077077000770770007707700000a3bb0007707770cc8c8700cc8c8700000002020000000
007707700077707770077000770000000d9b35000d9b35000d2135007ee7ee607ee7116071171160007943bb007e07e00111ccc00111ccc00000000000000000
007fef700007fef700077707770000000d99bb000d99bb000d211b006e828e606e8111606111116000aaa40b007777700011cc000011cc000000000000000000
00eeeee0000eeeee00077fef77000000d9944500d2144500d211150006222600062116000611160000a94000ff7717170001c0000001c0000000000000000000
00eefee0000eefee0000eeeee0000000d9455000d1155000d115500000d2d00000d1d00000d1d00000000000f77f79bf00000000000000000000000000000000
0ee1f1ee00ee1f1ee000eefee0000000555000005550000055500000000d0000000d0000000d0000001111000777749000011000000110000000000000000000
0eefffee00eefffee00ee1f1ee00000007700770000000000000000000888800000000000000000000000000880000cc00070007000000009000000700000070
0ee222ee00ee222ee00eefffee0000001cc018800aa00aa000000000080000800088880000000000000880008000000c0e700e700000000009700a7000700700
0ef1e1fe00ef1e1ee00ee2e2fe0000001cc018801cc01880000000008000000808000080000880000080080000800c00e70007000000a0000097a70090000000
00e111e0000e211f0000f112e00000001cc018801cc018800000000080077008080770800087780008077080000ee000000e7000000a7a00000a700000000000
000202000000002000000200000000001ccc88801cc018800000000080077008080770800087780008077080000ee00000e7e7000000a00000a7a70000000070
0077007707700007700000000000000001cc88001ccc8880000000008000000808000080000880000080080000c008000ee20e70000000000aa80a70000000a9
007700770777007770770000770000000011100001cc88000000000008000080008888000000000000088000c0000008e00000e200000000a00000a90a000000
0077777700777777007770077700000000000000001110000000000000888800000000000000000000000000cc0000880000000e000000000000000aa0000000
0077777700777777000777777000000007776600000000000800080000cccc0000000000000000000000000000000000000e7000000000000008700000000000
007777770e777777e0077777700000007887886008808800080008000c0000c000cccc0000000000000000000000000000ee7700000000000088770000087000
00e7777e0ee7777ee0e777777e000000788788600880880008000800c000000c0c0000c0007b7b00007b7b00000000000ee1e170000ee0000881817000887700
00eeeeee0eeeeeeee0ee7777ee000000088788000880880008000800c007700c0c0770c0079b3f00079b3f00000000000222eee00eee77e00222888008888770
00eeeeee00eeeeee00eeeeeeee000000777877600888880008000800c007700c0c0770c00799bb000799bb00000000000022ee000eeee7700022880002218180
00eeeeee000eeee0000eeeeee0000000000000000880880008000800c000000c0c0000c079944f0007f44f00000000000002e0000221e1e00002800000228800
000eeee0000021100000eeee000000000616160008808800080008000c0000c000cccc00794ff00000fff00000000000000000000222eee00000000000028000
0002020000000020000002000000000000000000000000000800080000cccc0000000000fff00000000000000000000000011000001111000001100000111100
__gff__
0000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300000907000070060703f970309703f50031600070000100000000000002e600266002e7002e7002e700265002d7002d7002c7002c700296002a6002b700214002b7002b7002b700000002a7002a70029700
000100000a0100e0101101016010190101c0101f01022010270102901012010100100d0100b0100a0100d0000c0000a0000800007000060000600006000050000400006000020000000000000000000000000000
000400000e050170501f0502b050060000b00013000290000b0000c000000000e0001000011000150001d00025000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000080200c02010020240001d00016000120000e00009000030000200000000000000600001500005000050000500005000050000500155001450013500115000f5000e5000d5000b5000a5000950007500
0001000015720190201b0003770025000240001f0001a000180001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000157201e020387003770025000240001f0001a000180001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009000025f3120e303ff3019f0218e0100e000040003400004001e100090020a000020000a000010000400000000000002d40000000000000000000000000000000000000000000000000000000000000000000
0020000007000090020a0010e00012000160021b0012000021000260002b0002f0003500238000180000000000000000000000000000000001a00000000000000000000000000000000000000000000000000000
000200003603039000240003e0003e0003c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002e0223f0212700033000180021f001240002200016000130001d0001b00218000180000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000000
0016000303020050200b0200b020060200b02002020070200b0200402006020020200302006020020200002000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000341302610023100010000000000000018003c10036100000003d100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a0100003b65030650156501b65018650176301a6401a6401a64019640176401364013640176401a6400c6401d630126300f6300e6200d6200962009620056200361002610006100161000600006000060000600
0005000013050150401c0501f05023040230302302023010230202301023020230002300023000230002300023000230002300023000230002300023000000000000000000000000000000000000000000000000
000200001d0101f0202103029020300102e0003d000320003d000360003c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d702000005053070530b05310053130531405315053140431204311043100430d0430a04309033070330503303023020230201301013010130201302013010130201301013010130101300003000030000300003
11050000050120601207022090320b0320d0421004211052130521505218052180521805218052180521805218055180551804518045180351803518025180250000200002000020000200002000020000200002
00040000313152e3252c3352934526345233551f3551d3551a3451633513325103150d3150b3150b3150b3150a0150902508025080350703506045050450304502035010250002500015000051e3051a30517305
000100000061001610016100161002610026000361004610056000060002600016000060000600016000060002600016000360001600016000260001600016000260000000000000000000000000000000000000
000900001b75015750107502670037700237002a70000000090000000009000000000900000000090000000009000000000900000000090000000009000000000900000000090000000009000000000900000000
00040000313252e3352c3552936526375233751f3751d3751a3751636513345103450d3350b3350b3250b3250a0150901508025080350704506055050650307502075010650004500025000551e3051a30517305
01140020213651a3451e345213551a3451e345153651a345213651a3451e345153551a3451e345153651a34521365183451c34515365183451c345153651834515355173451c34515365173451c3451536517345
000100001b01000600086002600000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000060110b0211003515035190351c0351c035280351c0353403526035300352403530035240253001524000240002400024000240002400024000240002400024000240002400024000240000000000000
00030000030300c030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000402004020040200002000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000060100601005010240001d00016000120000e00009000030000200000000000000600001500005000050000500005000050000500155001450013500115000f5000e5000d5000b5000a5000950007500
d702000005677076770b67710677136771465715657146471264711647106470d5470a14709137071370513703127021270211701117017170271702717017170271701717017170171700704007040070400004
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0108002013033000000060500000216050960000604000002461500000000000000013033000000e003000000e0030000000000000000e0030000000000000002461500000000000000000000000000000000000
0110000000010070100c0101301000010075100c5101351000010070100c0101301000010075100c5101351000510075100c5101301000010075100c5101351000010070100c0101301000010075100c51013510
0110000000510075100c7101301000510075100c5101301000010070100c7101371000010070100c5101301000010070100c7101371000010070100c010130100001007010007100771000010070100c71013710
011000000c51013510185101f5100c51013510180101f0100c01013010180101f0100c01013010180101f0100c01013010180101f0100c01013010180101f0100c01013010180101f0100c01013010180101f010
011000000c0101301018010130100c01013510185100c5100c0001301018010130100c000180101f010180100c0101301018010130100c01013510185100c5100c0001301018010130100c000180101f01024010
491000001812013120171101812017120131100c120131220000013120151101712200000151201711018122181201312017110181201712013110111201012211120101200e1100c12204100041000210002100
012010000002507025070250452207025070250702507522040250402504025045220202502025020250252200025070250702504025070250702507025070250b0250b0250b0250b02509025090250902509025
491000001812013120171101812017120131100c1201312200000181201a1101c122000001a1201c1101d1221d120181201c1101d1201c12018110171201512217120151201311011122101200e1100c12202100
0120100000025090250000009025090250000009025070250502507025000000702507025000000c0250000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013033000002461500000130330000013033000001303300000
011000001303300000000000000024615000001303300000000000000000000000002461500000130330000013033000000000024615130000000024615000001303324615000001300024615130001303305025
012010000702500025000000002500025000000000000025070250002500000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001a235162351323514235122350020012235002000a235002000020006235002000020002235052000a200092000220003200032000720000200022000020000200062000020000200002000020000200
011000001e3351a3351733518335163350430016335043000e33504300043000a335043000430006335093000a300093000230003300033000730000300023000030000300063000030000300003000030000300
014000000c5240c525135241352510524105250752407525155001550013500135001150011500105001050017500175001750000500185001850018500005000050000500005000050000500005000050000500
014000001552415525135241352511524115251052410525005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
0d1400000e2350223502235022350e2350223502235022350f2350223502235022350d2350223502235022350e2350223502235022350e2350223502235022351223502235112350223512235022351123502235
912810000233502135023350213502335021350233502135023350213502335021350233502135023350213500100001000010000100001000010000100001000010000100001000010000100001000010000100
011400000c133021350c1330213513433021350c133021350c133021350213513433021350c1330c133021350c133021350c1330213513433021350c133021350c133021350213513433021350c1330c13302135
01140000181221a1222112222122211221f122211222112221122211122112221112211222111222122211221f1221f12222122211221f1221f1121f1221f1121f1221f1121f1221f1120e122121221a1221b122
0d1400001223506235062350623512235062350623506235132350623506235062351123506235062350623512235062350623506235122350623506235062351623506235152350623516235062351523506235
011400000c133061350c1330613513433061350c133061350c133061350613513433061350c1330c133061350c133061350c1330613513433061350c133061350c133061350613513433061350c1330c13306135
01140000327222e7222a7222a712267222671232722327122e7222e712000002a7222a712000002672226712327222e7222a7222a712267222671232722327122e7222e712000002a7222a712000002672226712
011400000c100061000c1000610013400061000c100061000c100061000610013400061000c1000c100061000c100061000c1000610013400061000c1000c13313433061001343313400134330c1001343306100
01100000180321c0321f0321c0321f032240321f032240322803224032280322b032280322b032300320000030022000003001200000300120000000000000000000000000000000000000000000000000000000
01100000001320413200132041320713204132071320c132071320c13210132131321013213132001320011200112001120011200112001120011200112001120010000100001000010000100001000010000100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 15424344
01 1e204444
00 1e1f2044
00 1e21441f
02 1e204444
03 1e424344
01 1e246444
00 1e246244
00 1e242144
00 1e242144
00 1e242244
00 1e242244
00 1e242344
00 1e242563
00 1e242365
00 1e242565
00 26274344
00 28262044
00 28262144
00 28262344
00 28262544
00 28242c44
00 28242d44
00 28242c44
00 28242d44
00 282c2044
00 282d2144
00 282c2344
00 282d2544
00 282c2444
00 282d2644
02 29275f44
01 2e424344
00 2e2f4344
01 2e307044
00 2e307044
00 2e303144
00 2e303144
00 2e303444
00 2e303444
00 2e303144
00 2e303144
00 2e303444
00 2e303444
00 32337044
00 32337444
00 32333444
00 32333444
00 6e303144
00 6e303144
00 6e2f3444
00 2e2f3444
00 2e2f7544
02 2e2f3544
05 2a2b4344
00 36374344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
__label__
ccccccccccccccccccccccccccccc77777cccccccceeccccccccccceeeeeeeeeeeeeeeee888888ee887777788888888888888888888888888888888888888888
cccccccccccccccccccccccccccc7777777cccceeeecccecceccceeeeeeeeeeeeeeeeeeee8888888777777777788888888888888888888888888888888888888
ccccccccccccccccccccccccccc777777777ceeeeecccccccccceeeeeeeeeeeeeeeeeeeeee888887777777777778888888e88888888888888888888888888888
ccccccccccccccccccccccccce77777777777eeeeeccccccccceeeeeeeeeeeeeeeeeeeeeee888887777777777777888888ee8888888888888888888888888888
cccccccccccccccccccccccce777777777777eeeeecccccccceeeeeeeeeeeeeeeeeeeeeeeee88887777777777777788888eee888888888888888888888888888
cccccccccccccccccccccccee777777777777eeeeeeccccccceeeeeeeeeeeeeeeeeeeeeeeeee88877777777777777888888eee88888888888888888888888888
ccccccccccccccccccccceee7777777777777eeeeeecccccceeeeeeeeeeeeeeeeeeeeeeeeeee88877777777777777888888eee88888888888888888888888888
cccccccccccccccccccceeee7777777777777eeeeeecccccceeeeeeeeeeeeeeeeeeeeeeeeeeee8877777777777777788888eee88888888888888888888888888
ccccccccccccccccccceeeee7777777777777eeeeeeecccceeeeeeeeeeeeeeeeeeeeeeeeeeeee8877777777777777788888eeee8888888888888888888888888
cccccccccccccccceeeeeeee7777777777777eeeeeeeccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeee877777777777777788888eeee8888888888888888888888888
ccccccccccccccceeeeeeeee77777777777777eeeeeeeccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777788888eeee8888888888888888e88888888
cccccccccccccceeeeeeeee777777777777777eeeeeeeecceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777788888eeeee888888888888888ee8888888
ccccccccccccceeeeeeeeee777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777777777778888eeeeee888888888888888ee8888888
cccccccccccceeeeeeeeeee777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777888eeeeeee888888888888888eee888888
ccccccccccceeeeeeeeeeee777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777788eeeeeeeee88888888888888eee888888
ccccccccccceeeeeeeeeeee777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777eeeeeeeeeee88888888888888ee8888888
cccccccccceeeeeeeeeeeee7777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777eeeeeeeeeee888888888888888e88888888
cccccccccceeeeeeeeeeeeee777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777eeeeeeeeeee888888888888888e88888888
cccccccccceeeeeeeeeeeeee777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777eeeeeeeeeee888888888888888888888888
cccccccccceeeeeeeeeeeeee777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777eeeeeeeeeee888888888888888888888888
ccccccccceeeeeeeeeeeeeee7777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777777777eeeeeeeeeeeee88888888888888888888888
ccccccccceeeeeeeeeeeeeee7777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777eeeeeeeeeeeeeee888888888888888888888
ccccccccceeeeeeeeeeeeeeee7777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777eeeeeeeeeeeeee8888888888888888888888
ccccccccceeeeeeeeeeeeeeee7777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777777777eeeeeeeeeeeeeee8888888888888888888888
cccccccccceeeeeeeeeeeeeeee7777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777777777eeeeeeeeeeeeeee888888888ee88888888888
cccccccccceeeeeeeeeeeeeeee7777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777777777eeeeeeeeeeeeeeee8888888ee888888888888
cccccccccceeeeeeeeeeeeeeeee7777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777eeeeeeeeeeeeeeeeee88888ee888888888888
cccccccccceeeeeeeeeeeeeeeee7777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777777777eeeeeeeeeeeeeeeeeeee888ee8888888888888
cccccccccceeeeeeeeeeeeeeeeee777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777eeeeeeeeeeeeeeeeeeeeeeeee8888888888888
cccccccccceeeeeeeeeeeeeeeeee7777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777777777eeeeeeeeeeeeeeeeeeeeeeeee88888888888888
cccccccccceeeeeeeeeeeeeeeeeee7777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777eeeeeeeeeeeeeeeeeeeeeeee888888888888888
ccccccccccceeeeeeeeeeeeeeeeeee777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777777777eeeeeeeeeeeeeeeeeeeeeeeee888888888888888
ccccccccccceeeeeeeeeeeeeeeeeee7777777fff777777eeeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777eeeeeeeeeeeeeeeeeeeeeeee8888888888888888
ccccccccccceeeeeeeeeeeeeeeeeeee77777fffff77777eeeeeeeeeeeeeeeeeeeeeeeeeeee7777777777777eeeeeeeeeeeeeeeeeeeeeeeee8888888e88888888
ccccccccccceeeeeeeeeeeeeeeeeeeee7777ffffff77777eeeeeeeeeeeeeeeeeeeeeeeeeee7777fff777777eeeeeeeeeeeeeeeeeeeeeeeee888888ee88888888
ccccccccccceeeeeeeeeeeeeeeeeeeee7777fffffff7777eeeeeeeeeeeeeeeeeeeeeeeeee7777fffff7777eeeeeeeeeeeeeeeeeeeeeeeeeee8888ee888888888
ccccccccccceeeeeeeeeeeeeeeeeeeeee777ffffffff7777eeeeeeeeeeeeeeeeeeeeeeee7777ffffff777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888
ccccccccccceeeeeeeeeeeeeeeeeeeeeee777ffffffff777eeeeeeeeeeeeeeeeeeeeeee7777ffffff777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888
ccceccccccceeeeeeeeeeeeeeeeeeeeeeee777ffffffff77eeeeeeeeeeeeeeeeeeeeee777ffffffff77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888
ccccccccecceeeeeeeeeeeeeeeeeeeeeeeee777ffeeeeeeeeeeeeeeeeeeeeeeeeeeee777ffffffff77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888
ccccceeeecceeeeeeeeeeeeeeeeeeeeeeeeee777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefff77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888
ccccceeeccceeeeeeeeeeeeeeeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888888888
cccccceeccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888888888
cccccceeecceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888888
cccccceeecceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6eeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888888
ccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6eeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888888
cccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee666eeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888
ccccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeee66eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee66666eeeeeeeeeeeeeeeeeeeeeeeeee888888888888888
cccccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeee666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6e66666eeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
ccccccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeee6666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee666666666666eeeeeeeeeeeeeeeeeeeeeeee88888888888888888
cccccccccccceeeeeeeeeeeeeeeeeeeeeeeeeee666666666eeeeeeeeeeeeeeeeeeeeeeee666666666666666eeeeeeeeeeeeeeeeeeeeeee888888888888888888
cccccccccceeeeeeeeeeeeeeeeeeeeeeeeeee66666666666ee44eeeeeeeeeeeeeeeeee6666666666666666eeeeeeeeeeeeeeeeeeeeee88888888888888888888
00cccc00ccceeeeeeeeeeeeeeeeeeeeeeeeee66666eeeeeee4f4eeeeeeeeeeeeeeeeeee666666666666666eeeeeeeeeeeeeeeeeee88888888888888888888888
200cc002cccceeeeeeeeeeeeeeeeeeeeeeeee6eeeeeeeeeeefffeeeeeeeeeeeeeeeeeeeeeeeeeeeee2466eeeeeeeeeeeeeeeeee8888888888888888888888888
c200002cccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefffeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2466eeeeeeeeeeeeeeeeee888888888eeee88888888888
cc0808cccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefff4eeeeeeeeeeeeeeeeeeeeeeeeeeeeee244eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888888888
cc000cccccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee24eeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888888
ccccccccccccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee224eeeeeeeeeeeeeeeeeeeeeeeeeee88888888888888
cccccccccccccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeee2222eeeeeeeeeeeeeeeeeeeeeeeeee888888888888888
ccccccccccccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeee441111ffeeeeeeeeeeeeeeeeeeeeeeeeeeee22222eeeeeeeeeeeeeeeeeeeeeee88888888888888888
ccccccccccccccccceeeeeeeeeeeeeeeeeeeee2eeeeeee4fffffffff4eeeeeeeeeeeeeeeeeeeeeeeeeee22222eeeeeeeeeeeeeeeeeeee8888888888888888888
cccccccccccccccceeeeeeeeeeeeeeee2eeee22eeeeee44ffffffffffeeeefeeee4e4eeeeeeeeeeeeeee22222eeeeeeeeeeeeeeeeee888888888888888888888
ceeecccccccccceeeeeeeeeeeeeeeeee2eeee22eeeeee4fffffffffffeeeffeeee44eeeeefeeeeeeeeeee2222eeeeeeeeeeeeee8888888888888888888888888
ceeeeeeecccceeeeeeeeeeeeeeeeeee22ee2222eeeeeeffffffffffffffffffee4fffeeefffeeeeeeeeee22222eeeeeeeeeeeeee888888888888888888888888
cceeeeeeeeeeeeeeeeeeeeeeeeeeeee22ee2222eeeeeefff55555ffffffffffe4fff555e5ffeeeeeeeeeee2222eeeeeeeeeeeeee888888888888888888888888
cceeeeeeeeeeeeeeeeeeeeeeeeeeeee2222222eeeeee4f111111111ffffffffffff1111111feeeeeeeeeee2222eeeeeeeeeeeeeee88888888888888888888888
cceeeeeeeeeeeeeeeeeeeeeeeeeeee22222222eeeee4f1111ffffff1ffffffffff1ffffff11feeeeeeeeee22222eeeeeeeeeeeeeeee888888eee888888888888
cccceeeeeeeeeeeeeeeeeeeeeeeeee22222222eeee1111fff62266ffffffffffffff62266ff11111eeeeeee2222eeeeeeeeeeeeeeeeeeeeeeeee888888888888
cccccceeeeeeeeeeeeeeeeeeeeeeee2222222eeeee1111fff22776ffffffffffffff22776ff11111eeeeeee2222eeeeeeeeeeeeeeeeeeeeeeee8888888888888
cccccccceeeeeeeeeceeeeeee777ee2222222eeeeeeeefff622776fffffffffffff622776fffeeeeeeeeeee22222eeeeeeeeeeeeeeeeeeeee888888888888888
ccccccccccccccccceeeeeeee77722222222eeeeeeeeefff722227fffffffffffff722227ffffeeeeeeeeee222222eeeeeeeeeeeeeeeee888888888888888888
ccccccccccccccccceeeeeeee77722222222eeeeeeefffff722227fffffffffffff722227ffffffeeeeeeee222222eeeeeeeeeeeeeeeeee88888888888888888
ccccccccccccccccceeeeeeeeeee22222222eeeeeeefffff722227fffffffffffff722227ffffffeeeeeeeee22222eeeeeeeeeeeeeeeeeee8888888888888888
cccccccccccccccceeeeeeeeeeee22222222eeeeeeeffffff7227fffffffffffffff7227ffffffffeeeeeeee22222eeeeeeeeeeeeeeeeeee8888888888888888
cccccccccccccccceeeeeeeeeeee2222222eeeeeeeffffffffffffffffff4fffffffffffffffffffeeeeeeee22222eeeeeeeeeeeeeeeeeee8888888888888888
ccccccccccccccceeeeeeeeeeeee2222222eeeeeeef4ffffffffffffffffffffffffffffffffff4feeeeeeeee2222eeeeeeeeeeeeeeeeeee8888888888888888
ccccccccccccccceeeeeeeeeeeee2222222eeeeeeeffffffffffffffffffffffffffffffffffffffeeeeeeeee2222eeeeee8eeeeeeeeeeee8888888888888888
ccccccccccccceeeeeeeeeeeeeeee222222eeeeeeef44fffffffffffffffffffffffffffffffff44eeeeeeeee222eeeeee888eeeeeeeeeee8888888888888888
ccccccccccccceeeeeeeeeeeeeeee222222eeeeeee400fffffffffffffffffffffffffffffffff04eeeeeeeee222eeeee88888eeeeeeeeee8888888888888888
ccccccccccccccceeeeeeeeeeeeee222222eeeeeee000ffffffffffffffffffffffffffffffff000eeeeeeeee222eeeee088888eeeeeeeee8888888888888888
ccccccccccccccceeeeeeeeeeeeeee2222eeeeeeee000ffffffffff422222222224ffffffffff000eeeeeeeee222eee00000000eeeeeeeee8888880088880088
ccccccccccccccceeeeeeeeeeeeeeee222eeeeeeee0000ffffffffff2222222222fffffffff00000eeeeeeeee22eeee00000000eeeeeeee88888882008800288
ccccccccccccccceeeeeeeeeeeeeeee222eeeeeeee0000ffffffffff2222222222fffffffff00000eeeeeeee222eeee0000000eeeeeeeee88888888200002888
cccccccccccccccceeeeeeeeeeeeeeee22eeeeeeee00000ffffffffff2222222ffffffffff000000eeeeeeee22eeeee0000000eeeeeeee888888888c0c088888
ccccccccccccccccceeeeeeeeeeeeeeee2eeeeeeee000000fffffffffff2222ffffffffff0000000eeeeeeee2eeeeee000000eeeeeeee8888888888800088888
c00cccc00cccccccceeeeeeeeeeeeeeeeeeeeeeeee00000000fffffffffffffffffffff000000000eeeeeee2eeeeeee000000eeeeeeee8888888888888888888
c200cc002ccccccccceeeeeeeeeeeeeeeeeeeeeeee000000000ffffffffffffffffffff000000000eeeeeeeeeeeeeee000000eeeeeee88888888888888888888
cc200002ccccccccccceeeeeeeeeeeeeeeeeeeeeee00000000002fffffffffffffff000000000000eeeeeeeeeeeeeee000000eeeee0000888888888888888888
ccc0808cccccccccccceeeeeeeeeeeeeeeeeeeeeeee0000000022222ffffffffff22200000000000eeeeeeeeeeeeeee000000000000000088888888888888888
ccc000cccccccccc0000eeeeeeeeeeeeeeeeeeeeeee0000000222222222222222222222000000000eeeeeeeeeeeeeee000000000000000008888888888888888
cccccccccccc000000000eeeeeeeeeeeeeeeeeeeeee0000002222222222222222222222200000000eeeeeeeeeeeeeee000000000000000000888888888888888
cccccccccc000000000000eeeeeeeeeeeeeeeeeeeeeee00022222222222222222222222200000000eeeeeeeeee0eeee000000000000000000088888888888888
ccccccccc00000000000000eeeeeeeeeeee0eeeeeeeeee00222222222222222222222222200000eeeeeeeeeee00eee000000bbbb000000000008888888888888
cccccccc00000000000000000eeeeeeeeee00eeeeeeeeee0222222222222222222222222200000eeeeeeeeeee00eee00000b77bbb00000000008888888888888
cccccccc007777700000000000eeeeeeeeeee0eeeeeeeeeeee2222222222222222222222111eeeeeeeeeeeee000ee00000bb17b1bb0000000008888888888888
ccccccc00777776600000000000eeeeeeeeeee0eeeeeeeeee112222222222222222222111eeeeeeeeeeeeee00000000000b313313b0000000000888888888888
ccccccc007887886000000000000eeeeeeeeee00eeeeeeeeee1111122222222222222111eeeeee111eeee0000000000000b333333b0000000000088888888888
ccccccc00788788600000000000000eeeeeeeeee111111111111111111222222212111111111111111181e000000000000bb3333bb0000000000088888888888
cccccc00077787760000000000000000eeeeeee111111111111111111111111111111111111111111111800000000000000bbbbbb00000000000088888888888
cccccc000776666600000000000000000c1111111111111111111111111111111111111111111111111118000000000000000000000000000000088888888888
cccccc00006868600000000000000000cc1111111111111111111111111111111111111111111111111111880000000000000000000000000000008888888888
cccccc00000000000000000000000000c111111111111111111111111111ee111111111111111111111111118000000000000000000000000000008888888888
cccccc0000000000077777000000000c111111111111111111111111111eeee11111111111111111111111111800000000000000000000000000008888888888
cccccc000000000077777660000000c111111111111111111111111111ee11ee1111111111111111111111111180000000000000000000000000008888888888
cccccc00000000007117116000000c111111111111111111111111111ee1871ee111111111111111111111111118000000000000000000000000008888888888
ccccccc00000000070070060000cc111111111111111111111111111ee188771ee1111111111111111111111111180000000000000000bbbb000008888888888
ccccccc0000000007771776000c1111111111111111111111111111ee18888771ee11111111111111111111111111800000000000000b77bbb00008888888888
ccccccc000000000776666600cc1111111111111111111111111111ee12228881ee1111111111111111111111111118800000000000bb17b1bb0008888888888
cccccccc0000000006161600c1111111111111111111111111111111ee122881ee11111111111111111111111111111180000000000b313313b0088888888888
cccccccc000000000000000cc11111111111111111111111111111111ee1281ee111111111111111111111111111111118000000000b333333b0088888888888
cccccccc00000000000000c11111111111111111111111111111111111ee11ee1111111111111111111111111111111111800000000bb3333bb0088888888888
ccccccccc00000000000cc1111111111111111777777777117771117771e777777111111117777771111111111111111111800000000bbbbbb00888888888888
cccccccccc000000000c111111111111111111777777777117771117771177777711111111777777111111111111111111118000000000000000888888888888
cccccccccc0000000cc1111111111111111111777777777007770017770077777700111111777777001111111111111111111800000000000000888888888888
ccccccccccc0000cc111111111111111111111777000777007770017770077700077711777110000001111111111111111111180000000000008888800888800
ccccccccccc0000c1111111111111111111111777000777007770017770077700077711777110000001111111111111111111118000000000088888820088002
cccccccccccc00c11111111111111111111111777001777007770017770077700177700777001111111111111111111111111111800000000088888882000028
ccc00cccc00c0c11111111111111111111111177777711000777001777007770017770077777777711111111111111111111111118000000088888888c0c0888
ccc200cc002ccc111111111111111111111111777777110007770017770077700177700777777777111111111111111111111111118000008888888888000888
cccc200002cccc111111111111111111111111777777001117770017770077700177700777777777001111111111111111111111111800088888888888888888
ccccc0808cccccc11111111111111111111111777000777117770017770077700177700110000777001111111111111111111111111180088888888888888888
ccccc000cccccccc1111111111111111111111777000777117770017770077700177700110000777001111111111111111111111111118888888888888888888
ccccccccccccccccc111111111111111111111777001777007770017770077700177700111111777001118111111111111111111111888888888888888888888
cccccccccccccccccc1111111111111111ccc1777777777001107777770077700177700777777777001118811111111111111111118888800888800888888888
ccccccccccccccccccc11111111111111ccccc777777777001107777770077700177700777777777001118881111111111111111888888820088002888888888
ccccccccccccccccccccc1111111111cc00ccc777777777001117777770077700177700777777777001118888111111111111118888888882000028888888888
ccccccccccccccccccccccc1111111c0000ccc11000000000111110000001100011100011000000000111880081111111111118888888888c0c0888888888888
ccccccccccccccccccccccccc1111c000000ccc10000000001111100000011000111000110000000001118000088111111118888888888888000888888888888