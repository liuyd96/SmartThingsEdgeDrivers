-- Copyright 2023 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local capabilities = require "st.capabilities"
local clusters = require "st.zigbee.zcl.clusters"
local cluster_base = require "st.zigbee.cluster_base"
local ds = require "datastore"
local data_types = require "st.zigbee.data_types"
local log = require "log"
local security = require "st.security"
local zcl_commands = require "st.zigbee.zcl.global_commands"

local DoorLock = clusters.DoorLock
local PRIVATE_CLUSTER_ID = 0xFCC0
local PRIVATE_ATTRIBUTE_ID = 0xFFF3
local MFG_CODE = 0x115F

local FINGERPRINTS = {
  { mfr = "Lumi", model = "aqara.lock.akr011"},
}

MY_DS = ds.init()

local function can_handle_aqara_lock(opts, driver, device, ...)
  for _, fingerprint in ipairs(FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      return true
    end
  end
  return false
end

local function dump(data)
  if type(data) == "table" then
    local s = '{ '
    for k,v in pairs(data) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '}'
  else
    return tostring(data)
  end
end

local function stringToOctetString(str)
  log.debug("Length of octetString is: " .. #str)
  local octetString = ""
  for i = 1, #str do
      local byte = string.byte(str, i)
      octetString = octetString .. string.format("\\x%02X", byte)
  end
  return octetString
end

local function stringToHex(str)
  local hexFormat = ""
  for i = 1, # str do
    local byte = string.byte(str, i)
    hexFormat = hexFormat .. string.format("%02x", byte)
  end
  return hexFormat
end

local function my_secret_data_handler(secret_info)
  log.debug("This is my_secret_data_handler: 11111111111111111111111111111111")
  log.debug(dump(secret_info))
  MY_DS.cloud_public_key = secret_info.cloud_public_key
  MY_DS.shared_key = secret_info.shared_key
  if secret_info.secret_type == "aqara" then
    log.debug("cloud_public_key is " .. secret_info.cloud_public_key)
    log.debug("shared_key is " .. secret_info.shared_key)
    log.debug("MY_DS.cloud_public_key is " .. MY_DS.cloud_public_key)
    log.debug("MY_DS.shared_key is " .. MY_DS.shared_key)
  end
end

local function init(driver, device)
  security.register_aqara_secret_handler(driver, my_secret_data_handler)
    -- Send Encrypted Cloud Public Key to Lock
  local data = "\x3E" .. stringToOctetString(MY_DS.cloud_public_key)
  log.debug("MY_DS.cloud_public_key cmd is " .. data)
  device:send(cluster_base.write_manufacturer_specific_attribute(device, PRIVATE_CLUSTER_ID, PRIVATE_ATTRIBUTE_ID, MFG_CODE,
    data_types.OctetString, data))
end

local function aqara_specific_attr_handler(driver, device, value, zb_rx)
  log.debug("Get report attribute from aqara lock 33333333333333333333333333")

  local encrypted_pub_key = string.sub(value.value, 2, 65)
  log.debug("OctestString of value is: " .. value.value)
  log.debug("value is: " .. stringToHex(value.value))
  log.debug("Length of encrypted_pub_key is: " .. #encrypted_pub_key)
  log.debug("Hex format of encrypted_pub_key is: " .. stringToHex(encrypted_pub_key))
  log.debug("encrypted_pub_key is: " .. encrypted_pub_key)

  local res, err = security.get_aqara_secret(stringToHex(device.zigbee_eui), encrypted_pub_key, "AqaraDoorlock K100", "0AE0", "006", "337dbf83-af55-449c-824b-54ffcbb3afb6")
  if res then
    log.error("Wrong !!!!!!!!!!!!!!!!!!!!")
  end
end

local function unlock_cmd_handler(driver, device, command)
  log.debug("Read MY_DS.shared_key in lock_cmd_handler: " .. MY_DS.shared_key)
  local payload = "\x0D\01F\x00\x55\x01\x00"
  local opts = {cipher = "aes256-ecb"}
  local decrypted_payload = security.encrypt_bytes(payload, MY_DS.shared_key, opts)
  log.debug("decrypted_payload is: " .. decrypted_payload)
  local message = cluster_base.write_manufacturer_specific_attribute(device, PRIVATE_CLUSTER_ID,
    PRIVATE_ATTRIBUTE_ID, MFG_CODE, data_types.OctetString.ID, decrypted_payload)
  device:send(message)
end

local function lock_cmd_handler(driver, device, command)
  log.debug("Read MY_DS.shared_key in lock_cmd_handler: " .. MY_DS.shared_key)
  local payload = "\x0D\01F\x00\x55\x01\x01"
  local opts = {cipher = "aes256-ecb"}
  local decrypted_payload = security.encrypt_bytes(payload, MY_DS.shared_key, opts)
  log.debug("decrypted_payload is: " .. decrypted_payload)
  local message = cluster_base.write_manufacturer_specific_attribute(device, PRIVATE_CLUSTER_ID,
    PRIVATE_ATTRIBUTE_ID, MFG_CODE, data_types.OctetString.ID, decrypted_payload)
  device:send(message)
end

local aqara_driver = {
  NAME = "Aqara Lock Driver",
  -- Register secret_data_handler
  lifecycle_handlers = {
    init = init,
  },
  zigbee_handlers = {
    attr = {
      [PRIVATE_CLUSTER_ID] = {
        -- Lock should report it's public key through it's attr.
        [PRIVATE_ATTRIBUTE_ID] = aqara_specific_attr_handler,
      }
    }
  },
  -- capability_handlers = {
  --   [capabilities.lock.ID] = {
  --     [capabilities.lock.commands.lock.NAME] = lock_cmd_handler,
  --     [capabilities.lock.commands.unlock.NAME] = unlock_cmd_handler
  --   }
  -- },
  -- Cloud will responsd with generated cloudPubKey and sharedKey to EdgeDriver
  -- secret_data_handler = specific_secret_data_handler,
  can_handle = can_handle_aqara_lock
}

return aqara_driver
