

local log = require("comm.log");

--namespace for time
local ns_time = {
	last_record_time = 0,
};
	

--��ʼ��¼ʱ��
function ns_time.start(self)
	self.last_record_time = ngx.now();
end;


--������ʱ
function ns_time.print_cost(self)
	log.debug( "cost_time=" .. ngx.now() - self.last_record_time );
	self.last_record_time = ngx.now();
end;


--�ܺ�ʱ
function ns_time.print_cost_all(self)
	log.debug( "cost_time_all=" .. ngx.now() - ngx.req.start_time() );
end



return ns_time;

