pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
 -- villager
 -- by partnano
 
 -- [ main / utils ] --

function _init()
	t=0
	sfx_timer=300
	init_intro()
end

function _update60()
	t+=1
	sfx_timer+=1
	
	upd_afters()
	upd_intervals()
	
	if sfx_timer>500+rnd(300) then
		sfx(rnd({12,12,12,11}))
		sfx_timer=0
	end
	
	update()
end

function _draw()
	draw()
end

function gp_init()
	init_particles()
	gen_world()

	init_gp()
	init_buildings()
	init_plr()
	init_ui()
	init_peeple()
	
	debug={}
end

function gp_update60()
	debug={}
	
	update_world()
	update_gp()
	update_plr()
	update_peeple()
	update_particles()
	update_ui()
end

function gp_draw()
	cls(11)
	map()
	
	draw_world()
	draw_particles()
	draw_ui()

	draw_brd(cx,cy)

--	add(debug,stat(1))
--	draw_debug()
end

-- [ debug (remove when done) ] --
function draw_debug()
	for i=1,#debug do
		print(debug[i],cx+2,cy-4+i*6,7)
	end
end

-- [ utils ] --

-- draws the window border
function draw_brd(x,y)
	line(x,y,x+127,y,4)
	line(x,y,x,y+127,4)
	line(x+127,y,x+127,y+127,4)
end

-- draws a rect with border
-- fc = fillcolor
-- bc = bordercolor
function brd_rect(x,y,w,h,fc,bc)
	rectfill(x,y,x+w-1,y+h-1,bc or fc)
	rectfill(x+1,y+1,x+w-2,y+h-2,fc)
end

-- returns a value to be used for worldgen
-- lower on the map's edges,
-- higher in the middle
-- r = difference to .75 (= 0) of sin
-- => how low the value can go
function sin_prob(x,r)
	local base=0.75-r
	return
		sin(base+(r*2/ww)*(x+1))
end

-- tilizes pixel coordinates
function tlz(x,y)
	return x\8,y\8
end

function utlz(x,y)
	return x*8,y*8
end

-- outlined text
function printol(txt,x,y,fc,bc)
	for hor=-1,1 do
		for ver=-1,1 do
			print(txt,x+hor,y+ver,bc)
		end
	end
	
	print(txt,x,y,fc)
end

q={}
function upd_afters()
	foreach(q,function(a)
		a.t-=1
		if (a.t<=0) a.f() del(q,a)
	end)
end

function do_after(_t,_f)
	add(q,{f=_f,t=_t})
end

q2={}
function upd_intervals()
	foreach(q2,function(i)
		i.c+=1
		if i.c>=i.t then
			i.c=0 
			i:f()
		end
	end)
end

function do_interval(_t,_f)
	local int={t=_t,f=_f,c=0}
	add(q2,int)
	return int
end

function lerp(a,b,t)
	return min(a+(b-a)*t,b)
end
-->8
-- [ world mgmt ] --

function gen_world()
	ww,wh=128,32
	world={}
	
	gen_objs()
end

