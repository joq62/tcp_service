%% This is the application resource file (.app file) for the 'base'
%% application.
{application, tcp_service,
[{description, "tcp_service  " },
{vsn, "0.0.95" },
{modules, 
	  [tcp_service_app,tcp_service_sup,tcp_service,tcp_client]},
{registered,[tcp_service]},
{applications, [kernel,stdlib]},
{mod, {tcp_service_app,[]}},
{start_phases, []}
]}.
