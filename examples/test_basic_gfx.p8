__lua__
function _draw()
	cls(0)
	rect(2, 2, 18, 18, 7)
	rectfill(20, 2, 36, 18, 9)
	-- circ != circfill
	circ(10, 30, 8, 7)
	circfill(28, 30, 8, 9)

	line(10, 44, 28, 44, 3)
	line(10, 44, 28, 54, 4)
	line(10, 54, 28, 54, 5)
	line(10, 54, 28, 44, 6)


	-- line(20, 0, 20, 100, 6)
	ovalfill(2, 90, 36, 110, 9)
	oval    (2, 90, 36, 110, 8)

	print("this is normal-sized", 		40, 2, 7)
	print("\^wdouble-wide", 		40, 12, 7)
	print("\^tdouble-tall", 		40, 22, 7)
	print("\^t\^wdouble-double", 		40, 38, 7)
	print("this is \f8red", 		40, 54, 7)
	print("this is \f8red\f7-\f3green", 	40, 64, 7)

end
