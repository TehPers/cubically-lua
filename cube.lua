local Cube = {}
function Cube.new(size)
  local faces = {}
  size = size or 3
  local sizeSquared = size ^ 2
  for face = 0, 5 do
    faces[face] = {}
    for n = 0, sizeSquared - 1 do
      faces[face][n] = face
    end
  end
  
  faces.U = faces[0]
  faces.D = faces[5]
  faces.L = faces[1]
  faces.R = faces[3]
  faces.F = faces[2]
  faces.B = faces[4]

  local faceValues = {}
  for i = 0, 5 do
    faceValues[i] = i
  end

  return setmetatable({
    faces = faces,
    faceValues = faceValues,
    size = size,
    sizeSquared = sizeSquared
  }, {
    __index = Cube,
    __tostring = Cube.tostring
  })
end

function Cube:index(x, y)
  return y * self.size + x
end

function Cube:solved()
  return self:value(0) == 0 and self:value(1) == self.size ^ 2 and self:value(2) == 2 * self.size ^ 2
end

local function rotateFace(cube, face)
  local size = cube.size
  for y = 0, math.floor(size / 2) - 1 do
    for x = 0, math.ceil(size / 2) - 1 do
      local t = face[cube:index(x, y)]
      face[cube:index(x, y)] = face[cube:index(y, size - 1 - x)]
      face[cube:index(y, size - 1 - x)] = face[cube:index(size - 1 - x, size - 1 - y)]
      face[cube:index(size - 1 - x, size - 1 - y)] = face[cube:index(size - 1 - y, x)]
      face[cube:index(size - 1 - y, x)] = t
    end
  end
end

local function unrotateFace(cube, face)
  local size = cube.size
  for y = 0, math.floor(size / 2) - 1 do
    for x = 0, math.ceil(size / 2) - 1 do
      local t = face[cube:index(size - 1 - y, x)]
      face[cube:index(size - 1 - y, x)] = face[cube:index(size - 1 - x, size - 1 - y)]
      face[cube:index(size - 1 - x, size - 1 - y)] = face[cube:index(y, size - 1 - x)]
      face[cube:index(y, size - 1 - x)] = face[cube:index(x, y)]
      face[cube:index(x, y)] = t
    end
  end
end

function Cube:R(n, depth)
  n = n % 4
  depth = depth or 0
  if depth < 0 or depth >= self.size then
    return
  end

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    for i = 0, size - 1 do
      local t = faces.U[self:index(size - depth - 1, i)]
      faces.U[self:index(size - depth - 1, i)] = faces.F[self:index(size - depth - 1, i)]
      faces.F[self:index(size - depth - 1, i)] = faces.D[self:index(size - depth - 1, i)]
      faces.D[self:index(size - depth - 1, i)] = faces.B[self:index(depth, size - i - 1)]
      faces.B[self:index(depth, size - i - 1)] = t
    end

    -- Rotate face
    if depth == 0 then
      rotateFace(self, faces.R)
    elseif depth == size - 1 then
      unrotateFace(self, faces.L)
    end
  end
end

function Cube:L(n, depth)
  n = n % 4
  depth = depth or 0
  if depth < 0 or depth >= self.size then
    return
  end

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    for i = 0, size - 1 do
      local t = faces.U[self:index(depth, i)]
      faces.U[self:index(depth, i)] = faces.B[self:index(self.size - depth - 1, self.size - i - 1)]
      faces.B[self:index(self.size - depth - 1, self.size - i - 1)] = faces.D[self:index(depth, i)]
      faces.D[self:index(depth, i)] = faces.F[self:index(depth, i)]
      faces.F[self:index(depth, i)] = t
    end

    -- Rotate face
    if depth == 0 then
      rotateFace(self, faces.L)
    elseif depth == size - 1 then
      unrotateFace(self, faces.R)
    end
  end
end

function Cube:U(n, depth)
  n = n % 4
  depth = depth or 0
  if depth < 0 or depth >= self.size then
    return
  end

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    for i = 0, size - 1 do
      local t = faces.L[self:index(i, depth)]
      faces.L[self:index(i, depth)] = faces.F[self:index(i, depth)]
      faces.F[self:index(i, depth)] = faces.R[self:index(i, depth)]
      faces.R[self:index(i, depth)] = faces.B[self:index(i, depth)]
      faces.B[self:index(i, depth)] = t
    end

    -- Rotate face
    if depth == 0 then
      rotateFace(self, faces.U)
    elseif depth == size - 1 then
      unrotateFace(self, faces.D)
    end
  end
