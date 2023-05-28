pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--~awake~
--mod by sparky9d
--with help from michael,rubyred
--gonen, snek and taco
--huge thank you to my playtesters
--snek,taco,kamera,teal,avi,kimo
--supreee, vawlpe and michael

--original "celeste" made by
--maddy thorson and noel berry

--based on evercore v3.6
--a celeste classic mod base
--made by taco360
--based on meep's smalleste
--and akliant's hex loading
--with help from gonengazit
cartdata("celeste-awake_v1-1")
poke(0x5f2e,1)
menuitem(3,"reset cart data",function()
for i=0,63 do
dset(i,0)
end
end)
function vector(x,y)
return {x=x,y=y}
end
function rectangle(x,y,w,h)
return {x=x,y=y,w=w,h=h}
end
atrans={y=-1000,spd=16}
objects,got_fruit,
freeze,delay_restart,sfx_timer,
ui_timer=
{},{},
0,0,0,-99
title_fall,title_offset,spawn,f,skip,ascend,ld=0,0,vector(-1,-1),0,false,false,0
lvl_delay=-1
function _init()
frames,start_game_flash=0,0
music(16,0,7)
load_level(0)
end
function begin_game()
create_particles()
max_djump,deaths,frames,seconds_f,minutes,time_ticking,new_bg,newer_bg,newest_bg,got_fruit=0,0,0,0,0,false,false,false,false,{}
music(13,0,7)
load_level(1)
end
function is_title()
return lvl_id==0
end
clouds={}
for i=0,16 do
add(clouds,{
x=rnd(128),
y=rnd(128),
spd=0.5+rnd(3),
w=32+rnd(32)
})
end
function create_particles()
particles={}
for i=0,24 do
add(particles,{
x=rnd(128),
y=rnd(128),
s=flr(rnd(1.25)),
spd=0.25+rnd(5),
off=rnd(),
c=lvl_id and 9 or 6+rnd(2)
})
end
end
create_particles()
dead_particles={}
menuitem(2,"retry",kill_player)

player={
  init=function(this)
    this.djump,this.jg,this.dash_time,this.dash_effect_time,this.dash_target_x,this.dash_target_y,this.grace,this.jbuffer,this.dash_accel_x,this.dash_accel_y,this.hitbox,this.spr_off,this.solids,this.berry_count,this.berry_timer=max_djump,false,0,0,0,0,0,0,0,0,rectangle(1,3,6,5),0,true,0,0
    if lvl_id==1 then
      this.p_jump=true
    end
    create_hair(this)
  end,
  update=function(this)
    if pause_player then
      return
    end
    local h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0
    if spikes_at(this.x+this.hitbox.x,this.y+this.hitbox.y,this.hitbox.w,this.hitbox.h,this.spd.x,this.spd.y)
	   or	this.y>lvl_ph then
	    kill_player()
    end
    local on_ground=this.is_solid(0,1)
    if on_ground then
      this.berry_timer+=1
      this.jg=false
    else
      this.berry_timer,this.berry_count=0,0
    end
    local fr
    for f in all(fruitrain) do
      if f.type==fruit then
        fr=f
      end
    end
    if this.y<-4 and fr and not fr.golden then
      got_fruit[fr.level]=true
      init_object(lifeup, fr.x, fr.y)
      del(fruitrain, fr)
      destroy_object(fr)
      this.berry_timer=-5
      this.berry_count+=1
      dset(lvl_id,1)
      if (fruitrain[1]) fruitrain[1].target=get_player()
      lvl_delay,ld=20,lvl_id+1
      sfx(13)
      destroy_object(this)
    end

    if on_ground and not this.was_on_ground then
      this.init_smoke(0,4)
    end

    printh("circ x")
    local jump=btn(🅾️) and not this.p_jump
    printh("after circ before x")
    --local dash=btn(❎) and not this.p_dash
    local dash=btn(❎) and not this.p_dash
    printh("circ x")
    this.p_jump=btn(🅾️)
    --this.p_dash=btn(❎)
    this.p_dash=btn(4)
    printh("done")

    if jump then
      this.jbuffer=4
    elseif this.jbuffer>0 then
      this.jbuffer-=1
    end

    if on_ground then
      this.grace=6
      if this.djump<max_djump then
        psfx(54)
        this.djump=max_djump
      end
    elseif this.grace>0 then
      this.grace-=1
    end

    this.dash_effect_time-=1

    if this.dash_time>0 then
      this.init_smoke()
      this.dash_time-=1
      this.spd=vector(appr(this.spd.x,this.dash_target_x,this.dash_accel_x),appr(this.spd.y,this.dash_target_y,this.dash_accel_y))
    else
      local maxrun=1
      local accel=on_ground and 0.6 or 0.4
      local deccel=0.15

      this.spd.x=abs(this.spd.x)<=1 and
        appr(this.spd.x,h_input*maxrun,accel) or
        appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)

      if this.spd.x~=0 then
        this.flip.x=(this.spd.x<0)
      end

      local maxfall=2

      if h_input~=0 and this.is_solid(h_input,0) then
        maxfall=0.4
        if rnd(10)<2 then
          this.init_smoke(h_input*6)
        end
      end

      if not on_ground then
        this.spd.y=appr(this.spd.y,maxfall,abs(this.spd.y)>0.15 and 0.21 or 0.105)
      end
      
      local has_jumped=false
      if this.jbuffer>0 then
        if this.grace>0 then
          psfx(1)
		        this.jbuffer,this.grace,this.spd.y,this.jg=0,0,-2,false
		        this.init_smoke()
          has_jumped=true
        else
          local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
          if wall_dir~=0 then
            psfx(2)
            this.jbuffer,this.spd.y,this.spd.x=0,-2,-wall_dir*(maxrun+1)
            this.init_smoke(wall_dir*6)
            has_jumped=true
          end
        end
        if this.jg and not has_jumped then
          this.jbuffer,this.grace,this.spd.y,this.jg=0,0,-2,false
        end
      end

      local d_full=5
      local d_half=3.5355339059

      if this.djump>0 and dash then
        this.init_smoke()
        this.djump-=1
        this.dash_time=4
        has_dashed=true
        this.dash_effect_time=10
        local v_input=btn(⬆️) and -1 or btn(⬇️) and 1 or 0
        this.spd=vector(h_input~=0 and
        h_input*(v_input~=0 and d_half or d_full) or
        (v_input~=0 and 0 or this.flip.x and -1 or 1)
        ,v_input~=0 and v_input*(h_input~=0 and d_half or d_full) or 0)
        psfx(3)
        freeze=2
        this.dash_target_x=2*sign(this.spd.x)
        this.dash_target_y=(this.spd.y>=0 and 2 or 1.5)*sign(this.spd.y)
        this.dash_accel_x=this.spd.y==0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
        this.dash_accel_y=this.spd.x==0 and 1.5 or 1.06066017177
      elseif this.djump<=0 and dash then
        -- failed dash smoke
        psfx(9)
        this.init_smoke()
      end
    end

    -- animation
    this.spr_off+=0.25
    this.spr = not on_ground and (this.is_solid(h_input,0) and 5 or 3) or  -- wall slide or mid air
      btn(⬇️) and 6 or -- crouch
      btn(⬆️) and 7 or -- look up
      1+(this.spd.x~=0 and h_input~=0 and this.spr_off%4 or 0) -- walk or stand

    if not ascend then
      move_camera(this)
    end

    if lvl_delay<1 and this.y<-4 and lvl_id~=13 and lvl_id~=18 and lvl_id~=23 then
      if (lvl_id==4 and max_djump>0) or lvl_id==8 or lvl_id==20 then
        ld=lvl_id+1
        atrans.y=128
        lvl_delay=10
        destroy_object(this)
      else
        if lvl_id==4 and max_djump==0 then
          load_level(14)
        else
          next_level()
        end
      end
    end
    if this.x<-4 and lvl_id==13 and max_djump>1 then
      load_level(19)
    end
    this.was_on_ground=on_ground
  end,

  draw=function(this)
    local v=((lvl_id==13 and max_djump==2)) and -5 or -1
  		if this.x<v or this.x>lvl_pw-7 then
   		  this.x=mid(this.x,v,lvl_pw-7)
   		  this.spd.x=0
  		end
    if this.jg then
      pal(3,14)
      ?"🅾️",this.x,this.y-6,6
    end
    set_hair_color(this.djump)
    draw_hair(this,this.flip.x and -1 or 1)
    draw_obj_sprite(this)
    unset_hair_color()
    pal(3,3)
  end
}

function create_hair(obj)
  obj.hair={}
  for i=1,5 do
    add(obj.hair,vector(obj.x,obj.y))
  end
end

function set_hair_color(djump)
  pal(8,djump==1 and 14 or djump==2 and 11 or 12)
end

function draw_hair(obj,facing)
  local last=vector(obj.x+4-facing*2,obj.y+(btn(⬇️) and 4 or 3))
  for i,h in pairs(obj.hair) do
    h.x+=(last.x-h.x)/1.5
    h.y+=(last.y+0.5-h.y)/1.5
    circfill(h.x,h.y,mid(4-i,1,2),8)
    last=h
  end
end

function unset_hair_color()
  pal(8,8)
end

function get_obj(obj)
  for o in all(objects) do
    if o.type==obj then
      return o
    end
  end
end

function get_player()
  return get_obj(player) or get_obj(player_spawn)
end

player_spawn={
  init=function(this)
    sfx(4)
    this.spr=3
    this.target=spawn.y==-1 and this.y or spawn.y
    this.y=min(spawn.y==-1 and this.y+48 or spawn.y+48,lvl_ph)
				cam_x=mid(spawn.x==-1 and this.x or spawn.x,64,lvl_pw-64)
				cam_y=mid(spawn.y==-1 and this.y or spawn.y,64,lvl_ph-64)
    this.spd.y=-4
    this.state=0
    this.delay=0
    this.x=spawn.x==-1 and this.x or spawn.x
    create_hair(this)
    for i=1,#fruitrain do
      local f=init_object(fruit,this.x,this.y,fruitrain[i].spr)
      f.target=i==1 and get_player() or fruitrain[i-1]
      f.follow,f.r,f.level,fruitrain[i]=
      true,fruitrain[i].r,fruitrain[i].level,f
    end
  end,
  update=function(this)
    if this.state==0 then
      if this.y<this.target+16 then
        this.state=1
        this.delay=3
      end
    elseif this.state==1 then
      this.spd.y+=0.5
      if this.spd.y>0 then
        if this.delay>0 then
          this.spd.y=0
          this.delay-=1
        elseif this.y>this.target then
          this.y,this.spd,this.state,this.delay=this.target,vector(0,0),2,5
          this.init_smoke(0,4)
          sfx(5)
        end
      end
    elseif this.state==2 then
      this.delay-=1
      this.spr=6
      if this.delay<0 then
        destroy_object(this)
        init_object(player,this.x,this.y)
        if (fruitrain[1]) fruitrain[1].target=p
      end
    end
    move_camera(this)
  end,
  draw=function(this)
    set_hair_color(max_djump)
    draw_hair(this,1)
    draw_obj_sprite(this)
    unset_hair_color()
  end
}

fruitrain={}
fruit={
  if_not_fruit=true,
  init=function(this)
    this.y_,this.off,this.follow,this.tx,this.ty,this.level,this.golden=this.y,0,false,this.x,this.y,lvl_id,this.spr~=26
    if this.golden and dget(0)==0 then
      destroy_object(this)
    end
  end,
  update=function(this)
    if not this.follow then
      local hit=this.player_here()
      if hit then
        sfx(53)
        hit.berry_timer,this.follow=0,true
        this.target=#fruitrain==0 and hit or fruitrain[#fruitrain]
        this.r=#fruitrain==0 and 12 or 8
        add(fruitrain,this)
        if lvl_id==3 then
          mset(79,9,0)
          mset(79,10,0)
          lvl_pw=384
          for i=23,30 do
            init_object(smoke,i*8,76)
          end
        end
      end
    else
      local p=get_player()
      if not this.target then
        if p then
          this.target=p
        end
      else
        this.tx+=0.2*(this.target.x-this.tx)
        this.ty+=0.2*(this.target.y-this.ty)
        local a=atan2(this.x-this.tx,this.y_-this.ty)
        local k=((this.x-this.tx)^2+(this.y_-this.ty)^2) > this.r^2 and 0.2 or 0.1
        this.x+=k*(this.tx+this.r*cos(a)-this.x)
        this.y_+=k*(this.ty+this.r*sin(a)-this.y_)
      end
    end
    if this.spr~=26 then
      this.spr=9.4+sin(this.off/40)
    end
    this.off+=1
    this.y=this.y_+sin(this.off/40)*2.5
  end,
  draw=function(this)
    if dget(lvl_id)==1 then
      pal(8,12)
      pal(2,13)
    end
    draw_obj_sprite(this)
    pal()
  end
}

