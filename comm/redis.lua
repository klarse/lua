

local log       = require("comm.log");
local ns_config = require("config.config");
local redis     = require "resty.redis";


local ns_redis = {        --namespace for redis
}


--ngx.ctx.redis_connection = false;  本次建立的连接


ns_redis.get_hash = function( key )	
	if  type(key) == 'number' then		
		return  key % 10;

	elseif type(key) == 'string' then
		local num = tostring( key );
		if num then
			return num % 10;
		end	

	end

	log.error_exit( 'key1 error = ' .. (key or 'nil') );
end




ns_redis.get_config_by_hash = function(key)
	local hash_  = ns_redis.get_hash(key);		
	if ns_config and ns_config.redis_hash  and ns_config.redis_server then
		
		if  ns_config.redis_hash[hash_] and ns_config.redis_server[ ns_config.redis_hash[hash_]] then			
			return  hash_, ns_config.redis_server[ ns_config.redis_hash[hash_]];			
		end		
	end	
	
	log.error_exit( 'config1 hash, error = ' .. (key or 'nil') );
end



--获得连接
ns_redis.try_connect = function( key )

	if  ngx.ctx.redis_connection then
		log.debug( "use exist connection ..." );
		return  ngx.ctx.redis_connection;
	else
		log.debug( "try new connect..." );
	end	


	--新建连接
	local hash_, config_ = ns_redis.get_config_by_hash( key );

	local instance = redis.new();
	instance:set_timeout(1000);      --1s


	local ok, err = instance:connect( config_.ip, config_.port );
	if not ok then
		log.error_exit( "fail connect. msg=" .. err );
	end


	ok, err = instance:auth( config_.pass );
	if not ok then
		log.error_exit( "fail auth. msg=" .. err );
	end


	ok, err = instance:select(hash_);
	if not ok then
		log.error_exit( "fail select. msg=" .. err );
	end


	ngx.ctx.redis_connection = instance;
	return instance, err;
end;



--按照key获取数据
ns_redis.get = function(key)
	ns_redis.try_connect(key);

	local ret, err = ngx.ctx.redis_connection:get(key);
	if ret == ngx.null then
		log.debug( "get null value. key=" .. key );
		return "";
	else
		log.debug( "key=" .. key .. ", ret=" .. (ret or "") );
		return ret;
	end
end;



--set值
ns_redis.set = function(key, value)
	ns_redis.try_connect(key);

	local ok, err = ngx.ctx.redis_connection:set(key, value);
	if not ok then
	    log.error_exit("failed to set: ", err);
	else
		--log.debug("set date ok.")
	end

end;



--关闭连接
ns_redis.close = function()

	if  ngx.ctx.redis_connection then
		local ok, err = ngx.ctx.redis_connection:set_keepalive(10000, 100);
		ngx.ctx.redis_connection = nil;

		if not ok then
	    	log.debug("failed to set keepalive: ", err);
	    else
	    	log.debug("keep alive ok.");
	    end
	else
		log.error_exit( "no obj to close." );
    end

end;



return ns_redis;
