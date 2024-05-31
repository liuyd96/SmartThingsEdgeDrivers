-- Copyright 2024 SmartThings
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
local cluster_base = require "st.zigbee.cluster_base"
local custom_clusters = require "shus/custom_clusters"
local custom_capabilities = require "shus/custom_capabilities"
local log = require "log"
local socket = require "cosock.socket"


local FINGERPRINTS = {
  { mfr = "SHUS", model = "shus.smart.mattress" }
}

-- #############################
-- # Attribute handlers define #
-- #############################

local function process_switch_attr(device, value, cmd)
  if value.value == false then
    device:emit_event(cmd.off())
  elseif value.value == true then
    device:emit_event(cmd.on())
  end
end

local function left_ai_mode_attr_handler(driver, device, value, zb_rx)
  process_switch_attr(device, value, custom_capabilities.ai_mode.left)
end

local function right_ai_mode_attr_handler(driver, device, value, zb_rx)
  process_switch_attr(device, value, custom_capabilities.ai_mode.right)
end

local function auto_inflation_attr_handler(driver, device, value, zb_rx)
  process_switch_attr(device, value, custom_capabilities.auto_inflation.state)
end

local function strong_exp_mode_attr_handler(driver, device, value, zb_rx)
  process_switch_attr(device, value, custom_capabilities.strong_exp_mode.state)
end

local function process_control_attr(device, value, cmd)
  if value.value == 0 then
    device:emit_event(cmd.soft())
  elseif value.value == 1 then
    device:emit_event(cmd.middle())
  elseif value.value == 2 then
    device:emit_event(cmd.hard())
  end
end

local function left_back_attr_handler(driver, device, value, zb_rx)
  process_control_attr(device, value, custom_capabilities.left_control.back)
end

local function left_waist_attr_handler(driver, device, value, zb_rx)
  process_control_attr(device, value, custom_capabilities.left_control.waist)
end

local function left_hip_attr_handler(driver, device, value, zb_rx)
  process_control_attr(device, value, custom_capabilities.left_control.hip)
end

local function right_back_attr_handler(driver, device, value, zb_rx)
  process_control_attr(device, value, custom_capabilities.right_control.back)
end

local function right_waist_attr_handler(driver, device, value, zb_rx)
  process_control_attr(device, value, custom_capabilities.right_control.waist)
end

local function right_hip_attr_handler(driver, device, value, zb_rx)
  process_control_attr(device, value, custom_capabilities.right_control.hip)
end

local function yoga_attr_handler(driver, device, value, zb_rx)
  if value.value == 0 then
    device:emit_event(custom_capabilities.yoga.state.stop())
  elseif value.value == 1 then
    device:emit_event(custom_capabilities.yoga.state.left())
  elseif value.value == 2 then
    device:emit_event(custom_capabilities.yoga.state.right())
  elseif value.value == 3 then
    device:emit_event(custom_capabilities.yoga.state.both())
  end
end

-- ##############################
-- # Capability handlers define #
-- ##############################

local function send_read_attr_request(device, cluster, attr)
  device:send(
    cluster_base.read_manufacturer_specific_attribute(
      device,
      cluster.id,
      attr.id,
      cluster.mfg_specific_code
    )
  )
end

local function do_refresh(driver, device)
  log.error("Enter refresh !!!!!!!!!!!!!!!!!!!!!!!!!!!")

  send_read_attr_request(device, custom_clusters.shus_smart_mattress, custom_clusters.shus_smart_mattress.attributes.left_ai_mode)
  send_read_attr_request(device, custom_clusters.shus_smart_mattress, custom_clusters.shus_smart_mattress.attributes.right_ai_mode)

  socket.sleep(1.5)

  send_read_attr_request(device, custom_clusters.shus_smart_mattress, custom_clusters.shus_smart_mattress.attributes.auto_inflation)
  send_read_attr_request(device, custom_clusters.shus_smart_mattress, custom_clusters.shus_smart_mattress.attributes.strong_exp_mode)

  log.error("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
  socket.sleep(1.5)
  log.error("BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB")

  send_read_attr_request(device, custom_clusters.shus_smart_mattress, custom_clusters.shus_smart_mattress.attributes.left_back)
  send_read_attr_request(device, custom_clusters.shus_smart_mattress, custom_clusters.shus_smart_mattress.attributes.left_waist)

  socket.sleep(1.5)

  send_read_attr_request(device, custom_clusters.shus_smart_mattress, custom_clusters.shus_smart_mattress.attributes.left_hip)
  send_read_attr_request(device, custom_clusters.shus_smart_mattress, custom_clusters.shus_smart_mattress.attributes.right_back)

  socket.sleep(1.5)

  send_read_attr_request(device, custom_clusters.shus_smart_mattress, custom_clusters.shus_smart_mattress.attributes.right_waist)
  send_read_attr_request(device, custom_clusters.shus_smart_mattress, custom_clusters.shus_smart_mattress.attributes.right_hip)

  socket.sleep(1.5)
  send_read_attr_request(device, custom_clusters.shus_smart_mattress, custom_clusters.shus_smart_mattress.attributes.yoga)
end

local function process_switch_cap(device, value, cluster, attr)
  if value == "on" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        cluster.id,
        attr.id,
        cluster.mfg_specific_code,
        attr.value_type,
        attr.value.on
      )
    )
  elseif value == "off" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        cluster.id,
        attr.id,
        cluster.mfg_specific_code,
        attr.value_type,
        attr.value.off
      )
    )
  end
