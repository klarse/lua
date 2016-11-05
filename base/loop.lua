-------------------------------------------------------------------------------------------------------------
-- Project: OOP - Lua Object-Oriented Programming
-- Modle  : GS
-- Title  : Class Model
-- Author : Donnie(Wang Xuedong)
-------------------------------------------------------------------------------------------------------------
-- 本模块用到的全局变量
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
-- 模块定义
-- base.loop模块为面向对象编程提供支持
-- 输出函数: class(<类名>, <基类>)
-- 例:
-- oo = require "base.loop"
--
-- oo.class("A")
--
-- function A:__init(a, b)          -- 每个类必须定义构造函数，每个类的字段只能在此构造函数中定义
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
-- oo.class("B", A)                 -- A是B的基类，B是A的派生类
--
-- function B:__init(a, b, c, d)    -- 调用B.new时，先调用基类的__init, 将所有参数a、b、c、d传入
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
-- 局部函数	: access_deny，输出访问拒绝消息，可以用作元表的__index、__newindex字段
-- 参数  	: obj，一个由class的new方法创建的对象
--            field_name，字符串，访问字段名
--            field_value，任意类型，要设置的字段值
-- 返回值   : 无
local function access_deny(obj, field_name, field_value)
    error("the class '" .. obj.__class.__fullname .. "' has no field '" .. field_name .. "'.")
end
-------------------------------------------------------------------------------------------------------------
-- 局部变量 : __object_mt，可以用作new方法创建的对象的元表
local __object_mt = {
    __index = access_deny,
    __newindex = access_deny
}
-------------------------------------------------------------------------------------------------------------
-- 局部函数 : super_classes，返回一个class的所有super class列表
-- 参数     : class，由class方法创建的class对象
-- 返回值   : 数组，所有super class对象，
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
-- 局部函数 : derive_function，对象继承它的类中的所有函数,
--            在对象的table中加入所有class的函数，包括所有基类的函数
-- 参数     : object，由class的new方法创建的对象
--            class，创建object的class
-- 返回值   : nil
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
-- 局部函数 : derive_variable, 对象继承它的类中的所有变量,
--            依次运行所有基类的__init函数, 从最上层的类开始
-- 参数     : object，由class的new方法创建的对象
--            class，创建object的class
-- 返回值   ：nil
local function derive_variable(object, class, ...)
    local supers = super_classes(class)
    for i=#supers, 1, -1 do
        supers[i].__init(object, ...)
    end

    class.__init(object, ...)
end
-------------------------------------------------------------------------------------------------------------
-- 输出函数 ：class，定义一个类，并将该类加入调用此函数的函数的环境中
-- 参数     ：class_name，字符串
--            super，基类，必须也是一个由class创建的类对象
-- 返回值   : nil
function class(class_name, super, heavy)
    local new_class = {}
    new_class.__name = class_name
    new_class.__super = super
    -- 内存池
	new_class.free_class = {}
	new_class.free_class_count = 0
	-- 内存池 end

    if super then
        setmetatable(new_class, { __index = super })
    end
    new_class.new = function (...)
    					-- 内存池
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
						-- 内存池 end

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

    -- 内存池
	new_class.del = function (obj)
		new_class.free_class_count = new_class.free_class_count + 1
		new_class.free_class[new_class.free_class_count] = obj
	end
	-- 内存池 end

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




