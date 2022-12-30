pico-8 cartridge // http://www.pico-8.com
version 37
__lua__
-- terra nova pinball
-- ricochet around an alien world

-- terra nova pinball by matt sutton is licensed under a creative commons attribution-noncommercial 4.0 international license.
-- https://creativecommons.org/licenses/by-nc/4.0/legalcode

-- main
tracker_cols={5,13}

col_grads={
 split("0,0,5,13,6,7"),
 split("0,0,5,3,11,11"),
 split("0,0,2,8,14,15"),
 split("0,0,4,9,10,10"),
 split("0,0,1,13,12,12")
}


function _init()
 f=0

 version="1.2.0"
 cartdata("xietanu_terranovapinball_v1")
 if dget(0) == 0 then
  gen_highscores()
 end
 read_highscores()

 paddle_controls={
  {
   l=⬅️,
   r=➡️,
   ls="⬅️",
   rs="➡️"
  },
  {
   l=⬅️,
   r=🅾️,
   ls="⬅️",
   rs="🅾️"
  },
  {
   l=❎,
   r=🅾️,
   ls="❎",
   rs="🅾️"
  },
  {
   l=🅾️,
   r=❎,
   ls="🅾️",
   rs="❎"
  },
  {
   l=🅾️,
   r=➡️,
   ls="🅾️",
   rs="➡️"
  }
 }

 button_cols={}
 button_cols["🅾️"]=9
 button_cols["❎"]=8
 button_cols["➡️"]=12
 button_cols["⬅️"]=12

 pc_option=1

 modes={
  game={
   init=init_game,
   update=update_game,
   draw=draw_game
  },
  title={
   init=init_title,
   update=update_title,
   draw=draw_title
  },
  menu={
   init=init_menu,
   update=update_menu,
   draw=draw_menu
  },
  launch={
   init=init_launch,
   update=update_launch,
   draw=draw_game
  },
  game_over={
   init=init_game_over,
   update=update_game_over,
   draw=draw_game_over
  },
  logo={
   init=init_logo,
   update=update_title,
   draw=draw_logo
  },
  highscores={
   init=pass,
   update=update_highscores,
   draw=draw_highscores
  }
 }
 mode = modes.logo
 mode.init()
 music(3,0,1)
 menuitem(4,"music on",toggle_music)
end

function _update60()
 f+=1

 if transitioning then
  update_transition()
 end

 mode.update()
end

function _draw()
 cls()
 if show_stars then
  for _s in all(stars) do
   pset(_s.x,_s.y,_s.c)
  end
 end
 if show_credits then
  print_version_credits()
 end
 if transitioning then
  draw_transition()
 end
 mode.draw()
 pal()
end

function gen_highscores()
 dset(0,1)
 for i=1,40 do
  if i%4==0 then
   dset(i,13)
  else
   dset(i,0)
  end
 end
 dset(3,1)
 for i=0,9 do
  dset(6+i*4,900-i*100)
 end
end

function read_highscores()
 highscores={}
 for i = 0,36,4 do
  add(highscores,{dget(1+i),dget(2+i),dget(3+i),c=dget(4+i)})
 end
end

function write_highscores()
 for i=0,9 do
  for j=1,3 do
   dset(i*4+j,highscores[i+1][j])
  end
  dset(i*4+4,highscores[i+1].c)
 end
end

function toggle_music()
 local music_option
 music_off=not music_off
 if music_off then
  music_option="music off"
  music(-1,1000)
 else
  music_option="music on"
  music(3,0,1)
 end
 menuitem(4)
 menuitem(4,music_option,toggle_music)
end



--draw
--#include draw/draw_collider.p8
function draw_spr(_obj)
 local _spr=_obj.spr_coords
 if _obj.hit > 0 and not transitioning then
  _spr=_obj.hit_spr_coords or _spr
  pal(_obj.unlit_col or 8,9)
  _obj.hit-=1
 elseif _obj.lit and not transitioning then
  pal(_obj.unlit_col or 8,10)
 end
 local _off=_obj.origin:plus(_obj.spr_off)
 local _w,_h=_obj.spr_w,_obj.spr_h
 sspr(_spr.x,_spr.y,_w,_h,_off.x,_off.y,_w,_h,_obj.flip_x,_obj.flip_y)
 if not transitioning then
  pal()
 end
end


function print_shadow(
 _text,
 _x,
 _y,
 _col,
 _s_col
)
 -- print text with drop shadow
 for i=-1,1 do
  for j=-1,1 do
   print(
    _text, _x+i, _y+j, _s_col
   )
  end
 end
 print(_text, _x, _y, _col)
end



--modes
function init_game()
 show_stars = false
 got_highscore = 0
 balls=3
 planet_lights_lit=0.75

 msg=""

 msgs={}
 ongoing_msgs={}
 launch_msg={
  "⬆️/⬇️:",
  " set power",
  "🅾️: launch"
 }

 init_table()

 action_queue={}

 score=init_long(3)
end

function update_game()
 for _s in all(static_colliders) do
  _s.c=6
 end

 dt=1
 for _f in all(flippers) do
  dt=max(dt,update_flipper(_f))
 end

 for pinball in all(pinballs) do
  dt=max(dt,update_pinball_spd_acc(pinball))
  for _t in all(pinball.trackers) do
   _t.l-=0.5
   if _t.l < 0 then
    del(pinball.trackers,_t)
   end
  end
 end

 for i=1,dt do
  
  for _f in all(flippers) do
   update_flipper_pos(_f,dt)
  end
  for pinball in all(pinballs) do
   if not pinball.captured then
    for _f in all(flippers) do
     check_collision(pinball,_f)
    end
    update_pinball_pos(pinball,dt)
   end
  end
 end

 update_spinner()

 for _action in all(action_queue) do
  _action.delay -= 1
  if _action.delay <= 0 then
   del(action_queue,_action)
   _action.func(unpack(_action.args))
  end
 end
 
 if #pinballs==0 then
  if balls == 0 and not reset_light.lit then
   end_target_hunt()
   mode = modes.game_over
   mode.init()
   return
  end
  mode=modes.launch
  mode.init()
 end

 if #msgs > 0 then
  msgs[1].t-=1
  if msgs[1].t <= 0 then
   del(msgs,msgs[1])
  end
 end

 planet_lights_lit=max(planet_lights_lit-0.0025,0.75)
 set_planet_lights()
end

