
local FOO = {};


--path root is nginx
FOO.root_dir        = 'logs/';                       
FOO.debug_log_path  = FOO.root_dir .. 'debug.log';



-- 打印到输出界面
FOO.debug = function( txt )
	if ngx.req.get_uri_args().log == "1" then
		if txt then
			ngx.say( '-- ' .. txt .. '<br>' );
			-- FOO.log2file( FOO.debug_log_path, txt );
		else
			ngx.say( '-- empty nil string.<br>' );
			-- FOO.log2file( FOO.debug_log_path, txt );
		end
	end
end;


FOO.error_exit = function ( txt )	
	FOO.debug( txt );
	ngx.log( ngx.ALERT, txt );
	ngx.exit(ngx.ERROR);
end;




--打印到文件
FOO.log2file = function(filepath, txt)
	local file = io.open(filepath, "a");
    assert(file);
    file:write( txt .. '\n');
	file:close();
end;


--打印到 logs/debug.log
FOO.debug_file = function(txt)
	FOO.log2file( FOO.debug_log_path, txt );
end;



--当天日志
FOO.day = function(txt)
	FOO.log2file( FOO.root_dir .. 'debug_' .. os.date('%Y%m%d') .. '.log' , txt );
end;



return FOO;

