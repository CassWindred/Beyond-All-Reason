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


-- Initially from from luaui\Widgets\cmd_guard_transport_factory.lua
local function canTransport(transportID, unitID)
    local udef = Spring.GetUnitDefID(unitID)
    local tdef = Spring.GetUnitDefID(transportID)

    if not udef or not tdef then
        return false
    end

    local uDefObj = cachedTransportUnitDefs[udef]
    local tDefObj = cachedTransportUnitDefs[tdef]

    if uDefObj.xsize > tDefObj.transportSize * Game.footprintScale then
        return false
    end

    local trans = Spring.GetUnitIsTransporting(transportID) -- capacity check
    if tDefObj.transportCapacity <= #trans then
        return false
    end

    if uDefObj.cantBeTransported then
        return false
    end

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

return { canTransport = canTransport }