local data_types = require "st.matter.data_types"

local data = "\x00\x00\x00\x00\x00\x00\x00\x01"

local result = data_types.validate_or_build_type(data, data_types.Uint64, "effectId")

print("1111111")
print(result)
