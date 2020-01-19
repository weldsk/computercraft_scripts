----------------------
--      mining      --
----------------------

---- load libs ----
os.loadAPI("/lib/weldsk/eturtle")
os.loadAPI("/lib/weldsk/logging")

---- config ----
ITEM_COBBLESTONE = "minecraft:cobblestone"
ITEM_TORCH = "minecraft:torch"
TURTLE_SLOT_SIZE = 16
TURTLE_FUEL_SLOT = -1   -- -1: not use
TURTLE_FUEL_MIN =  30
TURTLE_NEED_EMPTY_SLOT_MIN = 3
RETRY_TIMES = 20
AUTODUMP_LIST =
{
    "minecraft:cobblestone",
    "minecraft:dirt"
}
STORAGE_LIST =
{
    "chest",
}
FLUID_LIST =
{
    "water",
    "lava"
}
AUTODUMP_MIN = 32
AUTODUMP_NUM = 8
BLOCK_BLACKLIST =
{
    "chest",
    "turtle",
    "builder",
    "quarry",
    "furnace",
    "controller",
    "spawn"
}

FUEL_LIST =
{
    "minecraft:coal"
}

RESOURCE_BLOCK_LIST =
{
    "ore",
    "Ore"
}

---- static ----
TURTLE_INIT_SLOT = 1
TORCH_RANGE = 13

---- code ----
local args = {...}

--! @brief      is block on RESROUCE_BLOCK_LIST
--! @return     slotNumber
--!     nil     failed(not found)
function isResourceBlock(block)
    for i=1, #RESOURCE_BLOCK_LIST do
        if string.match(block.name, RESOURCE_BLOCK_LIST[i]) ~= nil then
            return true
        end
    end

    return false
end

--! @brief checkBlackListBlock
function isBlackListBlock(block)
    for i=1, #BLOCK_BLACKLIST do
        if string.match(block.name, BLOCK_BLACKLIST[i]) ~= nil then
            return true
        end
    end

    return false
end

function countEmptySlot()
    local count = 0
    for i=1, TURTLE_SLOT_SIZE do
        item = turtle.getItemDetail(i)
        if item == nil then
            count = count + 1;
        end
    end
    return count
end

--! @brief      find item_name slot
--! @return     slotNumber
--!     nil     failed(not found)
function findItem(item_name)
    local item
    for i=1, TURTLE_SLOT_SIZE do
        item = turtle.getItemDetail(i)
        if item ~= nil then
            if string.match(item.name, item_name) ~= nil then
                return i
            end
        end
    end
    return nil
end

--! @brief      count Item
--! @return     item num
--!     0       not found
function countItem(item_name)
    local item, item_num
    item_num = 0
    for i=1, TURTLE_SLOT_SIZE do
        item = turtle.getItemDetail(i)
        if item ~= nil then
            if string.match(item.name, item_name) ~= nil then
                item_num = item_num + turtle.getItemCount(i)
            end
        end
    end
    return item_num
end

--! @brief          refuel
--! @return         bool
--!     true        refueled
--!     false       not found fuel
function autoRefuel()
    local item;
    -- use TURTLE_FUEL_SLOT
    if TURTLE_FUEL_SLOT > 0 then
        turtle.select(TURTLE_FUEL_SLOT)
        if turtle.getFuelLevel() > TURTLE_FUEL_MIN then
            if turtle.refuel(1) then
                return true
            end
        end
    end

    -- find FUEL_LIST
    for i=1, #FUEL_LIST do
        for j=1, TURTLE_SLOT_SIZE do
            item = turtle.getItemDetail(i)
            if item ~= nil then
                if string.match(item.name, FUEL_LIST[i]) ~= nil then
                    turtle.select(j)
                    if turtle.refuel(1) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function autoDump()
    local item_num, slot_num;
    for i=1, #AUTODUMP_LIST do
        item_num = countItem(AUTODUMP_LIST[i])
        if item_num >= AUTODUMP_MIN then
            for j=1, (item_num - AUTODUMP_MIN) % AUTODUMP_NUM do
                slot_num = findItem(AUTODUMP_LIST[i])
                if slot_num ~= nil then
                    turtle.select(slot_num)
                    eturtle.dump(AUTODUMP_NUM)
                end
            end
        end
    end
