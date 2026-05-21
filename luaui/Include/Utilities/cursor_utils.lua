local spTraceScreenRay = Spring.TraceScreenRay

local function unitUnderCursor(mx, my)
        local type, rayParams = spTraceScreenRay(mx, my)
        local unitId = type == 'unit' and rayParams
        return unitId or nil
end

local function mouseToWorldPosition(mx, my)
    local _, pos = spTraceScreenRay(mx, my, true)
    return pos
end


return {
    unitUnderCursor = unitUnderCursor,
    mouseToWorldPosition = mouseToWorldPosition
}