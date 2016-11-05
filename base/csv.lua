-------------------------------------------------------------------------------------------------------------
-- Project: RAD
-- Modle  : GS
-- Title  : The definitions of message between GS an Client
-- Author : Donnie(Wang Xuedong)
-------------------------------------------------------------------------------------------------------------
-- History:
--          2009.04.14----Create
-------------------------------------------------------------------------------------------------------------
local io            = io
local string        = string
local require       = require
local tostring      = tostring
local pairs         = pairs
local table			= table
local debug         = debug
local assert		= assert
local error			= error
local print         = print
local CCLuaLog      = CCLuaLog
local CCFileUtils   = CCFileUtils
local CCString      = CCString
local tonumber      = tonumber
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- ģ�鶨��
-- ��ģ�鶨���˶�ȡSCV�ļ���ת����һ������������
-- ʹ��:
-- equire��ģ�顣���ø�ģ���open����������Ĳ���Ϊ csv�ļ���·����
-- ���Ϊһ����
--����csv��������ݵ�һ��Ϊ ID,�������绰
--				   �ڶ���Ϊ��1��mali��8888
--				   ������Ϊ��2��lily��7777
--���صı�Ϊ t={
--              fields_name={"ID", "����", "�绰"},
--				records	   ={
--							 {"1", "mali", "8888"},
--							 {"2", "lily",  "7777"}
--							}
--				}
module "base.csv"




local cclog = function(...)
    --print(string.format(...))
    CCLuaLog( string.format(...) )
end


-------------------------------------------------------------------------------------------------------------
-- local pcre = require "rex_pcre"
local str = require "base.str"
-- local log = require "common.log"
-------------------------------------------------------------------------------------------------------------
-- �ֲ����� : copytable����Ŀ���������
-- ����     : s��ԭ��  d��Ŀ���
-- ����ֵ   : ��
-------------------------------------------------------------------------------------------------------------
function copytable(s, d)
	for i=1, #s do
		d[i] = tostring(s[i])
	end
end

function convert_filepath(filepath)

    cclog( "call convert_filepath=%s", filepath )
    local t = str.split(filepath, "\\")
    local s = ""
    for i=1, #t do
        if i ~= #t then
            s = s .. t[i] .. "/"
        else
            s = s .. t[i]
        end
    end

    return s
end


--ȥ���ļ���ͷ��BOM FF FE
function cleanBOM(content, filename)
    local ret = ""
    
    local tonumber = tonumber
    local tostring = tostring
    
    if #content > 2 then
        local char1 = string.sub(content, 1, 1)
        local char2 = string.sub(content, 2, 2)
        local char3 = string.sub(content, 3, 3)
        
        if char1 == string.char(239) and char2==string.char(187) and char3==string.char(191) then
            cclog("ERROR: find file utf8 index 239 187 191 !!!, filename=" .. filename)
            ret = string.sub(content, 4)
            cclog("clean bom ok.")
        elseif ( char1 == string.char(255) and char2==string.char(254) ) or
               ( char1 == string.char(254) and char2==string.char(255) ) then
            cclog("ERROR: find file utf8 index 255 254 !!!, filename=" .. filename)
            ret = string.sub(content, 3)
            cclog("clean bom ok.")
        else
            ret = content
        end
    end

    return ret
end

