function _debug_dump(o)
    if type(o) == 'table' then
	local s = '{ '
	for k,v in pairs(o) do
	    if type(k) ~= 'number' then k = '"'..k..'"' end
	    s = s .. '['..k..'] = ' .. _debug_dump(v) .. ','
	end
	return s .. '} '
    else
	return tostring(o)
    end
end

function add(t, value, index)
    if index == nil then
	t[#t+1] = value
    else
	table.insert(t, index, value)
    end
    return value
end

function _test_add()
    t = {1, 5}
    v = add(t, 7)  -- t = {1, 5, 7}
    assert(table.concat(t) == table.concat({1, 5, 7}))
    assert(v == 7)
    add(t, 3, 2)  -- t = {1, 3, 5, 7, 9}
    assert(table.concat(t) == table.concat({1, 3, 5, 7}))
end
