--TODO: mechanism for other mods to offer signal/char mappings to be added. maybe more map to global?
local charmap={
  c2s={
    ["0"]='signal-0',["1"]='signal-1',["2"]='signal-2',["3"]='signal-3',["4"]='signal-4',
    ["5"]='signal-5',["6"]='signal-6',["7"]='signal-7',["8"]='signal-8',["9"]='signal-9',
    ["A"]='signal-A',["B"]='signal-B',["C"]='signal-C',["D"]='signal-D',["E"]='signal-E',
    ["F"]='signal-F',["G"]='signal-G',["H"]='signal-H',["I"]='signal-I',["J"]='signal-J',
    ["K"]='signal-K',["L"]='signal-L',["M"]='signal-M',["N"]='signal-N',["O"]='signal-O',
    ["P"]='signal-P',["Q"]='signal-Q',["R"]='signal-R',["S"]='signal-S',["T"]='signal-T',
    ["U"]='signal-U',["V"]='signal-V',["W"]='signal-W',["X"]='signal-X',["Y"]='signal-Y',
    ["Z"]='signal-Z'
  },
  s2c={
    ['signal-0']='0',['signal-1']='1',['signal-2']='2',['signal-3']='3',['signal-4']='4',
    ['signal-5']='5',['signal-6']='6',['signal-7']='7',['signal-8']='8',['signal-9']='9',
    ['signal-A']='A',['signal-B']='B',['signal-C']='C',['signal-D']='D',
    ['signal-E']='E',['signal-F']='F',['signal-G']='G',['signal-H']='H',
    ['signal-I']='I',['signal-J']='J',['signal-K']='K',['signal-L']='L',
    ['signal-M']='M',['signal-N']='N',['signal-O']='O',['signal-P']='P',
    ['signal-Q']='Q',['signal-R']='R',['signal-S']='S',['signal-T']='T',
    ['signal-U']='U',['signal-V']='V',['signal-W']='W',['signal-X']='X',
    ['signal-Y']='Y',['signal-Z']='Z',
	}
}

local function charsig(c)
	return charmap.c2s[c]
end

local function sigchar(c)
	return charmap.s2c[c] or ''
end

remote.add_interface('signalstrings',
{
signals_to_string = function(signals)
  local str=""
  for i=0,30 do
    local endOfString=true
    for _,sig in pairs(signals) do
      local sigbit = bit32.extract(sig.count,i)
      if sig.signal.type=="virtual" and sigbit==1 then
        endOfString=false
        str=str .. sigchar(sig.signal.name)
      end
    end
    if endOfString then break end
  end
  return str
end,
string_to_signals = function(str)
  local s = string.upper(str)
  local letters = {}
  local i=1
  while s do
    local c
    if #s > 1 then
      c,s=s:sub(1,1),s:sub(2)
    else
      c,s=s,nil
    end
    letters[c]=(letters[c] or 0)+i
    i=i*2
  end

  local signals = {}
  for c,i in pairs(letters) do
    signals[#signals+1]={index=#signals+1,count=i,signal={name=charsig(c),type="virtual"}}
  end
  return signals
end,
})