end

local function left_ai_mode_cap_handler(driver, device, cmd)
  process_switch_cap(
    device,
    cmd.args.leftControl,
    custom_clusters.shus_smart_mattress,
    custom_clusters.shus_smart_mattress.attributes.left_ai_mode
  )
end

local function right_ai_mode_cap_handler(driver, device, cmd)
  process_switch_cap(
    device,
    cmd.args.rightControl,
    custom_clusters.shus_smart_mattress,
    custom_clusters.shus_smart_mattress.attributes.right_ai_mode
  )
end

local function auto_inflation_cap_handler(driver, device, cmd)
  process_switch_cap(
    device,
    cmd.args.stateControl,
    custom_clusters.shus_smart_mattress,
    custom_clusters.shus_smart_mattress.attributes.auto_inflation
  )
end

local function strong_exp_mode_cap_handler(driver, device, cmd)
  process_switch_cap(
    device,
    cmd.args.stateControl,
    custom_clusters.shus_smart_mattress,
    custom_clusters.shus_smart_mattress.attributes.strong_exp_mode
  )
end

local function process_control_cap(device, value, cluster, attr)
  if value == "soft" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        cluster.id,
        attr.id,
        cluster.mfg_specific_code,
        attr.value_type,
        attr.value.soft
      )
    )
  elseif value == "middle" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        cluster.id,
        attr.id,
        cluster.mfg_specific_code,
        attr.value_type,
        attr.value.middle
      )
    )
  elseif value == "hard" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        cluster.id,
        attr.id,
        cluster.mfg_specific_code,
        attr.value_type,
        attr.value.hard
      )
    )
  end
end

local function left_control_back_cap_handler(driver, device, cmd)
  process_control_cap(
    device,
    cmd.args.backControl,
    custom_clusters.shus_smart_mattress,
    custom_clusters.shus_smart_mattress.attributes.left_back
  )
end

local function left_control_waist_cap_handler(driver, device, cmd)
  process_control_cap(
    device,
    cmd.args.waistControl,
    custom_clusters.shus_smart_mattress,
    custom_clusters.shus_smart_mattress.attributes.left_waist
  )
end

local function left_control_hip_cap_handler(driver, device, cmd)
  process_control_cap(
    device,
    cmd.args.hipControl,
    custom_clusters.shus_smart_mattress,
    custom_clusters.shus_smart_mattress.attributes.left_hip
  )
end

local function right_control_back_cap_handler(driver, device, cmd)
  process_control_cap(
    device,
    cmd.args.backControl,
    custom_clusters.shus_smart_mattress,
    custom_clusters.shus_smart_mattress.attributes.right_back
  )
end

local function right_control_waist_cap_handler(driver, device, cmd)
  process_control_cap(
    device,
    cmd.args.waistControl,
    custom_clusters.shus_smart_mattress,
    custom_clusters.shus_smart_mattress.attributes.right_waist
  )
end

local function right_control_hip_cap_handler(driver, device, cmd)
  process_control_cap(
    device,
    cmd.args.hipControl,
    custom_clusters.shus_smart_mattress,
    custom_clusters.shus_smart_mattress.attributes.right_hip
  )
end

