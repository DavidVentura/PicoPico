pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- rockets!
-- by siddharth roy

version = "2.1"
screen = "" -- main or game

function _init()
    palt(0, false)
    palt(12, true)
    cartdata("rockets_21")
    switch_screen("main")
    highscore = dget(0)
    sfx(3, 0)
    menuitem(1, "reset highscore", function()
        highscore = 0
        dset(0, 0)
    end)
    code = ""
    cheat_code = "⬆️⬆️⬇️⬇️⬅️➡️⬅️➡️"
end

function _update()
    if screen == "main" then
        update_main_screen()
    elseif screen == "game" then
        update_game_screen()
    end
   
    if (btnp(⬅️)) code = code.."⬅️"
    if (btnp(➡️)) code = code.."➡️"
    if (btnp(⬆️)) code = code.."⬆️"
    if (btnp(⬇️)) code = code.."⬇️"

    if #code > 8 then
        code = sub(code, 2, 9)
    end
   
    if code == cheat_code then
        -- crt effect
        poke(0x5f2c,0x40)
        poke(0x5f5f,0x10)
        for i=0,15 do
         poke(0x5f60+i,i+128)
        end
        for i=0,15 do
         poke(0x5f70+i,0xaa)
        end
    end

end

function _draw()
    cls(12)
    palt(12, true)
    camera(p.x*0.08, p.y*0.08)
    map(64, 0, -192, -192, 64, 64)
    camera(p.x*0.1, p.y*0.1)
    map(0, 0, -192, -192, 64, 64)
    camera(0, 0)
   
    if screen == "main" then
        draw_main_screen()
    elseif screen == "game" then
        draw_game_screen()
    end
end

function switch_screen(scr)
    if scr == "main" then
        init_main_screen()
    elseif scr == "game" then
        init_game_screen()
    end
    screen = scr
end

-- death messages
death_messages = {
    "not good captain!",
    "is that a plane?",
    "is that a ufo?",
    "is that a bird?",
    "never gonna let you down",
    "♪i believe i can fly♪",
    "you can do it!",
    "try again",
    "game over!",
    "rockets?",
    "aww man!",
    "is that all you can do?",
    "am i going to heaven?",
    "you can do better",
    "you are not a good pilot",
    "there is no god here",
    "i'm the best pilot",
    "here comes the rocket",
    cheat_code
}
-->8
-- player

player = {}
player.__index = player

function player.new()
    local o = {
        x = 0,
        y = 0,
        dx = 0,
        dy = -1,
        r = 0,
        speed = 4,
        particle_timer = 1,
        sprite = 1,
    }
    setmetatable(o, player)
    return o
end

function player:draw()
    palt(12, true)
    spr_r(self.sprite, self.x-4, self.y-4, self.r)
end

function player:update()
    if self.r > 360 then
        self.r = 360 - self.r
    end
   
    local vel = vector.new(0, -1)
    vel:rotate(-self.r/360)
   
    self.x += vel.x * self.speed
    self.y += vel.y * self.speed
   
    local p1 = vector.new(4, 0)
    p1:rotate(-self.r/360)
    add_particle(p1.x+p.x+rnd_rng(-1, 1), p1.y+p.y+rnd_rng(-1, 1), 0, 0, 7, 1, 5)
    local p2 = vector.new(-5, 0)
    p2:rotate(-self.r/360)
    add_particle(p2.x+p.x+rnd_rng(-1, 1), p2.y+p.y+rnd_rng(-1, 1), 0, 0, 7, 1, 5)
end

function player:control()
    if (btn(⬅️)) self.r -= 6
    if (btn(➡️)) self.r += 6
end
-->8
-- enemy

enemy = {}
enemy.__index = enemy

function enemy.new(x, y)
    local o = {
        x = x,
        y = y,
        r = 0,
        speed = 4.3
    }
    local pv = vector.new(p.x, p.y)
    local ev = vector.new(o.x, o.y)
    local rv = pv - ev
    rv:normal()
    o.dx = rv.x
    o.dy = rv.y
    setmetatable(o, enemy)
    return o
end

function enemy:draw()
    -- there is a bug in the spr_r function
    palt(12, true)
    spr_r(15, self.x-4, self.y-4, (-atan2(self.dx, self.dy)*360)+90)
