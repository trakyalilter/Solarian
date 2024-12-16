local json = require("json")

local data = {}

-- Save file
local resourcesSaveFile = "resources.json"
local sectorsSaveFile = "sectors.json"
-- Save resources function
function data.saveResources(iron, copper,coin,gold)
    -- Convert the data table to JSON
    local jsonData = json.encode({
        iron = iron,
        copper = copper,
        coin = coin,
        gold = gold
    })

    -- Write the JSON data to a file
    love.filesystem.write(resourcesSaveFile, jsonData)
    print("Resources saved!")
end

function data.saveSectors(sectors)
    -- Convert the data table to JSON
    local jsonData = json.encode(sectors)

    -- Write the JSON data to a file
    love.filesystem.write(sectorsSaveFile, jsonData)
    print("Sectors saved!")
end
-- Load resources function
function data.loadResources()
    local iron, copper, coin,gold = 0, 0,0,0  -- Default values
    
    -- Check if the file exists
    if love.filesystem.getInfo(resourcesSaveFile) then
        -- Read the file content
        local fileData = love.filesystem.read(resourcesSaveFile)

        -- Decode the JSON data back into a table
        local loadedData = json.decode(fileData)

        -- If decoding was successful, set the values
        if loadedData then
            iron = loadedData.iron or 0
            copper = loadedData.copper or 0
            coin = loadedData.coin or 0
            gold = loadedData.gold or 0
            print("Resources loaded!")
        else
            print("Failed to load resources!")
        end
    else
        print("No save file found!")
    end

    return iron, copper,coin,gold
end

function  data.loadSectors()
    local sectors = {
        {name = "Sector-1", iron = "Poor", copper = "Poor",available=true},
        {name = "Sector-2", iron = "Rich", copper = "Poor",available=false},
        {name = "Sector-3", iron = "Poor", copper = "Rich",available=false},
        {name = "Sector-4", iron = "Rich", copper = "Rich",available=false},
    }

    -- Check if the file exists
    if love.filesystem.getInfo(sectorsSaveFile) then
        -- Read the file content
        local fileData = love.filesystem.read(sectorsSaveFile)

        -- Decode the JSON data back into a tablew
        local loadedData = json.decode(fileData)

        -- If decoding was successful, set the values
        if loadedData then
            sectors = loadedData
            print("Sectors loaded!")
        else
            print("Failed to load sectors!")
        end
    else
        print("No save file found!")
    end

    return sectors
end

return data  -- Return the module
