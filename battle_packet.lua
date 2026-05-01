-- https://github.com/atom0s/XiPackets/tree/main/world/server/0x0028
--
-- This implementation is only completed far enough to extract skillchain data.

local Bitreader = require('bitreader')
local Bit = require('bit')

---@class BattlePacketTargetResult
---@field miss integer The type of connection this attack makes (hit, miss, block, parry, etc.)
---@field kind integer cmd_no specific. Governs animations
---@field sub_kind integer cmd_no specific. Governs animations
---@field info integer miss specific. For general attacks, governs attack severity
---@field scale integer cmd_no specific. For most attacks, governs animations
---@field value integer cmd_no specific. Usually the damage or healing done
---@field message integer The format string to load and print to the chat log
---@field bit integer Extra message formatting (Crit!, Magic burst! etc.)
---@field has_proc integer Flag declaring if proc_ fields are included. All proc_ fields are zero if this is zero.
---@field proc_kind integer cmd_no specific. Additional effects caused by the attack (enfire, distortion, etc.)
---@field proc_info integer unknown.
---@field proc_value integer cmd_no specific. Holds a parameter associated with the proc
---@field proc_message integer Format string to load and print to the chat log.
---@field has_react integer Flag declaring if react_ fields are included. Just like has_proc
---@field react_kind integer cmd_no specific. Additional effects triggered by the defender (blaze spikes, counter, etc.)
---@field react_info integer unknown.
---@field react_value integer unknown.
---@field react_message integer Format string to load and print to the chat log.

---@class BattlePacketTarget
---@field m_uID integer The defender's server id
---@field result_sum integer The number of effects this defender receives (max 8)
---@field results BattlePacketTargetResult The list of effects (count lives in result_sum)

---@class BattlePacket
--- A table containing information parsed from a battle packet.
---@field m_uID integer The attacker's server id
---@field trg_sum integer The number of targets affected by this attack (max 16)
---@field res_sum integer Unused. Likely always zero
---@field cmd_no integer Enum describing the type of attack made.
---@field cmd_arg integer Additional data required by indiviudal cmd_no types.
---@field info integer More data specific to individual cmd_no types.
---@field targets BattlePacketTarget[] A list of targets this attack hits (count lives in trg_sum)

local Export = {};

function Export.is_battle_event(e)
    return e.id == 0x28
end

function Export.is_possible_skillchain_event(e)
    if not Export.is_battle_event(e) then
        return false;
    end
    local data = e.data

    -- targets starts at 78 bits, each target is variable size.
    -- This function's purpose is to skip extra processing.
    -- We hit diminishing returns here trying to figure out if a
    -- skillchain is present, so just check the cmd_no.
    -- This already rules out a lot of

    -- skip 42 bits, read 4.
    -- skip 40, read 1 byte, mask: 0011 1100
    local cmd_no = bit.band(bit.rshift(data[8 + 1], 2), 0x7)

    -- 3: weaponskill finish
    -- 4: magic finish (blu shenannigans)
    -- 6: ability finish
    -- 11: monster skill finish, trust skill finish
    -- 13: pet skill finish
    -- 14: dnc ability (?)
    return T { 3, 4, 6, 11, 13, 14 }:contains(cmd_no);
end

---Parses a raw battle packet into a lua table. No additional processing.
---@param e any The Ashita incomming_packet event.
---@return BattlePacket
function Export.parse_incomming_event(e)
    local cursor = Bitreader:new(e.data_raw, 0);

    local res = {};
    res.m_uID = cursor:read(32);
    res.trg_sum = cursor:read(6);
    res.res_sum = cursor:read(4);
    res.cmd_no = cursor:read(4);
    res.cmd_arg = cursor:read(32);
    local targets = {};
    res.targets = targets;
    ---@cast res BattlePacket

    for _i = 1, res.trg_sum, 1 do
        local target = {};
        target.m_uID = cursor:read(32);
        target.result_sum = cursor:read(4);
        local results = {};
        target.results = results
        ---@cast target BattlePacketTarget
        targets[#targets + 1] = target;

        for _i = 1, target.result_sum, 1 do
            -- prepopulate the proc_ and react_ stuff.
            local result = {
                proc_kind = 0,
                proc_info = 0,
                proc_value = 0,
                proc_message = 0,
                react_kind = 0,
                react_info = 0,
                react_value = 0,
                react_message = 0,
            };
            result.miss = cursor:read(3);
            result.kind = cursor:read(2);
            result.sub_kind = cursor:read(12);
            result.info = cursor:read(5);
            result.scale = cursor:read(5);
            result.value = cursor:read(17);
            result.message = cursor:read(10);
            result.bit = cursor:read(31);

            result.has_proc = cursor:read(1);
            if result.has_proc > 1 then
                result.proc_kind = cursor:read(6);
                result.proc_info = cursor:read(4);
                result.proc_value = cursor:read(17);
                result.proc_message = cursor:read(10);
            end

            result.has_react = cursor:read(1);
            if result.has_react > 1 then
                result.react_kind = cursor:read(6);
                result.react_info = cursor:read(4);
                result.react_value = cursor:read(14);
                result.react_message = cursor:read(10);
            end

            ---@cast result BattlePacketTargetResult
            target.results[#target.results + 1] = result;
        end
    end

    return res;
end

return Export;