function draw_game()
 draw_backboard()

 draw_table()

 if #msgs > 0 then
  local _m=msgs[1]
  for i=1,#_m do
   print(_m[i],83,31+i*8,get_frame({10,7,12,7},_m.t,15))
  end
 elseif #ongoing_msgs > 0 then
  local _m=ongoing_msgs[#ongoing_msgs]
  for i=1,#_m do
   print(_m[i],83,31+i*8,10)
  end
 end

end

function pass()
end

function draw_backboard(_score_col)
 _score_col = _score_col or 10
 fillp(0b1101000010110000.1)
 rectfill(81,0,127,127,5)
 fillp()

 rectfill(81,16,127,47,1)
 spr(112,80,18,6,2)
 
 rect(81,0,127,127,5)
 rect(81,0,127,15,5)
 rect(81,36,127,63,5)
 rectfill(82,1,126,14,0)
 rectfill(82,37,126,62,0)

 sspr(1,80,47,48,82,72)
 sspr(1,80,47,48,81,72)

 print_long(score,84,2,5,_score_col)
 print("balls:",84,9,10)
 print(balls,122,9,10)
end


function init_title()
 show_stars = true
 show_credits = true
 f = 0
 off_y=0
end

function update_title()
 rotate_stars()
 if btnp(⬇️) or btnp(❎) or btnp(🅾️) then
  sfx(16)
  mode=modes.menu
  mode.init()
 end
end

function rotate_stars(_angle)
 stars=rotate_pnts(stars,vec(64,150+off_y/2.5),_angle or -0.0005)
end

function draw_title()
 draw_title_foreground(off_y)

 if off_y==0 and f%60>20 then
  print_shadow("⬇️",60,110,7,1)
 end
end

function draw_title_foreground(_y_off)
 spr(112,40,30+_y_off,6,2)
 spr(160,40,48+_y_off,6,6)
end


function init_menu()
 show_stars = true
 show_credits = false
 f_base=f
 options={
  {func=function()
   init_transition(modes.game)
  end,
  text={"start"},
  base_y=75
  },
  {
   text={"highscores"},
   base_y=85,
   func=function()
    init_transition(modes.highscores)
   end
  },
  {
   text={"paddle controls:"},
   base_y=95,
   func=function()
   pc_option=mod(
    pc_option+1,
    #paddle_controls
   )
   end
  }
 }
 selected_option=1
 pad_con=paddle_controls[pc_option]
end

function update_menu()
 off_y=max(-28,-(f-f_base))

 rotate_stars(-0.00025)

 if mode==modes.transition then
  return
 end

 update_menu_items()

 if selected_option == 3 then
  pc_option=mod(
  pc_option+tonum(btnp(➡️))-tonum(btnp(⬅️)),
  #paddle_controls
 )
 end

 pad_con=paddle_controls[pc_option]
end

function update_menu_items()
 if btnp(⬇️) or btnp(⬆️) then
  selected_option=mod(
   selected_option+tonum(btnp(⬇️))-tonum(btnp(⬆️)),
   #options
  )
  sfx(0)
 end

 if btnp(🅾️) or btnp(❎) then
  options[selected_option].func()
  sfx(13)
 end
end

function draw_menu()
 draw_title()
 print_version_credits()

 draw_menu_items(32,28+off_y,true)

 local _off_y_m4=off_y*4

 sspr(
  16,44,
  11,11,
  51,214+_off_y_m4
 )
 sspr(
  16,44,
  11,11,
  66,214+_off_y_m4,
  11,11,
  true
 )
 print_shadow(pad_con.ls,52,228+_off_y_m4,button_cols[pad_con.ls],1)
 print_shadow(pad_con.rs,68,228+_off_y_m4,button_cols[pad_con.rs],1)
 if selected_option == 3 then
  print(chr(22),40.5+sin(f/60),222.5+_off_y_m4+cos(f/143),7)
  print(chr(23),84.5+sin(f/60),222.5+_off_y_m4+cos(f/143),7)
 end
end


function init_launch()
 cur_pinball=create_pinball(vec(74,75))
 
 if reset_light.lit then
  add(msgs,{"relaunch",t=90})
  cur_pinball.spd = vec(0,-3.5)
 else
  balls-=1
 end
 reset_light.lit = not reset_light.lit
 add(ongoing_msgs,launch_msg)
 released=false
 del(always_colliders,launch_block)

 refuel_lights_lit=-1
 light_refuel_lights()

 disable_bonus(kickouts[2])
 disable_bonus(kickouts[3])

 reset_drain(left_drain)
 reset_drain(right_drain)
 multiplier = 1
end

function update_launch()
 modes.game.update()

 launcher.origin.y=limit(
  launcher.origin.y+(tonum(btn(⬇️))-tonum(btn(⬆️)))/4,
  80,
  100
 )
 if (btn(⬇️) or btn(⬆️)) and f%7==0 then
  sfx(22)
 end
 if cur_pinball.origin.y>=launcher.origin.y then
  cur_pinball.origin.y=launcher.origin.y-0.51
  cur_pinball.last_pos.y=launcher.origin.y-0.511
 end
 if btnp(🅾️) or btnp(❎) then
  sfx(8)
  if cur_pinball.origin.y >78 then
   cur_pinball.spd.y=-sqrt(launcher.origin.y-80)
   cur_pinball.origin.y = 78
  end
  launcher.origin.y=80
 end
end


function init_game_over()
 end_flash_table(static_over)
 end_flash_table(static_under)
 options = {
  {
   text={"play","again"},
   func=quick_restart,
   base_y = 0
  },
  {
   text={"menu"},
   func=game_over_to_menu,
   base_y = 20
  }
 }

 selected_option = 1

 for i=1,10 do
  if is_bigger_long(score,highscores[i]) then
   score.c=10
   add(highscores,score,i)
   del(highscores,#highscores)
   write_highscores()
   got_highscore=i
   return
  end
 end
 if got_highscore > 0 then
  sfx(16)
 else
  sfx(31)
 end
end

function update_game_over()
 update_menu_items()
end

function draw_game_over()
 local _fc = get_frame({10,7,12,7},f,10)
 draw_table()
 draw_backboard(_fc)
 
 if f>10000 then
  f=0
 end

 local _lb = min(94,f*2)
 
 clip(81,36,47,_lb)

 rect(81,36,127,36+_lb,5)
 rectfill(82,37,126,126,0)

 print("game over!",84,39,10)

 draw_menu_items(90,51)
 if got_highscore>0 then
  print("new #"..got_highscore,84,114,_fc)
  print("highscore!",84,120,_fc)
 end
 clip()
end

function quick_restart()
 mode = modes.game
 mode.init()
end

function game_over_to_menu()
 init_transition(modes.menu)
end

function draw_menu_items(_x,_y_off,_i_multi)
 for i=1,#options do
  local _o=options[i]
  local _y = _o.base_y
  if _i_multi then
   _y+=_y_off*(i*2)
  else
   _y+=_y_off
  end
  if selected_option == i then
   print(chr(23),_x-5.5+sin(f/60),_y+(3*(#_o.text-1)),8)
   local _yo = 0
   for _text in all(_o.text) do
    print_shadow(_text,_x,_y+_yo,7,8)
    _yo+=6
   end
  else
   local _yo = 0
   for _text in all(_o.text) do
    print(_text,_x,_y+_yo,7)
    _yo+=6
   end
  end
 end
end


function init_logo()
 stars={}
 for i=1,400 do
  local star=vec(
   flr(rnd(400))-136,
   flr(rnd(400))-66
  )
  star.c=rnd(split("12,7,6,5,13,15,1"))
  add(stars,star)
 end

 show_stars=true
 show_credits=true

 off_y=0

 modes.title.init()
end

function draw_logo()
 local max_col = limit(flr(f/4)+1,0,6)

 if f == 90 then
  init_transition(modes.title)
 elseif f < 90 then
  for grad in all(col_grads) do
   for i=1,6 do
    pal(grad[i],grad[min(i,max_col)])
   end
  end
 end

 spr(68,29,56,2,2)
 
 print_shadow("spaghettieis",47,59,7,8)
 print_shadow("games",47,65,7,8)
end

function print_version_credits()
 print("v "..version,2,2+off_y,13)
 print("by matt sutton",71,2+off_y,13)
 print("@xietanu",95,10+off_y,13)
end


function init_transition(_next_state)
 next_state = _next_state
 transitioning=true
 t=-1

 update_transition()
end

function update_transition()
 t+=1
 if t==30 then
  mode = next_state
  mode.init()
 elseif t>=60 then
  transitioning=false
  return
 end

 max_col=limit(flr(abs(30-t)/4),0,6)
end

function draw_transition()
 for grad in all(col_grads) do
  for i=1,6 do
   pal(grad[i],grad[min(i,max_col)])
  end
 end
end


function init_highscores()
 reset_highscores_cnt=0
end

function update_highscores()
 rotate_stars()
 if btnp(❎) then
  init_transition(modes.menu)
 end
 if btn(🅾️) then
  reset_highscores_cnt+=0.5
  if reset_highscores_cnt>=61 then
   gen_highscores()
   read_highscores()
   reset_highscores_cnt=0
  end
 else
  reset_highscores_cnt=0
 end
end

function draw_highscores()
 print_shadow("highscores",44,3,7,8)
 for i = 1,10 do
  print(i..".",35,10*i+2,12)
  print_long(highscores[i],50,10*i+2,5,highscores[i].c)
 end
 print_shadow("❎: back",7,114,7,13)
 if reset_highscores_cnt>0 then
  rectfill(62,112,61+reset_highscores_cnt,120,8)
 end
 print_shadow("hold 🅾️: reset",64,114,7,13)
end



--components
function init_flippers()
 -- initialize flippers
 flippers={
  create_flipper(
   vec(29.5,118.5),
   pad_con.l,
   false,
   shift_light_left
  ),
  create_flipper(
   vec(50.5,118.5),
   pad_con.r,
   true,
   shift_light_right
  )
 }
end

function create_flipper(
 _origin,
 _button,
 _flip_x,
 _shift_light
)
 -- create a flipper
 local _flip=1
 local _base_angle=0
 local _spr_off=vec(-1,-5)
 if _flip_x then
  _spr_off.x=-9
  _flip*=-1
  _base_angle=0.5
 end
 local _f = {
  origin=_origin,
  simple_collider=create_box_collider(
   -7+5*_flip,-6,
   7+5*_flip,6
  ),
  collider_base=gen_polygon(
   "-2,-1,-1,-2,9.5,-1,10.5,0,9.5,1,-1,2,-2,1"
  ),
  check_collision=check_collision_with_flipper,
  spr_off=_spr_off,
  angle=0,
  angle_inc=0.07,
  button=_button,
  moving=0,
  bounce_frames=0,
  c=12,
  flip_x=_flip_x,
  flip=_flip,
  complete=true,
  shift_light=_shift_light
 }
 _f.collider = _f.collider_base
 
 return _f
end

function update_flipper(_f)
 -- update flipper each frame
 if btn(_f.button) then
		if _f.angle<0.09 then
			_f.moving=1
		else
			_f.moving=0
		end
	else
		if _f.angle> -0.09 then
			_f.moving=-1/3
		else
			_f.moving=0
		end
	end

 if btnp(_f.button) then
  _f.shift_light(top_rollovers.elements)
  sfx(0)
 end

 return ceil(_f.moving*5)
end

function update_flipper_pos(_f,_dt)
 -- update the position of the
 -- flipper each time the
 -- physics sim is updated
 if _f.moving!=0 then
  _f.angle=limit(
   _f.angle+_f.moving*_f.angle_inc/_dt,
   -0.09,
   0.09
  )
  update_flipper_collider(_f)
 end
end

function check_collision_with_flipper(_f,_pin)
 -- check collision with line
 -- segments of flipper
 if _f.moving==0 then
  check_collision_with_collider(_f,_pin)
  return
 end

 if point_collides_poly(_pin.origin,_f) then
  local _flp_spd = 2*_f.moving*dist_between_vectors(
   _f.origin,_pin.origin
   )*sin(-_f.angle_inc)
  local _flp_spd_vec = vec(
   _f.flip*_flp_spd*sin(-_f.angle+.035),
   _flp_spd*cos(_f.angle-.035)
  )
  rollback_pinball_pos(_pin)
  _f.angle=limit(
   _f.angle-_f.moving*_f.angle_inc/dt,
   -0.09,
   0.09
  )
  _pin.spd=_pin.spd:plus(_flp_spd_vec)
  update_flipper_collider(_f)
  _f.moving=0
  update_pinball_pos(_pin,dt)
 end
end


function update_flipper_collider(_f)
 -- update the vertex points
 -- based on the angle of the
 -- flipper.
 local _ang=_f.angle
 if _f.flip_x then
  _ang=0.5-_ang
 end
	_f.collider=rotate_pnts(
		_f.collider_base,
		vec(0,0),
		_ang
	)
end

function draw_flipper(_f)
 -- draw a flipper
 local i=4-flr(
  4.99*(
   _f.angle+0.09
  )/0.18
 )
 
 -- if draw_outlines then
 --  draw_collider(_f)
 -- end

 sspr(
  16,
  0+11*i,
  11,
  11,
  _f.origin.x+_f.spr_off.x,
  _f.origin.y+_f.spr_off.y,
  11,
  11,
  _f.flip_x
 )
end


function init_walls()
 -- initialize outer walls

 wall_groups = {
  --right side
  "50,127,64,113,64,119,65,122,66,119,66,88,63,85,67,81,63,70,69,60,69,57,67,57,62,61,53,47,53,46,56,43,62,41,68,38,72,34",
  --left/top side
  "75,27,75,21,71,14,64,7,54,2,48,1,34,1,26,3,18,7,13,12,10,17,9,26,10,37,14,47,9,55,9,58,16,62,16,63,12,81,16,85,13,88,13,119,14,121,15,119,15,113,29,127",
  --inner curve right
  "61,25,61,22,58,19,54,19,54,14,60,15,66,18,68,21,68,25,66,28,59,34,58,32,61,25",
  --inner curve left
  "24,43,18,37,14,28,14,25,17,18,22,13,24,12,24,16,26,16,26,19,20,25,20,33,25,43,24,43",
  --lower right floating corner
  "48,122,64,106,64,93,63,92,61,94,61,105,53,112,48,117.5,48,122",
  --lower left floating corner
  "31,122,15,106,15,93,16,92,18,94,18,105,26,112,31,117.5,31,122",
  --narrow walls
  "30,15,31,14,32,15,32,18,31,19,30,18,30,15",
  "36,15,37,14,38,15,38,18,37,19,36,18,36,15",
  "42,15,43,14,44,15,44,18,43,19,42,18,42,15",
  "48,15,49,14,50,15,50,18,49,19,48,18,48,15"
 }
 for wall_group in all(wall_groups) do
  local _pnts = gen_polygon(wall_group)
  local _wall_list = {}
  for i=2,#_pnts do
   local _poly={_pnts[i-1],_pnts[i]}
   add(_wall_list,_poly)
  end
  for wall_col in all(_wall_list) do
   add(
    static_colliders,
    {
     origin=vec(0.5,0.5),
     collider=wall_col,
     simple_collider=gen_simple_collider(wall_col),
     check_collision=check_collision_with_collider
    }
   )
  end
 end
end


function create_pinball(_pos)
 -- create a pinball
 local _p = {
   origin=_pos,
   last_pos=_pos:copy(),
   spd=vec(0,0),
   spd_mag=0,
   simple_collider=create_box_collider(
    -1.5,-1.5,
    1.5,1.5
   ),
   check_collision=check_collision_with_pinball,
   captured=false,
   trackers={}
  }
 add(
  pinballs,
  _p
 )
 return _p
end

function update_pinball_spd_acc(_pin)
 _pin.spd=_pin.spd:multiplied_by(0.995)
 _pin.spd.y+=0.03
 _pin.spd_mag=_pin.spd:magnitude()

 local _dt = min(
  ceil(
   _pin.spd_mag
  ),
  4
 )

 return _dt
end

function update_pinball_pos(_pin,_dt)
 if _pin.captured then
  return
 end

 _pin.last_pos = _pin.origin:copy()

 if _pin.spd_mag > _dt then
  _pin.origin=_pin.origin:plus(
   _pin.spd:normalize()
  )
 else
  _pin.origin=_pin.origin:plus(
   _pin.spd:multiplied_by(1/_dt)
  )
 end

 if _pin.origin.y > 140 or _pin.origin.y < 0 or _pin.origin.x < 2 or _pin.origin.x > 78 then
  del(pinballs,_pin)
  if blastoff_mode then
   add_blastoff_ball()
  end
 else
  for _col_grp in all({collision_regions[flr(_pin.origin.x/16)+1][flr(_pin.origin.y/16)+1],always_colliders,flippers,pinballs}) do
   for _sc in all(_col_grp) do
    if _pin != _sc then
     check_collision(_pin,_sc)
    end
   end
  end
  if #_pin.trackers==0 then
   add_tracker(_pin)
  elseif not pos_are_equal(_pin.origin,_pin.trackers[#_pin.trackers]) then
   add_tracker(_pin)
  end
 end
end

function add_tracker(pinball)
 add(pinball.trackers,{
   x=pinball.origin.x,y=pinball.origin.y,l=7
  })
end

function rollback_pinball_pos(_pin)
 _pin.origin=_pin.last_pos
end

function draw_pinball(_pin)
 sspr(
  29,0,
  3,3,
  _pin.origin.x-1,
  _pin.origin.y-1
 )
end

function check_collision_with_pinball(_pin1,_pin2)
 if dist_between_vectors(_pin1.origin, _pin2.origin)<=3 then
  if not _pin1.captured then
   rollback_pinball_pos(_pin1)
  end
  if not _pin2.captured then
   rollback_pinball_pos(_pin2)
  end

  local perp_vec = _pin1.origin:minus(_pin2.origin):normalize()

  local u1 = perp_vec:dot(_pin1.spd)
  local u2 = perp_vec.x*_pin1.spd.y - perp_vec.y*_pin1.spd.x
  local u3 = perp_vec:dot(_pin2.spd)
  local u4 = perp_vec.x*_pin2.spd.y - perp_vec.y*_pin2.spd.x

  _pin2.spd.x = perp_vec.x * u1 - perp_vec.y * u4
  _pin2.spd.y = perp_vec.y * u1 + perp_vec.x * u4
  _pin1.spd.x = perp_vec.x * u3 - perp_vec.y * u2
  _pin1.spd.y = perp_vec.y * u3 + perp_vec.x * u2

 end
end


function init_round_bumpers()
 -- initialise circular bumpers
 r_bumpers={
  create_round_bumper(
   vec(42,28),
   1
  ),
  create_round_bumper(
   vec(51,34),
   4
  ),
  create_round_bumper(
   vec(29,30),
   3
  ),
  create_round_bumper(
   vec(37,38),
   2
  )
 }
 for _rb in all(r_bumpers) do
  add(static_colliders,_rb)
  add(static_over,_rb)
 end
end

function create_round_bumper(
 _origin,
 _spr_i
)
 -- create a round bumper
 return {
  origin=_origin,
  simple_collider={
   x1=-5,y1=-5,x2=5,y2=5
  },
  spr_off=vec(-4,-4),
  spr_coords=vec(0,8*_spr_i),
  draw=draw_spr,
  spr_w=8,
  spr_h=8,
  hit=0,
  check_collision=check_collision_with_r_bumper
 }
end

function check_collision_with_r_bumper(_b,_pin)
 -- check for collision with the
 -- bumper
 if dist_between_vectors(_b.origin, _pin.origin)<=4.5 then
  increase_score(751)
  planet_lights_lit+=0.35
  sfx(planet_lights_lit)
  _b.hit = 8
  local normalized_perp_vec = _pin.origin:minus(_b.origin):normalize()
  rollback_pinball_pos(_pin)
  _pin.spd = calc_reflection_vector(
   _pin.spd,
   normalized_perp_vec
  )
  _pin.spd = _pin.spd:plus(normalized_perp_vec:multiplied_by(0.375))
 end
end

function set_planet_lights()
 if planet_lights_lit>=10 then
  add(ongoing_msgs,planet_msg)
  light_orbit(4)
  add(msgs,{"star system","mapping","complete!",t=120})
  increase_score(500,1)
  planet_lights_lit=0.75
  flash_table(planet_lights,2,false)
  sfx(10)
  return
 end
 update_prog_light_group(planet_lights,planet_lights_lit)
end


function init_poly_bumpers()
 -- create polyginal bumpers
 spaceship = create_poly_bumper(
  vec(29,55),
  gen_polygon("-1,3,6,0,17,-1,14,2,14,4,17,7,6,6"),
  vec(0,48),
  16,7,
  false,
  vec(32,48)
 )
 spaceship.collider[1]=vec(-1,3,1,543,false,13)
 spaceship.collider[2]=vec(6,0,1,543,false,13)

 local _wall_col = gen_polygon("75,27,72,34")
 launch_block={
  origin=vec(0.5,0.5),
  collider=_wall_col,
  simple_collider=gen_simple_collider(_wall_col),
  check_collision=check_collision_with_collider
 }


 left_drain_block = create_poly_bumper(
  vec(16.5,110.5),
  gen_polygon("-1,-5,-1,6"),
  vec(36,5),
  1,3
 )
 right_drain_block = create_poly_bumper(
  vec(63.5,110.5),
  gen_polygon("1,-5,1,6"),
  vec(36,5),
  1,3
 )
 add(always_colliders,left_drain_block)
 add(static_over,left_drain_block)
 add(always_colliders,right_drain_block)
 add(static_over,right_drain_block)

 left_drain = create_poly_bumper(
  vec(13.5,112.5),
  gen_polygon("0,-1,2,1"),
  vec(32,5),
  3,4,
  true
 )
 left_drain.light = left_drain_light
 left_drain.block = left_drain_block

 right_drain = create_poly_bumper(
  vec(64.5,112.5),
  gen_polygon("2,-1,0,1"),
  vec(32,5),
  3,4,
  false
 )
 right_drain.light = right_drain_light
 right_drain.block = right_drain_block

 
 
 poly_bumpers={
   -- spaceship
   spaceship,
   -- left bumper
   create_poly_bumper(
    vec(51.5,95.5),
    gen_polygon("4,-1,6,1,6,11,1,14,-1,13,2,1"),
    vec(8,0),
    8,14,
    false,
    vec(40,4)
   ),
   -- right bumper
   create_poly_bumper(
    vec(21.5,95.5),
    gen_polygon("5,1,8,13,6,14,1,11,1,1,3,-1"),
    vec(8,0),
    8,14,
    true,
    vec(40,4)
   ),
   -- right gutter pin
   create_poly_bumper(
    vec(64.5,120.5),
    {
     vec(0,0,2.1,0,true,13),
     vec(2,0)
    },
    vec(43,0),
    3,2,
    false,
    nil,
    close_right_drain
   ),
   -- left gutter pin
   create_poly_bumper(
    vec(13.5,120.5),
    {
     vec(0,0,2.1,0,true,13),
     vec(2,0)
    },
    vec(43,0),
    3,2,
    false,
    nil,
    close_left_drain
   )
 }
 poly_bumpers[2].collider[5] = vec(-1,13,1,543,false,13)
 poly_bumpers[3].collider[1] = vec(5,1,1,543,false,13)

 add_group_to_board(poly_bumpers,{static_colliders,static_over})
end

function create_poly_bumper(
 _origin,
 _collider,
 _spr,
 _spr_w,
 _spr_h,
 _flip_x,
 _spr_hit_coords,
 _action
)
 -- create a polyginal bumper
 _spr_w,_spr_h=_spr_w or 1,_spr_h or 1
 return {
  origin=_origin,
  simple_collider=gen_simple_collider(_collider),
  collider=_collider,
  spr_off=vec(0,0),
  spr_coords=_spr,
  hit_spr_coords=_spr_hit_coords,
  r=4,
  draw=draw_spr,
  check_collision=check_collision_with_collider,
  spr_w=_spr_w,
  spr_h=_spr_h,
  flip_x=_flip_x,
  complete=true,
  hit=0,
  c=7,
  action=_action
 }
end

function close_left_drain()
 reset_drain(left_drain)
 add_to_queue(close_drain,30,{left_drain})
end

function close_right_drain()
 reset_drain(right_drain)
 add_to_queue(close_drain,30,{right_drain})
end

function close_drain(
 _d
)
 if _d.light.lit then
  add(static_over,_d)
  add(always_colliders,_d)
  del(static_over,_d.block)
  del(always_colliders,_d.block)
  _d.light.lit = false
 end
end

function reset_drain(_d)
 if not _d.light.lit then
  del(static_over,_d)
  del(always_colliders,_d)
  add(static_over,_d.block)
  add(always_colliders,_d.block)
  _d.light.lit = true
 end
end


function init_targets()
 -- initialize targets
 skillshot_target=create_target(
  vec(24.5,13.5),
  gen_polygon("-1,-0.5,2.5,0.5,2.5,4,-1,4"),
  nil,
  vec(40,0),
  2,4
 )
 skillshot_target.p=nil
 skillshot_target.sfx=nil
 skillshot_target.check_collision=check_collision_with_skillshot
 add(static_colliders,skillshot_target)
 add(static_over,skillshot_target)
 local left_col=gen_polygon(
  "0,-1,3,0,2,5,-1,5"
 )
 left_light_offset=vec(4,3)
 left_targets={
  elements={
   create_target(
    vec(12.5,76.5),
    left_col,
    left_light_offset,
    vec(32,0),
    3,5
   ),
   create_target(
    vec(13.5,70.5),
    left_col,
    left_light_offset,
    vec(32,0),
    3,5
   ),
   create_target(
    vec(15.5,63.5),
    left_col,
    left_light_offset,
    vec(32,0),
    3,5
   ),
  },
  all_lit_action=left_targets_lit,
  sfx=15
 }
 add_target_group_to_board(left_targets)

 right_target_poly = gen_polygon(
  "3,5,1.5,5,-0.5,1,1,-1"
 )
 right_light_offset = vec(-3,3)

 right_targets={
  elements={
   create_target(
    vec(53.5,47.5),
    right_target_poly,
    right_light_offset,
    vec(42,18),
    3,5
   ),
   create_target(
    vec(64.5,74.5),
    right_target_poly,
    right_light_offset,
    vec(42,18),
    3,5
   )
  },
  all_lit_action=right_targets_lit,
  sfx=15
 }
 add_target_group_to_board(right_targets)

 h_target_poly = gen_polygon(
  "-1,-1,5,-1,4,3,-1,2"
 )
 h_light_offset = vec(0,4)

 rocket_targets={
  elements={
   create_target(
    vec(38.5,61.5),
    h_target_poly,
    h_light_offset,
    vec(32,18),
    5,3
   ),
   create_target(
    vec(32.5,60.5),
    h_target_poly,
    h_light_offset,
    vec(32,18),
    5,3
   )
  },
  all_lit_action=pass,
  sfx=15
 }
 add_target_group_to_board(rocket_targets)
 
end

function add_target_group_to_board(_grp,_draw_layer)
 for _t in all(_grp.elements) do
  _t.group = _grp
  add(static_colliders,_t)
  add(_draw_layer or static_over,_t)
 end
end

function create_target(
 _origin,
 _collider,
 _light_offset,
 _unlit_spr,
 _spr_w,
 _spr_h
)
 local _l = {
  origin=_origin,
  simple_collider=gen_simple_collider(_collider),
  check_collision=check_collision_with_target,
  collider=_collider,
  draw=draw_spr,
  hit=0,
  c=7,
  lit=false,
  complete=true,
  spr_coords=_unlit_spr,
  hit_spr_coords=_unlit_spr:plus(vec(_spr_w,0)),
  spr_off=vec(0,0),
  spr_w=_spr_w,
  spr_h=_spr_h,
  p=1212,
  sfx=14
 }
 if _light_offset then
  _l.light = create_light(
   _origin:plus(_light_offset),
   nil,
   draw_dot_light
  )
  add(static_under,_l.light)
 end
 return _l
end

function check_collision_with_target(_obj,_pin)
 -- action to take if pinball
 -- hits the target
 if check_collision_with_collider(_obj,_pin) then
  _obj.lit=true
  if _obj.group then
   group_elem_lit(_obj.group)
  end
  if _obj.light.flashing then
   target_hunt_cnt += 1
   update_prog_light_group(pent_lights,target_hunt_cnt)
   add_to_queue(end_target_hunt,1800,{true})
   if target_hunt_cnt>=5 then
    end_target_hunt()
    increase_score(500,1)
    light_orbit(5)
    cycle_lights(pent_lights,1,3,10,true)
   else
    repeat
     flash_rnd_target()
    until cur_target != _obj
   end
  end
 end
end

function check_collision_with_skillshot(_t,_pin)
 if check_collision_with_collider(_t,_pin) and _t.bonus_enabled then
  increase_score(250,1)
  add(msgs,{"skillshot!",t=90})
  disable_bonus(_t)
  _t.hit = 7
  sfx(10)
 end
end

function left_targets_lit(_g)
 reset_drain(left_drain)
 rollovers_all_lit(_g)
 sfx(15)
end

function right_targets_lit(_g)
 reset_drain(right_drain)
 rollovers_all_lit(_g)
 sfx(15)
end


function init_spinners()
 -- create spinner
 spinner={
  origin=vec(11.5,26.5),
  simple_collider={x1=-2,y1=-5,x2=2,y2=4},
  check_collision=check_collision_with_spinner,
  draw=draw_spinner,
  update=update_spinner,
  to_score=0
 }
 add(static_colliders,spinner)
 add(static_over,spinner)
end

function draw_spinner()
 -- draw spinner animation frame
 local spr_i = 33+16*flr((spinner.to_score/50)%4)
 spr(spr_i,spinner.origin.x-3,spinner.origin.y-4)
end

function check_collision_with_spinner(_s,_pin)
 -- check collision with spinner
 if spinner.deactivated then
  return
 end
 spinner.to_score = max(spinner.to_score,flr(min(6.123,abs(_pin.spd.y))*2000))
 if _pin.spd.y < 0 and not kickouts[2].bonus_enabled then
  sfx(23,3)
  enable_bonus(kickouts[2],180)
  cycle_lights(spinner_lights,1,3,flr(60/#spinner_lights))
 end
 spinner.deactivated = true
 add_to_queue(reactivate,30,{spinner})
end

function update_spinner()
 -- update spinner each frame
 if spinner.to_score > 0 then
  if f%ceil(10000/spinner.to_score)==0 then
   sfx(22)
  end
  local scr_change = min(spinner.to_score,max(10,flr(spinner.to_score*0.02)))
  spinner.to_score-=scr_change
  increase_score(scr_change)
 end
end


function init_rollovers()
 -- initialize rollovers
 top_rollovers={
  elements={},
  all_lit_action=increase_multi,
  sfx=25
 }
 for i=0,4 do
  add(top_rollovers.elements,create_rollover(28.5+6*i,15.5))
 end
 bottom_rollovers={
  elements={
   create_rollover(14.5,95.5,hit_refuel_rollover),
   create_rollover(20.5,97.5,hit_refuel_rollover),
   create_rollover(65.5,95.5,hit_refuel_rollover),
   create_rollover(59.5,97.5,hit_refuel_rollover)
  },
  all_lit_action=rollovers_all_lit,
  sfx=27
 }
 add_target_group_to_board(top_rollovers,static_under)
 add_target_group_to_board(bottom_rollovers,static_under)
end

function create_rollover(_x,_y,_action)
 -- create a rollover
 return {
  origin=vec(_x,_y),
  simple_collider={x1=-2,y1=0,x2=2,y2=3},
  draw=draw_spr,
  check_collision=check_collision_with_rollover,
  spr_coords=vec(37,0),
  spr_w=3,
  spr_h=8,
  spr_off=vec(-1,0),
  unlit_col=4,
  hit=0,
  action=_action
 }
end

function set_light(_r,_lit)
 -- set light status for an element
 _r.lit=_lit
end

function check_collision_with_rollover(_r,_pin)
 -- action to trigger when box
 -- collider is triggered
 if _r.deactivated then
  return
 end
 if not _r.lit then
  sfx(26)
 end
 set_light(_r,true)
 if _r.group then
  group_elem_lit(_r.group)
 end

 _r.deactivated=true
 add_to_queue(reactivate,20,{_r})
 increase_score(1234)
 if _r.action != nil then
   _r.action(_r,_pin)
 end
end

function rollovers_all_lit(_rg)
 -- action for when rollover
 -- group's lights all lit.
 increase_score(50,1)
 for _r in all(_rg.elements) do
  set_light(_r,false)
 end
end

function hit_refuel_rollover(_r,_pin)
 if _pin.spd.y > 0 then
  light_refuel_lights()
 end
end

function increase_multi(_rg)
 light_orbit(3)
 if multiplier<4 then
  add(msgs,{"multiplier","increased!",t=120})
 end
 multiplier=min(4,multiplier+1)
 rollovers_all_lit(_rg)
end


function group_elem_lit(_grp)
 if _grp.deactivated then
  return
 end
 for _r in all(_grp.elements) do
  if not _r.lit then
   return
  end
 end
 sfx(_grp.sfx)

 flash_table(_grp.elements,2,false)

 _grp.deactivated = true
 add_to_queue(reactivate,65,{_grp})

 _grp:all_lit_action()
end

function shift_light_left(_r)
 -- shift lit status to the left
 shift_light(_r,-1)
end

function shift_light(_r,_dir)
 local _cpy={}
 for i in all(_r) do
  add(_cpy,i.lit or false)
 end
 for i = 1,#_r do
  set_light(_r[mod(i+_dir,#_r)],_cpy[i])
 end
end

function shift_light_right(_r)
 -- shift lit status to the right
 shift_light(_r,1)
end

function add_group_to_board(_grp,_layers)
 for _el in all(_grp) do
  for _l in all(_layers) do
   add(_l,_el)
  end
 end
end


function init_kickouts()
 -- initialise the capture
 -- elements on the board.
 blastoff_msg = {"blast-off!","multiball!"}
 target_hunt_msg = {"calibrate","lasers!","hit targets!"}

 kickouts = {
  -- target hunt capture
  create_capture(
   vec(68.5,58.5),
   vec(-1,1),
   1111,
   start_target_hunt
  ),
  -- escape velocity capture
  create_capture(
   vec(11.5,56.5),
   vec(1,0),
   1111,
   escape_velocity_action
  ),
  -- rocket fuel capture
  create_capture(
   vec(45.5,58.5),
   vec(0.4,0.4),
   0,
   empty_fuel_action
  )
 }
 add_group_to_board(kickouts,{static_under,static_colliders})
end

function create_capture(
 _origin,
 _eject_vector,
 _points,
 _action
)
 return {
  origin=_origin,
  simple_collider=create_box_collider(
   -1.5,-1.5,
   1.5,1.5
  ),
  output_vector=_eject_vector,
  draw=draw_capture,
  check_collision=check_collision_with_capture,
  action=_action,
  p=_points
 }
end

function check_collision_with_capture(
 _cap,
 _pin
)
 -- action to take when pinball
 -- collides with box collider.
 if _cap.captured_pinball != nil or 
 _cap.deactivated then
  return
 end
 _pin.captured=true
 _pin.origin=vec(
  _cap.origin.x,
  _cap.origin.y
 )
 
 _pin.spd=vec(0,0)
 _cap.captured_pinball=_pin
 _cap.deactivated=true
 increase_score(_cap.p)
 if _cap.action != nil then
  _cap:action()
 end
 add_to_queue(eject_captured,90,{_cap})
end

function eject_captured(_cap)
 -- eject the ball
 _cap.captured_pinball.spd=_cap.output_vector:copy()
 _cap.captured_pinball.captured=false
 _cap.captured_pinball = nil
 _cap.bonus_timer = 0
 disable_bonus(_cap)
 add_to_queue(reactivate,30,{_cap})
end

function draw_capture(_cap)
 local _bc = 0
 if _cap.deactivated then
  _bc = 5
 end
 circfill(
  _cap.origin.x,
  _cap.origin.y,
  2,
  _bc
 )
 _c = 4
 if _cap.lit then
  _c=10
 end
 circ(
  _cap.origin.x,
  _cap.origin.y,
  2,
  _c
 )
end

function escape_velocity_action(_cap)
 if not _cap.bonus_enabled then
  sfx(24)
  return
 end
 increase_score(50,1)
 add(msgs,{"slingshot!",t=90})
 light_orbit(1)
 sfx(10,3)
end

function empty_fuel_action(_cap)
 -- action for when fuel capture
 -- triggered.
 if blastoff_mode then
  increase_score(50,1)
  sfx(24)
  return
 end

 increase_score(
  3^min(5,refuel_lights_lit),
  1
 )
 if refuel_lights_lit>=#refuel_lights then
  light_orbit(2)
  blastoff_mode = true
  kickouts[2].deactivated=true
  reset_light.lit = true
  add(ongoing_msgs,blastoff_msg)
  sfx(29,1)
  flash(_cap,-99,false)
  cycle_lights(refuel_lights,1,30,10,true)
  add_blastoff_ball()
  add_to_queue(add_blastoff_ball,60)
  add_to_queue(end_blastoff_mode,1200)
 elseif refuel_lights_lit>0 then
  add(msgs,{"partial","refuel",t=90})
  flash(_cap,3,false)
  flash_table(refuel_lights,3,false,true)
  sfx(24)
 else
  sfx(24)
 end
 refuel_lights_lit=0
end

function add_blastoff_ball()
 local _cap = kickouts[2]
 _p = create_pinball(_cap.origin:copy())
 _p.spd=_cap.output_vector:copy()
end

function end_blastoff_mode()
 local _cap = kickouts[2]
 if not blastoff_mode then
  return
 end
 blastoff_mode = false
 reset_light.lit = false
 reactivate(_cap)
 del(ongoing_msgs,blastoff_msg)
 end_flash(_cap,false)
 end_flash_table(refuel_lights,false)
end

function start_target_hunt()
 add_to_queue(end_target_hunt,1800,{true})
 sfx(28)
 if not target_hunt then
  add(ongoing_msgs,target_hunt_msg)
  flash_rnd_target()
  target_hunt = true
  target_hunt_cnt = 0
 end
end

function flash_rnd_target()
 if cur_target then
  end_flash(cur_target.light)
  cur_target.sfx=14
 end
 local _rn = flr(rnd(3))
 local _t = nil
 if _rn==0 then
  _t=rnd(left_targets.elements)
 elseif _rn == 1 then
  _t=rnd(right_targets.elements)
 else
  _t=rnd(rocket_targets.elements)
 end
 flash(_t.light,-99)
 _t.sfx = 28
 cur_target=_t
end

function end_target_hunt(_timeout)
 if not target_hunt then
  return
 end
 del(ongoing_msgs,target_hunt_msg)
 target_hunt = false
 if _timeout then
  sfx(30,2)
  target_hunt_cnt = 0
  update_prog_light_group(pent_lights,target_hunt_cnt)
 end
 if cur_target then
  end_flash(cur_target.light)
  cur_target.sfx=14
  cur_target=nil
 end
end
function init_lights()
 -- initialise decorative lights
 refuel_lights_lit=0

 chevron_light_spr = create_light_spr(
  vec(32,9)
 )
 up_chevron_light_spr = create_light_spr(
  vec(35,12)
 )
 h_chevron_light_spr = create_light_spr(
  vec(35,9)
 )
 small_up_right_chevron_spr = create_light_spr(
  vec(33,12),2,2
 )
 big_up_right_chevron_spr = create_light_spr(
  vec(32,12)
 )
 orbit_lights = {}
 for i=1,5 do
  add(
   orbit_lights,
   create_light(
    vec(27+i*4,93),
    sub("orbit",i,i),
    draw_letter_light
   )
  )
 end

 add_group_to_board(orbit_lights,{static_under})

 pent_lights={}
 for i=0,0.8,0.2 do
  add(
   pent_lights,
   create_light(
    vec(64.5-sin(i)*4,48.5-cos(i)*4),
    nil,
    draw_dot_light
   )
  )
 end
 add_group_to_board(pent_lights,{static_under})

 left_drain_light = create_light(
  vec(13,108),
  chevron_light_spr,
  draw_spr
 )
 left_drain_light.lit=true
 add(static_under,left_drain_light)
 right_drain_light = create_light(
  vec(64,108),
  chevron_light_spr,
  draw_spr
 )
 right_drain_light.lit=true
 add(static_under,right_drain_light)

 spinner_lights={
  create_light(
   vec(16,27),
   up_chevron_light_spr,
   draw_spr
  ),
  create_light(
   vec(16,24),
   up_chevron_light_spr,
   draw_spr
  ),
  create_light(
   vec(17,22),
   small_up_right_chevron_spr,
   draw_spr
  ),
  create_light(
   vec(18,20),
   big_up_right_chevron_spr,
   draw_spr
  ),
  create_light(
   vec(20,18),
   big_up_right_chevron_spr,
   draw_spr
  )
 }
 for i=0,3 do
  add(
   spinner_lights,
    create_light(
    vec(20-i,36-i*2),
    vec(20-i,37-i*2),
    draw_line_light
   ),
   i+1
  )
 end

 add_group_to_board(spinner_lights,{static_under})

 refuel_lights={}
 for i=0,3 do
  add(
   refuel_lights,
   create_light(
    vec(47+i*3,57),
    h_chevron_light_spr,
    draw_spr
   )
  )
 end
 add_group_to_board(refuel_lights,{static_under})

 reset_light = create_light(
  vec(39,125),nil,draw_dot_light
 )
 add(static_under,reset_light)

 planet_lights={}
 for i=1,10 do
  local _x = 65-abs(5.5-i)/2
  add(
   planet_lights,
   create_light(
    vec(_x,29-i),
    vec(_x+1,29-i),
    draw_line_light
   )
  )
 end
 add_group_to_board(planet_lights,{static_under})
end

function create_light(
 _origin,
 _config,
 _draw,
 _off_col,
 _lit_col
)
 -- create light object
 local _l = {
  origin=_origin,
  config=_config,
  off_col=_off_col or 4,
  lit_col=_lit_col or 10,
  draw=_draw,
  lit=false,
  spr_off=vec(0,0)
 }
 if _draw == draw_spr then
  for k,v in pairs(_config) do
   _l[k]=v
  end
 end
 return _l 
end

function draw_line_light(_l)
 -- draw a line-like light
 local _c = _l.off_col
 if _l.lit then
  _c=_l.lit_col
 end
 line(
  _l.origin.x,
  _l.origin.y,
  _l.config.x,
  _l.config.y,
  _c
 )
end

function draw_letter_light(_l)
 local _c = _l.off_col
 if _l.lit then
  _c=_l.lit_col
 end
 print(
  _l.config,
  _l.origin.x,
  _l.origin.y,
  _c
 )
end

function draw_dot_light(_l)
 local _c = _l.off_col
 if _l.lit then
  _c=_l.lit_col
 end
 rect(
  _l.origin.x,
  _l.origin.y,
  _l.origin.x+1,
  _l.origin.y+1,
  _c
 )
end

function create_light_spr(
 _spr_coord,
 _w,_h
)
 return {
  spr_coords=_spr_coord,
  unlit_col=4,
  spr_w=_w or 3,
  spr_h=_h or 3,
  hit=0
 }
end

function light_refuel_lights()
 -- action for progressive
 -- lighting of refuel lights.
 -- lights a light each time
 -- it's triggered.
 if #pinballs > 1 then
  return
 end
 refuel_lights_lit+=1
 if refuel_lights_lit >= #refuel_lights then
  flash(kickouts[3],-99,true)
 end
 update_prog_light_group(refuel_lights,refuel_lights_lit)
end

function update_prog_light_group(_grp,_n)
 for i = 1,#_grp do
  _grp[i].lit=_n>=i
 end
end

function cycle_lights(_group,_next_index,_times,_delay,_rev)
 _group[mod(_next_index-1,#_group)].lit = _rev

 if _next_index > #_group*_times then
  if _rev then
   cycle_lights(_group,2,1,_delay)
  else
   end_flash_table(_group)
  end
  return
 end

 _group[mod(_next_index,#_group)].lit = not _rev
 add_to_queue(cycle_lights,_delay,{_group,_next_index+1,_times,_delay,_rev})
end

function light_orbit(i)
 flash(orbit_lights[i],3,true)
 local _cnt = 0
 for _l in all(orbit_lights) do
  if _l.lit or _l.flashing then
   _cnt+=1
  end
 end
 if _cnt==5 then
  add(msgs,{"orbit","achieved!","extra ball!",t=120})
  sfx(16)
  increase_score(2500,1)
  balls+=1
  flash_table(orbit_lights,3,false)
 end
end


function init_launcher()
 local _col=gen_polygon("-1,-0.5,3,-0.5")
 launcher={
  origin=vec(73,78),
  collider=_col,
  simple_collider=gen_simple_collider(_col),
  complete=false,
  check_collision=check_collision_with_collider,
  draw=draw_launcher,
  c=7
 }
 add(static_under,launcher)
 add(always_colliders,launcher)
end

function draw_launcher(_l)
 line(73,_l.origin.y+1,75,_l.origin.y+1,4)
 fillp(0b1111000011110000)
 rectfill(73,_l.origin.y+2,75,103,214)
 fillp()
end


function init_launch_triggers()
 launch_triggers={
  create_trigger_area(
   create_box_collider(71,22,78,27)
  ),
  create_trigger_area(
   create_box_collider(65,22,71,37)
  )
 }
 for _l in all(launch_triggers) do
  add(static_colliders,_l)
 end
end

function create_trigger_area(
 _simple_collider
)
 return {
  origin=vec(0,0),
  simple_collider=_simple_collider,
  check_collision=exit_launch_mode
 }
end

function exit_launch_mode(_l)
 if mode!=modes.launch then
  return
 end
 mode=modes.game
 add(always_colliders,launch_block)
 del(ongoing_msgs,launch_msg)
 if reset_light.lit then
  enable_bonus(skillshot_target,80)
 end
 add_to_queue(set_light,900,{reset_light,false})
end



function init_table()
 multiplier=1

 pinballs={}
 static_colliders={}
 always_colliders={}
 static_over={}
 static_under={}

 init_walls()
 init_lights()
 init_round_bumpers()
 init_poly_bumpers()
 init_targets()
 init_spinners()
 init_rollovers()
 init_kickouts()
 init_launcher()
 init_launch_triggers()
 init_flippers()

 collision_regions=gen_collision_regions(
  0,0,79,127,16
 )
end

function draw_table()
 map()

 for _sc in all(static_under) do
  _sc:draw()
 end

 for pinball in all(pinballs) do
  for _t in all(pinball.trackers) do
   circfill(_t.x,_t.y,flr(_t.l/6),tracker_cols[1+flr(_t.l/4)])
  end
  draw_pinball(pinball)
 end
 
 for _sc in all(static_over) do
  _sc:draw()
 end
 foreach(flippers,draw_flipper)
 
 local _multi_y=115-multiplier*6
 rectfill(9,_multi_y-1,10,_multi_y,10)
end


--lib
function calc_reflection_vector(
 _v,
 _l
)
	return _v:minus(calc_bounce_vector(_v,_l))
end

function calc_bounce_vector(_v, _l)
 return _l:multiplied_by(2*_v:dot(_l))
end

function bounce_off_line(_pin,_l)
 local normalized_perp_vec = perpendicular(normalize(_l):multiplied_by(0.9))
 if _l.only_ref then
  _pin.spd=normalized_perp_vec:multiplied_by(_l.ref_spd)
 else
  _pin.spd = calc_reflection_vector(
    _pin.spd,
    normalized_perp_vec
  )

  if _l.ref_spd then
   _pin.spd = _pin.spd:plus(normalized_perp_vec:multiplied_by(_l.ref_spd))
  end
 end
end


function rotate_pnts(
	_points,_origin,_angle
)
	local _new_points={}
	for _pnt in all(_points) do
		local _pnt_o=subtract_vectors(_pnt,_origin)
  local _np =	add_vectors(
   _origin,
   vec(
    _pnt_o.x*cos(_angle)-_pnt_o.y*sin(_angle),
    _pnt_o.y*cos(_angle)+_pnt_o.x*sin(_angle)
   )
  )
  _np.c=_pnt.c
		add(_new_points,_np)
	end
	return _new_points
end

function check_collision(_pin,_obj)
 if point_collides_box(_pin.origin,_obj) then
  _obj:check_collision(_pin)
 end
end

function create_box_collider(_x1,_y1,_x2,_y2)
 -- create a simple box collider
 return {x1=_x1, y1=_y1,x2=_x2, y2=_y2}
end

function lines_cross(_l1_1,_l1_2,_l2_1,_l2_2)
 local _a1,_b1,_c1=calc_inf_line_abc(_l1_1,_l1_2)
 local _a2,_b2,_c2=calc_inf_line_abc(_l2_1,_l2_2)
 local _d1 = (_a1*_l2_1.x)+(_b1*_l2_1.y)+_c1
 local _d2 = (_a1*_l2_2.x)+(_b1*_l2_2.y)+_c1

 if sign(_d1)==sign(_d2) then
  return false
 end
 
 local _d1 = (_a2*_l1_1.x)+(_b2*_l1_1.y)+_c2
 local _d2 = (_a2*_l1_2.x)+(_b2*_l1_2.y)+_c2

 if sign(_d1)==sign(_d2) then
  return false
 end
 
 return true
end

function calc_inf_line_abc(_l1,_l2)
 local _a=_l2.y-_l1.y
 local _b=_l1.x-_l2.x
 local _c=(_l2.x*_l1.y)-(_l1.x*_l2.y)
 return _a,_b,_c
end

function check_collision_with_collider(_obj,_pin)
 local _crossed_line = pin_entered_poly(_pin,_obj)
 if _crossed_line != nil then
  local _sfx = _crossed_line.sfx or _obj.sfx
  if _sfx then
   sfx(_sfx)
  elseif _pin.spd_mag > 2 then
   sfx(12)
  elseif _pin.spd_mag > 0.5 then
   sfx(11)
  end
  local _pnts = _crossed_line.p or _obj.p or 0
  if _pnts > 0 then
   increase_score(_pnts)
   _obj.hit = 7
  end
  if _obj.action!=nil then
   _obj:action()
  end
  rollback_pinball_pos(_pin)
  bounce_off_line(_pin,_crossed_line)
  return true
 end
end

function pin_entered_poly(_pin,_obj)
 local _pnts,_origin=_obj.collider,_obj.origin
 local _n_pnts=#_pnts
 if not _obj.complete then
  _n_pnts-=1
 end
	for i=1,_n_pnts do
		local j=i%#_pnts+1
		if lines_cross(
    _pin.origin,
    _pin.last_pos,
				_pnts[i]:plus(_origin),
			 _pnts[j]:plus(_origin)
			) then
   local output=_pnts[i]:minus(_pnts[j])
   output.p=_pnts[i].p
   output.ref_spd=_pnts[i].ref_spd
   output.only_ref=_pnts[i].only_ref
   output.sfx=_pnts[i].sfx
   return output
		end
	end
 return nil
end



function pos_are_equal(_p1,_p2)
 return flr(_p1.x)==flr(_p2.x) and flr(_p1.y)==flr(_p2.y)
end


function gen_simple_collider(_col)
  local _out={
  x1=_col[1].x,
  y1=_col[1].y,
  x2=_col[1].x,
  y2=_col[1].y,
 }
 for _pnt in all(_col) do
  _out.x1=min(_out.x1,_pnt.x-1)
  _out.y1=min(_out.y1,_pnt.y-1)
  _out.x2=max(_out.x2,_pnt.x+1)
  _out.y2=max(_out.y2,_pnt.y+1)
 end
 return _out
 
end


function gen_collision_regions(
 _x1,_y1,
 _x2,_y2,
 _side_length
)
 local _col_regions = {}
 for i=_x1,_x2,_side_length do
  local _col_col={}
  for j=_y1,_y2,_side_length do
   local _r_x1=i-1
   local _r_x2=i+_side_length+1
   local _r_y1=j-1
   local _r_y2=j+_side_length+1
   local _col_row={}
   for _obj in all(static_colliders) do
    local _col = _obj.simple_collider
    local _org = _obj.origin
    if (_r_x1 <= _col.x2+_org.x and _r_x2 >= _col.x1+_org.x and
     _r_y1 <= _col.y2+_org.y and _r_y2 >= _col.y1+_org.y) then
     add(_col_row,_obj)
    end 
   end
   add(_col_col,_col_row)
  end
  add(_col_regions,_col_col)
 end
 return _col_regions
end

function increase_score(
 _scr,_offset
)
 for i=1,multiplier do
  add_to_long(score,_scr,_offset)
 end
end

function add_to_queue(_func,_delay,_args)
 _args = _args or {}
 for _a in all(action_queue) do
  if _a.func == _func and _a.args[1] == _args[1] then
   _a.delay = _delay
   _a.args = _args
   return
  end
 end
 add(
  action_queue,{
   func = _func,
   delay = _delay,
   args = _args
  }
 )
end

function reactivate(_r)
 _r.deactivated=false
end

function disable_bonus(_o)
 _o.bonus_enabled=false
 end_flash(_o,false)
end

function enable_bonus(_o,_t)
 _o.bonus_enabled=true
 flash(_o,-99,true)
 add_to_queue(disable_bonus,_t,{_o})
end


function flash(_o,_times,_next_state,_rep_call)
 -- Will end on initialitial _next_state
 if not _o then
  return
 elseif not(_rep_call) then
  _o.flashing = true
 elseif not _o.flashing then
  return
 end

 set_light(_o,_next_state)

 if _times <= 0 and _times > -99 then
  _o.flashing = false
  return
 end

 _times -= 0.5
 add_to_queue(flash,15,{_o,_times,not _next_state, true})
end

function end_flash(_o,_state)
 _o.flashing = false
 set_light(_o,_state)
end

function flash_table(_t,_times,_next_state,_if_lit)
 for _o in all(_t) do
  if not _if_lit or _o.lit then
   flash(_o,_times,_next_state)
  end
 end
end

function end_flash_table(_t,_state)
 for _o in all(_t) do
  end_flash(_o,_state)
 end
end



-- common
function vec(_x,_y,_ref_spd,_pnts,_only_ref, _sfx)
 -- Create a vector object
 return {
  x=_x,
  y=_y,
  p=_pnts,
  ref_spd=_ref_spd,
  only_ref=_only_ref,
  plus=add_vectors,
  minus=subtract_vectors,
  copy=copy_vec,
  dot=dot_product,
  magnitude=magnitude,
  multiplied_by=multiply_vector,
  normalize=normalize,
  perpendicular=perpendicular,
  sfx=_sfx
 }
end

function copy_vec(_v)
 -- Create a copy of a vector
 return vec(_v.x, _v.y,_v.ref_spd,_v.p,_v.only_ref)
end

function normalize(_v)
--Makes magnitude = 1
	return _v:multiplied_by(1/_v:magnitude())
end

function dot_product(_v1,_v2)
	return _v1.x*_v2.x+_v1.y*_v2.y
end

function perpendicular(_v)
	return vec(-_v.y,_v.x)
end

function multiply_vector(_v,_mul)
--Multiple a vector by a scalar.
	return vec(_v.x*_mul,_v.y*_mul)
end

function add_vectors(_v1,_v2)
	return vec(_v1.x+_v2.x,_v1.y+_v2.y)
end

function subtract_vectors(_v1,_v2)
	return vec(_v1.x-_v2.x,_v1.y-_v2.y)
end

function dist_between_vectors(_v1,_v2)
 return sqrt(
  (_v1.x-_v2.x)^2+(_v1.y-_v2.y)^2
 )
end

function magnitude(_v)
 return sqrt(_v.x^2+_v.y^2)
end


function mod(val,modulo)
 --Mod for 1 based numbers.
 --3%3=3. 4%3=1, 1%3=1
 return (val-1)%modulo+1
end

function point_collides_box(
 _p,_box
)
 local _box_collider=_box.simple_collider
 local _origin=_box.origin
	return _p.x>=_box_collider.x1+_origin.x and
		_p.x<=_box_collider.x2+_origin.x and
		_p.y>=_box_collider.y1+_origin.y and
		_p.y<=_box_collider.y2+_origin.y
end

function point_collides_poly(
 _p,_obj
)
	local _pnts={}
 
 for _pnt in all(_obj.collider) do
  add(
   _pnts,
   {
    x=_pnt.x+_obj.origin.x,
    y=_pnt.y+_obj.origin.y
   }
  )
 end
	
	for i=1,#_pnts do
		local j=mod(i+1,#_pnts)
		if not below_line(
				_p,_pnts[i],_pnts[j]
			) then
   return false
  end
	end
 return true
end


function below_line(_p,_l1,_l2)
 local v1 = vec(
  _l2.x-_l1.x,
  _l2.y-_l1.y
 )
 local v2 = vec(
  _p.x-_l1.x,
  _p.y-_l1.y
 )
 return v1.x*v2.y - v1.y*v2.x > 0
end


function limit(val,mn,mx)
 --Limit a value to within a
 -- range
 return min(mx,max(mn,val))
end


function sign(_val)
 if (_val==0) return 0
 return sgn(_val)
end

function init_long(_l)
 local _o={}
 for i=1,_l do
  add (_o,0)
 end
 return _o
end

function add_to_long(_long,_to_add,_offset)
 _offset=_offset or 0
	_long[_offset+1]+=_to_add
 for i=_offset+2,#_long do
  if _long[i-1]>=1000 then
   _long[i]+=flr(_long[i-1]/1000)
   _long[i-1]=_long[i-1]%1000
  end
 end
end

function print_long(
	_long,
	_x,_y,_zero_col,_col
)
	local _n,_c=1,_zero_col
	for _plc = 1,#_long do
  local _num=_long[#_long-_plc+1]
		local _check_size = 100
		while _num < _check_size and 
			_check_size >= 1 do
   if _check_size==1 and _plc==#_long then
    _c=_col
   end
			print("0",_x,_y,_c)
			_x+=4
			_check_size/=10
		end
		if _num > 0 then
			_c=_col
			print(_num,_x,_y,_c)
			_x+=4*#tostr(_num)
		end
		if _n < #_long then
			print(",",_x,_y)
			_x+=3
		end
		_n+=1
	end
end

function is_bigger_long(a,b)
 for i=3,1,-1 do
  if a[i]>b[i] then return true
  elseif a[i]<b[i] then return false
  end
 end
 return false
end


function get_frame(_frames,_f,_spd,_f_start)
 _f_start=_f_start or 0
	return _frames[
		flr((_f-_f_start)/_spd)%#_frames+1
	]
end

function gen_polygon(_pnts_str)
 -- create a list of vertices
 -- by unpacking a string
 local _pnts=split(_pnts_str)
 local _output = {}
 for i = 1,#_pnts,2 do
  add(_output,vec(_pnts[i],_pnts[i+1]))
 end
 return _output
end


__gfx__
000000000000f0000000000077000575660660d060607000ddddddddddddddddddddddddddddddddd77777777777777777dddddddddddddddddddddddddddddd
0000000000072f0000000077700007666886806068607000ddddddddddddddddddddddddddd77777770000000000000007777777dddddddddddddddddddddddd
0070070000072f0000007777000005d5688680d068600000dddddddddddddd8dddddddddd77700000000000000000d000000000777dddddddddddddddddddddd
0007700000788f0000777770000000006806800060600000ddddd77dddddd28dddddddd7770000000000000000000000000000000777dddddddddddddddddddd
0007700000722f007777700000000000680600000000f000dddd766dddddd28dddddd77700000000000000000000000000000000000777dddddddddddddddddd
0070070000728f0072770000000000000060604000072f00edd5776ddddddd22dddd77000000000000000000000000000000000000000777eeedddeeeddddddd
0000000000728f0077700000000000000660044400072f00eeee777ddddddddddd777000000000000000000000000000000000000000000777eeeeeeeeeedddd
0000000007222f0000000000000000006600604000788f00eeeee677dddddddd77700000000000000000000000000000000000000000000007eeeeeeeeeeeeed
0088880007882f0000000000000000006000000000722f00eeeeeee7ddddddd77000000000000000000000000000000000000000000000000077dddddddddddd
08dddc8007282f0000000000000000004044400007028f00dddd65577ddddd7700000000000000000000000000600000000000000000000000077ddddddddddd
8dccdcd807222f0000000000000000004440440007028f00ddddd656ddddd770000006000000000000000000000000000000000000000000000077dddddddddd
85c88cd87282f00000000000000000000404400070222f00dddddddddddd77000000000000000000000000000000000000000000000000000000077ddddddddd
81d88dc8f2ff000000000000000000004440400070882f00ddddddddddd77000000000000000000000d0000000000000000000000000000000000077dddddddd
851cccd80f00000000000000000000000044440070282f00ddddddddddd700000000000f0000000000000000000000000000060000000000000000077ddddddd
085555800000000000000077770000000044040070222f00dddddddddd770000000000ff0000000000000000000000000000000000000000000000007ddddddd
00888800000000007777777770000000000000007282f000dddddddddd70000000000fef0000000e00000e00000e00000e00000fffff00000050000077dddddd
0088880000000000727777000000000000000000f2ff0000ddddddddd77000000000feef0000000e00000ed0000e00000e00000feeeeff0000000000077ddddd
08776680000000007770000000000000000000000f000000ddddddddd7000000000feeefff00000e00000e00000e00000e00000feeeeeeff000000000077dddd
875776780000000000000000000000006666666666066066ddddddddd700000000ff222eef00000e00000e00000e00000e00000ffffeeeeef00000000007dddd
867887780077770000000000000000008888608886886086ddddddddd700000000f2222eef000000000000000000000000000000000feeeeef00000000077ddd
857886780666666000000000000000000088000000886086ddddddddd70000000f22222ff00000000000000000000000000000000000feeeeef0000000007ddd
866777780077770000000000000000000000000000086086dddddddd770000000f2222ff0000000000000000000000000000000000000feeeeef000000007ddd
086556800000000000000000000000000000000000086006dddddddd70000000f2222ff00000000000000000000000000000000000ddd0feeeef000000007ddd
008888000000000000000000000000000000000000000000dddddddd70000000f222ff00000000000000000000000d0000000000000d00feeeef000000007ddd
008888000000000000000000000000000000000000000000dddddddd7000000f222ff00000000000600000000000000000000000000d00feeeef000000007ddd
08cccc800000000000000000000000000000000000000000dddddddd7005000f222f00000000000000000000000000000000000000ddd0feeeef000000007ddd
877cc7780077770077777700000000000000000000000000dddddddd7000000f222f000000000000000000000000000000000000000000feeef0000060007ddd
81b88bc80077770072777777777000000000000000000000dddddddd7000000f222f0000000000000000000000000000000000d000000feeeef0000000007ddd
89a887780666666077777700000000000000000000000000dddddddd7000000f222f00000000000000000050000000000000000000000feeef00000000007ddd
81366bc80077770000000000000000000000000000000000dddddddd7000000f222f0000000000000000000000000000000000000000feeef000000000007ddd
08133b800077770000000000000000000000000000000000dddddddd70000000f2ff00060000000000000000000d0600000000000000feff00000000000e7ddd
008888000000000000000000000000000000000000000000dddddddd70000000f2ff000000000000500000000000000000000000000fff0000000000000e7ddd
008888000000000000000000000000000000000000000000dddddddd700000000f2f000000000000000000000000000000000000000ff0000000000000e07ddd
08eeeb800000000000000000000000000000400000000000dddddddd770000000f2f000000000000000000000000000000000000000f00000000000000e07ddd
8bbbbbb800000000000000000000000000004f0000000000ddddddddd700000000f2f0000000000000000000000000000000000000000000005000000e007ddd
82b88ee800666600000000000000000004400f4000000000ddddddddd700000000f2f0000000000000000000000000000000000000000000000000007e007ddd
82e88eb806666660000000000000000000ff00ee88000000ddddddddd7006000000f2f0000000000006000000000000000000000005000000000000770007ddd
833bbbe800666600777000000000000000044ee88f700000ddddddddd7000000000f2f0000000000000000000000000000000000000000000000007770007ddd
08222e800000000072777700000000000000e8ff88770000ddddddddd77000000000fff0000000000000000000d0500000000000000000000000077d70007ddd
00888800000000007777777770000000000082f872f70000dddddddddd70000000000ff00000000000000000000000000000000000000000000077dd70007ddd
00000000000000000000007777000000000f82f878ff0000dddddeeeee700000000000ff000000000000000000000000000000000000000000777ddd70007ddd
00000000000000000000000000000000000f2f77f8f88000ddddeeeeee7700000000000f0000000000000000000000000000d00000000000777ddddd70007ddd
00000000000000000000000000000000007f8f78ff7f8700deeeeeeeeee700000000000000000000000000000000000000000000000007777dddd11170007ddd
0000000000000000000000000000000007788ff8877f8870ddddddddddd700000000000000000000000000000000000000000000007777dddddddd1d70007ddd
00000000067777600000000000000000077888fff666f770ddddddddddd770000000000000000600000000000000000000000000777dddd8888ddd1d70007ddd
000000000000000000000000000000000077776666667700dddddddddddd700000000000000000000000000000000000000000077dddd88888888d1d70007ddd
000000000000000000000000000000000006666777770000dddddddddddd70000000000000000005000000000060000000000077ddddd88777788ddd70007ddd
000000000000000000000000000000006666000000000000dddddddddddd77000000000000000000000000000000000000000077dddd8877777788dd70007ddd
00000000000777ff777000000000000000000777777777ffddddddddddddd7000000000000000000000000000000000000000007dddd8877887788dd70007ddd
00000777777888f0727700000000000000077000000888f0ddddddd11ddd770000000000000000000000000000000000000000077ddd8877887788dd70007ddd
007778888788ff007777700000000000077008888788ff00dddddd1d1dd7700000000000000000000000000000000000000000007ddd8877777788ee70007edd
7788888878888f0000777770000000007f88888878888f00dddddd1d1dd70000000000000000000000000000000000000000000077ddd88777788eee70007eee
00fff8888788ff00000077770000000000fff8888788ff00dddddd11dd770000000000d000000000000000000500000000000000077ee88888888eee70007eee
00000ffffff888f0000000777000000000000ffffff888f0ddddddddd77000000000000000000000000000000000000000000000007eeee8888eeeee70007eee
00000000000fffff000000007700000000000000000fffffddddfddd7700000000000000000000000000000000000000000000000077dddddddddddd70007ddd
000000000000000000000000000000000000000000000000ddddfddd700000000000000000dd000000000000000000000000000000077dddddd7777d70007ddd
000077777770777777770777777000777777000077777000dddffddd700000000000000000d2000000000000000000000000000000007dddd777777770007ddd
000777777700777777700777777700777777700777777700dddfeddd700000006000000000120000000000000000000055555555500077ddd777077770007ddd
000000770007700000007700007707700007707700007700dd22eedd7700000000000000001200000006000000000000555555555500077d7700007770007ddd
000007700007777700007777777707777777707777777700dd222eddd77000000000000000112000000000000000000055555555500000777000077770007ddd
000007700007777000007777777007777777007777777700dd222edddd777000000000500011200000000000000000000000000000000070000d077770007ddd
000007700007700000007700770007700770007700007700d2222edddddd7770000000000011200000000000000000000000ddd0600000000000077d70007ddd
000077000077777777077000077077000077077000077000d2222edddddddd770000000001112000000000000000d0000000d0d000000000000077dd70007ddd
00007700007777777007700007707700007707700007700022222eddddddddd7000000d00111200000000000000000000000dd000000000000007ddd70007ddd
000000077000077007777700770000077007777700000000222222dddddffd77005000dd0111200000000050000000000000d0d00000000000077ddd70007ddd
00000007770007707777777077000007707777777000000022f222ddddeedd70000000d221112000000000000000000000000000000000000077dddd70007ddd
0000007777007707770007707700007707700007700000002ff2222eee22dd7000000011221110000d0000000000000000d0000000000dd0007ddddd70007d22
0000007707707707700007700770077707777777700000002fe22222222ddd700000000112110000000012200000000000d20000000dd110077ddedd70007222
00000077077077077000077007707770077777777000000022e2222222dddd7000000001121100000001111222200020000120000011110007ddd2edf000f222
000000770077770770007770077777000770000770000000222e22222dddd70000000011121100000111111111111112220120001111100077ddd222f000f222
000007700077700777777700077770007700007700000000222e222222ddd7000000111111100001111111111111111111111111111100007dddd222f000f222
000007700007700077777000007700007700007700000000222e22222222d7000111111111111111111111111111111111111111111111007d222222f000f222
0000000077700777707700077000770007000070000000002222e22222222f111111111111111111111111111111111111111111111111111f222222f000f222
000000007770077770770007770777700700007000000000ee22e22222222f111111111111111111111111111111111111111111111111111f222222f000f222
0000000700700070070070700707007070000700000000002ee22e222222f1111111111111111111111111111111111111122222211111111f222222f000f222
00000007777000700700707777077770700007000000000022222e222222f11111111111111111111111111111111111111111112222221111f22222f000f222
00000007770007000700707770077770700007000000000022222ee22222f11111111112222211111111111111111111111111111111111111f22222f000f222
000000770000070070070700707000707000070000000000222222e22222f111112222211112222221111111111111111111111111111111111f2222f000f222
000000700007777070070777707007077770777700000000222222222222f111111111111111111122111111111111111111111111111111111f2222f000f222
00000070000777707007077700700707777077770000000022222222222f1111111111111111111111111111111111111111111111111111111f2222f000f222
00000000000000000000cccccccc0000000000000000000022222222222f11111111111111111111111111111111111111111111111111111111f222f000fe22
0000000000000000cccccc1111cccccc000000000000000022222222222f11111111111111111111111111111111111111111111111111111111f222f000f222
00000000000000cc1111cc11c1cc1111cc0000000000000022222222222ff111111111111111111111111111111111111111111111111111111ff222f000fee2
000000000000cccc11c11c111ccc11c1cccc000000000000222222222222ff1111111111111111111111111111111111111111111111111111ff2222f000f222
00000000000cc1cc11cc1c11c1c11111c11cc000000000002222222222222ff11111111111111111111111111111111111111111111111111ff22222f000fe22
000000000ccc111cc11c1cd666c11c1cc11cccc00000000022222222222222ff111111111111111111111111111111122211111111111111ff222222f000f222
00000000cc1cc111c1ccc5d7776ccc1c11cccccc000000002222222222222ff11111111111111111111111111111122112222211111111111ff22222f000fee2
0000000cc111cc11ccc1556677761ccc11ccc11cc0000000ddddddddd222ff1111111111111111111111111111222211111111111111111111ff2222f000f222
000000cc11c1ccccc111ddd66676111cc11c111ccc000000ddddddddddd2f111111111111111111111111111111111111111111111111111111f2222f000fe22
00000ccc111cccc1111166ddd66d11111cc111ccccc00000d7d7ddddddddf111111111111111111111111111111111111111111111111111111f2222f000f222
00000cccc111cc111111776ddddd111111cc1cccccc00000d7d7ddddd44df111111111111111111111111111111111111111111111111111111f2222f000fee2
0000cccc7c1cc11111111766d5511111111c11c7cccc0000d777d7d7d44df111111111111111111111111111111111111111111111111111111f2222f000f222
000ccccccccc11111177116d551177111111ccccccccc000ddd7dd7dddddf111111111111111111111111111111111111111111111111111111f2222f000fe22
000ccc7cccc11111777771aaaa17777711111cccc7ccc000ddd7d7d7ddddf111f1111111111111111111111111111111111111111111111f111f2222f000f222
00cccccccc11111777e7771aa177e777711111cccccccc00ddddddddddddf111ff11111111111111111111111111111111111111111111ff111f2222f000fee2
00cc77ccc1111177ee77e71a717e7e7ee711111ccc77cc00d777ddddddddf111ff11111111111111111111111111111111111111111111ff111f2222f000f222
0ccc77ccc11117eeeeeeee1771eeeeeeee71111ccc77ccc0ddd7ddddd44df111ff11111111111111111111111111111111111111111111ff111f2222f000fe22
0ccccccc11117eeee2e2e21aa12e2e2eeee71111ccccccc0dd77d7d7d44df111ff11111111111111111111111111111111111111111111ff111f2222f000f222
0cc77ccc111eeeee2e2e2e1a7712e2e2eeeee111ccc77cc0ddd7dd7dddddf111ff11111111111111111111111111111111111111111111ff111f2222f000fee2
0cc77ccc111ee2e2e222221aaa12222e2e2ee111ccc77cc0d777d7d7ddddf111ff11111111111111111111111111111111111111111111ff111f2222f000f222
ccccccc111ee21111111111a7a1111111112ee111cccccccddddddddddddf111ff11111111111111111111111111111111111111111111ff111f2222f000fe22
cc7c7cc111eee199919911aa7a199919991eee111cc7c7ccd777ddddddddf111ff11111111111111111111111111111111111111111111ff111f2222f000f222
ccc7ccc111ee2119119191777a1919191912ee111ccc7cccddd7ddddd44df111ff11111111111111111111111111111111111111111111ff111f2222f000f222
cc7c7cc11ee21219119191aa7719991991112ee11cc7c7ccd777d7d7d44df111ff11111111111111111111111111111111111111111111ff111f2222f000f222
ccccccc11e2121191191911aaa191119191212e11cccccccd7dddd7dddddf111ff11111111111111111111111111111111111111111111ff111f2222fffff222
cc7c7cc112e211191191911aaa19111919112e211cc7c7ccd777d7d7ddddf111ff11111111111111111111111111111111111111111111ff111f222222222222
ccc7ccc11e2111191191911a7a191119991112e11ccc7cccddddddddddddf111ff11111111111111111111111111111111111111111111ff111f222222222222
cc7c7cc112111111111111aa7a111111111111211cc7c7ccd77dddddddddf1111ff111111111111111111112211111111111111111111ff1111f227272222222
0ccccccc11111111111111aa7a11111111111111ccccccc0dd7dddddd44df11111ff1111111111111111122121111111111111111111ff11111f222772222222
0cc7c7cc12111111111111a777a1111111111121cc7c7cc0dd7dd7d7d44df111111fff111111111111112211222211111111111111fff111111f227772222222
0ccc7ccc11111111111111a777aa111111111111ccc7ccc0dd7ddd7dddddf1115111fff1111111111222211111122111111111111fff1115111f222272277772
0cc7c7ccc1111111aa111aa77a88a11111111aaaac7c7cc0d777d7d7ddddf11111111fff11111111111111111111122211111111fff11111111f222277777777
00ccccccc1111111a8811a877aaa891111111a88accccc00ddddddddddd2f5115111111ff111111111111111111111111111111ff1111115115f222277777777
00ccc7c7aaa111111811aa877a8889111111aa888ac7cc00ddddddddd222f55111111111ff1111111111111111111111111111ff11111111155f222677777777
000ccc7c98aa1111111a88a77aaaa911111aaaaaaaacc000222222222222f155111111111ff11111111111111111111111111ff111111111551f222677777777
000cc7c79888a11111aaaa8877a88aaa11aa99999999c0002222dd222222f115f111111111ff111111111111111111111111ff111111111f511f226667777766
0000cccc9988a11119888aa777a88a8aaa999888889900002222d2d22222f111ff111111111ff1111111111111111111111ff111111111ff111f226667777655
00000cc7c9988aaa19888a8aaaa8888aa9988888889900002222dd222222f111fff111111111111111111111111111111111111111111fff111f226666577766
00000cc99888a99a1199888888a8999988889888889000002222d2d22222f111f2ff1111111111111111111111111111111111111111ff2f111f222665657777
000000c988888a99aaaa88899888888888889988899000002222ddd22222f111f22ff11111111111111111111111111111111111111ff22f111f222225656677
000000098888a999999aaa88888888888888898899000000222222222222f111f222ff111111111111111111111111111111111111ff222f111f222222222222
000000099988aa9aaaa99988888899988988899990000000222222222222f111f2222ff1111111111111111111111111111111111ff2222f111f222222222222
00000000999899aaa9988888898888989988899900000000222222222222fffff22222ff11111111111111111111111111111111ff22222fffff222222222777
00000000009888999988889999888888988899000000000022222222222222222222222ff111111111111111111111111111111ff22222222222222222226777
000000000009888888888888888888899999900000000000222222222222222222222222ff1111111111111111111111111111ff222222222222222222226677
0000000000000999888898888988899999900000000000002222222222222222222222222ff11111111111111111111111111ff2222222222222222222222666
00000000000000099999988999999999900000000000000022222222222222222222222222ff111111111111111111111111ff22222222222222222222222622
000000000000000000099999999990000000000000000000222222222222222222222222222ff1111111111111111111111ff222222222222222222222222222
__map__
060708090a0b0c0d0e0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
161718191a1b1c1d1e1f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
262728292a2b2c2d2e2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
363738393a3b3c3d3e3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
464748494a4b4c4d4e4f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
565758595a5b5c5d5e5f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
666768696a6b6c6d6e6f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
767778797a7b7c7d7e7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
868788898a8b8c8d8e8f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
969798999a9b9c9d9e9f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a6a7a8a9aaabacadaeaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b6b7b8b9babbbcbdbebf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c6c7c8c9cacbcccdcecf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d6d7d8d9dadbdcdddedf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e6e7e8e9eaebecedeeef00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f6f7f8f9fafbfcfdfeff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0106000000532276050b6050e6051160515605186051c6051f6052260525605286052a6052d6052f6053160533605356053a60535605336052e60527605226051d60518605136050c60507605036053860500605
910500001b75518700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
010400001d75529700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001f75522700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002275500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002475500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002775500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002975500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002b75500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002e7552e700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600002275024755247002775029755277002475027755000002b75030750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490600000051300500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
490600000453304100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
491000001f53700500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
490a00001131500303003030030300303003030030300303003030030300303003030030300303003030030300303003030030300303003030030300303003030030300303003030030300303003030030300303
491000001b325183221b3251b1031f325001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103
011000001b73022720225101f7302472024510297302772029700277002e7002b700297002e700000002b7001b70022700225001f70024700245002970027700297002e700000002b7002b700000000000000000
491000200c0330050000625006231862500000006250000000133000000052300003186250000000513000000c033005130000000000186250000000513000000013300000005230000318625000000051300000
611000000210002000001300012500110001300012500110001300012500110031300312003110001350011003100031000013000125001100313003120031100313003120031100513005125051100313503110
491000000210002000051300512505110031300312503110051300512505110031300312503110051350511003100031000513005125051100313003120031100013000125001100313003120031100013500110
016000201b7141b7101b71517500227142271222712227151f7141f7101f715005002471424712247122471529714297102971524702277142771027715005002471424710247150050029714297122971229715
016000002771427710277151750022714227122271222715247142471024715005001f7141f7121f7121f715227142271022715247021d7141d7101d71500500227142271022715005001f7141f7121f7121f715
010200000361200600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00180000187341b7311d7311f7311d7241f7212272124721227242472127711297110070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
490e00001633013333223301d30030300333003530030300303003d3003f300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
00080000180431d0311b043220351b0431f0311d043240351d043220311f043270350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49080000180231b0111b0150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000180331d021270001b0331f021180001803322031220250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003175333743347333570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002b02038020220202f6202e6212a62126621216211d6211861117611186111a6111c61120611256112a61132611386113e6113f615326003460036600396003c600000000000000000000000000000000
0d100000132300f2400c2300f2400c2200a2110a21500200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
0a1000000f230132401123016240132300f2400c2300f2400c2200a2210a211072210721500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 10111244
01 41111244
02 41111344
01 14514344
02 15424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
__label__
00000000000000000000000000000050000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d0d00000dd000000ddd00000ddd000000000010000000000000000000000000000000ddd0d0d00000ddd0ddd0ddd0ddd000000dd0d0d0ddd0ddd00dd0dd000
00d0d000000d00000000d00000d0d000000000000000000000000000000000000000000d0d0d0d00000ddd0d0d00d000d000000d000d0d00d000d00d0d0d0d00
00d0d000000d000000ddd00000d0d000000000000000000000000000000000000000000dd00ddd00000d0d0ddd00d000d000000ddd0d0d00d000d00d0d0d0d00
00ddd000000d000000d0000000d0d000000000000000000000000000000000000000000d0d000d00000d0d0d0d00d000d00000000d0d0d00d000d00d0d0d0d00
000d000000ddd00d00ddd00d00ddd000000000000000000000000000000000000000000ddd0ddd00000d0d0d0d00d000d000000dd000dd00d000d00dd00d0d00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00d0d0ddd0ddd0ddd0ddd0dd00d0d00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0d0d0d00d00d0000d00d0d0d0d0d0d00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0d00d000d00dd000d00ddd0d0d0d0d00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000d0d00d00d0000d00d0d0d0d0d0d00
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd0d0d0ddd0ddd00d00d0d0d0d00dd00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000c0000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000c000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000
00000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000c0c000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000777777707777777707777770007777770000777770000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007777777007777777007777777007777777007777777000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007700077000000077000077077000077077000077000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000077000077777000077777777077777777077777777000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000077000077770000077777770077777770077777777000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000077000077000000077007700077007700077000077000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000770000777777770770000770770000770770000770000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000770000777777700770000770770000770770000770000000000000000000000000000000000000000000
0000000000c000000000000000000000000000000d00000770000770077777007700000770077777000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000777000770777777707700000770777777700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007777007707770007707700007707700007700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007707707707700007700770077707777777700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007707707707700007700770777007777777700000000000000500000000000000000000000000000000
00000000000000000000000000000000000000000000007700777707700077700777770007700007700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000077000777007777777000777700077000077000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000077000077000777770000077000077000077000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000
00000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000cccccccc000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000cccccc1111cccccc00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000cc1111cc11c1cc1111cc000000000000000000000c00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000cccc11c11c111ccc11c1cccc0000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000cc1cc11cc1c11c1c11111c11cc00000f000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000ccc111cc11c1cd666c11c1cc11cccc0000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000cc1cc111c1ccc5d7776ccc1c11cccccc000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000cc111cc11ccc1556677761ccc11ccc11cc000d0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000cc11c1ccccc111ddd66676111cc11c111ccc0000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000ccc111cccc1111166ddd66d11111cc111ccccc000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000cccc111cc111111776ddddd111111cc1cccccc000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000cccc7c1cc11111111766d5511111111c11c7cccc00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000ccccccccc11111177116d551177111111ccccccccc0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000ccc7cccc11111777771aaaa17777711111cccc7ccc0000000000000000000000000000000000000000000
000000000000000000000000000000000000000000cccccccc11111777e7771aa177e777711111cccccccc000000000000000000000000000000000000000000
000000000000000000000000000000000000600000cc77ccc1111177ee77e71a717e7e7ee711111ccc77cc000000000000000000000000000000000000000000
00000000000000000000000000000000000000000ccc77ccc11117eeeeeeee1771eeeeeeee71111ccc77ccc00000000000000000000000000000000000000000
00000000000000000000000000000000000000000ccccccc11117eeee2e2e21aa12e2e2eeee71111ccccccc00000000000000000000000000000000000000000
00000000000000000000000000000000000000000cc77ccc111eeeee2e2e2e1a7712e2e2eeeee111ccc77cc00000000000000000000000000000000000000000
00000000000000000000000000000000000000000cc77ccc111ee2e2e222221aaa12222e2e2ee111ccc77cc00000000000000000000000000000000000000000
0000000000000000000000000000000000000000ccccccc111ee21111111111a7a1111111112ee111ccccccc0000000000000000000000000000000000000000
0000000000000000000000000000000000000000cc7c7cc111eee199919911aa7a199919991eee111cc7c7cc0000000000000000000000000000000000000000
0000000000000000000000000000000000000000ccc7ccc111ee2119119191777a1919191912ee111ccc7ccc0000000000000000000000000000000000000000
0000000000000000000000000000000000000000cc7c7cc11ee21219119191aa7719991991112ee11cc7c7cc0000000000000000000000000000000000000000
0000000000000000000000000000000000000000ccccccc11e2121191191911aaa191119191212e11ccccccc0000000000000000000000000000000000000000
0000000000000000000000000000000000000000cc7c7cc112e211191191911aaa19111919112e211cc7c7cc0000000000000000000000000000000000000000
0000000000000000000000000000000000000000ccc7ccc11e2111191191911a7a191119991112e11ccc7ccc0000000000000000000000000000000000000000
0000000000000000000000000000000000000000cc7c7cc112111111111111aa7a111111111111211cc7c7cc0000000000000000000000000000000000000000
00000000000000000000000000000000000000000ccccccc11111111111111aa7a11111111111111ccccccc00000000000000000000000000000000000000000
00000000000000000000000000000000000000000cc7c7cc12111111111111a777a1111111111121cc7c7cc00000000000000000000000000000000000000000
00000000000000000000000000000000000000000ccc7ccc11111111111111a777aa111111111111ccc7ccc00000000000000000000000000000000000000000
00000000000000000000000000000000000000000cc7c7ccc1111111aa111aa77a88a11111111aaaac7c7cc00000000000000000000000000000000000000000
000000000000000000000000000000000000000000ccccccc1111111a8811a877aaa891111111a88accccc000000000000000000000000000000000000000000
700000000000000000000000000000000000000000ccc7c7aaa111111811aa877a8889111111aa888ac7cc000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000ccc7c98aa1111111a88a77aaaa911111aaaaaaaacc0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000cc7c79888a11111aaaa8877a88aaa11aa99999999c0000000000000000000000000000000000000000000
000000000000000000000000000c0000000000000000cccc9988a11119888aa777a88a8aaa999888889900000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000cc7c9988aaa19888a8aaaa8888aa9988888889900000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000cc99888a99a1199888888a8999988889888889000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000c988888a99aaaa88899888888888889988899000000000000000000000c00000000000000000000000
0000000000000000000000000000000000000000000000098888a999999aaa888888888888888988990000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000099988aa9aaaa999888888999889888999900000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000999899aaa99888888988889899888999000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000d00000000000988899998888999988888898889900000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000098888888888888888888999999000000000000000000000000000000000000000000000000000
000000000000000000d0000000000000000000000000000000000999888898888988899999900000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000009999998899999999990000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000999999999900000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000
0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000
00000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000