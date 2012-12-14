local fn = arg[1] or error("No input filename")
local f = io.open(fn, "rb")
if not f then error("Unable to open '" .. fn .. "'") end
local s = f:read"*a"
f:close()
local newFileName = fn:sub(1, -4) .. "r.lua"
local x, y = ParseLua(s)
if not x then error(y) end
local ast = y.Body
local header = [[

-- Automatically generated by a tool
-- Tool name: GenerateReflectionInfo.lua
-- Generated timestamp: ]] .. (os and tostring(os.time()) or '<unknown>') .. '\r\n' ..
[[-- Generated time: ]] .. (os and tostring(os.date()) or '<unknown>') .. '\r\n' .. 
[[-- DO NOT EDIT THIS FILE! ANY EDITS **WILL NOT** BE SAVED
-- Copyright (C) 2012 LoDC : the ClrBclInLua project

]]

local i = 1
while ast[i] and ast[i].AstType ~= 'AssignmentStatement' do 
    if ast[i].AstType ~= 'CallStatement' then return end
    i = i + 1 
end
if not ast[i] then return end
local tbl = ast[i].Rhs[1]
if tbl.AstType ~= 'ConstructorExpr' then return end

local base = ast[i].Lhs[1]
local ClassName, Namespace
s = ""
while base.AstType == 'MemberExpr' do
    s = base.Indexer .. base.Ident.Data .. s
    base = base.Base
end
assert(base.AstType == 'VarExpr' and base.Name ~= nil)
s = base.Name .. s
local i2 = 1
for i3 = 1, #s do
    if s:sub(i3, i3) == '.' then
        i2 = i3
    end
end
Namespace = s:sub(1, i2 - 1)
ClassName = s:sub(i2 + 1)

local source = header
--local source = ""
source = source .. [[
]] .. s .. '.ClassName = "' .. ClassName .. [["
]] .. s .. '.Namespace = "' .. Namespace .. [["
]] .. s .. '.Inherits = '

local inherits = ast[i + 1]
if not inherits then return end
local wrote = false
if inherits.AstType == 'CallStatement' then
    local _ = inherits.Expression.Arguments[2]
    if _.AstType == 'ConstructorExpr' then
        for i = 1, #_.EntryList do
            local x = _.EntryList[i]
            if x.Type == 'KeyString' and x.Key == '__index' and x.Value.AstType ~= 'NilExpr' then
                local base = x.Value
                local tmp = ""
                while base.AstType == 'MemberExpr' do
                    tmp = tmp .. base.Indexer .. base.Ident.Data
                    base = base.Base
                end
                tmp = base.Name .. tmp
                if tmp ~= "System.__index" then
                    source = source .. (tmp == "" and 'System.Object' or tmp).. '\r\n'
                    wrote = true
                    break
                end
            end
        end
    end
end
if not wrote then
    source = source .. 'nil'
end

source = source .. header

--print(source)
f = io.open(newFileName, "wb")
if not f then error("Unable to open '" .. newFileName .. "' for writing") end
f:write(source)
f:close()