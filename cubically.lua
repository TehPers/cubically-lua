require("cube")
require("iterators")
require("codepage")

-- Interpreter
local C = {}

function C.new(options)
  options = (type(options) == "table") and options or {}
  
  local cubically = setmetatable({
    cube = Cube.new(options.size),
    notepad = 0,
    input = 0,
    accumulator = {},
    options = options
  }, {__index = C})

  cubically.codepage = Codepage.new(cubically)
  
  return cubically
end

function C:exec(program)
  assert(self.cube, "Must be an instance, call new() first")
  assert(type(program) == "string", "program must be a string")
  
  self.program = self.codepage:tochars(self.codepage:utf8bytes(program))
  self.ptr = 1
  self.loops = {}
  self.conditionFailed = false
  self.doElse = false
  self.didCommand = false
  self.command = nil
  self.commandIndex = nil
  while self.ptr <= #self.program do
    local b, index = self:next()
    local ptr = self.ptr
    
    if self.codepage:arg(b, index) then
      -- Face-valued command argument
      if self.command then
        self:command(self.codepage:arg(b, index))
        self.didCommand = true
        self.doElse = false
      end
    elseif self.conditionFailed then
      -- Command being skipped by a conditional
      
      self:skipcmd()
      self.conditionFailed = false
      self.doElse = true
    else
      -- Command
      
      if self.command and not self.didCommand then
        -- Implicitly call the command
        self:command()
        self.didCommand = true
        self.doElse = false
      end
      
      if self.ptr == ptr then
        -- Call the current command if the pointer didn't move
        self.command = self.commands[b]
        self.commandIndex = index
        self.didCommand = false
      end
    end
        
    if self.ptr > #self.program and self.command and not self.didCommand then
      self:command()
      self.didCommand = true
    end
  end
end

function C:next()
  local b = self:nextChar()
  local index = nil
  local ptr = self.ptr
  local cur = self:nextChar()
  while cur do
    if self.codepage:faceindex(cur) then
      index = self.codepage:faceindex(cur)
    elseif self.codepage:constindex(cur) then
      if type(index) ~= "string" then
        index = ""
      end
      index = index .. self.codepage:constindex(cur)
    else
      break
    end
    ptr = self.ptr
    cur = self:nextChar()
  end
  self.ptr = ptr
  
  return b, tonumber(index)
end

function C:nextChar()
  local c = self.program[self.ptr]
  if c == "\\" then
    -- Escape sequence
    local charsLeft = 2
    local hex = 0
    self.ptr = self.ptr + 1
    local cur = self.program[self.ptr]
    while cur and charsLeft > 0 and self.codepage:hex(cur) do
      hex = hex * 16 + self.codepage:hex(cur)
      
      self.ptr = self.ptr + 1
      cur = self.program[self.ptr]
      charsLeft = charsLeft - 1
    end
    return hex
  elseif c == "𝐶" then
    -- Character set
    self.ptr = self.ptr + 1
    local cur = self.program[self.ptr]
    self.ptr = self.ptr + 1
    return cur and self.codepage.bytes[cur] + 0x100 or -1
  else
    self.ptr = self.ptr + 1
  end
  return self.codepage.bytes[c]
end

function C:skipcmd()
  local level = 0
  local c = self.program[self.ptr]
  local extraSkip
  local ptr = self.ptr
  repeat
    extraSkip = c == "?"
    
    repeat
      if c == "{" then
        level = level + 1
      elseif c == "}" then
        level = level - 1
      end
      
      ptr = self.ptr
      c = self.codepage.chars[self:next()]
    until self.ptr > #self.program or (level == 0 and not self.codepage:arg(c))
  until not extraSkip
  self.ptr = ptr
end

function C:value(n, index)
  if n % 1 ~= 0 then
    return 0
  end
  
  if n >= 0 and n <= 5 then
    return self.cube:value(n, index)
  elseif n == 6 then
    return self.notepad
  elseif n == 7 then
    return self.input
  elseif n == 8 then
    return self.cube:solved() and 0 or 1
  else
    return 0
  end
