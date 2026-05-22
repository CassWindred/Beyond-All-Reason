local widget = widget ---@type Widget

function widget:GetInfo()
    return {
        name = "Drag Transport",
        desc = ".",
        author = "FyreFly",
        version = "v0",
        date = "",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true,
        handler = true
    }
end

local MINIMUM_DRAG_DISTANCE_SQUARED = 5

-- Localized Spring API for performance
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetSelectedUnitsCount = Spring.GetSelectedUnitsCount
local spTraceScreenRay = Spring.TraceScreenRay
local spGetUnitDefID = Spring.GetUnitDefID
local spEcho = Spring.Echo

spEcho("Widget loaddedd: " .. widget:GetInfo().name .. " - " .. widget:GetInfo().desc)

local startPos = nil
local currentPos = nil
local currentTarget = nil
local cachedUnitDefs = {}

for id, def in pairs(UnitDefs) do
    cachedUnitDefs[id] = {
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

-- Issues:
-- Starting drag while a transport is not loaded, and ending it while the unit is loaded, causes a bit of a panic
local unitUtils = VFS.Include("luaui/Include/Utilities/unit_utils.lua")
local cursorUtils = VFS.Include("luaui/Include/Utilities/cursor_utils.lua")
spEcho("Unitutils: " .. tostring(unitUtils.unitUnderCursor))
local unitUnderCursor, mouseToWorldPosition = cursorUtils.unitUnderCursor, cursorUtils.mouseToWorldPosition
local couldTransport = unitUtils.couldTransport
spEcho("Cachessdddsd  unit definitions for " .. #cachedUnitDefs .. " units.")
spEcho("Widget loadded: " .. widget:GetInfo().name .. " - " .. widget:GetInfo().desc)

local function endDrag()
    spEcho("Ending drag.")
    startPos = nil
    currentPos = nil
    currentTarget = nil
end

function widget:MousePress(mx, my, mButton)
    -- Current issue: Breaks default command behaviour, most notably guard as a default when full.
    spEcho(
        "Mouse sPressed: " .. mButton .. " at (" .. mx .. ", " .. my .. ")" .. "World Pos:"
            .. tostring(mouseToWorldPosition(mx, my)[1]) .. ", " .. tostring(mouseToWorldPosition(mx, my)[2]) .. ", "
            .. tostring(mouseToWorldPosition(mx, my)[3])
    )
    if mButton == 1 and startPos then
        -- If left-click is pressed while dragging, cancel the drag
        endDrag()
        return true
    end
    if mButton ~= 3 then return false end

    -- Only work for a single unit
    if spGetSelectedUnitsCount()~=1 then return false end

    local selectedUnit = spGetSelectedUnits()[1]

    -- Only work for transports
    if Spring.FindUnitCmdDesc(selectedUnit, CMD.UNLOAD_UNITS) == nil then return false end

    local target = unitUnderCursor(mx, my)
    spEcho("Unit under cursor: " .. tostring(target) .. " at (" .. mx .. ", " .. my .. ")")
    if not target or not couldTransport(selectedUnit, target) then return false end

    -- From here: A single unit is selected, it's a transport, and the mouse is over a unit that can be transported. Mark the start position.
    local worldPos = mouseToWorldPosition(mx, my)

    if not worldPos then
        -- No worldpos if user clicks outside the map.
        return false
    end

    startPos = mouseToWorldPosition(mx, my)
    currentTarget = target

    spEcho("Start dragging transport with unit " .. target)

    return true
end

function widget:MouseMove(mx, my, dx, dy, mButton)
    if not startPos then return false end
    spEcho("Mouse moved: " .. mx .. ", " .. my .. " with button " .. mButton)
    currentPos = mouseToWorldPosition(mx, my)
    return true
end

function widget:MouseRelease(mx, my, mButton)
    spEcho("Mouse Released: " .. mButton)
    local selectedUnit = spGetSelectedUnits()[1]
    if mButton == 3 and currentTarget and startPos then
        local alt, ctrl, meta, shift = Spring.GetModKeyState()
        spEcho("Attempting to load unit " .. currentTarget .. " into transport.")
        -- Need a check for if something is already being transported, and if so, whether the transport can still take the new unit (capacity and mass)
        Spring.GiveOrder(CMD.LOAD_UNITS, { currentTarget }, (shift and { "shift" } or {}))
        if currentPos then
            local dist = math.distance2dSquared(startPos[1], startPos[3], currentPos[1], currentPos[3])
            if dist >= MINIMUM_DRAG_DISTANCE_SQUARED then
                Spring.GiveOrder(CMD.UNLOAD_UNIT, { currentPos[1], currentPos[2], currentPos[3], currentTarget }, { "shift" })
            end
        end
        endDrag()
    end
end

function widget:DrawWorld()
    if startPos and currentPos and currentTarget then
        local sx, sy, sz = startPos[1], startPos[2], startPos[3]
        local ex, ey, ez = currentPos[1], currentPos[2], currentPos[3]
        gl.Color(0.45, 1, 0.45)
        local pattern = (65536 - 775)
        gl.LineStipple(2, pattern, 0)

        gl.BeginEnd(GL.LINES, function ()
            gl.Vertex(sx, sy, sz)
            gl.Vertex(ex, ey, ez)
        end)
        gl.LineStipple(false)
    end
end
