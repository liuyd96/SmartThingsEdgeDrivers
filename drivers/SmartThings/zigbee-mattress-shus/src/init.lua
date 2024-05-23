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
local ZigbeeDriver = require "st.zigbee"
local defaults = require "st.zigbee.defaults"
local constants = require "st.zigbee.constants"

local zigbee_mattress_template = {
  supported_capabilities = {
    capabilities.refresh,
  },
  sub_drivers = {
    require("shus"),
  },
  ias_zone_configuration_method = constants.IAS_ZONE_CONFIGURE_TYPE.AUTO_ENROLL_RESPONSE,
}

defaults.register_for_default_handlers(zigbee_mattress_template, zigbee_mattress_template.supported_capabilities)
local zigbee_mattress_driver = ZigbeeDriver("zigbee-mattress", zigbee_mattress_template)
zigbee_mattress_driver:run()