end

C.commands = {
  ['R'] = function(self, n)
    self.cube:R(n or 1, self.commandIndex)
  end,
  ['L'] = function(self, n)
    self.cube:L(n or 1, self.commandIndex)
  end,
  ['U'] = function(self, n)
    self.cube:U(n or 1, self.commandIndex)
  end,
  ['D'] = function(self, n)
    self.cube:D(n or 1, self.commandIndex)
  end,
  ['F'] = function(self, n)
    self.cube:F(n or 1, self.commandIndex)
  end,
  ['B'] = function(self, n)
    self.cube:B(n or 1, self.commandIndex)
  end,
  
  [':n'] = function(self, n)
    self.notepad = n
  end,
  ['+n'] = function(self, n)
    self.notepad = (self.commandIndex or self.notepad) + n
  end,
  ['-n'] = function(self, n)
    self.notepad = (self.commandIndex or self.notepad) - n
  end,
  ['*n'] = function(self, n)
    self.notepad = (self.commandIndex or self.notepad) * n
  end,
  ['/n'] = function(self, n)
    self.notepad = (self.commandIndex or self.notepad) / n
  end,
  ['ⁿ'] = function(self, n)
    self.notepad = (n or self.notepad) ^ (self.commandIndex or 2)
  end,
  ['%n'] = function(self, n)
    self.notepad = (self.commandIndex or self.notepad) % n
  end,
  ['√'] = function(self, n)
    self.notepad = (n or self.notepad) ^ (1 / (self.commandIndex or 2))
  end,
  ['ṡ'] = function(self, n)
    self.notepad = math.sin(n or self.notepad)
  end,
  ['ċ'] = function(self, n)
    self.notepad = math.cos(n or self.notepad)
  end,
  ['Ṡ'] = function(self, n)
    self.notepad = math.asin(n or self.notepad)
  end,
  ['Ċ'] = function(self, n)
    self.notepad = math.acos(n or self.notepad)
  end,
  
  ['~'] = function(self, n)
    self.notepad = -(n or self.notepad)
  end,
  
  ['«'] = function(self, n)
    self.notepad = bit32.arshift(self.commandIndex or self.notepad, -(n or 1))
  end,
  ['»'] = function(self, n)
    self.notepad = bit32.arshift(self.commandIndex or self.notepad, n or 1)
  end,
  ['&n'] = function(self, n)
    self.notepad = bit32.band(self.commandIndex or self.notepad, n)
  end,
  ['|n'] = function(self, n)
    self.notepad = bit32.bor(self.commandIndex or self.notepad, n)
  end,
  ['^'] = function(self, n)
    self.notepad = n and bit32.bxor(self.commandIndex or self.notepad, n) or bit32.bnot(self.commandIndex or self.notepad)
  end,
  ['¬'] = function(self, n)
    self.notepad = (n or self.notepad) == 0 and 1 or 0
  end,
  
  ['>n'] = function(self, n)
    self.notepad = ((self.commandIndex or self.notepad) > n) and 1 or 0
  end,
  ['<n'] = function(self, n)
    self.notepad = ((self.commandIndex or self.notepad) < n) and 1 or 0
  end,
  ['=n'] = function(self, n)
    self.notepad = ((self.commandIndex or self.notepad) == n) and 1 or 0
  end,
  
  ['.'] = function(self, n)
    if not n or n ~= 0 then
      self.ptr = #self.program + 1
    end
  end, 
  ['('] = function(self, n)
    local label
    if self.didCommand then
      label = self.loops[#self.loops]
    else
      label = {
        ptr = self.ptr,
        args = {}
      }
      
      while self.program[label.ptr] ~= "(" do
        label.ptr = label.ptr - 1
      end
      
      table.insert(self.loops, label)
    end
  
    if n then
      label.args[n] = true
    else
      label.args = nil
    end
    
    label.index = self.commandIndex
  end,
  [')'] = function(self, n)
    local label = table.remove(self.loops)
    if label then
      if (not n or n ~= 0) and (not label.args or table.iterator(label.args):any(function(arg) return self:value(arg) ~= 0 end)) then
        -- Jump to the `(`
        self.ptr = label.ptr
        return
      else
        self.ptr = self.ptr - 1
        self:skipcmd()
      end
    end
  end,
  ['?'] = function(self, n)
    if (n or self.notepad) == 0 then
      self.conditionFailed = true
    else
      self.conditionFailed = false
      self:skipcmd()
    end
  end,
  ['{'] = function(self, n) end,
  ['}'] = function(self, n) end,
  ['!'] = function(self, n)
    if not self.doElse then
      if n then
        if self.program[self.ptr - 1] == "!" then
          self:skipcmd()
          self.conditionFailed = true
          return
        end
      else
        self:skipcmd()
        self.conditionFailed = true
        return
      end
    end
    
    if not n then
      self.conditionFailed = false
    elseif n == 0 then
      self.conditionFailed = true
    else
      self.conditionFailed = false
      self.doElse = false
      self:skipcmd()
    end
  end,
  
  ['"'] = function(self, n)
    -- TODO: Maybe make the index select what base to output this in?
    io.write(tostring(n or self.notepad))
  end,
  ['@'] = function(self, n)
    io.write(string.char(math.floor(n or self.notepad) % 256))
  end,
  ['$'] = function(self, n)
    self.input = io.read("*n") or self.input
  end,
  ['_'] = function(self, n)
    local inp = io.read(1)
    self.input = inp and string.byte(inp) or -1
  end,
  
  ['■'] = function(self, n)
    self.cube = Cube.new(n)
  end,
  ['ƒi'] = function(self, n)
    self.cube:setFace(self.commandIndex, n)
  end,
  ['𝔸'] = function(self, n)
    local accum = self.accumulator[self.commandIndex or 0]
    self.accumulator[self.commandIndex or 0] = n or (accum and (accum + 1) or 0)
  end,
  
  ['ρ'] = function(self, n)
    local function isPrime(n)
      local sqrt = math.sqrt(n)
      for i = 2, sqrt do
        if n % i == 0 then
          return false
        end
      end
      return true
    end
    
    local iterator
    if n then
      -- Make `iterator` iterate through prime factors of `n` such that `1 < f < n`, where `f` is the factor
      iterator = n % 1 == 0 and table.range(2, n - 1):where(function(i) return n % i == 0 end) or table.iterator(function() end)
    else
      -- Make `iterator` iterate through all prime factors greater than 1
      local i = 1
      iterator = table.iterator(function()
        i = i + 1
        return i
      end)
    end
    iterator = iterator:where(function(n) return isPrime(n) end)
    
    iterator:skip(self.commandIndex or 0)
    self.notepad = iterator() or 0
  end,
  
  ['`'] = function(self, n)
    print(self.cube:tostring())
    print("Notepad: " .. self.notepad)
    print("Input: " .. self.input)
    print()
  end
}

-- Parse commands
C.commands = table.iterator(C.commands)
  :select(function(cmd, func)
    local chars = Codepage:utf8raw( cmd)
    cmd = Codepage.bytes[chars[1]]
    local args = table.concat(chars, "", 2)
        
    if args:match("n") then
      local f = func
      func = function(self, n)
        return n and f(self, n) or nil
      end
    end
    
    if args:match("i") then
      local f = func
      func = function(self, n)
        return self.commandIndex and f(self, n) or nil
      end
    end
    
    return cmd, args, func
  end)
  :totable(function(cmd, args, func) return cmd end, function(cmd, args, func) return func end)

_G.Cubically = C