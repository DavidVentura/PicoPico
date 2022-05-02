pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
function _init()
 game_init()
 s_con=0
 d_con=0
end

function _draw()
 if d_con==0 then
  cls()
  print(":| dices :|",43,61,7)
  print("press X",48,91,7)
 end
 if s_con==0 then
  sfx(6)
  s_con=1
 end
 if btnp(5) or btnp(4) then
  d_con=1
 end
 if d_con==1 then
  if s_con==1 then
   sfx(-1)
   s_con=2
  end
  game_draw()
 end
end

function _update()
 game_update()
end

-->8
--game play
dice_count=-1
dice_count_num=0
function game_init()
 
end

function game_draw()
 if btnp(5) and con==1 then
  dice_count=dice_count+1
 end
 ground_draw()
 dice_drop_draw()
 next_draw()
 dice_move_draw()
 hold_draw()
 score_draw()
 full_draw()
 --line(23,48,23,48,14)
end
kd_x=0
function game_update()
 if dice_count>=3 or dice_count==-1 then
  random_dices()
  dice_count = 0
 end
 dice_drop_update()
 next_update()
 dice_move_update()
 next_to_move()
 hold_update()
 full_update()
 score_update()
 enemy_update()
 if score>=25536 then
  cls()
  print("win!!!nb!nb!nb!")
 end
 if btnp(5) and con==1 then
  dice_count_num=dice_count_num+1
  kd_x=score/dice_count_num
  kd=flr(kd_x*100)/100
 end
end

leap_y=0
function ground_draw()
 cls(1)
 print("next☉:",22,6,7)
 print(">>",28,19,7)
 rect(21-17,48-17,21,48)
	rect(22,31,21+82,31+81,11)
	rect(22,31,21+82,31+17,8)
	rect(22+16,31-18,22+80-15,30,11)
	line(110,31,110,112,7)
	line(108,31,112,31,7)
	line(108,112,112,112,7)
	circfill(110,lerp_y,2)
end

next_dice_table={}
function random_dices()
 for i=1,12 do
  dice_next=flr(rnd(6))+1
  add(next_dice_table,dice_next)
  i=i+1
 end
end
function next_update()
 n1,n2,n3,n1_x,n2_x,n3_x=0,0,0,0,0,0
	n1=next_dice_table[1]
	n2=next_dice_table[2]
	n3=next_dice_table[3]
	n1_x=8*n1
	n2_x=8*n2
	n3_x=8*n3
end
function next_draw()
 sspr(n1_x,0,8,8,22+17,31-17,16,16)
 sspr(n2_x,0,8,8,22+17+16,31-17,16,16)
 sspr(n3_x,0,8,8,22+17+32,31-17,16,16)
end

dice_x,dice_y=55,32
function dice_move_update()
 if btnp(5) and con==1 then
  dice_x,dice_y=55,32
 end
 if btnp(2) and pget(dice_x-4,dice_y+1)==1 then
  dice_x=dice_x-16
  sfx(0)
 elseif btnp(3) and pget(dice_x+24,dice_y+1)==1 then
  dice_x=dice_x+16
  sfx(0)
 elseif btnp(1) and pget(dice_x,dice_y+24)==1 then
  dice_y=dice_y+16
  sfx(0)
 elseif btnp(0) and pget(dice_x,dice_y-4)==1 then
  dice_y=dice_y-16
  sfx(0)
 end
 
 if dice_x<=22 then
  dice_x=dice_x+16
  sfx(2)
 elseif dice_x>=22+16*5 then
  dice_x=dice_x-16
  sfx(2)
 elseif dice_y<=30 then
  dice_y=dice_y+16
  sfx(2)
 elseif dice_y>=32+16*5 then
  dice_y=dice_y-16
  sfx(2)
 end
end

function dice_move_draw()
 sspr(dice_now,0,8,8,dice_x,dice_y,16,16)
end

dice_first=0
function next_to_move()
 if dice_first==0 then
   dice_now=8*(flr(rnd(5))+1)
   dice_first=1
 end
 if btnp(5) and con==1 then
  dice_now=n1_x
  deli(next_dice_table,1)
 end
end

dice_droped={}
dice_num_arr={}
arr_row1={0,0,0,0,0}
arr_row2={0,0,0,0,0}
arr_row3={0,0,0,0,0}
arr_row4={0,0,0,0,0}
dice_num_arr[1]=arr_row1
dice_num_arr[2]=arr_row2
dice_num_arr[3]=arr_row3
dice_num_arr[4]=arr_row4
function dice_drop_update()
 con=0
 con=condition()
 if btnp(5) and con==1 then
  pad_x=(dice_x-23)/16+1
  pad_y=(dice_y-48)/16+1
  dice_num_arr[pad_y][pad_x]=dice_now/8
  add(dice_droped,dice_now)
  add(dice_droped,dice_x)
  add(dice_droped,dice_y)
  sfx(1)
 end
