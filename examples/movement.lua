x = 64  y = 64
function _update()
  if (btn(0)) then x=x-1 end
  if (btn(1)) then x=x+1 end
  if (btn(2)) then y=y-1 end
  if (btn(3)) then y=y+1 end
end

function _draw()
  rectfill(0,0,127,127,5)
  rectfill(0,0,64,64,2)
  print("this is movement", 37, 70, 14)
  circfill(x,y,7,8)
end
