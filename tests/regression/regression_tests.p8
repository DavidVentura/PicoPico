__lua__
function test_map_no_args()
  map() -- no arguments
end
function test_circ_top_left_edge()
  circ(5, 5, 10) -- radius is > X, shouldn't overflow
end
