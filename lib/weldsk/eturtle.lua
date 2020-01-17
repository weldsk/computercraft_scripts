---------------------------------------
--  enhanced turtle API              --
--      (turtle function wrapper     --
--               for moving turtle)  --
---------------------------------------

os.loadAPI("/lib/weldsk/logging")

LOG_FILEPATH = "/log/eturtle.log"
CACHE_FILEPATH = "/cache/eturtle.cache"

eturtle_log = logging.load(LOG_FILEPATH)
_load_cache()


function _load_cache()
    local str_line = _read_cache()
    if str_line then
        eturtle_log:writeLog(str_line)
    end
    _clear_cache()
end


function _read_cache()
    local str_line
    if fs.exists(CACHE_FILEPATH) then
        local file = fs.open(CACHE_FILEPATH, "r")
        str_line = file.readLine()
        file.close()
    end
    return str_line
end

function _write_cache(message)
    local file = fs.open(CACHE_FILEPATH, "w")
    file.writeLine(message)
    file.flush()
    file.close()
end

function _clear_cache()
    if fs.exists(CACHE_FILEPATH) then
        fs.delete(CACHE_FILEPATH)
    end
    local cache_file = fs.open(CACHE_FILEPATH, "w")
    cache_file.close()
end

function craft(...)
    return turtle.craft(...)
end

function forward()
    _write_cache("forward()")
    local success, message = turtle.forward()
    if success then
        eturtle_log:writeLog("forward()")
    end
    _clear_cache()
    return success, message
end

function back()
    _write_cache("back()")
    local success, message = turtle.back()
    if success then
        eturtle_log:writeLog("back()")
    end
    _clear_cache()
    return success, message
end

function up()
    _write_cache("up()")
    local success, message = turtle.up()
    if success then
        eturtle_log:writeLog("up()")
    end
    _clear_cache()
    return success, message
end

function down()
    _write_cache("down()")
    local success, message = turtle.down()
    if success then
        eturtle_log:writeLog("down()")
    end
    _clear_cache()
    return success, message
end

function turnLeft()
    eturtle_log:writeLog("turnLeft()")
    return turtle.turnLeft()
end

function turnRight()
    eturtle_log:writeLog("turnRight()")
    return turtle.turnRight()
end

function select(...)
    return turtle.select(...)
end

function getSelectedSlot(...)
    return turtle.getSelectedSlot(...)
end

function getItemCount(...)
    return turtle.getItemCount(...)
end

function getItemSpace(...)
    return turtle.getItemSpace(...)
end

function getItemDetail(...)
    return turtle.getItemDetail(...)
end

function equipLeft(...)
    return turtle.equipLeft(...)
end

function equipRight(...)
    return turtle.equipRight(...)
end

function dig()
    return turtle.dig()
end

function digUp()
    return turtle.digUp()
end

function digDown()
    return turtle.digDown()
end

function place(...)
    return turtle.place(...)
end

function placeUp(...)
    return turtle.placeUp(...)
end

function placeDown(...)
    return turtle.placeDown(...)
end

function detect(...)
    return turtle.detect(...)
end

function detectUp(...)
    return turtle.detectUp(...)
end

function detectDown(...)
    return turtle.detectDown(...)
end

function inspect(...)
    return turtle.inspect(...)
end

function inspectUp(...)
    return turtle.inspectUp(...)
end

function inspectDown(...)
    return turtle.inspectDown(...)
end

function compare(...)
    return turtle.compare(...)
end

function compareUp(...)
    return turtle.compareUp(...)
end
function compareDown(...)
    return turtle.compareDown(...)
end

function compareTo(...)
    return turtle.compareTo(...)
end

function drop(...)
    return turtle.drop(...)
end

function dropUp(...)
    return turtle.dropUp(...)
end

function dropDown(...)
    return turtle.dropDown(...)
end

function suck(...)
    return turtle.suck(...)
end

function suckUp(...)
    return turtle.suckUp(...)
end

function suckDown(...)
    return turtle.suckDown(...)
end

function refuel(...)
    return turtle.refuel(...)
end

function getFuelLevel(...)
    return turtle.getFuelLevel(...)
end
function getFuelLimit(...)
    return turtle.getFuelLimit(...)
end

function turtle.transferTo(...)
    return turtle.transferTo(...)
end

-- // additional function //

--- drop to Non-Block Area
function dump(...)
    local retval = false
    if not detectDown() then
        retval = dropDown(...)
    end
    if not detectUp() then
        retval = dropUp(...)
    end
    if not detect() then
        retval = drop(...)
    end
    if retval then
        return retval
    end

    for i = 1, 3 do
        turnRight()
        if turtle.detect() then
            retval = drop(...)
            if retval then
                resume()
                return retval;
            end
        end
    end
    turnRight()
    
    return retval
end

RESUME_COMMAND = {}
RESUME_COMMAND["forward()"]   = turtle.back
RESUME_COMMAND["back()"]      = turtle.forward
RESUME_COMMAND["up()"]        = turtle.down
RESUME_COMMAND["down()"]      = turtle.up
RESUME_COMMAND["turnRight()"] = turtle.turnLeft
RESUME_COMMAND["turnLeft()"]  = turtle.turnRight

--- Resume
function resume(time)
    if not time then
        time = 0
    end
    while true do
        local log = eturtle_log:readLog(time)
        if not log then
            break
        end
        command = RESUME_COMMAND[log["message"]]
        if not command then
            break
        end

        local can_reduce = false
        -- optimize code --
        if (command == turtle.turnRight) or (command == turtle.turnLeft) then
            for i=2, 4 do
                local tmp_log = eturtle_log:readLog(time, i)
                if log["message"] ~= tmp_log["message"] then
                    break
                end
                if i == 4 then
                    can_reduce = true
                    eturtle_log:deleteLog()
                    eturtle_log:deleteLog()
                    eturtle_log:deleteLog()
                    eturtle_log:deleteLog()
                end
            end
        end
        -- optimize code --

        if not can_reduce then
            _write_cache("#DELETE")
            if command() then
                eturtle_log:deleteLog()
            end
            _clear_cache()
        end
    end
end

--- Clear
function clear()
    _clear_cache()
    eturtle_log:clear()
end