end

function enemy:update()
    add_particle(self.x+rnd_rng(-1, 1), self.y+rnd_rng(-1, 1)*2, 0, 0, 0, 1, 20)
    self.x += self.dx * self.speed
    self.y += self.dy * self.speed
   
    if not game_over then
        local pv = vector.new(p.x, p.y)
        local ev = vector.new(self.x, self.y)
        local rv = pv - ev
        rv:normal()
        self.dx = lerp(self.dx, rv.x, 0.08)
        self.dy = lerp(self.dy, rv.y, 0.08)
    end
end
-->8
-- screen

-- minimum score to unlock sprites
score_unlocks = {
 [1] = 0,
 [2] = 50,
 [3] = 100,
 [4] = 150,
 [5] = 200 
}

function init_main_screen()
    p = player.new()
    switch_screen_timer = -1
    banner_pos = vector.new(64-((8*8)/2), 20)
    banner_pos_dy = 0
    hint_pos = vector.new(64 - ((16*4)/2), 100)
    hint_pos_dy = 0
    if dget(1) == 0 then
        dset(1, 1)
    end
    sfx(0, -2)
    p.sprite = dget(1)
    highscore = dget(0)
end

function draw_main_screen()
    camera(p.x-64, p.y-64)
    --map(0, 0, -((128*8)/2),-((64*8)/2), 128, 64)
    draw_particles()
    p:draw()
    camera(0, 0)
    local highscore_str = "highscore: "..highscore
    print(highscore_str, 1, banner_pos.y-18, 13)
    print(highscore_str, 1, banner_pos.y-19, 7)
    if highscore >= score_unlocks[p.sprite] then
        print("press ❎ to start", hint_pos.x, hint_pos.y+1, 13) 
        print("press ❎ to start", hint_pos.x, hint_pos.y, 7) 
    else
        local str = score_unlocks[p.sprite].." points required"
        print(str, 64-((#str*4)/2), hint_pos.y+1, 13) 
        print(str, 64-((#str*4)/2), hint_pos.y, 7) 
    end
    palt(12, true)
    spr(33, banner_pos.x+2, banner_pos.y, 8, 2)
    if p.sprite == 1 then
        pal(7, 6)
    else
        pal(7, 7)
    end
    palt(12, true)
    spr(24, 64-20, 60)
    if p.sprite == 5 then
        pal(7, 6)
    else
        pal(7, 7)
    end
    spr(25, 64+12, 60)
    palt(12, true)
    pal(7, 7)
    print(version, 127-(#version*4), hint_pos.y+22, 1)
    print("by siddharth roy", 64-((15*4)/2), hint_pos.y+22, 1) 
end

function update_main_screen()
    banner_pos.y += banner_pos_dy
    hint_pos.y += hint_pos_dy
    p:update()
    update_particles()
   
    if btnp(❎) and highscore >= score_unlocks[p.sprite] then
        switch_screen_timer = 10
        banner_pos_dy = -3
        hint_pos_dy = 3
        dset(1, p.sprite)
    end
   
    if switch_screen_timer == -1 then
        if btnp(➡️) and p.sprite < 5 then
            p.sprite += 1
        end
   
        if btnp(⬅️) and p.sprite > 1 then
            p.sprite -= 1
        end
    end
   
    if switch_screen_timer > 0 then
        switch_screen_timer -= 1
    end
   
    if switch_screen_timer == 0 then
        switch_screen_timer = -1
        switch_screen("game")
    end
end

function init_game_screen()
    game_over = false
    spawn_enemy_timer = 50
    enemies = {}
    coins = {}
    coins_collected = 0
    start_time = flr(time())
    end_time = 0
    enemies_died = 0
    score_y = 1
    score_dy = 0
    next_enemy_position = new_enemy_position()
    enemy_warnig_sfx_playing = false
    warning_color = 7
    death_message = rnd(death_messages)
end

function draw_game_screen()
    camera(p.x-64, p.y-64)
    draw_particles()
    foreach(enemies, function(enemy)
        enemy:draw()
    end)
    foreach(coins, function(coin)
        coin:draw()
    end)
    if not game_over then
        p:draw()
    end
   
    -- ui
    camera(0, 0)
    -- time
    local time_str = ""..(flr(time()) - start_time)
    print(time_str, 64-((#time_str*4)/2), score_y+1, 13)
    print(time_str, 64-((#time_str*4)/2), score_y, 7)
    -- enemy died
    local enemies_died_str = ""..enemies_died
    print(enemies_died_str, 126-((#enemies_died_str*4)/2), score_y+1, 0)
    print(enemies_died_str, 126-((#enemies_died_str*4)/2), score_y, 1)
    -- coins
    local coins_str = ""..coins_collected.."X5"
    print(coins_str, 1, score_y+1, 9)
    print(coins_str, 1, score_y, 10)
   
    -- enemy warning
    if spawn_enemy_timer < 30 and not game_over then
        if next_enemy_position == "top" then
            line(64-20, 0, 64+20, 0, warning_color)
        elseif next_enemy_position == "bottom" then
            line(64-20, 127, 64+20, 127, warning_color)
        elseif next_enemy_position == "left" then
            line(0, 64-20, 0, 64+20, warning_color)
        elseif next_enemy_position == "right" then
            line(127, 64-20, 127, 64+20, warning_color)
        end
        warning_color = ({[7]=8,[8]=7})[warning_color]
    end
   
    -- game over
    function draw_score(name, value, y, value_postfix)
        print(name, 64-30, y, 13)
        print(name, 64-30, y-1, 7)
        local value_str = ""..value..value_postfix
        print(value_str, (66+30)-((#value_str*4)), y, 13)
        print(value_str, (66+30)-((#value_str*4)), y-1, 7)
        line(64-30, y+7, 64+30, y+7, 13)
        line(64-30, y+6, 64+30, y+6, 7)
    end
   
    if game_over then
        print(death_message, 64-(str_width(death_message)/2), 21, 13)
        print(death_message, 64-(str_width(death_message)/2), 20, 7)
        draw_score("time:", (end_time-start_time), 40, "")
        draw_score("coins:", coins_collected, 55, "X5")
        draw_score("enemies:", enemies_died, 70, "")
        draw_score("total:", total_score(), 85, "")
        if total_score() > highscore then
            spr(26, 100, 83, 2, 2)
        end
        print("press ❎ to play again",22, 111, 13)
        print("press ❎ to play again",22, 110, 7)  
    end
end

-- i'm smart
function str_width(str)
    return (print(str, 1000, 1000) - 1000)
end

function update_game_screen()
    if game_over then
        if btn(❎) then
            switch_screen("main")
            sfx(3)
        end
    end
    score_y += score_dy
    local enemies_to_delete = {}
   
    foreach(enemies, function(enemy1)
        enemy1:update()
        foreach(enemies, function(enemy2)
            if enemy1 != enemy2 then
                if distance(enemy1.x, enemy1.y, enemy2.x, enemy2.y) < 3 then
                    add(enemies_to_delete, enemy1)
                    add(enemies_to_delete, enemy2)
                    explode_effect(enemy1.x, enemy1.y)
                    if not game_over then
                        enemies_died += 1
                        add(coins, coin.new(enemy1.x, enemy1.y))
                    end
                end
            end
        end)
        if not game_over then
            if distance(p.x, p.y, enemy1.x, enemy1.y) < 8 then
                game_over = true
                sfx(0, -2)
                sfx(3, -2)
                score_dy = -1
                end_time = flr(time())
                explode_effect(p.x, p.y)
                if total_score() > highscore then
                    dset(0, total_score())
                end
            end
        end
    end)
   
    foreach(enemies_to_delete, function(enemy)
        del(enemies, enemy)
    end)
   
    local coins_to_delete = {}
   
    foreach(coins, function(coin)
        coin:update()
       
        if distance(coin.x, coin.y, p.x, p.y) < 8 then
            add(coins_to_delete, coin)
            if not game_over then
                coins_collected += 1
                sfx(2)
            end
        end
    end)
   
    foreach(coins_to_delete, function(coin)
        del(coins, coin)
    end)
   
    if not game_over then
        p:update()
        p:control()
    end
   
    update_particles()
    spawn_enemy_timer -= 1
   
    if spawn_enemy_timer == 0 then
        spawn_enemy_timer = 50
        if #enemies < 5 and not game_over then
            sfx(0, -2)
            enemy_warnig_sfx_playing = false
            add(
                enemies,
                enemy.new(
                    p.x+enemy_position_coord[next_enemy_position].x,
                    p.y+enemy_position_coord[next_enemy_position].y
                )
            )
            next_enemy_position = new_enemy_position()
        end
    end
   
    if spawn_enemy_timer < 30 and not game_over then
        if not enemy_warnig_sfx_playing then
            sfx(0, 1)
            enemy_warnig_sfx_playing = true
        end
    end
end

function new_enemy_position()
    local positions = {
        "top",
        "bottom",
        "left",
        "right"
        }
    return rnd(positions)
end

enemy_position_coord = {
    ["top"] = {x=0, y=-68},
    ["bottom"] = {x=0, y=68},
    ["left"] = {x=-68, y=0},
    ["right"] = {x=68, y=0}
}


function total_score()
    return (end_time-start_time)+(coins_collected*5)+enemies_died
end

function explode_effect(x, y)
    sfx(4, 2)
    for i=1, 10 do
        local v = vector.new(0, 4)
        v:rotate(rnd())
        add_particle(
            x+v.x,
            y+v.y ,
            v.x*0.5, v.y*0.5,
            rnd_rng(9, 11),
            5,
            4
        )
    end
    for i=1, 10 do
        add_particle(
            x+rnd_rng(-3, 3),
            y+rnd_rng(-3, 3),
            0, 0,
            7,
            10,
            2
        )
    end
end
-->8
-- particles

particles = {}

function add_particle(x, y, dx, dy, c, s, t)
    add(particles, {
        x = x,
        y = y,
        dx = dx,
        dy = dy,
        size_timer_dur = t,
        size_timer = t,
        size = s,
        c = c
    })
end

function draw_particles()
    foreach(particles, function(particle)
        circfill(particle.x, particle.y, particle.size, particle.c)
    end)
end

function update_particles()
    local particles_to_delete = {}
   
    foreach(particles, function(particle)
        particle.x += particle.dx
        particle.y += particle.dy
       
        particle.size_timer -= 1
       
        if particle.size_timer == 0 then
            particle.size_timer = particle.size_timer_dur
            particle.size -= 1
        end
       
        if particle.size < 0 then
             add(particles_to_delete, particle)
        end
    end)
   
    foreach(particles_to_delete, function(particle)
        del(particles, particle)
    end)
end
-->8
-- coin

coin = {}
coin.__index = coin

function coin.new(x, y)
    local o = {
        x=x,
        y=y,
        sprite = 17,
        sprite_timer = 5
    }
    setmetatable(o, coin)
    return o
end

function coin:draw()
    spr(self.sprite, self.x, self.y)
end

function coin:update()
    self.sprite_timer -= 1
    if self.sprite_timer == 0 then
        self.sprite_timer = 5
        self.sprite += 1
        if self.sprite == 20 then
            self.sprite = 17
        end
    end
end
-->8
-- utils

-- vector

vector = {}
vector.__index = vector

function vector.new(x, y)
    local o = {x=x, y=y}
    setmetatable(o, vector)
    return o
end

function vector.__add(v0, v1)
    local v = vector.new(0, 0)
    v.x = v0.x + v1.x
    v.y = v0.y + v1.y
    return v
end

function vector.__sub(v0, v1)
    local v = vector.new(0, 0)
    v.x = v0.x - v1.x
    v.y = v0.y - v1.y
    return v
end

function vector:len()
    return sqrt(sqr(self.x) + sqr(self.y))
end

function vector:normal()
    self.x /= self:len()
    self.y /= self:len()
end

function vector:scale(s)
    self.x *= s
    self.y *= s
end

-- a = 0-1
function vector:rotate(a)
    local sina = sin(a)
    local cosa = cos(a)
   
    local rotx = cosa*self.x-sina*self.y
    local roty = sina*self.x+cosa*self.y
    self.x = rotx
    self.y = roty
end

-- rotated sprite
-- this function has a bug related to sprite number
function spr_r(s,x,y,a,w,h)
    sw=(w or 1)*8
    sh=(h or 1)*8
    sx=(s%8)*8
    sy=flr(s/8)*8
    x0=flr(0.5*sw)
    y0=flr(0.5*sh)
    a=a/360
    sa=sin(a)
    ca=cos(a)
    for ix=sw*-1,sw+4 do
        for iy=sh*-1,sh+4 do
            dx=ix-x0
            dy=iy-y0
            xx=flr(dx*ca-dy*sa+x0)
            yy=flr(dx*sa+dy*ca+y0)
            if (xx>=0 and xx<sw and yy>=0 and yy<=sh-1) then
                pset(x+ix,y+iy,sget(sx+xx,sy+yy))
            end
        end
    end
end

-- random range
function rnd_rng(minv, maxv)
    return flr(
        rnd()*(maxv - minv)
    ) + minv
end

-- slowly transition to a value
function lerp(tar,pos,perc)
    return (1-perc)*tar + perc*pos;
end

-- why there isn't a sqr function!!
function sqr(v)
        return v * v
end

-- distance between two points
function distance(x1, y1, x2, y2)
    return sqrt(squaredist(x1-x2, y1-y2))
end

-- to prevent overflow
function squaredist(dx,dy)
 local sdx,sdy=shr(dx,8),shr(dy,8)
 return shl(min(0x0.7fff,sdx*sdx+sdy*sdy),16)
end
__gfx__
00000000ccc11cccccc11cccccc11ccccc1cc1ccc1cccc1ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000c117711ccc1771cccc1771ccc181181c1b1cc1b1cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0070070019966991c126621cc136631c1887788113b77b31ccc88ccccccaacccccccccccccccccccccccccccccccccccc77ccccccccccccccccccccccccccccc
000770001a9aa9a118288281c13bb31c1826628113b66b31cc8888ccccaaaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00077000111aa11118188181c11bb11c1282282113311331c88cc88ccaaccaaccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00700700c19aa91cc128821cc13bb31cc128821c1b1111b1c8cccc8ccaccccaccccccccccccccccccccccccccccccccccccccc77cccccccccccccccccccccccc
00000000cc1aa1cccc1881cccc1bb1cccc1881cc1b1cc1b1cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000c111111cc111111cc111111cccc11cccc1cccc1ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000cc1111cccc1111ccccc11cccccc11cccccccccccccccccccccc11ccccccccccccccccccccc888888888ccccccccccccccccccccccccccccccccccccc
00000000c1a7771ccc1a71cccc19a1cccc17a1cccccccccccccccccccc1821cccccc77cccc77ccccc87777777778cccccccccccccccccccccccccccccccccccc
000000001aa99a71c1aaa71ccc19a1ccc17aaa1ccccccccccccccccccc1221ccccc77dccccd77cccc87878788878cccccccccccccccccccccccccccccccccccc
000000001a9aa7a1c1a97a1ccc19a1ccc1a79a1ccccccccccccccccccc1001cccc77dccccccd77cc877888778778cccccccccccccccccccccccccccccccccccc
000000001a9aa7a1c1a97a1ccc19a1ccc1a79a1ccccccccccccccccccc1001cccc77cccccccc77cc877888778778cccccccccccccccccccccccccccccccccccc
0000000019a77aa1c19aaa1ccc19a1ccc1aaa91ccccccccccccccccccc1001ccccd77cccccc77dcc287878788878cccccccccccccccccccccccccccccccccccc
00000000c1999a1ccc19a1cccc19a1cccc1a91cccccccccccccccccccc1001cccccd77cccc77dccc287777777778cccccccccccccccccccccccccccccccccccc
00000000cc1111ccccc11cccccc11cccccc11cccccccccccccccccccc111111cccccddccccddccccc28888888882cccccccccccccccccccccccccccccccccccc
00000000777777cc777777cc777777cc77cc77cc777777cc777777cccc7777ccc77ccccccccccccccc222222222ccccccccccccccccccccccccccccccccccccc
00000000777777cc777777cc777777cc77cc77cc777777cc777777cccc7777ccc77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000077dd77cc77dd77cc77ddddcc77cc77cc77ddddccdd77ddcc77ddddccc77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000077dd77cc77dd77cc77ddddcc7777ddcc7777ddccdd77ddcc77ddddccc77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000007777ddcc77dd77cc77cccccc7777ddcc7777cccccc77ccccddcc77cccddccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000007777ddcc77dd77cc77cccccc77dd77cc77ddcccccc77ccccddcc77cccddccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000077dd77cc777777cc777777cc77dd77cc777777cccc77cccc7777ddccc77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000077dd77cc777777cc777777cc77cc77cc777777cccc77cccc7777ddccc77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000ddccddccddddddccddddddccddccddccddddddccccddccccddddcccccddccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000ddccddccddddddccddddddccddccddccddddddccccddccccddddcccccddccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666ccccccccccccccccccccccccccc66666cccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccc77777ccccccccccccccccccccccccccc66666666cccccccccccccccccccccc6666ccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccc7777777777cccccccccccccccccccccccccccc6666666666ccccccccccccccc666666666666cccccccccccccccc
cc777777777cccccccccccccccccccccccccccccccc77777777cccccccccccccccccccc6666666666666cccccccccccccccccccccc6666666ccccccccccccccc
ccc77777777777ccccccccccccccccccccccccccccc7777777777777cccccccccccccccccccc666666ccccccccccccccccccccccccccccc6666ccccccccccccc
ccc777777777777777ccccccccccccccccccccccccccc777777777777cccccccccccccccccccccccccccccccc666ccccccccccc666c6cccccccccccccccccccc
cccccccc777777777777ccccccccccccccccccccccccccccccc7777ccccccccccccccccccccccccccccccccccc666ccccccccccccccccccccccccccccccccccc
ccccccc777777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccc777777777777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc77777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc77777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccc77777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccc6666666666cccccccc
ccccccccccccccccccccccccccccccccccccccc77777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc666666666cccccccccccc
cccccccccccccccccccccccccccccccccccccccc7777777777777ccccccccccccccccccccccc6666cccccccccccccccccccccccc666666666ccccccccccccccc
ccccccccccccccccccccccc777777cccccccccc777cccccccc7777777cccccccccccccccc666666ccccccccccccccccccccccc66666666666666cccccccccccc
cccccccccccccccccccccc7777777777ccccc777cccccccccccccccccccccccccccccc6666cccccccccccccccccccccccccccccc666666cccc6666cccccccccc
ccccccccccccccccc7777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc666ccccccccccccccccccccccc
cccccccccccccccc7777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc77777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccc6666ccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc77777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6666cccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
f1f1d3f1d3e3f1f1f1f1f1f1f1d3e3f1f1f1f1f1f1f1d3e3f1f1f1f1f1f1f1d3e3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1e2f1f1f1d2e2f1f1f1d2f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1e3f1f1f1d3e3f1f1f1d3f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1d3e3f1f1f1f1f1f1f1d3e3f1f1f1f1f1f1f1d3e3f1f1f1f1f1f1f1d3e3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1f1f1f1f1f1d2e2f1f1f1d2f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1f1f1f1f1f1d3e3f1f1f1d3f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d2e2f1f1f1f1f1f1f1f1d2
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d2e2f1f1f1d2e2f1f1f1f1f1f1f1f1f1f1f1f1f1d2
e2f1f1f1d2e2f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d2e2f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1f1f1f1d2e2f1d3
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1f1d3e3f1f1f1f1f1f1f1f1f1f1f1f1f1d3
e3f1f1f1d3e3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1
d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1
d2f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1
d3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d2e2f1f1f1d2e2f1f1f1d2
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1f1d3e3f1f1f1d3
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1
d2f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1
d3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d2e2f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1d2e2f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1d3e3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1
d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1
d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1d2e2f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1d3e3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
caaacccccaaacccccccccccccccccccccccccccccccccccccccccccccccccc777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cc
ca9acacaca99cccccccccccccccccccccccccccccccccccccccccccccccccc7d7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc01cc
cacac9a9caaacccccccccccccccccccccccccccccccccccccccccccccccccc777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1cc
cacaccacc99accccccccccccccccccccccccccccccccccccccccccccccccccdd7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1cc
caaaca9acaaacccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111c
c999c9c9c999ccccccccccccccccccccccccccccccccccccccccccccccccccccdccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccc77777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccc7777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccc77777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccc7777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccc77777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccc7777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777ccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777cccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777cccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777ccccccccccc666cccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777cccccccccccccccccccc666ccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6666ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc666666666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6666666ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6666ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66c6cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
77777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
77ccccccccccccccccccc666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccc666ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1769917ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc196a9a1cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777199aaa11cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccc11ccccccccccccccccccccccccccccccccccccccccccccccccc7cc111aa9ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc19a1cccccccccccccccccccccccccccccccccccccccccccccccccc7119aa111ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc19a1ccccccccccccccccccccccccccccccccccccccccccccccccc77ccc111177cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc19a1cccccccccccccccccccccccccccccccccccccccccccccccccc7cc11ccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc19a1cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc19a1cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccc666cccccccc
cccccc19a1cccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccc777cccccccccccccccccccccccccccccccccccccccccccccc666ccccccc
ccccccc11cccccccccccccccccccccccccccccccccccccccccccccccccc777ccc666cc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7c7666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777ccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccccc777ccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccc111cccccccccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc1221cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc1021cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccc10001cccccccccccccccccccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccc1001ccccccccccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccc111001ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccc1111cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccc111cccccc00011cccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccc1182ccccccc0ccccccccccccccccccccccccc7cccccccccccccccccccccc6666666666cccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccc10211cccccccccccccccccccccccccccccccccccccccccccccccccccc666666666cccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccc10001cccccccccccccccccccccccccccccccccccccccccccccccccc666666666ccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccc111001cccccc0ccccccccccccccccccccccccc7cccccccccccccccc66666666666666cccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccc110011ccccc000ccccccccccccccccccccccccccccccccccc7ccccccc666666cccc6666cccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccc0c111ccccc0c0cccccccccccccccccccccccccccccccccccccccccc666ccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccc000c11cccc000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccc0ccccccccc0ccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccc0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc00cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccc0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccc111cccccc000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc07cc1182ccccccc0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccc77700ccc1021ccc77c0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc770cc10001ccccc000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccc7ccc1001ccc77cc0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc077110011cc777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777cccccccccccccccccccccccccccccccc
cccccccccc7000cc0111cccc6666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777ccccccccccccccccccccccccccccc
ccccccccc0cc0cc00011cc66666ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777ccccccccccccccccccccccccc
cccccccc000ccccc0c66c6ccccc0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777ccccccccccccccccccccccc
ccccccccc0cccccccccccccccc000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777777cccccccccccccccccc
cccccccccccccc0cccccccccccc0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777777777777cccccccccccc
cccccccc0cccc000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777ccccccccccccccccccccccc
ccccccc000cccc0ccccccccccc0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777ccccccccccccccccc
cccccccc0cccccccccccccccc000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777cccccccccccccccccccccc
cccccccccccc0ccccccccccccc0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccc0ccccc000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc000ccccc0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccc0cccccccccccccccccccc0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc0cccccccccccccccc000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccc0ccc000cccccccccccccccc0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc000c0c0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666cccccccccccccc
ccc0c000cccccccccccccccccc0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6666ccccccccccccccccc
cccccc0cccccccccccccccccc000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc666666666666cccccccccccc
cc0ccccccccccccccccccccccc00cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6666666ccccccccccc
c0000ccccccccccccccccccccc000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6666ccccccccc
cc0000ccccccccccccccccccccc0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66c6cccccccccccccccc
cccc0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
__map__
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f404142431f1f1f1f1f1f1f1f1f1f1f606060601f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f505152531f1f1f2d2e1f1f1f2d2e60444546601f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
2d606160601f1f1f1f1f1f1f1f60601f605556602d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d494a1f1f2d1f1f1f1f1f1f5b1f1f1f1f1f1f1f1f4c4d4e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
3d606060601f1f1f1f1f1f1f1f1f1f607060606060601f1f1f3d3e1f1f1f3d3e1f1f1f3d595a5b1f3d1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f5d5e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f601f1f2d2e1f1f1f1f1f1f1f1f1f601f60601f1f601f1f1f6465661f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f3d3e1f1f1f444546431f601f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f1f1f55561f1f1f1f1f1f1f1f1f1f1f1f60606060601f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f434342431f1f60606060601f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f601f1f1f1f3d3e1f1f1f1f1f1f1f1f4371727343431f1f60606060606060601f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f5b1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f60601f1f1f1f1f1f1f1f1f1f1f1f1f1f43434343431f1f70606060601f1f1f1f6c6d6e1f1f1f1f1f1f1f4c4d4e1f1f1f1f1f5b1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f7172731f1f1f1f1f1f1f1f606042601f1f1f2d2e1f1f60601f1f1f1f1f7c7d7e1f1f1f1f1f1f1f1f5d5e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f1f1f1f1f
1f1f2d2e1f1f1f3d3e1f1f1f1f1f1f1f1f1f1f1f1f1f1f3d3e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e5b1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f1f1f1f1f
1f1f3d3e1f1f1f1f3d3e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f1f1f1f1f1f3d3e1f1f1f1f1f1f1f1f1f1f1f1f1f4445461f1f1f1f1f1f1f1f1f1f1f1f1f1f7a1f1f1f1f1f1f5b1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f601f1f1f1f1f1f1f55561f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f60606060601f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f6c6d6e1f1f1f1f1f1f1f68691f1f1f1f1f5b1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f3d3e1f1f6465661f1f3d3e1f1f1f40411f604260606060601f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f7c7d7e1f1f1f1f1f1f1f78791f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f741f1f1f1f1f1f1f1f1f505152536060606060601f1f1f1f1f1f1f1f1f1f1f68696a1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f2d2e1f1f1f1f1f1f1f2d2e1f1f1f1f1f1f606060606060601f0808431f1f1f5b1f1f1f78792e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2d2e1f1f1f1f1f1f2d2e1f1f1f2d2e2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f3d3e1f1f1f1f1f1f1f3d3e1f1f1f1f1f1f606060606060601f0808431f1f1f1f1f1f1f1f3d3e1f1f1f1f1f1f1f1f4c4d4e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f3d3e1f1f1f1f1f1f3d3e1f1f1f3d3e3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f601f1f606060601f0808431f2d2e1f1f1f2d1f48494a1f1f1f1f1f2d2e1f5d5e2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f1f1f1f1f
1f1f2d1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f6060601f6060602e0808431f3d3e1f1f1f3d1f1f1f1f1f1f1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f3d1f3d3e1f1f1f1f1f1f1f3d3e1f1f1f1f1f1f6060601f6060603e1f08431f1f1f1f1f1f1f1f3d3e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f1f1f1f1f44451f1f1f1f1f1f1f606060606060601f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f7172731f1f1f1f1f1f1f55561f1f1f1f1f1f6060606060601f1f1f1f2d2e1f1f1f1f1f1f1f2d2e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f3d3e1f1f1f1f1f1f1f3d3e1f1f1f1f1f1f6060606060601f1f1f1f3d3e1f1f1f1f1f1f1f3d3e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f68691f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f6060646566601f1f1f1f1f1f1f1f6c6d6e1f1f1f1f1f1f1f1f1f48494a1f1f1f1f1f1f1f1f1f78791f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f60746060601f1f1f1f1f1f1f1f7c7d7e1f1f1f1f1f1f1f1f1f1f595a5b1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2d2e1f1f1f1f1f1f2d2e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2d
1f1f1f1f3d3e4340411f1f1f1f3d3e1f1f1f1f1f1f601f6060601f1f1f1f1f3d3e1f1f1f1f1f5b1f3d3e1f1f1f1f1f1f1f1f1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f1f1f2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f1f1f2d2e1f3d
1f1f1f1f1f1f43505152531f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2e1f1f1f2d2e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f1f1f3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f1f3d3e1f1f
1f1f2d1f2d2e1f1f1f1f1f1f1f2d2e1f1f1f1f1f1f1f2d2e1f1f1f1f1f1f1f2d2e1f1f1f1f1f1f1f1f1f2d2e3d3e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800003805035050310502e0502c0502a05028050250502405023050210501f0501d0501b0500d0500005000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000369503b9503f9501a1001b1001b1001b1001a1001e6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800200c0351004515055170550c0351004515055170550c0351004513055180550c0351004513055180550c0351104513055150550c0351104513055150550c0351104513055150550c035110451305515055
000a00001765002650026500265002650026500265003600036000360007700087000ab000ab000ab000ab000ab000cb000ab000ab000cb000ab000cb000bb000ab000bb000ab000ab000bb000ab000ab000cb00