spring={
	init=function(this)
		this.dy,this.delay=0,0
	end,
	update=function(this)
		local hit=this.player_here()
		if this.delay>0 then
			this.delay-=1
		elseif hit then
			hit.y,hit.spd.y,hit.dash_time,hit.dash_effect_time,this.dy,this.delay,hit.djump,hit.jg=this.y-4,-3,0,0,4,10,max_djump,false
			hit.spd.x*=0.2
			psfx(8)
		end
	this.dy*=0.75
	end,
	draw=function(this)
		local dy=flr(this.dy)
		sspr(16,8,8,8-dy,this.x,this.y+dy)
	end
}

balloon={
  init=function(this)
    this.offset,this.start,this.timer,this.hitbox=rnd(),this.y,0,rectangle(-1,-1,10,10)
  end,
  update=function(this)
    if this.spr==22 then
      this.offset+=0.01
      this.y=this.start+sin(this.offset)*2
      local hit=this.player_here()
      if hit and (hit.djump<max_djump or max_djump==0) then
        psfx(6)
        this.init_smoke()
        hit.djump=(max_djump==0 and 1 or max_djump)
        this.spr=21
        this.timer=60
      end
    elseif this.timer>0 then
      this.timer-=1
    else
      psfx(7)
      this.init_smoke()
      this.spr=22
    end
  end
}

function break_fall_floor(obj)
  if obj.state==0 then
    psfx(15)
    obj.state,obj.delay=1,15
    obj.init_smoke()
    local hit=obj.check(spring,0,-1)
    if hit then
      hit.hide_in=15
    end
  end
end

adelie={
  draw=function(this)
    spr(83,this.x-4,this.y-2)
    sspr(18,38,6,2,this.x-6,this.y+6)
    sspr(18,38,6,2,this.x,this.y+6,6,2,true)
  end
}

smoke={
  init=function(this)
    this.spd,this.flip,this.spr=vector(0.3+rnd(0.2),-0.1),vector(maybe(),maybe()),29
    this.x+=-1+rnd(2)
    this.y+=-1+rnd(2)
  end,
  update=function(this)
    this.spr+=0.2
    if this.spr>=32 then
      destroy_object(this)
    end
  end
}

jump_gem={
  init=function(this)
    this.offset,this.start,this.timer,this.hitbox=rnd(),this.y,0,rectangle(-1,-1,10,10)
  end,
  update=function(this)
    if this.spr==19 then
      this.offset+=0.01
      this.y=this.start+sin(this.offset)*2
      local hit=this.check(player,0,0)
      if hit then
	      if not hit.jg and not hit.standing then
          psfx(6)
          this.init_smoke()
          hit.jg,this.spr,this.timer=true,21,60
	      	end
      end
    elseif this.timer>0 then
      this.timer-=1
    else
      psfx(7)
     	this.init_smoke()
      this.spr=19
    end
  end
}

lifeup={
  init=function(this)
    this.spd.y,this.duration,this.flash=-0.25,30,0
    this.x-=2
    this.y-=4
  end,
  update=function(this)
    this.duration-=1
    if this.duration<=0 then
      destroy_object(this)
    end
  end,
  draw=function(this)
    this.flash+=0.5
    ?"1000",this.x-2,this.y,7+this.flash%2
  end
}

function init_fruit(this,ox,oy)
  sfx_timer=20
  sfx(16)
  init_object(fruit,this.x+ox,this.y+oy,26)
  destroy_object(this)
end

side_plat={
  init=function(this)
    this.origin,this.dir,this.spd=this.x,1,
    {x=0.6,y=0}
  end,
  update=function(this)
    if this.check(player,0,-1) and not this.check(player,0,0) then
      this.check(player,0,-1).move(this.spd.x,0,1)
    end
    if this.dir==1 then
      this.spd.x+=0.1
      if this.x>this.origin+16 or this.is_solid(0,0) then
        this.dir,this.spd.x=0,0
      end
    else
      this.spd.x-=0.1
      if this.x<this.origin-16 or this.is_solid(0,0) then
        this.dir,this.spd.x=1,0
      end
    end
    this.spd.x=mid(this.spd.x,-1,1)
  end
}

smol_spring={
	init=function(this)
		this.dy,this.delay=0,0
	end,
	update=function(this)
		local hit=this.player_here()
		if this.delay>0 then
			this.delay-=1
		elseif hit then
			hit.y,hit.spd.y,hit.dash_time,hit.dash_effect_time,this.dy,this.delay,hit.djump=this.y-4,-2.2,0,0,4,10,max_djump
			hit.spd.x*=0.2
			hit.jg=false
			psfx(8)
		end
	this.dy*=0.75
	end,
	draw=function(this)
		local dy=flr(this.dy)
		sspr(64,16,8,8-dy,this.x,this.y+dy)
	end
}

tent={
  init=function(this)
    this.zy=this.y-4
    this.zc=7
    if not skip then
      poke(0x5f2c,3)
      this.ptimer,this.px,this.psprite,this.p=60,this.x,111,true
      lvl_ph=256
      cam_x=mid(spawn.x==-1 and this.x or spawn.x,64,lvl_pw-64)
				  cam_y=mid(this.y+32,64,lvl_ph-64)
    else
      this.ptimer=0
      this.px=this.x
      this.psprite=111
      this.p=false
      cam_x=mid(spawn.x==-1 and this.x or spawn.x,64,lvl_pw-64)
				  cam_y=mid(this.y+32,64,lvl_ph-64)
      init_object(player,this.x+10,this.y)
      time_ticking=true
      ui_timer=5
    end
  end,
  update=function(this)
    if this.p and this.ptimer==0 then
      this.px+=0.2
    end
    if this.px>this.x+4 then
      this.psprite=127
    end
    if this.px>this.x+7 then
      this.px=0
      this.p=false
      init_object(player,this.x+10,this.y)
      time_ticking=true
      lvl_ph=128
      poke(0x5f2c,0)
      ui_timer=5
    end
    if this.ptimer>0 then
      this.ptimer-=1
      this.zy-=0.5
      this.zc-=0.1
      if this.zy<this.y-16 then
        this.zy=this.y
        this.zc=7
      end
    end
  end,
  draw=function(this)
    spr(79,this.x+8,this.y,1,1,true)
    if this.p and this.ptimer==0 then
      spr(this.psprite,this.px+3,this.y)
    end
    spr(79,this.x,this.y)
    if this.ptimer>14 then
      ?"z",this.x+7,this.zy,this.zc
    end
  end
}

waterfall={
  init=function(this)
    this.t=0
    while (not this.is_solid(0,8) and this.y+this.hitbox.h<lvl_ph) this.hitbox.h+=8
    this.d=(this.spr==99 and 24 or 32)
    this.offscrn=this.y+this.hitbox.h>lvl_ph-6
  end,
  update=function(this)
    local hit=this.check(player,0,0)
    if (hit and frames%4==0) init_object(smoke,this.x+rnd(4)-2,hit.y-4)
    if (frames%4==0 and not this.offscrn) this.init_smoke(rnd(4)-2,this.hitbox.h-4)
  end,
  draw=function(this)
    this.t=(this.t+1)%8
    for i=0,this.hitbox.h/8-1 do
      sspr(this.d,56-this.t,8,this.t,this.x,this.y+8*i)
      sspr(this.d,48,8,8-this.t,this.x,this.y+8*i+this.t)
    end
  end
}

checkpt={
  init=function(this)
    this.hitbox,this.active=rectangle(-2,-2,12,12),false
  end,
  draw=function(this)
    this.spr=118+(frames/5)%3
    if this.check(player,0,0) and not this.active then
      spawn=vector(this.x,this.y)
      sfx(10)
    end
    if spawn.x==this.x and spawn.y==this.y then
      pal(11,3)
      this.active=true
    else
      this.active=false
      pal(11,7)
    end
    spr(this.spr,this.x,this.y)
    pal(11,11)
  end
}

taco={
  init=function(this)
    this.hitbox=rectangle(0,-3,16,19)
  end,
  draw=function(this)
    spr(68,this.x,this.y-3)
    spr(84,this.x,this.y+5,2,1)
    sspr(16,32,8,3,this.x,this.y+13)
    sspr(16,32,8,3,this.x+8,this.y+13,8,3,true)
    if this.check(player,0,0) then
      mset(87,9,70)
      clue=true
      local camx=round(cam_x)-64
      rectfill(4+camx,106,124+camx,122,0)
      rect(4+camx,106,124+camx,122,7)
      ?"this shrine is for taco, who",8+camx,108,7
      ?"is a huge inspiration to me.",8+camx,116,7      
    end
  end
}

jumpthrough={}

smol_grass={
  init=function(this)
    this.timer=0
    this.hitbox=rectangle(0,3,8,5)
  end,
  update=function(this)
    local hit=this.player_here()
    if hit and abs(hit.spd.x)>0 then
      this.timer=4
    end
    if this.timer>0 then
      this.spr=63
      this.timer-=1
    else
      this.spr=61
    end
  end
}

big_grass={
  init=function(this)
    this.timer=0
    this.hitbox=rectangle(0,3,8,5)
  end,
  update=function(this)
    local hit=this.player_here()
    if hit and abs(hit.spd.x)>0 then
      this.timer=4
    end
    if this.timer>0 then
      this.spr=95
      this.timer-=1
    else
      this.spr=73
    end
  end
}

florr={
  init=function(this)
    this.timer=0
    this.hitbox=rectangle(1,3,6,5)
  end,
  update=function(this)
    local hit=this.player_here()
    if hit and abs(hit.spd.x)>0 then
      this.timer=4
    end
    if this.timer>0 then
      this.spr=16
      this.timer-=1
    else
      this.spr=62
    end
  end
}

orb={
  update=function(this)
    local hit=this.player_here()
    if hit then
      sfx(51)
      sfx_timer=10
      freeze=10
      destroy_object(this)
      local val=lvl_id==4 and 1 or 2
      max_djump,hit.djump=val,val
      if val~=1 then
        spawn=vector(this.x,this.y+8)
      end
    end
  end,
  draw=function(this)
    if lvl_id!=4 then
      pal(14,11)
    end
    spr(102,this.x,this.y)
    pal(2,2)
    for i=0,0.875,0.125 do
      circfill(this.x+4+cos(frames/30+i)*8,this.y+4+sin(frames/30+i)*8,1,7)
    end
  end
}

blade_vert={
  init=function(this)
    this.y_=this.y
    this.hitbox=rectangle(1,1,6,6)
    while true do
      if not this.is_solid(0,-1) and this.y-1>0 then
        this.y-=1
      else
        break
      end
    end
    local fy=0
    while true do
      if not this.is_solid(0,fy) and this.y+fy<lvl_ph then
        fy+=1
      else
        this.mid=this.y+(fy/2)
        break
      end
    end
    this.y=this.y_
    this.timer=15
    this.up=this.is_solid(0,2)
  end,
  update=function(this)
    if this.timer>0 then
      this.timer-=1
    else
      if this.up then
        this.flip.y=false
        if this.y<this.mid+2 then
          if not this.is_solid(0,2) and this.y+2>0 then
            this.y-=2
          else
            this.up=false
            this.timer=15
          end
        else
          this.y-=2
        end
      else -- down
        this.flip.y=true
        if this.y>this.mid+2 then
          if not this.is_solid(0,-2) and this.y+4<lvl_ph then
            this.y+=2
          else
            this.up=true
            this.timer=15
          end
        else
          this.y+=2
        end
      end
    end
    local hit=this.player_here()
    if hit then
      kill_player()
    end
  end,
  draw=function(this)
    if this.y>this.mid-8 and this.y<this.mid then
      this.spr=42
    elseif this.y<this.mid+8 and this.y>this.mid+1 then
      this.spr=58
    else
      this.spr=57
    end
    draw_obj_sprite(this)
  end
}

