__lua__
function test_map_no_args()
  map() -- no arguments
end

function test_print_p8scii_color()
  cls(0)
  camera(0, 0)
  print("a\f3a", 1, 0, 7)
  -- should be the same
  --print("a", 1, 0, 7)
  --print("a", 5, 0, 3)
-- expect
-- > .777.333.........
-- > .7.7.3.3.........
-- > .777.333.........
-- > .7.7.3.3.........
-- > .7.7.3.3.........
  debug_mem(0, 0, 10, 5)
  -- these are the values set for 1 A
  local pixels = { {0,0}, {1,0}, {2,0},
  		   {0,1},        {2,1},
  		   {0,2}, {1,2}, {2,2},
  		   {0,3},        {2,3},
  		   {0,4},        {2,4},
		   }

  -- first A
  local offset=1
  for i, v in ipairs(pixels) do
    _x, _y = v[1], v[2]
    assert(pget(_x+offset, _y) == 7)
  end
  -- second A
  local offset=5
  for i, v in ipairs(pixels) do
    _x, _y = v[1], v[2]
    assert(pget(_x+offset, _y) == 3)
  end

end

function debug_mem(sx, sy, w, h)
  printh("")
  for y=sy,h do
    s = ""
    for x=sx,w do
         s = s .. pget(x, y)
    end
    printh(s)
  end
end
