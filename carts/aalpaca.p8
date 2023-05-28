pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- alpine alpaca
-- created by @johanpeitz
-- audio by @gruber_music

-- special thanks
-- intro graphic by @2darray
-- art tips from @ilkkke

debug=false
extcmd("rec")
goto donewithintro


-- intro
daynumber="14"
::_::
//if (btnp()>0) goto donewithintro
cls(7)
f=4-abs(t()-4)
for z=-3,3 do
 for x=-1,1 do
  for y=-1,1 do
   b=mid(f-rnd(.5),0,1)
   b=3*b*b-2*b*b*b
   a=atan2(x,y)-.25
   c=8+(a*8)%8
   if (x==0 and y==0) c=7
   u=64.5+(x*13)+z
   v=64.5+(y*13)+z
   w=8.5*b-abs(x)*5
   h=8.5*b-abs(y)*5
   if (w>.5) rectfill(u-w,v-h,u+w,v+h,c) rect(u-w,v-h,u+w,v+h,c-1)
  end
 end
end
 
if rnd()<f-.5 then
 ?daynumber,69-#daynumber*2,65,2
end
 
if f>=1 then
 for j=0,1 do
  for i=1,f*50-50 do
   x=cos(i/50)
   y=sin(i/25)-abs(x)*(.5+sin(t()))
   circfill(65+x*8,48+y*3-j,1,2+j*6)
  end
 end
 
 for i=1,20 do
  ?sub("pico-8 advent calendar",i),17+i*4,90,mid(1-(-1-i/20+f),0,1)*7
 end
end
 
if (t()==8) goto donewithintro
 
flip()
goto _
::donewithintro::

function _init() 

 best=1
 cartdata("jpaalpaca")

 -- reset best
 best=dget(0)
 if (best==0) then
  reset_best()
 end

 swap_state(title_state)
end


function reset_best()
 set_best(10)
end

function set_best(b)
 best=b
 dset(0,b) 
end

-->8
--------------------------------
-- main game
--------------------------------

upgrade={
 { id=1,amt=2,df=0,icon=78,name="traversing",desc="add more turns to your deck", },
 { id=2,amt=2,df=0,icon=94,name="schussing",desc="add more downhill cards to your deck", },
-- -{ id=3,amt=3, name="perseverance",desc="reduces difficulty when played", },
-- -{ id=4,amt=1, name="bottom line",desc="awards instant points when played", },
 { id=5,amt=2,df=0,icon=110,name="ripping",desc="add strafe cards for sideways movement", },
 { id=6,amt=1,df=0,icon=76,name="snowplough",desc="reduces any gained speed", },
 { id=7,amt=1,df=0.5,icon=92,name="bombing",desc="speed up and get extra points, but game gets harder", },
 { id=8,amt=1,df=0,icon=126,name="mini schuss",desc="add short downhill cards to your deck", },
 { id=9,amt=1,df=1,icon=74,name="kicker",desc="jump obstacles when played, but game gets harder", },
 { id=10,amt=1,df=1,icon=108,name="snow bomb",desc="destroy obstacles when played, but game gets harder", }, 
-- -{ id=11,amt=1, name="shuffle",desc="reshuffles deck and hand when played", },
}

function init_play()
 first=false
 letters={
  {0,16,12}, --w
  {36,0,6}, --i
  {24,0,12}, --p
  {54,0,12}, --e
  {12,16,12}, --d
  
  {24,16,12}, --o
  {36,16,12}, --u
  {48,16,12}, --t
 }
 
 
 t=0
 hand={}
 deck={}
 pile={}
 trail={}
 particles={}
 ptext={}
 obs_lookup={}
 punch={
  active=false
 }

 fx={}
 fx[0]=0
 fx[2]=132 -- :(
 fx[4]=132
 fx[6]=128 --!
 fx[8]=128
 fx[10]=134
 fx[12]=130 -- :)
 fx[14]=134
 fx[32]=132
 fx[34]=132
 
 difficulty=2
 x_diff=0
 cpup=0
 cpicks={}
 pup_ui_y=128
 pup_ui_delay=0
 end_ui_y=130
 end_ui_delay=20
 end_t=0
 ui_gates=0
 max_deck=99
 wipe=16
 has_bombing=false
 broke_high=false
 broke_high_sfx=false
 bounce_count=0
 
 pl={
  x=3,
  y=1,
  jy=0,
  jyd=1,
  spr=66,
  moves={},
  cmove=nil,
  score=0,
  speed=0,
  gates=0,
  level_up=false,
  lx=0,
  ly=0,
  actions=0,
  jumps=0
 }
 
 tcamx=8
 tcamy=8
 set_cam_target(tcamx,tcamy)
 camx=tcamx
 camy=tcamy
 cam_delay=0
 -- mode
 -- -1 tutorial
 -- 0 draw
 -- 1 choose card
 -- 2 use card
 -- 3 impact
 -- 4 level up
 mode=-1
 last_mode=-2
 step_count=0
 
 -- obstacles & gates
 obstacles={}
 for y=1,64 do
  add_gate(y*7-3) 
 end
 -- todo: ugly hack
 next_gate=obstacles[2]
 
 for y=1,16 do
  add_obstacle(difficulty+x_diff,y)
 end
 
 -- inital deck
 for i=1,3 do 
  add_card(2,184,i) -- down
  add_card(1,183,i) -- left
  add_card(3,185,i) -- right
 end

 reshuffle(deck)

 -- initial hand
 add_card(1,183,2) -- left
 add_card(3,185,2) -- right
 add_card(2,184,2) -- down
 --add_card(4,188,3) -- slow
 --add_card(5,189,5) -- fast
 --add_card(9,174,0) -- jump
 --add_card(10,158,0) -- eraser
 for i=1,3 do
  draw_new_card(10+i*10)
 end
 
end

