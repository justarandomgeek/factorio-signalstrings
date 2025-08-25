if not __DebugAdapter then return end

local sigstr = require("__signalstrings__/signalstrings.lua")

---@param sigs Signal[]
---@param expect? string
local function test_signals(sigs, expect)
  local outstr = sigstr.signals_to_string(sigs)
  assert(outstr == expect)
end

---@param str string
---@param expect? string
local function test_string(str, expect)
  local sigs = sigstr.string_to_signals(str)
  test_signals(sigs, (expect or str))
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

test_string("Hello ~ World", "Hello   World")
test_string("a long string more than 32 characters", "a long string more than 32 chara")
test_string("[virtual-signal=signal-H,quality=uncommon][virtual-signal=signal-I]", "Hi")

test_signals({
  { signal = { type="virtual", name="signal-A"}, count = 0xf },
  { signal = { type="virtual", name="signal-B"}, count = 0x3 },
  { signal = { type="virtual", name="signal-C"}, count = 0xc },
}, "aaaa")

