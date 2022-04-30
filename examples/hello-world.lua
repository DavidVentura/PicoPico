t = 0
function cos(angle)
	return math.cos(2 * math.pi * angle)
end

-- music(0) -- play music from pattern 0
function _draw()
  cls()
  for i=1,11 do               -- for each letter
    for j=0,7 do              -- for each rainbow trail part
      t1 = t + i*4 - j*2      -- adjusted time
      y = 25-j + cos(t1/50)*5 -- vertical position
      pal(7, 14-j)            -- remap colour from white
      spr(16+i, 8+i*8, y)     -- draw letter sprite
    end
  end

  print("this is pico-8", 37, 50, 14)
  print("nice to meet you", 34, 60, 12)
  spr(1, 64-4, 70) -- draw heart sprite
  t = t+1
end
