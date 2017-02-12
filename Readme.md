## SignalStrings

This library provides common functions for handling strings on circuit networks.

Currently, this provides converting between lua strings and circuit strings via
`remote.call('signalstrings','string_to_signals',"FOOBAR")` and `remote.call('signalstrings','signals_to_string',signallist)`
