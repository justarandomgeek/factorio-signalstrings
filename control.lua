if not __DebugAdapter then return end

local sigstr = require("__signalstrings__/signalstrings.lua")

local function test_string(str)
  local sigs = sigstr.string_to_signals(str)
  local outstr = sigstr.signals_to_string(sigs)
  assert(outstr == str)
end

test_string("Hello World!")
test_string("Hello [item=iron-plate]")
test_string("Hello [item=iron-plate,quality=rare]")
test_string("Hello [item=iron-plate")
test_string("Hello [item=flurts]")
test_string("Hello 💀👻🛈✓❌·$♥⚠⭐")
test_string("Hello !\"#%&'()*+,-./:")
test_string("Hello <=>?[]^÷≤≠≥")
test_string("Hello │─╭╮┌┐┬┤┼╳╱╲╰╯└┘├┴")
test_string("Hello ◯↑↗→↘↓↙←↖↔↕↩↪")
