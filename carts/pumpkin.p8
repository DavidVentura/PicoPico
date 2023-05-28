pico-8 cartridge // http://www.pico-8.com
version 12
__lua__
--pumpking
--sophie houlden

--i have commented the code as
--best i can, but if you have
--any questions feel free to
--ask me on twitter: @s0phieh
--(the '0' in s0phieh is a zero)

-----------------------------

--this tab of code is where i
--prepare all the variables
--that the game will use

--no functions here

-----------------------------

--animations - each one is
--a list of sprites

--player animations
idleanim ={1}
runanim ={1,2,1,3}
riseanim ={2}
fallanim ={3}
deadanim ={1,19}
winanim ={53}

--enemy animations
batflap = {4,5,6}
ghostanim = {7,8}
skelwalk = {9,10,11}
spikeranim={34,35,36,36,36,36,36,37,34,33,33,33,33,33,33,33,33,33}
blobblob={26,27,26,28}
lavaanim={38,39,40,41,40,39}
sludgeanim={54,55,56,57,56,55}
witchcast={43,43,43,43,43,43,43,43,44,45,45,45,46,47}
witchspell={59,60,61,62}

--object animations
keyanim={16}
keywallanim={119}

checkstill={48}
checkanim={48,49,50,51,50,49}
lifeanim={52}

coinspin = {12,13,14,15}
crownanim={17}

--particle animations
boneparticle = {20,21,22}
bloodparticle = {23,24,25}
blobsplat={29,30,31}
sludgebubble={32}
spewanim={94,95,110,111}
shellanim={120,121,126,127}


--camera things
camx=0
camy=0
camytarget=0
camoff=0

--boss object reference
boss={}
--list of actors
actors={}
--list of ai rebound objects
rebounds={}

--game stuff
gametime=600 --time remaining
starttime=600
score=0
checkx=0 --checkpoint position
checky=0
lives=3

--every 30 frames is a second
--so to count seconds, we count
--frames first
framecount=0

--counter we use to flash things
titleflash=10

--count with this to change
--animation frames
animcount = 0

--'big' stuff like what screen
--to show and what the game
--state is/when to change it
won=false
dead=false
screen="title"
gamefrozen=false
transitiontime=0
playtime=0
level=1

--values that get shown only on
--the game over screen
finallives=0
finaltime=0

--a reference to where the
--player is in the actors list
--so we can quickly find it
playerindex=0

--a list of patrons who support
--me so i can credit them on
--the title screen
patrons={"tim monks","robert mock","shane doyle","jake hadley","vincent markusse","edmund lewry","terry","edderiofer he","mistodon","miles ranisavljevic","amazing stace","lee","malcolm brown","norgg","weeble wilson","herve jolly","michael","max","harry danby","marcelo perez","dorian beaugendre","israel storey","dustin mckenzie","davio cianci","willem jager","michael adams","aeronic","alex mole","nerdi","sigurdur finnsson","dora breckinridge","claire","josh mathews","hodge","kris kauffman","arcadely","neil","elliott davis","dave reed","francis fernandez","alan hazelden","jonathan wright","andrew thorpe","ed key","oliver","kleril","thomas shea","lax","jamie","luke robinson","c","gkr","mike watson","stephen stagg","ronja bohringer","calum grace","keith evans","eric schwarzott","daniel cassidy","drew messinger-michaels & lauren villegas","evan gale","luke","oscar paterson","chris hudson","dan sanderson","colin strong","derek carroll","ian badcoe","alex taylor","cian booth","toby","royce rogers","fred alger","clarity","piano inky","perplamps","connor sherlock","alice robinson","richard fabian","agent v","thegamedesigner","le-roy karunaratne","greg v.","hayden scott-baron","vorundor","jeremy oduber","ian walker","chris","dan stott","stacy read","rav","david green","ed","kemp","sarah mccormack","gregory avery-weir","cool ghosts","stingingnettle","malky","...and you!"," "}
patronindex=1

-->8
--game beginning and ending

-----------------------------

--functions here:
--  _init()    begingame()
--  die()      win()
--  timeout()

-----------------------------

--the _init() function is the
--first one pico-8 runs
function _init()
 --spawn all actors (tab 2)
 spawnactors()
 --begin a new game
 begingame(true)
 --display title screen
 screen="title"
 --play the title screen music
 music(0)
end

--function to begin a game
--called for a new game, or
--when respawning after a death
function begingame(newgame)
 
 if newgame then
  --if this is a new game then
  --reset our game progress
  checkx=0
  checky=0
  lives=5
  score=0
  gametime=starttime
  level=1
 end
 
 --initialise our actors (tab 2)
 initactors(newgame)
 
 camx=0
 camy=0
 camytarget=0
 camoff=0
 
 screen="game"
 gamefrozen=false
 dead=false
 won=false
 
 playtime=0
 framecount=0
end

--we call this function to lose
--a life, freeze the game and
--show the player die
function die()
 if (dead) return--one death at a time
 
 --death sound effect
 sfx(1)
 --lose a life
 lives-=1
 --freeze the game
 gamefrozen=true
 --show death animation
 actors[playerindex].anim=deadanim
 
 --begin a transition count
 --this is checked in _update()
 transitiontime=0
 
 --mark the player as dead
 dead=true
 
 --make a record of lives/score
 --to show on game over screen
 --in case we lost all our lives
 finallives=lives
 finaltime=gametime
end

--function called when a player
--touches the crown actor
--freezes the game and shows win
--animation
function win()
 if (won) return
 
 --freeze game + mark it as won
 gamefrozen=true
 won=true
 
 --show player win animation
 actors[playerindex].anim=winanim
 
 --begin a transition count
 transitiontime=0
 
 --make record for win screen
 finallives=lives
 finaltime=gametime
end

--function called when player
--runs out of time
--like the die() function but
--doesn't care about lives
function timeout()
 if (dead) return
 
 --play the time up sound effect
 sfx(7)
 --freeze the game
 gamefrozen=true
 --show death animation
 actors[playerindex].anim=deadanim
 
 --begin a transition count
 transitiontime=0
 
 --mark player as dead
 dead=true
 
 --record lives/score for game
 --over screen
 finallives=lives
 finaltime=gametime
end
-->8
--actor spawning/initialisation

-----------------------------

