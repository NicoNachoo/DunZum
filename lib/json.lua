--
-- json.lua
--
-- A lightweight JSON library for Lua
--

local json = {}

-- Internal functions

local function kind_of(obj)
  if type(obj) ~= 'table' then return type(obj) end
  local i = 1
  for _ in pairs(obj) do
    if obj[i] ~= nil then i = i + 1 else return 'table' end
  end
  if i == 1 then return 'table' else return 'array' end
end

local function escape_str(s)
  local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
  local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
  for i, c in ipairs(in_char) do
    s = s:gsub(c, '\\' .. out_char[i])
  end
  return s
end

local function skip_delim(str, pos, delim, err_if_missing)
  pos = pos + #str:match('^%s*', pos)
  if str:sub(pos, pos) ~= delim then
    if err_if_missing then
      error('Expected ' .. delim .. ' near position ' .. pos)
    end
    return pos, false
  end
  return pos + 1, true
end

local function parse_str_val(str, pos, val)
  local x
  if val == 'true' then x = true
  elseif val == 'false' then x = false
  elseif val == 'null' then x = nil
  elseif tonumber(val) then x = tonumber(val)
  elseif val:sub(1,1) == '"' then
    x = val:sub(2, -2)
    -- define unescape handling
     local function unescape(s)
         local mapping = {
             ['b'] = '\b', ['f'] = '\f', ['n'] = '\n',
             ['r'] = '\r', ['t'] = '\t', ['"'] = '"',
             ['\\'] = '\\', ['/'] = '/'
         }
         return mapping[s] or s
     end
    x = x:gsub('\\(.)', unescape)
  else error('Unknown token: '..val)
  end
  return pos, x
end

-- Public functions

function json.encode(obj, stack)
  local t = kind_of(obj)
  if t == 'boolean' then return tostring(obj) end
  if t == 'number' then return tostring(obj) end
  if t == 'string' then return '"' .. escape_str(obj) .. '"' end
  if t == 'array' then
    local s = '['
    for i, val in ipairs(obj) do
        if i > 1 then s = s .. ',' end
        s = s .. json.encode(val)
    end
    return s .. ']'
  end
  if t == 'table' then
    local s = '{'
    local first = true
    for k, val in pairs(obj) do
        if not first then s = s .. ',' end
        s = s .. '"' .. escape_str(k) .. '":' .. json.encode(val)
        first = false
    end
    return s .. '}'
  end
  if t == 'nil' then return 'null' end
  error('Cannot encode type: ' .. t)
end

function json.decode(str)
  local pos = 1
  local atomic_types = {['true']=true, ['false']=true, ['null']=true}
  
  local function parse_val(str, pos)
      pos = pos + #str:match('^%s*', pos)
      local char = str:sub(pos, pos)
      
      if char == '{' then -- Object
          local obj = {}
          pos = pos + 1
          while true do
              pos = pos + #str:match('^%s*', pos)
              if str:sub(pos, pos) == '}' then return pos + 1, obj end
              
              local key
              pos, key = parse_val(str, pos)
              
              pos = skip_delim(str, pos, ':', true)
              
              local val
              pos, val = parse_val(str, pos)
              obj[key] = val
              
              pos = skip_delim(str, pos, ',', false)
          end
      elseif char == '[' then -- Array
          local arr = {}
          pos = pos + 1
          local idx = 1
          while true do
              pos = pos + #str:match('^%s*', pos)
              if str:sub(pos, pos) == ']' then return pos + 1, arr end
              
              local val
              pos, val = parse_val(str, pos)
              arr[idx] = val
              idx = idx + 1
              
              pos = skip_delim(str, pos, ',', false)
          end
      elseif char == '"' then -- String
          local start = pos
          -- Simple string parsing (doesn't handle escaped quotes perfectly in regex but good enough for simple manifests)
          -- Better logic:
          local i = pos + 1
          while i <= #str do
              if str:sub(i, i) == '"' and str:sub(i-1, i-1) ~= '\\' then
                  break
              end
              i = i + 1
          end
          local val = str:sub(start + 1, i - 1)
          
           -- unescape
           local function unescape(s)
              local mapping = {
                  ['b'] = '\b', ['f'] = '\f', ['n'] = '\n',
                  ['r'] = '\r', ['t'] = '\t', ['"'] = '"',
                  ['\\'] = '\\', ['/'] = '/'
              }
              return mapping[s] or s
          end
          val = val:gsub('\\(.)', unescape)
          
          return i + 1, val
      else -- Atomic / Number
          local start = pos
          while pos <= #str do
             local c = str:sub(pos, pos)
             if c == ' ' or c == ',' or c == '}' or c == ']' or c == '\n' or c == '\r' or c == '\t' then
                 break
             end
             pos = pos + 1
          end
          local val_str = str:sub(start, pos - 1)
          local val
          if atomic_types[val_str] then
             if val_str == 'true' then val = true
             elseif val_str == 'false' then val = false
             elseif val_str == 'null' then val = nil end
          else
             val = tonumber(val_str)
          end
          return pos, val
      end
  end
  
  local _, res = parse_val(str, pos)
  return res
end

return json
