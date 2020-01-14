%% This is the application resource file (.app file) for the 'base'
%% application.
{application, lib_service,
[{description, "lib_service  " },
{vsn, "0.0.95" },
{modules, 
	  [lib_service_app,lib_service_sup,lib_service,
	   misc_lib,pod,container]},
{registered,[lib_service]},
{applications, [kernel,stdlib]},
{mod, {lib_service_app,[]}},
{start_phases, []}
]}.