blade_horiz={
init=function(this)
this.x_=this.x
this.hitbox=rectangle(1,1,6,6)
while true do
if not this.is_solid(-1,0) and this.x-1>0 then
this.x-=1
else
break
end
end
local fx=0
while true do
if not this.is_solid(fx+1,0) and this.x+fx<lvl_pw then
fx+=1
else
this.mid=this.x+(fx/2)
break
end
end
this.x,this.timer,this.left=this.x_,15,this.is_solid(3,0)
end,
update=function(this)
if this.timer>0 then
this.timer-=1
else
if this.left then
this.flip.x=true
if this.x<this.mid+2 then
if not this.is_solid(2,0) and this.x+2>0 then
this.x-=2
else
this.left,this.timer=false,15
end
else
this.x-=2
end
else
this.flip.x=false
if this.x>this.mid+2 then
if not this.is_solid(-2,0) and this.x+4<lvl_pw then
this.x+=2
else
this.left,this.timer=true,15
end
else
this.x+=2
end
end
end
local hit=this.player_here()
if hit then
kill_player()
end
end,
draw=function(this)
if this.x>this.mid-8 and this.x<this.mid then
this.spr=42
elseif this.x<this.mid+8 and this.x>this.mid-1 then
this.spr=58
else
this.spr=57
end
draw_obj_sprite(this)
end
}

biga={
update=function(this)
if this.player_here() then
local th=get_player()
th.spd.y,th.x,th.y=-5.5,92,78
end
end,
draw=function(this)
sspr(24,40,8,8,89,69,16,16,true)
sspr(16,32,8,3,88,85)
sspr(16,32,8,3,100,85,8,3,true)
sspr(20,32,4,3,96,85)
end
}

flag={
  init=function(this)
    this.score=0
    for _ in pairs(got_fruit) do
      this.score+=1
    end
    this.cloud={}
    for i=1,14 do
      add(this.cloud,vector((i-1)*14,i<3 and 10 or i==3 and 12 or i<6 and 11 or i==6 and 10 or i<9 and 9 or i<11 and 11 or 12))
    end
    this.inc=0.1
    this.rise=0
    this.hitbox=rectangle(-4,7,12,1)
    -- little clouds
    this.lclouds={}
    for i=1,3 do
      add(this.lclouds,{x=48,y=-78-rnd(20),spd=0.1})
    end
    this.applespr=26
  end,
  update=function(this)
  		local hit=this.player_here()
  		if not this.show and hit then
      sfx(55)
      sfx_timer,this.show,time_ticking,ascend=30,true,false,true
  		  pause_player=true
  		  hit.spd=vector(0,0)
  		  local fr
      for f in all(fruitrain) do
        if f.type==fruit then
          fr=f
          if fr and fr.golden then
            init_object(lifeup, fr.x, fr.y)
            del(fruitrain, fr)
            destroy_object(fr)
            sfx(13)
            this.score+=1
            this.applespr=8
          end
        end
      end
  		end
  		for i=1,3 do
      local lc=this.lclouds[i]
      lc.x+=lc.spd
  		  if lc.x>76 then
  		    lc.x,lc.y,lc.spd=48,-78-rnd(20),0.1+rnd()/2
  		  end
    end
  end,
  draw=function(this)
    draw_obj_sprite(this)
    sspr(18,38,6,2,this.x-14,this.y+6)
    sspr(18,38,6,2,this.x-8,this.y+6,6,2,true)
    rectfill(0,-192,128,30,5)
    for i=1,14 do
      c=this.cloud[i]
      c.x+=1
      if c.x>138 then
        c.x=-10
      end
      circfill(c.x,30,c.y,5)
    end
    if this.show then
      if cam_y>-64 then
        this.rise+=this.inc
        cam_y-=this.rise
      end
      draw_time(42,-68)
      spr(this.applespr,51,-61)
      ?"x"..this.score.."/7",60,-59,7
      ?"deaths:"..deaths,48,-52,7
      spr(23,52,-100,2,1)
      spr(23,68,-100,1,1,true)
      spr(45,52,-92,3,1)
      spr(28,52,-84)
      spr(100,60,-84)
      spr(87,68,-84)
      for i=1,3 do
        local lc=this.lclouds[i]
        sspr(114,36,4,2,lc.x,lc.y)
      end
    end
  end
}

flag2={
  init=function(this)
    this.x+=5
    this.score=0
    for _ in pairs(got_fruit) do
      this.score+=1
    end
    this.applespr=26
  end,
  update=function(this)
    if not this.show and this.player_here() then
      sfx(55)
      sfx_timer,this.show,time_ticking=30,true,false
      local fr
      for f in all(fruitrain) do
        if f.type==fruit then
          fr=f
        end
      end

      if fr and fr.golden then
        init_object(lifeup, fr.x, fr.y)
        del(fruitrain, fr)
        destroy_object(fr)
        sfx(13)
        this.score+=1
        this.applespr=8
      end
    end
  end,
  draw=function(this)
    spr(118+frames/5%3,this.x,this.y)
    if this.show then
      rectfill(56,6,120,36,0)
      rect(56,6,120,36,7)
      spr(this.applespr,76,9)
      ?"x"..this.score..(lvl_id==18 and "/2" or "/7"),85,12,7
      draw_time(66,19)
      ?"deaths:"..deaths,73,28,7
    end
  end
}

psfx=function(num)
  if sfx_timer<=0 then
   sfx(num)
  end
end

tiles={
  [1]=player_spawn,
  [8]=fruit,
  [13]=jumpthrough,
  [14]=jumpthrough,
  [15]=jumpthrough,
  [19]=jump_gem,
  [65]=side_plat,
  [18]=spring,
  [20]=chest,
  [22]=balloon,
  [26]=fruit,
  [40]=smol_spring,
  [57]=blade_horiz,
  [58]=blade_vert,
  [61]=smol_grass,
  [62]=florr,
  [66]=biga,
  [83]=adelie,
  [68]=taco,
  [73]=big_grass,
  [79]=tent,
  [99]=waterfall,
  [102]=orb,
  [114]=flag,
  [118]=flag2,
  [119]=checkpt
}

-- [object functions]

function init_object(type,x,y,tile)
  if type.if_not_fruit and got_fruit[lvl_id] then
    return
  end

  local obj={
    type=type,
    collideable=true,
    solids=false,
    spr=tile,
    flip=vector(false,false),
    x=x,
    y=y,
    hitbox=rectangle(0,0,8,8),
    spd=vector(0,0),
    rem=vector(0,0),
  }

  function obj.is_solid(ox,oy)
    return (oy>0 and not obj.check(jumpthrough,ox,0) and obj.check(jumpthrough,ox,oy)) or
           (oy>0 and not obj.check(side_plat,ox,0) and obj.check(side_plat,ox,oy)) or
           obj.is_flag(ox,oy,0)
  end

  function obj.is_flag(ox,oy,flag)
    return tile_flag_at(obj.x+obj.hitbox.x+ox,obj.y+obj.hitbox.y+oy,obj.hitbox.w,obj.hitbox.h,flag)
  end

  function obj.check(type,ox,oy)
    for other in all(objects) do
      if other and other.type==type and other~=obj and other.collideable and
        other.x+other.hitbox.x+other.hitbox.w>obj.x+obj.hitbox.x+ox and
        other.y+other.hitbox.y+other.hitbox.h>obj.y+obj.hitbox.y+oy and
        other.x+other.hitbox.x<obj.x+obj.hitbox.x+obj.hitbox.w+ox and
        other.y+other.hitbox.y<obj.y+obj.hitbox.y+obj.hitbox.h+oy then
        return other
      end
    end
  end

  function obj.player_here()
    return obj.check(player,0,0)
  end

  function obj.move(ox,oy,start)
    for axis in all({"x","y"}) do
      obj.rem[axis]+=axis=="x" and ox or oy
      local amt=flr(obj.rem[axis]+0.5)
      obj.rem[axis]-=amt
      if obj.solids then
        local step=sign(amt)
        local d=axis=="x" and step or 0
        for i=start,abs(amt) do
          if not obj.is_solid(d,step-d) then
            obj[axis]+=step
          else
            obj.spd[axis],obj.rem[axis]=0,0
            break
          end
        end
      else
        obj[axis]+=amt
      end
    end
  end

  function obj.init_smoke(ox,oy)
    init_object(smoke,obj.x+(ox or 0),obj.y+(oy or 0),29)
  end

  add(objects,obj)

  if obj.type.init then
    obj.type.init(obj)
  end

  return obj
end

function destroy_object(obj)
  del(objects,obj)
end

function kill_player()
  local obj=get_player()
  if obj then
    sfx_timer=12
    sfx(0)
    deaths+=1
    destroy_object(obj)
    dead_particles={}
    for dir=0,0.875,0.125 do
      add(dead_particles,{
        x=obj.x+4,
        y=obj.y+4,
        t=2,
        dx=sin(dir)*3,
        dy=cos(dir)*3
      })
    end
    for f in all(fruitrain) do
      if f.golden then
        full_restart=true
      end
      del(fruitrain,f)
    end
    delay_restart=15
    if lvl_id==3 then
      mset(79,9,97)
      mset(79,10,113)
      lvl_pw=256
    end
  end
end

-- [room functions]

function next_level()
  local next_lvl=lvl_id+1
  load_level(next_lvl)
end

function load_level(lvl)
  local diff_room=lvl_id~=lvl
  if diff_room then
    spawn=vector(-1,-1)
    if lvl==4 or lvl==8 or lvl==13 or lvl==23 then --wind music
      music(30,500,7)
    elseif lvl==5 or lvl==21 then
      music(0,0,7)
      new_bg=true
    elseif lvl==9 then
      music(8,0,7)
      newer_bg=true
    end
    if lvl==21 then
      newest_bg=true
    end
    if lvl~=13 and lvl~=18 and lvl~=23 then
      menuitem(2,"retry",kill_player)
      menuitem(3,"reset cart data",function()
        for i=0,63 do
          dset(i,0)
        end
      end)
    else
      menuitem(2)
      menuitem(3)
    end
  end
  has_dashed=false

  --remove existing objects
  foreach(objects,destroy_object)

  --reset camera speed
  cam_spdx,cam_spdy=0,0

		--set level index
  lvl_id=lvl

  --set level globals
  local tbl=get_lvl()
  lvl_x,lvl_y,lvl_w,lvl_h,lvl_title=tbl[1],tbl[2],tbl[3]*16,tbl[4]*16,tbl[5]
  lvl_pw=(lvl_w*8)-((lvl_id==3 and not got_fruit[lvl_id]) and 128 or 0)
  lvl_ph=lvl_h*8


  --reload map
  --level title setup
  if not is_title() then
   if diff_room then reload() end
  	if lvl_id~=1 then
  	  ui_timer=5
  	end
  end

  --chcek for hex mapdata
  if diff_room and get_data() then
  	 for i=0,get_lvl()[3]-1 do
      for j=0,get_lvl()[4]-1 do
        replace_room(lvl_x+i,lvl_y+j,get_data()[i*get_lvl()[4]+j+1])
      end
  	 end
  end

  -- entities
  for tx=0,lvl_w-1 do
    for ty=0,lvl_h-1 do
      local tile=mget(lvl_x*16+tx,lvl_y*16+ty)
      if tiles[tile] then
        if tiles[tile]==orb then
          if not (lvl_id==4 and max_djump==1) and not (lvl_id==8 and max_djump==2) then
            init_object(tiles[tile],tx*8,ty*8,tile)
          end
        else
          init_object(tiles[tile],tx*8,ty*8,tile)
        end
      end
    end
  end
  if lvl_id==13 then
  		dset(0,1)
  		if clue then
      mset(1,43,70)
    end
  end
