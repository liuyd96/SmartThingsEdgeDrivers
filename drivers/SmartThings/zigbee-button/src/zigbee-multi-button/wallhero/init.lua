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
local log = require "log"
local stDevice = require "st.device"
local socket = require "cosock.socket"
local zcl_clusters = require "st.zigbee.zcl.clusters"

local Scenes = zcl_clusters.Scenes

local FINGERPRINTS = {
  { mfr = "WALL HERO", model = "ACL-401SCA4" }
}

local function can_handle_wallhero_button(opts, driver, device, ...)
  for _, fingerprint in ipairs(FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      return true
    end
  end
  return false
end

local function scenes_cluster_handler(driver, device, zb_rx)
  local additional_fields = {
    state_change = true
  }

  local ep = zb_rx.address_header.src_endpoint.value
  local button_name = "button" .. ep
  local event = capabilities.button.button.pushed(additional_fields)
  local comp = device.profile.components[button_name]
  if comp ~= nil then
    device:emit_component_event(comp, event)
    device:emit_event(event)
  else
    log.warn("Attempted to emit button event for unknown button: " .. button_name)
  end
end

local function find_child(parent, ep_id)
  return parent:get_child_by_parent_assigned_key(string.format("%02X", ep_id))
end

local function create_child_devices(driver, device)
  local base_name = device.label:sub(1, device.label:find(" "))
  for i = 2, 30, 1 do
    if find_child(device, i) == nil then
      local metadata = {
        type = "EDGE_CHILD",
        parent_assigned_child_key = string.format("%02X", i),
        label = base_name .. i,
        profile = "one-button",
        parent_device_id = device.id,
        vendor_provided_label = base_name .. i,
      }
      driver:try_create_device(metadata)
    end
    -- Add timeout to avoid missing create devices
    socket.sleep(2)
  end
  device:refresh()
end

local function added_handler(driver, device)
  if device.network_type ~= stDevice.NETWORK_TYPE_CHILD then
    create_child_devices(driver, device)
  end
  -- Set Button Capabilities for scene switches
  if device:supports_capability_by_id(capabilities.button.ID) then
    device:emit_event(capabilities.button.numberOfButtons({ value = 1 }, { visibility = { displayed = false } }))
    device:emit_event(capabilities.button.supportedButtonValues({ "pushed" }, {visibility = {displayed = false } }))
  end
end

local function component_to_endpoint(device, component_id)
  local ep_num = component_id:match("button(%d)")
  return ep_num and tonumber(ep_num) or device.fingerprinted_endpoint_id
end

local function endpoint_to_component(device, ep)
  local button_comp = string.format("button%d", ep)
  if device.profile.components[button_comp] ~= nil then
    return button_comp
  else
    return "main"
  end
end

local device_init = function(self, device)
  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)
end

local wallhero_button = {
  NAME = "Zigbee Wall Hero Button",
  lifecycle_handlers = {
    init = device_init,
    added = added_handler
  },
  zigbee_handlers = {
    cluster = {
      [Scenes.ID] = {
        [Scenes.server.commands.RecallScene.ID] = scenes_cluster_handler,
      }
    }
  },
  can_handle = can_handle_wallhero_button
}

return wallhero_button