local function yoga_cap_handler(driver, device, cmd)
  if cmd.args.stateControl == "stop" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        custom_clusters.shus_smart_mattress.id,
        custom_clusters.shus_smart_mattress.attributes.yoga.id,
        custom_clusters.shus_smart_mattress.mfg_specific_code,
        custom_clusters.shus_smart_mattress.attributes.yoga.value_type,
        custom_clusters.shus_smart_mattress.attributes.yoga.value.stop
      )
    )
  elseif cmd.args.stateControl == "left" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        custom_clusters.shus_smart_mattress.id,
        custom_clusters.shus_smart_mattress.attributes.yoga.id,
        custom_clusters.shus_smart_mattress.mfg_specific_code,
        custom_clusters.shus_smart_mattress.attributes.yoga.value_type,
        custom_clusters.shus_smart_mattress.attributes.yoga.value.left
      )
    )
  elseif cmd.args.stateControl == "right" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        custom_clusters.shus_smart_mattress.id,
        custom_clusters.shus_smart_mattress.attributes.yoga.id,
        custom_clusters.shus_smart_mattress.mfg_specific_code,
        custom_clusters.shus_smart_mattress.attributes.yoga.value_type,
        custom_clusters.shus_smart_mattress.attributes.yoga.value.right
      )
    )
  elseif cmd.args.stateControl == "both" then
    device:send(
      cluster_base.write_manufacturer_specific_attribute(
        device,
        custom_clusters.shus_smart_mattress.id,
        custom_clusters.shus_smart_mattress.attributes.yoga.id,
        custom_clusters.shus_smart_mattress.mfg_specific_code,
        custom_clusters.shus_smart_mattress.attributes.yoga.value_type,
        custom_clusters.shus_smart_mattress.attributes.yoga.value.both
      )
    )
  end
end

-- #############################
-- # Lifecycle handlers define #
-- #############################

local function device_init(driver, device)
  -- TODO
  log.error("---------------------------- Enter Init------------------------")
end

local function device_added(driver, device)
  do_refresh(driver, device)
end

local function do_configure(driver, device)
  -- TODO
  log.error("@@@@@@@@@@@@@@@@@@@@@@@@@@ Enter do_configure @@@@@@@@@@@@@@@@@@@@@@@@@@@@")
end

local function is_shus_products(opts, driver, device)
  for _, fingerprint in ipairs(FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      return true
    end
  end
  return false
end

-- #################
-- # Handlers bind #
-- #################

local shus_smart_mattress = {
  NAME = "Shus Smart Mattress",
  supported_capabilities = {
    capabilities.refresh
  },
  lifecycle_handlers = {
    init = device_init,
    added = device_added,
    doConfigure = do_configure
  },
  zigbee_handlers = {
    attr = {
      [custom_clusters.shus_smart_mattress.id] = {
        [custom_clusters.shus_smart_mattress.attributes.left_ai_mode.id] = left_ai_mode_attr_handler,
        [custom_clusters.shus_smart_mattress.attributes.right_ai_mode.id] = right_ai_mode_attr_handler,
        [custom_clusters.shus_smart_mattress.attributes.auto_inflation.id] = auto_inflation_attr_handler,
        [custom_clusters.shus_smart_mattress.attributes.strong_exp_mode.id] = strong_exp_mode_attr_handler,
        [custom_clusters.shus_smart_mattress.attributes.left_back.id] = left_back_attr_handler,
        [custom_clusters.shus_smart_mattress.attributes.left_waist.id] = left_waist_attr_handler,
        [custom_clusters.shus_smart_mattress.attributes.left_hip.id] = left_hip_attr_handler,
        [custom_clusters.shus_smart_mattress.attributes.right_back.id] = right_back_attr_handler,
        [custom_clusters.shus_smart_mattress.attributes.right_waist.id] = right_waist_attr_handler,
        [custom_clusters.shus_smart_mattress.attributes.right_hip.id] = right_hip_attr_handler,
        [custom_clusters.shus_smart_mattress.attributes.yoga.id] = yoga_attr_handler
      }
    }
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = do_refresh
    },
    [custom_capabilities.ai_mode.ID] = {
      ["leftControl"] = left_ai_mode_cap_handler,
      ["rightControl"] = right_ai_mode_cap_handler
    },
    [custom_capabilities.auto_inflation.ID] = {
      ["stateControl"] = auto_inflation_cap_handler
    },
    [custom_capabilities.strong_exp_mode.ID] = {
      ["stateControl"] = strong_exp_mode_cap_handler
    },
    [custom_capabilities.left_control.ID] = {
      ["backControl"] = left_control_back_cap_handler,
      ["waistControl"] = left_control_waist_cap_handler,
      ["hipControl"] = left_control_hip_cap_handler
    },
    [custom_capabilities.right_control.ID] = {
      ["backControl"] = right_control_back_cap_handler,
      ["waistControl"] = right_control_waist_cap_handler,
      ["hipControl"] = right_control_hip_cap_handler
    },
    [custom_capabilities.yoga.ID] = {
      ["stateControl"] = yoga_cap_handler
    }
  },
  can_handle = is_shus_products
}

return shus_smart_mattress