end

function dice_drop_draw()
 if #dice_droped >=1 then
  for i=0,#dice_droped/3 do
   sspr(dice_droped[i*3+1],0,8,8,dice_droped[i*3+2],dice_droped[3*i+3],16,16)
  end
 end
end

function condition()
 local condition=0
 if pget(dice_x-1,dice_y+1)==11 or pget(dice_x+16,dice_y+1)==11 or pget(dice_x,dice_y+16)==11 or pget(dice_x-4,dice_y)==7 or pget(dice_x,dice_y-4)==6 or pget(dice_x+24,dice_y)==7 or pget(dice_x,dice_y+24)==6 then
  condition=1
 end
 return condition
end
function hold_draw()
 print("hold♥:",0,25,7)
 sspr(hold_x,0,8,8,5,32,16,16)
end

c=0
hold_time=0
function hold_update()
 if btnp(4) and hold_time==0 then
  if pget(8,32)==1 then
   hold_x=dice_now
   dice_now=n1_x
   deli(next_dice_table,1)
  elseif pget(8,32)==6 then
   printh(pget(8, 32))
   c=hold_x
   hold_x=dice_now
   dice_now=c 
  end
  hold_time=1
 end
 if btnp(5) and con==1 then
  hold_time=0
 end
end

score=0
kd=0
function score_draw()
 print("score✽:",90,1,7)
 print(score,90,8,12)
 print("score/dice",89,15,8)
 print(kd,90,22,8)
end

row_full1,row_full2,row_full3,row_full4=1,1,1,1
function full_draw()
 
end

function isintable(tbl)
 local row_full=0
 for i,v in ipairs(tbl) do
  if v == 0 then
   row_full=0
   return row_full
  end
 end
 row_full=1
 return row_full
end

function full_update()
 row_full1=isintable(arr_row1)
 row_full2=isintable(arr_row2)
 row_full3=isintable(arr_row3)
 row_full4=isintable(arr_row4)
end

-->8
--score count
function score_update()
 if row_full1==1 then
  score_row_count(arr_row1)
  remove(48)
  row_full1=0
  arr_row1[1]=0
  arr_row1[2]=0
  arr_row1[3]=0
  arr_row1[4]=0
  arr_row1[5]=0
 elseif row_full2==1 then
  score_row_count(arr_row2)
  remove(64)
  row_full2=0
  arr_row2[1]=0
  arr_row2[2]=0
  arr_row2[3]=0
  arr_row2[4]=0
  arr_row2[5]=0
 elseif row_full3==1 then
  score_row_count(arr_row3)
  remove(80)
  row_full3=0
  arr_row3[1]=0
  arr_row3[2]=0
  arr_row3[3]=0
  arr_row3[4]=0
  arr_row3[5]=0
 elseif row_full4==1 then
  score_row_count(arr_row4)
  remove(96)
  row_full4=0
  arr_row4[1]=0
  arr_row4[2]=0
  arr_row4[3]=0
  arr_row4[4]=0
  arr_row4[5]=0
 end
 if btnp(5) and con==1 then
  score_count()
 end
end
score_row=0
score_row_count_num=0
function score_row_count(arr_row)
 local difference={}
 
 for i,v in ipairs(arr_row) do
  if v == 7 then
   sfx(5)
   goto skip
  end
 end
 
 for i=#arr_row,2,-1 do
  add(difference,arr_row[i]-arr_row[i-1])
 end
 for i=1,3 do
  if difference[i]==1 or difference[i]==-1 or difference[i]==0 then
   if difference[i]==difference[i+1] then
    score_row_count_num=score_row_count_num+3
   end
  end
 end
 ::skip::
 score_row=score_row_count_num*10
end

score=0
function score_count()
 score=score+score_row
 score_row=0
 score_row_count_num=0
end

function remove(row_y)
 for i=3,#dice_droped,3 do
  if dice_droped[i]==row_y then
   deli(dice_droped,i-2)
   deli(dice_droped,i-2)
   deli(dice_droped,i-2)
  end
 end
 for i=#dice_droped,3,-3 do
  if dice_droped[i]==row_y then
   deli(dice_droped,i-2)
   deli(dice_droped,i-2)
   deli(dice_droped,i-2)
  end
 end
end
-->8
--enemy
enemy_speed=1
speed_level=0
function enemy_update()
 enemy_speed=1
 speed_level=flr(score/90)
 if speed_level<1 then
  speed_level=1
 end
 enemy_speed=enemy_speed*(16/speed_level)
 
 timer2 = 1 - abs(time()/enemy_speed % 2 - 1)
 lerp_y=lerp(31,112,timer2)
 interference()
end

timer2=0
function timer()
 timer2 = 1 - abs(time()/2 % 2 - 1)
end