-- here is where we spawn actors
-- (check map for actors and
-- then create them) and we also
-- initialise them here (set
-- all actor's initial settings)

-- actors are objects which get
-- added to the 'actors' list

-- they either do stuff on their
-- own, or are acted upon by
-- other actors

--functions here:
-- spawnactors()  addactor()
-- addparticle()  initactors()

-----------------------------

--find all actors we want in the
--map and spawn them
function spawnactors()
 --for every tile in the map
 for x=0,160 do
 for y=0,80 do
  --get the tile type
  tilenum=mget(x,y)
  
  --from here, create actors
  --based on what type of tile
  --we just found
  
  if tilenum==1 then
   addactor("player",x,y)
   playerindex=#actors
  end
  
  if tilenum==4 then
   addactor("bat",x,y)
  end
  
  if tilenum==7 then
   addactor("ghost",x,y)
  end
  
  if tilenum==9 then
   addactor("skeleton",x,y)
  end
  
  if tilenum==12 then
   addactor("coin",x,y)
  end
  
  if tilenum==16 then
   addactor("key",x,y)
  end
  
  if tilenum==118 then
   addactor("keyhole",x,y)
  end
  
  if tilenum==119 then
   addactor("keywall",x,y)
  end
  
  if tilenum==90 then
   addactor("pewking",x,y)
  end
  
  if tilenum==91 then
   bossx_b = x*8
   mset(x,y,0)
  end
  if tilenum==92 then
   bossx_c = x*8
   mset(x,y,0)
  end
  
  if tilenum==18 then
   addactor("airebound",x,y)
  end
  
  if tilenum==33 then
   addactor("spiker",x,y)
  end
  if tilenum==35 then
   addactor("coin",x,y)
   addactor("spiker",x,y)
  end
  if tilenum==34 then
   addactor("spikertop",x,y)
  end
  
  if tilenum==26 then
   addactor("blob",x,y)
  end
  
  if tilenum==38 then
   addactor("lava",x,y)
  end
  
  if tilenum==54 then
   addactor("sludgeb",x,y)
  end
  if tilenum==55 then
   addactor("sludge",x,y)
  end
  
  if tilenum==43 then
   addactor("witch",x,y)
  end
  if tilenum==44 then
   addactor("witchf",x,y)
  end
  
  if tilenum==48 then
   addactor("checkpoint",x,y)
  end
  
  if tilenum==52 then
   addactor("life",x,y)
  end
  
  if tilenum==17 then
   addactor("finish",x,y)
  end
  
 end
 end
 
end

--add a new actor
function addactor(typ,x,y)
 --create a new actor at x,y
 a={}
 a.typ=typ
 a.startx=x*8
 a.starty=y*8

 --add actor to the actors list
 if (typ!="airebound") add(actors,a)
 
 --add rebound to rebounds list
 if (typ=="airebound") add(rebounds,a)
 
 --clear the map at x,y unless
 --we want the actor drawn
 --as part of the background map
 if (typ!="keyhole") mset(x,y,0)
end

--add a new particle
--this is a special case of
--adding a new actor and
--initialising it at the same
--time
--particles are unique because
--they initialise only once and
--have a limited life before
--being removed from the game
function addparticle(typ,x,y)
 a={}
 a.typ="particle"
 a.ptype=typ
 a.startx=x
 a.starty=y
 a.x=x
 a.y=y
 a.fx=(rnd()-0.5)*2
 a.fy=-(rnd()*2)-1
 a.life=100
 a.frame=1
 if (rnd()<0.5) a.frame+=1
 --default particle is bones
 a.anim=boneparticle
 
 --randomly flip the particle
 if (rnd()<0.5) a.flipped=true
 
 --boss damage particle
 if typ=="pewshell" then
  a.anim = shellanim
  a.fx*=2
 end
 
 --enemy bounce particles
 if typ=="blood" then
  a.anim=bloodparticle
  a.life=rnd()*6+8
  a.fy=rnd()-0.5
 end
 if typ=="blobsplat" then
  a.anim=blobsplat
  a.life=rnd()*6+4
  a.fy=rnd()-0.5
 end
 if typ=="bubble" then
  a.anim=sludgebubble
  a.life=120
  a.fy=(rnd()*-2)-2
  a.fx=0--(rnd()-0.5)*0.2
 end
 
 --harmful projectile particles
 if typ=="witchspell" or typ=="witchspellf" then
   a.anim=witchspell
   a.frame=flr(rnd()*4)
   a.life=100
   a.fy=0
   a.fx=2
   a.flipped=false
   if typ=="witchspellf" then
    a.ptype="witchspell"
    a.fx=-2
    a.flipped=true
   end
 end
 
 if typ=="spew" then
  a.life = 90
  a.fx=-2
  a.anim=spewanim
  a.fy=rnd()-0.5
  a.flipped=true
 
  rndx=(rnd()*6)-3
  rndy=(rnd()*6)-3
 
  dirx=(spewaimx+rndx)-(boss.x+8 )
  diry=(spewaimy+rndy)-(boss.y+10)
       
  len=sqrt(dirx*dirx+diry*diry)
  if len!=0 then
  dirx=dirx/len
  diry=diry/len
  end
  a.fx=dirx*(2+rnd())
  a.fy=diry*(2+rnd())
 end
 
 --add the particle to the
 --list of actors
 add(actors,a)
end

--initialise all actors
function initactors(newgame)
 --initialise ai rebounds
 for i=1,#rebounds do
  rebounds[i].x=rebounds[i].startx
  rebounds[i].y=rebounds[i].starty
 end
 
 --initialise actors
 for i=1,#actors do
  
  --make a copy of the actor we
  --can initialise easily
  a=actors[i] 
  
  --remember if we were drawing
  --the actor in case we dont
  --want that to change
  wasdrawing=a.dontdraw
  
  --set actor defaults now
  a.flipped=false
  a.flippedv=false
  a.frame=1
  a.anim={}
  a.dontdraw=false
  
  --we cache where actors can
  --move, it doesn't need to be
  --reset unless it's a new game
  if newgame then
   a.maxposx=5000
   a.minposx=-5000
   a.maxposy=5000
   a.minposy=-5000
   a.maxset=false
   a.minset=false
  end
  
  --coins and lives don't need
  --to be reinitialised unless
  --it's a new game
  if not newgame then
   if a.typ=="coin" or a.typ=="life" then
    a.dontdraw=wasdrawing
   end
  end
  
  --set actor's default movement
  a.move=0
  a.fx=0
  a.fy=0
  
  --and position
  a.x=a.startx
  a.y=a.starty
  
  --now begin specific
  --initialisation based on the
  --actor's type
  
  if a.typ=="player" then
   a.anim=idleanim
   a.grounded=false
   a.fy=0
   if newgame then
    checkx=a.startx
    checky=a.starty
   else
    a.x=checkx
    a.y=checky
   end
  end
 
  if a.typ=="bat" then
   a.anim=batflap
   a.toffset=rnd()*3.14
  end
 
  if a.typ=="ghost" then
   a.move=0.25
   a.anim=ghostanim
  end
 
  if a.typ=="skeleton" then
   a.move=0.5
   a.anim=skelwalk
  end
 
  if a.typ=="coin" then
   a.anim=coinspin
  end
  
  if a.typ=="spiker" or a.typ=="spikertop" then
   a.anim=spikeranim
   a.frame=flr8(10000-a.startx)
   if flr8(a.starty)%2==0 then
    --animate it in reverse
    a.frame=flr8(a.startx)
   end
   while a.frame>#spikeranim do
    a.frame-=#spikeranim
   end
  end
  if a.typ=="spikertop" then
   a.flippedv=true
  end
  
  if a.typ=="particle" then
   --we clear particles when
   --resetting, so mark it for
   --being removed next update
   a.life=-1
  end
  
  if a.typ=="blob" then
   a.anim=blobblob
   a.move=0.25
  end
  
  if a.typ=="lava" then
   a.anim=lavaanim
   a.frame=flr(rnd()*5)
  end
  
  if a.typ=="sludge" or a.typ=="sludgeb" then
   a.anim=sludgeanim
   a.frame=flr(rnd()*5)
   a.spawntimer=30
   a.spawntype=0
  end
  
  if a.typ=="witch" then
   a.anim=witchcast
  end
  if a.typ=="witchf" then
   a.anim=witchcast
   a.flipped=true
  end
  
  if a.typ=="checkpoint" then
   a.anim=checkstill
   a.checkpoint=false
  end
  
  if a.typ=="life" then
   a.anim=lifeanim
  end
  
  if a.typ=="finish" then
   a.anim=crownanim
  end
  
  if a.typ=="key" then
   a.anim=keyanim
   if newgame then
   a.collected=false
   a.used=false
   a.xa=a.x
   a.ya=a.y
   end
  end
  
  if a.typ=="keyhole" then
   a.dontdraw=true
   if newgame then
    a.unlocked=false
   end
  end
  
  if a.typ=="keywall" then
   a.anim=keywallanim
   a.toff=a.y*0.1
   if newgame then
    a.dontdraw=false
   else
    a.dontdraw=wasdrawing
   end
  end
  
  if a.typ=="pewking" then
   --this is the boss
   a.dontdraw=true
   a.stage=1
   a.state="fight"
   a.mouthtime=0
   boss=a
  end
  
  --take out copy of the actor
  --and put it back in the list
  actors[i]=a
  
 end
end
-->8
--actor updates

-----------------------------

--here are the update functions
--for each type of actor
--they are called from the
--functions in tab 4

-----------------------------


function playerupdate(player)
 --player should not appear on
 --the title screen
 if screen=="title" then
  player.dontdraw=true 
  return
 end
 
 --no player movement/control
 --if they are dead
 if (dead) return

 --add/subtract from horizontal
 --force based on player input
 if (btn(⬅️)) player.fx-=0.5
 if (btn(➡️)) player.fx+=0.5
 --clamp players x force (this
 --is our terminal velocity)
 player.fx=mid(-1.5,player.fx,1.5)
 --slow down if no player input
 if (not btn(⬅️) and not btn(➡️)) player.fx*=0.4
 
 
 --if player isn't grounded,
 --then they start to fall
 if not player.grounded then
  --add to players vertical force
  player.fy+=0.5
  --terminal velocity again,
  --we set it to 7 so it never
  --falls greater than 1 tile
  --per frame
  player.fy=min(player.fy,7)
 end
  
 --move player based on vertical
 --forces that have been set
 player.y+=player.fy
 
 --now, we might have moved
 --the player into a tile above
 --or below, so we want to
 --resolve any colissions
 
 --move up till not overlapping
 --any tiles
 if player.fy>=0 then
  while overlapssolid(player.x,player.y) do
   player.y-=1
   --we had moved down into a
   --tile so we are grounded now
   --play a 'land' sound effect
   if (not player.grounded) sfx(24)
   --mark ourselves as grounded
   player.grounded=true
   --stop moving down
   player.fy=0
  end
 end
 --move down till not
 --overlapping any tiles
 if player.fy<0 then
  while overlapssolid(player.x,player.y) or player.y<0 do
   player.y+=1
   --we bumped our head so now
   --we stop moving up
   player.fy=0
  end
 end
 
 --we might have walked off an
 --edge last update, so let's
 --check if we're not grounded
 if not overlapssolid(player.x,player.y+1) then
  player.grounded=false
 end
 
 --that's it for vertical motion
 --now we begin horizontal stuff
 
 --move player horizontally
 player.x+=player.fx*1.5
 
 --once again, we might have
 --moved into a tile, so we have
 --to check and resolve that
 
 if player.fx<0 then
  --move right till not
  --overlapping any tiles
  while overlapssolid(player.x,player.y) or player.x<0 do
   player.x+=1
   player.fx=0
  end
 end
 if player.fx>0 then
  --move left till not
  --overlapping any tiles
  while overlapssolid(player.x,player.y) or player.x>1017 do
   player.x-=1
   player.fx=0
  end
 end
 
 --if we are grounded and the
 --player pressed 'jump'...
 if player.grounded and sbtnp() then
  --we jump!
  --that means a sound effect
  sfx(0)
  --upwards force
  player.fy=-5.5
  --and leaving the ground
  player.grounded=false
 end
 
 --thats it for moving the player
 --now we animate them!
  
 
 if player.grounded then
  --grounded, so we decide to
  --play running or idle anim
  if btn(➡️) or btn(⬅️) then
   player.anim = runanim
  else
   player.anim = idleanim
  end
 else
  --in air, so we decide to play
  --the rising or falling anim
  if player.fy<0 then
   player.anim = riseanim
  else
   player.anim = fallanim
  end
 end
  
 
 --ok so that's the main player
 --stuff but it only covers
 --interaction with the map...
 --we want out player to be
 --able to interact with other
 --actors:
 
 --first we get a list of all
 --other actors the player is
 --currently touching
 collisions=acollidesall(player,"coin")
 
 --then loop through and resolve
 --each as necessary
 for i=1,#collisions do
  collider=collisions[i]
  
  if collider.typ=="coin" then
   --get coins if  they haven't
   --been picked up already
   if not collider.dontdraw then
    collider.dontdraw=true
    score+=10
    sfx(5)
   end
  end
  
  if collider.typ=="skeleton" then
   --if a skeleton is still here
   if not collider.dontdraw then
    --...and we land on it...
    if player.y < collider.y or player.fy>0 then
     --bop it!
     --sound effect
     sfx(2)
     --bounce
     player.fy=-3.5
     if (sbtn()) player.fy=-5.5
     --hide the skeleton
     collider.dontdraw=true
     --points!
     score += 5
     --spawn some bone particles
     for i=1,3 do
      addparticle("bone",collider.x,collider.y)
     end
    else
     --if we didn't land on it
     --then we die here d;
     if (player.fy>=0) die()
    end
   end
  end
  
  --(most enemy interactions are
  --like skeletons so i'll not
  --go into as much detail with
  --them)
  
  if collider.typ=="ghost" then
   if getdist(collider.x,collider.y,player.x,player.y)<5 then
    die()
   end
  end
  
  if collider.typ=="finish" then
   win()
  end
  
  if collider.typ=="bat" then
   if not collider.dontdraw then
    if player.y<collider.y or player.fy>0 then
     --bop it!
     sfx(2)
     player.fy=-3.5
     if (sbtn()) player.fy=-5.5
     collider.dontdraw=true
     score += 7
     for i=1,3 do
      addparticle("blood",collider.x,collider.y)
     end
    else
     --die here d;
     die()
    end
   end
  end
  
  if collider.typ=="blob" then
   if not collider.dontdraw then
    if player.y<collider.y and player.fy>0 then
     --bounce!
     
     player.fy=-3.5
     if sbtn() then
      player.fy=-7
      sfx(3)
     else
      sfx(4)
     end
     for i=1,3 do
      addparticle("blobsplat",collider.x,collider.y)
     end
     
    end
   end
  end
  
  if collider.typ=="life" then
   if not collider.dontdraw then
    lives+=1
    collider.dontdraw=true
    sfx(8)
   end
  end
  
  if collider.typ=="lava" or
     collider.typ=="sludge" or
     collider.typ=="sludgeb" then
   die()
  end
  
  if collider.typ=="particle" then
   if collider.ptype=="witchspell" then
    if getdist(collider.x,collider.y,player.x,player.y)<4 then
     die()
    end
   end
  end
  
  if collider.typ=="particle" then
   if collider.ptype=="bubble" then
   if getdist(player.x,player.y,collider.x,collider.y)<6 then
    die()
   end
   end
  end
  
  if collider.typ=="particle" then
   if collider.ptype=="spew" then
   if getdist(player.x,player.y,collider.x,collider.y)<5.5 then
    die()
   end
   end
  end
  
  if collider.typ=="keywall" then
   if not collider.dontdraw then
    die()
   end
  end
  
  if collider.typ=="witch" or collider.typ=="witchf" then
   if not collider.dontdraw then
    if player.y<collider.y or player.fy>0 then
     --bop it!
     sfx(2)
     player.fy=-3.5
     if (sbtn()) player.fy=-5.5
     collider.dontdraw=true
     score += 5
     for i=1,3 do
      addparticle("blood",collider.x,collider.y)
     end
    end
   end
  end
  
  if collider.typ=="spiker" or collider.typ=="spikertop" then
   spikeframe = collider.anim[collider.frame]
   if spikeframe==35 or spikeframe==36 then
    --spikers are only deadly
    --on certain frames
    if player.x<collider.x+5.5 and player.x>collider.x-5.5 then 
     die()
    end
   end
  end
  
  if collider.typ=="checkpoint" then
   checkpointnow(collider)
  end
  
  if collider.typ=="key" then
   if not collider.collected then
    collider.collected=true
    collider.target=player
    sfx(9)
   end
  end
  
 end
 
 --boss collision
 --this is unique because the
 --boss is a much larger sprite
 if acollidesboss(player) then
  bossbop(player)
 end
  
 --now we've resolved the stuff
 --the player does, but we still
 --need to make the camera
 --follow the player

 --position camera horizontally
 --so player is on screen
 camx=mid(player.x-75+camoff, camx, player.x-45+camoff)
 --dont let camera past map edge
 camx=mid(0,camx,896)
  
 --cam offtets for each level
 --the offset is a little extra
 --horizontal space so the
 --player can see ahead of them
 camoff= 10--bottom level
 if (player.y<384) camoff= 10
 if (player.y<256) camoff= -10
 if (player.y<128) camoff= 10--top level
 
 --now for camera y position
 --we set a target position
 --to snap to the player's level
 if player.y>camytarget+127 then
  camytarget+=128
 end
 if player.y<camytarget then
  camytarget-=128
 end
 --then we move the camera's y
 --position towards the target
 if camy<camytarget+1 and camy>camytarget-1 then
  camy=camytarget
 else
  camy=lerp(camy,camytarget,0.2)
 end
 
 --finally for the player update
 --we play some music stings
 --whenever the player moves to
 --a new level (or the boss)
 if level<2 and player.y>128 then
  level=2
  music(16)
 end
 if level<3 and player.y>256 then
  level=3
  music(16)
 end
 if level<4 and player.y>384 then
  level=4
  music(16)
 end
 if level==4 and player.x>286 then
  --boss
  level=5
  music(17)
 end
  
end


function skeletonupdate(skel)
  --skeletons move horizontally
  skel.x+=skel.move
  
  --we check if we've reached as
  --far as we can walk this way
  getlimits(skel)
  
  rebound = false
  if skel.x<skel.minposx then
   --cant go further left
   rebound=true
   skel.x=skel.minposx
  end
  if skel.x>skel.maxposx then
   --cant go further right
   rebound=true
   skel.x=skel.maxposx
  end
  
  if rebound then
   --change direction
   skel.move *=-1
   --flip the skeleton sprite
   skel.flipped=not skel.flipped
  end
end

--again, moving enemies act just
--as the skeleton does, so i'm
--putting less detailed comments
--on them

function blobupdate(blob)
  blob.x+=blob.move
  
  getlimits(blob)
  
  rebound = false
  if blob.x<blob.minposx then
   rebound=true
   blob.x=blob.minposx
  end
  if blob.x>blob.maxposx then
   rebound=true
   blob.x=blob.maxposx
  end
  
  if rebound then
   blob.move *=-1
   blob.flipped=not blob.flipped
  end
end

function ghostupdate(ghost)
 ghost.y+=ghost.move
  
 getlimits(ghost)
 
 rebound = false
 if ghost.y<ghost.minposy then
  rebound=true
  ghost.y=ghost.minposy
 end
 if ghost.y>ghost.maxposy then
  rebound=true
  ghost.y=ghost.maxposy
 end
  
 if rebound then
  ghost.move *=-1
 end
end


function particleupdate(part)
 --most particles behave in a
 --similar way; they move based
 --on x/y forces, and their life
 --decreases until they are
 --removed
 
 --move this particle
 part.x+=part.fx
 part.y+=part.fy

 --decrease particle life
 part.life-=1
 if part.life<0 then
  --particle has lived too long
  --so we remove it
  del(actors,part)
  
 else
 
  --particle is still alive so
  --we can do specific stuff
  --based on what kind it is
  if part.ptype=="bubble" then
   part.fy+=0.15
   if part.y>part.starty then
    part.life=-1
   end
  end
  
  if part.ptype=="bone" then
   part.fy+=0.4
  end
  if part.ptype=="pewshell" then
   part.fy+=0.4
  end
  
  if part.ptype=="witchspell" then
   if overlapssolid(part.x,part.y) then
    part.life=-1
   end
  end
  
 end
end

function batupdate(bat)
 bat.x=bat.startx+sin(playtime+bat.toffset)*8
 bat.y=bat.starty+cos((playtime+bat.toffset)*4)*4
end

function lifeupdate(life)
 life.y=life.starty+sin(playtime)*4
end

function keyupdate(key)
 tx=key.startx
 ty=key.starty
 if key.collected or key.used then
  key.xa=lerp(key.xa,key.target.x,0.2)
  key.ya=lerp(key.ya,key.target.y,0.2)
  tx=key.xa
  ty=key.ya
 end
 
 if key.collected and not key.used then
  --look for heyholes nearby
  for a=1,#actors do
   if actors[a].typ=="keyhole" and not actors[a].unlocked then
    if actors[a].x>key.x-20 and actors[a].x<key.x+20 then
    if actors[a].y>camy and actors[a].y<camy+127 then
     key.target=actors[a]
     key.used=true
     unlock(actors[a])
    end
    end
   end
  end
 end
 
 key.x=tx+sin(playtime)*4
 key.y=ty+cos(playtime*4)*3
end

function finishupdate(crown)
 crown.x=crown.startx+sin(playtime)*6
 crown.y=crown.starty+cos(playtime*4)*3
end

function witchupdate(witch)
 if (witch.dontdraw) return
 if witch.frame==#witch.anim then
  if witch.canspawn then
   if witch.flipped then
    addparticle("witchspellf",witch.x-2,witch.y)
   else
    addparticle("witchspell",witch.x+6,witch.y)
   end
  end
  witch.canspawn = false
 else
  witch.canspawn = true  
 end
end

function sludgeupdate(s,offscreen)
 s.spawntimer-=1
 if s.spawntimer<0 then
  s.spawntimer=100
  s.spawntype=0
  if (rnd()*20<3) s.spawntype=1
 end

 if s.spawntimer<10 and not offscreen then
  if s.spawntype==0 then
   addparticle("bubble",s.x+(rnd()*6)-2,s.y)
  else
   addparticle("bone",s.x+(rnd()*6)-2,s.y)
  end
 end
end

function unlock(keyhole)
 if (not keyhole.unlocked) sfx(10)
 keyhole.unlocked=true
 for i=1,#actors do
  if actors[i].typ=="keywall" then
   if 50>getdist(actors[i].x,actors[i].y,keyhole.x,keyhole.y) then
    actors[i].dontdraw = true
   end
  end
 end
end

function wallupdate(wall)
 wall.x=wall.startx+sin((playtime+wall.toff)*3)*1
end

--rest is boss specific stuff
--i'm not going to go into
--detail, you'll probably never
--want something just like this

function bossbop(player)
 if (boss.state!= "fight") return
 
 if player.x>=boss.x+8 then
  --bop it!
  sfx(2)
  
  boss.mouthtime=0
  
  player.fy=-3.5
  if (sbtn()) player.fy=-5.5
      
  score += 77
  for i=1,8 do
   addparticle("pewshell",boss.x+(i*2),boss.y-16)
  end
      
  if boss.stage==1 then
   boss.state = "retreat"
  end
  if boss.stage==2 then
   boss.state = "retreat"
  end
  if boss.stage==3 then
   boss.state = "dead"
   boss.y+=16
  end
  boss.stage+=1
  
  
 else
  --die here d;
  die()
 end
end

function bossupdate()
 if boss.state=="retreat" then
  boss.x+=3
  if boss.stage==2 and boss.x>bossx_b then
   boss.x=bossx_b
   boss.state="fight"
  end
  if boss.stage==3 and boss.x>bossx_c then
   boss.x=bossx_c
   boss.state="fight"
  end
 end
 
 if (boss.state!="fight") return
 boss.mouthtime-=1
 if boss.mouthtime<0 then
  boss.mouthtime = 50
 end
 
 if boss.mouthtime==9 then
  spewaimx=actors[playerindex].x
  spewaimy=actors[playerindex].y
  
  if actors[playerindex].x>boss.x-7 then
  --player is above, dont shoot up
   spewaimx=boss.x-90
   spewaimy=boss.y
  end
 end
 if boss.mouthtime<8 then
  --spew
  addparticle("spew",boss.x+4,boss.y+10)
 end
 
end
-->8
--game update

-----------------------------

--functions here:
--  _update()    actorupdate()

-----------------------------


--al our game code happens
--inside _update(), all actor
--update functions are called
--from in here
function _update()

 --update a variable we use for
 --time based effects (eg bats)
 playtime+=0.011

 --respond to player input on
 --title/gameover screens
 if actionp() then
  if screen=="title" then
   begingame(true)
   music(17)
  end
  if screen=="gameover" then
   begingame(true)
   screen="title"
   music(0)
  end
 end
 
 --if dead, wait for transition
 --and then show game over or
 --respawn if it's not over
 if dead then
  transitiontime+=1
  if transitiontime>50 then
   if lives<0 or gametime<=0 then
    if screen!="gameover" then
     if (screen!="gameover")music(18)
    
     screen="gameover"
    end
   else
    begingame(false)
   end
  end
 end
 
 --if the game is won, wait for
 --transition and then add time
 --and lives to the score
 --then go to game over screen
 if won then
  transitiontime+=1
  if transitiontime>50 then
   if gametime>0 then
    scorechange=10
    if (gametime<10) scorechange=gametime*10
    gametime-=10
    score+=scorechange
    sfx(5)
    transitiontime=47
    if gametime<=0 then
     gametime=0
     transitiontime=20
    end
   else
    if lives>0 then
     lives-=1
     score+=500
     sfx(8)
     transitiontime=20
    else
     if (screen!="gameover")music(19)
    
     screen="gameover"
    end
   end
  end
 end
 
 --don't do anything else if
 --the game is frozen
 if (gamefrozen) return

 --count down the game time
 --every second is 30 updates
 framecount+=1
 if framecount==30 then
  framecount=1
  gametime-=1
 end
 
 --if there's no time left end
 --the game
 if gametime<=0 and screen=="game" then
  gametime=0
  timeout()
 end

 --go through list of actors
 --and update each
 for a=1,#actors do
   actorupdate(actors[a])
 end
 
end

function actorupdate(actor)
 --function to determine what
 --kind of update to perform
 --for this actor
 --all these functions are on
 --tab 3

 if (not actor) return
 
 if actor.typ=="player" then
  playerupdate(actor)
 end
 
 if actor.typ=="particle" then
  particleupdate(actor)
 end
 
 if actor.typ=="key" then
  keyupdate(actor)
 end
 
 --skip this if its on a different level
 if (actor.y<camy-8) return
 if (actor.y>camy+128) return
 
 if actor.typ=="skeleton" then
  skeletonupdate(actor)
 end
 
 if actor.typ=="blob" then
  blobupdate(actor)
 end
 
 if actor.typ=="ghost" then
  ghostupdate(actor)
 end
 
 --skip this if not close to the screen
 offscreen=false
 if (actor.x<camx-40) offscreen=true
 if (actor.x>camx+168) offscreen=true
 
 if actor.typ=="sludgeb" then
  sludgeupdate(actor, offscreen)
 end
 
 if (offscreen) return
 
 if actor.typ=="bat" then
  batupdate(actor)
 end
 
 if actor.typ=="witch" or actor.typ=="witchf" then
  witchupdate(actor)
 end
 
 if actor.typ=="life" then
  lifeupdate(actor)
 end
 
 if actor.typ=="finish" then
  finishupdate(actor)
 end
 
 if actor.typ=="keywall" then
  wallupdate(actor)
 end
 
 if actor.typ=="pewking" then
  bossupdate()
 end
 
end
-->8
--game drawing

-----------------------------

--all the 'action' happens in
--other tabs, but here is where
--we draw it all on the screen

--functions here:
--  _draw()    drawgame()
--  drawboss()

-----------------------------

--all game drawing happens in
--the _draw() function, it
--happens after _update()
function _draw()
 
 --always count down title flash
 titleflash-=1
 if (titleflash<0)titleflash=40
 
 --draw the title screen
 if screen=="title" then
  --scroll camera
  if (camytarget==0) camx+=0.5
  if (camytarget!=0) camx-=0.5
  if (camx>896) camytarget=1
  if (camx<0) camytarget=0
  --draw the game
  drawgame(false)
  
  --now we draw the title screen
  --stuff itself
  
  --reposition camera
  camera()
  
  --show patrons
  if (titleflash==20)patronindex+=1
  if (patronindex>#patrons) patronindex=1
  oprint2("thanks to:",0,122,13,1)
  oprint2(patrons[patronindex],128-#patrons[patronindex]*4,122,13,1)
 
  --show music credit 
  musicstr="♪ music by tim monks ♪"
  oprint2(musicstr,64-(#musicstr/2)*4,113,13,1)
  
  --show version number
  verstr="v1.1a"
  oprint2(verstr,128-(#verstr/2)*8,min(30-(playtime*30),0),1,0)
  
  --show sophie credit and title
  tx=48 ty=30
  sprint("sophie houlden's",tx-13,ty-15,13,1)
  palall(1)
  spr(112,tx-1,ty,5,1)
  spr(112,tx+1,ty,5,1)
  spr(112,tx,ty-1,5,1)
  spr(112,tx,ty+1,5,1)
  pal()
  spr(112,tx,ty,5,1)
  
  --flash the 'press ❎' text
  if (titleflash<20)sprint("press ❎ to begin",33,95,9,1)
 
 end

 --draw the game
 if screen=="game" then
  drawgame(true)
 end
 
 --draw the game over screen
 if screen=="gameover" then
  --clear the screen
  cls()
  --draw part of the map
  map(112,32,0,0,16,16)
  if won then
   --show win text
   spr(53,60,71)
   spr(17,60,63)
   oprint2("you win!",49,94,9,1)
   oprint2("you are the true pumpking!",14,50,9,1)
  else
   --show loss text
   if finaltime<=0 then
    oprint2("ran out of time!",32,50,8,1)
    spr(19,60,72)
   else
    oprint2("ran out of lives!",30,50,8,1)
    spr(69,60,72)
   end
   oprint2("game over!",45,94,8,1)
  end
  
  --display game stats
  oprint("play time: ",25,4,6,2)
  timestr=formattime(starttime-finaltime)
  oprint(timestr,105-(#timestr*4),4,6,2)
  
  oprint("lives: ",25,14,6,2)
  livesstr=livesdisplay(max(finallives,0))
  liveswidth=#livesstr*8
  if finallives<=0 then
   livesstr="none"
   liveswidth=16
  end
  oprint(livesstr,105-liveswidth,14,6,2)
  
  scorestr = "final score: "..score.."0"
  oprint(scorestr,64-(#scorestr*2),26,7,1)
  
  --show 'press ❎' message
  oprint2("press ❎ to continue",25,115,9,1)
 
 end
end


function drawgame(drawhud)
 cls() --clear the screen
 
 --map drawing and camera
 camera(camx,camy)
 map(0,0,0,0,256,256)
 
 --draw pewking boss
 drawboss()
  
 
 --counter for animations
 --every 4 game frames is 1
 --animimation frame
 animcount -= 1
 if (animcount<0) animcount=4
 
 --go through list of actors and
 --draw them now
 for a=1,#actors do
 
  --animate actors
  if animcount==0 then
   actors[a].frame+=1
  end
  if (actors[a].frame>#actors[a].anim)actors[a].frame=1
  
  
  --draw actors if not hidden
  if not actors[a].dontdraw then
   spr(actors[a].anim[actors[a].frame], actors[a].x,actors[a].y,1,1,actors[a].flipped,actors[a].flippedv)
  end
  
 end
 
 
 --now for the heads-up-display
 --(not drawn on title screen)
 if drawhud then
  --reset camera
  camera()
  
  --display remaining time
  --(make it red if it's low)
  timecol=6
  if (not won and gametime<=30 and titleflash<20) timecol=8
  oprint("time: "..formattime(gametime),0,1,timecol,1)
  
  --display lives
  livestr=livesdisplay()
  oprint(livestr,127-#livestr*8,1,6,1)
  
  --display score
  oprint("score: "..score.."0",0,9,6,1)
 end
end

function drawboss()
 --draw the pewking
 if boss.state!="dead" then
  --draw living boss
  spr(74, boss.x,boss.y-8,4,4)
  
  --if it's mouth is open then
  --draw that over the top
  palt(0,false)
  if (boss.mouthtime<30 and boss.mouthtime>0) spr(78, boss.x,boss.y+8,2,1)
  palt()
 else
  --draw dead boss
  spr(74, boss.x,boss.y-8,4,2)
 end
 
end
-->8
--collision and action functions

-----------------------------

--functions here:
-- acollidesboss() acollides()
-- arebounds()     acollidesall()
-- overlapssolid() getlimits()
-- checkpointnow() 

-----------------------------

function acollidesboss(actor)
 --does an actor collide with
 --the boss?
 if actor.x>boss.x-6 and
    actor.x<boss.x+31 and
    actor.y>boss.y-8 and
    actor.y<boss.y+31 then
  return true
 end
 return false
end

function acollides(actor,typ)
 --does this actor collide with
 --another actor of a type?
 for a=1,#actors do
  if actors[a].typ==typ then
   if actors[a].x>actor.x-8 and
      actors[a].x<actor.x+7 and
      actors[a].y>actor.y-8 and
      actors[a].y<actor.y+7 then
    return a
   end
  end
 end
 
 return 0
end

function arebounds(actor,typ)
 --does this actor collide with
 --an ai rebound?
 for a=1,#rebounds do
  if rebounds[a].x>actor.x-8 and
     rebounds[a].x<actor.x+7 and
     rebounds[a].y>actor.y-8 and
     rebounds[a].y<actor.y+7 then
   return a
  end
 end
 
 return 0
end

function acollidesall(actor)
 --returns list of alllll
 --actors touched
 returnlist={}
 for a=1,#actors do
  if actors[a].x>actor.x-8 and
     actors[a].x<actor.x+7 and
     actors[a].y>actor.y-8 and
     actors[a].y<actor.y+7 then
   add(returnlist,actors[a])
  end
 end
 
 return returnlist
end

function overlapssolid(x,y)
 --returns true if an 8x8 object
 --at x,y overlaps a solid tile
 if (fget(mget(flr8(x),flr8(y)),0)) return true
 if (fget(mget(flr8(x+7),flr8(y)),0)) return true
 if (fget(mget(flr8(x),flr8(y+7)),0)) return true
 if (fget(mget(flr8(x+7),flr8(y+7)),0)) return true
 
 return false
end

function getlimits(actor)
 --finds max/min position an ai
 --actor can move to
 --(for skeletons,blobs,ghosts)
 if (actor.move <0 and actor.minset) return
 if (actor.move >0 and actor.maxset) return
 
 if actor.move<0 and not actor.minset then
  while arebounds(actor,"airebound")>0 do
   actor.minposx=actor.x
   actor.minposy=actor.y
   actor.minset=true
   if actor.typ=="skeleton" or actor.typ=="blob" then
    actor.x+=1
   else
    actor.y+=1
   end
  end
  while overlapssolid(actor.x,actor.y) do
   actor.minposx=actor.x
   actor.minposy=actor.y
   actor.minset=true
   if actor.typ=="skeleton" or actor.typ=="blob" then
    actor.x+=1
   else
    actor.y+=1
   end
  end
 end
 
 if actor.move>0 and not actor.maxset then
  while arebounds(actor,"airebound")>0 do
   actor.maxposx=actor.x
   actor.maxposy=actor.y
   actor.maxset=true
   if actor.typ=="skeleton" or actor.typ=="blob" then
    actor.x-=1
   else
    actor.y-=1
   end
  end
  while overlapssolid(actor.x,actor.y) do
   actor.maxposx=actor.x
   actor.maxposy=actor.y
   actor.maxset=true
   if actor.typ=="skeleton" or actor.typ=="blob" then
    actor.x-=1
   else
    actor.y-=1
   end
  end
 end
 
end

function checkpointnow(checkpoint)
 --activate a checkpoint
 if (checkpoint.checkpoint) return
 for i=1,#actors do
  if actors[i].typ=="checkpoint" then
   actors[i].checkpoint=false
   actors[i].anim=checkstill
  end
 end
 sfx(6)
 checkpoint.checkpoint=true
 checkpoint.anim=checkanim
 checkx=checkpoint.x
 checky=checkpoint.y
end




-->8
--helper functions

-----------------------------

--functions here:
-- formattime()  livesdisplay()
-- palall()      oprint()
-- oprint2()     sprint()
-- actionp()     sbtn()
-- sbtnp()       flr8()
-- lerp()        getdist()

-----------------------------

function formattime(t)
 --converts t to 'mm:ss' display
 tstr=""
 mins=0
 while t>=60 do
  t-=60
  mins+=1
 end
 secs=t
 if (t<10) secs="0"..t
 tstr=mins..":"..secs
 
 return tstr
end

function livesdisplay(n)
 --returns a string with n ♥s
 livesstr=""
 count = lives
 if (n) count = n
 for i=1,count do
  livesstr=livesstr.."♥"
 end
 return livesstr
  
end

function palall(v)
 --set all drawing to a
 --single colour
 pal(1,v)
 pal(2,v)
 pal(3,v)
 pal(4,v)
 pal(5,v)
 pal(6,v)
 pal(7,v)
 pal(8,v)
 pal(9,v)
 pal(10,v)
 pal(11,v)
 pal(12,v)
 pal(13,v)
 pal(14,v)
 pal(15,v)
end

function oprint(s,x,y,col,ocol)
 --print text with outline
 print(s,x-1,y,ocol)
 print(s,x+1,y,ocol)
 print(s,x,y-1,ocol)
 print(s,x,y+1,ocol)
 print(s,x,y,col)
end

function oprint2(s,x,y,col,ocol)
 --print text with thick outline
 print(s,x-1,y-1,ocol)
 print(s,x+1,y-1,ocol)
 print(s,x-1,y+1,ocol)
 print(s,x+1,y+1,ocol)
 print(s,x-1,y,ocol)
 print(s,x+1,y,ocol)
 print(s,x,y-1,ocol)
 print(s,x,y+1,ocol)
 print(s,x,y,col)
end

function sprint(s,x,y,col,ocol)
 --print text with drop shadow
 print(s,x,y+1,ocol)
 print(s,x,y,col)
end

function actionp()
 --action pressed?
 if (btnp(🅾️) or btnp(❎)) return true
 return false
end

function sbtn()
 --jump held down?
 if btn(🅾️) or btn(⬆️) or btn(❎) then
  return true
 end
 return false
end

function sbtnp()
 --jump pressed?
 if btnp(🅾️) or btnp(⬆️) or btnp(❎) then
  return true
 end
 return false
end

function flr8(v)
 --converts a position from
 --game space to map space
 return flr(v/8)
end

function lerp(a,b,t)
 --linear interpolation
 return a * (1-t) + (b*t)
end

function getdist(ax,ay,bx,by)
 --get distance between
 --two points
 a=ax-bx
 b=ay-by
 a*=0.01
 b*=0.01
 a=a*a+b*b
 a=sqrt(a)*100
 
 if(a<0) return 32767 --clamp big numbers

 return a
end
__gfx__
000000000000300000a9990000a999000000000000000000000000000066d000066d00000005dd500005dd500000000000000000000000000000000000000000
0000000000a9a9000a9999900a99999000000000000000000000000000565d000565d000000d6d60000d6d600005dd5000000000000000000000000000000000
007007000a999990991991949919919401100110000000000000000000666d000666d0000000d6000056d600000d6d6000044000000440000004400000044000
00077000991991949999994499999944111d51110110011011000011000666500066650000560000006d50000056d600004a9400000a44000004900000499400
00077000999999449911114499111144110110111110011101100110066677d066677d00006d560000560600006d500000499400000944000004900000449400
0070070099111144099444400994444010000001101d51010110011000066dd00066dd0000560000000560000056060000044000000440000004400000044000
000000000994444000400400004004000000000010011001001d51000006d6d0006d6d5000606000006600000060600000000000000000000000000000000000
00000000004004000040000000000400000000000000000000011000000d6d650006d6d506006000000d00000060060000000000000000000000000000000000
000000000000000000111100000030000060000000060600000000000000000000000080000000000003bb000033bbb000000000000000000000003000000000
00009000900000090181181000a9a9006600000000006d0000000000000000000880008880008000003333b00333333b0003bb00000000000b300b333000b000
0004a400a90a909a189119810a1991900d600000000d60000d0000060000880008800080000000080033333003331313003333b00000bb000330003000000003
0049a940aa9f99aa899119989159951400d600000006d00006d6666d0808880000000000000000000033131000333333003333300b03b3000000000000000000
09aa7aa9444444441891198199911944000d600000d60000006d00d6088888000000000800000000003333300033313000331310033333000000000b00000000
0049a940a9a9a9a901811810991111440000dd60006d000006d0000d00088000880008000000000000333330003331300333333000b33000b300030000000000
0004a4009a9a9a9a001111000294442000000600060600000000000000008880888008880080000003333130033333300333111300003bb033300b3300300000
00009000000000000000000004000040000000000000000000000000000000000000000800000008333333333333333333333333000000000000000300000003
00000000000000000000000000070000000000000000000000000000000000000000000000000000aaaaaaaa0005000000550000005500000000500000005000
00033000000000000000000000060000000600000000000000000000000000000000000000000000aaaaaaaa0005500000055550000555500000550000005500
003bb300000000000000000000070000000600000006000000000080000000000800000008800000aaaaaaaa0555555005555000005550000055555500555555
03babb30000000000000000000066000000600000006000000008898080008888988000089980000aaaaaaaa000ff000000ff000050ff0000000ff000000ff00
03bbbb3000000000000000000006d0000006d00000060000888899f9898889999f9988889ff98808aaaaaaaa00555000005550000b55500000533bb0000555fb
003bb30000000000000000000006d0000006d0000006d0009999ffaf9f999ffffaff9999faaf9989aaaaaaaa00f5500003055000000550000005500000055000
0003300000000000000600000006d0000006d0000006d000ffffaaaafafffaaaaaaaffffaaaaff9faaaaaaaa0055550000555500005555000055550000555500
000000000d5555200d5555200d5555200d5555200d555520aaaaaaaaaaaaaaaaaaaaaaaaaaaaaafaaaaaaaaa00d00d0000d00d0000d00d0000d00d0000d00d00
00520000005200000052000000520000000000000000300000000000000000000000000000000000bbbbbbbb0000000000000000000000000000000022122122
050050000500500005005000050050000e800e8090a9a90900000000000000000000000000000000bbbbbbbb000b0000000000000000000000000000555552d5
500ddd00500ddd00500ddd00500ddd00e888e8820a199190000000b0000000000b0000000bb00000bbbbbbbb0000000000000000000000000000000052222215
50ddddd050ddddd050ddddd050ddddd088888822999999940000bb3b0b000bbbb3bb0000b33b0000bbbbbbbb0b0bb000b00ba000000abb0000bbb00012d55521
5006060050064600500f9f00500a7a000888882099111144bbbb3333b3bbb3333333bbbb3b33bb0bbbbbbbbb000ab00000bbb0000b0bb000b00ba00021555122
5006060050064600500f9f00500a7a000288822099111144333333b3333333b33b3b33333bb333b3bbbbbbbb0000000000000000000000000000000052511125
500ddd00500ddd00500ddd00500ddd0000082000099224403b33bbbb3b3b3bbbbbbb33b3bbbbb333bbbbbbbb0000000000000b000000000000b0000052222215
500000005000000050000000500000000000000000400400bbbbbb3bbbbbb3bb3bbbbbbbbb3bbb3bbbbbbbbb0000000000000000000000000000000011211111
550550550000000055055055221221250000000000ddd55000555500000000000055550500000000000000000000000000000000000000000999900099999990
00000500000000000000050051d552d5000000000ddddd5500055000000000000005555000000000000000000000000000000000000000000999990009999000
0000050000000500000005005515125500000000055d5d5500055000000000000000555000000055000000000000000000000000000000000999999999999999
00000500000005000000000011151251000000000ddddd5500055000000000000055555500055550000000000000000000000000000000000999999990990090
55055055550550000000000052122122000000000d555d5500055000000000005500055555550000000000000000000000099000000000000999999000000000
005000000050000000000000d52d5551000000000ddddd5500055000000000000000055550005500000000000099949994999499000000000999990000000000
0050000000500000000000005125551d0000300005d55d5500555500000300000000555500000000000000009944994443335999940000000999900000000000
00500000005000000000000011211515003030030ddddd5505555550003000300005555000000000000000994944444113355144994000000999900000000000
0dddd5ddddd5dddddd5dddd0dddddddd033333333333333333333330033333305055550500000000000099999444444113515449994440000000000000000000
ddddd5ddddd5dddddd5ddddddddddddd333333335335353353353333333335330555500000000000000999994494994111154999994444000000000000000000
dd11125111125111112511dd11111111335531351151113511511333353513535555000000050005000999944999944444449999999444400000f99900009999
d1252525252525252522521d525252513513511124214111242141300321415055550000000055550099999999994499949944994994444000f9999900999999
02122222221222222212222002222220312214121251451212114112121141125555005505550055009999999999499999999499949444409999999499999999
dd2d5555552d5555552d5552dd52d552041421411414214114142141141421410555050000000000099999999999999999999999949444400044444400499999
d52555555125555551255551d5125551024124254211242142112420421124200555500000000005099999999999999999999999949444400000444400004494
51251111112511111125111151121111001221141512211411122100011221005055550000000000099990099999999900999999449444440000000000000000
02122122221221222212222002222220141214122141151421411512414115120005555005000000099990009999999000999999449444440000000000000000
dd5552d5555552d555555552dd552d52212421141421412114214121242141210000555505500500099999000999900009999949449944440000000000000000
d55512555555125555555551d5512551011411411114114211141140111411400000055500555000099999000999900099999949449444440000449400004444
51111251111112511111111151112111442141212421221124212211042122110005055500550000099999999999999999999949449444440049999900444444
02222122221221222212222002222220251141521251414212514142425141420000555505550005099999999999999949999449449444449999999999999994
dd555555552d5555552d5552dd52d552141421411414215114142111241421110005555000055055099999999499999949999449444444440099999900999999
d55555555125555551255551d5125551021124214211242142112410021124100555555005055550099990999409009940099449444444440000999900009999
51111111112111111121111151121111001221141142211411422100004221005555555500555500099990000409009040099449444444440000000000000000
9999000000000000000000900000000000000000254515142252125200400a000044000000000000099990000000000000094444444444440000000000000000
992290900900909000990090090909900099000054515221552151250004a0004094440000000000009990990090000900094444444444440000000000400000
99009090090929290922909092020929092200001514214252159512000a40000099444000449900009999999490999449944444444444000009940000000000
999920900909090909009099200909090909900054215214215dad5100a004000094994004444490000949999499994449944444444444000099400900094900
992200900909020909992092900909090902900042554145159aaa9500a004000094944000004440000094999449994449444444444440000994400000949940
990000299209000909220092290909090299200054142151215dad51000a40000999440000000940000004494449444444444444444400000949400049499440
220000022002000202000020020202020022000045112525521595120004a0000944400000900000000000444444444444444444444000000949940004444000
0000000000000000000000000000000000000000144254541521512100400a009440009000000000000000044404444444444444000000000044400000000004
f32600c0000616161616161616f3161616161616f3f3161616161616f31616161616161616161616161616161616161616161616161616161616161616161616
161616161616161616161616161616161616161616260406161616161616161616161616260406f3161616162624040616161616f31616161616161616161616
16260000000000002404042400000036040404042404040424040436040424000000002404040414000000360000000070000000000000000000000000000000
00002222222222222222222222222222220000002404043604140000000000002404040436240616161616162604140616f31616161616161616161616161616
16161515250000c000c024c000030036042404002400142404240436240000000000000000240424000000360000000000000070000000000070000000001212
123212321232123212321232123212321212121212002436040001000000000000000414360436000000000036240406f316161616161616161616f3161616f3
26000000161515151515151515250036140424240024240000040436000043000000000000002400000000360000000000000000000070000000000000000515
151515151515151515151515151515151515151525000036000000000000000000000004341406161616f3162604040616f32600000000000000000000061616
2600b200000000000000000000000036040000140000000014001436140000000000000000000000000000360000051515151515151515151515151515152604
042400000000000000140000360000140000000036000006151515151525000000051515260406161616161626140406162600c0c0c0c0c0c0c0c0c0c00006f3
26003500900000009000000090000036040024042400000424000436041400000000000000000000000000000000000000000000000000000000240404043600
041400000000000000240400362404240000000036000526040406260000000000162624040436000000000036042406260000c0c0c0c0c0c0c0c0c0c0000006
26001615151515151515151515151516000000000000242400002406151515152500000000000000000000000000000000000000000000000000000004243600
2400000000000000000000003600240043000000360000000024062600002190001626140004341616161616261404062600c0c0c0c0c0c0c0c0c0c0c0c00006
2600c000c000c000c024040616f3260000000000000000000000000006163416f325000000000005250000000000000000007000000000000000000000003600
0000000000000000000000003600000000000000360000000000062600000005151626040024343416161616260414062600c0c0c0c0c0c0c0c0c0c0c0c00006
161515151515151525002406f3260000000000000000000000000024040626040424000000000006260000000000007000000000000000350000000000003600
0000000000000000c20000000615151515250000062500000000000000000000000000000000340000000000362404062600c0c0c0c0c0c0c0c0c0c0c0c00006
16f3163416f334342600003600000000000000c2000300b200000000240626240000000000000006162500000000000000000000000000360000000000003600
0000000000000005250000000000000000000000000000000000000000000000000000000000061634343434261424062600c0c0c021a1a1a10021c0c0c00006
f3161616161616162600003600000000000000051515152500000000000626000000000000000006342600000000000000000000000000360000000000003600
00000000c2000000000000000000000000000000000000000000000021a10021000000000000061616163434342400062600c0c0c0000515152500c0c0c00006
260000c000c000c000c000360000052500000006f367f326000000000000000000002100a1210006161625000000000000000000000000061525000000000000
0000000515250000000000c200c20000000000000000000000000000000525000000000000003600000000003400000626000000000064000064000000000006
26000515151515151515152600000626000000770000007700000000000000000000000525001406163426000000002100002100000000061616000003000000
00000000000000000000003500350000350021a100030000210021000000009000000021000006f316161616260000046400002100a164a1a164a10021000064
26000000000000000000000000c20626000000770000007700000000000000000000000024240406f31626000021a1a1a1210021a1a1a106f316151515151515
15152562626262626262626262626262626262051515152573637305151515151515257373731616f31616f326000000642100a10515151515151525a1002164
26000090000000900000009000053426a1000035000000350000a10000051515257373736373730634f326a1a1a1051525a1a1a10515151616161616161616f3
1616f3a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2f3f31616f3a3a3a3161616f31616f316a3a3a32600000000003600000064051515f31616161616161615152564
1615151515151515151515151516161615151526000000061515151515f3163416a3a3a3a3a3a3161616161515151616f315151516161616161616f316161616
f3161615151515151515151515151515151515f3161616161515151616161616161616151515161515151515161515151516f316161616161616f31616f31615
56565656465656565656565656565656565616260404040616161616161616161616161616161616f31616161616f31616161616161616f31616161616161616
161634f31616f31616f3161616161616f31616f31626040414240616f31616161616f3161616341616f3161616163416f3161634341616f31616161616161616
660000000000000000465656565666004616562604240006f3161616f316161616161616161616161616f316161616f316260404240000000000000000240414
0406162604040424000000000006342600000006f326042412121212121212121200000006f316161616f316161616161616f31616161616161616f316161616
66000000000000000000465666000000000016260414040616161634341616341616161634161616f3f316161616161616260400000000000000000000000024
04061626240414000070000100061634004300341626000005151515151515152500000006162600342600062600342600061616163416163416161616343416
66000000000000000000000000000001000016260024040616f31616161616161616161616f31616f3f316161616f31616260000002100900000900000002100
240634260024000000000000000616340000003416260000000000000000002436000000061634000626000626000626000616f3161616161616161616163416
660000000000004555555555650000000000562614241406161634161616f3161616341616161616161616163416161616260000000005151515151515250000
0006162600000000000000000006163434343434162600001212120000000000360000000616260006260006340006260006161616f316161616f31634161616
66000000000000000000465656650000004556261404040616161616163416161616161616341616163434161616161616260000000000240424000000360000
00061626000000000005151515343434142404341634151515151515250000003600000006161616163416f31616161616163416161616161616161616161616
660000960000000000000046564655555556162604240406f31616f31616161616f3161616161616161616161616f3f316261525000000000000004300360000
0006162600000000000000007700007700002406162600000000000000000000360000000616341616f316161616f31634161616f316260424040616f3f3f316
66009584940000000000000000000000000046262404140616341616161616161616161616163416161616161616f31616260077002100900090009000360000
00063426000000000000000077000077000000061626000000001212120000003600000006f3161616161616161616161616f316260424000000240406163416
66002185a10021000000000096940000000000362424140616161626040404061616161616341616161616f31616161616260077000005151515151515260000
0006f32600a10021000000007700007700000006f326000005151515151515152600000006f3161616260024040616161616f326041400000000002404061616
669000455565009000210095849400000000000000140406162604042400240404061616f31616161616161616161616f3260077000000240436042400360000
0006f31615152500000000000515152500000006f326000000000000000000003600000006f3260414000000000000140406f326040000000000002404061616
565555565656555565000000850000000000000000240406260404000000000004040616161616161634161616163416f3671525000000002436000100360000
0006f32604042400000000000616166700000006f326000000121212000000003600000006f3260404240001000000240406672600000000110000002406f316
565656565656165656555565869400000000000000001406260424000043000000040616161616f31634161616161616f3260000000000000036000000360000
00061626040000000000000000000036000000061616151515151515250000003600000006162600240000000000000000000077000000000000000000061616
56565656565656565656565665000000000000000000246726240000000000000024061616161616161616161616161616260000000000000000000000a50000
000064000000000000000000000000b500000000640424000000000000000035c50000000064000000000000000000000000007700000005152500000006f334
56565616565656161656565656556500000000000000000077000000000300000000000000002404042400002404000064000000000035000000000000000000
000064000000210000a1000021000000000000006400000000000000000000360000000000640000000000000000051515151515151515f31616151515161616
56565656565656565616565656566600000000000000000077000000051525000000000000000024000000000000000064000000000036000000000000000000
000064000000000515151525000000000000000064000000000000000000003600000000006400000000000000000616341616f3161616163434161616f31616
56565656565616565656561616561635355535553535353535353535161616151515151515151515151515151515151515151515151516151515151515151515
1515151515151516161616161515151515151515151515151515151515151516151515151515151515151515151516f316161616341616f3161616161616f316
__map__
6565656566646565656565646565656565656565660000000000000064656664656564666564656565656565656565656565656665656566666465656465656775756466656564656565666664656565656565666565656665656565656565656665656665656565656565656566000000603f61616161616161616161613f61
656600000000000000000000000000646564660000000000000000000000000000000000000000646565656565656565660000000000000000000000000064660000222222222222222222220000006565660c0c0c0c0c0c0c0c646565660000000000000000646565656566660000000060624040410000410000000000603f
00000000000000000000000000000000670000000000000000000c000000000000000000000007000064666565656566000000000000000000000000000064660054555555555555555555560034006566000c0c0c0c0c0c0c0c0065650000000000000000000064666566000000000000004042410000424200424041006061
000000000000000000000000000000000000000000000000000000000000000000000000000000000000006465656600000000000000124400090909001264660065656567000064656565650044006566000c0c0c0c0c0c0c0c00757500000000000000000000000000000000000000000000414000000c0000004000006061
000000000000000000040000000000000000000000000000000000000000000000000047004400004744006465656600000000000000005455555555560064660021212121210000000000655556006566000c0c0c0c0c0c0c0c00757500000012004709120044470030004700000000000000000000410c000000000000603f
00000000000000000000000000000000000000000000000000000000000000000000545555555555555600006465660900470012000000646565656566000064555555555556474400000000006700656556090909090909090954657500000000545556000054555555555600000000002c00000000425300000000002c6061
0c69490004000000000000000000000000000000000000000000000000000c0c0000000c64656565656600006465655555555600000000646565656566000064656565656565555556000000006700656565555555555555555565656500000000000000000000646565616600000000005051515151513f5152000000506161
0c484900000000000000000000000000000000000000040000000c0000005456000000006465656565660000646566000000000000470064650c0c0c0c44006465656565656600000000004400670065656565656565656565656565660000124409001200000064656565660044000000630000000042404200000000006061
5958000000000000000000000000000000000000000000000000000000000c0c000000006700000030004744646600000000000000570064655555555556006465646565000000000c00545555660065656565656565656565656565660000005455560000000064616165655556000000630000000000000000000000416061
4768490000000000000c000000000000000000000000000000000000000000001244094767000054555555556600000c0c00004400670064656565656600470c0c0c0c67000000000c00000000000000000000646565666564656665660000000000000000000064616565656600000000630000002b00000000000042406061
555600000000000000000c0069490000000000000000000000000000000000000054555566000000000000000000000c0c00005700670064656565656600545555555566000000000c00000000000000000000000007000000000000000000001209444712000064656565616600000000634100005051515151515151516161
6565560047014500440c00595800000000000000000000001244094700120000006465660000040000000000000047004400006700670064656565660000006465656566000000000c00000000000000000000000000000007000000000000000054555600000064656161616200000000634000000000000000000041006061
6565655555555555555644006849470044000000000047440054555556004709446465660000000000000000040054555556006700670064656565660000006465660000000030000000440012090909120000440000004700000007440c0c0c47656565004744646565616162000000006340400000000c0000004240006061
65656565656565656565555555555555555626262654555555656565655555555565660c00000000040000000000646565652665266526656565654709000021222100004744571a0044574700545556000000545626545626545626545555555565656555555565656565656647001a006300404200000c000000004240603f
6565656565656565656565656565656565652a2a2a656565656565656565656565660c0c00474700440047004400646565652a652a652a656565655555555555555555555555655555556555556565664444476465656565656565656565656565656565656565616165656561515551516140002b00000c00002c0040506161
65656565656565656565656565656565656565656565656565656565656565656565555555555555555555555555656565656565656565656565656565656565656565656565656565656565656565655555556565656565656565656565656565656565656565656565656561656565616151515152000c0050515151616161
6161616161616161616161616161616161616161616161613f3f3f3f3f3f3f3f6161613f616161616161613f61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161613f3f3f616162000c00603f613f3f3f61
6200000000000000000000000000000042424042404140603f6200606200603f616161616161613f616161616200000000000000000000000000410000000000004140404040404042000000004240404100000000004140406300000000000000000000000000000000000000004140630060616162000c0060613f62006061
6200003400000000000000000000000000000042404041603f6200606200603f616161613f6161616161613f6200000000000000000000000000424042000000424242414040414242000000070000420000000000000042406300120000000000000009000000000009001200424240605362000000000c0000000060536161
6200000000000000000000000400000000000000004140603f6200606200603f61616161616161613f6161616200000000000000000000000000000000000000000000000040000000000007000000000034000000003400416300505151515151515151515151515151520000000042606200000000000c0000000000603f61
6200505151515151515152000004000000000000424242603f6200606200603f620000006061616161616161620053000000000000000000000000000000000000000000000000000000070000000000000000000000000040630000000000006061624041000000000000000000300060620000000000000000000000606161
62000c0c0c0c0c0c0c006341000000000000000000000000606200606200606162000000002122210000212221006051515200000000000000000000000000000000000000000000000000000000000000000000000000424060515151520000606162404200000000000000005051516200000400000040410000040000603f
6151515151515151520063404200005051520000000000002122002122002121000030005051515151515151515161616162000000000000000000000000000000000030000000000000505152000000505152410000004200004140410000006061624200002121212121212160616162000000004240400000000000006061
62000c0c0c0c0c0c0c006300000000603f6151515151515151523650523650515151515161613f6161613f616161613f620000000400000000000000000000505151515151515200000042400000000000000040420000000041404042420000603f620000005051515151515162000000000000000000424200000042416061
62005051515151515151620000004160613f6161616161613f613a3f613a6161613f613f61616161616161613f3f6162000000000000000000000000000000004100603f624041000000000000000000000042420000000000424240000000006061620000000000424042420000000000004100000000000000000000426061
62000c0c0c0c0c0c0c00000000424060616161616161613f61616161616161613f613f613f61613f61616161613f6162410000000000000400000000000000424040603f6240420000000000000000000000000000000000000000000000000060613f520000000000000000000000004240420000000000000000000000603f
615151515151515151515200000042603f61613f61616161616161616161616161616161616161620000000000606162400041404100000000000004000000000040603f62420000000000000000000000000041000000000000000000000000603f61620000212121212121212100000000000000000030000000000041603f
3f6161616161613f763f6200000000002222222222222222222222222222222200004240420000000000100000006062404040404242000000000000000000000000606162404100002b000000000000505152404100002b0000000000000000603f616200505151515151515151515152000000005051515152000042406061
624040410000770000006300000000000000000000000000000000000000000000000000000000070000000000076062004200424040000000000000000000000000603f615152001a50515152373637606162373637505152373737505151516161616200603f61616161616161613f61262626262661613f26262626266161
6240420000007700000000000000000021212121000021212121000021212121000000000000000000000000000060620000000000424200420000000000000000006061613f615151616161613a3a3a3f61613a3a3a613f613a3a3a61613f6161613f6200002323230c0c232323603f612a2a2a2a2a6161612a2a2a2a2a3f61
6242000c000077000000000000000050515151515151515151515151515151515200300000000000005051520000606237363737373737373737373737363737373761616161616161613f6161515151613f6151515161613f5151513f3f61616161613f5151515151515151515161616151515151513f61615151515151613f
6152000c0050515151515151515151613f613f6161616161613f616161613f616151515151515151513f3f3f51513f613a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a6161613f613f61616161613f6161616161613f6161616161613f6161613f613f616161616161613f61613f6161613f3f6161616161616161616161616161
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010100000000000000000000000100000000000000000000000000000000010101010101010100000000000000000101010101010101000000000000000000000000000000010000000000000000
__sfx__
00010000097500975009750097500a7500b7500f75013750177502000021700227002570028700287000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000029050290502a0502b0502c0502c0502d0502e0501c0501c0501c0501d0501f05020050200502105023050240500e0002d0002e00013050120501205011050100500f0500f0500f0500d0500c0500b050
000100001a7500f150177500f1501575010150117500b750077500675006750087500b7500d7501175018750097000c7000f700177001a7001d7002170025700297002b7002d700041000b700031000b70004100
00010000151501a5501f150205502115021550207501c55015150115500f1500b5500a15008550081500855008150085500a1500c5500f1501255015150185501c1501f550211502355026150275502715027550
00010000151501a5501f150205502115021550207501c55015150115500f1500b5500a15008550075500655005550045500355002550015000150001500015000150001500015000150001500015000150027500
00010000297502e75030750307502f7502b75032700397003a7003d7003e7003d700137003a7003e7003f7003e700387000000000000000000000000000000000000000000000000000000000000000000000000
00020000125500d5500a550075500555003550025500000001550015500000001550000000155000000000000355000000055500000008550000000b5500000000000105500000015550000001a550000001e550
00040000190501b0501e050210502c0002c000120000e0501005012050170501e0001100011000140001600006050060500505005050040500405003050030500305003050030500305003050030500205001050
000100000c5500e55011550145501555015550115500c550055500455004550095500e550155501b5501e5501b550125500a5500855009550095500a5500d5501555021550265502a5502f55032550305502a550
00020000297502c7502f7500700008000357503675000000000000000000000000000000014700167001970000000000000000000000000002b7002e700307003270036700377000000000000000000000000000
000200002475026750297500000000000000002d750307503275000000000000000000000000002d7003b7503d7503e75022700207001e7001c700307001a7001870017700177000000018700197000000000000
001000000c0500f050100521005210052000000000000000140501505014052140521405200000000000000018050190501805218052180521805218052180521804218032180221801218000180000000000000
0010000019012190221903219042190521905219052190521c0121c0221c0321c0421c0521c0521c0521c0521a0121a0221a0321a0421a0521a0521a0521a0521701217022170321704217052170521705217052
001000000c0730c50318613186130c0730c50318613000030c0730c50318613186130c0730c50319613000030c0730c50318613186130c0730c50318613000030c0730c50318613186130c0730c5030c07300003
0010000019050190500d0500d0000d050000000d0000d050100501205010050000000f0500f0500d0500d05019050190500d0500d0000d05000000000000d050100501205010050000001c0501c0501e0501e050
00100000200522005220052000002a0002a0002a000000002a0422a0422a042000000000000000000000000028052280522805200000000000000000000000002f0522f0522f0520000000000000000000000000
001000002c0522c0522c0520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000019050190500d0500d0000d050000000d0000d050100501205010050000000f0500f0500d0500d05019050190500d0500d0000d05000000000000d0501005012050100500000000000000000000000000
001000002c0522c0522c0520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001d0001e0501e0501c0501c050
00100000201322013220132000002a1322a1322a13200700281322813228132007001c1301c1301e1301e130201322013220132001002a1322a1322a132001002513225132251320010024132241322413200000
00100000201322013220132000002a1322a1322a132007002813228132281320070028130281302a1302a1302c1322c1322c1322a1002c1302c1302d1302d1302c1322c132001002c1302a1322a1322a1321d000
001000001915000000191200000019100000001910000000151500000015120000000000000000000000000014150000001412000000000000000000000000001015000000101200000000000000000000000000
001000000000019130000001911000000000000000000000000001513000000151100000000000000000000000000141300000014110000000000000000000000000010130000001011000000000000000000000
0010000019050190500d0500d0000d050000000d0000d050100501205010050000000f0500f0500d0500d05019000190000d0000d0000d00000000000000d0050d000120000d0000200000000000000000000000
011000000c02300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000000000000000000000000000000
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 0b5e4344
01 0c0d4344
00 410d0e44
00 0c0d460f
00 0e0d4310
00 0c0d4344
00 410d0e44
00 0c0d430f
00 110d4312
00 0c405713
00 0c0d4314
00 0c0d4313
00 0c0d4314
00 0c0d1516
02 0c421516
04 0b424344
04 17424344
04 0b424344
04 13424344
04 14424344
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
14115142141151214121412214115142141151414121412214115122141151414121412214115142141151421411514214115142141151421411514214115142
42141211421412121242114142141211421412121242114142141211421412121242114142141211421412114214121142141211421412114214121142141211
11411421114114001141141111411421114114201141141111411401114114201141141111411421114114211141142111411421114114211141142111411421
42122112421221144214121242122112421221144214121242122112421221144214121242122112421221124212211242122112421221124212211242122112
25141421251414225114152125141421251414225114152125141421251414225114152125141421251414212514142125141421251414212514142125141421
41421511414211114142141141421511414215114142141141421111414215114142141141421511414215114142151141421511414215114142151141421511
21124214211241002112421421124214211242102112421421124104211242102112421421124214211242142112421421124214211242142112421421124214
14221141142210000122114114221141142211400122114114221001142211400122114114221141142211411422114114221141142211411422114114221141
00000000000000000000000000000000000000000000000000000000000000000000000000000001412141221411514214115142141151421411514214115142
00000000000000000000000000000000000000000000000000000000000000000000000000000002124211414214121142141211421412114214121142141211
00000000000000000000000000000000000000000000000000000000000000000000000000000000114114111141142111411421114114211141142111411421
00000000000000000000000000000000000000000000000000000000000000000000000000000004421412124212211242122112421221124212211242122112
00000000000000000000000000000000000000000000000000000000000000000000000000000002511415212514142125141421251414212514142125141421
00000000000000000000000000000000000000000000000000000000000000000000000000000001414214114142151141421511414215114142151141421511
00000000000000000000000000000000000000000000000000000000000000000000000000000000211242142112421421124214211242142112421421124214
000000000000000000000000000000000000dd00dd0ddd0d0d0ddd0ddd00000d0d00dd0d0d0d000dd12ddd4dd422d141dd221141142211411422114114221141
00000000000000000000000000000000000d110d1d0d1d0d0d01d10d1100000d0d0d1d0d0d0d000d1d0d110d1d0d100d11214122141151221411514214115142
00000000000000000000000000000000000ddd0d0d0ddd0ddd00d00dd000000ddd0d0d0d0d0d000d0d0dd00d0d01000ddd421141421412114214121142141211
0000000000000000000000000000000000011d0d0d0d110d1d00d00d1000000d1d0d0d0d0d0d000d0d0d100d0d0000011d411411114114011141142111411421
00000000000000000000000000000000000dd10dd10d000d0d0ddd0ddd00000d0d0dd101dd0ddd0ddd0ddd0d0d00000dd1141212421221124212211242122112
00000000000000000000000000000000000110011001000101011101110000010101100011011101110111010100000111141521251414212514142125141421
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000141421411414211114142151141421511
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021124214211241042112421421124214
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001221141142210011422114114221141
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014121412214115142
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021242114142141211
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001141141111411421
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044214121242122112
00000000000000000000000000000000000000000000000000000000000000000000000066d00000000000000000000000000000000000025114152125141421
000000000000000000000000000000000000000000000000111100000000000000000010565d0000000000000000000000000000000000014142141141421511
00000000000000000000000000000000000000000000000199991010010010100011019161610110001100000000000000000000000000002112421421124214
00000000000000000000000000000000000000000000000199229191191191910199119119191991019910000000000000000000000000000122114114221141
00000000000000000000000000000000000000000000000199119191191929291922919192121929192210000000000000000000000000014121412214115142
00000000000000000000000000000000000000000000000199992191191919191911919921191919191991000000000000000000000000021242114142141211
00000000000000000000000000000000000000000000000199221191191912191999219291191919191291000000000000000000000000001141141111411421
00000000000000000000000000000000000000000000000199110129921911191922119229191919129921000000000000000000000000044214121242122112
00000000000000000000000000000000000000000000000122100012211210121211012112121212112210000000000000000000000000025114152125141421
00000000000000000000000000000000000000000000000011000001100100010100001001010101001100000000000000000000000000014142141141421511
00000000000000000000000000000000000000000000000000300000000000000003000000000000000000000030000000030000000000002112421421124214
00000000000000000000000000000000000000000000000003000300000000000303003000000000000000000300030003030030000000000122114114221141
00000000000000000000000000000000000000003333333333333333333333333333333333333333333333333333333333333300000000000000000141214122
00000000000000000000000000000000000000033333333533535335335353353353533533535335335353353353533533533330000000000000000212421141
00000000000000000000000000000000000000033553135115111351151113511511135115111351151113511511135115113330000000000000000011411411
00000000000000000000000000000000000000035135111242141112421411124214111242141112421411124214111242141300000000000000000442141212
00000000000000000000000000000000000000031221412125145121251451212514512125145121251451212514512121141120000000000000000251141521
00000000000000000000000000000000000000004142141141421411414214114142141141421411414214114142141141421410000000000000000141421411
00000000000000000000000000000000000000002412425421124214211242142112421421124214211242142112421421124200000000000000000021124214
00000000000000000000000000000000000000000122114151221141512211415122114151221141512211415122114111221000000000000000000001221141
00000000000000000000000000000000000000000000000000000001412141221411514214115142141151421411514214115120000000000000000141214122
00000000000000000000000000000000000000000000000000000002124211414214121142141211421412114214121142141210000000000000000212421141
00000000004400000044000000000000000000000000000000440000114114111141142111411421114114211141142111411400000000000000000011411411
0000000000a4400000a4400000000000000000000000000000a44004421412124212211242122112421221124212211242122110000000000000000442141212
00000000009440000094400000000000000000000000000000944002511415212514142125141421251414212514142125141420000000000000000251141521
00000000004400000044000000000000000000000000000000440001414214114142151141421511414215114142151141421110000000000000000141421411
00000000000000000000000000000000000000000000000000000000211242142112421421124214211242142112421421124100000000000000000021124214
00000000000000000000000000000000000000000000000000000000012211411422114114221141142211411422114114221000000000000000000001221141
00000000333333333333330000000000000000000000000000000001412141221411514214115142141151421411514214115120000000000000000141214122
00000003333333353353333000000000000000000000000000000002124211414214121142141211421412114214121142141210000000000000000212421141
00000003355313511511333000000000000000000000000000000000114114111141142111411421114114211141142111411400000000000000000011411411
00000003513511124214130000000000000000000000000000000004421412124212211242122112421221124212211242122110000000000000000442141212
00000003122141212114112000000000000000000000000000000002511415212514142125141421251414212514142125141420000000000000000251141521
00000000414214114142141000000000000000000000000000000001414214114142151141421511414215114142151141421110000000000000000141421411
00000000241242542112420000000000000000000000000000000000211242142112421421124214211242142112421421124100000000000000000021124214
00000000012211411122100000000000000000000000000000000000012211411422114114221141142211411422114114221000000000000000000001221141
00000000000000000000000000000000000000000000000000000004141151200000000000000000000000000520000000000000000000000000000141214122
00000000000000000000000000000000000000000000000000000002421412100000000000000000000000005005000000000000000000000000000212421141
000000000044000000440000000000000000000000000000000000011141140000000000000000000000000500ddd00000000000000000000000000011411411
0000000000a4400000a4400000000000000000000000000000000000421221100000000000000000000000050ddddd0000000000000000000000000442141212
00000000009440000094400000000000000000000000000000000004251414200000000000000000000000050060600000000000000000000000000251141521
00000000004400000044000000000000000000000000000000000002414211100000000000000000000000050060600000000000000000000000000141421411
000000000000000000000000000000000000000000000000000000002112410000000000000000000000000500ddd00000000000003000000003000021124214
00000000000000000000000000000000000000000000000000000000042210000000000000000000000000050000000000000000030003000303003001221141
00000000000000000000000000000000000000000005dd5000000004141151200000000000000000333333333333333333333333333333333333333214115120
00000000000000000000000000000000000000000006d6d000000002421412100000000000000003333333353353533533535335335353353353533142141210
000000000000000000000000000000000000000000006d0000000001114114000000000000000003355313511511135115111351151113511511135111411400
00000000000000000000000000000000000000000000006500000000421221100000000000000003513511124214111242141112421411124214111242122110
0000000000000000000000000000000000000000000065d600000004251414200000000000000003122141212514512125145121251451212514512125141420
00000000000000000000000000000000000000000000006500000002414211100000000000000000414214114142141141421411414214114142141141421110
00000000000000000000000000000000000300000000060600300000211241000000000000000000241242542112421421124214211242142112421421124100
00000000000000000000000000000000030300300000060063000300042210000000000000000000012211415122114151221141512211415122114114221000
00000000000000000000000000000000333333333333333333333332141151200000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000003333333353353533533535331421412100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000003355313511511135115111351114114000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000003513511124214111242141112421221100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000003122141212514512125145121251414200000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000414214114142141141421411414211100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000241242542112421421124214211241000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000012211415122114151221141142210000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000001412141221411514214115120000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000002124211414214121142141210000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000114114111141142111411400000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000004421412124212211242122110000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000002511415212514142125141420000000000000001100110000000000000000000000000000000000000000000000000000
000000000000000000000000000000014142141141421511414211100000000000000111d5111000000000000000000000000000000000000000000000000000
00000000000000000000000000000000211242142112421421124100000000000000011011011000000000000000000000000000000000000000000000000000
00000000000000000000000000000000012211411422114114221000000000000000010000001000000000000000000000000000000000000000000000000000
000000000005dd500000000000000001412141221411514214115120000000000000000000000000000000000000000000000000000000000000000000000000
000000000006d6d00000000000000002124211414214121142141210000000000000000000000000000000000000000000000000000000001100110000000000
0000000000006d0000000000000000001141141111411421114114000000000000000000000000000000000000000000000000000000000111d5111000000000
00000000000000650000000000000004421412124212211242122110000000000000000000000000000000000000000000000000000000011011011000000000
00000000000065d60000000000000002511415212514142125141420000000000000000000000000000000000000000000000000000000010000001000000000
00000000000000650000000000000001414214114142151141421110000000000000000000000000000000000000000000000000000000000000000000000000
00000000003006060000000000030000211242142112421421124100000000000000000000000000000000000000000000000000000000000000000000000000
00000000030006006000000003030030012211411422114114221000000000000000000000000000000000000000110011000000000000000000000000000000
3333333333333333333333333333333214115142141151200000000000000000000000000000000000000000000111d511100000000000000000000000000000
33535335335353353353533533535331421412114214121000000000000000000000000000000000000000000001101101100000000000000000000000000000
15111351151113511511135115111351114114211141140000440000000000000000000000000000000000000001000000100000000000000000000000000000
42141112421411124214111242141112421221124212211000a44000000000000000000000000000000000000000000000000000000000000000000000000000
25145121251451212514512125145121251414212514142000944000000000000000000000000000000000000000000000000000000000000000000000000000
41421411414214114142141141421411414215114142111000440000000000000000000000000000000000000000000000000000000000000000000000000000
21124214211242142112421421124214211242142112410000000000000000000000000000000000000000000000000000000000000000000000000000000000
51221141512211415122114151221141142211411422100000000000000000000000000000000000000000000000000000000000000000000000000000000000
14115142141151421411511111115141111111111111111111110001111111110001111111111111000111111111111111111111000000111110000000000000
42141211421412114214121ddd141211ddd1d1d11dd1ddd11dd10001ddd1d1d10001ddd1ddd1ddd10001ddd11dd1dd11d1d11dd10000001ddd10000000000000
11411421114114211141141d11111421ddd1d1d1d1111d11d1110001d1d1d1d100011d111d11ddd10001ddd1d1d1d1d1d1d1d1110000001d1110000000000000
42122112421221124212111d12122111d1d1d1d1ddd11d11d1a44001dd11ddd100001d101d11d1d10001d1d1d1d1d1d1dd11ddd10000111d1000000000000000
251414212514142125141ddd15141421d1d1d1d111d11d11d1114001d1d111d100001d111d11d1d10001d1d1d1d1d1d1d1d111d100001ddd1000000000000000
414215114142151141421ddd11421511d1d11dd1dd11ddd11dd10001ddd1ddd100001d11ddd1d1d10001d1d1dd11d1d1d1d1dd1100001ddd1000000000000000
21124214211242142112111111124211111111111111111111110001111111110030111111111111000111111111111111111110003011111000000000030000
14221141142211411422114114221141142210000000000000000000000000000300030003000300000000000303003000000000030003000000000003030030
14115142141151421411514214115142141151433333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
42141211421412114214121142141211421412153353533533535335335353353353533533535335335353353353533533535335335353353353533533535335
11411421114114211141142111411421114114211511135115111351151113511511135115111351151113511511135115111351151113511511135115111351
42122112421221124212211242122112421221124214111242141112421411124214111242141112421411124214111242141112421411124214111242141112
25141421251414212514142125141421251414212514512125145121251451212514512125145121251451212514512125145121251451212514512125145121
41421511414215114142151141421511414215114142141141421411414214114142141141421411414214114142141141421411414214114142141141421411
21124214211242142112421421124214211242142112421421124214211242142112421421124214211242142112421421124214211242142112421421124214
14221141142211411422114114221141142211415122114151221141512211415122114151221141512211415122114151221141512211415122114151221141