end

-- [main update loop]

function _update()
  frames=(frames+1)%30
  if time_ticking then
    seconds_f+=1
    minutes+=seconds_f\1800
    seconds_f%=1800
  end

  if sfx_timer>0 then
    sfx_timer-=1
  end

  -- cancel if freeze
  if freeze>0 then
    freeze-=1
    return
  end

  if lvl_delay>0 then
    lvl_delay-=1
  elseif lvl_delay==0 then
    if lvl_id==4 or lvl_id==8 or lvl_id==20 then
      create_particles()
    end
    load_level(ld)
    lvl_delay=-1
  end

  -- restart (soon)
  if delay_restart>0 then
  		cam_spdx,cam_spdy=0,0
    delay_restart-=1
    if delay_restart==0 then
      load_level(lvl_id)
      if full_restart then
        full_restart=false
        begin_game()
      end
    end
  end

  -- update each object
  foreach(objects,function(obj)
    obj.move(obj.spd.x,obj.spd.y,0)
    if obj.type.update then
      obj.type.update(obj)
    end
  end)

  -- start game
  if is_title() then
    if start_game then
      start_game_delay-=1
      title_fall=mid(title_fall-0.3,-6,6)
      if start_game_delay<=-280 or start_game_delay<=-50 and btn(❎) and btn(⬆️) then
        if btn(❎) and btn(⬆️) then
          skip=true
        end
        title_offset=0
        title_fall=0
        begin_game()
      end
    elseif btn(🅾️) or btn(❎) then
      music(-1)
      start_game_delay=0
      start_game=true
      sfx(38)
    end
  end
  if atrans.y>-200 then
    atrans.y-=atrans.spd
  end
end

function _draw()
  if freeze>0 then
    return
  end
  pal()
  if is_title() and start_game then
    local c=start_game_delay>-40 and (frames%10<5 and 7 or 10) or (start_game_delay>-45 and 2 or start_game_delay>-40 and 1 or 0)
    if c<10 and start_game_delay>-40 then
      for i=1,15 do
        pal(i,c)
      end
    end
  end
  local camx=is_title() and 0 or round(cam_x)-64
  local camy=is_title() and 0 or round(cam_y)-64
  camera(camx,camy)

  local xtiles=lvl_x*16
  local ytiles=lvl_y*16

  cls(flash_bg and frames/5 or newest_bg and 2 or newer_bg and 6 or new_bg and 13 or 1)

  if not is_title() then
    foreach(clouds, function(c)
      c.x+=c.spd-cam_spdx
      ovalfill(c.x+camx,c.y+camy,c.x+c.w+camx,c.y+16-c.w*0.18+camy,newest_bg and 6 or newer_bg and 7 or new_bg and 6 or 13)
      if c.x>128 then
        c.x=-c.w
        c.y=rnd(120)
      end
    end)
  end

  map(xtiles,ytiles,0,0,lvl_w,lvl_h,4)

  foreach(objects, function(o)
    if o.type==blade_vert or o.type==blade_horiz then
      draw_object(o)
    end
  end)

  map(xtiles,ytiles,0,0,lvl_w,lvl_h,2)

  foreach(objects, function(o)
    if o.type~=blade_vert and o.type~=blade_horiz and o.type~=fruit then
      draw_object(o)
    end
  end)

  foreach(objects, function(o)
    if o.type==fruit then
      draw_object(o)
    end
  end)

  foreach(particles, function(p)
    p.x+=p.spd-cam_spdx
    p.y+=sin(p.off)-cam_spdy
    p.off+=min(0.05,p.spd/32)
    rectfill(p.x+camx,p.y%128+camy,p.x+p.s+camx,p.y%128+p.s+camy,p.c)
    if p.x>132 then
      p.x,p.y=-4,rnd(128)
   	elseif p.x<-4 then
     	p.x,py=128,rnd(128)
    end
  end)

  foreach(dead_particles, function(p)
    p.x+=p.dx
    p.y+=p.dy
    p.t-=0.2
    if p.t<=0 then
      del(dead_particles,p)
    end
    rectfill(p.x-p.t,p.y-p.t,p.x+p.t,p.y+p.t,14+5*p.t%2)
  end)

  if ui_timer>=-30 then
  	if ui_timer<0 then
  		draw_ui(camx,camy)
  	end
  	ui_timer-=1
  end

  if is_title() then
				title_offset-=title_fall
				spr(74,49,24-title_offset,4,1)
    spr(91,57,32-title_offset,2,1)
    spr(106,49,40-title_offset,4,1)
    spr(121,41,48-title_offset,6,1)
    pset(47,31-title_offset,9)
    pset(48,30-title_offset,9)
    pset(48,29-title_offset,9)
    ?"🅾️+❎",54,58-title_offset,6
    ?"original game by",34,68-title_offset,13
    ?"maddy thorson",40,76-title_offset,12
    ?"noel berry",46,84-title_offset,12
    ?"mod by",52,96-title_offset,13
    ?"sparky9d",48,104-title_offset,12
  end
  if is_title() and start_game_delay and start_game_delay<=-40 then
    local c=1
    if start_game_delay>-230 and start_game_delay<-80 then
      c=7
    elseif start_game_delay>-240 and start_game_delay<-70 then
      c=6
    elseif start_game_delay>-250 and start_game_delay<-60 then
      c=5
    elseif start_game_delay>-260 and start_game_delay<-50 then
      c=0
    end
    ?'"long ago, penguins roamed this',2,56,c
    ?'land. now, only their ruins',10,64,c
    ?'remain."',48,72,c
    ?"- (1), penguin's elegy by elfia",3,80,c
    ?'❎ + ⬆️ - skip',4,118,c
  end
  local ty=atrans.y
  if ty>-200 then
    local camx=round(cam_x)-64
    fillp(0b0111110101111101.1)
    rectfill(camx,ty+cam_y,camx+128,ty+164+cam_y,7)
    fillp(0b0101101001011010.1)
    rectfill(camx,ty+12+cam_y,camx+128,ty+152+cam_y,7)
    fillp()
    rectfill(camx,ty+24+cam_y,camx+128,ty+140+cam_y,7)
  end
  pal(4,132,1)
  pal(9,137,1)
  pal(10,9,1)
  pal(11,139,1)
  pal(12,140,1)
  pal(1,129,1)
  if (lvl_id>8 and lvl_id<14) or lvl_id==19 or lvl_id==20 then
    pal(9,6,1)
    pal(10,7,1)
  elseif (lvl_id>0 and lvl_id<5) or (lvl_id>13 and lvl_id<19) then
    pal(9,3,1)
    pal(10,139,1)
  end
