-------------------------------------------------------------------------------------------------------------
-- Project: RAD
-- Modle  : GS
-- Title  : Message generator
-- Author : Donnie(Wang Xuedong)
-------------------------------------------------------------------------------------------------------------
-- History:
--          2009.04.01----Create
-------------------------------------------------------------------------------------------------------------
-- 本模块用到的全局变量
local string = string
local table = table
local debug = debug
local require = require
local pairs = pairs
local print = print
local type = type
local assert = assert
local loadstring = loadstring
local tostring = tostring
local tonumber = tonumber
-------------------------------------------------------------------------------------------------------------
-- 模块定义
-- 提供一些方便的字符串操作
module "base.str"
-------------------------------------------------------------------------------------------------------------
function split(s, symbol)
    local len = #symbol
    local t = {}
    local i = string.find(s, symbol)
    local j = 1
    while i do
        table.insert(t, string.sub(s, j, i-1))
        j = i + len
        i = string.find(s, symbol, j)
    end
    table.insert(t, string.sub(s, j, #s))
    return t
end

function trim (s) 
	return (string.gsub(s, "^%s*(.-)%s*$", "%1")) 
end

function split_tonumber(s, symbol)
	local len = #symbol
	local t = {}
	local i = string.find(s, symbol)
	local j = 1
	while i do
		table.insert(t, tonumber(string.sub(s, j, i-1)))
		j = i + len
		i = string.find(s, symbol, j)
	end
	table.insert(t, tonumber(string.sub(s, j, #s)))
	return t
end

function split_tonumber_hash(s, symbol)
	local len = #symbol
	local t = {}
	local i = string.find(s, symbol)
	local j = 1
	while i do
		t[tonumber(string.sub(s, j, i-1))] = true
		j = i + len
		i = string.find(s, symbol, j)
	end
	t[tonumber(string.sub(s, j, #s))] = true
	return t
end

function strip(s)
    local i = 1
    while i <= #s do
        local si = string.sub(s, i, i)
        if si ~= " " and si ~= "\t" and si ~= "\n" and si ~= "\r" then
            break
        end
        i = i + 1
    end

    local j = #s
    while j > i do
        local sj = string.sub(s, j, j)
        if sj ~= " " and sj ~= "\t" and sj ~= "\n" and sj ~= "\r" then
            break
        end
        j = j - 1
    end

    return string.sub(s, i, j)
end
-------------------------------------------------------------------------------------------------------------
-- test
if string.sub(debug.traceback(), -1, -1) == '?' then
-- test-section-begin
-------------------------------------------------------------------------------------------------------------
local helper = require "base.assist"
-------------------------------------------------------------------------------------------------------------
-- testcase
local testcase = {}

function testcase.test_split()
    local t = split(",,a,b,c,,e,,", ",")
    assert(#t == 9)
end

function testcase.test_strip()
    local s = strip("  hello   ")
    assert(s == "hello")

    s = strip("     ")
    assert(s == "")

    s = strip("")
    assert(s == "")

    s = strip("\t \nhello world \r\n")
    assert(s == "hello world")
end
-------------------------------------------------------------------------------------------------------------
-- execute all test cases
for _, func in pairs(testcase) do
    func()
end

-- test-section-end
end


table.serial = function(t)
	local mark={}
	local assign={}
	local function ser_table(tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			local key= type(k)=="number" and "["..k.."]" or "[".. string.format("%q", k) .."]"
			if type(v)=="table" then
				local dotkey= parent.. key
				if mark[v] then
					table.insert(assign,dotkey.."='"..mark[v] .."'")
				else
					table.insert(tmp, key.."="..ser_table(v,dotkey))
				end
			elseif type(v) == "string" then
				table.insert(tmp, key.."=".. string.format('%q', v))
			elseif type(v) == "number" or type(v) == "boolean" then
				table.insert(tmp, key.."=".. tostring(v))
			end
		end

		return "{"..table.concat(tmp,",").."}"
	end

	return "do local ret="..ser_table(t,"ret")..table.concat(assign," ").." return ret end"
end

table.unserial = function(strData)
	local f = loadstring(strData)
	if f then
		return f()
	end
end