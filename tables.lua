--[[ This file focuses on iterators, like pairs and ipairs. It defines functions similar to LINQ that return iterators. ]]--

local iterators = {}

local function isIterator(o)
  return type(o) == "function" or iterators[o]
end

local function asIterator(o)
  return isIterator(o) and o or table.iterator(o)
end

--- Converts a table or iterator function into an iterator object.
-- An iterator object is just a wrapper for an iterator function with additional functionality attached to it.
-- @param target The object to iterate. If `target` is an iterator object or function, this function simply wraps it. If `target` is a table, this function creates an iterator object from it.
-- @param valuesOnly Whether to iterate through only the values of `target`. This parameter is only used if `target` is a table.
function table.iterator(target, valuesOnly)
  -- If onCall is a table to iterate, then convert it to a stateless iterator function
  if not isIterator(target) then
    local t = target
    local nxt = pairs(t)
    local k, v
    target = function()
      k, v = nxt(t, k)
      
      if valuesOnly then
        return v
      end
      
      return k, v
    end
  end
  
  -- Create the iterator
  local iter = {}
    
  iter.where = function(predicate)
    return table.iterator(function()
      local ret
      repeat
        ret = {target()}
      until #ret == 0 or predicate(unpack(ret))
      return unpack(ret)
    end)
  end
  
  iter.select = function(predicate)
    return table.iterator(function()
      local ret = {target()}
      if #ret > 0 then
        return predicate(unpack(ret))
      end
    end)
  end
  
  iter.concat = function(...)
    local joined = {...}
    
    return table.iterator(function()
      local ret = {target()}
      
      while #ret == 0 and #joined > 0 do
        target = asIterator(table.remove(joined, 1))
        ret = {target()}
      end
      
      if #ret > 0 then
        return unpack(ret)
      end
    end)
  end
  
  iter.join = function(inner, selector)
    inner = asIterator(inner)
    selector = selector or function(...) return ... end
    
    return table.iterator(function()
      local ret1 = {target()}
      local ret2 = {inner()}
      
      if #ret1 > 0 and #ret2 > 0 then
        for i, v in ipairs(ret2) do
          table.insert(ret1, v)
        end
        
        return selector(unpack(ret1))
      end
    end)
  end
  
  iter.any = function(predicate)
    local ret = {target()}
    while #ret > 0 do
      if predicate(unpack(ret)) then
        return true
      end
      ret = {target()}
    end
    return false
  end
  
  iter.totable = function(keySelector, valueSelector)
    local t = {}
    local ret = {target()}
    if keySelector then
      -- Use keySelector to select keys
      while #ret > 0 do
        t[keySelector(unpack(ret))] = valueSelector and valueSelector(unpack(ret)) or ret[1]
        ret = {target()}
      end
    else
      -- Keys will be an incrementing integer starting at 1.
      local i = 1
      while #ret > 0 do
        t[i] = valueSelector and valueSelector(unpack(ret)) or ret
        ret = {target()}
        i = i + 1
      end
      --end
    end
    return t
  end
  
  iterators[iter] = true
  return setmetatable(iter, {
    __call = target
  })
end

--- Returns an iterator containing number values.
-- If no `start` is defined, this function will start at `1`.
-- @param start Optional. What number to start at. Default value is `1`. (Inclusive)
-- @param finish What number to end at. (Inclusive)
-- @param step Optional. Difference between each element. Default value is `1`.
function table.range(start, finish, step)
  step = step or 1
  if not finish then
    finish = start
    start = 1
  end
  
  local i = start - step
  return table.iterator(function()
    i = i + step
    return i <= finish and i or nil
  end)
end