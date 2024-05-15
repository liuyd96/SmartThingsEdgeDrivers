local data_types = require "st.matter.data_types"
local cluster_base = require "st.matter.cluster_base"

local data = "\x00\x00\x00\x00\x00\x00\x00\x0F"

local result = data_types.validate_or_build_type(data, data_types.Uint64, "effectId")

print(result)

local parameter = {result}
local message = cluster_base.build_cluster_command(nil, nil, parameter, 0x02, 0x1312FC05, 0x1312000e)