function draw_world()
	local dplr=true
	local tcx,tcy=tlz(cx,cy)
	
	for y=tcy,min(tcy+18,#world) do
		if dplr and (y+1)*8>plr_y then
			draw_plr()
			dplr=false
		end
		
		foreach(world[y],draw_obj)
		foreach(peeple[y],draw_peep)
	end
end

function update_world()
	if rnd()<0.0007 then
		local rx=rnd(ww-1)\1+1
		local ry=rnd(wh-1)\1+1
	
		local rt=rnd()
		if rt<0.3 then
			gen_grass_group(rx,ry)
		else
			if not collides(rx*8,ry*8) then
				if rt<0.7 then
					spawn_tree(rx,ry)
				else
					spawn_mushroom(rx,ry)
				end
			end
		end
	end
end

-- [ world specifics ] --

function gen_objs()
	-- only uses mset,
	-- thus can be used before
	spawn_river(30,rnd()>0.5)
	spawn_river(62,rnd()>0.5)
	spawn_river(95,rnd()>0.5)

	for y=1,wh-2 do
		world[y]={}
		for x=1,ww-3 do
		
			local obj=false

			if not collides(utlz(x,y)) then
				if rnd() > 0.97 then
					gen_grass_group(x,y)
				elseif rnd() > 0.96 then
					mset(x,y,65)
				else
					if #world[y]==0
					or #world[y]>0 
					and world[y][#world[y]].x~=x-1
					then
						obj=gen_mushroom(x,y)
						obj=gen_bush(x,y) or obj
						obj=gen_boulder(x,y) or obj
						obj=gen_tree(x,y) or obj
					end
				end
			end
			
			if (obj) add(world[y],obj)
		end
	end
	
	local ptx,pty=tlz(512,120)
	for x=ptx-1,ptx+1 do
		for y=pty-1,pty+1 do
			world_del(find_obj(x,y))
		end
	end
	
	spawn_bees()
end

function spawn_bees()
	for i=1,20 do
		add_bees(rnd(1010)\1,rnd(220)\1)
	end
end

function get_rnd_x(stx)
	local x=stx+rnd(30)\1-15
	if x>57 and x<67 then
		x=get_rnd_x(stx)
	end
	
	return x
end

function spawn_river(stx,up)
	local x=get_rnd_x(stx)
	local y=up and 30 or 1
	local tiles=up
		-- vert,vfroml,vfromr,hor,rfromv,lfromv
		and	{124,119,120,108,103,104}
		or  {124,103,104,108,119,120}
	
	if up then mset(x,31,127)
	else mset(x,0,111) end
	
	local od,tl -- old_dir,tile
	for i=1,25 do
		local r=i==1 and 0 or rnd()
		tl=nil
		
		if r<0.7 then -- ⬇️/⬆️
			if (od==0) tl=tiles[2]
			if (od==1) tl=tiles[3]
			
			mset(x,y,tl or tiles[1])
			y=up and y-1 or y+1
			od=3
		
		elseif r<0.875 then -- ➡️
			if (od==3) tl=tiles[5]
			if od==0 then -- stub
			else
				mset(x,y,tl or tiles[4])
				x+=1
				od=1
			end
		
		else -- ⬅️
			if (od==3) tl=tiles[6]
			if od==1 then --stub
			else
				mset(x,y,tl or tiles[4])
				x-=1
				od=0
			end
		end
	end
	
	if (od==3) tl=up and 126 or 125
	if (od==0) tl=109
	if (od==1) tl=110
	mset(x,y,tl)
end

function gen_grass_group(sx,sy)
	for tx=sx,sx+flr(rnd()*5) do
		for ty=sy,sy+flr(rnd()*5) do
			
			if mget(tx,ty)==0 and ty<wh-2 then
				if rnd() > 0.5 then
					mset(tx,ty,64)
				elseif rnd() > 0.8 then
					mset(tx,ty,66)
				elseif rnd() > 0.95 then
					mset(tx,ty,67)
				elseif rnd() > 0.98 then
					mset(tx,ty,84)
				end
			end
		end
	end
end

function gen_mushroom(x,y)
	if spawn_farmable(x,-0.03,0.075,0.98) then
		return gen_obj(105,x,y,1,1,1,farm_mushroom)
	end
end

function gen_tree(x,y)
	local w,h,s=1,2,98
	
	-- big tree or fallen log
	if rnd()>0.5 
	and not collides(utlz(x+1,y))
	then
		local r=rnd()
		if r>0.9 then     w,h,s=2,1,122
		elseif r>0.8 then w,s=2,197
		else              w,s=2,96
		end
	end

	if spawn_farmable(x,0.05,0.125,0.95) then
		return gen_obj(s,x,y,w,h,50,farm_tree,0)
	end
end

function gen_bush(x,y)
	if spawn_farmable(x,-0.1,0.125,1) then
		return gen_obj(
			191,x,y,1,1,30,farm_stump,0)
	end
end

function gen_boulder(x,y)
	local wh,s,wl,exe=1,rnd({83,175}),50,farm_stone
	
	if rnd()>0.4
	and not collides(utlz(x+1,y))
	then
		wh,s,wl,exe=2,rnd({99,173,195}),100,farm_boulder
	end
	
	if spawn_farmable(x,0,0.09,0.98) then
		return gen_obj(s,x,y,wh,wh,wl,exe,1)
	end
end

-- p_init = see sin_prob (main/utils)
function spawn_farmable(
	x,rnd_corr,p_init,p_corr
)
	if rnd()+rnd_corr > 
		sin_prob(x,p_init)*p_corr 
	then
		return true
	end
end

-- s    = start sprite
-- wl   = workload
-- exec = func to do when worked
-- sf   = sfx #
-- sgl  = single frame (drawn h*w)
function gen_obj(
	s,x,y,w,h,wl,exec,sf,sgl
)
	for lx=x,x+w-1 do
		for ly=y,y-h+1,-1 do
			local obj=find_obj(lx,ly)
			if (obj) del(world[ly],obj)
		end
	end

	return
		{ s=s
		, x=x, y=y
		, w=w, h=h
		, wl=wl or 100, dwl=0
		, exec=exec
		, sf=sf
		, sgl=sgl or false
		}
end

function draw_obj(obj)
	local tcx,tcy=tlz(cx,cy)
	
	if obj.x<tcx-5
	or obj.x>tcx+16
	then return end

	if obj.sgl then
		for w=0,obj.w-1 do
			for h=0,obj.h-1 do
				spr(
					obj.s,
					(obj.x+w)*8,
					(obj.y-h)*8
				)
			end
		end
		
	else
		spr(
			obj.s,
			obj.x*8,(obj.y-obj.h+1)*8,
			obj.w,obj.h
		)
	end
	
	draw_obj_progbar(obj)
end

function collides(x,y)
	local tx,ty=tlz(x,y)
	if tx<1 or ty<1
	or tx>127 or ty>31
	then return true end
	
	local el=find_obj(tx,ty)
	if el and fget(el.s,0) then
		return true
	end
	
	if fget(mget(tx,ty),0) then
		return true
	end
	
	return
end

function sel_collides()
	for ver=0,sh-1 do
		for hor=0,sw-1 do
			if collides((sx+hor)*8,(sy-ver)*8)
			or fget(mget(sx+hor,sy-ver),4)
			then
				return true
			end
		end
	end
	
	return false
end

function sel_adj_water()

	local found_water=false	

	for _x=sx-1,sx+sw do
		for _y=sy-sh,sy+1 do
			if fget(mget(_x,_y),4) then
				found_water=true
				break
			end
		end
	end
	
	return not sel_collides() and found_water
end

function world_del(obj)
	if (obj) del(world[obj.y],obj)
end

function find_obj(x,y)
	for _y=y,y+1 do
		local wy=world[_y]
	
		if wy and #wy>0 then
			for i=1,#wy do
				for j=0,wy[i].w-1 do
					if wy[i].x+j==x 
					and 
						( _y==y
						or wy[i].h>2
						or (wy[i].h>1 and wy[i].sgl))
					then
						return wy[i]
					end
				end
			end
		end
	end
end

function find_peep(x,y)
	local wy=peeple[y]
	
	if wy and #wy>0 then
		for i=1,#wy do
			if wy[i].x==x then
				return wy[i]
			end
		end
	end
end
-->8
-- [ ui / camera ] --

function init_ui()
	-- camera
	cx,cy,cam_off=450,200,32

	uic_bg=15
	uic_font=4
	uic_disabled=6
	uic_hl=4
	
	menu_sel=2
	menu_start=1
	disp_menu=false
	box_offset=1
	menu_anim=0
	
	disp_sel=false
	sx,sy,sw,sh,scond=0,0,0,0,nil
	
	olbl,xlbl="BUILD","WORK"
	indicator_off=0
end

function update_ui()
	move_cam()
	indicator_off=max(0,indicator_off-0.1)
end

function draw_ui()
	camera(cx,cy)
	
	if (disp_sel) draw_sel()
	
	draw_menu()
	draw_hud()
	
	local lbl_off=-sin(indicator_off)
	printol("🅾️"..olbl,cx+3,cy+lbl_off+105,15,4)
	printol("❎"..xlbl,cx+3,cy+lbl_off+113,15,4)
end

-- [ cam specifics ] --

function move_cam()
	cx+=(plr_x-64-cx)/10
	cy+=(plr_y-60-cy)/10
	cy=min(max(0,cy),32*8-120)
	cx=min(max(0,cx),128*8-128)
end

-- [ ui specifics ] --

function toggle_disp_menu()	
	disp_menu=not disp_menu
	
	if disp_menu then
		box_offset=1
		set_btndir(move_ui_sel,true)
		set_btnx(do_ui_sel,"SELECT")
		olbl="CLOSE"
		sfx(9)
	else
		set_btndir(move_plr,false)
		set_btnx()
		olbl="BUILD"
		sfx(10)
	end
end

function move_ui_sel(b)
	sfx(2)
	menu_anim=0
	if b==1 then
		for i=menu_sel,#menu do
			if type(menu[i])=="string" then
				menu_sel=i+1
				if menu_start<menu_sel-8 then
					menu_start=min(menu_sel-1,#menu-8)
				end
				return
			end
		end
		menu_sel,menu_start=2,1
	
	elseif b==0 then
		c,i=0,menu_sel
		while i>0 do
			if type(menu[i])=="string" then
				c+=1
			end
				
			if c==2 then
				menu_sel=i+1
				if menu_start>menu_sel then
					menu_start=menu_sel-1
				end
				return
			end
			
			i-=1
		end
		
		i=#menu
		while i>0 do
			if type(menu[i])=="string" then
				menu_sel=i+1
				menu_start=min(menu_sel-1,#menu-8)
				return
			end
			
			i-=1
		end
		
	elseif b==2 then
		if menu_sel==2 then
			menu_sel,menu_start=
				#menu,#menu-8
		else
			menu_sel-=1
			if (menu_start>=menu_sel) menu_start-=1
		end
		
	elseif b==3 then
		if menu_sel==#menu then
			menu_sel,menu_start=2,1
		else
			menu_sel=min(#menu,menu_sel+1)
			if (menu_start<menu_sel-8) menu_start+=1
		end
	end
	
	if type(menu[menu_sel])=="string" then
		if menu_sel==1 then menu_sel=2
		else move_ui_sel(b) end
	end
end

function do_ui_sel()
	if avail_res() 
	and unlocked[menu[menu_sel].label]
	then
		toggle_disp_menu()
		menu[menu_sel].action()
	
	else
		sfx(16)
	
	end
end

function m(
	label,action,wood,stone,desc
)
	return
		{ label=label
		, action=action
		, wood=wood
		, stone=stone
		, desc=desc
		}
end

-- hc = hide collision
function set_sel(w,h,cond)
	if not w or not h then
		disp_sel=false
	else
		disp_sel=true
		sw,sh,scond=w,h,cond
	end
end

-- [ ui draws (aka the walls of text) ] --

function draw_obj_progbar(obj)
	if (obj.dwl==0 or not obj.exec) return

	local x,y=
		(obj.x+obj.w/2)*8-6,
		(obj.y-obj.h)*8+6

	if (y<0) y+=8

	brd_rect(x,y,12,2,15,2)
	local w=obj.dwl*10/obj.wl
	rectfill(x,y,x+w,y+1,2)
end

function draw_sel()
	sx,sy=tlz(plr_x,plr_y)
	local w,h=sw-1,sh-1
	
	sx+=dir_x[plr_dir]
	sy+=dir_y[plr_dir]
	
	sx=plr_dir==1 and sx-w or sx
	sy=plr_dir==4 and sy+h or sy
	
	if (scond and scond()) 
	or (not scond and sel_collides())
	then
		pal(7,8)
	end
	
	spr(1,sx*8,(sy-h)*8)
	spr(1,(sx+w)*8,(sy-h)*8,1,1,true)
	spr(1,sx*8,sy*8,1,1,false,true)
	spr(1,(sx+w)*8,sy*8,1,1,true,true)

	pal()
end

function draw_menu()
	if not disp_menu and box_offset==1 then
		return
	end

	local w,h=80,64

	local x,y,tx,ty=draw_ctr_box(w,h,-30,true)
	?"build ...",x,y-10,15
	
	local off=0
	for i=1,9 do
		local _y,m,c=
			y+(i-1)*6,menu[menu_start+i-1],uic_disabled
	
		local is_head=type(m)=="string"
		if (is_head and i~=1) off+=4
		
		_y+=off
	
		if i==menu_sel-menu_start+1 then
			local length=lerp(0,w-4,menu_anim)
			menu_anim+=0.1
			brd_rect(x-2,_y+3,length-1,3,4)
			c=3
		end
		
		if is_head then
			brd_rect(x-4,_y-2,w-1,7,4)
			brd_rect(x-4,_y-1,w,5,4)
			?m,x,_y-1,15
		else
			if (unlocked[m.label] and c==uic_disabled) c=uic_font
			if (not unlocked[m.label]) c=6
			?m.label,x+2,_y,c
		end

		if (menu_start>1) print("⬆️",x+w-1,y,4)
		if (menu_start<#menu-8) print("⬇️",x+w-1,y+h-8,4)
		
	end
	
	local ms=menu[menu_sel]
	
	-- descbox
	x,y=draw_ctr_box(w,20,67)
	?ms.desc,x-1,y,uic_font
	
	-- resbox
	draw_box(tx-49,ty+22,49,9)
	local c=not avail_res() and 9 or 4
	print_res(tx-46,ty+24,ms.wood,ms.stone,nil,c)

end

function draw_hud()
	brd_rect(cx-1,cy+120,130,9,4,5)
	print_res(cx+1,cy+122,wood,stone,food,nil,true)
	print_pnum(cx+86,cy+122)
end

function print_res(x,y,w,s,f,c,mx)
	palt(14,true)
	palt(0,false)
	
	c=c or 15
	
	if mx and w>=max_wood then _c=9
	else _c=c end
	spr(15,x,y)
	?w,x+8,y,_c
	
	if mx and s>=max_stone then _c=9
	else _c=c end
	spr(14,x+22,y)
	?s,x+31,y,_c
	
	if f then
		if mx and f>=max_food then _c=9
		elseif f<=20 then _c=8
		else _c=c end
		spr(12,x+44,y)
		?f,x+52,y,_c
	end
	
	palt()
end

function print_pnum(x,y)
	palt(14,true)
	palt(0,false)
	
	local _c=15
	spr(13,x,y)
	?peeplenum,x+8,y,_c
	
	if happiness<20 then _c=8
	elseif happiness<50 then _c=6
	else _c=15 end
	spr(11,x+22,y)
	?flr(happiness),x+28,y,_c
	
	palt()
end

-- draws centered box
-- w/h in px
-- returns cursor start pos
-- also returns lower right coords
-- for resource box
function draw_ctr_box(w,h,v_off,head)
	local pw,ph=max(w+15,60),h+5
	local dx,dy=flr(cx)+128-pw,flr(cy)+(128-ph+(v_off or 0))/2
	dx+=128*box_offset

	box_offset=disp_menu 
		and max(box_offset-0.01-box_offset/3,0)
		or  min(box_offset+0.01+box_offset/3,1)

	draw_box(dx,dy,pw,ph,head)

	return dx+5,dy+4,dx+pw,dy+ph
end

function draw_box(x,y,w,h,head)
	brd_rect(x+2,y+2,w,h,3)
	if head then
	 brd_rect(x+2,y-5,w,7,3)
	 brd_rect(x+2,y-6,w,1,3)
 end
	
	brd_rect(x,y,w,h,15,4)
	if head then
		brd_rect(x,y-7,w,7,4)
		brd_rect(x,y-8,w,1,4)
		spr(2,x+w-9,y-8)
	end
end
-->8
-- [ gameplay ] --

function init_gp()

	-- ⬅️➡️⬆️⬇️
	dir_x={ -1, 1, 0, 0 }
	dir_y={  0, 0,-1, 1 }

	-- resources
	wood,max_wood=0,150
	stone,max_stone=0,150
	food,max_food=50,100
	
	happiness=50
	
	res_buildings=0
	
	-- how many resources per period
	per_wood=0
	per_stone=0
	per_food=-1
	
end

function update_gp()
	if (t%200==0) calc_happy()
	
	if t%600==0 then
		local p=min(1,peeplenum*2/res_buildings)
		local h=min(1,happiness/75)
	
		wood+=flr(per_wood*p*h)
		stone+=flr(per_stone*p*h)
		food+=per_food-peeplenum*2
	end
	
	wood=min(999,max(0,min(max_wood,wood)))
	stone=min(999,max(0,min(max_stone,stone)))
	food=min(999,max(0,min(max_food,food)))
end

function calc_happy()

	if (peeplenum==0) return
	if (food<10) happiness-=peeplenum
	
	local rate= -peeplenum*max(1,happiness/50)
	if (food<min(200,peeplenum*2)) rate*=2
	rate+=houses*1.8
	rate+=wells
	rate+=taverns*3
	rate+=chapels*4
	
	happiness+=max(-5,min(5,rate))
	happiness=max(0,min(100,happiness))
	
end

function avail_res()
	return 
		wood >= menu[menu_sel].wood and
		stone >= menu[menu_sel].stone
end

function use_res(inverted)
	local sign=inverted and -1 or 1
	wood-=sign*menu[menu_sel].wood
	stone-=sign*menu[menu_sel].stone
end

-- default for x
is_working=false
function work()
	local x,y=plr_x+dir_x[plr_dir]*4,plr_y+dir_y[plr_dir]*4
	local obj=find_obj(tlz(x,y))
	
	if find_peep(tlz(x,y)) then
		sfx(rnd({19,20,23}))
	end
	
	if obj and obj.exec 
	and not is_working 
	then
		change_anim("work",true)
		set_btndir(function()end)
		is_working=true
		
		do_after(15,function() 
			sfx(obj.sf)
			
			local ex=plr_x+dir_x[plr_dir]*4
			local ey=plr_y+dir_y[plr_dir]*4
			add_burst(ex,ey-4,2,2,{5,6})
			
			obj.dwl+=10
		
			if obj.dwl>=obj.wl then
				obj:exec()
			end
		end)
		
		do_after(30,function()
			change_anim()
			if (not disp_menu) set_btndir()
			is_working=false
		end)
	end
end

function cancel_action()
	set_defbtns()
	set_sel()
end

-- [ farming resources ] --
function farm_tree(obj)
	if obj.s==96 then
		wood+=20
		obj.s,obj.w=80,2
	elseif obj.s==197 then
		wood+=20
		obj.s,obj.w=229,2
	elseif obj.s==122 then
		wood+=15
		world_del(obj)
	else
		wood+=10
		obj.s,obj.w=82,1
	end

	local ex,ey=utlz(obj.x,obj.y)
	add_burst(ex-2,ey,8*obj.w+4,4,{3,4,5})

	obj.h,obj.dwl,obj.exec=1,0,farm_stump

	sfx(4)
end

function farm_stump(obj)
	wood+=5
	world_del(obj)
	
	local ex,ey=utlz(obj.x,obj.y)
	add_burst(ex,ey+4,8*obj.w,2,{3,4,5})
end

function farm_boulder(obj)
	stone+=40
	
	for hor=0,1 do
		add(world[obj.y],gen_obj(
			rnd({83,175}),obj.x+hor,obj.y,
			1,1,50,farm_stone,1
		))
	end
	
	local ex,ey=utlz(obj.x,obj.y)
	add_burst(ex-2,ey+4,8*obj.w+4,4,{5,6})
	
	world_del(obj)
	sfx(5)
end

function farm_stone(obj)
	stone+=10
	world_del(obj)
	
	local ex,ey=utlz(obj.x,obj.y)
	add_burst(ex,ey+4,8*obj.w,4,{5,6})
end

function farm_mushroom(obj)
	food+=5
	world_del(obj)
	
	local ex,ey=utlz(obj.x,obj.y)
	add_burst(ex,ey+6,8,2,{8})
end
-->8
-- [ player / controls ] --

function init_plr()

	plr_x,plr_y=512,120
	plr_dir=4 -- reflects dir_x/_y

	-- ⬅️➡️⬆️⬇️
	anim_repo=
	{ idle={32,32,17,16}
	, run ={32,32,36,34}
	, work={52,52,50,48}
	}

	plrt=0
	plr_anim="idle"
	canidle=true
	plr_vel=0
	
	set_defbtns()

	pressed_last_frame=false

end

function update_plr()
	plrt+=1

	if (btnp(❎) or btnp(🅾️))
	and not pressed_last_frame
	then
		indicator_off=1
		pressed_last_frame=true
	end
	
	if not (btn(❎) or btn(🅾️)) then
		pressed_last_frame=false
	end

	if (btnp(❎)) btnpx()
	if (btnp(🅾️)) btnpo()
	
	-- stop directional animation
	local stopda=true
	
	for b=0,3 do
		if (btnp(b))	btnpdir(b)
		if btn(b) then
			btndir(b)
			stopda=false
			break
		end
	end
	
	if stopda and canidle then
		change_anim("idle")
	end
	
	plr_vel=max(0,plr_vel-0.05)
end

-- called in world draw
function draw_plr()
	palt(0,false)
	palt(14,true)
	
	local frame=anim_repo[plr_anim][plr_dir]
	
	if plr_anim~="idle" then
		local plr_anim_speed=
			plr_anim=="work" and 18 or 12
		frame+=(plrt+plr_anim_speed)/plr_anim_speed%2
	end
	
	spr(frame,
		plr_x-4,plr_y-7,1,1,
		plr_dir==1)
	
	palt()

end

-- [ control mgmt ] --

-- p for btnp
function set_btndir(f,p)
	if not f then
		btnpdir,btndir=
			function() end,move_plr
	else
		btnpdir,btndir=
			return_btnf(f,p)
	end
end

function return_btnf(f,p)
	return 
		p and f or function() end, -- btnp
		p and function() end or f  -- btn
end

function set_btno(f,lbl)
	if not f then
		btnpo,olbl=toggle_disp_menu,"MENU"
	else
		btnpo,olbl=f,lbl
	end
end

function set_btnx(f,lbl)
	if not f then
		btnpx,xlbl=work,"WORK"
	else
		btnpx,xlbl=f,lbl
	end
end

function set_defbtns()
	set_btndir()
	set_btnx()
	set_btno()
end

-- [ player specifics ] --

function move_plr(b)
	change_anim("run")
	plr_vel=min(1,plr_vel+0.1)
	plr_dir=b+1
	
	local x,y=plr_x+dir_x[plr_dir]*plr_vel,plr_y+dir_y[plr_dir]*plr_vel
	local tx,ty=tlz(plr_x+dir_x[plr_dir]*3,y)
	local obj=find_obj(tx,ty)
	
	if collides(plr_x+dir_x[plr_dir]*3,y)
	and not (obj and obj.s==187)
	then
		change_anim()
	else
		plr_x,plr_y=x,y
	end
end

function change_anim(a,noidle)
	if not a then
		plr_anim="idle"
		return
	end

	if (plr_anim~=a) plrt=0
	plr_anim=a
	
	canidle=not noidle
end
-->8
-- [ peeple ] --

function init_peeple()
	peeplenum=0
	peeple={}
	for y=0,wh-1 do
		peeple[y]={}
	end
	
	peep_sr=0 -- spawnratecounter see update
end

function update_peeple()
	if houses*3>peeplenum
	and happiness>20
	then
		peep_sr+=rnd()
	end

	if happiness<20
	and peeplenum>1
	and rnd()>0.995 then
		remove_peep()
	end

	if peep_sr>2200
	and happiness>=50
	then
		peep_sr=0
		create_peep()	
	end

	for y=0,wh-1 do
		foreach(peeple[y],update_peep)
	end
end

function update_peep(p)
	local oldy=p.y
	
	if (p.ox~=0) p.ox-=sgn(p.ox)/2
	if (p.oy~=0) p.oy-=sgn(p.oy)/2
	
	p.x +=p.tx    p.y +=p.ty
	p.ox-=p.tx*8  p.oy-=p.ty*8
	p.tx =0       p.ty =0
	
	if rnd()>0.998 then
		local ntx=rnd()>0.5 and 1 or -1
		local nx=p.x+ntx
		if not collides(nx*8,p.y*8+8) then
			p.tx=ntx
			p.d =sgn(p.tx)==-1 and 0
		end
	end
	
	if rnd()>0.998 then
		local nty=rnd()>0.5 and 1 or -1
		local ny=p.y+nty
		if not collides(p.x*8,ny*8) then
			p.ty=nty
			p.d =sgn(p.ty)==-1 and 2
		end
	end
	
	if oldy~=p.y then
		del(peeple[oldy],p)
		add(peeple[p.y],p)
	end
end

-- called in world mgmt
-- because of z-index rendering
function draw_peep(p)
	palt(0,false)
	palt(14,true)
	
	local f = (p.d==2 and p.s+2 or p.s) + ((t+p.off)/40)%2
	local x,y=utlz(p.x,p.y)
	
	spr(f,x+p.ox,y+p.oy+2,1,1,p.d==0)
	
	palt()
end

function create_peep()
	function get_coords()
		local h=rnd(tc)
	
		return h.x+flr(rnd(20)-10),
									h.y+flr(rnd(20)-10)
	end
	
	local x,y=get_coords()
	local c=0
	while collides(utlz(x,y))
	and c<10 do
		x,y=get_coords()
		c+=1
	end
	
	if (c<10) spawn_peep(x,y)
end

function spawn_peep(x,y)
	sfx(7)

	add(peeple[y],
		{ x=x,  y=y, off=rnd(100)
		, tx=0, ty=0
		, ox=0, oy=0
		, d=1,  s=rnd({18,22,38,54})
		})
		
	peeplenum=0
	foreach(peeple,function(p)
		peeplenum+=#p
	end)

	add_burst(
		x*8-4,y*8+3,14,10,
		{7,14}
	)
end

function remove_peep()

	local ys={}
	for i=0,wh-1 do
		if (#peeple[i]>0) add(ys,i)
	end

	if (#ys==0) return

	local ry=rnd(ys)
	local rp=rnd(peeple[ry])
	
	if rp then
		del(peeple[ry],rp)
		peeplenum-=1
		
		add_burst(
			rp.x*8-4,rp.y*8+3,14,10,
			{7,14}
		)
		
		sfx(15)
	end
		
end
-->8
-- [ particles ] --

function init_particles()
	emitters={}
	particles={}
	
	add_wind_prt({3},0.015)
	add_wind_prt({7,14},0.005)
end

function update_particles()
	foreach(emitters,function(e)
		e.ctr+=e.rate+rnd(e.rand*2)-e.rand
		
		while e.ctr>1 do	
			add(particles,
			{ x=e.x+rnd(e.w),y=e.y+rnd(e.h)
			, vel=e.vel,dc=e.pdc,t=0
			, c=rnd(e.clrs)
			, event=e.event
			, emitter=e
			})
			
			e.ctr-=1
		end
		
		if (e.burst) del(emitters,e)
	end)
	
	foreach(particles,function(p)
		if (p.event) p:event()
		
		p.t+=1
		local dx,dy=p:vel()
		p.x+=dx
		p.y+=dy
		if p:dc() then
			del(particles,p)
		end
	end)
end

function draw_particles()
	foreach(particles,function(p)
		pset(p.x,p.y,p.c)
	end)
end

-- bees
function add_bees(x,y)
	add(emitters,
	{ x=x,y=y,w=3,h=8
	, vel=bees_vel
	, clrs={10,9}
	, ctr=0,rate=0.03,rand=0.03
	, pdc=bees_death
	, event=bees_event
	})
end

function bees_event(p)
	if plr_x>p.x-10 and plr_x<p.x+13
	and plr_y>p.y-10 and plr_y<p.y+18
	then
		p.t2,p.st=p.t,0.3
		p.vel=bees_vel_alt
		p.event=nil
		
		if del(emitters,p.emitter) then
			do_after(600,function()
					add_bees(rnd(1010)\1,rnd(220)\1)
			end)
		end
	end
end

function bees_vel(p)
	return sin(p.t/200+0.25)/7,
								sin(p.t/200)/10
end

function bees_vel_alt(p)
	p.st+=0.03+rnd(0.03)-0.015

	return sin(p.t2/200+0.25)/(2.333*p.st),
								sin(p.t2/200)/(3.333*p.st)
end

function bees_death(p)
	return p.t>200
end

-- smoke

function add_smoke(x,y,w,h,c)
	local em=
		{ x=x,y=y,w=w,h=h
		, vel=smoke_vel
		, clrs=c
		, ctr=0,rate=0.05,rand=0.02
		, pdc=smoke_death
		}
	
	add(emitters,em)
	
	return em
end

function smoke_vel(p) 
	return sin(p.t/200)/25,-0.1
end

function smoke_death(p)
	return p.t>60+rnd(20)-10
end

-- burst

function add_burst(x,y,w,h,c)
	add(emitters,
	{ x=x,y=y,w=w,h=h
	, vel=burst_vel
	, clrs=c
	, burst=true
	, ctr=w*h/2,rate=0,rand=0
	, pdc=burst_death
	})
end

function burst_vel(p)
	local s=rnd()>0.5 and 1 or -1
	return sin(p.t*s/300),
								-1/((p.t+rnd(20))/2)
end

function burst_death(p)
	return p.t>40-rnd(20)
end

-- wind

function add_wind_prt(c,r)
	add(emitters,
	{ x=0,y=0,w=1024,h=256
	, vel=wind_vel
	, clrs=c
	, ctr=0,rate=r,rand=r/2
	, pdc=wind_death
	})
end

function wind_vel(p)
	return 
		0.25+sin(p.t/200%2-1)/20,
		0.05+sin(p.t/300%2-1)/5
end

function wind_death(p)
	return p.t>1200
		or p.x>1024 or p.y>256
end
-->8
-- [ building mgmt ] --

function init_buildings()
	blds=
		{ house="house"
		, tavern="tavern"
		, workshop="workshop"
		, lodge="forester's lodge"
		, quarry="quarry"
		, windmill="windmill"
		, fisher="fisher's lodge"
		, chapel="chapel"
		, crops="crop field"
		, tree="tree"
		, flowers="flowers"
		, mushroom="mushroom"
		, road="road"
		, woodpile="wood pile"
		, stonepile="stone pile"
		, storage="storage"
		, bridge="bridge"
		, well="well"
		, deconstruct="deconstruct"
		}
		
	unlocked={}
	unlock(blds.house)
	
	-- menu contents
	menu=
		{ "general"
		, m(blds.house,place_house,40,20,"⬆️ happiness,peeple\n★ road,workshop,crops")
		, m(blds.road,place_road,3,0,"places dirt road\n★ bridge,well")
		, m(blds.bridge,place_bridge,10,10,"to cross rivers\nmust be on hor/ver\nwater")

		, "resources"
		, m(blds.workshop,place_workshop,50,50,"⬆️ wood & stone\n★ forester,quarry\n   fisher")
		, m(blds.lodge,place_lodge,70,50,"⬆️⬆️ wood\n★ woodpile,plants")
		, m(blds.quarry,place_quarry,50,70,"⬆️⬆️ stone\n★ stonepile")
		
		, "food"
		, m(blds.crops,place_crops,30,0,"grows farmable food\n★ windmill")
		, m(blds.windmill,place_windmill,150,200,"farms surr. crops\n⬆️ food storage\n★ tavern")
		, m(blds.fisher,place_fisher,50,30,"⬆️ food\nmust be near water")
		, m(blds.mushroom,plant_mushroom,3,0,"plants a mushroom")
	
		, "happiness"
		, m(blds.well,place_well,30,60,"⬆️ happiness")
		, m(blds.tavern,place_tavern,200,250,"⬆️⬆️ happiness")
		, m(blds.chapel,place_chapel,250,400,"⬆️⬆️⬆️ happiness")		
	
		, "storage"
		, m(blds.woodpile,place_woodpile,50,0,
					"⬆️ wood storage (+25)")
		, m(blds.stonepile,place_stonepile,0,50,
					"⬆️ stone storage (+25)")
		, m(blds.storage,place_storage,100,100,"⬆️ wood & stone\n   storage (+50)")

		, "misc"
		, m(blds.flowers,place_flower,1,0,"places random flower")
		, m(blds.tree,plant_tree,5,0,"plants a tree")
		, m("deconstruct",deconstruct,0,0,"removes a building")

		}

	houses=0
	wells=0
	taverns=0
	chapels=0
	
	tc={} -- towncenter, contains houses (for peeplespawn)

	last_road=90

end

function unlock(key)
	unlocked[key]=true
end

function deconstruct()
	function deconst_sel()
	
		local obj = find_obj(sx,sy)
		if (obj and obj.del) return false
		
		local tle=mget(sx,sy)
		if (tle==187 or tle==188) return false
		
		return true
	end

	set_sel(1,1,deconst_sel)
	set_btno(cancel_action,"CANCEL")
	set_btnx(function()

		local obj = find_obj(sx,sy)
		if obj and obj.del then
			obj:del()
			return
		end
		
		local tle=mget(sx,sy)
		if tle==187 then
			mset(sx,sy,124)
			return
		elseif tle==188 then
			mset(sx,sy,108)
			return
		end
		
		sfx(16)
		
	end,"DECONSTRUCT")
end

-- [ buildings ] --

function place_house()
	place_constr_site(2,1,100,fin_house)
end

function fin_house(obj)
	fin_def(obj,78,2)
	
	houses+=1
	
	add(tc,obj)
	
	unlock(blds.workshop)
	unlock(blds.crops)
	unlock(blds.road)
	unlock(blds.deconstruct)

	obj.sdel=function()
		houses-=1
		del(tc,obj)
	end

	local em=add_smoke(
		(obj.x+2)*8-3,(obj.y-1)*8,
		2,1,{13,6,5})
		
	obj.em=em
end

function place_workshop()
	place_constr_site(2,1,100,fin_workshop)
end

function fin_workshop(obj)
	fin_def(obj,160,2)
	
	unlock(blds.lodge)
	unlock(blds.quarry)
	unlock(blds.fisher)
	
	per_wood+=5
	per_stone+=5
	res_buildings+=1
	
	obj.sdel=function()
		per_wood-=5
		per_stone-=5
		res_buildings-=1
	end
end

function place_lodge()
	place_constr_site(2,1,150,fin_lodge)
end

function fin_lodge(obj)
	fin_def(obj,128,2)
	
	unlock(blds.tree)
	unlock(blds.mushroom)
	unlock(blds.flowers)
	unlock(blds.woodpile)
	
	per_wood+=10
	res_buildings+=1
	
	obj.sdel=function()
		per_wood-=10
		res_buildings-=1
	end
end

function place_quarry()
	place_constr_site(3,1,150,fin_quarry)
end

function fin_quarry(obj)
	fin_def(obj,130,2)

	unlock(blds.stonepile)

	per_stone+=10
	res_buildings+=1
	
	obj.sdel=function()
		per_stone-=10
		res_buildings-=1
	end
end

function place_stonepile()
	setup_bld_action(1,1,function()
		local pile=
			gen_obj(186,sx,sy,1,1)
			
		add(world[sy],pile)

		max_stone+=25
		unlock(blds.storage)
		
		pile.del=function(self)
			def_del(self)
			max_stone-=25
		end
		
		sfx(3)
	end)
end

function place_woodpile()
	setup_bld_action(1,1,function()
		local pile=
			gen_obj(185,sx,sy,1,1)
		
		add(world[sy],pile)
			
		max_wood+=25
		unlock(blds.storage)
		
		pile.del=function(self)
			def_del(self)
			max_wood-=25	
		end
		
		sfx(3)
	end)
end

function place_storage()
	place_constr_site(2,1,150,fin_storage)
end

function fin_storage(obj)
	fin_def(obj,162,2)
	
	max_wood+=50
	max_stone+=50
	
	obj.sdel=function()
		max_wood-=50
		max_stone-=50
	end
end

function place_windmill(obj)
	place_constr_site(4,2,200,fin_windmill)

	res_buildings+=1
end

function fin_windmill(obj)
	fin_def(obj,133,4)
	
	max_food+=100
	res_buildings+=1
	
	unlock(blds.tavern)
	unlock(blds.chapel)
	
	local _x,_y=obj.x,obj.y
	
	local int=do_interval(200,
		function()
			windmill_int(_x,_y)
		end)

	obj.sdel=function()
		del(q2,int)
		max_food-=100
		res_buildings-=1
	end
end

function windmill_int(_x,_y)
	local p=min(1,peeplenum*2/res_buildings)
	local h=min(1,happiness/50)
	
	local last_found=nil
	for x=_x-5,_x+9 do
			for y=_y-5,_y+5 do
				local mb_crop=find_obj(x,y)
				if mb_crop and mb_crop.s==106 then
					if p<=0 or h<=0 or rnd()>p*h then
						return
					end
					
					last_found=mb_crop
					
					if rnd()>0.7 then
						farm_crop(mb_crop)
						return
					end
				end
			end
		end
		
		if last_found then
			farm_crop(last_found)
		end
end

function place_fisher()
	place_constr_site(
		3,1,150,fin_fisher,
		function()
			return (not sel_adj_water())
		end)
end

function fin_fisher(obj)
	fin_def(obj,141,2)
	per_food+=5
	
	obj.sdel=function()
		per_food-=5
	end
end

function place_well()
	place_constr_site(1,1,100,fin_well)
end

function fin_well(obj)
	fin_def(obj,199,2)
	
	wells+=1
	
	obj.sdel=function()
		wells-=1
	end
end

function place_chapel()
	place_constr_site(4,2,300,fin_chapel)
end

function fin_chapel(obj)
	fin_def(obj,137,3)
	
	chapels+=1
	
	obj.sdel=function()
		chapels-=1
	end

	obj.em = add_smoke(
		(obj.x+3)*8+1,(obj.y-1)*8-2,
		3,1,{13,6,5})
end

function place_tavern()
	place_constr_site(
		3,2,300,fin_tavern)
end

function fin_tavern(obj)
	fin_def(obj,192,3)
	
	taverns+=1
	
	obj.sdel=function()
		taverns-=1
	end

	obj.em = add_smoke(
		(obj.x)*8+5,(obj.y-2)*8+2,
		2,1,{13,6,5})
end

function place_crops()
	setup_bld_action(3,3,function()
		local crop,c=
			{ 76,75,77
			, 75,75,75
			, 92,75,93
			}, 1
		
		local _x,_y,_w,_h=sx,sy,sw,sh
		function loop(f)
			for y=_y-_h+1,_y do
				for x=_x,_x+_w-1 do
					f(x,y)
				end
			end
		end
		
		loop(function(x,y)
			mset(x,y,crop[c])
			c+=1
		end)
		
		local dur=1000
		function grow_crops(x,y)
			do_after(dur+rnd(200),function()
				
				local obj=gen_obj(107,x,y,1,1,10)
				add(world[y],obj)
					
				do_after(dur+rnd(200),function()
					obj.s,obj.exec=106,farm_crop
				
					add_burst(obj.x*8,obj.y*8,8,5,{9,10})
				end)
			end)
		end
		
		loop(grow_crops)
		
		unlock(blds.windmill)
	end)
end

function farm_crop(obj)
	food+=3
	del(world[obj.y],obj)
	
	local _x,_y=utlz(obj.x,obj.y)
	if  _x>cx-20 and _x<cx+148
	and _y>cy-20 and _y<cy+148
	then
		sfx(22)
	end
	
	local tle=mget(obj.x,obj.y)
	if tle==75 or tle==76 or tle==77
	or tle==92 or tle==93 then
		grow_crops(obj.x,obj.y)
	end
end

function remove_crop(x,y)
	local obj=find_obj(x,y)
	if obj and 
		(obj.s==106 or obj.s==107)
	then
		del(world[y],obj)
	end
end

function plant_tree()
	setup_bld_action(1,1,
		function()
			spawn_tree(sx,sy)
		end)
end

function spawn_tree(x,y)
	local sap=gen_obj(68,x,y,1,1,50)
	
	add(world[y],sap)
	
	do_after(600,function()
		sap.h=2
		sap.exec=farm_tree
		
		if not collides(utlz(x+1,y)) 
		and rnd()>0.3
		then
			sap.s,sap.w=rnd({96,197}),2
		
		elseif not collides(utlz(x-1,y))
		and rnd()>0.3
		then
			sap.s,sap.w=rnd({96,197}),2
			sap.x-=1
			
		else
			sap.s=98
		end
		
		add_burst(sap.x*8,sap.y*8,sap.w*8,10,{3,3,9,11,11})
	end)
end

function plant_mushroom()
	setup_bld_action(1,1,function()
		spawn_mushroom(sx,sy)
	end)
end

function spawn_mushroom(x,y)
	local sap=gen_obj(121,x,y,1,1,10)
	add(world[y],sap)
	
	do_after(400,function()
		sap.s=105
		sap.exec=farm_mushroom
		
		add_burst(sap.x*8,sap.y*8,8,5,{8,9})
	end)
end

function place_road()
	set_sel(1,1)
	set_btno(cancel_action,"CANCEL")
	set_btnx(function()
		local tle=mget(sx,sy)
		if tle==187 or tle==188 then
			sfx(16)
			return
		end
	
		if is_road(sx,sy) then
			mset(sx,sy,0)
			wood+=1
			fix_roads_around()
			return
		end
		
		if collides(utlz(sx,sy))
		or not avail_res() then
			sfx(16)
			return
		end
	
		set_road(sx,sy)
		fix_roads_around()
		
		remove_crop(sx,sy)
		
		unlock(blds.bridge)
		unlock(blds.well)
		
		use_res()
		sfx(3)
	end,"PLACE/REMOVE")
end

function place_flower()
	set_sel(1,1)
	set_btno(cancel_action,"CANCEL")
	set_btnx(function()
		if (collides(utlz(sx,sy))) return
		
		mset(sx,sy,rnd({64,65,66,67}))
		
		remove_crop(sx,sy)
		
		use_res()
	end,"PLACE")
end

function place_bridge()
	set_sel(1,1,check_for_bridge_coll)
	set_btno(cancel_action,"CANCEL")
	set_btnx(function()
		local ntle=get_bridge_tle()
		if not ntle then
			sfx(16)
			return
		end
				
		mset(sx,sy,ntle)
		fix_roads_around()

		sfx(3)
		use_res()
	end,"PLACE/REMOVE")
end

function get_bridge_tle()
	local tle=mget(sx,sy)
	if (tle==124) return 187
	if (tle==108) return 188
end

function check_for_bridge_coll()
	if (get_bridge_tle()) return false

	return true
end

-- [ helpers ] --

-- build prep

function setup_bld_action(
	_sw,_sh,_f,_cond
)
	set_sel(_sw,_sh,_cond)
	set_btno(cancel_action,"CANCEL")
	set_btnx(function()

		if sel_collides()
		or _cond and _cond()
		then
			sfx(16)
		 return
		end

		_f()
	
		use_res()
	
		set_sel()
		set_defbtns()
	end,"PLACE")
end

function place_constr_site(
	_sw,_sh,_wl,_f,_cond
)
	setup_bld_action(_sw,_sh,function()
		add(world[sy],
			gen_obj(
				91,sx,sy,sw,sh,
				_wl,_f,0,true
		))
	end,_cond)
end

-- build fin

function fin_def(obj,s,h)
	obj.s,obj.h,obj.sgl,obj.exec=s,h or obj.h,false,nil
	
	local ex,ey=utlz(obj.x,obj.y)
	local ew,eh=utlz(obj.w,obj.h)
	
	obj.del=def_del
		
	add_burst(
		ex-4,ey,ew+8,eh/2,
		{4,5,13}
	)
		
	sfx(3)
end

function def_del(o)
	local ex,ey=utlz(o.x,o.y)
	local ew,eh=utlz(o.w,o.h)

	if (o.sdel) o:sdel()
	
	if o.em then
		del(emitters,o.em)
	end
	
	add_burst(
		ex-4,ey,ew+8,eh/2,
		{4,5,13}
	)
	del(world[o.y],o)
end

-- roads

function is_road(x,y)
	local tle=mget(x,y)
	local roads=
		{71,72,73,74,88,89,90,187,188}
		
	for v in all(roads) do
		if (tle==v) return tle
	end
	
	return false
end

function fix_roads_around()
	for x=sx-1,sx+1 do
		for y=sy-1,sy+1 do
			
			local road=is_road(x,y)
			
			if road
			and (road~=187 and road~=188)
			and (x~=sx or y~=sx)
			then
				set_road(x,y)
			end
			
		end
	end
end

-- a bit of a mindtwister
-- checks surrounding tiles
-- and based on that chooses
-- which one to mset
function set_road(x,y)
	local tle
	local l,r,u,d=
		is_road(x-1,y),
		is_road(x+1,y),
		is_road(x,y-1),
		is_road(x,y+1)
	
	if not (l or r or u or d) then
		mset(x,y,last_road)
		return
	end
	
	if u then
		tle=r and l and 71 or
						r and 88 or 
						l and 89 or
						74
						
		tle=d and (r or l) and 71 or tle
	end
	
	if d then
		tle=r and l and 71 or
						r and 72 or 
						l and 73 or
						74
						
		tle=u and (r or l) and 71 or tle
	end
	
	tle=tle or (r or l) and 90 or 74
	
	if tle==74 or tle==90 then
		last_road=tle
	end
	
	mset(x,y,tle)
end
-->8
-- [ intro screens ] --

function init_intro()
	draw=draw_intro
	update=update_intro
	
	intro_done=false
	
	screen=1
	screen_off=300
	
	intro_cg=1
	intro_c=100
	
	intro_wobble=0
	
	sf=9
end

function update_intro()
	if (intro_done) return

	if btnp(❎) then
		screen+=1
		screen_off=300
		
		if (screen<=3) sfx(sf)
		sf=17
	end
	
	if screen==3 then
		intro_cg=1.015
	
		do_after(100,function()
			gp_init()
			update=gp_update60
			draw=gp_draw
			
			intro_done=true
			
			q={}
		end)
	
	else
		intro_wobble=t/40%2
		screen_off=max(0,screen_off/1.2)\1

	end
end

function draw_intro()
	if (intro_done) return

	cls(12)
	palt(14,true)
	palt(0,false)

	intro_c*=intro_cg
	circfill(64,180,intro_c,10)
	
	for i=1,20 do
			local anim=i-t/300
			local tx=cos(anim/20)*220+64
			local ty=sin(anim/20)*220+200
			
			for j=-15,15 do
				line(64-j/3,180,tx+j,ty,10)
			end
	end
	
	draw_brd(0,0)
	rectfill(0,120,128,128,4)
	line(1,120,126,120,5)

	if (screen==1) draw_screen1()
	if (screen==2) draw_screen2()

	print("by partnano",2,122,15)
	print("made with ♥",79,122,15)
	palt()
end

function draw_screen1()
	sspr(80,8,48,16,
		16,20-screen_off,96,32)
		
	printol("❎ to start",
		42,100+intro_wobble+screen_off,7,0)
end

function draw_screen2()
	printol(
		"welcome, villager!\n\n"..
		"farm trees and stones,\n"..
		"gather food, and build a\n"..
		"village for your peeple!\n\n"..
		"buildings unlock others.\n"..
		"some produce resources & food,\n"..
		"others make peeple happy.\n"..
		"happy and well-fed peeple\n"..
		"mean more production.\n\n"..
		"peeple will come with \nthe first house,\n"..
		"but there is no rush.\n\nhave fun.",
		6,7-screen_off,7,0)

	local y=110+t/50%2+screen_off
	printol("❎ to start",80,y,7,0)
end
__gfx__
0000000077000000033333300000000000000000000000000000000000000000000000000000000000000000ae7eaeeeeaaeeeeeee1ee1eeeee6666eee4444ee
000000007000000033e333330000000000000000000000000000000000000000000000000000000000000000e777eeeee9aabeeeee1111eeee6666dee44442ee
00700700000000003e333e33000000000000000000000000000000000000000000000000000000000000000077a77eeeee9abeeee116161ee6666dee444422ee
0007700000000000334333e30000000000000000000000000000000000000000000000000000000000000000e777eeeeee33bbeeee1111ee7766deeefff22eee
0007700000000000334334330000000000000000000000000000000000000000000000000000000000000000ae7eaeeeeee33beeee1111ee7666eeeefff2eeee
0070070000000000333443330000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000000000000000333343330000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000000000000000033333300000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeee1ee1eeeeeeeeeeee1ee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00eeee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee00eeeeee00eeeee1111eeee1ee1eeee1111eeee1ee1eee9eeee9eeeeeeeeee9eeee9eeeeeeeeeee0770ee0770eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0440eeee0440eee116161eee1111eee111111eee1111eeee5555eee9eeee9eee5555eee9eeee9eee0770ee0770eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0ff0eeee0420eeee1111eee116161eee1111eee111111eee5f5feeee5555eeee5555eeee5555eeee0770ee07700e00ee00eee00eeee0000eee0000e0000eee
e088980ee088880eee1111eeee1111eeee1111eeee1111eeee5555eeee5f5feeee5555eeee5555eeee0777007777707700770e0770ee077770e07777077770ee
0f5558f005555880ee1111eeee1111eeee1111eeee1111eeee5555eeee5555eeee5555eeee5555eeeee077007707707700770e0770e0777770077777077770ee
e040040ee040040ee311113ee311113ee311113ee311113ee399993ee399993ee399993ee399993eeee077007707707700770e07770077000e0770000770770e
ee0330eeee0330eeee3333eeee3333eeee3333eeee3333eeee3333eeee3333eeee3333eeee3333eeeee07777770770770077007777007700000777770777770e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedeedeeeeeeeeeeeedeedeeeeeeeeeeeeee077770077077007700777770770077077000077770ee
eee000eeeee000eeeee00eeeeee00eeeeee00eeeeee00eeeeed5ddeeeedeedeeeeddddeeeedeedeeeeee0777700770777077707707707777770777770770770e
ee04440eee04440eee0440eeee0440eeee0440eeee0440eeeed1d1eeeed5ddeeeeddddeeeeddddeeeee407777007707770777077077007777700777707707704
ee024f0eee024f0ee00ff0eeee0ff00ee00420eeee04200eeed5ddeeeed1d1eeeeddddeeeeddddeeeee444774444444444444444444444447744444444444444
ee08880eee08880e0f88980ee08898f00f88880ee08888f0eeddddeeeed5ddeeeeddddeeeeddddeee5ee44774444ee44e444444ee444444477444e44444444ee
e0f5550ee0f555eee0555f0ee0f5580ee0855f0ee085550eeeddddeeeeddddeeeeddddeeeeddddeeeeeee44444eee5eeeeeeeee5eee44ee4444eeeeee4eeee5e
ee04020eee0040eeee0400eeee0040eeee0400eeee0040eee3dddd3ee3dddd3ee3dddd3ee3dddd3eeee5eee44eeeeeee5eeeeeeeeeeeeeee44eee5eeeeeeeeee
ee00303eee3000eeee3033eeee3303eeee3033eeee3303eeee3333eeee3333eeee3333eeee3333eeeeeeeeeeeeeeeeeeeeeeeeeeeeee5eeeeeeeeeeeeeeeeeee
eeeeeeeeee600eeeeeeeeeeeeee004eeeeeeeeeeee00046eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000
eee00eeeee4440eeeee00eeeee0444eeee000eeee04444eeede66edeeeeeeeeeede66edeeeeeeeee000000000000000000000000000000000000000000000000
ee0440eee0fff0eeee0440eeee042f0ee04440eee024ff0eee6666eeede66edeee6666eeede66ede000000000000000000000000000000000000000000000000
ee0ff0eee08980eeee0420eeee08880ee024f0eee088800eee6565eeee6666eeee6666eeee6666ee000000000000000000000000000000000000000000000000
e089880e085550eee088880eee05588e088880ee085550eeee6666eeee6565eeee6666eeee6666ee000000000000000000000000000000000000000000000000
e0f5550ee05550eee0555f0eee05550ee0555f44e05550eeee6666eeee6666eeee6666eeee6666ee000000000000000000000000000000000000000000000000
e040040ee04040eee040040eee04040e040020e6e04020eee366663ee366663ee366663ee366663e000000000000000000000000000000000000000000000000
e36330eee30303eee303303eee30303e303303eee30303eeee3333eeee3333eeee3333eeee3333ee000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000cccccccc0030000f034444300000030000300000004454304444444400044444444440000000004444000550
bbb3bbbbbbbbbbbbbbb3bbbbbbbbb7bb00e00000cccccccc30ff30ff344444430003343333433000034444404444444404444444444444400000449999440220
bbbbbbbbbbbbb3bbbbbbbabbbbbb797b0e000e00ccccccccffffffff44444544003444444444430004444400535553540355535453555350004494aaa9494220
b3bbbbbbb3bebbbbb3bba9abbbbb373b00404000ccccccccffffffff44444444004444444444440000444400444444444444444444444444049494a9aa494920
bbbbbb3bbbeaebbbbbbb3a3bbb7bbbbb00404000ffffffffdddddddd44444444034444444444443000444430444444444444444444444444249494aaaa494942
bbbbbbbbbb3e3bbbbbbbbbbbb797bbbb00044000ffffffffcccccccc445444440444454444544440034544404444444444444444444444442494a444444a4942
bbbb3bbbbbbbbb3bbbbb3bbbb373bbbb00034300ff03ff30cccccccc0444444000444440044444000444440053535554535355545353555424a4442222444a42
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00333000f0000300cccccccc004444000044440000444400004444004444444444444444444444442444221111224442
00000000000000000000000000000000bbbbbbbbccccff30ffffcccccccccccc0044443003444400030003000000000044444444444444442122111221112212
00000000000000000000000000000000bbbbb3bbccccff003fffcccccccccccc0344444334444430343334330004000044444444444444441111122222211111
00000000000000000000000000000000bbbb3bbbccccfff300ffcccccccccccc0444454444544440444444440004200053555354535553540121224444222210
0000003ff300000000000000000ddd00bb3b3bbbccccfff003ffcccccccccccc0044444444444400544444440004200044444444444444440122441144114210
000033f44f330000000ff00000d66dd0b3bbbbb3ccccff303fffcccccccccccc0044444444444400444445440004230044444444444444440124411114112210
0001424ff4241300001442000d6ddd50b3bbbb3bccccff300fffcccccccccccc0004444444444000444444440004300004444444444444403124411914224210
00142124421241000143441035dd5553bbbbbb3bccccfff003ffcccccccccccc0000040000400000004000400003000003535554535355500314411114444130
00031443044130000030030003555530bbbbbbbbccccffff00ffcccccccccccc0000000000000000000000000000000000044444444440003033033330330303
0000033333300000000330000000000000000000ccccccccccccccccf00000f00000f00f000880000a0a0a00000900000f00f03000f0000000f00f00cccccccc
00003333333300000031b3000000000000000000cccccccccccccccc00ffffffffffff00008782000909090009030900ffffffff0ffffffffffffff0cccccccc
0003a3baab333000033b33100000000000000000cccccccccccccccc0ffddddddddddff0008882000909090003030300ddddddddffddddddddddddffcccccccc
003b3baaaab13300013aa3300000000000000000cccccccccccccccc0fdccccccccccdf008888e200000000000000000ccccccccfccccccccccccccfcccccccc
033a33baab13b33033b4ab3300000ddddddd0000ccccccffffcccccc0fccccccccccccff087822200a0a0a0009000000ccccccccfccccccccccccccffccccccf
0331bb3333bb1130313bb3110000dd6d666dd000cccccffffffccccc0fccccccccccccf0008222000909090003090900ccccccccffccccccccccccffffccccff
033311331311333013bb1b31000ddddddd66dd00ccccffff3fffcccc0fcccccffcccccf0003113000909090003030300ffffffff0ffffffffffffff00fccccf0
01b33333333ab3103113b33100dddddddddd6dd0ccccff333fffcccc0fccccffffccccf0032222300000000000000000f03f000000f00f00000f00000fccccf0
031bb3b333ab11301b3331110055dddddd55ddd0ccccfff333ffccccffccccffffccccff0000000000000000000099000fccccf0ffccccf000ffff000fccccf0
0111113b1311311011b3bb1105555ddd66dd5550ccccfff3ffffcccc0fccccdffdccccf00000000000224444444944000fccccf00fccccf00ffddff00fccccf0
0011b1131333110031333313055dd5d66dd51550ccccdffffffdcccc0fcccccddcccccf00000000002222994999494400fccccf30fccccffffdccdf0ffccccff
0001113133111000031111300151dddddd551550cccccdffffdcccccffccccccccccccf0000000000212222442442240ffccccf00fccccf00fccccf0fdccccdf
00031111111130000032230033151dddd5555133ccccccddddcccccc0fccccccccccccf00000000002212444244441100fccccf00fccccf00fccccffdccccccd
0031421111241300001442000331115555111330cccccccccccccccc0ffccccccccccff00000000001224212222122300fccccf00fccccffffccccf0cccccccc
0314212442124130314344130033331111333300cccccccccccccccc00ffffffffffff000008800033111111111111333fccccff0ffccff00fccccf0cccccccc
0030144304413000033313300000333333300000cc00000000000000000000000000000f000223000033333333333300ffccccf000ffff000fccccffcccccccc
00000000000000000000000000000000000000000000000777000000000000000000000000000000000000000000000000000000000000000044400000000000
00000000044000000000000000444440000000000000007777700000000000000000000000000004440000000000000000000000000000044499400000000000
000000044a400000000000000049499440000000000007777777000000000000000000000000044999440000000000000000000000004449a499400000000000
0000044949400000000000000049499494400000000004777777700000000000004700000004494a9949440000000000000000000044994994aa400000000000
000449494a40000000000000004a4a949494400000000041777777000000000004777000044a4949a949494400000000000000000294994aa444400000000000
0449494a444000000000000000444444a494944000000004177777744400000041777700294949499949494920000000000000000294aa444422200000000000
29494a4442200000000000000022222444a4949200000000417777779a4400041777770029494a4a99494a49200000000555000002a444422211100000000000
294a44422110000000000000000400122444a4920000000004177777794942417777770029494949994949492444444442224440024422211121000000000000
2a444221110000003044330443040011122444a2000000004241777777492417777770002a49494aaa494949249494a492229494022211122224000000000000
244221111000ff000355455555340301111224420000004494941777777941777777000029494a44444a49492494949494949494011122224224000000000000
212111222001442045655565555403022211121200000294949241777714177777700000294a444222444a4924a4a4a4a4a4a4a4001224444421400555555550
1111222420143441466666666654300242221111000002949497141771417777772000002a4442211122444a2444444444444444001144411421400522252225
00122114200300003466566666443002411221000000029494777147141777777920000024422111111122442222222222222222031244111421343544454445
032441142304446003466646643400324114423000000294a7777714477777774920000021211115251111212151151151151111031244111421343555555552
0034411430003660003344344300000341144300000002a477777774417777744a20000011115552225551111155555555555511003144111413033222222223
00003333000000300030030330000000333300000000024777777141741777224420000001155555465655115511661166116651033030333300000333333330
00000000000444000444444444444440000000000000027777771417714171112120000001556666466665515611661156116650000000000000000000000000
00000000444994002949494994949492000000000000077777714177771411511110000001566656666666515611651166116550000000000000000000000000
000004449a499400294a494a9494a49200000000000277777714577777714551112200000155666666655651565566556655665300000000000000000ddd0000
00044994994aa4002949494a9494949200000000002777777145557777771455114420000156666111666651566656666566565000000000000000000d6ddd00
00294994aa4444002a494949a49494920000000002777777145656577777714651444200315556111116665156666666666665330000000000dd000005d66dd0
00294aa4444222002949494994a4949200000000027777714565656577777714513342003156661919165551333333333333330300000000dd66d000055dddd0
002a44442221110029494949949494920000000002777714565666565777777141393200031666111116661330330000003003000000000d666d55003355d553
00244222111010002a4a4a4aa4a4a4a2000000000237774566656666657777771433320000333033333333300000000300000000000000d66ddd550003355530
0022211100402000214444444444441200000000023374156666666666577777774332000004400000055000666666660644446000000d66ddd5550000333300
001116663444200011222222222222110000000002333315665566666665777777733200004444000055550055555555f644446f0000d6ddddd5500003baa330
000135553444230001111111111111100000000002337315666666666666577777333200044444400555555044444444d64c446d000dddd5dd551000033b3b30
0001333334f4230001222222222222100000000004279711566556611665657773332400344444433555555344444c44c644446c00dd6dd15555000001b3b310
003233f33fff433001222441144422100000000004427331566666111166665510324400344ff4433557755344c44444c644446c00dddddd1551000000133100
00343343333343003124241111444213000000000044333116666611916666610034400034ffff433577775344444444c644c46c331ddd555513333004111140
0004333333333000032444111144423000000000000400331166661111666610330400003ffffff33777777366666666f644446f033311111133300003244230
003303033330000000333333333333000000000000000003030333333303033330300000033333300333333055555555f5444450000333333330000000333000
00000000004444000000000000000000000000000000000000000000000440000000000000000000000000000000000000000000000000000000000000000000
00000000449999440000000000000000000000000033000000000000044944400000000000000000000000000000000000000000000000000000000000000000
000005549499a9494400000000000000000000000331300000000000294a44920000000000000000000000000000000000000000000000000000000000000000
00004224949999494944000000000dd6d000000003bb3300000000002a4444920000000000000000000000000000000000000000000000000000000000000000
00449224a49a99494949440000005ddd66d00000313ab33000000000244224420000000000000000000000000000000000000000000000000000000000000000
0494929494999a4a494a4940000555d66ddd000033a43b3000333300222112220000000000000000000000000000000000000000000000000000000000000000
24a494a49499994949494942000ddd5dddd6d000313bb31103bab130111001110000000000000000000000000000000000000000000000000000000000000000
24949494949999494a49494200dddddddddd600013bb1b3113a11b31106666010000000000000000000000000000000000000000000000000000000000000000
2494949494aaaa49494949420055dddddd55dd000113b331313b33b1465555640000000000000000000000000000000000000000000000000000000000000000
2494a494a444444a49494a4200155dddd6dd5500013331113b113b31455355540000000000000000000000000000000000000000000000000000000000000000
249494a4442222444a494942000155d66dd515000013bb1113b33311655553560000000000000000000000000000000000000000000000000000000000000000
2494a44422111122444a494200315ddddd5515100013331301211110561111650000000000000000000000000000000000000000000000000000000000000000
24a444221111111122444a4233311dddd55551330001112034211100556666550000000000000000000000000000000000000000000000000000000000000000
24442211115555511122444203331155551113300303224032420000355555530000000000000000000000000000000000000000000000000000000000000000
21221112225555222111221200333311113333000334144444344330035555300000000000000000000000000000000000000000000000000000000000000000
11111521212665442222111100003333333300000033331330033300303333030000000000000000000000000000000000000000000000000000000000000000
01155211211466444442511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01556411411466555555551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01566444444466661166511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01566411411466611115651000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01566411411465519116651000000000000000000000fff00fff0000000000000000000000000000000000000000000000000000000000000000000000000000
33166444444466611116613000000000000000000003444034440000000000000000000000000000000000000000000000000000000000000000000000000000
03356666666666644446530300000000000000000034344444344300000000000000000000000000000000000000000000000000000000000000000000000000
03033303303300333333303000000000000000000033030330033300000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454566
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056
7546464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464676
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111000000000000000101010101010011111100000001000001010101010101111111110100001111111101010101011111111100010111111111
0101010101010101010101010101010101010101010101010101010101010100010101010001010101010101010101010101010100010101010101101001010101010101010101010000000000000000010101010101010100000000000000000101010000010100000000000000000000000000000101000000000000000000
__sfx__
0001000002171041510414106131091210b1110e1110c60106601036010260103601066010a601136011360112601126011260112601176010060100601006010060100601006010060100601006010060100601
000100000f12113121101111c6300e6300a6300a6200a6200a6200a6100a61009620096100a6001000004000280001f0001200005000000000000000000000000000000000000000000000000000000000000000
000100001a0201a0201a0202800007000030000300003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000080700a0700c0500d05018040150400704007030060200602005050050500405003050020500003000020000000000000000000000000000000000000300003000030000300003000030000300003000
0103000017613176130b6130b6330b6430b6630a6430a623046230462304623046130461304613026130c6030c6030c6030c6030c6030c6030c6030c6030c6030c6030c6030b6030b6030a6030a6030b60300603
000200000e8500f85000830008201682017850048200582004820128200c8500a8500080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800
010a00001f55023550265500d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d2000d200
000400001f732207322873231732347322173229732367322c7321f732207321f73225732327323173221732207322573226732277320e7020e7020e7020e7020e70210702007020070200702007020070200702
012b00000d6140d6100c6200c6200c6200b6200b6200a6200b6200b6200b6200b6200b6200b620006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
010400000e5300e530295001a5301a530255000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010400001a5301a530295000e5300e5300e5000e50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
006400000061402611046110761107611096110961106611036150660006600056000460003600026000160001600016000160004600056000460007600076000960009600066000360000000000000000000000
007800000461405611046110761500600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000000000000
00640000006140261104611056110061104611076110d61113611186111b611186110f6110b611056150000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000025322263322532235302353023130233322333223433231322323022e3022c30200302003020030200302003022432224332243220030200302333223333235322003020030200302003020030200302
000400002d73031730327302b7302b730327302573035730217301c7301b730127301b7301f7302373024730167300f7300b73000000000000000000000000000000000000000000000000000000000000000000
000300001312013120131200b1200b1200b1201910019100191001910019100181000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
010400000e5370e53729e070e5370e53700e071ae371ae371ae371ae371ae371ae371ae371ae371ae371ae371ae371ae371ae371ae371ae371ae371ae371ae371ae371ae271ae271ae271ae171ae171ae171ae17
011000000d2340d2320d2310d2210d2220d2210d2310d2320d2220d2150d2000d2020d2010d2010d2020d2010d2010d2020d2010d2010d2020d2020d2020d2010d2010d2020d2020d2010d2010d2020d20500000
0104000019750197501d7501775016750147501475019750227502275022750007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000300001c75012750107500e7501b7501b750147501e7501c7501f7501575224752207522630200302107521575210752197523330233302333023330232302303022e3022c3022a30227302263020030200302
002d000010234102250d2000d2010c2010c2010c2010c2010c2050020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
0102000017613176130b6130b6230b6330b6530a6330a623046230462304623046131c6031c6031a6030c6030c6030c6030c6030c6030c6030c6030c6030c6030c6030c6030b6030b6030a6030a6030b60300603
0004000014750197501d750197502575024750197501f750177501175013750117501970022700227000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01f000002345424450244550050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000000000000
01f000001745418450184550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01f000000b1540c1500c1550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001e0001f0001f0001f00020000200002000020000200001f0001f000120001200012000120001200012000120001200012000120001b0001d0001d0001d0001d0001d0001d0001d0001d0001d0001d000
__music__
00 3c3d3e44
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
00 41424344
00 41424344
00 41424344
00 41424344
__label__
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
4aaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaacc0000cccccccc0000cccccccccccccccaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaacc0000cccccccc0000cccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaa00777700cccc00777700cccccccccccccaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaa00777700cccc00777700cccccccccccccaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaa00777700cccc00777700cccccccccccccaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaa00777700cccc00777700cccccccccccccaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaa00777700cccc0077770000cc0000cccc0000aaaaaa0000aaaaaaaa00000000cccccc00000000cc00000000caaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaa00777700cccc0077770000cc0000cccc0000aaaaaa0000aaaaaaaa00000000cccccc00000000cc00000000caaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaa00777777000077777777770077770000777700aa00777700aaaa007777777700cc0077777777007777777700aaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaa00777777000077777777770077770000777700aa00777700aaaa007777777700cc0077777777007777777700aaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaa007777000077770077770077770000777700aa00777700aa00777777777700007777777777007777777700aaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaa007777000077770077770077770000777700aa00777700aa00777777777700007777777777007777777700aaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaa007777000077770077770077770000777700aa0077777700007777000000cc00777700000000777700777700aaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaa007777000077770077770077770000777700aa0077777700007777000000cc00777700000000777700777700aaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaa0077777777777700777700777700007777000077777777000077770000000000777777777700777777777700aaaaaaaaaaaaaaaaa4
4caaaaaaaaaaaaaaaaaaaa0077777777777700777700777700007777000077777777000077770000000000777777777700777777777700aaaaaaaaaaaaaaaac4
4caaaaaaaaaaaaaaaaaaaaaa007777777700007777007777000077770000777777777700777700007777007777000000007777777700aaaaaaaaaaaaaaaaaac4
4ccaaaaaaaaaaaaaaaaaaaaa007777777700007777007777000077770000777777777700777700007777007777000000007777777700aaaaaaaaaaaaaaaaacc4
4ccaaaaaaaaaaaaaaaaaaaaa00777777770000777700777777007777770077770077770077777777777700777777777700777700777700aaaaaaaaaaaaaaacc4
4cccaaaaaaaaaaaaaaaaaaaa00777777770000777700777777007777770077770077770077777777777700777777777700777700777700aaaaaaaaaaaaaaacc4
4cccaaaaaaaaaaaaaaaaaa440077777777000077770077777700777777007777007777000077777777770000777777770077770077770044aaaaaaaaaaaaccc4
4ccccaaaaaaaaaaaaaaaaa440077777777000077770077777700777777007777007777000077777777770000777777770077770077770044aaaaaaaaaaaaccc4
4ccccaaaaaaaaaaaaaaaaa444444777744444444444444444444444444444444444444444444444477774444444444444444444444444444aaaaaaaaaaacccc4
4cccccaaaaaaaaaaaaaaaa444444777744444444444444444444444444444444444444444444444477774444444444444444444444444444aaaaaaaaaaacccc4
4cccccaaaaaaaaaaaa55aaaa4444777744444444cccc4444cc444444444444aaaa444444444444447777444444cc4444444444444444aaaaaaaaaaaaaaccccc4
4cccccaaaaaaaaaaaa55aaaa4444777744444444cccc4444cc444444444444aaaa444444444444447777444444cc4444444444444444aaaaaaaaaaaaaaccccc4
4ccccccaaaaaaaaaaaaaaaaaaa4444444444cccccc55ccccccccccccaaaaaa55aaaaaa4444cccc44444444cccccccccccc44ccaaaaaa55aaaaaaaaaaacccccc4
4ccccccaaaaaaaaaaaaaaaaaaa4444444444cccccc55ccccccccccccaaaaaa55aaaaaa4444cccc44444444cccccccccccc44ccaaaaaa55aaaaaaaaaaacccccc4
4cccccccaaaaaaaaaaaaaa55aaaccc4444cccccccccccccc55ccccccaaaaaaaaaaaaaaaaaccccccc4444cccccc55ccccccccccaaaaaaaaaaaaaaaaaaccccccc4
4cccccccaaaaaaaaaaaaaa55aaaccc4444cccccccccccccc55ccccccaaaaaaaaaaaaaaaaaccccccc4444cccccc55cccccccccaaaaaaaaaaaaaaaaaaaccccccc4
4ccccccccaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccaaaaaaaaaaaaaaaa55cccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaccccccc4
4ccccccccaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccaaaaaaaaaaaaaaaa55cccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaacccccccc4
4cccccccccaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaacccccccc4
4cccccccccaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaccccccccc4
4ccccccccccaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaccccccccc4
4ccccccccccaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaaacccccccccc4
4cccccccccccaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaacccccccccc4
4cccccccccccaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaccccccccccc4
4cccccccccccaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaccccccccccc4
4ccccccccccccaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaacccccccccccc4
4ccccccccccccaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaacccccccccccc4
4cccccccccccccaaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaaaaaccccccccccccc4
4cccccccccccccaaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaaaaaccccccccccccc4
4ccccccccccccccaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaaaaaccccccccccccc4
4ccccccccccccccaaaaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaaaacccccccccccccc4
4cccccccccccccccaaaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaaaaacccccccccccccc4
4cccccccccccccccaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaaaaccccccccccccccc4
4ccccccccccccccccaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaaaaccccccccccccccc4
4ccccccccccccccccaaaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaaacccccccccccccccc4
4cccccccccccccccccaaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaaaacccccccccccccccc4
4cccccccccccccccccaaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaaaccccccccccccccccc4
4ccccccccccccccccccaaaaaaaaaaaaaccccccccccccccccccccccccccaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaaaccccccccccccccccc4
4ccccccccccccccccccaaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaacccccccccccccccccc4
4ccccccccccccccccccaaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaaccccccccccccccccccccccccaaaaaaaaaaaaaacccccccccccccccccc4
4cccccccccccccccccccaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaaccccccccccccccccccccccccaaaaaaaaaaaaaacccccccccccccccccc4
4cccccccccccccccccccaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaaccccccccccccccccccccccccaaaaaaaaaaaaaccccccccccccccccccc4
4ccccccccccccccccccccaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaaccccccccccccccccccc4
4ccccccccccccccccccccaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaccccccccccccccccccccccccaaaaaaaaaaaaacccccccccccccccccccc4
4cccccccccccccccccccccaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaccccccccccccccccccccccccaaaaaaaaaaaaacccccccccccccccccccc4
4cccccccccccccccccccccaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaccccccccccccccccccccccccaaaaaaaaaaaaccccccccccccccccccccc4
4ccccccccccccccccccccccaaaaaaaaaaaaccccccccccccccccccccaaaaaaaaaaaaaaaaaaaccccccccccccccccccccaaaaaaaaaaaaccccccccccccccccccccc4
4ccccccccccccccccccccccaaaaaaaaaaaaccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccaaaaaaaaaaaacccccccccccccccccccccc4
4cccccccccccccccccccccccaaaaaaaaaaacccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccaaaaaaaaaaaacccccccccccccccccccccc4
4cccccccccccccccccccccccaaaaaaaaaaacccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccaaaaaaaaaaaccccccccccccccccccccccc4
4ccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccc4
4ccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccc4
4ccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccc4
4cccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccc4
4cccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccc4
4cccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccc4
4cccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccc4
4cccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc4
4cccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccc4
4cccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccc4
4ccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccc4
4ccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccc4
4acccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccc4
4aacccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccca4
4aaccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaa4
4aaacaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000aaaa000000000aaaa00000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa007777700aaa077700770aaa007707770777077707770aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa077070770aaa007007070aaa070000700707070700700aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa077707770aaaa07007070aaa07770070077707700070aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa077070770aaaa07007070aaa00070070070707070070aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa007777700aaaa07007700aaa07700070070707070070aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000aaaaa0000000aaaa0000a000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa4
45555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555554
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44fff4f4f44444fff4fff4fff4fff4ff44fff4ff444ff4444444444444444444444444444444444fff4fff4ff44fff44444f4f4fff4fff4f4f444444ff4ff444
44f4f4f4f44444f4f4f4f4f4f44f44f4f4f4f4f4f4f4f4444444444444444444444444444444444fff4f4f4f4f4f4444444f4f44f444f44f4f444444fffff444
44ff44fff44444fff4fff4ff444f44f4f4fff4f4f4f4f4444444444444444444444444444444444f4f4fff4f4f4ff444444f4f44f444f44fff444444fffff444
44f4f444f44444f444f4f4f4f44f44f4f4f4f4f4f4f4f4444444444444444444444444444444444f4f4f4f4f4f4f4444444fff44f444f44f4f4444444fff4444
44fff4fff44444f444f4f4f4f44f44f4f4f4f4f4f4ff44444444444444444444444444444444444f4f4f4f4fff4fff44444fff4fff44f44f4f44444444f44444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444