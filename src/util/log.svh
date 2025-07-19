`ifndef LOG_SVH
`define LOG_SVH

`define INFO(msg)    __info(   msg, `__FILE__, `__LINE__)
`define WARNING(msg) __warning(msg, `__FILE__, `__LINE__)
`define ERROR(msg)   __error(  msg, `__FILE__, `__LINE__)
`define FATAL(msg)   __fatal(  msg, `__FILE__, `__LINE__)

function automatic void __info(string msg, file, int line);
    $display("\033[1;32m[INFO    ]: %s (%s:%-d)\033[0m", msg, file, line); // green
endfunction

function automatic void __warning(string msg, file, int line);
    $display("\033[1;33m[WARNING ]: %s (%s:%-d)\033[0m", msg, file, line); // yellow
endfunction

function automatic void __error(string msg, file, int line);
    $display("\033[1;31m[ERROR   ]: %s (%s:%-d)\033[0m", msg, file, line); // red
endfunction

function automatic void __fatal(string msg, file, int line);
    $display("\033[1;41m[FATAL   ]: %s (%s:%-d)\033[0m", msg, file, line); // red background
    $exit;
endfunction

// +-----------+------------+--------+
// | text      | background | name   |
// +-----------+------------+--------+
// | \033[30m  | \033[40m   | black  |
// | \033[31m  | \033[41m   | red    |
// | \033[32m  | \033[42m   | green  |
// | \033[33m  | \033[43m   | yellow |
// | \033[34m  | \033[44m   | blue   |
// | \033[35m  | \033[45m   | magenta|
// | \033[36m  | \033[46m   | cyan   |
// | \033[37m  | \033[47m   | white  |
// +-----------+------------+--------+

`endif // LOG_SVH