function reshuffle(array)
 for i=1,16 do
  local id=flr(rnd()*#array)
  local c=array[id]
  del(array,c)
  add(array,c)
 end
end

-- card sizes
cw=28
ch=10
function add_card(p_id,p_spr,p_spd)
  local c={
   x=98,
   ex=0,
   y=120,
   id=p_id,
   spr=p_spr,
   speed=p_spd,
   dx=0,
   dy=1,
   ds=0,
   pspr=66,
   hidden=true,
   delay=0,
   sm=1 -- speed multiplier
  }
 
  if (p_id==1) then
   c.dx=-1
   c.pspr=64
  end
  if (p_id==3) then
   c.dx=1
   c.pspr=68
  end
  if (p_id==4) then
   c.pspr=70
   c.str="slow down!"
  end
  if (p_id==5) then
   --c.pspr=70
   c.str="speed up!"
  end

  if (p_id==6) then
   c.dx=-1
   c.dy=0
   c.sm=0
  end
  if (p_id==7) then
   c.dx=1
   c.dy=0
   c.sm=0
  end  
  
  if (p_id==10) then
   c.dx=0
   c.dy=0
   c.sm=0
   c.speed=0
   c.on_complete=remove_obstacles
  end
  
  if (p_id==9) then
   c.dx=0
   c.dy=0
   c.sm=0
   c.speed=0
   c.on_complete=add_jump
   c.str="jump ready!"
  end
 
  add(deck,c)
end

function add_jump()
 pl.jumps+=1
 
 mode=0
end

function remove_obstacles()
 jumps=0
 for o in all(obstacles) do
  local dx=o.x-pl.x
  local dy=o.y-pl.y
  if (abs(dx)<=1 and dy>=-1 and dy<=1) then
   o.sink=16
  end
 end
 
 -- play bomb sfx
 sfx(53)
 
 -- fx
 for i=0,31 do 
  add(particles,{
   x=pl.x*16+8,
   y=pl.y*16+8,
   dx=(rnd(2)+3)*cos(i/32),
   dy=(rnd(2)+3)*sin(i/32),
   life=30-rnd(20),
   uf=function(p)
    p.x+=p.dx 
    p.y+=p.dy 
    p.dx*=0.9
    p.dy*=0.9
    p.life-=1
   end,
   df=function(p)
    circfill(p.x,p.y,10*(p.life/30),12)
    circfill(p.x-1,p.y-1,8*(p.life/30),7)
   end,
  })
 end


 mode=0

end

function draw_new_card(delay)
 if (#deck==0) then
  deck=pile
  pile={}
  reshuffle(deck)
  max_deck=0
  delay=#deck*3
 end

 local c=deck[#deck]
 c.delay=delay
 c.ex=0
 c.x=98
 c.y=120
 c.hidden=true
 add(hand,c)
 del(deck,c)
end


function update_play()
 t+=1
 if (t>10000) t-=9000
 
 if (wipe>0) then
  wipe-=1
 end
   
 if (mode==-1) then --tutorial
  if (t>305 or 
      bp()) then
   mode=0
   add_punch("let's go!")
  end
 elseif (mode==0) then -- draw
  last_mode=0
  draw_new_card(t>10 and 0 or 50)
  ccard=hand[1]
  mode=1
 elseif (mode==0.5) then
  if (btn(⬇️) or btn(⬆️) or bp()) then   
   ccard=hand[1]
   mode=1
   sfx(63)
  end
 elseif (mode==1) then -- choose
  local last_card=ccard
  if (btnp(⬆️)) ccard=get_prev_card()
  if (btnp(⬇️)) ccard=get_next_card()
  
  if (last_card!=ccard) sfx(63)
  
  if (ccard!=nil) then
   pl.spr=ccard.pspr
   if (last_card!=ccard or last_mode==0) then
    set_cam_target(pl.x*16-3*16+8+(ccard.speed*16*ccard.dx))
   end
   
   local ok_to_use=true
   if (ccard.id==4 and pl.speed==0) ok_to_use=false
   
   if (bp() and ok_to_use) then
    if (ccard.id>=9) then
     sfx(61)
    else
     sfx(62)
    end
    
    mode=2
    bounce_count=0
    pl.actions+=1
    
    if (ccard.str!=nil) then
     add_punch(ccard.str)
    end
    
    -- create delta list
    local spd=ccard.speed+ccard.sm*pl.speed
    for i=1,spd do
     add(pl.moves,{
      x=ccard.dx,
      y=ccard.dy,
      spd=2
     })
    end
    step_count=0
    if (spd==0) then
     step_count=16
     add(pl.moves,{
      x=0,
      y=0,
      spd=0
     })
    end
    
    pl.cmove=pl.moves[#pl.moves]
    del(hand,ccard)
    add(pile,ccard)
   end 
  end
  last_mode=1
 elseif (mode==2) then -- use
  local boom=false
  if (pl.jy==0) then
   add(trail,{
    x=7+pl.x*16+pl.cmove.x*step_count,
    y=8+pl.y*16+pl.cmove.y*step_count
   })
   add(trail,{
    x=7+pl.x*16+pl.cmove.x*(step_count+1),
    y=8+pl.y*16+pl.cmove.y*(step_count+1)
   })
  
   local pcs={12,6,7}
   for i=1,16 do
    add(particles,{
     x=rnd(4)-2+7+pl.x*16+pl.cmove.x*(step_count+1),
     y=rnd(4)-2+8+pl.y*16+pl.cmove.y*(step_count+1),
     dx=0.5*(-pl.cmove.x*2+rnd(2)-1),
     dy=-2-rnd(),
     c=pcs[flr(1+rnd(#pcs))],
     life=10+rnd(10),
     uf=u_snow,
     df=d_snow
    })
   end
  end 
  
  if (pl.jy>0) then  
   pl.jy+=pl.jyd
   if (pl.jy>16) pl.jyd=-2
   if (pl.jy<0) then
    pl.jy=0
   end
  end
  
  -- check next obstacle
  if (pl.jy==0 and step_count==0) then
   for i=1,#obstacles do
    o=obstacles[i]
    if (o.y>pl.y+10) i=9999
     
    if (o.x==pl.x+pl.cmove.x and
        o.y==pl.y+pl.cmove.y) then
     if (fx[o.spr]==132) then
      if (pl.jumps>0) then
       pl.jumps-=1
       pl.jyd=4
       pl.jy=1
       -- play land jump sfx
       sfx(52)
       
       -- duplicate last move
       add(pl.moves,{
        x=pl.cmove.x,
        y=pl.cmove.y,
        spd=pl.cmove.spd
       })
      end
     end     
    end
   end
  end
  
  -- done skiing?  
  step_count+=pl.cmove.spd
  if (step_count==16) then
   step_count=0

   pl.x+=pl.cmove.x
   pl.y+=pl.cmove.y
   pl.lx=pl.cmove.x
   pl.ly=pl.cmove.y
   del(pl.moves,pl.cmove)
   set_cam_target(pl.x*16-3*16+8,
      pl.y*16-24,1)

   -- check for impacts
   next_gate=nil  
   for i=1,#obstacles do
    o=obstacles[i]
    if (o.y>pl.y+10) i=9999

    if (o.x==pl.x and o.y==pl.y and o.hit==false) then
     if (pl.jy==0) o.ht=10
     if (pl.jy==0) o.hit=true
     if (o.spr==6) then
      add(pl.moves,{x=1,y=0,spd=4})
      bounce_count+=1
      add_score(bounce_count)
      sfx(60)
     elseif (o.spr==8) then
      add(pl.moves,{x=-1,y=0,spd=4})
      bounce_count+=1
      add_score(bounce_count)
      sfx(60)
     elseif (o.spr==10) then
      add(pl.moves,{x=1,y=0,spd=4})
      sfx(60)
     elseif (o.spr==14) then
      add(pl.moves,{x=-1,y=0,spd=4})
      sfx(60)
     elseif (o.spr==12) then
      clear_gate(o)
      if (ui_gates==3) then
       pl.level_up=true
      end
     elseif (fx[o.spr]==132) then
      if (pl.jy==0) then
       pl.moves={}
       boom=true
      end
     end
    end
    
    -- set next gate
    if (next_gate==nil and o.y>pl.y and o.spr==12) then
     next_gate=o
    end 
   end
 
   -- get next move
   pl.cmove=pl.moves[#pl.moves]

   -- add obstacles
   add_obstacle(difficulty+x_diff,16)
   
  
  end
  if (#pl.moves==0) then
   if (boom) then
    pl.spr=72
    music(27)
    sfx(58)
    if (pl.score>best) then
     set_best(pl.score)
    end
    end_t=0
    mode=3
   elseif (pl.level_up) then
    mode=4
    pl.level_up=false
    cpup=0
    pup_ui_delay=20
    pup_ui_y=128
  
    cpicks={}
    for i=1,#upgrade do
     -- dont add id=6 unless 
     -- pl has_bombing
     if (upgrade[i].id==6) then
      if (has_bombing) add(cpicks,i)
     else
      add(cpicks,i)
     end
    end
    while(#cpicks>3) do
     del(cpicks,cpicks[flr(rnd(#cpicks+1))])
    end

    
   elseif (ccard.on_complete) then
    mode=5
    ccard.on_complete()
   else
    mode=0
    pl.jumps=0
    pl.jy=0
    
    if (ccard.id==4) pl.speed-=1
    if (ccard.id==5) pl.speed+=1
    pl.speed=max(0,pl.speed)
   
    pl.cmove=nil
    ccard=nil
    set_cam_target(pl.x*16-3*16+8,
      pl.y*16-24,1)
   end
  end
 elseif (mode==3) then
  pl.lx+=sign(pl.lx)
  pl.ly+=sign(pl.ly)
  pl.lx*=0.95
  pl.ly*=0.95

  if (abs(pl.lx)>0.1 or abs(pl.ly)>0.1) then
   add(trail,{
    x=7+pl.x*16+pl.lx,
    y=8+pl.y*16+pl.ly,
    boom=true
   })
  end  
  
  if (bp()) then
   --swap_state(title_state)
   swap_state(wipe_state)
   sfx(61)
  end
 elseif (mode==4) then
  local ocpup=cpup
  if (btnp(⬅️)) cpup-=1
  if (btnp(➡️)) cpup+=1
  if (cpup<0) cpup+=3
  if (cpup>2) cpup-=3
  if (cpup!=ocpup) then
   pup_ui_y-=5
   sfx(63)
  end
  if (bp()) then
   sfx(61)
   -- add cards
   local u=upgrade[cpicks[cpup+1]]
   apply_upgrade(u)
  
   -- move on
   mode=0
   pl.jumps=0
   pl.jy=0
   ui_gates=0
  end
 end
 
 -- update text particles
 for p in all(ptext) do
  p.x+=p.dx
  p.y+=p.dy
  p.dx*=0.95
  p.dy*=0.9
  p.life-=1
  if (p.life<0) del(ptext,p)
 end

 --if (mode==2 or mode==3) do
  for p in all(particles) do
   p.uf(p)
   if (p.life<0) del(particles,p)
  end
 --end
 
 -- update obstacles
 for o in all(obstacles) do
  if (o.ht>0) o.ht-=2
  if (o.y<pl.y-5) then
   del_o(o)
   del(obstacles,o)
  end
 end
 
 -- cull trail
 for p in all(trail) do
  if (p.y<(pl.y-6)*16) del(trail,p)
 end
 
 -- update camera
 if (cam_delay>0) then
  cam_delay-=1
  if (cam_delay==0) then
   tcamx=next_tcamx
   tcamy=next_tcamy
  end
 end

 camx+=(tcamx-camx)*0.08
 camy+=(tcamy-camy)*0.08
 
 -- update punch
 if (punch.active) then
  punch.t-=1
  if (punch.t==0) punch.active=false
 end
 
 -- base difficulty
 difficulty=2+flr(pl.y/10)
end

function u_snow(p)
 p.x+=p.dx
 p.y+=p.dy
 p.dx*=0.95
 p.dy+=0.2
 p.life-=1
end

function d_snow(p)
 pset(p.x,p.y,p.c)
end



function apply_upgrade(u)
 if (u.id==1) then
  -- turns
  add_card(1,183,2)  -- left
  add_card(3,185,2) -- right
 elseif (u.id==2) then
  -- straights
  add_card(2,184,2) -- down
  add_card(2,184,3) -- down
 elseif (u.id==3) then
  -- less difficulty
 elseif (u.id==4) then
  -- points
 elseif (u.id==5) then
  -- strafe
  add_card(6,186,1)
  add_card(7,187,1)
 elseif (u.id==6) then
  -- slow down
  add_card(4,188,2)
 elseif (u.id==7) then
  -- speed up
  add_card(5,189,4)
  has_bombing=true
 elseif (u.id==8) then
  -- short straight
  add_card(2,184,1) -- down
 elseif (u.id==9) then
  -- jump
  add_card(9,174,0)
 elseif (u.id==10) then
  -- white out
  add_card(10,158,0)
 elseif (u.id==11) then
  -- shuffle
 end

 x_diff+=u.df
 
 reshuffle(deck)
end

function add_score(amt)
 pl.score+=amt
 
 add(ptext,{
  str="+"..amt,
  x=pl.x*16+4,
  y=pl.y*16-8,
  dx=0,
  dy=-1,
  life=20
 })
end

function clear_gate(g)
 add_score(pl.speed+3)
 
 if (pl.score>best) then
  broke_high=true
 end
-- add_punch("gate passed!")
 pl.gates+=1
 ui_gates+=1
 sfx(59)

 for i=1,#obstacles do
  o=obstacles[i]
  if (o.y>pl.y+12) i=999
   
  if (o.spr==10 or o.spr==14) then
   if (o.y==g.y) then
    o.spr+=32
    o.ht=10
   end
  end
 end
end

function set_cam_target(x,y,delay)
 if (x) next_tcamx=x
 if (y) next_tcamy=y
 if (delay) then
  cam_delay=delay
 else 
  cam_delay=10
 end
end

function add_gate(dist)
  local gx=pl.x+flr(rnd(6))-3
  add(obstacles,{
   x=gx-1,
   y=pl.y+dist,
   spr=10,
   ht=0,
   hit=false
  })
  set_o(obstacles[#obstacles])

  add(obstacles,{
   x=gx,
   y=pl.y+dist,
   spr=12,
   ht=0,
   hit=false
  })
  set_o(obstacles[#obstacles])

  add(obstacles,{
   x=gx+1,
   y=pl.y+dist,
   spr=14,
   ht=0,
   hit=false
  })
  set_o(obstacles[#obstacles])

end

function add_obstacle(amnt,dist)
 local os={2,4,32,34, 6,8}
 for j=1,amnt do
  local ospr=os[flr(rnd(#os)+1)]
  local rx=pl.x+flr(rnd(32))-16
  local ry=pl.y+dist
  -- just skip occupied slots
  if (get_o(rx,ry)==nil) then
   add(obstacles,{
    x=rx,
    y=ry,
    spr=ospr,
    ht=0,
    hit=false
   })
   set_o(obstacles[#obstacles])
  end
 end
end

function set_o(o)
 obs_lookup[o.x.."x"..o.y]=o.spr
end

function del_o(o)
 obs_lookup[o.x.."x"..o.y]=nil
end

function get_o(x,y)
 return obs_lookup[x.."x"..y]
end

function get_next_card()
 local hit=false
 for c in all(hand) do
  if (hit) return c
  if (ccard==c) hit=true
 end
 
 return ccard 
end

function get_prev_card()
 local prev=ccard
 for c in all(hand) do
  if (ccard==c) return prev
  prev=c
 end
 
 return ccard 
end

function add_punch(str)
 punch.str=str
 punch.active=true
 punch.t=50
 punch.ty=50
 punch.y=128
end

function draw_punch()
 local y=punch.y
 
 if (punch.t<10) punch.ty=-20
 
 punch.y+=(punch.ty-punch.y)*0.2
 
 for yy=0,10 do
  line(15-yy/2,y+yy+2,80-yy/2,y+yy+2,12)
  line(15-yy/2,y+yy,80-yy/2,y+yy,14)
 end
 print(punch.str,
       48-2*#punch.str,y+3,1)
end

function draw_play()
 cls(7)
 
 -- grid
 local ox=flr(camx)%16
 local oy=flr(camy)%16
 for x=0,8 do
  for y=0,8 do
   spr(0,-ox+x*16,-oy+y*16,2,2)
  end
 end
 
 -- world 
 camera(camx,camy)

 -- trail
 for p in all(trail) do
  if (p.boom) then
   circfill(p.x,p.y,3,12)
  else
   rectfill(p.x-3,p.y,p.x-2,p.y+1,12)
   rectfill(p.x+2,p.y,p.x+3,p.y+1,12)
  end
 end
 
 -- card effects
 for c in all(hand) do
  local ok_to_use= c==ccard
   
  if (c.id==4 and pl.speed==0) ok_to_use=false

  if (ok_to_use) draw_path(c)
 end 
 
 -- obstacles
 for o in all (obstacles) do
  local sx=8*(o.spr%16)
  local sy=8*flr(o.spr/16)
  local h=16+o.ht
  
  if (o.sink) then
   o.sink-=1
   
   if (o.sink<=0) del(obstacles,o)
   
   h*=(o.sink/16)
   sspr(sx,sy,16,16,
        o.x*16,o.y*16-4-o.ht+(16-h),16,h)
  else
   sspr(sx,sy,16,16,
        o.x*16,o.y*16-4-o.ht,16,h)
  end
 end
 
 -- particles
 for p in all(particles) do
  p.df(p)
 end
 
 -- player
 local mx=0
 local my=0
 if (pl.cmove!=nil) then
  mx=pl.cmove.x*step_count
  my=pl.cmove.y*step_count
 end
 local pjy=0
 if (pl.jumps>0 and mode==1) then
  pjy=abs(3.5*sin(t/30))
 end
 
 spr(pl.spr,
     pl.x*16+mx+pl.lx,
     pl.y*16-4+my+pl.ly-pl.jy+pjy,
     2,2,boom and pl.lx>0 or false)
  
 for c in all(hand) do
  if (c==ccard) draw_path_obstacles(c)
 end 
 
 -- particles
 for p in all(ptext) do
  printo(p.str,p.x,p.y,7,1)
 end

 -- ui
 camera()
 
 -- next gate
 if (next_gate!=nil and mode!=3) then
  local ngx=max(0,min(95,7+16*next_gate.x-camx))
  local ngy=min(127,8+16*next_gate.y-camy)
  if (ngx==95 or ngx==0 or ngy==127) then
   circ(ngx,ngy,12-flr(t/2)%12,8)
  end
 end
 
 if (punch.active) draw_punch()

 -- game over
 if (mode==3) then
  
  if (end_ui_delay<=0) then
   end_t+=1
   end_ui_y+=(60-end_ui_y)*0.4
  else
   end_ui_delay-=1
  end
  local ey=end_ui_y
  
  for i=0,35 do
   line(15+i/4-5,end_ui_y+i,82+i/4-5,end_ui_y+i,13)
   line(15+i/4-5,end_ui_y+i-2,82+i/4-5,end_ui_y+i-2,14)
  end

  draw_letters_2(1,5,min(15,-100+end_t*8),60+0)
  draw_letters_2(6,8,max(45,196-end_t*8),60+16)
  
  local ty=max(0,100-end_t*4)
  local sc1=7
  if (broke_high) then
   sc1=flr(t/4)%4<2 and 12 or 14
   if (ty==0 and not broke_high_sfx) then
    broke_high_sfx=true
    sfx(56)
   end
  end
  
  local dstr=""..3*(pl.y-1)
  printo("   score "..pl.score,25,ty+100,sc1,1)
  printo("distance "..dstr,25,ty+108,7,1)
  spr(177,62+4*#dstr,ty+106)
  printo("   moves "..pl.actions,25,ty+116,7,1)

  if (end_t%32>17) printo("❎",2,121,13,7)  
 end
 
 camera(min((t-16)*3-40,0),0)
 -- card tray
 rectfill(96,0,127,127,14)
 line(95,0,95,127,12)
 local dir=1
 local x=121
 for y=0,127 do
  line(x,y,127,y,2)
  x+=dir
  if (x>124 or x<119) dir=-dir
 end
 
 -- score
 print("score",98,2,2)
 local d1=flr(pl.score/100)
 local d2=flr((pl.score-d1*100)/10)
 local d3=pl.score-d2*10-d1*100
 pal(12,1)
 spr(115+d1,99,9)
 spr(115+d2,99+8,9)
 spr(115+d3,99+16,9)
 pal(12,broke_high and (t%16<8 and 7 or 10) or 15)
 spr(115+d1,98,8)
 spr(115+d2,98+8,8)
 spr(115+d3,98+16,8)
 pal()
 
 -- gates
 print("gates",98,22,2)
 local y=28
 for x=1,3 do
  local id=160
  if (ui_gates>=x) then
   id+=1
   if (ui_gates==3 and flr((t-x*4)/8)%3==1) id+=1
  end
  spr(id,91+6*x,y)
 end
 
 -- deck
 if (max_deck<#deck) then
  if (t%3==0) max_deck+=1
 end
 for i=1,min(max_deck,#deck) do
  spr(96,
      100+0.5*sin(i/2.5)+0.5*cos(i/3.5),
      112-i*1,3,2)
 end
 printo(""..min(max_deck,#deck),117,120,7,2)
 
 -- misc
 if (debug==true) then
  print("diff: "..difficulty+x_diff,97,110,7)
 end
 
 -- keys
 local tt=t
 if (mode!=4 and mode!=3) then
  if (pl.y>10 or mode!=1) tt=30
  print("⬆️",99,95,tt%60>50 and 7 or 12)
  print("⬇️",107,95,(tt-5)%60>50 and 7 or 12)
  print("❎",118,95,(tt-10)%60>50 and 7 or 12)
 end
 
 -- hand
 print("cards",98,41,2)
 y=47
 for c in all(hand) do
  if (c.delay<=0) then
   c.x+=(98-c.x)*0.2
   c.y+=(y-c.y)*0.2

   if (abs(c.y-y)<2) c.hidden=false
   draw_card(c,c.x,c.y)
   y+=12
  else
   c.delay-=1
  end
 end
 

 
 -- upgrades
 if (mode==4) then
  if (pup_ui_delay<=0) then
   pup_ui_y+=(80-pup_ui_y)*0.3
  else
   pup_ui_delay-=1
   if (pup_ui_delay==1) then
    sfx(57)
   end
  end
  local py=pup_ui_y
  local u
  
  -- panel bg
  
  rectfill(2,py+10,93,127,1)
  rectfill(3,py+ch+1,92,127,12)
  rectfill(2+cpup*30,py-2,5+cw+cpup*30,py+ch-1,1)
  rectfill(3+cpup*30,py-1,4+cw+cpup*30,py+ch,12)
  
  -- cards    
  for i=0,2 do
   u=upgrade[cpicks[i+1]]
   pal(8,7)
   clip(0,0,127,py+ch)
   local yy=py+2
   if (i!=cpup) then
    pal(8,6)
    yy+=2
    rectfill(3+i*30,yy-1,4+i*30+cw,127,1)
    rectfill(4+i*30,yy,3+i*30+cw,127,13)
    yy+=2
   end
   local xx=10+i*30
   if (u.icon==126) yy+=flr(t/8)%3
   if (u.icon==110) xx+=flr(t/8)%2
   if (u.icon==76) yy+=((t%8<2) and 1 or 0)
   if (u.icon==94) yy+=flr(t/8)%2
   if (u.icon==92) then
    clip(0,yy,127,i==cpup and 8 or 4)
    spr(u.icon,xx,yy+flr(t/2)%8,2,1)
    spr(u.icon,xx,yy-8+flr(t/2)%8,2,1)
   elseif (u.icon==78) then
    local tt=flr(t/8)%4
    local xxx=0
    local yyy=0
    if (tt==0) then
     xxx-=1
     yy+=1
    end
    spr(u.icon,xx+xxx,yy)
    spr(u.icon+1,xx+8-xxx,yy)
   else
    spr(u.icon,xx,yy,2,1)
   end
  end
  clip()
  pal()
    
  u=upgrade[cpicks[1+cpup]]

  print(u.name,6,py+15,7)
  local ix=87-u.amt*3
  for i=1,u.amt do
   spr(176,6+4*#u.name+i*3,py+13)  
  end
  for ux=1,2*u.df do
   spr(178,84-ux*6+6,py+13)
  end
  
  -- break str into lines
  local str=u.desc
  local lines={}
  local words={}
  local done=false
  while not done do
   local id=indexof(str," ")
   if (id==0) then 
    done=true
    id=#str+1
   end
   add(words,sub(str,1,id-1))
   str=sub(str,id+1)
  end
  -- render lines
  local lc=0
  local x=6
  for w in all (words) do
   if (x+(#w+1)*4>90) then
    lc+=1
    x=6
   end
   print(w,x,py+23+lc*6,1)
   x+=(#w+1)*4
  end
  
  -- help
  local hdr="3 gates = new cards"
  local hy=max(py-11,59)
  printo(hdr,48-#hdr*2,hy,7,1)
  local lpy=max(py+42,122)
  local hdr="⬅️➡️browse  ❎select   "
  print(hdr,48-#hdr*2,lpy,6)
  
 end
 
 camera()
 
 
 -- tutorial
 if (mode==-1) then
  local ty1=max(50,140-t*8)
  if (t>100) ty1=50-8*(t-100)
  textbox("play cards to ski",ty1,1)
 
  local ty2=max(86,140+800-t*8)
  if (t>200) ty2=86-8*(t-200)
  textbox("pass gates to score",ty2,2)
 
  local ty3=max(40,140+1600-t*8)
  if (t>300) ty3=40-8*(t-300)
  textbox("don't crash!",ty3,3)
 end
  
 -- wipe
 if (wipe>0) then
  for y=0,128,4 do
   rectfill((16-wipe)*10-y/4,y,
            256,y+3,10)
           
  end
 end
 
 
 -- debug
 if (debug) then
  local mx=113-pl.x
  local my=100-pl.y
  
  for o in all(obstacles) do
   pset(mx+o.x,my+o.y,8) 
  end
  pset(mx+pl.x,my+pl.y,7)
 end
 
end

function draw_card_bg(x,y,col)
 rectfill(x+1,y+1,x+cw,y+ch,1)
 rectfill(x,y,x+cw-1,y+ch-1,col)
end

function draw_card(c,x,y)
 if (c.hidden) then
  spr(96,x+2,y-4,3,2)
  return 
 end
 
 if (c==ccard) then
  c.ex=-8 
 else
  c.ex*=0.7
 end

 local col=(c==ccard and 10 or 12)
 if (pl.speed==0 and c.id==4) then
  col=8
 end
 draw_card_bg(x+c.ex,y,col)
 local iw=1
 if (c.id>=9) iw=2
 pal(12,col==10 and 12 or 7)
 spr(c.spr,x+1+c.ex,y+1,iw,1)
 
 local show_bonus=pl.speed

 if (ccard != nil and ccard!=c and ccard.id==5) show_bonus+=1
 if (ccard != nil and ccard!=c and ccard.id==4) show_bonus-=1
 if (c.id==6) show_bonus=0
 if (c.id==7) show_bonus=0
 if (c.id==8) show_bonus=0
 if (c.id==9) show_bonus=0
 if (c.id==10) show_bonus=0
 
 if (show_bonus>0) then
  print("+"..show_bonus,x+20+c.ex,y+4,12)
 end

 if (c.speed>0) then
--  spr(115+c.speed+show_bonus,x+13+c.ex,y+1)
  spr(115+c.speed,x+13+c.ex,y+1)
 end

 
 pal()
end


function draw_path(c)
 local x=pl.x+c.dx
 local y=pl.y+c.dy
 if (c.dy==0) y+=1
 for i=1,ccard.speed+ccard.sm*pl.speed do
  
  -- draw path
  local ox=-c.dx*16
  local cx=-1+c.dx
  for a=0,15,8 do
   local j=(a+t%8)
   local col=12
   circfill(ox+8+x*16+j*c.dx+cx,
            -8+y*16+j*c.dy,
            min(i,3),
            col)
  end
  if (i==ccard.speed+ccard.sm*pl.speed) then
   circ(ox+7+x*16+16*c.dx,
        -9+y*16+16*c.dy,
        2+flr(t/2)%6,
        12)
  end

  x+=c.dx
  y+=c.dy
 end
 
 -- eraser
 if (c.id==10) then
  local ecol={15,15,14,8,14,15}
  local et=flr(t/4)%#ecol+1
  col=ecol[et]
  rect(16*x-10-et,16*y-26-et,
       16*x+24+et,16*y+8+et,col)
 end
end


function draw_path_obstacles(c)
 local x=pl.x+c.dx
 local y=pl.y+c.dy

 for i=1,ccard.speed+ccard.sm*pl.speed do
  
  -- check for obstacles
  for i=1,#obstacles do
   o=obstacles[i]
   if (o.y>pl.y+12) i=999
  
   if (not o.sink and o.x==x and o.y==y and fx[o.spr]!=0) then
    local skip=false
    if (o.spr==42 or o.spr==46) skip=true
   -- if (fx[o.spr]==134 and ccard.dx==0) skip=true
    
    if (not skip) then
     local sx=8*(fx[o.spr]-128)
     local sy=64
     local st=flr((t+i*2)/2)%8
     local s=16--8+st
     local cdx=ccard.dx
     if (cdx==0 and (o.spr==10 or o.spr==6)) cdx=1
     if (cdx==0 and (o.spr==14 or o.spr==8)) cdx=-1
     sspr(sx,sy,16,16,
          x*16+cdx*st/2,
          y*16-st-4,
          s,s)         
    end
   end
  end

  x+=c.dx
  y+=c.dy
 end
end

-- bad last minute
-- cut n paste
function draw_letters_2(a,b,sx,sy)
 local x=0
 
 for j=a,b do
  local l=letters[j]
  for i=0,15 do
   pal(i,1)
  end
  sspro(l[1],96+l[2],l[3],16,sx+x,sy)
  pal()
  local dx=l[3]
  sspr(l[1],96+l[2],l[3],16,sx+x+l[3]/2-dx/2,sy,dx,16)
  x+=l[3]+1
 end
end

play_state = {
 name = "play",
 init = init_play,
 update = update_play,
 draw = draw_play
}



-->8
--------------------------------
-- core functions 
--------------------------------
debug_str=""

--------------------------------
-- state swapping 
--------------------------------
state, next_state, change_state = {}, {}, false

function swap_state(s)
 next_state, change_state = s, true
end

--------------------------------
-- base functions 
--------------------------------
function _update()
 if (change_state) then
  state, change_state = next_state, false
  state.init()
 end

 state.update() 
end

function _draw()
 state.draw()
 
 -- debug, 175 tokens
 if (debug) then
  camera()
  
  local str = state.name .. " "
    
  if (btn(0)) str = str .. "⬅️"
  if (btn(1)) str = str .. "➡️"
  if (btn(2)) str = str .. "⬆️"
  if (btn(3)) str = str .. "⬇️"
  if (btn(4)) str = str .. "🅾️"
  if (btn(5)) str = str .. "❎"  

  str = str .. " " .. debug_str
  
  local mr = stat(0)/1024

  local ypos = 121
  if (debug_at_top) ypos=0
  rectfill(0,ypos,127,ypos+6,8)
  
  line(1, ypos+2, 8, ypos+2, 1)
  line(1, ypos+2, 1+min(7*stat(1),7), ypos+2, (stat(1)>1 and 8 or 12))
  
  line(1, ypos+4, 8, ypos+4, 2)
  line(1, ypos+4, 1+min(7*mr,7), ypos+4, (mr>1 and 8 or 14))
  print(str,10,ypos+1,15)

  debug_str = ""
 end
 
end
-->8
--------------------------------
-- utilities
--------------------------------

function textbox(str,y,extra)
 rectfill(2,y,92,y+9,13)
 rect(2,y+1,92,y+10,1)
 rect(2,y,92,y+9,12)
 print(str,4,y+3,7)
 
 if (extra==1) then
  rectfill(79,y-1,88,y+11,1)
  rectfill(79,y-1,88,y+10,12)
  local ar=flr(t/16)%4
  if (ar==3) ar=1
  pal(12,5)
  spr(183+ar,80,y+2)
  pal(12,7)
  spr(183+ar,80,y+1)
  pal()
 end

 if (extra==2) then
  rectfill(81,y-5,89,y+14,1)
  rectfill(81,y-5,89,y+13,12)
  for i=0,15 do pal(i,5) end
  spr(10,81,y-3,1,2)
  pal()
  spr(10,81,y-4,1,2)
 end

 if (extra==3) then
  rectfill(69,y-5,86,y+13,1)
  rectfill(69,y-5,86,y+12,12)
  pal(13,12)
  pal(6,12)
  spr(34,70,y-3,2,2)
  pal()
 end

end

function ssprt(sx,sy,sw,sh,dx,dy,dw,dh,tf)
 for y=0,sh-1 do
  sspr(sx,sy+y,sw,1,dx+(dw-y*tf),dy+y,dw,1)
 end
end

function bp()
 if (btnp(❎)) return true
 if (btnp(🅾️)) return true
end

function sign(x)
 if (x<0) return -1
 if (x>0) return 1
 return 0
end

function indexof(str,c) 
 for i=1,#str do
  if (sub(str,i,i)==" ") return i
 end
 return 0
end

function printc(str,cx,y,c)
 print(str,cx-#str*2,y,c)
end

function prints(str,x,y,c1,c2)
 print(str,x,y+1,c2)
 print(str,x,y,c1)
end

function printo(str,x,y,c1,c2)
 for i=-1,1 do
  for j=-1,1 do
--   print(str,x+1,y,c2)
--   print(str,x,y+1,c2)
--   print(str,x-1,y,c2)
--   print(str,x,y-1,c2)
 print(str,x+i,y+j,c2)
  end
 end
 print(str,x,y,c1)
end
-->8
--------------------------------
-- title screen
--------------------------------
first=true
function init_title()
 letters={
  {0,12}, --a
  {12,12}, --l
  {24,12}, --p
  {36,6}, --i
  {42,12}, --n
  {54,12}, --e
  {0,12}, --a
  {12,12}, --l
  {24,12}, --p
  {0,12}, --a
  {66,12}, --c
  {0,12}, --a
 }
 
 trees={}
 trails={}
 
 wipe=0
 
 t=-10
 
 music(0)
end

function update_title()
 t+=1
 
 if (bp() and wipe==0) then
  wipe=1
  sfx(61)
  music(4)
 end
 
 if (wipe>0) then
  wipe+=1
  if (wipe>16) swap_state(play_state)
 end
 
 local sprs={2,2,4,34,32,6,8,32,34}
 if (rnd()<0.03) then
  add(trees,{
   x=-16+rnd(32),
   y=128,
   spr=sprs[flr(rnd(#sprs)+1)]
  })
 end
 if (rnd()<0.03) then
  add(trees,{
   x=96+rnd(48),
   y=128,
   spr=sprs[flr(rnd(#sprs)+1)]
  })
 end
 
 for tt in all(trees) do
  tt.y-=1
  if (tt.y<-16) del(trees,tt)
 end
end

function draw_title()
 cls(7)
 
 -- grid
 for x=0,8 do
  for y=0,8 do
   spr(0,x*16-8,y*16-t%16,2,2)
  end
 end
 
 -- trees
 for tt in all(trees) do
  spr(tt.spr,tt.x,tt.y,2,2)
 end 
 
 for tt in all(trails) do
  rect(tt.x,tt.y,tt.x+1,tt.y+1,12)
  tt.y-=1
  if (tt.y<-1) del(trails,tt)
 end
 
 local ay=min(70,t-16)
 local dx=10*sin(t/100)+10*cos(t/80)
 local odx=10*sin((t-1)/100)+10*cos((t-1)/80)
 local ss=max(-1,min(1,2*(dx-odx)))
 if (abs(ss)!=1) ss=0
 spr(66+2*ss,58+dx,ay,2,2) 
 
 add(trails,{
  x=62+dx,
  y=ay+9
 })
 add(trails,{
  x=68+dx,
  y=ay+9
 })
 
 
 
 local lt=min(t*8,128)
 local llt=min((t-6)*8,128)
 
 for y=0.5,19.5 do
  line(lt-128,y+17,96-y/2-128+lt,y+17,13)
  line(lt-128,y+14,96-y/2-128+lt,y+14,12)
  line(32-y/2-lt+128,y+41,127-lt+128,y+41,13)
  line(32-y/2-lt+128,y+38,127-lt+128,y+38,14)
 end
 
 draw_letters(1,6,llt-128+15,16)
 draw_letters(7,12,31-llt+128,40)
 
 local tt=min((t+40)*2,128)
 local tt2=min((t+36)*2,128)
 print("created by @johanpeitz",3,113-tt+129,6)
 print("created by @johanpeitz",3,113-tt+128,13)
 print("audio by @gruber_music",3,120-tt2+129,6)
 print("audio by @gruber_music",3,120-tt2+128,13)

 if (t>0) then
  local c=t%16>4 and 12 or 14
  print("❎ to start ",min(3,t-90),103,c)
 end 
 
 -- best
 local str="best: "..best
 printo(str,128-#str*4-1,min(2,-50+t),7,14)

 -- head
 spr(204,
     max(95,190-t*2)+3.5*cos(t/100),
     99-abs(3*sin(t/100)),
     4,4)
 
 -- exit wipe
 if (wipe>0) then
  for y=0,128,4 do
   rectfill(-256,y,wipe*10-y/4+4,y+3,12)
   rectfill(-256,y,wipe*10-y/4,y+3,10)
  end
 end
 
 -- entry wipe
 if (t<32)then
  rectfill(0,0+(t+10)*8,
   128,128,12)
  rectfill(0,10+(t+10)*8,
   128,128,first and 7 or 10)
 end
end

function draw_letters(a,b,sx,sy)
 local x=0
 
 for j=a,b do
  local l=letters[j]
  for i=0,15 do
   pal(i,1)
  end
  sspro(l[1],96,l[2],16,sx+x,sy)
  pal()
  local dx=l[2]--*sin((t+j*2)/30)
  sspr(l[1],96,l[2],16,sx+x+l[2]/2-dx/2,sy,dx,16)
  x+=l[2]+1
 end
end

function sspro(sx,sy,sw,sh,dx,dy)
 for x=-1,1 do
  for y=-1,1 do
   if (abs(x)!=abs(y)) then
    sspr(sx,sy,sw,sh,dx+x,dy+y)
   end
  end
 end
end


title_state = {
 name = "title",
 init = init_title,
 update = update_title,
 draw = draw_title
}
-->8
--------------------------------
-- wipe screen
--------------------------------

function init_wipe()
 t=-1
end

function update_wipe()
 t+=1

 if (t>14) swap_state(title_state)
end

function draw_wipe()
 for i=0,15 do
  line(0,t*16+i+4,t*16+i+4,0,12)
  line(0,t*16+i,t*16+i,0,10)
 end
end


wipe_state = {
 name = "wipe",
 init = init_wipe,
 update = update_wipe,
 draw = draw_wipe
}
__gfx__
7777777777777776000000b300000000000000000000000000000000000000000000000000000000000082000000000000000000000000000000000000400000
7777777777777777000000b330000000000000066d00000000000000000000000000000000000000000884000000000000000000000000000000000008400000
777777777777777600000bb3330000000000066666d00000000000000000000000000000000000000008880000000000000000000000000000000000e8200000
77777777777777770000bbb3333000000000677666d500000000000000000000000000000000000000ee88400000000000000000000000000000000fe4000000
7777777777777777000bbbbb3b330000000077666ddd00000000000000000000000000000000000000ee00200000000000000000000000000000000e84000000
7777777777777777003bb3bb3bb3000000067766d66d5000006600000006000000006000000000000ee000400000000000000000000000000000008e04000000
7777777777777777003113bb313100000006666d66ddd500066650000000600000060000ff940000080000200000000000000000000000000000008004000000
77777777777777770003113311113000006d66d66ddddd00666d55000000660000660009fff92000000000400000000000000000000000000000000002000000
7777777777777777003b3311111333000066dd666d566d50d6dd5100000060000006000499942000000000400000000000000000000000000000000004000000
777777777777777603bb3b333131331000666666dd566d10ddd51660000600000000600444421000000000040000000000000000000000000000000040000000
77777777777777773bbbbb3b3333131000d66666d516dd106566d66d000000000000000444421110000000040000000000000000000000000000000040000000
77777777777777763bb3bb3bb3b3313006dd666dd515d1100d6dddd6d00000000000004442442100000000040000000000000000000000000000000040000000
77777777777777770313bb1bb1331dd600ddddddd1111156066dd566d50000000000004442244200000000040000000000000000000000000000000040000000
7777777777777776066d11d11111dd6000d666dd515566776006516d516d00000000044421d22460000000020000000000000000000000000000000020000000
77777777777777760066dddddddd66000677776d16660000006667dd6666d00004444421dd66d246000000040000000000000000000000000000000040000000
67777667677767660000666666666000000000067777600006777676776d5600442d62d677677667000f0ef4fefee0f0ef0ff0000f0fe0feef00efee4f0f0000
0000b3000000000000000000000b000012121212121212121212121212121212121212121212121200033320000000000000000000000000000000bb33400000
0000b300000000000000000000bb30002121212121212121212121212121212121212121212121210bb3334000000000000000000000000000033bb333400000
0000b33000000000000000000bb3300012121212121212121212121212121212121212121212121233bb33400000000000000000000000000033bbb333200000
000bbb33000000000000000bbbbb30002121212121212121212121212121212121212121212121210003b3340000000000000000000000000000003334000000
000bbb33b300000000b0003bbb3b3100121212121212121212121212121212121212121212121212000000020000000000000000000000000000000004000000
00bbbbb3bb30000000b30001b33b3310212121212121212121212121212121212121212121212121000000040000000000000000000000000000000004000000
03bb3bb33310000000b3303311333110121212121212121212121212121212121212121212121212000000020000000000000000000000000000000004000000
03113bb3113300000bbb331bb3111100212121212121212121212121212121212121212121212121000000040000000000000000000000000000000002000000
0031133111133100bbbb3b31b3331310121212121212121212121212121212121212121212121212000000040000000000000000000000000000000004000000
03b3311313333310bb3b3311b3b33331212121212121212121212121212121212121212121212121000000004000000000000000000000000000000040000000
3bbbb3333b3133100331113313bb3131121212121212121212121212121212121212121212121212000000004000000000000000000000000000000040000000
3b3bbb3b333111d60bb3b31311bb3116212121212121212121212121212121212121212121212121000000004000000000000000000000000000000040000000
013bb31bb331dd60bb31b331dd111d60121212121212121212121212121212121212121212121212000000004000000000000000000000000000000040000000
66d111d1111dd600631d111d66ddd600212121212121212121212121212121212121212121212121000000002000000000000000000000000000000020000000
066dddddddd66000066dddd606666000121212121212121212121212121212121212121212121212000000004000000000000000000000000000000040000000
00066666666600000066666000000000212121212121212121212121212121212121212121212121000f0efe4efee0f00000000000000000ef00efee4f0f0000
000e00000e0000000000e00000e00000000000e00000e0000000e00000e000000005500000000000000008888800000000000000000000000000080000000000
000fe000ef0000000000fe000ef00000000000fe000ef0000000fe000ef000000005500ee0000500000880000088000000000000000000000000888000800000
000fffffff0000000000fffffff00000000000fffffff0000000fffffff00000000ee00e80005500008800000008800000880000000880000008880008880000
00ef7777ffe00000000ef77777fe000000000eff7777fe00000e1777771e00000058eeeef0005500088800080000880800888000008880008088800000888080
005fdddf11e0000000011fdddf11000000000e11fdddf500000e1fdddf1e000000558eeeff600550088000888000088800088800088800008888000000088880
00f77d777ff00000000f777d777f000000000ff777d77f00000f777d777f0000005eeeeeeffff650888000888000088800008880888000008880000000008880
00ef7777ffe0f000000ef77777fe0000000f0eff7777fe00000ef77777fe0000055eeeeeeeffee50888008888800888800000880880000008888000000088880
000effffee8ee0000000eefffee00000000ee8eeffffe0000000eefffee00000055eeeeeeeff0550888000080000000000000000000000000000000000000000
00008e8e88eef000000008e8e8000000000fee88e8e80000000008e8e80000000550eeeeeeef0055121212121212121200800008000000000000000000088000
0000ef7feee8f50000000ef7fe000000005f8eeef7fe000000008ef7fe80000055000eeeeeef0055212121212121212100000008000080000008800000088000
000ef777fe8f56000000ef777fe000000005f8ef777fe0000008ef777fe800000000000eeef60055121212121212121200000888880080000008800000088000
000fff7fff5560000000fff7fff00000000055fff7fff000005feff7ffef50000000000ee8f00005212121212121212100800088800080000008800008888880
000ffeeeff5600000000ffeeeff00000000005ffeeeff0000055efeeefe5560000eeeeeee6666600121212121212121200800008008888800888888000888800
0005f565f560000000005f505f5000000000005f565f56000005f50005f560006eeeeeee67766666212121212121212100800000000888000088880000088000
00555655560000000000555055500000000000055565556000005550555600007ee666ee77776000121212121212121288888000000080000008800000000000
00556055600000000000656065600000000000005500550000000550556000000767776007700000212121212121212108880008000000000000000000000000
00000000000000000000000012121212121212121212121212121212121212121212121212121212121212121212121200000000088000000008000000000000
00000000000000000000000021212121212121212121212121212121212121212121212121212121212121212121212100000088800800000088000000008000
00000000000000000000000012121212121212121212121212121212121212121212121212121212121212121212121200000808880000000888888000008800
00000000000000000000000021212121212121212121212121212121212121212121212121212121212121212121212100008088888000000888888008888880
00000000000001100000000012121212121212121212121212121212121212121212121212121212121212121212121200008088888000000088000008888880
0000000000011cc11000000021212121212121212121212121212121212121212121212121212121212121212121212100008888888000000008000000008800
00000000011cccccc110000012121212121212121212121212121212121212121212121212121212121212121212121200000888880000000000000000008000
000000011cccccccccc1100021212121212121212121212121212121212121212121212121212121212121212121212100000088800000000000000000000000
0000011cccccccccccccc1000cccc00000cc00000cccc0000cccc0000000cc00ccccc0000cccc000cccccc000cccc0000cccc000121212120000800000000000
00011cccccccccccccc11000cccccc000ccc0000cccccc00cccccc00cc00cc00ccccc000ccccc000cccccc00cccccc00cccccc00212121210088888000080000
011cccccccccccccc1100000cc00cc0000cc0000cc00cc00cc00cc00cc00cc00cc000000cc0000000000cc00cc00cc00cc00cc00121212120008880008888800
1cccccccccccccc110000000cc00cc0000cc0000000ccc00000cc000cccccc00ccccc000ccccc00000cccc000cccc000cccccc00212121210000800000888000
011cccccccccc11000000000cc00cc0000cc000000ccc000000cc000cccccc00cccccc00cccccc0000cccc000cccc0000ccccc00121212120000000000080000
00011cccccc1100000000000cc00cc0000cc00000ccc0000cc00cc000000cc000000cc00cc00cc000000cc00cc00cc000000cc00212121210000000000000000
0000011cc110000000000000cccccc000cccc000cccccc00cccccc000000cc00cccccc00cccccc000000cc00cccccc000ccccc00121212120000000000000000
0000000110000000000000000cccc0000cccc000cccccc000cccc0000000cc00ccccc0000cccc0000000cc000cccc0000cccc000212121210000000000000000
00000000000000000000000000000000000000000000000000000000000000001212121212121212121212121212121212121212121212121212121212121212
00000022000000000000000000000000000000000000000000000000110000002121212121212121212121212121212121212121212121212121212121212121
000002aa200000000000001111000000000001111100000000000001aa1000001212121212121212121212121212121212121212121212121212121212121212
000019aa91000000000013bbbb310000000012888821000000000019aaa100002121212121212121212121212121212121212121212121212121212121212121
00001aaaa10000000003bbbbbbbb100000018888888810000000001aaaa100001212121212121212121212121212121212121212121212121212121212121212
000019aaa1000000001bbbbbb1bb300000028212888881000000001aaa9000002121212121212121212121212121212121212121212121212121212121212121
000001aaa1000000003bb1bbbbbbb10000188888881282000000001aaa1000001212121212121212121212121212121212121212121212121212121212121212
000001aaa100000001bbbbbb3113b30000282112888188100000001aaa1000002121212121212121212121212121212121212121212121212121212121212121
0000019aa100000001bb311111bbb30000281111128888100000001aa9000000121212121212121212121212121212121212121212121212000000000cc00000
0000001aa100000001bbb31111bbb30000282111118882000000001aa1000000212121212121212121212121212121212121212121212121000000ccc00c0000
00000019a1000000001bbbb3111bb100001888821188810000000009a100000012121212121212121212121212121212121212121212121200000c0ccc000000
00000001410000000001bbbbbbbb1000000288888288100000000011100000002121212121212121212121212121212121212121212121210000c0ccccc00000
00000001aa100000000013bbbb3100000000128888210000000001aa100000001212121212121212121212121212121212121212121212120000c0ccccc00000
00000001aa10000000000011110000000000001111000000000001aa100000002121212121212121212121212121212121212121212121210000ccccccc00000
000000001100000000000000000000000000000000000000000000110000000012121212121212121212121212121212121212121212121200000ccccc000000
0000000000000000000000000000000000000000000000000000000000000000212121212121212121212121212121212121212121212121000000ccc0000000
0000000000000f0000000a00121212121212121212121212121212121212121212121212121212121212121212121212121212121212121200000ccccc000000
00000010000fff10000aaa102121212121212121212121212121212121212121212121212121212121212121212121212121212121212121000cc00000cc0000
000011100fffff100aaaaa10121212121212121212121212121212121212121212121212121212121212121212121212121212121212121200cc0000000cc000
00111110001fff10001aaa1021212121212121212121212121212121212121212121212121212121212121212121212121212121212121210ccc000c0000cc0c
0000111000001f1000001a1012121212121212121212121212121212121212121212121212121212121212121212121212121212121212120cc000ccc0000ccc
0000001000000f1000000a102121212121212121212121212121212121212121212121212121212121212121212121212121212121212121ccc000ccc0000ccc
0000001000000f1000000a101212121212121212121212121212121212121212121212121212121212121212121212121212121212121212ccc00ccccc00cccc
0000001000000010000000102121212121212121212121212121212121212121212121212121212121212121212121212121212121212121ccc0000c00000000
00000000000000000000000000000000121212121212121212121212000000c0000cc0000c000000000c00000000c00000000000000cc0000c0000c000ccc000
0000700000000000000000000000000021212121212121212121212100000ccc000cc000ccc0000000cc00000000cc00c000000c000cc000ccc00ccc0ccccc00
0007c700000000000077700000000000121212121212121212121212c000ccc0000cc0000ccc000c0ccc00000000ccc0cc0000cc0cccccc00cccccc00c000c00
007ccc70111111000707070000000000212121212121212121212121cc0ccc00000cc00000ccc0ccccccccccccccccccccc00ccc00cccc0000cccc00cc000cc0
07ccc700177171100777770000000000121212121212121212121212ccccc000cccccccc000ccccccccccccccccccccc0cc00cc0000cc00000cccc00c00000c0
007c7000171717100070700000000000212121212121212121212121cccc00000cccccc00000cccc0ccc00000000ccc000c00c000cccccc00cccccc0c0cc00c0
00070000171717100000000000000000121212121212121212121212ccccc00000cccc00000ccccc00cc00000000cc000000000000cccc00ccc00cccc0cc0ccc
00000000111111100000000000000000212121212121212121212121cccccc00000cc00000cccccc000c00000000c00000000000000cc0000c0000c0c0cc00c0
00009aa9000000099000000000009aa900009aa90000099009a90000009aa9000000009aa9000000121212121212121200000000000000000000000000000000
009aa7aaa900009aa9000000009aa7aaa900a77a00009aa90a7a00009aa7aaa900009aa7aaa90000212121212121212100000000000000000000000000000000
09a77aaaaa9009a7a900000009a77aaaaa90a77a9009a7aa09aa9009a77aaaaa9009a77aaaaa900012121212121212120000000ee00000000000000000000000
0a77a99aaaa00a7aa00000000a77a99aaaa09a7aa00a7aaa00aaa00a77a999aaa00a77a999aaa0002121212121212121000000effe00000000000000ee000000
0a7a9009aaa0977a900000000a7a9009aaa90aaaa9977aaa90aaa90a7a90009aa90a7a90009aa9001212121212121212000000efffeeeeeee00000eeffe00000
97aa0000aaa9a7aa0000000097aa0000aaaa0a7aaaa7a9aaa0aaaa97aa00000aaa97aa00000aaa002121212121212121000000effeffffffeee0eefffee00000
a7a900009aaaaaa900000000aaa900009aaa09aaaaaaa0aaa0aaaaaaa900000a7aaaa900000a7a001212121212121212000000eeeeffffffffeefffeeee00000
aaa000000aaaa7a000000000a7a000000aaa09aaaaa7a09aa9aaaaa7a0000009a9a7a0000009a900212121212121212100000eefffeeeeefffffffffeee00000
a7a0000007aaaaa000000000aaa0000007aa0aaaaaaaa00aaa7aaaaaa000000000aaa0000000000012121212121212120000effffffffffffffffffffee00000
aaa0000007aaaaa000000000aaa9000097a90aaaaaaaa909aaaaaaaaa000000000aaa000000000002121212121212121000ef77777777777777ffffffeee0000
aaaaaaa77aaaaaa900000000aaaaaaa77a900aaaaaaaaa00aaaaaaaaaaaa900000aaa900000000001212121212121212000e77777777777777777fffffee0000
9aaa0000aaa99aaa90009a909aaa000000009a7aa99aaa009aaaa99aaa00009a909aaa90009a9000212121212121212100e65d7dddddd6777755d7ffffeee000
4aaa9009aaa44aaaaaaaa7a44aaa900000009aaaa44aaa909aaaa44aaaaaaaa7a44aaaaaaaa7a400121212121212121200e777777d777777777777fffffee000
299990099992299aaaaaaa92299990000000499992299990499992299aaaaaaa92299aaaaaaa920021212121212121210ef7776776777776777777fffffee000
0499400999400499999999400499400000002499400499400499400499999999400499999999400012121212121212120eff77766666666777777ffffffee000
0244200244200244444444200244200000000244200244200244200244444444200244444444200021212121212121210eff7777777777777777fffffffee000
09a90009a90009aaaa90000000009aa9000009a900009a9009aaaaaa99000000121212121212121212121212121212120efff7777777777777fffffffffee000
0aaa000a7a009a777aaa9000009aa7aaa9000aaa9009aaa09a777a7aaa900000212121212121212121212121212121210efffff77777777fffffffffffeee000
9a7a0009aa90a77aaaaaa90009a77aaaaa909aaa9009aaa9a77aaaaaaaa900001212121212121212121212121212121200efffffffffffffffffffffffee0000
a7aa0000aaa0a7a909aaaa000a77a99aaaa09aaa0000aaa99aaaaaaaaaaa00002121212121212121212121212121212100effffffffffffffffffffffeee0000
a7a90000aaa9aaa0009aaa900a7a9009aaa0aaa900009aaa0099aaaaaaa9000012121212121212121212121212121212000efffffffffffffffffeffeeee0000
a7a000009aaaa7a00009aaa097aa0000aaa9aaa900009aaa0000aaaaa9900000212121212121212121212121212121210000effffffffffffffeeefffee00000
aaa000900aaaaaa00000aaa9aaa900009aaaaaa000000aaa00009aaa900000001212121212121212121212121212121200000eefffffffffeeeeeffffee00000
aaa9097007aaa7a00000aaaaa7a000000aaaaaa000000aaa00009aaa900000002121212121212121212121212121212100000efeeeeeeeeeeeeffffffee00000
aaaa97a907aaaaa00000aaaaaaa000000aaaaaa000000aaa0000aaaa9000000012121212121212121212121212121212000000efeeeeeeeeefffffeffee00000
aaaaaaaa97aaaaa00000a7aaaaa0000007aaaaa0000007aa0009aaaa4000000021212121212121212121212121212121000000effffffffffffffffeeee00000
aaaaaaa77aaaaaa00000a7a9aaa9000097aaaaa9000097aa0009a7aa0000000012121212121212121212121212121212000000effefffeffefffffffeee00000
9aaaaaaaaaa9aaa900097aa49aaa90097aa99aaa90097aa90009a7aa00000000212121212121212121212121212121210000000eefeeefeeffffffffeeee0000
4aaaa09aaaa49aaaaaa7aa904aaaaa77aaa44aaaaa77aaa40009aaa900000000121212121212121212121212121212120000000efffffffffffffeffeeee0000
29999049999249aaaaaaa940299aaaaaa992299aaaaaa9920000999900000000212121212121212121212121212121210000000effffffffffffffeeeeee0000
0499400499402499999994200499999999400499999999400000499400000000121212121212121212121212121212120000000efffffffffffffffeeeeee000
0244200244200244444442000244444444200244444444200000244200000000212121212121212121212121212121210000000effffffffffffffeeeeeeee00
__gff__
0000000000000000000008000800080000000000000000000000000000000000000000000000000000000800000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010800001877000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001874000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01ff00001872418731187411875118761187711877118704007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
010600011804000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0000288142b92428814269242481426924288142b92428814269242481426924288142b92428814269242481426924288142b92428814269242481426924288142b92428924268142492426814288142b924
010c0000057400573005722057120c7300c710107301073510722107150c7300c7300c7200c710057400573005720057100c7300c71010730107200574005730057100571005710057120c7300c7151073010720
010c0000268141c8141f8141c8141a81418814268141c8141f8141c8141a81418814268141c8141f8141c8141a81418814268141c8141f8141c8141a81418814268141c8141f8141c8141a81418814268141c814
010c00000c543000000c5431f8141c8141a814188141a814186151f8141c8141a814188141a8140c5430000000000000000c543268141c8141f8141c8141a81418615268141c8141f8141c8141a8141881426814
010c00000074000730007220071500740007200e7300e7300e7200e71007730077300772007710007400073000720007100074500735007400072010730107300e7200e7120e712077100e7300e7150773007720
010c0000268141c8141f8141c8141a814188142f9141c8141f8141c8142f91418814268141c8141f8141c8141a81418814268142f9141f8141c8141a81418814268142f9141f8141c8141a814188142f91426814
010800200c8250e8251082513825188251a8251c8251f8252482526825288252b8253082532825348253782534805378053480537805008050080500805008050080500805008050080500805008050080500805
0108002000900009000c9250e9251092513925189251a9251c9251f9252492526925289252b925309253292534905379050090000900009000090000900009000090000900009000090000900009000090000900
0105000006600086010a6010c6010f60113601176011a6011e6012260125601286012a60129601296012760124605206001c6011860114601116010d6010b6010960108601076010660105601046010360101600
010e00000173001721017110d81501025007000a7300a7210a7110a815160150a0150873008721087111481508015087000573005721057110591511815059150673006721067111281506815129150873008721
010e00000c5030000000000000001d816209171d81620916186050000000000000001d800209001d000200000c50300000000000000000000000000000000000186050000000000000001e816209171e81620916
010e00000c5331da141da211da311da411da521da621da72186151da141da211da311da411da521da621da720c5331da141da211da311da411da521da621da72186151ea141ea211ea311ea411ea521ea621ea72
010e000000a0020a1420a2120a3120a4120a5220a6220a7200a0020a1420a2120a3120a4120a5220a6220a7200a0020a1420a2120a3120a4120a5220a6220a7200a0020a1420a2120a3120a4120a5220a6220a72
010e00000673006721067111281506025007000f7300f7210f7110f8151b0150f0150d7300d7210d711198150d015087001173011721117111191505815119150f7300f7210f7111b8150d7300d7210d71119815
010e00000c50300000000000000020816229172081622916186050000000000000001d800209001d000200000c503000000000000000000000000000000000001860500000000000000020816229172081622916
010e00000c5331da141da211da311da411da521da621da72186151da141da211da311da411da521da621da720c53322a1422a2122a3122a4122a5222a6222a72186151ea141ea211ea311ea411ea521ea621ea72
010e000000a0022a1422a2122a3122a4122a5222a6222a7200a0025a1425a2125a3125a4125a5225a6225a7201a0027a1427a2127a3127a4127a5227a6227a7200a0022a1422a2122a3122a4122a5222a6222a72
010e00000c53329a1429a2129a3129a4129a5229a6229a72186151da141da211da311da411da521da621da720c53322a1422a2122a3122a4122a5222a6222a72186151ea141ea211ea311ea411ea521ea621ea72
010e000000a0025a1425a2125a3125a4125a5225a6225a7200a0025a1425a2125a3125a4125a5225a6225a7201a0027a1427a2127a3127a4127a5227a6227a7200a0022a1422a2122a3122a4122a5222a6222a72
010e00000c50300000297202c72525720257222772029720297251d0252c7002e7202c7202c7202c7222c7222c725140052a7242a72029721297202071720720207202072220722207221e7201e7202572225722
010e000030725317252c7242c7202c7222c7222c722297201d9151d0002a7252a72529720277202572025722257222582519815198052272022720227222772029721297202a720297252c7202a7202972520725
010e00002c7202c7202c7202c7202c7112c7122c71229711297202972029720297222971129712297122971225720257202572225722257112571225712257122072022721227222272222711227122271222712
010e000030725317252c7242c7202c7222c7222c722297202a7252c72525724257202572225722257222272022725227052e8052e8052272022722227252972029722297252a725297252c725227252572529725
010e0000207202072020722207151d816209171d816209162a7052c70525704257002570225702257022270022705227052e8052e8052270022702227052970029702297052a705297051d816209171d81620916
010e00000000020a1420a2120a3120a4120a5220a6216b1514b1516b2519b151bb251db1520b250cb001bb100f0051bb121bb1519b101bb121bb151bb001bb101db1020b1519b100db121bb101db101d7171db15
010e00002cb1529b1529b101d01524b1525b1520b1020b1220b1220b1222b1522b1520b101eb101db101db121db121db1519b0516b1514b1516b1519b151db1520b1020b1214b1520b1025b1019b1525b1525b15
010e000027b1027b1020b1525b1025b1025b121db111db101db101db1220b251bb101bb121bb121bb1500b0000b0016b1514b1516b151db101db121db1525b1025b1225b1527b1525b1529b151eb1722b1525b15
010e000029b1029b1029b1229b1225b1125b1025b1025b1025b1025b1025b1225b1220b1120b1020b1020b1020b1020b1220b1220b121db111db101db101db101db101eb111eb101eb101eb121eb121eb121eb12
010e00000373003721037110f81503025087150a7250d7350f7300f721038150f020030150d7150a7250873505730057211181505025000000f7150d725147351173011721117110581511025020000581500000
010e0000207302072020711207122cb011ea701ea721ea72227302272022711227122eb011ea701ea721ea722573025720257112571231b0120a7020a7220a722973029720297112971235b0120a7020a7220a72
010e000019b1019b1019b1119b1522b0022b2520b151eb251db1520b2525b1025b1225b1529b2527b1525b252ab1529b2527b1027b1227b122ab2529b1527b252ab1529b252771525b2529b17277252571522725
010e00000c53325a1425a2125a3125a4125a5225a620c533186150c53325a6025a600c53325a6025a6025a620c53325a6025a6025a6025a6025a6225a6225a621861525a6025a6025a6025a6025a600c5130c523
010e000006730067210671112815060250d7150f7251173512730127210681512020060150d7150a7250873504730047211081504025140150b7150d7250f73510730107211071104815100250f0150481514015
010e000019b1019b1019b1119b1522b0022b2520b151eb251db1520b2525b1025b1225b1529b2527b1525b252cb152eb2525b1025b1225b1525b2527b1523b2525b152ab2528b1527b2528b152cb1531b1533b15
010e0000207302072020711207122cb011ea701ea721ea72227302272022711227122eb011ea701ea721ea722573025720257112571231b0120a7020a7220a722c7302c7202c7112c71238b0120a7020a7220a72
010e0000317303172031711317123fb011ea701ea721ea722c7302c7202c7112c7123ab011ea701ea721ea72297302972029711297123db0120a7020a7220a722773027720277112771238b0120a7020a7220a72
010e00002ab102ab122ab122ab1522b0035b2533b1531b252eb152cb2529b1027b2225b152cb252ab1527b2529b152ab2531b1031b1231b1231b1535b1533b1536b1036b1236b1236b1235b1135b1035b1238b11
010e000006730067210671112815060250d7150f7251173512730127210681512020060150d7150a72508735087300872114815080251481008720087150f70514730147211471108815147300e7210871104711
010e00000173001721017110171101712017150c5130c5230000001a7001a7101a7101a710d7250d7250d7250000001a7001a7101a7101a710d72501a720d7250900008a1408a2108a3108a4108a520872508725
010e00002c7102c7122c7122c7151d816209171d81620916000000c52300000000000c52300000000000c52322705227052e8052e8052270022702227050c52329702297052a705297051d816209171d81620916
010e00000500006a7006a711272506a7106a7206725067250500006a7006a7106a7106a7106a72127251272508020087151273012721127111291506815129151173011721117111d81508730087210572102711
010e00003871038710387103871038711387123871235711357103571035710357123571135712357123571231710317103171031710317113171231712317122c7102e7112e7102e7102e7112e7122e7122e712
010c00000c543000000c5431f8041c8041a804188041a804186151f8041c8041a804188041a8040c5430000000000000000c543268041c8041f8041c8041a80418615268041c8041f8041c8041a8041880426804
000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00000a024107311404119751197552462017621116110c61108611056151100015001220011d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000052670061710267006171236700617123570161712357016170a157006170d147006170d147006170b047006170b037006170a037006170a727006170b727006170c717006170b117006170811700617
010d002000000000002875025751227511f7411d7411a74118731157311473112721107210e7210c7210a71107711057110471103711027110171100000000010000100001000000000000000000000000000000
010c002000000000002b75027751257512374121741207411d7311b73119731177211572113721117210f7110d7110a7110771105711047110371100000000010000100001000010000100001000010000100000
010800001c7741a5741807413774185641a0641c7641f5642405426754280542b544307443204434534377343c0243e5041c50400004000040000400004000040000400004000040000400004000040000400004
010a00001f5502854524535265252b5302b5222b51500500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000000000000
012800000c3633060014601146050f600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01050000150552155515055215551a055265551a055265551e0552a5551e0552a5550000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
010a0000144330c3111233118301223011a0001b7011a00116701120010f7010b0010000000001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
01030000180251f535260452a55512604176011b6011f601226012560128601296012b601296012760124601216011f6011c601186011560113601116010f6010e60500500005000050000500005000050000500
01030000180251f535260452a55512614176111b6111f611226112561128611296112b611296112761124611216111f6111c611186111561113611116110f6110e61500500005000050000500005000050000500
010200002151526525005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
__music__
01 08090a0b
00 08090a0b
00 080c0d0b
02 080c0d0b
00 0e0f104b
01 12141311
00 12141311
00 16181715
00 161a1915
00 14131b11
00 14131c11
00 18171e15
00 1a191d15
00 14131f11
00 12141311
00 16181715
00 161a1915
00 13201b11
00 13211c11
00 17221e15
00 19231d15
00 27262524
00 27292a28
00 272c2b24
00 2723312d
00 14132f2e
02 1a191630
00 36373344
01 09324a4b
00 09324a4b
00 0c324d4b
02 0c324d4b
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
777777767777777777777776777777777777777677777777777777767777777777cc7776cc777777777777767777777777777776777777777777777677777777
777777777777777777777777777777777777777777777777777777777777777777cc7777cc77777777777777777777eeeeeeeeeeeeeeeee7777777eeeeeeeee7
7777777677777777777777767777777777777776777777777777777677777777777cc7767cc7777777777776777777e777e777ee77e777eeee7777e777e777e7
7777777777777777777777777777777777777777777777777777777777777777777cc7777cc7777777777777777777e7e7e7eee7eeee7eee7e7777eee7e7e7e7
777777777777777777777777777777777777777777777777777777777777777777777cc7777cc77777777777777777e77ee77ee777ee7e7eee77777e77e777e7
777777777777777777777777777777777777777777777777777777777777777777777cc7777cc77777777777777777e7e7e7eeeee7ee7e7e7e7777eee7e7e7e7
7777777777777777777777777777777777777777777777777777777777777777777777cc7777cc7777777777777777e777e777e77eee7e7eee7777e777e777e7
7777777777777777777777777777777777777777777777777777777777777777777777cc7777cc7777777777777777eeeeeeeeeeee7eee77777777eeeeeeeee7
77777777777777777777777777777777777777777777777777777777777777777777777cc7777cc7777777777777777777777777777777777777777777777777
77777776777777777777777677777777777777767777777777777776777777777777777cc7777cc7777777767777777777777776777777777777777677777777
777777777777777777777777777777777777777777777777777777777777777777777777cc7777cc777777777777777777777777777777777777777777777777
777777767777777777777776777777777777777677777777777777767777777777777776cc7777cc777777767777777777777776777777777777777677777777
7777777777777777777777777777777777777777777777777777777777777777777777777cc7777cc77777777777777777777777777777777777777777777777
7777777677777777777777767777777777777776777777777777777677777777777777767cc7777cc77777767777777777777776777777777777777677777777
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777776777777777777777677777777
ccccccccccccccccccc1111cccccccc11cccccccccccc1111ccccc1111cccccc11cc111ccccccc1111cccccccccccccc77766766677676677776676667767667
ccccccccccccccccc119aa911ccccc1991ccccccccc119aa911cc19aa91cccc199119a91cccc119aa911ccccccccccc777777776777777777777777677777777
cccccccccccccccc19aa7aaa91ccc19aa91ccccccc19aa7aaa91c1a77a1ccc19aa91a7a1ccc19aa7aaa91ccccccccccd77777777777777777777777777777777
ccccccccccccccc19a77aaaaa91c19a7a91cccccc19a77aaaaa911a77a91c19a7aa19aa91c19a77aaaaa91ccccccccdd77777776777777777777777677777777
ccccccccccccccc1a77a99aaaa1c1a7aa1ccccccc1a77a99aaaa119a7aa1c1a7aaa11aaa1c1a77a999aaa1ccccccccd777777777777777777777777777777777
ccccccccccccccc1a7a9119aaa11977a91ccccccc1a7a9119aaa911aaaa91977aaa91aaa911a7a91119aa91ccccccdd777777777777777777777777777777777
cccccccccccccc197aa1cc1aaa91a7aa1ccccccc197aa1cc1aaaa11a7aaa1a7a9aaa1aaaa197aa1ccc1aaa1ccccccd7777777777777777777777777777777777
cccccccccccccc1a7a91cc19aaa1aaa91ccccccc1aaa91cc19aaa119aaaa1aaa1aaa1aaaa1aaa91ccc1a7a1cccccdd7777777777777777777777777777777777
cccccccccccccc1aaa1cccc1aaa1a7a1cccccccc1a7a1cccc1aaa119aaaa1a7a19aa9aaaa1a7a1cccc19a91cccccd77777777777777777777777777777777777
cccccccccccccc1a7a1cccc17aa1aaa1cccccccc1aaa1cccc17aa11aaaaa1aaa11aaa7aaa1aaa1ccccc111cccccdd77777777777777777777777777777777777
cccccccccccccc1aaa1111117aa1aaa1cccccccc1aaa9111197a911aaaaa1aaa919aaaaaa1aaa1111ccccccccccd777777777776777777777777777677777777
cccccccccccccc1aaaaaaa77aaa1aaa91ccc111c1aaaaaaa77a91c1aaaaa1aaaa11aaaaaa1aaaaaa91111cccccdd777777777777777777777777777777777777
cccccccccccccc19aaa1111aaa919aaa91119a9119aaa1111111c19a7aa919aaa119aaaa919aaa11119a91ccccd7777777777776777777777777777677777777
cccccccccccccc14aaa9119aaa414aaaaaaaa7a414aaa91cccccc19aaaa414aaa919aaaa414aaaaaaaa7a41ccdd7777777777777777777777777777777777777
cccccccccccccc12999911999921299aaaaaaa921299991cccccc149999212999914999921299aaaaaaa921ccd77777777777776777777777777777677777777
ccccccccccccccc149941199941c149999999941c149941cccccc1249941c149941149941c149999999941ccdd77777777777776777777777777777677777777
ccccccccccccccc124421124421c124444444421c124421ccccccc124421c124421124421c124444444421ccd77676677776676666d676677776676667767667
cccccccccccccccc1111cc1111ccc1111111111ccc1111ccccccccc1111ccc1111cc1111ccc1111111111ccdd777777777777776666d77777777777677777777
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccdc77777777777777666ddd7777777777777777777
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddc7777777777777766ddd57777777777677777777
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddcc77777777777777d6dd566777777777777777777
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddcc777777777777777b66d66d77777777777777777
777777777777777777337333b37377777777777777777777777777777777777777777777777777777cc7777cc777777777777777b6dddd667777777777777777
7777777777777777777733b33377777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
77777777777777777733bbb33337777eeee1111eeeeeeee11eeeeeeeeeeee1111eeeeeeeee1111eeeeeeeee1111eeeeeeeee1111eeeeeeeeeeeeeeeeeeeeeeee
777777777777777733bbbbbb33b377eee119aa911eeeee1991eeeeeeeee119aa911eeeee119aa911eeeee119aa911eeeee119aa911eeeeeeeeeeeeeeeeeeeeee
77777776777777733bb3bbbbb3b333ee19aa7aaa91eee19aa91eeeeeee19aa7aaa91eee19aa7aaa91eee19aa7aaa91eee19aa7aaa91eeeeeeeeeeeeeeeeeeeee
77777777777777777333bbb3b3333ee19a77aaaaa91e19a7a91eeeeee19a77aaaaa91e19a77aaaaa91e19a77aaaaa91e19a77aaaaa91eeeeeeeeeeeeeeeeeeee
7777777677777773333bb33333373ee1a77a99aaaa1e1a7aa1eeeeeee1a77a99aaaa1e1a77a99aaaa1e1a77a999aaa1e1a77a99aaaa1eeeeeeeeeeeeeeeeeeee
7777777777777777377333377337eee1a7a9119aaa11977a91eeeeeee1a7a9119aaa911a7a9119aaa1e1a7a91119aa911a7a9119aaa1eeeeeeeeeeeeeeeeeeee
7777777677777777777777767777ee197aa1ee1aaa91a7aa1eeeeeee197aa1ee1aaaa197aa1ee1aaa9197aa1eee1aaa197aa1ee1aaa91eeeeeeeeeeeeeeeeeee
777777767777777777777776777eee1a7a91ee19aaa1aaa91eeeeeee1aaa91ee19aaa1a7a91ee19aaa1aaa91eee1a7a1a7a91ee19aaa1eeeeeeeeeeeeeeeeeee
777667666776766777766766677eee1aaa1eeee1aaa1a7a1eeeeeeee1a7a1eeee1aaa1aaa1eeee1aaa1a7a1eeee19a91aaa1eeee1aaa1eeeeeeeeeeeeeeeeeee
77777776777777777777777677eeee1a7a1eeee17aa1aaa1eeeeeeee1aaa1eeee17aa1a7a1eeee17aa1aaa1eeeee1111a7a1eeee17aa1eeeeeeeeeeeeeeeeeee
77777777777777777777777777eeee1aaa1111117aa1aaa1eeeeeeee1aaa9111197a91aaa1111117aa1aaa1eeeeeeee1aaa1111117aa1eeeeeeeeeeeeeeeeeee
7777777677777777777777767eeeee1aaaaaaa77aaa1aaa91eee111e1aaaaaaa77a911aaaaaaa77aaa1aaa91eee111e1aaaaaaa77aaa1eeeeeeeeeeeeeeeeeee
7777777777777777777777777eeeee19aaa1111aaa919aaa91119a9119aaa1111111e19aaa1111aaa919aaa91119a9119aaa1111aaa91eeeeeeeeeeeeeeeeeee
777777777777777777777777eeeeee14aaa9119aaa414aaaaaaaa7a414aaa91eeeeee14aaa9119aaa414aaaaaaaa7a414aaa9119aaa41eeeeeeeeeeeeeeeeeee
77777b777777777777777777eeeeee12999911999921299aaaaaaa921299991eeeeee12999911999921299aaaaaaa9212999911999921eeeeeeeeeeeeeeeeeee
77777b77777777777777777eeeeeeee149941199941e149999999941e149941eeeeeee149941199941e149999999941e149941199941eeeeeeeeeeeeeeeeeeee
77777b37777777777777777eeeeeeee124421124421e124444444421e124421eeeeeee124421124421e124444444421e124421124421eeeeeeeeeeeeeeeeeeee
7777bb3777777777777777eeeeeeeeee1111ee1111eee1111111111eee1111eeeeeeeee1111ee1111eee1111111111eee1111ee1111eeeeeeeeeeeeeeeeeeeee
7777bb3377777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
777bbbbb377777777777777ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
7bbbbbb333777777777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
333bb3b333337777777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
73733333733377777777777677777777777777767777777777777776777777777777777ccc777ccc777777767777777777777776777777777777777677777777
7773b3333bb37777777777767777777777777776777777777777777677777777777777ccc777ccc7777777767777777777777776777777777777777677777777
773bbb33bb3336677776676667767667777667666776766777766766677676677776cccc67cccc67777667666776766777766766677676677776676667767667
73bbbbb33bb33777777777767777777777777776777777777777777677777777777ccc767ccc7777777777767777777777777776777777777777777677777777
3b3bb3bbbb33337777777777777777777777777777777777777777777777777777ccc777ccc77777777777777777777777777777777777777777777777777777
3b3333b333337377777777767777777777777776777777777777777677777777cccc77cccc777777777777767777777777777776777777777777777677777777
bbb3333bb333337777777777777777777777777777777777777777777777777ccc777ccc77777777777777777777777777777777777777777777777777777777
7bb33bbb33b337777777777777777777777777777777777777777777777777ccc777ccc777777777777777777777777777777777777777777777777777777777
b3b3bbbbb3bb337777777777777777777777777777777777777777777777cccc77cccc7777777777777777777777777777777777777777777777777777777777
3bb333bb333b7777777777777777777777777777777777e77777e777777ccc777ccc777777777777777777777777777777777777777777777777777777777777
7b33bbb333333777777777777777777777777777777777fe777ef7777cccc77cccc7777777777777777777777777777777777777777777777777777777777777
7bb3333333333377777777777777777777777777777777fffffff777ccc777ccc777777777777777777777777777777777777777777777777777777777777777
b33333333377337777777776777777777777777677777ef7777ffe7ccc777ccc7777777677777777777777767777777777777776777777777777777677777777
3333337733377777777777777777777777777777777775f111f11eccc77cccc77777777777777777777777777777777777777777777777777777777777777777
777777767777777777777776777777777777777677777f771777ffc677ccc7777777777677777777777777767777777777777776777777777777777677777777
777777777777777777777777777777777777777777777ef7777ffe7f7ccc77777777777777777777777777777777777777777777777777777777777777777777
7777777677777777777777767777777777777776777777eeeeeee8eeccc777777777777677777777777777767777777777777776777777777777777677777777
777777767777777777777776777777777777777677777778e8e88eefcc7777777777777677777777777777767777777777777776777777777777777677777777
77766766677676677776676667767667777667666776766efffeee8f577676677776676667767667777667666776766777766766677676677776676667767667
7777777677777777777777767777777777777776777777efffffe8f5777777777777777677777777777777767777777777777776777777777777777677777777
7777777777777777777777777777777777777777777777fffffff557777777777777777777777777777777777777777777777777777777777777777777777777
7777777677777777777777767777777777777776777777ffeeeff576777777777777777677777777777777767777777777777776777777777777777677777777
77777777777777777777777777777777777777777777775f575f5777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777755575557777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777755775577777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777776777777777777777677777777777777767777777777777776777777777777777677777777777777767777777777777776777777777777777677777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777776777777777777777677777777777777767777777777777776777777777777777677777777777777767777777777777776777777777777777677777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777776777777777777777677777777777777767777777777777776777777777777777677777777777777767777777777777776777777777777777677777777
77777776777777777777777677777777777777767777777777777776777777777777777677777777777777767777777777777776777777777777777677777777
77766766677676677776676667767667777667666776766777766766677676677776676667767667777667666776766777766766677676677776676667767667
77777776777777777777777677777777777777767777777777777776777777777777777677777777777777767777777777777776777777777777777677777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777776777777777777777677777777777777767777777777777776777777777777777677777777777777767777777777777776ee7777777777777677777777
7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777effe77777777777777ee77777
7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777efffeeeeeee77777eeffe7777
7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777effeffffffeee7eefffee7777
7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777eeeeffffffffeefffeeee7777
7777eeeee777777eee77ee777777ee7eee7eee7eee7eee77777777777777777777777777777777777777777777777777777777eefffeeeeefffffffffeee7777
777ee7e7ee777777e77e7e77777e7777e77e7e7e7e77e77777777777777777777777777777777777777777777777777777777effffffffffffffffffffee7777
777eee7eee777777e77e7e76777eee77e77eee7ee777e7777777777677777777777777767777777777777776777777777777ef77777777777777ffffffeee777
777ee7e7ee777777e77e7e7777777e77e77e7e7e7e77e7777777777777777777777777777777777777777777777777777777e77777777777777777fffffee777
7777eeeee7777777e77ee776777ee777e77e7e7e7e77e777777777767777777777777776777777777777777677777777777e65d7dddddd6777755d7ffffeee77
777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777e777777d777777777777fffffee77
77777776777777777777777677777777777777767777777777777776777777777777777677777777777777767777777777ef7776776777776777777fffffee77
37777776777777777777777677777777777777767777777777777776777777777777777677777777777777767777777777eff77766666666777777ffffffee77
77766766677676677776676667767667777667666776766777766766677676677776676667767667777667666776766777eff7777777777777777fffffffee67
77777776777777777777777677777777777777767777777777777776777777777777777677777777777777767777777777efff7777777777777fffffffffee77
7777dd7ddd7ddd7ddd7ddd7ddd7dd777777ddd7d7d777777d77ddd77dd7d7d7ddd7dd77ddd7ddd7ddd7ddd7ddd77777777efffff77777777fffffffffffeee77
777d667d6d7d667d6d76d67d667d6d77777d6d7d7d77777d6d76d67d6d7d7d7d6d7d6d7d6d7d6676d676d6766d777777777efffffffffffffffffffffffee777
337d777dd67dd77ddd77d77dd77d7d77777dd67ddd77777d7d77d77d7d7ddd7ddd7d7d7ddd7dd777d777d777d6777777777effffffffffffffffffffffeee777
377d777d6d7d677d6d77d77d677d7d77777d6d766d77777d7677d77d7d7d6d7d6d7d7d7d667d6777d777d77d677777777777efffffffffffffffffeffeeee777
3376dd7d7d7ddd7d7d77d77ddd7ddd77777ddd7ddd777776dd7dd77dd67d7d7d7d7d7d7d777ddd7ddd77d77ddd77777777777effffffffffffffeeefffee7777
777766767676667676776776667666777776667666777777667667766776767676767676777666766677677666777777777777eefffffffffeeeeeffffee7777
777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777efeeeeeeeeeeeeffffffee7777
777ddd7d7d7dd77ddd77dd77777ddd7d7d777777d777dd7ddd7d7d7ddd7ddd7ddd77777ddd7d7d77dd7ddd77dd7777777777777efeeeeeeeeefffffeffee7777
777d6d7d7d7d6d76d67d6d76777d6d7d7d77777d6d7d667d6d7d7d7d6d7d667d6d77777ddd7d7d7d6676d67d667777777777777effffffffffffffffeeee7777
777ddd7d7d7d7d77d77d7d77777dd67ddd77777d7d7d777dd67d7d7dd67dd77dd677777d6d7d7d7ddd77d77d777777777777777effefffeffefffffffeee7777
777d6d7d7d7d7d77d77d7d76777d6d766d77777d767d7d7d6d7d7d7d6d7d677d6d77777d7d7d7d766d77d77d7777777777777776eefeeefeeffffffffeeee777
777d7d76dd7ddd7ddd7dd677777ddd7ddd777776dd7ddd7d7d76dd7ddd7ddd7d7d7ddd7d7d76dd7dd67ddd76dd77777777777777efffffffffffffeffeeee777
77767676667666766676677677766676667777766676667676776676667666767676667676776676677666766677777777777776effffffffffffffeeeeee777
77777776777777777777777677777777777777767777777777777776777777777777777677777777777777767777777777777776efffffffffffffffeeeeee77
77766766677676677776676667767667777667666776766777766766677676677776676667767667777667666776766777766766effffffffffffffeeeeeeee7
