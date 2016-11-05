

local log         = require("comm.log");
local cjson_safe  = require("cjson.safe");
cjson_safe.encode_sparse_array(true);

local FOO = {};


FOO.safe_loadstring = function( txt )
	--安全的把一个string转换成lua的table

	local ret = {};

	local config_ = 'do local _local_var_ =\n' .. txt ..  '\nreturn 	_local_var_ end';
	--log.debug( "-----------------------------------------" );
	--log.debug( config_ );
	--log.debug( "-----------------------------------------" );


	if string.find( txt, '%(' ) or  string.find( txt, '%)' )  then
		log.debug( "ERROR: safe_loadstring find ( or ) in content !!! " );
		return {};
	end


	local func = loadstring( config_ );	
	log.debug( "type=" .. type(func) );

	if func and type(func) == 'function' then	
		ret = func();
		if ret and type(ret) == 'table' then
			log.debug( "table====================================" );
			log.debug( table.tostring(ret) );
			log.debug( "table====================================" );
		else
			log.debug("ERROR: table data error.");
			return {};
		end
	end


	return ret or {};
end;




FOO.safe_loadTable4File = function( filename )	
	local file = io.open( filename, "r");
	assert(file);
	local ret = file:read("*all");
	file:close();	
	return  FOO.safe_loadstring( ret );
		
end;



FOO.get_time_stamp = function( str_ )
	--{year,month,day,hour,min,sec}
	local s_ret = 0;
	
	if str_ then	
		if type(str_) == 'number' then
			return str_;			
		elseif type(str_) == 'string' and #str_ >= 19 then
			--"2016/11/01 00:00:00",

			local ret = {};
			ret.year  = tonumber( string.sub( str_, 1, 4 ) )  or 2016;
			ret.month = tonumber( string.sub( str_, 6, 7 ) )  or 1;
			ret.day   = tonumber( string.sub( str_, 9, 10 ) ) or 1;
			
			ret.hour = tonumber( string.sub( str_, 12, 13 ) ) or 0; 
			ret.min  = tonumber( string.sub( str_, 15, 16 ) ) or 0;
			ret.sec  = tonumber( string.sub( str_, 18, 19 ) ) or 0;

			s_ret = os.time( ret );
		end

	end

	return s_ret;
end




FOO.table2json = function ( t_ )
	return cjson_safe.encode(t_) or "";
end



return FOO;