function lerp(a,b,t)
  return a + (b-a)*t
end

function interference()
 if lerp_y==31 or lerp_y==112 then
  next_dice_table[3]=7
  sfx(4)
 end
end

-->8
--init
__gfx__
00000000067777700677777006777770067777700677777006777770077777700000000000000000000000000000000000000000000000000000000000000000
00000000667777776cc77777688777776cc77cc7688778876cc77cc7677777770000000000000000000000000000000000000000000000000000000000000000
00700700677887776777777767788777677777776778877767777777677777770000000000000000000000000000000000000000000000000000000000000000
0007700067788777677777776778877767777777677887776cc77cc7677777770000000000000000000000000000000000000000000000000000000000000000
000770006777777767777cc7677778876cc77cc76777777767777777677777770000000000000000000000000000000000000000000000000000000000000000
007007006777777767777cc7677778876cc77cc76887788767777777677777770000000000000000000000000000000000000000000000000000000000000000
0000000066777777667777776677777766777777628778876dc77cc7677777770000000000000000000000000000000000000000000000000000000000000000
00000000066666600666666006666660066666600666666006666660066666600000000000000000000000000000000000000000000000000000000000000000
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmdddmddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmdddddmdddddmdddddddddddddmddd
ddddmdmdmdmdddddddddddddmddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddmmddddddddmddddddmdddddddddddddddmdmdddddddddddddddmddddddddddddmdddddddddmdmddmdddddmddddddddddddmdmdddddddddd
mdmdddddmdddddddddddddddmddddddddmdddmddddddddddddddmdmddddddddmdddmddmdddmmddddmdddddmmmmdddddddddddmddmdddddddddddddddddmddddd
mdddddmdddddddddddddddddmddddddddddmdddmddddddddmmddmmddddddddddddddmddddddddmdddmmmdddddmddddmdddddddddddmmddddddmddddddmddmddd
dmdddddddmdddmddddddmddddddmmddmmddmddddddmddddddddddddmddmddddddmdddmdddddddddmdmmdmdddddddddddddddddddddddddmdddddddmdddmddddd
ddmdmmddmddddddmdddmdmddddmddddddddddddddmmddddmdddddddddddddddddddmddddmmdddmmddddddddddddmdddddmdddddddddddddddddmdddddddmdmdd
ddddmmdmddmdmdddddddddmddddddmdmdmdddddddddddddddddddddmmmmdddmddddmdmdddmdmdmdddddddddmdmddmdddddddddddddddmdmdddddddddddmdmddd
ddddmmdddddmdddddddmddmddddmdmddmdddddmdddddmdddddddddddmddddddmddddddmdmmdddddddddddddddddddddmddddddddddddmddddddmmddddddmmmmd
dmmmdddddddmdddddmddmmddddddmdddddmdddddddddddddmdmmdddmdddmmdddddddddmdddddmddddddddmddddmdmddmdmmdddmdddddddddddddmmdddddddddm
mmddddddddddddddddddddddmddddddmddddddddddddmdmddddddddddddmddmmddddddddddddddddddmdddddddddddmddmddmdddddmdmdddmdmdddmdddmdddmm
ddmmddmdddmddddmdmdmdddddmmdmmdmdmdddmdmdddmmdddddddddddmdddddmddmdmddddmdddddddddmmddddmmdmdddddddddddddddmmdddddmmdddmmdmddddd
ddddmddddddddddddddmmddddddmddddddmdddmddddddmddddddddddmdddmdddmmdmmdddmddddddddddmdddddddddddddddmddddmdddmddmddddddmddddmmddd
dddddmddmddmdmdddmdddddddddddddddddmdddddmdddddddmdddddmdmdddddddmddddddmddddddddddddddddmddddddmddmmdddddddddddddddddmdddmddddd
ddmddddddddddmddddmddddmddddddddddddddddddmdddddmddmddmddddmmddddmddmdddddddmddddmmddddddddmmmdddddmddddmdmdmdmddddmmddddmdmdmdd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__sfx__
000100001d0501e0501e0501f05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000250502505025050260502605027050290502d05032050380503f0503f0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001405014050140500d050050500105000000000001a0001a0001a0001a0001a00015000110000f0000c0000b0000900008000070000600005000050000500004000040000400004000040000400005000
000100000000015050150501405014050140500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000033650306502f6502f6503065033650366503e6502665027650296502b6502f650366503d6503120031200312003220032200322003320033200342003b2003b2003c2003c2003c2003d2003e2003e200
00010000304702c47028470244701f4701a47016470114700e470324702c4702947025470214701f4701a47016470124700f4700f470004000040000400004000040000400004000040000400004000040000400
00100000110501605015050100500d0500d050100501505015050120500d0500b0500d0501105015050180501805015050100500e05010050130501605016050110500d0500c0500d05010050130501505013050