end

function Cube:D(n, depth)
  n = n % 4
  depth = depth or 0
  if depth < 0 or depth >= self.size then
    return
  end

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    for i = 0, size - 1 do
      local t = faces.B[self:index(i, size - depth - 1)]
      faces.B[self:index(i, size - depth - 1)] = faces.R[self:index(i, size - depth - 1)]
      faces.R[self:index(i, size - depth - 1)] = faces.F[self:index(i, size - depth - 1)]
      faces.F[self:index(i, size - depth - 1)] = faces.L[self:index(i, size - depth - 1)]
      faces.L[self:index(i, size - depth - 1)] = t
    end

    -- Rotate face
    if depth == 0 then
      rotateFace(self, faces.D)
    elseif depth == size - 1 then
      unrotateFace(self, faces.U)
    end
  end
end

function Cube:F(n, depth)
  n = n % 4
  depth = depth or 0
  if depth < 0 or depth >= self.size then
    return
  end

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    -- Rotate sides
    for i = 0, size - 1 do
      local t = faces.U[self:index(i, size - depth - 1)]
      faces.U[self:index(i, size - depth - 1)] = faces.L[self:index(size - depth - 1, size - i - 1)]
      faces.L[self:index(size - depth - 1, size - i - 1)] = faces.D[self:index(size - i - 1, depth)]
      faces.D[self:index(size - i - 1, depth)] = faces.R[self:index(depth, i)]
      faces.R[self:index(depth, i)] = t
    end

    -- Rotate face
    if depth == 0 then
      rotateFace(self, faces.F)
    elseif depth == size - 1 then
      unrotateFace(self, faces.B)
    end
  end
end

function Cube:B(n, depth)
  n = n % 4
  depth = depth or 0
  if depth < 0 or depth >= self.size then
    return
  end

  local faces = self.faces
  local size = self.size
  for _ = 1, n do
    for i = 0, size - 1 do
      local t = faces.U[self:index(i, depth)]
      faces.U[self:index(i, depth)] = faces.R[self:index(size - depth - 1, i)]
      faces.R[self:index(size - depth - 1, i)] = faces.D[self:index(size - i - 1, size - depth - 1)]
      faces.D[self:index(size - i - 1, size - depth - 1)] = faces.L[self:index(depth, size - i - 1)]
      faces.L[self:index(depth, size - i - 1)] = t
    end

    -- Rotate face
    if depth == 0 then
      rotateFace(self, faces.B)
    elseif depth == size - 1 then
      unrotateFace(self, faces.F)
    end
  end
end

function Cube:setFace(index, n)
  if not index or index < 0 or index > 5 or index % 1 ~= 0 then
    return
  end
  n = n or index
  self.faceValues[index] = n
end

function Cube:value(n, index)
  if not n or n < 0 or n > 5 or n % 1 ~= 0 then
    return 0
  end
  
  if index then
    local f = self.faces[n][index]
    return f and self.faceValues[f] or 0
  end
  
  local sum = 0
  for i = 0, self.sizeSquared - 1 do
    sum = sum + self.faceValues[self.faces[n][i]]
  end
  return sum
end

function Cube:tostring()
  local s = ""
  local size = self.size
  for y = 0, size - 1 do
    s = s .. (" "):rep(size)
    for x = 0, size - 1 do
      s = s .. self:value(0, self:index(x, y))
    end
    s = s .. "\n"
  end
  
  for y = 0, size - 1 do
    for i = 1, 4 do
      for x = 0, size - 1 do
        s = s .. self:value(i, self:index(x, y))
      end
    end
    s = s .. "\n"
  end
  
  for y = 0, size - 1 do
    s = s .. (" "):rep(size)
    for x = 0, size - 1 do
      s = s .. self:value(5, self:index(x, y))
    end
    s = s .. "\n"
  end

  return s:sub(1, #s - 1)
end

_G.Cube = Cube