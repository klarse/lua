
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
-- 拆分UTF8汉字

module "base.utf8"

local funciton_table = {}

local RANGE = function(number, min, max)
	if number >= min and number <= max then
		return true
	else
		return false
	end
end	

local RANGE_SND = function(number)
	if number >= 128 and number <= 191 then
		return true
	else
		return false
	end
end

local UTF8_BOM = function(first_byte, second_byte, third_byte) 
	if first_byte and first_byte == 0xEF and second_byte and second_byte == 0xBB 
		and third_byte and third_byte == 0xBF then
		return true
	else
		return false
	end
end

local utf8_next = function(str, pos)
	local first_byte = string.byte(str, pos)
	if not first_byte then
		return 0
	end
	if first_byte < 128 then
		return 1
	end

	if first_byte < 194 then
		return 0
	end
	if first_byte > 244 then
		return 0
	end

	local second_byte = string.byte(str, pos+1)
	if not second_byte then
		return 0
	end

	if first_byte < 224 and RANGE_SND(second_byte) then
		return 2
	end

	local third_byte = string.byte(str, pos+2)
	if not third_byte then
		return 0
	end

	if UTF8_BOM(first_byte, second_byte, third_byte) then
		return 3
	end

	if RANGE(first_byte, 225, 239) and first_byte ~= 237 and RANGE_SND(second_byte) 
	  and RANGE_SND(third_byte) then
		return 3
	end

	if first_byte == 224 and RANGE(second_byte,160,191) and RANGE_SND(third_byte) then
		return 3
	end
	if first_byte == 237 and RANGE(second_byte,128,159) and RANGE_SND(third_byte) then
		return 3
	end
	
	local fourth_byte = string.byte(str, pos+3)
	if not fourth_byte then
		return 0
	end

	if RANGE(first_byte, 241, 243) and RANGE_SND(second_byte) 
	  and RANGE_SND(third_byte) and RANGE_SND(fourth_byte) then
		return 4
	end
	if first_byte == 240 and RANGE(second_byte,144,191) 
		and RANGE_SND(third_byte) and RANGE_SND(fourth_byte) then
		return 4
	end
	if first_byte == 244 and RANGE(second_byte,128,143) 
		and RANGE_SND(third_byte) and RANGE_SND(fourth_byte) then
		return 4
	end
	return 0
end


local UTF8_wordwrap = function (str)	
	local strlen = string.len(str)
	local str_buffer = {}
	local word_count = 0
	local pos = 1
	while pos <= strlen do
		local clen = utf8_next(str, pos);
		if clen == 0 then
			return false
		else
			table.insert(str_buffer, string.sub(str, pos, pos + clen-1))
			pos = pos + clen
			word_count = word_count + 1
		end
	end
	return str_buffer
end


--剪裁UTF8的个数
local trim_utf8 = function(str, count)
    local t = UTF8_wordwrap(str)
    
    if #t <= count then
        return str
    end

    local ret = ""
    for i=1, count do
        ret = ret .. t[i]
    end

    return ret    
end


local test = function()
	local output_file =io.open("testoutput.txt","w")
	local f= io.lines("testfile.txt")
	assert(f)
	local line1 = f()
	while line1 do
		output_file:write(UTF8_wordwrap(line1, 1, "\n"))
		line1 = f()
	end
	output_file:close()
end


local check_utf8 = function ( string_ )
    if not UTF8_wordwrap( string_ ) then
        return "error_string"
    else
        return string_
    end
end


funciton_table.utf8_next = utf8_next
funciton_table.UTF8_wordwrap = UTF8_wordwrap
funciton_table.check_utf8 = check_utf8
funciton_table.trim_utf8  = trim_utf8

return funciton_table
