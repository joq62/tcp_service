% test
-ifdef(unit_test).
-define(TEST,unit_test).
-endif.
-ifdef(system_test).
-define(TEST,system_test).
-endif.

% dns_address
-ifdef(public).
-define(DNS_ADDRESS,{"joqhome.dynamic-dns.net",42000}).
-endif.
-ifdef(private).
-define(DNS_ADDRESS,{"192.168.0.100",42000}).
-endif.
-ifdef(local).
-define(DNS_ADDRESS,{"localhost",42000}).
-endif.

% Heartbeat
-ifdef(unit_test).
-define(HB_TIMEOUT,20*1000).
-else.
-define(HB_TIMEOUT,1*60*1000).
-endif.



%compiler

-define(COMPILER,just_for_shell_compile).
-ifdef(public).
-undef(COMPILER).
-ifdef(unit_test).
-define(COMPILER,{d,public},{d,unit_test}).
-else.
-ifdef(system_test).
-define(COMPILER,{d,public},{d,system_test}).
-else.
-define(COMPILER,{d,public}).
-endif.
-endif.
-endif.

-ifdef(private).
-undef(COMPILER).
-ifdef(unit_test).
-define(COMPILER,{d,private},{d,unit_test}).
-else.
-ifdef(system_test).
-define(COMPILER,{d,private},{d,system_test}).
-else.
-define(COMPILER,{d,private}).
-endif.
-endif.
-endif.
-ifdef(local).
-undef(COMPILER).
-ifdef(unit_test).
-define(COMPILER,{d,local},{d,unit_test}).
-else.
-ifdef(system_test).
-define(COMPILER,{d,local},{d,system_test}).
-else.
-define(COMPILER,{d,local}).
-endif.
-endif.
-endif.
