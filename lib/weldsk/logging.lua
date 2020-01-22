---------------------------------------
--  Log API                          --
--    for CC:Tweaked                 --
--    Ver 1.01                       --
---------------------------------------

SLICE_CHAR = ":"

--- Log Object Constractor (new)
function new(filepath)
    local instance = _create_instance(filepath)
    instance:clear()
    return instance
end

--- Log Object Constracter (load)
function load(filepath)
    local instance = _create_instance(filepath)
    instance.data = _loadFile(filepath)
    return instance
end

function clear(filepath)
    if fs.exists(filepath) then
        fs.delete(filepath)
    end
    local file = fs.open(filepath, "w")
    file.close()
end

function _create_instance(filepath)
    local instance = {}
    instance.data = {}
    instance.filepath = filepath
    instance.writeLog = function(...)
        return _writeLog(...)
    end
    instance.readLog = function(...)
        return _readLog(...)
    end
    instance.deleteLog = function(...)
        return _deleteLog(...)
    end
    instance.clear = function(self, time)
        return clear(self.filepath)
    end
    return instance
end

function getTime()
    return os.epoch("utc")
end

--- Write Log
function _writeLog(self, message)
    -- write file
    local log_file = fs.open(self.filepath, "a")
    local timestamp = getTime();
    log_file.writeLine(timestamp .. ":" .. message)
    log_file.flush()
    log_file.close()

    -- insert data
    local log = {}
    log["time"] = timestamp
    log["message"] = message
    table.insert(self.data, log)
end

---@return time, message
function _lineToLog(log_strline)
    local first_str = string.sub(log_strline, 1, 1)
    local time, message
    if first_str == "#" then
        time = -1
        message = log_strline
    else
        local slice_pos = string.find(log_strline, SLICE_CHAR)
        if slice_pos and slice_pos > 1 and slice_pos <= #log_strline then
            time = tonumber(string.sub(log_strline, 1, slice_pos - 1))
            message = string.sub(log_strline, slice_pos+1)
        end
    end
    if not(time and message) then
        time = nil
        message = nil
    end
    return time, message
end

function _readLog(self, time, index)
    if not(time) then
        time = 0
    end
    if not(index) then
        index = #self.data
    else
        index = #self.data - (index - 1)
    end

    if (index <= 0) or #self.data < index then
        return nil
    end
    local log = self.data[index]
    if log then
        if time <= log["time"] then
            return log
        end
    end
    return nil
end

function _deleteLog(self, time)
    if #self.data <= 0 then
        return nil
    end
    if not(time) then
        time = 0
    end

    local log = self.data[#self.data]
    if time <= log["time"] then
        -- write file
        local log_file = fs.open(self.filepath, "a")
        log_file.writeLine("#DELETE")
        log_file.flush()
        log_file.close()

        -- delete data
        table.remove(self.data, #self.data)

        -- clear
        if #self.data == 0 then
            clear(self.filepath)
        end
        return log
    end
    return nil
end

function _loadFile(filepath)
    local loaded_table = {}

    if not fs.exists(filepath) then
        return loaded_table;
    end

    local log_file = fs.open(filepath, "r")
    while true do
        local log_line = log_file.readLine()
        if log_line then
            local time, message = _lineToLog(log_line)
            if time and message then
                if string.len(message) > 0 then
                    if string.sub(message, 1, 1) == "#" then
                        -- exec #COMMAND
                        if message == "#DELETE" then
                            table.remove(loaded_table, #loaded_table)
                        end
                    else
                        -- load Log
                        local log = {}
                        log["time"] = time
                        log["message"] = message
                        table.insert(loaded_table, log)
                    end
                end
            end
        else
            break
        end
    end
    log_file.close()
    return loaded_table
end