end
function draw_object(obj)
(obj.type.draw or draw_obj_sprite)(obj)
end
function draw_obj_sprite(obj)
spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
end
function draw_time(x,y)
rectfill(x,y,x+44,y+6,0)
?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30).."."..two_digit_str(flr(100*(seconds_f%30)\30)),x+1,y+1,7
end
function draw_ui(camx,camy)
rectfill(24+camx,54+camy,104+camx,76+camy,0)
rect(24+camx,54+camy,104+camx,76+camy,7)
local area=(lvl_id<5 and "foggy foothills" or lvl_id<9 and "mountain paths" or lvl_id<14 and "misty peaks" or lvl_id<19 and "mountain trials" or lvl_id<21 and "???" or "golden spire")
pal(11,11)
local area_c=(lvl_id<9 and 10 or lvl_id<14 and 6 or lvl_id<19 and 13 or 10)
?area,64-#area*2+camx,58+camy,area_c
if lvl_title then
?lvl_title,64-#lvl_title*2+camx,68+camy,7
else
local level=(lvl_id)*100
?level.." m",52+(level<1000 and 2 or 0)+camx,68+camy,7
end
draw_time(4+camx,4+camy)
draw_time(4+camx,4+camy)
end
function two_digit_str(x)
return x<10 and "0"..flr(x) or flr(x)
end
function round(x)
return flr(x+0.5)
end
function appr(val,target,amount)
return val>target and max(val-amount,target) or min(val+amount,target)
end
function sign(v)
return v~=0 and sgn(v) or 0
end
function maybe()
return rnd()<0.5
end
function tile_flag_at(x,y,w,h,flag)
for i=max(0,x\8),min(lvl_w-1,(x+w-1)/8) do
for j=max(0,y\8),min(lvl_h-1,(y+h-1)/8) do
if fget(tile_at(i,j),flag) then
return true
end
end
end
end
function tile_at(x,y)
return mget(lvl_x*16+x,lvl_y*16+y)
end
function spikes_at(x,y,w,h,xspd,yspd)
for i=max(0,x\8),min(lvl_w-1,(x+w-1)/8) do
for j=max(0,y\8),min(lvl_h-1,(y+h-1)/8) do
local tile=tile_at(i,j)
if (tile==17 and ((y+h-1)%8>=6 or y+h==j*8+8) and yspd>=0) or
(tile==27 and y%8<=2 and yspd<=0) or
(tile==43 and x%8<=2 and xspd<=0) or
(tile==59 and ((x+w-1)%8>=6 or x+w==i*8+8) and xspd>=0) then
return true
end
end
end
end
-->8
levels={
[0]="0,-1,1,1",
"0,0,2,1,base camp",
"2,0,1,1",
"3,0,3,1",
"0,1,1,1",
"6,0,2,1",
"4,1,1,2",
"1,1,2,2",
"3,1,1,3,crumbling cliff",
"0,3,3,1",
"5,1,3,1",
"0,0,1,4",
"1,1,2,3",
"0,2,1,1,cloudy summit",
"5,2,1,2,first trial",
"6,2,1,2,second trial",
"7,2,1,2,third trial",
"0,0,1,2,final trial",
"4,3,1,1,trials' summit",
"0,0,2,1,hidden overhang",
"0,0,1,1,adelie's memorial",
"0,0,3,3,spire's base",
"0,0,1,4,ghostly cliff",
"0,0,1,2,spire tip",
}
mapdata={
[11]="252525262b003b312525253232252525322525262b0000682432336958312525233132262b16000030685e5d69682425252223372b00004e30492c00003e31322525262b004e006824233c3d492122223225332b5d690011313321222225252523375a5958593b21222225252525252526696e6875693b31323232323225252526115d596e58595867594e003b2425252523586958696865696869003b24252532336e006e114e6e001100003b24252522230000002769005d272b003b242525252611111130111111372b163b242525252522222337212222232b003b242525323232252522252532332b003b31322522222324253232336900000000000031,25252631336900005d5e0000000000002525336900005d595859000000004e11253369000000586968755911005d6538261b000000006e005d656738005d6738261100585e0000005d6968380000683825235869000000001111113811111138252669005d59111138383838383838382526770000683435222222233435353548260d0e4e5859583132252522222222252600006869685a5900312525252525252611115d595d67690000242532252525252223116e58655e0000242620242525254826272b6869000000312522252525253233302b00000000003b2425482532332122331111110000003b3132322522222526383838382b16003b21222324,25254825231b1b1b0000003b2425263125252525262b0000000000112425252248252532332b0000111111342525252532323321232b163b383838382425252522222225262b00001b1b1b212532323225252525262b4e0000003b313321222232252548265e68594e003921222525326831322526395d67755958242532336958676531262b5865696869243365690068756968372b6e6859003b3769685958006859001b0000586900001b005875690058690000000068590000005d676759006e5d5e000000006e000000585a6968594e00000000001212620000686759006865590000583838383859585e68655958696859582123383821236559586968,67593b21222526212225252222232b0075693b31252533242525482525332b00675e58593133214825252532336900006900686767382425253233691b00000000005d6569382432331b1b0000000000111111685938375869000000000000002222232b6e276569000000000000004e2548262b0037690000000000000058652525332b001b0000004e00000058696848262b0000000000586900000068595825332b00005859016859585e00586569262b0000006821232123690058756759332b004e001124262426110068696869690058693b2125263125231100005859005d65593b2425252324482359006865595867693b2448252624252668595869",
[12]="252526242548252525262b003b242525252526242532323232332b003b24252525252631331b1b1b1b1b00003b31252525252523690000000000001600002425254825265e00001111110000000024253232323359003b2122235900000024482222232b68593b24482668594e0024252548262b006e3b2425265d67655931332525262b00163b2425261168676921232525262b00003b2425252358675e24262532331100003b242548267569112426263838382b003b312525266859212526263838382b004e68313233116831322525365a690000685921222223112123312667690000005869242525252225252326690000115869582425322525253233,2600003b2769006824262024253369003300003b3011111124252225336900005859003b2422222225252526585e00117569163b242548323232322669003b27675e003b243233690000683700003b246900003b376900000000002900003b31585900001b000000000000000000003b69685900000000000000000000004e3b005869003a004e00000000000000685958675e00115865590000000000005d7567690011276968690000000000000068655e00212611585e000077005300003b69001124482369005d383838385e003b000021252526110000212222232b0000111124252525231111242525262b001622222525252525223624252526111111,254832323225253321252525482222223233676767313321254825252532323368676769686958312525323233690068006e68595859686724331b1b1b0000000000586767695869371b00000000000000006867695865591b0000110000000000005d75596e6869000011275e000000000000686900000000112126110000003d002c000000000058212525235e000022233c01493e000068242548261100002525222222365e0011312525252300002548252533690000212324252533590032323233690000582426313233276859222223690000006e24252321222611682525330000000000242526242525231125266900000000002425262425482621,25266759682425262425252525332425252669685924252631252548262125252533005d752425252324252533242525266859586924252526313233212525252658696e11242525252321222525322526655e582125252525262425252620243369006e2448252532333125252522252b0000113132323369686731322525252b003b3838386569000068593b2425252b00001b1b1b6e0000115d693b2448252b00160000000058592700003b3132321111111111115869683011004e68592122222222222369005d2423586900682425252525323311111124265a5e0e0f242448253321222222222526695d59582431252621253225252548261100687524,6831332426202425252525232b5867240068592425222532323232332b686731000068312525337569001b1b0000685a11000068242658690000000000005d67230000002426675e160011114e1a006833110000313369000000383869000011212359001b1b000000113838111111212426675e0000004e582738382122222524266900111158656924222225252525242611112123696e00242525482525322425222225261111112425252525332124482532323321222225252525262125313233676968313232252525323324251b1b1b6e00000068753132332122252500000000000000006e682122252525251111114e000011000000242532323225,36212369005d3800000024263838382421252611111138110000312522222225313225222223382700003b2425252548686731252525222600003b31322532325d655924323232330000000000372122006867372122232b0058595859212525005867752425262b0068656968312525006e68692448262b00586759003b242500000000312526115d676769003b2425000000006824252358696e28003b2448000000000031323369003b381111242500110000001b1b1b00003b3838383132112700000000000016003b3821222222212600004e1111111111113824252525242659586921222223212222252525252526685a592425252624252525254825",
[17]="3226690031252525323369683125252560370000682425266900000068242548006e0000002425263d00002c00242525110000587324252523493e3c3d24252523000070672448252523212223313232330058606531323225262448252222221b006e0068740068312624252525252500001300006e000068373125252525250000001100000000006e3b312525252511111127000000000000003b312525482222222600000058591100003b313232252548264e125869682711000000706032323233602069111124231100166e00222222231111113422254823735e00002525253321222223313232336900000025482621483232336900000000000000,2525263133690000000000000000130032323369000000000000001100000000690000000000000011000027735e00001100004e4e58595d275900376911111123590068343669003069112711212222336059001127111130112125233132321b0068732125222225233132336968591100586031323232322523690000006823736900000000006824330000000100336900585e3a5d5900306900005821221b005d74001100687330000000212525000058740027000068370000002425480058696859300000006e000011242525736912006830000011000000273125256921222300300000270000002423313258242526733059583059005824252222",
[19]="25322658696824252525252526242525261b376900002425252525252624253233001b000000312525482525262426201b00000000006831322525253324252259000000000000006831252621252525655900000000000000682426242525336769000000000000000031332425266974000000000000000000682125253300705e00005d3436594e0058244826690069000000006860676573672425330000000000000000006860696e312669000000000000000000000000006830000000000000000000000000000000370000000000000000000000000000006e0000000000000000000000000000000000000000000000000000000000000000000000,2525253324252525252525262425252525252621252525482525253324252525242526242525252525252621252525252532333132322525252533242525252533696859006831323233212525254825690000705e000000006831322525252500005d6759000000004e70603125252500005865740000000070690068313225005d3435365e000058675e000000683100000000000000006869000000000068000000000000000000000000000001580000000000000000000000000000212200000000000000000000000000112425000000000000000000000000002125250000000000000000000000000024252500000000000000000000000058242525",
[20]="0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004e000000000000000000000000000000685900000000000000000000000000000070590000000000000000000000000000687400000000000000000000004e42005869000000000000000000005821222223590059000000000000005867242525252359222300000000015821222525252525222526590000002122252525252525252525252300587324252525252525252525",
[21]="25252525262425254825252525254826252525252624252525253232323225262525252526242532323369000068312625482525263133690000004e0000683725252525336900000000007059000068252525262b0000000000006869000000252525262b000000000011585e0000003232323311000000110027690000000022222222232b003b271130110000110025252525262b003b242225231111272b25482525262b003b242525252222262b25252525262b163b244825252525262b25252548262b003b242525252525261125252525332b003b31322525482525233225252669000000006831252525253360313226000000000000682425252621,000068370000000000000031323233240000006e0000000000000000006834320000000000000000000000000000687500000000000000000000000011005d6700000000000000000000005d272b0068000000000000000000004e77301100000000000000000000005d212248232b0000000000000000000058243232262b0000000000000000005867371b1b372b00000000000000005d67691b00000000000000000000000058740000000000001600000000000000706900000000000000000000000000006859000000000000580000000000000000707359000000586700000000000000006869687359586769000000000000000000005d6567606900,000000000000000000000068690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b0000000000000000000000000000003b0000000000000000000000000000003b000000000000000000000000000000000000000000004e000000000000000000000000004e5867735900000000000000000000586765676767735901000000000000006867676968607521222311004e0000000070675e0000682425252358690000005867690000001124252526740000005d67690000000021252525336900000058675900000000242525261b0000,242548252525252525252631323232322425252525252525252533690000000024252525252525482533690000001100242525252525252526690000001127112425252525252532330000003b2148233125252525252621231100003b31322668312548252533242523110000001b37006824252526212548252311001600680000313232333132322525231100000000001b1b1b1b1b1b1b313225231100001600003a000000000000683148232b0000001111111111000000006831262b00111121222222232b0000000068302b00212225252525262b0000000000372b00242525252525261100585900001b000025252525482525237360690000000016,252525252525252669000011585e0000252525252525253311111127690000002425252525252621222222261111111124252525252533242525252522222222312525252526212525482525253232323b2425482526242525323232336900003b2425252526313233690000000000003b2425253232366900000000000000003b313233690000000000004e0011004e001b1b1b00000000004e58677327736000000000000000115865676968376900001111110058732767696e00586900007321222373696837690000007059000060312526690000000000000068755e000068242600001111111111115869000000112426111121232122222374000000,3b2125252222252624252526690000003b2425252525252631252526110000003b242525254825252324252523115873113132252525252526242525252365602122233132252525332425252526740024252522232425263432252525336900312525252631323367652448266900003b2448252536676767672425330000003b312525266775676067312669000000003b31323360696e006867300000001100001b1b1b0000000000683700003b2100000000000000000000006e00003b2400001111110000000000000000003b24000021222300000000110000000011240011242526590000112759000058212500212525266859582126685958692425,32322525252525262b003b242525252500683125254825262b003b312548252500006831252525262b000068242525250000006824252526110000002425252500000000312525252311000031252532000000006824252525232b003b243360597700000024252525262b003b376900212236000024254825262b00001b001124262b0058313232322611000000002131262b58741b1b1b1b312300000000243b302b68605e0000003b3000000000313b30111111111100003b3000000000683b2422353535362b003b3059000000003b31261b1b1b1b00003b3060590000000068302b00000000003b3000705912580000372b000011111111307369683422,0011272b003b212222223369000068311121262b003b3132323369000000006821482659000000007069000000000000252526685900005874000000000000003232333422222222222300000000000000000068313232324826000000000000000000000000685924261111111111110000000000000068312522232122222200111100000000003b2425332425252573212311000016003b24262125252525683125232b0000003b31332425254825006831262b0039003b21222525252525000068372b0000003b313225252525250000006e000000000000683132252525000000000000000000000068592432320000004e587359000016000068372122,004e5867756767590000000000212548586767696e686767590000000024252567696e0000006e68675e000000313225690000004e00005d5a59000000686724000000586900005867605900000068240000007059587367695d675e000000240000006860676069000068590000002400000000006e000000005d6759000024110000000000000000000068675e0024272b0000000000000000000068591131262b0000000000000000000000682122261100000000000000000000000024254823590000000000000000000058242525336873594e00000000007758212525262b5867696859000058212222254825262b7069005821222222252525252525",
[22]="2525252525254825266900682448252548252525252525252600000024252525252525252525252526000000312525252525323232252525331100003b242525323369006831323321232b003b2425256900004e5869006831262b003b242548000058677400000068372b003b242525005d656069000000000000003b243232005867590000000000000000113721220070676900000000005859002122252573677400000000000068657324254825747067590000000000006e68312525256867676900000000000000006824252558696e00000000001200000000242525675e000011111121222311000031252569001111212222252525232b003b2448,11112122252525252525262b003b242522222525253225254825262b003b313225254825262024252525332b003b2122252525252522252525331b00163b24253232322525252525331b00000011242522222331323232331b00000011212525252525222222231b0000001121252525252548252525265900003b2125252525252525252532336759003b2425254825252525253369686574003b31322525252525252669005d67690000006831252532323233110000685e000000006831322222222223000000000000000000212225252525335900000000001111112425252525262b6859000000112122224825252525262b5874000000212525252525,252548252222360000002425252532322525252525331b00000024252533212225252525262b0000001124252621254832323225262b0000112125252631322522222331332b003b343232323369683125252522232b00001b1b1b1b1b00006825482525262b16003a00000016000011252525252611111111111111000000212532322526212222222222230000002433696831333125252525482600000031690000000068313232323226000000681100000000001b1b1b1b1b37590000002311000000000000000000687400000025230000000011111100005d6759000025260000004e212223004e5865675e0032330000006831252673606767690000,2369000000001b312669006867590000261100000000001b371111117069000025230000001100001b342236690000004826591258271100001b376900000000252621222225230000001b00000000002533242525482659000000000000000026212525323226675e00000000000000332425336968376759000000000000002225266900006e68605e0000000000002532330000000000000000000000000033690000000000000000000000000000690000000000000000000000000000000000004e000000000001000000000000000058605e0000583422235900000000005d740000000021232426685900000000586059000058242624260068590058",
[23]="000000000000000000000000000000000000000000760000000000000000000000000000002700000000000000000000000000000c300000000000000000000000000000212659000000000000000000000000002425230000000000000000000000000024252619000000000000000000000000313225230000000000000000000000006e6831335900000000000000000000000000686774000000000000000000004e19005865690000000000000000000021230b7074000000000000000000000024323535360b00000000000000000058372122222223000058590000140000212225252525260000212300002100002425254825252600002426000024,0058242525252525330b0c242600002458212525252525332122222526000031222525252525262125252525260000682525252525252624254825323300000025482525323233242525265869000000323232336900683132252669000000006900000000000000683126000000000000000000000000000068370000000000000000000000000000006e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001400000000000000010000000000002122235900001958212359000000000c24252522222222232448235900145821252548252525252624252621222222252525252525"
}
function get_lvl()
return split(levels[lvl_id])
end
function get_data()
printh("splitting getdata")
printh(tostring(lvl_id))
printh(tostring(mapdata[lvl_id]))
if(mapdata[lvl_id]==nil) return nil
return split(mapdata[lvl_id],",",false)
end
cam_x=0
cam_y=0
cam_spdx=0
cam_spdy=0
cam_gain=0.25
function move_camera(obj)
cam_spdx=cam_gain*(4+obj.x+0*obj.spd.x-cam_x)
cam_spdy=cam_gain*(4+obj.y+0*obj.spd.y-cam_y)
cam_x+=cam_spdx
cam_y+=cam_spdy
if cam_x<64 or cam_x>lvl_pw-64 then
cam_spdx,cam_x=0,mid(cam_x,64,lvl_pw-64)
end
if cam_y<64 or cam_y>lvl_ph-64 then
cam_spdy=0
cam_y=mid(cam_y,64,lvl_ph-64)
end
end
function replace_room(x,y,room)
for y_=1,32,2 do
for x_=1,32,2 do
local offset=4096+(y<2 and 4096 or -4096)
local hex=sub(room,x_+(y_-1)*16,x_+(y_-1)*16+1)
poke(offset+x*16+y*2048+(y_-1)*64+x_/2, "0x"..hex)
end
end
end
__gfx__
00000000000000000000000008888880000000000000000000000000000000000700007000700700000770000000000000000000aaaaaaaaaaaaaaaaaaaaaaaa
0000000008888880088888808838888808888880088888000000000008388880760770670767767000766700000000000000000099a99949949994a99499a499
000000008838888888388888838ffff888388888888883800888888083f1ff186676676606666660006666000011110000111100449444944944494449444944
00000000838ffff8838ffff888f1ff18838ffff88ffff8308838888888fffff80066660000666600000660000117171001717110094000000000000000000490
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80838ffff888fffff80777776007777760077777600111991001991110940000000000000000000049
0000000008fffff008fffff000cccc0008fffff00fffff8088fffff808cccc800777776007777760077777601117771111777111400000000000000000000004
0000000000cccc0000cccc000600006006cccc0000cccc6008f1ff1000cccc000077760000777600007776001119779119779111000000000000000000000000
000000000060060000600060000000000000060000006000066ccc60006006000007600000076000000760000119669009669110000000000000000000000000
000000000000000000000000000660000000000000066000000660005555555555555555000000000000000066656665555cccc6000000000000000070000000
00cc0cc000000000000000000067e6000011110000600600006ee60055555555c5cccc5c001111000000b0006765676555c5cc66007700000770070007000007
00ccccc00000000000000000067e7e60017171100600006006e88e605555c5c55cccccc501171710000b300067706770555ccc66007770700777000000000000
000c1c000070007006aaaa6067e7e2e6019911106000000668888886555c5c5ccccccccc01119910008388000700070055c5c566077777700770000000000000
00ccccc000700070005005006e7e2e261177711160000006628888265555cccccccccccc111777110888882007000700555c5656077777700000700000000000
00cc9cc0067706770005500006e2e260117771110600006006222260555c5ccccccccccc11177711088888200000000055555565077777700000077000000000
000a00005676567600500500006e260001777110006006000062260055c5cccccccccccc01177710008882000000000055555555070777000007077007000070
000a0000566656660005500000066000099699110006600000066000555ccccccccccccc11996990000820000000000055555555000000007000000000000000
5aaaaaa55aaaaaaaaaaaaaaaaaaaaaa5a9444444444444444444449a5aaaaaa500000000005005007000700755000000077777705c5ccccccccc7cccccccc5c5
aa9999aaaa99999999999999999999aaa9944444444444444444499aaa9999aa000000000555555007076070667000007777777755ccccccccc77ccccccccc55
a994499aa9994444499999944444999aa9944444444444444444499aa999999a000000005666b6650056550067777000777777775ccccccccc677cccccccccc5
a944449aa9944444444994444444499aa9994444444444444444999aa994499a00000000566b36657658867066600000777799775ccccccccc7677ccccccccc5
a944449aa9444444444444444444449aa9994444444444444444999aa944449a006aa600568382650768856755000000777799775cccccccc66777ccccccccc5
a994499aa9444444444444444444449aa9944444444444444444499aa944449a00055000568882650055650066700000797799975ccccccc667677ccccccccc5
aa9999aaa9444444444444444444449aa9944444444444444444499aa944449a005005005668266507067070677770007999aa9755cccccc6667677ccccccc55
5aaaaaa5a9444444444444444444449aa9444444444444444444449aa944449a000550000555555070070007666000000999aa905c5cccc66666767cccccc5c5
a994499aa9444444444444444444449a5aaaaaaaaaaaaaaaaaaaaaa5a944449a5555555500700700000700700000066609999990000000000000000000000000
a994499aa9444444444444444444449aaa99999999999999999999aaa944449a7777757700706700707067000007777609a99990000000000cc0cc0000000000
a944449aa9444444444444444444449aa9994444994444994444999aa944449a666665767756557707565570000007660999999000000a000ccccc000000000a
a944449aa9444444444444444444449aa9944444444444444444499aa944449a666665760658860006588607000000550999a99000009a0000c1c000000000a0
a944449aa9944444444994444444499aa9944444444444444444499aa994499a55555555006885607068856000000666009999000000a0000ccccc00000009a0
a944449aa9994444499999944444999aa9994444994444994444999aa999999a77757777775565770755657000077776000440000000a0000cc9cc0000000a00
a994499aaa99999999999999999999aaaa99999999999999999999aaaa9999aa6665766600760700007607070000076600044000a00a90a0000a000000a0a90a
a994499a5aaaaaaaaaaaaaaaaaaaaaa55aaaaaaaaaaaaaaaaaaaaaa55aaaaaa5666576660070070007007000000000550099990009099a90000a000009099a90
aa555aa5aaaaaaaa0077777700000000000000000000000000000000000000004444444400000000000000000000000a00000000000000000000000000000000
9aaaaaaa999999990666666650555505000000005055550500500000000000004a444444000000000a000a00000a000a00000a00a00a00000000000000000066
99999aaa0944449066666666555656550000000055656555055000005055550549aa4444000000000a0000a000a0000aa0000a0a0000aaaa0000000000006677
444499a500044000000000005555dd550d00000d55dd555555555555556565554499a44400000000a0a000a000a000a7a0000a0a0000a0000000000000067777
444449a50000000000000000055666500dd000dd056665505555555555dd555544999a4400a00000a0a000a000a000a7a0000aa00000aaa00005500000677776
444449a50000000000000000055666500d6d5d6d056665500550000005666550444999a4000a00000909009090a000a990000909000090000055550000677761
444449aa0000000000077777055666500d55555d05666550005000000d66d55044444444a00a00a00009009999900a7799000909000099990555555006777611
4444499a000000000066666655dd5dd5055555555dd5dd55000000000d66d55044444444090990900000900909000a7769000900900900005555555506776111
4444499a000000000000000000000000056d5d655000000000000000ccccc5550000000550000000555555550000a77679000000000000055000000000000000
444449aa000c00000000000000555500555555555500000000000000cccc5c550000005555000000555555550000777766600000000000555500000000000000
444449a5000cc0005055550505565650556555665555000000000000ccccc5550000055555500000550000550007777676600000000005555550000000000000
444449a5001ccc00555656550555dd500566d66665555500000000007c5c5c550000555555550000550000550007776766600000000055555555000000000000
444499a50011cc005555dd555556665505666666655555500000000075c5c5550005555555555000550000550077777666600000000055555555000000000a00
99999aaa000111000556665055566655005666666555555000000000575555550055555555555500550000550077776766660000000005555550000000000a00
9aaaaaaa00001000055d66d00556665000566666655555500000000055555555055555555555555055555555007776766666000000000055550000000a00a00a
aa555aa500000000055d66d055dd5dd0000566665555555000000000555555555555555555555555555555550aa7779766660000000000055000000009099090
555555555aa555aa0000000007cccc706667677c5555555500777700555555555555555555555555000000000aaa9a7969696000000000005555555500000000
55555555aaaaaaa90055550007c6cc7066667677555005550700007055555555055555555555555000000000aaa9a99999969000000000000555555000000000
55555555aaa99999056565500767cc7066676777550000557077000755555555005555555555550000000000aaaa999999999900000000000055550000000000
555555555a99444405dd5550077ccc7066667677500000057077ee075555555500055555555550000000000aaaa9a99999999990000000000005500000000000
555555555a9444445566655507cc6c706666677750000005700eee07555555550000555555550000000000aaaa9a99999999999900000000000000000ccc0000
555005555a9444445566655507cc76705666767555000055700eee0755555555000005555550000000000aaaaaa3a9999999999900000000000000000cffc000
55000055aa9444440566655007ccc77065666757555005550700007055555555000000555500000000000ababa3939393999999990000000000000000cff0000
50000005a99444440dd5dd5507cccc705555555555555555007777005555555500000005500000000000ababa3a3939393939393990000000000000000070000
55555555a994444400000000500000055555555555555555004bbb00004b000000400bbb00000000000ababb3a33333339393939393000000000000000000000
05555555aa94444450550000550000555555555050055555004bbbbb004bb000004bbbbb0000000000bbbbbbb333333333339333933300000000000000000000
005555555a9444440555050055500555555555005005505504200bbb042bbbbb042bbb0000000000bbbbbbbb3030303033333033333330000000000000000000
000555555a944444d5505550555555555555500055555555040000000400bbb0040000000000000bbbbb0b0b030303030303030303033300000000000ccc0000
000555555a994444d6665650555555555555500055555555040000000400000004000000000000b0b0b0b0b030303030303030303030303030000000ccffc000
00555555aaa999995666d5505555555555555500550555554200000042000000420000000000b00b0b0b000000000000030303030303030303000000cfff0000
05555555aaaaaaa9d606d6505555555555555550555555054000000040000000400000000b0b0b00b00000000000000000000000000000000003000003330000
555555555aa555aad555050055555555555555555555555540000000400000004000000000000000000000000000000000000000000000000000000007070000
0000000000000000000000000000000000861384337695d576a596854284526296e60000b34262b200864262b200000000b372960000422232e400d573e500e6
0086e585a57696869572859600b142526200869542525252525252624252525252525262132323233300000013525252008595853795e4008695008695000000
00000000000000000000000000000000000086039686960086968576425252621111111111136211001142621100000000b30311111142526276950000000000
00000086728383d596039600000042526200859642525252525252624252525252525233b2008656950000008613845200077696e68676958576958547000011
00000000000000000000000000000000210000030000000000d57696135252621222328383834232111252523211000000b3132222324252627656e500000000
0000008573838311117311111111132362859600425223232323233342525252525233b20000d576960031000086132385067695008576569686067676958512
0000000000000000000000000000000063000003000000000000e6000013523342526283368342522252845252321111e400b3425262135262869600006600e4
0000d502838312324353222222222222628695004233960086950012842323845262b20000001107e50000000000122247000706958676470000008606a54713
0000000000000000000000000000000096000073000000000000000000110312525233958676132323525252523312225695b313845232426285e50000548596
0085958643225233577613232352525262118695039600001186954233b1b1428462b2003100729600000000001142528637960007e5079600000000008696b1
00000000000000000000000000000000000000e6000000001100000085727342846276769586765676132323334352528676e5b3135262423396008543223295
859686958642629686767696861323235232008673e5008572008673b100851352331100000073111111111111125252857695008695e6008595000000000000
0000000000000000000000002700000000000061000000b383b200008673125252625776769586767676769685a51323d557950036426273b100d596b1426276
a5e5d59600426200855696000086e5002333e40000008596030000b100d596b1628383b293b383831253532222528452470747008556e5008676958595210000
00000000000000000083838383000000958595000000e41183b2000000b1425252339686a5960086765776958696e68600869600851333b1000085e585426296
869511000042628596e6100000000000223296003100e611030000000085958533b20000000086123396861352525252069686379686e500859686968602e500
000000000000000085122222329500007656960000e4868383b200d59585425262769500e6000000e68696e600000000000000857696e6000011869586426200
0086720000423396851222320000000052621100000011123300000000860696b1000000610000039600008642522323000000079500001107e5310000e60000
958595000000000012525252523200007656950085a5958383b2000086564252627696000000000000000000009400d30000d55676950000117200e611426211
0011030000039685764252620000000052627211111143339600610000000000000000000000007300000000133312220000b312321111729600000000111111
96e6869500000000425252845262000096869685767696b183b20000d576425262a5e50000000000e3d394108543532200000086769600e41262111112525232
1112620000038596e64252620000e400526213535363960000000000000085e500000000e40000e600310000861252520000b313522222621111111111122222
e500d5470000008542522323233300000000d5765796111183b200000086132333960000000000d5433283838383834200000000e66185764252222252525252
22523300007386e50042526200859685233396865695e4000000e4000000869500e400859600000000000000e442525200000086422323235353535322525252
95e485960000854323331222223295000000e48696857283831100000000b1b1b1000000000000008613638383728342000000e400d576574252528452525252
5262008595e600d5951323331186958696000000867676e500008695110000868596008695000000000000008613528400610000038596000000008613232323
2232471085122222222252525252320000855695d596423283839500000000000000000000000085950086432252225285958556958596861323525252525252
5262e4e68695001186761222328576e511000000d5968695110031867295218576950085069500000000000000b142520000e485739600000000000000008695
52842222324252525252525284526295857676769511426283728695820011111100e40000008596e600e486425284528696867676a59500b1b1135252522323
52339600d5a5e572008642526257960032950000110031867211111142222222867637470007e50011e4003100b3425200857656470031000011000000000086
5252525262425284525252525252523276577696861252522262008672001222328596000000869500855695425252520000857696e686950000004223331222
62579500857695030000425262e6000033960085721111111322223213528452d556767637769511720695000011132337a5767676958595007200d595000000
5252526242525252525233425252525223232323235252525252621352845252522333968613235284525262b200b34295859686950000869500000312225252
000000000000000000000000000000009600d556422222223213232363425223008606968676961262008695001222228676760676767676377395e4f0720000
23525262425223232333125252525262b2860696b34252525252523213525252629600000000d34252525262b200b342e686958596001100e661e47342525252
0000000000000000000000e4000000000000008613232323339600008613331200000000d5471142621100863742525285069600079686968696864700030000
32425262133376960086132352525262b200a100b3425252528423337613525262d30000e385125252525262b200b34200d57657e50072b20000861252525284
0000000000000000000085729500000000000000b1b1b10000000000000086420000000000861252523200850613845296000085769585950000008637038200
62135233767656950000e68613525262b2001100b34252525233b200e6861352523295941232135223525262b200b342e4008696000003110000114252525252
00000000000000000085125232950000000000000000006100000000000000420000e400001142845262379600b113520000d506767676769500000086030200
52327385968696e611d595e486135262b2d502e5b342525233b20000000086425252222252523273b1132362b200b31356958595000042321111125252232352
00000000000000851222525252320000110000001111110000000000008595428537569511435252523396000000864200000000860676574700000085039600
52523276e500001172b2865695864262b2009200b3425262b20000000000851352235284525233b100e68673b261b31296867676e50042522232138433000013
0000000000000012528423235262950032952185122232859531001185968642968696861232132333960000000000130000e400000007069600008596030082
525233968595b31262b2d57696004262b2000000b3135233b20000000000869503b113525233b100000000e60000b3420000e686958542525252327300000000
0000000000000042233376561333720052222232422333769600b372960000420000001142522232960000000000008611859600148596000000d54700030002
526236e48696b3426211008695d5136295006100e400039600001100000000e67300364233b100001100e4000000b313000000b3122223528452620000000000
00000000000000730676767676126295845223337356968695e4b37300000042000011125252523300000000000000003276e585374700111100859600030086
5262d59685e5b3425232b28576e5860386959300869503e400b3721100000000e6008573b1000011728596000000b343000000b342335613525262d30000c200
000000000000000737769686764252322333765696e600008656950000000042111112528452629685e50021000011113396008606961112320007e500030000
526285e58695b3425262b2867695857300e600000086739600b342321100000000d596e6000011126257e50000e40000e40000b37396e686425252329400c3e3
00000000000000123247678543525252857696e600000000008696000000854222321352525262859600b37211111222b10000d53795125233859600000321e4
523396008596114252621100865796b1000000000000b10000b34252320000001185950061d5125262960000855695005695e400e6d5e5854284525222222222
00000000000085425222222232425284579600000000000031d59511e485564252523213235262960000b3132222525200003100860642628596001111136306
3396008596b312525252320000e600a3000000000000000000b3425262e400b3727696e400004252331100008676960076765795d31085125252232323528452
00000000008572135252845262425252960000000000000000008672867696425284522232133311000000b3132323230000d595001142629600004363960000
96000086951142525252620000000000000061000000000000114252629600b303968556e511133312320000d576e500e68696f0122232132333122232132352
3295108512225232425252526213525200c200e31000000000000003859600425252525252222232110031000000008500000086951252620000000000000082
951094218612525252526200000000000000e40000859500b31252526211001103e5867695122222526200008576950000000011425252222222525252223213
52222222525252621352525252324252d3c394123295000000000073960011425252525252525252320000000010859600000000861352620000000000000002
222222223213525252526295d59500110000869500e68695b3425252627211126211008676425252526200d5a576a5e500000012525252845252525252525222
528452525252525232425252526242522222324262869500000000e600851284525252525252525262000085123243229510000000b142620000110031000086
52525252523242525252629685a595729500857695008596b3425252624222525232008557425252526200857676769500000042525252525252525252525252
525252525252845262425284526242525284624262123200000000008596425252525252525284526295851252523242222232950085426295b372b200000085
__map__
00000000000000000000000000000000685a2425265a675e687567242525252532323232323232323232323232335e00265a5e2425252631323232323233313232323324252525252525252525262425262425262425263125252525252525252525252525252525252624252600000000000024482600000068313225252525
000000000000000000000000000000005d672448267569000068672425252525000000685a676968675958675e0000002669002432323236596865695869585900003b24252525482525253232332425332425262425252331322525252525252525252525252525253324252600004e5d590024252600004e00006831323232
000000000000000000000000000000000068312525235900005d5a2425252525001a00586769000068676769003d49582659003700004e296e5d695869586968594e3b24252525252525335a67673126212525263125252522233132323232252525252525254825262125252611586900685931323359006859000000000068
00000000000000000000000000000000000068313232230d0e0f21252525252500003b3435353611112769001127342226675e0000585a594e0011685968596268693b24252525323233676767676737242525252324322525252223383838244825253232323232333132252523755e00586921222223595869585e00000000
0000000000000000000000000000000000000068696337594e58242525252525000000005867693435330000342523242667590058692123690027006e0068272b1a3b24253233212367676968756721252525252637273132323233386338242532333435366769000068242526690000685924252525222223205900000000
0000000000000000000000000000000000000000000068675a672425252548250028005867755e002900005d7531333126687520675e242611113711111111372b003b3133212225336769005d676724252525253363376767755e0068593824333436676767675e00000031482659585962682425252532323222230d0e0f21
000000000000000000000000000000000000000000000068677531323225252522223621222359000000000068675e002535353669002432353621223535365900003b34352525335a67595859676724252532336773676767675900006838240068676767676900000000683133270d0e0f20242548263838382426001a5824
00000000000000000000000000000000000000000000005867212222233132322533212525262122222223005869003d265867690028300021233133756759685e005867693126676759687567676724253359686967675a6767694e0000682400586767696e00001100000021222658594e6831323233386338242659586924
000000000800000000000000000000000000000000005d5a6724252525222222262125252526312525482522360d0f342667755900203000313369006e6867594e5d6769586730756769006869685a31335a6759586767696869585a59000024586968675900001127110058243226675a675934353669000068312668695824
00000000000000000000000000004e585900000000005867212548252525252533312525252523313232323359000000266767695d6737006869000000006e68695d5a596e6830696e000000005869615d67676767696e000000686769000031685958676900002125235968371b376867676720692900000000683700586924
004f002c3e000000000000000000685a69493e002c002123312525252525252500003132323233690000685a675e00002667692858696e00004e58590000000000116e6e00003700000000005d67597158756958675e0044000058675e0000215867696e0000582425265a591b4e1b586968696e000000110000000058695824
2222222223593d000000002c623d49685921222222222525232425252525252500000000005869000000006867592849265a5e2069000000586767755e0000000027000000006e00003d013e5875212222222369685900000058676900000024675a5e00005d6924323369685e6e5d675958590000001127594e001168596824
2525252525222223003d3e3c2122222223242525252525252631252525252525493d00005d675e493e0000006e6821222669586900000000685a67690000004e00300000001100000021222222222525252526212223383838382123490021256769000000005d37212358590011006869686759001121265a695d205e685924
25254825252525252222222225252525262425482525252525232425252525252223010058672122230d0e0e0f212525265d67594e0000005d67690011005869003011000027004e00242525252525252525332425252222222324252222252575590149005d59214826756911271100165d6769112724266759002700006824
252525252525252525252525252525252624252525252525252624254825252525252222222324252600585e58242548261268675a594900006859002758694e112423004e30586900242525252525252526212525252525252624252525252567273827585e6824252668592148235e005869112126242669685e3000585e24
252525252525252525254825252525252624252525252525252624252525252548252525252624252658690068242525252222222222230d0058675930695869212526006830685900242525252525252526242525252525252624252525252568303830695859242526596e2425265958675e21482624265900003058655924
3232263132262b003b2425252624252532322525252525252525252526242525252525252525252525253324266900000000242624482525252525252525252500000000002425252525330058590024252525254825262425252525252525252526242525252525262425252525252525254825265869682448262b00685924
0068376968302b003b24252526242525676731322525482525252525332425252525254825253232252621252600000000002426312525252525252525252525000000004e2425323233595869685924252525252525332425252525252525482533242525254825263132324832323225323225336900002425261100006831
3e006e2c3d302b163b2425253324252568675a6731252525252525262125482525252525323359683133242526000000595d24252331322525252525252548250000001a68242621366968690000682425253232323321252548252525252525262125252525252533630000371b1b1b3769683069000000242525232b000068
23593f3c21262b003b242526212525255968676767312525252525333132252525253233676569586921254833000000685924253369683132252525252532320000000000313330675e160000111124323369000068313232323225252532323324252532252526735900001b0000001b000030000000112425252611000000
2522222225332b003b242526242548256958676767692425252533690068312525267567696e586759312526694e0000006824266300006e0031323232332122004e0000000021266900000011212225690000000000586765696831323321222225252620242526706900003a0000003a0000370000582125252548362b3900
25252525266900003b31252631322525596867756958312525266900000068242526696e00006e686767242600685900003b24330000000000002122222225250068590000002426585911112125252511000000000070606900000068592425252525252225252674000000110000001100586900007024253232262b000000
252525252600000000683133675a3125675968675e6e6824483300004e0000312526590000111100685a243300586900003b3069000011000000242525252525005d67594e5d2426696821222525252523590000115869000000000000683125252525252525252669000058271111112711685900166e24336968372b000058
25323232264e0000005d20696e68672467655e6e00585931266900006e000068242668590021232b5d6730695d655e00003b37000000272b16002425322525253d5867675a59243358593125252525252670590027690000000000000000682425252532323232330d0000683122222225237369000058306900006e00587365
33690070370d000000004e00665d6724686900774e687569370000004e000000242600685924262b006830595869000000006e000000302b003b2426202425252222230d0e0f37676968673125252525336865733011111111110000000000244825331b1b1b1b1b00000000682425252526690000006830004e000000706069
690000687400000000585a5945587524005d3422232b6e006e00005865590000312600586924262b0000370d0e000000110000000011302b003b2425222525252525262b5d5929685958675a242525251b0070742422222222232b000000002425266900160000000000000011242525252611111111113773690011006e0000
00000058744e00005d2122233838212500006824262b000000005d6567655e00683058690024262b00001b0000000000231100005821262b003b2425252525252525262b00685958696867673132323211007074242525482526110000000031252673590011111100000058212525253233342222222223705e3b275e001200
0000006867690000582425262122482500000024261111111100006865690000003769003b242611004e000000000000482359586731262b003b2425323225322525332b00586769115875692122222223586560243232252525232b00000068242665693b2122232b000068312525332b003b312525253369003b3011112711
590000585a5900582125252624252525000000312522222223111111202b0000006e00003b24252358691600000000003233696e6865302b4e3b31332123370025262b005d675a59386769583125252526706900376968242548261100000000312674003b2425262b0000001b24332b001a003b3125332b00003b2422222522
22222369016859202425252631252525590000272448323232222222232b0000000000003b2425336900110000000000686900005d69302b68594e002426630025332b58596867673867596875242525336900006e005831252525232b004e00683769003b2425262b0000005d372b00001100003b372b000000112425254825
2525262122222222252525482324252568591030313367756731322526111111004e585e3b24261b00002711000000005e0000000000302b006e687324335958332b5867695d676900686759682425251b000000015821233132252611007059006e00003b2448262b5d735e0029000011271100006e0000003b212525252525
252526242525252525252525262425255d652125236769686767673125222223585a69003b24262b004e24232b000000000011585e0030111100006e300068750058696859587559001168675e312525000058212222252522233125232b6865590000003b2425262b586059000000582125235916000000003b242548252525
__gff__
0000040000000000000000040402020200020000040000000004000200000000030303030303030300040002020000000303030303030303030000020200000000000002000204000300000000000400000000000000000004040400000404000403040000040004040400000000040004030004040400000000000000000000
__sfx__
0102000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0102000011770137701a7702477000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000d77010770167702277000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011800001d35521355000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00000505000000295002650030525355000c0500c03011050110300c0500c03005050000000a050000002e5002e50016050160302e500295001105011030160501603016020160100a0500a0300a0200a015
010e00001d3551d3151f3451f31524345243152935529315283552831524345243151f33524300263572632226312263152435024332243222431500300003002271527715297252e72533735355353a5453c555
310500002256522565005002456524565005002656526565005002856528565005002956529565005002b5652b565005000050000500000000000000000000000000000000000000000000000000000000000000
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
001000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000e00000c053000000000000000346153460000000000002865500000000000c0000c053000000c0530000034600000053461500005286550c0000c053000000c05300000346150000028632286252400024000
000e00000505000000355002950030535000000c0500c03011050110300c0500c03005050000000a0500a03000000000001605016030160201601029525355001105011030110201101013050130301302013010
000e00001d3551d315243452431526345263152935529315283552831524345243151d335243002635726332263222632226312263152e74533725357453a525243502433224322243151f3501f3321f3221f315
000e0000140501403026515000000f0500f030080500000014050140300f0500f030080500f0000f0500f0502b5150a0000a0500a03003050030300a0500a0300f050000000f0500f03003050030300205002030
010e00001d3451d3151f3451f31524355243152636126332263222631524355243151f3451f3151d3451d3151b3551b3151d3451d3151f3551f315243612433224322243151f3551f3151d3451d3151b3351b315
010e000000050000000000000000050000000007050070300c0500c03007050070300005000000000500003000020000100000000000050000000007050070300c0500c0000c0500c03007050070300405004030
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
010e00001c3451c3151d3451d3151f3551f310243612432224312243151f3551f3151d3451d3151c3451c315283552831529345293152b3552b31530365303152473528715297352b71530745325353554534555
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01200000140501403026515000000f0500f030080500000014050140300f0500f030080500f0000f0500f0502b5150a0000a0500a03003050030300a0500a0300f050000000f0500f03003050030300205002030
012000000505000000355002950030535000000c0500c03011050110300c0500c03005050000000a0500a03000000000001605016030160201601029525355001105011030110201101013050130301302013010
0120000000050000000000000000050000000007050070300c0500c03007050070300005000000000500003000020000100000000000050000000007050070300c0500c0000c0500c03007050070300405004030
012000000000000000130441301518055180151a0611a0321a0221a0151805518015130451301511045110150f0550f0151104511015130551301518051180521805218055160451601512055120150f0450f015
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011c0000000001d5341d5321a5311a53218531185321c5311c535005001c5341c5321a5311a5321d5311d5321f5311f5321a5311a5350050018534185321a5311a53216531165321853118535005001a5341a535
010e0000267362d736267262d726267162d716267062d706267362d736267262d726267162d716267062d706267362b736267262b726267162b716267062b706267362b736267262b726267162b716267062b706
010e0000267362d736267262d726267162d716267062d706267362d736267262d726267162d716267062d70626736297362672629726267162971626706297062673628736267262872626716287162670628706
010e00001c5501c5401a5411a5401d5511d5501f5711f5701a5611a560005000050000500005051c5501c5501d5411d5401a5411a5401f5511f5501d5611d5601c5511c55000505005001c5501c5501a5611a560
010e00001c5511c5501a5411a540005000050000500005001c5501c5501d5411d5401f5511f5501d5411d54021561215601d5511d5501a5411a54000500005001a5501a5501d5611d5601c5511c5501854118540
011000000c3500c3400c3300c3200f3500f3400f3300f320183501834013350133401835013350163401d36022370223702236022350223402232013300133001830018300133001330016300163001d3001d300
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
010e000029615006002461510063006002661528665006000e0630000000600006002462500600266150060000600286150e05329615006002861524625266152966528615006000e06300600266152862524615
010e000029625266152b6150060011063286152b615006002b665296252861500000006002861513073296252661529625286150060026655296250060029615286152b615130732962500600266152862524615
010e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00001c5411c54000500005001a5401a5401d5511d5501c5411c5401f5511f5501a5411a54000500005001d5401d5401c5511c5501f5611f5601c5511c5501a5411a54000500005001a5501a5501d5411d540
010e0000296652861526615006000e06328615296252b615006002d625130532861500000006002962500600296650060011033286151006300000006002661528655246150060029625286152b6152867528615
010e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e000000000000001c5501c5501d5511d5502155121550005000050021550215501f5511f5501d5511d5501c5511c5501a5511a55000500005001a5501a5501c5511c5501a5511a5501c5511c5550000000000
010e00002962500600110632661528615006002666528625296150060013053006002b6152864529625006001105328615266150060026615296252866500600286152b625100530060026615006002462500600
01200000000003474530700307003074530700307003574530700307003074530700307003474530700307003774530700307003a74530700307003574530700300003073500000000002e735000000000032735
011c00000c6140c6100e6100e61010610106100c6100c6150a6140a61010610106100a6100a610116101161015610156100c6100c61011610116100e6100e6100a6100a6150e6140e61011610116100c6100c610
011c0000000001c5341c532185311853216531165321a5311a535005001d5341d5321a5311a5321c5311c532185311853500500165341653218531185321c5311c5321a5311a5321853118535005001c5341c535
012000003074500000000003274500000000002e74500000000003074500000000003474500000000003574500000000003274500000000003774500000000003474500000000003574500000000003074500000
000500000373005731077410c741137511b7612437030371275702e5712437030371275702e5712436030361275602e5612435030351275502e5512434030341275402e5412433030331275202e5212431030311
011c0000106101061013610136100c6100c6100a6100a6150e6140e61011610116101561015610106101061011610116100c6100c61011610116100a6100a6150e6140e61011610116100e6100e6101561015615
310800002456524565265652656528565285650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
011000000505000000000000c00011000110000c0500c0001105011000050500000005050050000305003000020500200000000000000000000000090500c0000e05011000090500000002050020500e0500e050
01100000000000000035600000003561500000000000000029165291152b1552b1152d1652d1152b1552b115000000000000000000001d13300000051230000029165291152b1552b1152d1652d1152915529115
911000001d3151d0152431524015213252102524325240251f3351f03524335240351d3251d02524325240251d3151d0152431524015213252102524325240251f3351f03524335240351d3251d0252432524025
030800200c053000003e600000003264500000000000000032635000000000000000326250000000000000003e645266353262500000326350000000000000000c05300000000000000026645000000000000000
0110000001050000000000000000000000000008050080000d050000000d050000000805008050000500005000000000000000000000070000700007050070000c0500c000000000000007050070000c0501c600
911000202e6102d6102a61028610296102a6102a61028610216101d61018610136100f6100d6100c6100c6100c6100c6100c6100f610146101d610246102a6102e61030610316103361033610346103461034610
01100000000000000000053000003561500000000000000029165291152b1552b1152d1652d1152e1552e1150c053000002d1552d11535615000002b1552b1150000000000291552911529155291151c6001c600
911000202e6102d6102a61028610296102a6102a61028610216101d61018610136100f6100d6100c6100c6100c6100c6100c6100f610146101d610246102a6102e61030610316103361033610346103461034610
__music__
00 0b0c1148
00 12131144
00 14151144
02 16181144
00 41424344
00 41424344
00 41424344
00 41424344
01 21232744
00 22242844
00 212a2b44
02 222d2e44
00 41424344
01 202f3044
02 31323444
00 41424344
01 38393a3b
02 3c3e3b7b
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
01 3d7e4344
00 3d1a4344
01 3d1b1d44
02 3d1c4344
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
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9hhh9hhhhh9hhh9hhhhh9hh9hh9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9hhhh9hhh9hhhh99hhhh9h9hhhh9999hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9h9hhh9hhh9hhh979hhhh9h9hhhh9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9h9hhh9hhh9hhh979hhhh99hhhhh999hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhphphphhphph9hhh9pphhhhphphhhhphhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhphhhphhppppphh977pphhhphphhhhpppphhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhphhhhhphhphphhh9776phhhphhphhphhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh97767phhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7777666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77776766hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77767666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh777776666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhhhhhhhhhhhhhhhhh7777676666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7776766666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh99777p76666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh999p97p6p6p6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh999p9pppppp6phhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9999pppppppppphhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9999p9pppppppppphhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhh7hhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9999p9pppppppppppphhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh99999939ppppppppppphhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9r9r93p3p3p3pppppppphhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9r9r9393p3p3p3p3p3p3pphhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7h9r9rr393333333p3p3p3p3p3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhrrrrrrr33333333333p333p333hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhrrrrrrrr3h3h3h3h33333h3333333hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhrrrrrhrhrh3h3h3h3h3h3h3h3h3h333hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhrhrhrhrhrh3h3h3h3h3h3h3h3h3h3h3h3h3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhh7hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhrhhrhrhrhhhhhhhhhhhhh3h3h3h3h3h3h3h3h3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhrhrhrhhrhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66666hhhhhhh66666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66hhh66hh6hh66h6h66hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66h6h66h666h666h666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66hhh66hh6hh66h6h66hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66666hhhhhhh66666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhdddhdddhhddhdddhddhhdddhdhhhhhhhhddhdddhdddhdddhhhhhdddhdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhdhdhdhhdhhdhhhhdhhdhdhdhdhdhhhhhhhdhhhdhdhdddhdhhhhhhhdhdhdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhdhddhhhdhhdhhhhdhhdhdhdddhdhhhhhhhdhhhdddhdhdhddhhhhhhddhhdddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhdhdhdhhdhhdhdhhdhhdhdhdhdhdhhhhhhhdhdhdhdhdhdhdhhhhhhhdhdhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhhdhdhdddhdddhdddhdhdhdhdhdddhhhhhdddhdhdhdhdhdddhhhhhdddhdddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhssshssshsshhsshhshshhhhhssshshshhsshssshhsshhsshsshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhssshshshshshshshshshhhhhhshhshshshshshshshhhshshshshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshshssshshshshshssshhhhhhshhssshshshsshhssshshshshshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshshshshshshshshhhshhhhhhshhshshshshshshhhshshshshshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshs6shshssshssshssshhhhhhshhshshsshhshshsshhsshhshshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhsshhhsshssshshhhhhhhssshssshssshssshshshhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshshshshshhhshhhhhhhshshshhhshshshshshshhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshshshshsshhshhhhhhhsshhsshhsshhsshhssshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshshshshshhhshhhhhhhshshshhhshshshshhhshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshshsshhssshssshhhhhssshssshshshshshssshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhdddhhddhddhhhhhhdddhdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdddhdhdhdhdhhhhhdhdhdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhdhdhdhdhdhhhhhddhhdddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhdhdhdhdhdhhhhhdhdhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhdhddhhdddhhhhhdddhdddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhsshssshssshssshshshshshssshsshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshhhshshshshshshshshshshshshshshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhssshssshssshsshhsshhssshssshshshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshshhhshshshshshshhhshhhshshshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhsshhshhhshshshshshshssshhhshssshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
