-------------------------------------------------------------------------------------------------------------
-- Project: OOP - Lua Object-Oriented Programming
-- Modle  : GS
-- Title  : Class Model
-- Author : Donnie(Wang Xuedong)
-------------------------------------------------------------------------------------------------------------
-- ��ģ���õ���ȫ�ֱ���
local setmetatable  = setmetatable
local getmetatable  = getmetatable
local getfenv       = getfenv
local table         = table
local pairs         = pairs
local type          = type
local error         = error
local rawget		= rawget
local print         = print
local string 		= string
local tostring		= tostring
local loadstring	= loadstring
--local main_server	= main_server

-------------------------------------------------------------------------------------------------------------
-- ģ�鶨��
-- base.loopģ��Ϊ����������ṩ֧��
-- �������: class(<����>, <����>)
-- ��:
-- oo = require "base.loop"
--
-- oo.class("A")
--
-- function A:__init(a, b)          -- ÿ������붨�幹�캯����ÿ������ֶ�ֻ���ڴ˹��캯���ж���
--     self.a = a
--     self.b = b
-- end
--
-- function A:f()
--     print(self.a, self.b)
-- end
--
-- a = A.new(1, 2)
-- a:f()            --> 1   2
--
-- oo.class("B", A)                 -- A��B�Ļ��࣬B��A��������
--
-- function B:__init(a, b, c, d)    -- ����B.newʱ���ȵ��û����__init, �����в���a��b��c��d����
--     self.c = c
--     self.d = d
-- end
--
-- function B:f()
--     print(self.a, self.b, self.c, self.d)
-- end
--
-- b = B.new(10, 20, 30, 40)
-- b:f()            --> 10  20  30  40
--
module "base.loop"
-------------------------------------------------------------------------------------------------------------
-- �ֲ�����	: access_deny��������ʾܾ���Ϣ����������Ԫ���__index��__newindex�ֶ�
-- ����  	: obj��һ����class��new���������Ķ���
--            field_name���ַ����������ֶ���
--            field_value���������ͣ�Ҫ���õ��ֶ�ֵ
-- ����ֵ   : ��
local function access_deny(obj, field_name, field_value)
    error("the class '" .. obj.__class.__fullname .. "' has no field '" .. field_name .. "'.")
end
-------------------------------------------------------------------------------------------------------------
-- �ֲ����� : __object_mt����������new���������Ķ����Ԫ��
local __object_mt = {
    __index = access_deny,
    __newindex = access_deny
}
-------------------------------------------------------------------------------------------------------------
-- �ֲ����� : super_classes������һ��class������super class�б�
-- ����     : class����class����������class����
-- ����ֵ   : ���飬����super class����
local function super_classes(class)
    local super_classes = {}

    local super = class.__super
    while super do
        table.insert(super_classes, super)
        super = super.__super
    end

    return super_classes
end
-------------------------------------------------------------------------------------------------------------
-- �ֲ����� : derive_function������̳��������е����к���,
--            �ڶ����table�м�������class�ĺ������������л���ĺ���
-- ����     : object����class��new���������Ķ���
--            class������object��class
-- ����ֵ   : nil
local function derive_function(object, class)
    for k, v in pairs(class) do
        if type(v) == "function" and rawget(object, k) == nil and k ~= "new" and k ~= "__init" then
            object[k] = v
        end
    end

    local supers = super_classes(class)
    for i=1, #supers do
        for k, v in pairs(supers[i]) do
            if type(v) == "function" and rawget(object, k) == nil and k ~= "new" and k ~= "__init" then
                object[k] = v
            end
        end
    end
end
-------------------------------------------------------------------------------------------------------------
-- �ֲ����� : derive_variable, ����̳��������е����б���,
--            �����������л����__init����, �����ϲ���࿪ʼ
-- ����     : object����class��new���������Ķ���
--            class������object��class
-- ����ֵ   ��nil
local function derive_variable(object, class, ...)
    local supers = super_classes(class)
    for i=#supers, 1, -1 do
        supers[i].__init(object, ...)
    end

    class.__init(object, ...)
end
-------------------------------------------------------------------------------------------------------------
-- ������� ��class������һ���࣬�������������ô˺����ĺ����Ļ�����
-- ����     ��class_name���ַ���
--            super�����࣬����Ҳ��һ����class�����������
-- ����ֵ   : nil
function class(class_name, super, heavy)
    local new_class = {}
    new_class.__name = class_name
    new_class.__super = super
    -- �ڴ��
	new_class.free_class = {}
	new_class.free_class_count = 0
	-- �ڴ�� end

    if super then
        setmetatable(new_class, { __index = super })
    end
    new_class.new = function (...)
    					-- �ڴ��
						local free_count = new_class.free_class_count
						if free_count > 0 then
							local obj = new_class.free_class[free_count]
							new_class.free_class[free_count] = nil
							new_class.free_class_count = free_count - 1
							local mt = getmetatable(obj)
							mt.__newindex = nil
							derive_variable(obj, new_class, ...)
							mt.__newindex = access_deny
							return obj
						end
						-- �ڴ�� end

                        local object = {m__rel = false}
						if heavy then
                        	derive_function(object, new_class)
						end
                        object.__class = new_class
                        setmetatable(object, { __index = new_class })
                        derive_variable(object, new_class, ...)
                        local mt = getmetatable(object)
                        mt.__newindex = access_deny
                        return object
                    end

    -- �ڴ��
	new_class.del = function (obj)
		new_class.free_class_count = new_class.free_class_count + 1
		new_class.free_class[new_class.free_class_count] = obj
	end
	-- �ڴ�� end

    new_class.super = function(self) return self.__super end
    local env = getfenv(2)
    if env._NAME then
        new_class.__fullname = env._NAME .. "." .. class_name
    else
        new_class.__fullname = class_name
    end
    env[class_name] = new_class
end
-------------------------------------------------------------------------------------------------------------
table.tostring = function(t)
	local mark={}
	local assign={}
	local function ser_table(tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			local key= type(k)=="number" and "["..k.."]" or "[".. string.format("%q", k) .."]"
			if type(v)=="table" then
				local dotkey= parent .. key
				if mark[v] then
					table.insert(assign,dotkey .. "=" .. mark[v] .. "")
				else
					table.insert(tmp, key .. "=" .. ser_table(v,dotkey))
				end
			elseif type(v) == "string" then
				table.insert(tmp, key .. "=" .. string.format('%q', v))
			elseif type(v) == "number" or type(v) == "boolean" then
				table.insert(tmp, key .. "=" .. tostring(v))
			end
		end
		return "{" .. table.concat(tmp,",") .. "}"
	end
	return ser_table(t,"ret") .. table.concat(assign,"")
end

table.loadstring = function(strData)
	local f = loadstring("do local ret=" .. strData .. " return ret end")
	if f then
	   return f()
	end
end




