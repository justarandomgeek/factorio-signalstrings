local prototypes = prototypes
local script = script
local pairs = pairs
local bband = bit32.band
local bextract = bit32.extract
local breplace = bit32.replace
local sbyte = string.byte
local sformat = string.format
local sfind = string.find
local ssub = string.sub
local tconcat = table.concat
local _ENV = nil

---@alias typeinfo {type:SignalIDType, richtag:string?, richqual:boolean?, protos:LuaCustomTable<string>}

---@type table<SignalIDType, typeinfo>
local signal_types = {}
---@type table<string, typeinfo>
local richtag_types = {}

do
  ---@type typeinfo[]
  local typeinfos = {
    { type = "item", richtag="item", richqual=true, protos = prototypes.item, },
    { type = "fluid", richtag="fluid", richqual=true, protos = prototypes.fluid, },
    { type = "virtual", richtag="virtual-signal", richqual=true, protos = prototypes.virtual_signal, },
    { type = "recipe", richtag="recipe", richqual=true, protos = prototypes.recipe, },
    { type = "entity", richtag="entity", richqual=true, protos = prototypes.entity, },
    { type = "space-location", richtag="space-location", protos = prototypes.space_location, },
    { type = "quality", richtag="quality", protos = prototypes.quality, },
    { type = "asteroid-chunk", protos = prototypes.asteroid_chunk, },
  }
  for _, info in pairs(typeinfos) do
    signal_types[info.type] = info
    if info.richtag then
      richtag_types[info.richtag] = info
    end
  end
end

---@type {[string]:SignalID}
local c2s=prototypes.mod_data["signalstrings-mapping"].data --[[@as {[string]:SignalID}]]

---@type {[QualityID]:{[SignalIDType]:{[string]:string}}}
local s2c={}
--TODO: validate the signal prototypes? or just let them fail later?
for char, signal in pairs(c2s) do
  local qmap = s2c[signal.quality or "normal"]
  if not qmap then
    qmap = {}
    s2c[signal.quality or "normal"] = qmap
  end
  local tmap = qmap[signal.type or "item"]
  if not tmap then
    tmap = {}
    qmap[signal.type or "item"] = tmap
  end
  tmap[signal.name] = char
end

---@param signal SignalID
---@return string?
local function sigchar(signal)
  if not signal then return end
  local qmap = s2c[signal.quality or "normal"]
  if qmap then
    local tmap = qmap[signal.type or "item"]
    if tmap then
      local char = tmap[signal.name]
      if char then
        return char
      end
    end
  end
  local typeinfo = signal_types[signal.type]
  if typeinfo then
    if typeinfo.richqual and signal.quality and signal.quality ~= "normal" then
      -- qual tag
      return sformat("[%s=%s,quality=%s]", typeinfo.richtag, signal.name, signal.quality)
    end
    return sformat("[%s=%s]", typeinfo.richtag, signal.name)
  end
end

---@param set Signal[]
---@return string
local function signals_to_string(set)
  local sigbits = {}
  local bitsleft = -1
  local lastbit = 0
  for _,sig in pairs(set) do
    local ch = sigchar(sig.signal)
    if ch then
      local newbits = bband(sig.count,bitsleft)
      if newbits ~= 0 then
        for i=0,31 do
          local sigbit = bextract(newbits,i)
          if sigbit==1 then
            sigbits[i+1] = ch
            bitsleft = breplace(bitsleft,0,i)--[[@as integer]]
            if lastbit < i then
              lastbit = i
            end
            if bitsleft == 0 then
              return tconcat(sigbits)
            end
          end
          newbits = breplace(newbits, 0, i)--[[@as integer]]
          if newbits == 0 then break end
        end
      end
    end
  end

  for i=1,lastbit do
    if sigbits[i] == nil then
      sigbits[i]  = " "
    end
  end

  return tconcat(sigbits)
end

---@param str string
---@param i integer
---@return SignalID? tag
---@return string? tagstr
---@return integer? nexti
local function try_match_richtext(str,i)
  local _,j,tagtype,tagname,tagqual
  if script.feature_flags.quality then
    _,j,tagtype,tagname,tagqual = sfind(str, "^%[([%a%-]+)=([%a%d%-_]+),quality=([%a%d%-_]+)%]", i)
  end
  
  if not tagtype then
    tagqual = "normal"
    _,j,tagtype,tagname = sfind(str, "^%[([%a%-]+)=([%a%d%-_]+)%]", i)
  end

  if not tagtype then return end
  ---@cast tagname string
  ---@cast tagname string
  ---@cast tagqual string
  local taginfo = richtag_types[tagtype]
  if not taginfo then return end
  if not taginfo.protos[tagname] then return end
  if not prototypes.quality[tagqual] then return end

  ---@type SignalID
  local sig = {
    type = taginfo.type,
    name = tagname,
    quality = tagqual,
  }
  return sig, ssub(str,i,j), j+1
end

---@generic T
---@param str string
---@param signal_format fun(signal:SignalID, value:integer):T
---@return T[]
local function string_to_Ts(str,signal_format)
  local letters = {}
  local tagsigs = {}

  do
    local b=1 -- bit position in output
    local i=1 -- index in str
    local l=#str

    while i<=l and b < 0x100000000 do
      local c = ssub(str,i,i)
      local j = i+1
      if c == "[" then
        local tagsig,tagstr,tagi = try_match_richtext(str, i)
        if tagsig then
          ---@cast tagstr -?
          ---@cast tagi -?
          c = tagstr
          tagsigs[tagstr] = tagsig
          j = tagi
        end
      elseif sbyte(c) >= 0x80 then
        local _,uchari, uchar = sfind(str, "^([\xC2-\xF4][\x80-\xBF]+)", i)
        if uchari then
          ---@cast uchar -?
          c = uchar
          j = uchari+1
        end
      end
      letters[c]=(letters[c] or 0)+b
      i=j
      b=b*2
    end
  end

  ---@type T[]
  local signals = {}
  for c,b in pairs(letters) do
    if b >= 0x80000000 then b =  b - 0x100000000 end
    local sig = tagsigs[c] or c2s[c]
    if sig then
      signals[#signals+1]=signal_format(sig, b)
    end
  end

  return signals
end

---@param signal SignalID
---@param value integer
---@return LogisticFilter
local function to_logistic_filter(signal, value)
  return {
    value = {
      type = signal.type or "item",
      name = signal.name,
      quality = signal.quality or "normal",
      comparator = "=",
    },
    min = value,
  }
end

---@param signal SignalID
---@param value integer
---@return DeciderCombinatorOutput
local function to_decider_output(signal, value)
  return { signal = signal, constant = value, copy_count_from_input=false, }--[[@as DeciderCombinatorOutput]]
end

---@param signal SignalID
---@param value integer
---@return Signal
local function to_signal(signal, value)
  return { signal = signal, count = value, }--[[@as Signal]]
end

return {
  signals_to_string = signals_to_string,
  string_to_Ts = string_to_Ts,

  ---@param str string
  ---@return LogisticFilter[]
  string_to_logistic_filters = function(str)
    return string_to_Ts(str, to_logistic_filter)
  end,

  ---@param str string
  ---@return DeciderCombinatorOutput[]
  string_to_decider_outputs = function(str)
    return string_to_Ts(str, to_decider_output)
  end,

  ---@param str string
  ---@return Signal[]
  string_to_signals = function(str)
    return string_to_Ts(str, to_signal)
  end,
}
