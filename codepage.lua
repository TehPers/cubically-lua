

-- Codepage
-- First 128 characters are auto-populated below if not explicitly set here
local Codepage = {}
local INH = false -- Inherit from ASCII table, equivalent to `nil`
Codepage.chars = {
  [0] = 
  -- _0   _1   _2   _3   _4   _5   _6   _7   _8   _9   _A   _B   _C   _D   _E   _F
     nil, nil, nil, nil, nil, nil, nil, nil, nil, INH, nil, nil, nil, nil, nil, nil, -- 0_ -- 0A is `\n`
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- 1_
     " ", "!", '"', "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", -- 2_
     "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", -- 3_
     "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", -- 4_
     "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", INH, "]", "^", "_", -- 5_ -- 5C is `\`
     "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", -- 6_
     "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~", nil, -- 7_
     "₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉", "ⁿ", "√", "ṡ", "ċ", "Ṡ", "Ċ", -- 8_
     "⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹", "¬", "«", "»", nil, nil, nil, -- 9_
     "𝟘", "𝟙",  "𝟚", "𝟛", "𝟜", "𝟝", "𝟞",  "𝟟", "𝟠", "𝟡", "■", "ƒ", nil, nil, nil, nil, -- A_
     "½", "π", "φ", "𝑒", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- B_
     "ρ", "𝔸", "𝕒", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- C_
     "𝐶", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- D_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- E_
     nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- F_
}

-- First 128 characters
for i = 0, 127 do
  Codepage.chars[i] = Codepage.chars[i] or string.char(i)
end

-- Reverse lookup
Codepage.bytes = {}

for i = 0, 255 do
  if Codepage.chars[i] then
    Codepage.bytes[Codepage.chars[i]] = i
  end
end

-- Metatables for undefined characters
setmetatable(Codepage.chars, {
  __index = function(self, k)
    return rawget(self, k) or "�"
  end
})

setmetatable(Codepage.bytes, {
  __index = function(self, k)
    return rawget(self, k) or -1
  end
})

-- String to utf8 character array conversion
local ascii = {}
for i = 0, 255 do
  ascii[i] = string.char(i)
end

function Codepage.new(cubically)
  return setmetatable({
    cubically = cubically
  }, {
    __index = Codepage
  })
end

function Codepage:utf8raw(str)
  local bytes = {}
  local ptr = 1
  local len = str:len()
  
  local cur = nil
  local bytesleft = 0
  while ptr <= len do
    local b = str:byte(ptr)
    if b >= 0xF0 then
      -- 4 byte character
      cur = ascii[b]
      bytesleft = 3
    elseif b >= 0xE0 then
      -- 3 byte character
      cur = ascii[b]
      bytesleft = 2
    elseif b >= 0xC0 then
      -- 2 byte character
      cur = ascii[b]
      bytesleft = 1
    elseif b >= 0x80 and bytesleft > 0 then
      -- Part of a character
      cur = cur .. ascii[b]
      bytesleft = bytesleft - 1
      
      if bytesleft == 0 then
        table.insert(bytes, cur)
        cur = nil
      end
    else
      -- 1 byte character
      if cur then
        table.insert(bytes, cur)
        cur = nil
      end
      
      table.insert(bytes, ascii[b])
      bytesleft = 0
    end
    ptr = ptr + 1
  end
  
  return bytes
end

function Codepage:utf8bytes(str)
  local bytes = {}
  local ptr = 1
  local len = str:len()
  
  local cur = nil
  local bytesleft = 0
  while ptr <= len do
    local b = str:byte(ptr)
    if b >= 0xF0 then
      -- 4 byte character
      cur = ascii[b]
      bytesleft = 3
    elseif b >= 0xE0 then
      -- 3 byte character
      cur = ascii[b]
      bytesleft = 2
    elseif b >= 0xC0 then
      -- 2 byte character
      cur = ascii[b]
      bytesleft = 1
    elseif b >= 0x80 and bytesleft > 0 then
      -- Part of a character
      cur = cur .. ascii[b]
      bytesleft = bytesleft - 1
      
      if bytesleft == 0 then
        table.insert(bytes, self.bytes[cur])
        cur = nil
      end
    else
      -- 1 byte character
      if cur then
        table.insert(bytes, self.bytes[cur])
        cur = nil
      end
      
      table.insert(bytes, self.bytes[ascii[b]])
      bytesleft = 0
    end
    ptr = ptr + 1
  end
  
  return bytes
end

function Codepage:tochars(str)
  local chars = {}
  for i, v in ipairs(str) do
    chars[i] = Codepage.chars[v]
  end
  return chars
end

function Codepage:tobytes(str)
  local bytes = {}
  for i, v in ipairs(str) do
    bytes[i] = self.bytes[v]
  end
  return bytes
end

function Codepage:arg(char, index)
  if type(char) == "string" then
    char = self.bytes[char]
  end
  
  if char >= 0xA0 and char < 0xAA then
    -- Normal constant
    local r = char - 0xA0
    return index and tonumber(r .. index) or r
  elseif char >= 0x30 and char < 0x3A then
    -- Face
    return self.cubically:value(char - 0x30, index)
  elseif char == 0x27 then
    -- Treat each apostrophe as a 3
    return 3
  elseif char == 0xB0 then
    -- Fraction
    return 1 / (index or 2)
  elseif char == 0xB1 then
    -- pi
    return 3.141592653589793
  elseif char == 0xB2 then
    -- phi
    return 1.618033988749894 -- rounds to 5, truncates to 4
  elseif char == 0xB3 then
    -- e
    return 2.718281828459045
  elseif char == 0xC2 then
    -- accumulator
    return self.cubically.accumulator[index or 0] or 0
  elseif char > 0x100 then
    -- Character set
    return self:charset(char - 0x100, index)
  end
end

function Codepage:charset(char, index)
  if type(char) == "string" then
    char = self.bytes[char]
  end
  
  index = index or 0
  
  -- Note: ASCII is already default, no need for a charset for it
  
  if char == 0x44 or char == 0x64 then
    -- Digits
    if index < 0 or index > 9 or index % 1 ~= 0 then
      return 0
    end
    return index + 0x30
  elseif char == 0x41 then
    -- Uppercase
    if index < 0 or index > 25 or index % 1 ~= 0 then
      return 0
    end
    return index + 0x41
  elseif char == 0x61 then
    -- Lowercase
    if index < 0 or index > 25 or index % 1 ~= 0 then
      return 0
    end
    return index + 0x61
  elseif char == 0x43 or char == 0x63 then
    -- Codepage
    return self.chars[index] or 0
  end
end

function Codepage:constindex(char)
  if type(char) == "string" then
    char = self.bytes[char]
  end
  
  if char >= 0x80 and char < 0x8A then
    return char - 0x80
  end
end

function Codepage:faceindex(char)
  if type(char) == "string" then
    char = self.bytes[char]
  end
  
  if char >= 0x90 and char < 0x9A then
    return self.cubically:value(char - 0x90)
  end
end

function Codepage:hex(char)
  if type(char) == "string" then
    char = self.bytes[char]
  end
  
  if char >= 0x30 and char <= 0x39 then
    return char - 0x30
  elseif char >= 0x41 and char <= 0x46 then
    return char - 0x41 + 10
  elseif char >= 0x61 and char <= 0x66 then
    return char - 0x61 + 10
  end
end

_G.Codepage = Codepage