function all(a)
    if (a == nil) return function() end

    local t = {}
    local i = 0
    local n = #a

    for x = 1, n do 
	t[x] = a[x]
    end

    return function()
	if(i <= n) then
	    i = i+1
	    return t[i]
	end 
    end	
end

sub = string.sub

function add(a, val)
    if a != nil then 
	table.insert(a, val)
    end
    return val
end

function del(a, val)
    if a != nil then
	for k, v in pairs(a) do
	    if val == v then
		return table.remove(a, k)
	    end
	end
    end
end

function count(a)
    return #a
end

function foreach(a, f)
    for v in all(a) do
	f(v)
    end
end


__assert = assert
function assert(cond, msg) 
    if not cond then
	printh("assertion failed:")
	__assert (false, msg)
    end
end

yield = coroutine.yield
cocreate = coroutine.create
coresume = coroutine.resume
costatus = coroutine.status

-- constants for input/buttons
⬅️ = 0
➡️ = 1
⬆️ = 2
⬇️ = 3
🅾 = 4
❎ = 5