end

--! @brief      mining (forward)
--!             dig for mining
--! @return     bool
--!     true    dig or non-block(air)
--!     false   detectBlackListBlock (ERROR)
function mining()
    local is_success, block 
    is_success, block = turtle.inspect()

    -- detect block
    if is_success then
        -- check BlackListBlock
        autoDump()
        if isBlackListBlock(block) then
            -- detectBlackListBlock
            error("detect blacklist block(" .. block.name .. ")")
            return false
        end

        turtle.select(TURTLE_INIT_SLOT)
        if not(turtle.dig()) then
            -- unbreakable block
            --  (include fluid)
            -- error("unbreakable block(" .. block.name .. ")")
            -- return false
        end
    end

    return true
end 

--! @brief      mining (up)
--!             digUp for mining
--! @return     bool
--!     true    dig or non-block(air)
--!     false   detectBlackListBlock (ERROR)
function miningUp()
    local is_success, block 
    is_success, block = turtle.inspectUp()

    -- detect block
    if is_success then
        -- check BlackListBlock
        if isBlackListBlock(block) then
            -- detectBlackListBlock
            error("detect blacklist block(" .. block.name .. ")")
            return false
        end

        turtle.select(TURTLE_INIT_SLOT)
        if not(turtle.digUp()) then
            -- unbreakable block
            --  (include fluid)
            -- error("unbreakable block(" .. block.name .. ")")
            -- return false
        end
    end

    return true
end 

--! @brief      mining (down)
--!             digDown for mining
--! @return     bool
--!     true    dig or non-block(air)
--!     false   detectBlackListBlock (ERROR)
function miningDown()
    local is_success, block 
    is_success, block = turtle.inspectDown()

    -- detect block
    if is_success then
        -- check BlackListBlock
        if isBlackListBlock(block) then
            -- detectBlackListBlock
            error("detect blacklist block(" .. block.name .. ")")
            return false
        end

        turtle.select(TURTLE_INIT_SLOT)
        if not(turtle.digDown()) then
            -- unbreakable block
            --  (include fluid)
            -- error("unbreakable block(" .. block.name .. ")")
            -- return false
        end
    end

    return true
end

-- force move
function tryMoveForward(retry_times)
    -- args check
    if retry_times == nil then
        retry_times = -1
    end

    -- try move
    local i
    while true do
        if i >= retry_times then
            return false
        end
        -- mining
        if not(mining()) then
            return false
        end

        -- try move
        if eturtle.forward() then
            return true
        end

        -- attack
        turtle.attack()
        
        i = i + 1
    end

    error('Can\'t move! blocked by enemy or no fuel.')
    return false
end

function tryMoveUp(retry_times)
    -- args check
    if retry_times == nil then
        retry_times = -1
    end

    -- try move
    local i
    while true do
        if i >= retry_times then
            return false
        end
        -- mining
        if not(miningUp()) then
            return false
        end

        -- try move
        if eturtle.Up() then
            return true
        end

        -- attack
        turtle.attackUp()
        
        i = i + 1
    end

    error('Can\'t move! blocked by enemy or no fuel.')
    return false
end

function tryMoveDown(retry_times)
    -- args check
    if retry_times == nil then
        retry_times = -1
    end

    -- try move
    local i
    while true do
        if i >= retry_times then
            return false
        end
        -- mining
        if not(miningDown()) then
            return false
        end

        -- try move
        if eturtle.Down() then
            return true
        end

        -- attack
        turtle.attackDown()
        
        i = i + 1
    end

    error('Can\'t move! blocked by enemy or no fuel.')
    return false
end

--! @brief      digVein
function digVein()
    local is_success, block, time
    is_success, block = turtle.inspectUp()
    if is_success then
        if isResourceBlock(block) and not(isBlackListBlock(block)) then
            time = logging.getTime()
            if (tryMoveUp()) then
                digVein()
            end
            eturtle.resume(time)
        end
    end
    is_success, block = turtle.inspectDown()
    if is_success then
        if isResourceBlock(block) and not(isBlackListBlock(block)) then
            time = logging.getTime()
            if (tryMoveDown()) then
                digVein()
            end
            eturtle.resume(time)
        end
    end
    for i=1, 4 do
        is_success, block = turtle.inspect()
        if is_success then
            if isResourceBlock(block) and not(isBlackListBlock(block)) then
                time = logging.getTime()
                if (tryMoveForward()) then
                    digVein()
                end
                eturtle.resume(time)
            end
        end
        eturtle.turnRight()
    end
