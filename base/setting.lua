
-------------------------------------------------------------------------------------------------------------
-- History:
--          2013.04.30----Create SeaHorse
--�������������ļ�
-------------------------------------------------------------------------------------------------------------
local CCLuaLog      = CCLuaLog
local CCFileUtils   = CCFileUtils
local string        = string
--local CCUserDefault = CCUserDefault
local table         = table
local main_server   = main_server
local require       = require

---------------------------------------------------------------------------------------------------------
local cclog = function(...)
    CCLuaLog( string.format(...) )
end


---------------------------------------------------------------------------------------------------------
module "base.setting"

d_file       = require "common.file"

--��ȡ����������Ϣ
g_setting = {}

function initSetting()
    local file_path = CCFileUtils:sharedFileUtils():getWriteablePath() .. "setting_w/setting.txt"
    g_setting = d_file.readTable( file_path )
    
    if g_setting and g_setting.openMusic then
        --�Ѿ�������
    else
        setDefaultSetting()
    end
end

function setDefaultSetting()
    g_setting = 
    {
        volume = 3,
        openMusic = 1,
        openEffect = 1,
        openMsgBubble = 1,

        last_area = { 0, 0 },
        role_name = { "", "", ""},
        
        username = "",
        password = "",
        md5_password = "",
        role_id  = "",

        server_id = 0,
        ready_login_area = 0,
        ready_login_action = "acc_login",
    }

    saveSetting()    
end


--������д���ļ���
function saveSetting()
    local file_path = CCFileUtils:sharedFileUtils():getWriteablePath() .. "setting_w/setting.txt"
    d_file.saveTable( g_setting, file_path )
end


--��¼���һ��ʹ���ֻ�ֱ�ӵ�½���˺ź�����
function saveLastMobileLoginInfo(server_area_id, username, password, role_name, role_id, server_id)

    table.insert( g_setting.last_area, 1, g_setting.ready_login_area )  --������ǰ
    table.insert( g_setting.role_name, 1, role_name                  )  --������ǰ

    for i=2, #g_setting.last_area do  --ȥ���ظ����б�
        if g_setting.last_area[i] ~=0 and g_setting.last_area[i] == g_setting.ready_login_area then
            table.remove( g_setting.last_area, i )
            table.remove( g_setting.role_name, i )
        end
    end

    --������˻�����ͬʱ�г��Ȳ��ܱ���
    if username and password and #password>0 and #username>0 then
        g_setting.username = username
        g_setting.password = password
    end

    g_setting.role_id    = "" .. role_id
    g_setting.server_id  = server_id

    --����
    saveSetting()

    --����Ҫ��¼serverid
    if  main_server.doTPAction then
        main_server.doTPAction( "chooseServer",  server_area_id)
    end
end


function saveName(username)
    g_setting.role_name[1] = username
	saveSetting()
end



