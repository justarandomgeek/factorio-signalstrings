## SignalStrings

This library provides common functions for handling strings on circuit networks. Strings are expressed as a bitmask of where each letter appears, LSB on the left.
"foobar" = {signal-F=1,signal-O=6,signal-B=8,signal-A=16,signal-R=32}

Signals without mappings will fall back to a richtext tag if possible. If quality is enabled, uncommon signals will be used for capital letters. Mods may register additional signal mappings by adding them to `data.raw["mod-data"]["signalstrings-mapping"].data` (`{[string]:SignalID}`), using a single utf8 encoded character as the key.


```lua
local sigstr = require("__signalstrings__/signalstrings.lua")

-- read a string from signals...
local str = sigstr.signals_to_string(entity.get_signals(defines.wire_connector_id.combinator_input_green))

-- write to a constant combinator...
control.sections[1].filters = sigstr.string_to_logistic_filters("Hello World!")

-- write to a decider...
local p = control.parameters
p.outputs = sigstr.string_to_decider_outputs("Hello World!")
control.parameters = p

-- also back to signals...
local sigs = sigstr.string_to_signals("Hello World!")

-- or customize it...
local Ts = sigstr.string_to_Ts("Hello World!", function (signal, value)
  return "Earl Grey, Hot"
end)

```