end

function createRoad()
    -- select cobblestone
    local slot_num = findItem(ITEM_COBBLESTONE)
    if slot_num ~= nil then
        turtle.select(slot_num)
        if turtle.placeDown() then
            return true
        end
    end

    return false
end

function placeTorch()
    local slot_num = findItem(ITEM_TORCH)
    if slot_num ~= nil then
        turtle.select(slot_num)
        turtle.placeDown()
    end
end

function miningFlow(range)
    for i = 1, range do
        autoDump()
        autoRefuel()
        if countEmptySlot() < TURTLE_NEED_EMPTY_SLOT_MIN then
            return false, i - 1, "NEED_EMPTY_SLOT"
        end
        tryMoveForward()

        for j = 1, RETRY_TIMES do
            if not(turtle.detectUp()) then
                break;
            end
            if not(miningUp()) then
                return false, i
            end
        end

        digVein()

        createRoad()
    end

    return true
end

function torchFlow(range)
    if not(tryMoveUp()) then
        return false
    end

    placeTorch()

    for i = 1, range do
        autoDump()
        autoRefuel()


        if i % TORCH_RANGE == 0 then
            placeTorch()
        end
        if not(tryMoveForward()) then
            return false, i - 1
        end

        digVein()

        if countEmptySlot() < TURTLE_NEED_EMPTY_SLOT_MIN then
            return false, i, "NEED_EMPTY_SLOT"
        end
    end

    if not(tryMoveDown()) then
        return false, range, "STOP"
    end

    return true
end

function storeStorage()
    local item
    local is_success, block
    local is_storage = false

    is_success, block = turtle.inspect()
    if is_success then
        for i=1, #STORAGE_LIST do
            if string.match(block.name, RESOURCE_BLOCK_LIST[i]) ~= nil then
                is_storage = true
                break
            end
        end
    end
    if not is_storage then
        return false
    end
    for i=1, TURTLE_SLOT_SIZE do
        item = turtle.getItemDetail(i)
        if item ~= nil then
            if string.match(item.name, ITEM_COBBLESTONE) == nil then
                if string.match(item.name, ITEM_TORCH) == nil then
                    if i ~= TURTLE_FUEL_SLOT then
                        turtle.drop()
                    end
                end
            end
        end
    end
    return true
end

-- main
function main()
    local range = args[1]
    local is_success = false -- success or fail
    local progress = 0       -- Flow Progress: (progress / range)
    local message  = nil     -- reason it failed

    -- init
    eturtle.clear()

    -- Mining Flow (Create 2x1 tunnel)
    while true do
        is_success, progress, message = miningFlow(range)
        if is_success == true then
            break
        end

        -- resume
        eturtle.resume()
        
        -- look back
        eturtle.turnRight()
        eturtle.turnRight()

        -- wait for empty inventory
        storeStorage()

        -- look forward
        eturtle.turnRight()
        eturtle.turnRight()
    end

    eturtle.turnRight()
    eturtle.turnRight()

    -- torchFlow
    local is_success = false -- success or fail
    local progress = 0       -- Flow Progress: (progress / range)
    local message  = nil     -- reason it failed
    while true do
        is_success, num, message = torchFlow(range)
        if is_success == true then
            break
        end

        -- resume
        eturtle.resume()
        
        -- look back
        eturtle.turnRight()
        eturtle.turnRight()

        -- wait for empty inventory
        storeStorage()

        -- look forward
        eturtle.turnRight()
        eturtle.turnRight()
        
        -- goto torchFlow StartPoint (= miningFlowEndPoint)
        for i = 1, range do
            autoDump()
            autoRefuel()
            tryMoveForward()
        end

        eturtle.turnRight()
        eturtle.turnRight()
    end
    storeStorage()
    eturtle.clear()
end

main()
