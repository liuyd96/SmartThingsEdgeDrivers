# Problem report

## Development Env reference

This is my EdgeDriver dev env setting, for reference only.

```bash
liuyd in 🌐 eco-HP-ProDesk-600-G3-MT in ~/lua_api
❯ ll
total 6188
drwxrwxr-x  4 liuyd liuyd    4096 4月  28 17:51 ./
drwxr-xr-x 54 liuyd liuyd    4096 5月  15 13:17 ../
drwxr-xr-x  8 liuyd liuyd    4096 2月  28 06:25 docs/
lrwxrwxrwx  1 liuyd liuyd      15 3月  29 17:05 lua_libs -> lua_libs-api_v9/
drwxrwxr-x 14 liuyd liuyd    4096 4月  28 17:52 lua_libs-api_v9/
-rw-rw-r--  1 liuyd liuyd 6318881 3月   7 01:14 lua_libs-api_v9_52X.tar.gz

liuyd in 🌐 eco-HP-ProDesk-600-G3-MT in ~/lua_api
❯ grep LUA_PATH ~/.bashrc
export LUA_PATH="/home/liuyd/lua_api/lua_libs/?.lua;/home/liuyd/lua_api/lua_libs/?/init.lua;;"

liuyd in 🌐 eco-HP-ProDesk-600-G3-MT in ~/lua_api
❯ lua -v
Lua 5.3.3  Copyright (C) 1994-2016 Lua.org, PUC-Rio
```

## Background

Recently I'm developing EdgeDriver for a matter light which uses a private cluster to control light scene.

I've developed a custom capabiility and want to parse this capability into related Matter message.
Per docs provided by manufacture, the data type is **Uint64**.

Here are some code snippets.

```lua
local data_types = require "st.matter.data_types"

local LIGHTING_EFFECT_ID = {
---snip---
  ["starrySky"] = "\x00\x00\x00\x00\x00\x00\x00\x0F",
  ["aurora"] = "\x0F\x00\x00\x00\x00\x00\x00\x00",
---snip---
} 

---snip---
local function state_control_handler(driver, device, cmd) -- custom capability handler

  local data = data_types.validate_or_build_type(LIGHTING_EFFECT_ID[cmd.args.stateControl], data_types.Uint64, "effectId") -- "validate_or_build_type" is must for Matter data

  local parameter = {data}
  local message = cluster_base.build_cluster_command(driver, device, parameter, 0x02,
    PRIVATE_CLUSTER_ID, PRIVATE_LIGHTING_THINGS_CMD)
  device:send(message)
---snip---
end
```

## Problem

- build_cluster_command can't parse matter Uint64 (**test3.lua**)
  If we pass `parameter` to `build_cluster_command`, we got error

  ```text
  [string "st/utils.lua"]:188:bad argument #2 to 'pack' (number expected, got string)
  ```

  This is what we asked yesterday. It's strange that `build_cluster_command` can't parse the data which is generated from `validate_or_build_type`.

- Green's answer doesn't work (**test1.lua/test2.lua**)

  ```text
  My guess is that you'd want to change the map types to be int literals, so probably
  0x000000000000000F and
  0xF000000000000000 without the quotes
  ```

  We have already tried **INT** literals, that is how we originally defined。
  Then we got error (**test1.lua could reproduce**)

  ```text
  Error creating effectId: ..._api/lua_libs/st/matter/data_types/base_defs/DataABC.lua:110: Uint64 values must be string bytes
  ```

  So we think string bytes definition of Uint64 is the correct way. (**test2.lua could prove it**) [Official doc](https://developer.smartthings.com/docs/edge-device-drivers/matter/data_types.html?highlight=uint64#st.matter.data_types.Uint64.value)
  
## Summary

- We need to build/send a Uint64 data to a matter device
- Current Lua library use string bytes to implement Uint64
- `build_cluster_command` expect number, but Uint64 is implemented in string. (We guess this is the root cause.)