-------------------------------------------------------------------------------------------------------------
-- �ֲ����� : ��ȡcsv�ļ�����������Ķ��巵��һ����
-- ����     : filename���򿪵�csv�ļ���·��
-- ����ֵ   : ��
-------------------------------------------------------------------------------------------------------------
function open(filename)
   	local t = {}
   	t.fields_name = {}
    t.records = {}

    local ifacsvfile = string.sub(filename,-4,-1)
    assert(ifacsvfile == ".csv")

    filename = convert_filepath(filename)
    cclog("cvs filename=%s", filename)

    --local file, err_msg, err_code = io.open(filename, 'r')
    --if not file then
        --error(err_msg)
        --return
    --end

    --local tmp_path = CCFileUtils:sharedFileUtils():fullPathFromRelativePath( filename )
    local tmp_path = filename

    local p_content
    local len=0
    p_content, len = CCFileUtils:sharedFileUtils():getFileData( tmp_path, "rb", len )    
    
    local all_contents = CCString:createWithData(p_content, len):getCString()

    all_contents = cleanBOM( all_contents, filename)   --ȥ��BOMͷ��

    local countline = 1
    local start_pos = 1
    local end_pos = string.find(all_contents, "\n")

    while end_pos do
    	local line = string.sub(all_contents, start_pos, end_pos-1)
    	if all_contents[end_pos + 1] ~= "," then
    	   	if string.sub(line, -1, -1) == "\r" then
	       	    if (#line < 2) then
	   	            line = ""
	   	        else
    	   	        line = string.sub(line, 1, -2)
    	   	    end
	   	    end

    	    local linetable = str.split(line, ",")

		    if countline == 1 then
			    copytable(linetable, t.fields_name)
	        else
	            
	            if linetable and #linetable==1 and linetable[1]=="" then
	                --�ձ� [1]=""  �ջ��е���
	                cclog("find empty line")
                    countline = countline - 1
	            else
	                t.records[countline-1] = {}
			        copytable(linetable, t.records[countline-1])
			    end
    	    end

    	    countline = countline + 1
    	    start_pos = end_pos + 1
  		end

        end_pos = string.find(all_contents, "\n", end_pos + 1)
    end

    local line = string.sub(all_contents, start_pos, -1)
    if str.strip(line) ~= "" then
        local linetable = str.split(line, ",")
        if countline == 1 then
            copytable(linetable, t.fields_name)
    	else
	        if linetable and #linetable==1 and linetable[1]=="" then
	            --�ձ� [1]=""  �ջ��е���
                cclog("find empty line")
			else
		        t.records[countline-1] = {}
			    copytable(linetable, t.records[countline-1])
			end
        end
    end

	return t
end
-------------------------------------------------------------------------------------------------------------
local csv_rex_pattern = '(?:\\n|,)(?:"(?:[^"]|"")*"|[^",\\n]*)'
-- local csv_rex = pcre.new(csv_rex_pattern)

function parse(filename)
	local t = {}
   	t.fields_name = {}
    t.records = {}

    local suffix = string.sub(filename,-4,-1)
    assert(suffix == ".csv")

    filename = convert_filepath(filename)    
    cclog( "csv filename=%s", filename )

    local file, err_msg, err_code = io.open(filename, 'r')
	if not file then
		error(err_msg)
		return
	end

    local all_contents = file:read("*a")
	file:close()

    local end_pos = string.find(all_contents, "\n")
    local first_line = string.sub(all_contents, 1, end_pos-1)

    if first_line and str.strip(first_line) == "" then
        return
    end

    t.fields_name = str.split(first_line, ",")
    if not t.fields_name then
        return
    end

    local column_count = #t.fields_name

    local line_count = 1
    local fields_count = 1
    local start_pos = end_pos + 1

    while end_pos do
        t.records[line_count] = t.records[line_count] or {}

        if string.sub(all_contents, start_pos, start_pos) == '"' then
            end_pos = string.find(all_contents, '"', start_pos+1)
            if not end_pos then
				error("parse csv error, quote note error")
                return
            end
            local field = string.sub(all_contents, start_pos+1, end_pos)
            if not field then
				error("parse csv error, quote note error 2")
                return
            end
            if #field > 0 then
                field = string.sub(field, 1, -2)
            end
            table.insert(t.records[line_count], field)
            fields_count = fields_count + 1

            start_pos = end_pos + 1
            if fields_count == column_count + 1 then
                end_pos = string.find(all_contents, "\n", start_pos)
                start_pos = end_pos + 1

                line_count = line_count + 1
                fields_count = 1
            else
                end_pos = string.find(all_contents, ",", start_pos)
                start_pos = end_pos + 1
            end
        else
            end_pos = string.find(all_contents, ',', start_pos)
            if not end_pos then
				if #t.records[#t.records] == 0 then
					t.records[#t.records] = nil
				end

                return t
            end
            local field = string.sub(all_contents, start_pos, end_pos)
            if not field then
				error("parse csv error, , note error")
                return
            end
            if #field > 0 then
                field = string.sub(field, 1, -2)
            end
            table.insert(t.records[line_count], field)
            fields_count = fields_count + 1

            start_pos = end_pos + 1
            if fields_count == column_count + 1 then
                end_pos = string.find(all_contents, "\n", start_pos)
                start_pos = end_pos + 1

                line_count = line_count + 1
                fields_count = 1
            end
        end
    end

	if #t.records[#t.records] == 0 then
		t.records[#t.records] = nil
	end

    return t
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

    function testcase.open()
        -- local t = parse("test.csv")
        -- helper.dir_tb(t)
    end

    -------------------------------------------------------------------------------------------------------------
    -- execute all test cases
    for _, func in pairs(testcase) do
        func()
    end

    -- test-section-end
end

-------------------------------------------------------------------------------------------------------
--����һ��csv�ļ���lua table�У��ֶ�������csv�ļ��еĵ�һ�� ��һ�б�����Ӣ��
function open2(filename)
    local ret = {}    
    local src_table = open(filename)   --ֻ��������[1]�����ı�


    for i, v in pairs( src_table.records ) do
        local tmp_line = {}

        --�ֶ�����
        for m, n in pairs( src_table.fields_name ) do
            local f_name = n
            local bracket  = "%(";     --ȥ������
            local pos = string.find(f_name, bracket )
            if pos then
                f_name = string.sub( f_name, 1, pos-1 )
            end
            
            if #f_name > 0 then
                tmp_line[f_name] = src_table.records[i][m]
            end
        end

        table.insert( ret, tmp_line )
    end    

    return ret
end







