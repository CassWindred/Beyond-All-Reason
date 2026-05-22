local cachedTransportUnitDefs = {}
for id, def in pairs(UnitDefs) do
    cachedTransportUnitDefs[id] = {
        translatedHumanName = def.translatedHumanName,
        isTransport = def.isTransport,
        isFactory = def.isFactory,
        mass = def.mass,
        transportMass = def.transportMass,
        speed = def.speed,
        transportCapacity = def.transportCapacity,
        cantBeTransported = def.cantBeTransported,
        transportSize = def.transportSize,
        xsize = def.xsize
    }
end

-- local function sumUnitMasses(unitIDs)
--     if not unitIDs then
--         return 0
--     end
--     local mass = 0
--     for _, id in ipairs(unitIDs) do
--         local defID = Spring.GetUnitDefID(id)
--         if defID then
--             mass = mass + cachedTransportUnitDefs[defID].mass
--         end
--     end
--     return mass
-- end

-- -- Returns a tuple of count capacity and mass capacity remaining at the end of the transport's command queue, assuming all commands in the queue are executed as expected.
-- -- To avoid unecessary loops, it will return 0 for both if count capacity is capped.
-- local function transportCapacityAtEndOfQueue(transportID)
--     local tDefObj = cachedTransportUnitDefs[Spring.GetUnitDefID(transportID)]
--     if not tDefObj then
--         return 0
--     end

--     const commandQueue = Spring.GetUnitCommands(transportID, -1)

--     local countCapacity = tDefObj.transportCapacity
--     local currentlyHeldUnits = Spring.GetUnitIsTransporting(transportID)

--     local massCapacity = tDefObj.transportMass

--     countCapacity = countCapacity - #currentlyHeldUnits

--     if countCapacity <= 0 then
--         return 0, 0
--     end

--     massCapacity = massCapacity - sumUnitMasses(currentlyHeldUnits) 

--     for _, cmd in ipairs(commandQueue) do
--         if cmd.id == CMD_LOAD_UNITS then
--             local unitIDs = cmd.params

--             massCapacity = massCapacity - sumUnitMasses(unitIDs)
--         elseif cmd.id == CMD_UNLOAD_UNIT then
--             local unitID = cmd.params[1]
--             local defID = Spring.GetUnitDefID(unitID)
--             if defID then
--                 countCapacity = countCapacity + 1
--                 massCapacity = massCapacity + cachedTransportUnitDefs[defID].mass
--             end
--         elseif cmd.id == CMD_UNLOAD_UNITS then
--             local unitIDs = cmd.params
--             countCapacity = countCapacity + #unitIDs
--             for _, unitID in ipairs(unitIDs) do
--                 local defID = Spring.GetUnitDefID(unitID)
--                 if defID then
--                     massCapacity = massCapacity + cachedTransportUnitDefs[defID].mass
--                 end
--             end
--         end
--     end



-- end

local function couldTransport(transportID, unitID)
    local udef = Spring.GetUnitDefID(unitID)
    local tdef = Spring.GetUnitDefID(transportID)

    if not udef or not tdef then
        return false
    end

    local uDefObj = cachedTransportUnitDefs[udef]
    local tDefObj = cachedTransportUnitDefs[tdef]

    if uDefObj.cantBeTransported then
        return false
    end

    --- Check if the unit can fit in the transport, based on footprint size. 
    if uDefObj.xsize > tDefObj.transportSize * Game.footprintScale then
        return false
    end

    --- Check if the unit can fit in the transport, based on mass.
    if uDefObj.mass > tDefObj.transportMass then
        return false
    end


    return true
end

-- Initially from from luaui\Widgets\cmd_guard_transport_factory.lua
-- The function above has been seperated out.
local function canTransport(transportID, unitID)
    if not couldTransport(transportID, unitID) then
        return false
    end

    local uDefObj = cachedTransportUnitDefs[Spring.GetUnitDefID(unitID)]
    local tDefObj = cachedTransportUnitDefs[Spring.GetUnitDefID(transportID)]

    local trans = Spring.GetUnitIsTransporting(transportID) -- capacity check
    if tDefObj.transportCapacity <= #trans then
        return false
    end

    --- Strictly speaking, this involves redoing some of the work from couldTransport,
    --- but it may actually help performance overall, by avoiding the loop for units that could never be transported in the first place.
    --- Not that this function is likely to be particularly performance critical anyway.
    local mass = -1 -- mass check
    for _, a in ipairs(trans) do
        local aDefID = Spring.GetUnitDefID(a)
        if aDefID then
            mass = mass + cachedTransportUnitDefs[aDefID].mass
        end
    end
    mass = mass + uDefObj.mass

    if mass > tDefObj.transportMass then
        return false
    end

    return true
end

return { canTransport = canTransport, couldTransport = couldTransport }