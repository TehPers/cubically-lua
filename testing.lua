require("cubically")

local interpreter = Cubically.new({size = 3})
io.input("input.txt")
local program = io.open("program.cb", "r"):read("*a")
interpreter:exec(program)

print()
print("===========")
print("Program size: " .. #Codepage:utf8bytes(program) .. " bytes (" .. #program .. " in ASCII).")
print("-----------")
print("Final state:")
interpreter:exec("`")