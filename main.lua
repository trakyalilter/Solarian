-- Player and meteorites

local data = require("data")
local images = require( "images")
local viewClass = require("viewClass")

local WIDTH = 0
local HEIGHT = 0

local GameWidth = 0
local GameHeight = 0

-- Minimap settings
local MINIMAP_WIDTH = 200
local MINIMAP_HEIGHT = 200
local MINIMAP_MARGIN = 20 -- Distance from bottom-right corner

local player
local playerImageScale = 0.075
local playerX, playerY -- Initial position
local playerVX, playerVY = 0, 0   -- Velocity components
local playerSpeed = 200           -- Maximum speed
local playerAcceleration = 400    -- Acceleration rate
local playerFriction = 300        -- Deceleration rate (when no key is pressed)
local playerAngle = 0             -- Angle (in radians)
local meteorite
local ironAmount = 1
local copperAmount = 0
local meteorSize
local playerHealth = 10 -- <3 aşkıma torpil
local playerShield = 10
local iron = 0 -- Player's stored iron amount
local copper = 0 -- Player's stored copper amount
local coin = 0
local sectors = {} -- Table to store sectors
local selectedSector = "Sector-1"
local meteorites = {} -- Table to store meteorites
local spawnTimer = 0 -- Timer to control meteorite spawning
local enemyImage
local enemySpawnInterval = math.random(4,7)
local enemies = {} -- Table to store enemies
local laserImage
local lasers = {} -- Table to store lasers
local enemySpawnTimer = 0 -- Timer to control enemy spawning

local enemyLaserTimer = 0 -- Timer for enemy laser shooting
local enemyLasers = {} -- Table for storing lasers shot by enemies
local dropBoxes = {}
local dropbox
local lastDestroyedX, lastDestroyedY = -1,-1
-- Button position and size
local buttonX, buttonY = 10, 100
local buttonWidth, buttonHeight = 100, 30

MainView = viewClass.View:create({name="MainView",pageNo=1})
MapView = viewClass.View:create({name="MapView",pageNo=2})
InventoryView = viewClass.View:create({name="InventoryView",pageNo=3})
ShopView = viewClass.View:create({name="ShopView",pageNo=4})
OptionsView  = viewClass.View:create({name="OptionsView",pageNo=5})
local healthBarRed
local healthBarGreen
local shieldBar
local shieldRefillTimer
local selectedView

local inventorySlotImage

local notifications = {}

-- Function to add a notification message
local function addNotification(message, duration)
    table.insert(notifications, { text = message, timer = duration })
end
function drawMinimap()
    -- Minimap position and size
    local minimapX = WIDTH - MINIMAP_WIDTH - MINIMAP_MARGIN
    local minimapY = HEIGHT - MINIMAP_HEIGHT - MINIMAP_MARGIN

    -- Draw the minimap background
    love.graphics.setColor(0, 0, 0, 0.6) -- Black background
    love.graphics.rectangle("fill", minimapX, minimapY, MINIMAP_WIDTH, MINIMAP_HEIGHT)
    
    -- Reset color after minimap background
    love.graphics.setColor(1, 1, 1)

    -- Draw the player's position on the minimap
    love.graphics.setColor(0, 1, 0) -- Red player dot
    local playerMinimapX = minimapX + (playerX / WIDTH) * MINIMAP_WIDTH
    local playerMinimapY = minimapY + (playerY / HEIGHT) * MINIMAP_HEIGHT
    love.graphics.circle("fill", playerMinimapX, playerMinimapY, 3)
    
    -- Reset color after minimap player dot
    love.graphics.setColor(1, 1, 1)
end
local function spawnEnemy()
    enemySpawnInterval = math.random(2,8)
    local side = math.random(1, 4)
    local x, y

    if side == 1 then -- Top
        x = math.random(0, WIDTH)
        y = -50
    elseif side == 2 then -- Bottom
        x = math.random(0, WIDTH)
        y = HEIGHT+50
    elseif side == 3 then -- Left
        x = -50
        y = math.random(0, HEIGHT)
    elseif side == 4 then -- Right
        x = WIDTH+50
        y = math.random(0, HEIGHT)
    end

    -- Calculate direction towards the player
    local dx, dy = playerX - x, playerY - y
    local length = math.sqrt(dx^2 + dy^2)
    dx, dy = dx / length, dy / length

    -- Add enemy to the table
    table.insert(enemies, {
        x = x,
        y = y,
        dx = dx,
        angle = math.atan2(dy, dx)-math.pi/2,
        hp = math.random(2,5),
        dy = dy,
        speed = math.random(20,60), -- Speed of the enemy
    })
end
local function enemyShootLaser(enemy)
    table.insert(enemyLasers, {
        x = enemy.x,
        y = enemy.y,
        angle = math.atan2(playerY - enemy.y, playerX - enemy.x),
        dx = playerX - enemy.x,
        dy = playerY - enemy.y,
        speed = 400,
    })
end
-- Function to shoot a laser
local function shootLaser()
    table.insert(lasers, {
        x = playerX,
        y = playerY,
        r = ((90+playerAngle)*math.pi/180),
        dx = 0, -- Lasers travel straight up
        dy = -1,
        speed = 400,
    })
end
-- Function to save resources to a file
local function saveResources()
   data.saveResources(iron, copper)
end

local function saveSectors()
    data.saveSectors(sectors)
end
local function loadSectors()
    sectors = data.loadSectors()
end
-- Function to load resources from the file
local function loadResources()
        iron,copper = data.loadResources()
end
-- Function to spawn a meteorite outside the screen
local function spawnMeteorite()
    ironAmount = math.random(1, 3)
    copperAmount = math.random(0, 2)
    meteorSize = ironAmount+copperAmount
    local side = math.random(1, 4) -- Choose which side the meteorite spawns from
    local x, y

    if side == 1 then -- Top
        x = math.random(0, WIDTH) -- Random X within the window width
        y = -50 -- Just above the window
    elseif side == 2 then -- Bottom
        x = math.random(0, WIDTH)
        y = HEIGHT + 50 -- Just below the window
    elseif side == 3 then -- Left
        x = -50
        y = math.random(0, HEIGHT) -- Random Y within the window height
    elseif side == 4 then -- Right
        x = WIDTH + 50
        y = math.random(0, HEIGHT)
    end

    -- Calculate direction towards the player's current position
    local dx, dy = playerX - x, playerY - y
    local length = math.sqrt(dx^2 + dy^2) -- Normalize the direction vector
    dx, dy = dx / length, dy / length

    -- Add meteorite to the table
    table.insert(meteorites, {
        x = x,
        y = y,
        dx = dx,
        dy = dy,
        speed = 150/meteorSize, -- Speed of the meteorite
        size = 0.04*(meteorSize)
    })
end

function love.load()
    
    love.window.setFullscreen(true, "desktop")
    --font = love.graphics.newFont("AlphaProta.ttf",18 )
    
    
    WIDTH =love.graphics.getWidth()
    HEIGHT = love.graphics.getHeight()
    GameWidth = WIDTH*10
    GameHeight = HEIGHT*10
    playerX, playerY = WIDTH/2,HEIGHT/2
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    player = love.graphics.newImage("Images/player.png")
    meteorite = love.graphics.newImage("Images/meteorite.png")
    enemyImage = love.graphics.newImage("Images/enemy.png")
    laserImage = love.graphics.newImage("Images/laser.png")

    inventoryButtonImage = love.graphics.newImage("Images/inventorySmall.png")
    mapButtonImage = love.graphics.newImage("Images/mapButton.png")
    backButtonImage = love.graphics.newImage("Images/backButton.png")

    healthBarRed = love.graphics.newImage("Images/healthBarRed.png")
    healthBarGreen = love.graphics.newImage("Images/healthBarGreen.png")

    dropbox = love.graphics.newImage("Images/dropbox.png")
    shopButtonImage = love.graphics.newImage("Images/shopButton.png")

    shieldBar = love.graphics.newImage("Images/shieldBar.png")
    inventorySlotImage = images.inventorySlotImage
    loadSectors()
    meteorSize = ironAmount+copperAmount
    loadResources()
    loadSectors()
    
    selectedView = MainView

end
function love.keypressed(key, unicode)
    if key == "i" then
        if selectedView == InventoryView then
            selectedView = MainView
        else
            selectedView = InventoryView
        end
    end
    if key == "m" then
        if selectedView == MapView then
            selectedView = MainView
        else
            selectedView = MapView
        end
    end
    if key == "m" then
        return
    end
end
function love.update(dt)
    if selectedView == MainView then
        if playerShield < 10 then
            shieldRefillTimer = shieldRefillTimer + dt
            if shieldRefillTimer >= 3 then
                playerShield = playerShield + 1
                shieldRefillTimer = 0
            end
        end
        local inputX, inputY = 0, 0 -- Input direction
        -- Handle input for acceleration
        if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
            inputY = inputY - 1
        end
        if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
            inputY = inputY + 1
        end
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            inputX = inputX - 1
        end
        if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            inputX = inputX + 1
        end
        --Notification
        for i = #notifications, 1, -1 do
            local n = notifications[i]
            n.timer = n.timer - dt
            if n.timer <= 0 then
                table.remove(notifications, i)
            end
        end
        -- Normalize input direction (avoid faster diagonal movement)
        local length = math.sqrt(inputX^2 + inputY^2)
        if length > 0 then
            inputX, inputY = inputX / length, inputY / length
        end
        -- Update velocity based on input and acceleration
        playerVX = playerVX + inputX * playerAcceleration * dt
        playerVY = playerVY + inputY * playerAcceleration * dt

        -- Apply friction when no input is given
        if inputX == 0 then
            if playerVX > 0 then
                playerVX = math.max(0, playerVX - playerFriction * dt)
            elseif playerVX < 0 then
                playerVX = math.min(0, playerVX + playerFriction * dt)
            end
        end
        if inputY == 0 then
            if playerVY > 0 then
                playerVY = math.max(0, playerVY - playerFriction * dt)
            elseif playerVY < 0 then
                playerVY = math.min(0, playerVY + playerFriction * dt)
            end
        end

        -- Cap velocity to the maximum speed
        local velocityLength = math.sqrt(playerVX^2 + playerVY^2)
        if velocityLength > playerSpeed then
            playerVX = playerVX / velocityLength * playerSpeed
            playerVY = playerVY / velocityLength * playerSpeed
        end

        -- Update player position
        playerX = playerX + playerVX * dt
        playerY = playerY + playerVY * dt

        -- Update player angle based on velocity direction
        if velocityLength > 0 then
            playerAngle = math.atan2(playerVY, playerVX)*180/math.pi -- Angle in radians
        end
    

        -- Spawn meteorites at intervals
        spawnTimer = spawnTimer + dt
        if spawnTimer >= 4 then
            spawnMeteorite()
            spawnTimer = 0
        end

        -- Spawn enemies at intervals
        enemySpawnTimer = enemySpawnTimer + dt
        if enemySpawnTimer >= enemySpawnInterval then
            spawnEnemy()
            enemySpawnTimer = 0
        end

        -- Update meteorites
        for i = #meteorites, 1, -1 do
            local m = meteorites[i]
            m.x = m.x + m.dx * m.speed * dt
            m.y = m.y + m.dy * m.speed * dt

            -- Check collision with player
            local playerWidth, playerHeight = player:getWidth() * playerImageScale, player:getHeight() * playerImageScale
            local meteoriteWidth, meteoriteHeight = meteorite:getWidth() * 0.1, meteorite:getHeight() * 0.1

            if m.x < playerX + playerWidth / 2 and
               m.x + meteoriteWidth > playerX - playerWidth / 2 and
               m.y < playerY + playerHeight / 2 and
               m.y + meteoriteHeight > playerY - playerHeight / 2 then
                table.remove(meteorites, i)

                iron = iron + ironAmount
                copper =copper + copperAmount
                -- Add notifications for collected resources
                if ironAmount > 0 then
                    addNotification("+" .. ironAmount .. " Iron", 2) -- Show for 2 seconds
                end
                if copperAmount > 0 then
                    addNotification("+" .. copperAmount .. " Copper", 2)
                end
            end
        end
        
        
        -- Update dropBoxes
        
        for i = #dropBoxes, 1, -1 do
            local d = dropBoxes[i]
            

            -- Check collision with player
            local playerWidth, playerHeight = player:getWidth() * playerImageScale, player:getHeight() * playerImageScale
            local dropboxWidth, dropboxHeight = dropbox:getWidth() * 0.05, dropbox:getHeight() * 0.05
            local str =d.x .. d.y
            
            if d.x < playerX + playerWidth / 2 and
                d.x + dropboxWidth > playerX - playerWidth / 2 and
                d.y < playerY + playerHeight / 2 and
                d.y + dropboxHeight > playerY - playerHeight / 2 then
                table.remove(dropBoxes, i)
                coin = coin + math.random(1,5)
                --coin will be added!
            end
        end
        
        -- Update enemies
        for i = #enemies, 1, -1 do
            local e = enemies[i]

            -- Recalculate the direction towards the player
            local dx, dy = playerX - e.x, playerY - e.y
            local length = math.sqrt(dx^2 + dy^2)
            dx, dy = dx / length, dy / length

            -- Update the enemy's direction and angle
            e.dx = dx
            e.dy = dy
            e.angle = math.atan2(dy, dx) - math.pi / 2

            -- Move the enemy towards the player
            e.x = e.x + e.dx * e.speed * dt
            e.y = e.y + e.dy * e.speed * dt

            -- Check collision with the player
            local playerWidth, playerHeight = player:getWidth() * playerImageScale, player:getHeight() * playerImageScale
            local enemyWidth, enemyHeight = enemyImage:getWidth() * 0.1, enemyImage:getHeight() * 0.1

            if e.x < playerX + playerWidth / 2 and
            e.x + enemyWidth > playerX - playerWidth / 2 and
            e.y < playerY + playerHeight / 2 and
            e.y + enemyHeight > playerY - playerHeight / 2 then
                playerHealth = playerHealth-10
				if playerHealth < 1 then
					love.event.quit()
				end
            end
        end

        enemyLaserTimer = enemyLaserTimer + dt
        if enemyLaserTimer >= 1.5 then
            for _, enemy in ipairs(enemies) do
                enemyShootLaser(enemy)
            end
            enemyLaserTimer = 0
        end

        -- Update enemy lasers
        for i = #enemyLasers, 1, -1 do
            local laser = enemyLasers[i]
            local length = math.sqrt(laser.dx^2 + laser.dy^2)
            laser.dx, laser.dy = laser.dx / length, laser.dy / length

            -- Move laser
            laser.x = laser.x + laser.dx * laser.speed * dt
            laser.y = laser.y + laser.dy * laser.speed * dt

            -- Check collision with player
            local laserWidth, laserHeight = laserImage:getWidth() * 0.03, laserImage:getHeight() * 0.03
            local playerWidth, playerHeight = player:getWidth() * playerImageScale, player:getHeight() * playerImageScale

            if laser.x < playerX + playerWidth / 2 and
            laser.x + laserWidth > playerX - playerWidth / 2 and
            laser.y < playerY + playerHeight / 2 and
            laser.y + laserHeight > playerY - playerHeight / 2 then
                table.remove(enemyLasers, i)
                shieldRefillTimer = 0
                if playerShield >0 then
                    playerShield = playerShield-1
                else
                    playerHealth = playerHealth - 1
                end
                if playerHealth < 1 then
                    love.event.quit() -- Close the game
                end
            end

            -- Remove lasers that are off-screen
            if laser.x < 0 or laser.x > WIDTH or laser.y < 0 or laser.y > HEIGHT then
                table.remove(enemyLasers, i)
            end
        end


        -- Update lasers
        for i = #lasers, 1, -1 do
            local laser = lasers[i]
            laser.x = laser.x + laser.dx * laser.speed * dt
            laser.y = laser.y + laser.dy * laser.speed * dt
        
            -- Remove laser if it goes off-screen
            if laser.x < 0 or laser.x > WIDTH or laser.y < 0 or laser.y > HEIGHT then
                table.remove(lasers, i)
            else
                -- Check collision with enemies
                local laserWidth, laserHeight = laserImage:getWidth() * 0.1, laserImage:getHeight() * 0.1
                for j = #enemies, 1, -1 do
                    local e = enemies[j]
                    local enemyWidth, enemyHeight = enemyImage:getWidth() * 0.1, enemyImage:getHeight() * 0.1
        
                    if laser.x < e.x + enemyWidth / 2 and
                       laser.x + laserWidth > e.x - enemyWidth / 2 and
                       laser.y < e.y + enemyHeight / 2 and
                       laser.y + laserHeight > e.y - enemyHeight / 2 then
                        e.hp = e.hp - 1
                        table.remove(lasers, i)  -- Remove laser immediately after hitting an enemy
                        if e.hp < 1 then
                            lastDestroyedX, lastDestroyedY = e.x,e.y
                            table.remove(enemies, j)  -- Remove enemy if HP is depleted
                            -- if math.random(0,100) > 50 then
                            --     love.graphics.draw(dropbox,e.x,e.y,0,0.01,0.01)
                            -- end
                        end
                        break  -- Stop checking other enemies for this laser
                    end
                end
            end
        end
    end
end
function love.draw()
    -- love.graphics.setFont(font)
    if selectedView == MapView then

    -- Draw Map View
    --font = love.graphics.newFont("AlphaProta.ttf",10 )
    love.graphics.print(selectedSector, 10, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Map View", 10, 10)

    local gridX, gridY = 200, 100 -- Top-left corner of the grid
    local cellSize = 100 -- Size of each cell
    local sectorNumber = 1

    -- Draw the 2x2 grid
    for row = 0, 1 do
        for col = 0, 1 do
            local x = gridX + col * cellSize
            local y = gridY + row * cellSize

            love.graphics.rectangle("line", x, y, cellSize, cellSize)
            local sector = sectors[sectorNumber]

            if sector.available then
                -- If the sector is available, display its name and resources
                love.graphics.print(sector.name, x + 10, y + 10)
                love.graphics.print("Iron: " .. sector.iron, x + 10, y + 30)
                love.graphics.print("Copper: " .. sector.copper, x + 10, y + 50)
            elseif sectorNumber == 2 and iron >= 50 and copper >= 50 then
                -- Sector-2 is ready to be unlocked (enough resources collected)
                love.graphics.setFont(love.graphics.newFont(12))
                love.graphics.print("Unlock?", x + 20, y + 40)
            else
                -- If the sector is unavailable, draw a big question mark
                love.graphics.setFont(love.graphics.newFont(32))
                love.graphics.print("?", x + cellSize / 2 - 10, y + cellSize / 2 - 16)
                love.graphics.setFont(love.graphics.newFont(12))
            end

            sectorNumber = sectorNumber + 1
        end
    end
    elseif selectedView == InventoryView then
        drawInventory()
    elseif selectedView == ShopView then
        -- Draw Shop View
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Shop", 10, 10)
    elseif selectedView == MainView then
        -- Draw notifications at the top-center of the screen
        local screenWidth = love.graphics.getWidth()
        for i, n in ipairs(notifications) do
            love.graphics.setColor(10/255, 145/255, 46/255) -- White color
            love.graphics.print(n.text, screenWidth / 2 - 50, 50 + (i - 1) * 20)
        end

        love.graphics.setColor(1, 1, 1) -- Reset color
        -- Draw Game View
        -- Draw player
        love.graphics.draw(player, playerX, playerY, ((90+playerAngle)*math.pi/180), playerImageScale, playerImageScale, player:getWidth() / 2, player:getHeight() / 2)
        for i=1,playerHealth do
            love.graphics.draw(healthBarGreen,(playerX-40)+(8*(i-1)),playerY-65,0,0.05,0.3)

        end
        for i=1,playerShield do
        love.graphics.draw(shieldBar,(playerX-40)+(8*(i-1)),playerY-75,0,0.05,0.3)
        end
        -- Draw meteorites
        for _, m in ipairs(meteorites) do
            love.graphics.draw(meteorite, m.x, m.y, 0, m.size, m.size, meteorite:getWidth() / 2, meteorite:getHeight() / 2)
        end
        -- Draw enemies
        for _, e in ipairs(enemies) do
            local value = 15
            for i=1,e.hp do
                love.graphics.draw(healthBarRed,(e.x+(value*(i-1))-25),e.y-45,0,0.1,0.3)
            end
            
            -- love.graphics.draw(healthBarRed,e.x,e.y-45,0,0.1,0.3)
            -- love.graphics.draw(healthBarRed,e.x-15,e.y-45,0,0.1,0.3)
            -- love.graphics.draw(healthBarRed,e.x-30,e.y-45,0,0.1,0.3)

            love.graphics.draw(enemyImage, e.x, e.y, e.angle, 0.1, 0.1, enemyImage:getWidth() / 2, enemyImage:getHeight() / 2)
        end
        -- Draw lasers
        for _, laser in ipairs(lasers) do
            love.graphics.draw(laserImage, laser.x, laser.y,laser.angle, 0.05, 0.05, laserImage:getWidth() / 2, laserImage:getHeight() / 2)
        end
        -- Draw enemy lasers
        for _, laser in ipairs(enemyLasers) do
            love.graphics.draw(laserImage, laser.x, laser.y, laser.angle, 0.05, 0.05, laserImage:getWidth() / 2, laserImage:getHeight() / 2)
        end
        love.graphics.print("Coin: " .. coin, 10, 40)

        --Draw dropbox
        if lastDestroyedX>0 and lastDestroyedY>0 and math.random(0,100) > 50 then

            table.insert(dropBoxes, {
                x = lastDestroyedX,
                y = lastDestroyedY
            })
            
            
            lastDestroyedX = -1
            lastDestroyedY = -1
            
        end
        for _, dropBox in ipairs(dropBoxes) do
            love.graphics.draw(dropbox,dropBox.x,dropBox.y,0,0.05,0.05,dropbox:getWidth()/2,dropbox:getHeight()/2)
        end
        drawMinimap()

        
    end

end
function drawInventory()
    -- Inventory background
    love.graphics.draw(images.inventoryBackgroundImage, 10, 10, 0, 1, 1)

    -- Inventory grid settings
    local slotWidth = 200    -- Slot width (reduce to fit 8 columns)
    local slotHeight = 200   -- Slot height
    local offsetX = 10      -- Horizontal spacing between slots
    local offsetY = 10      -- Vertical spacing between slots
    local gridStartX = 125   -- Starting X position of grid
    local gridStartY = 125   -- Starting Y position of grid
    local columns = 8       -- Number of columns
    local rows = 4          -- Number of rows

    -- Inventory items
    local items = {
        { name = "Iron", amount = iron,image = images.ironIngotImage },
        { name = "Copper", amount = copper,image = images.copperIngotImage },
        -- Add more items here dynamically if needed
    }

    -- Draw the inventory grid
    local index = 0
    for i = 1, rows do
        for j = 1, columns do
            index = index + 1
            local x = gridStartX + (j - 1) * (slotWidth + offsetX)
            local y = gridStartY + (i - 1) * (slotHeight + offsetY)
            
            -- Draw the inventory slot
            love.graphics.draw(images.inventorySlotImage, x, y, 0, 1, 1)

            -- Draw item if available
            local item = items[index]
            if item then
                -- Draw the item's name and quantity
                love.graphics.print(item.name, x + 5, y + 5)
                love.graphics.print("x" .. tostring(item.amount), x + 5, y + 25)
                love.graphics.draw(item.image,x+100,y+125,0,0.1,0.1,item.image:getWidth()/2,item.image:getHeight()/2)
            end
        end
    end
end
function love.mousepressed(x, y, button)

    if button == 1 then -- Left mouse button
        if MainView then
            -- Calculate angle and direction for the laser
            local angle = math.atan2(y - playerY, x - playerX)
            local dx = math.cos(angle)
            local dy = math.sin(angle)
            local laser_angle = angle
            -- Add a new laser to the lasers table
            table.insert(lasers, {
                x = playerX,
                y = playerY,
                r = laser_angle,
                dx = dx,
                dy = dy,
                angle = angle,
                speed = 500, -- Speed of the laser
            })
        end
        -- Check if clicking on a sector in the Map View
        if MapView then
            local gridX, gridY = 200, 100 -- Top-left corner of the grid
            local cellSize = 100 -- Size of each cell

            for row = 0, 1 do
                for col = 0, 1 do
                    local xSector = gridX + col * cellSize
                    local ySector = gridY + row * cellSize

                    -- Check if the player clicked within a sector
                    if x > xSector and x < xSector + cellSize and y > ySector and y < ySector + cellSize then
                        local sectorIndex = row * 2 + col + 1
                        local sector = sectors[sectorIndex]

                        -- Unlock Sector-2 if resources are sufficient
                        if sectorIndex == 2 and iron >= 50 and copper >= 50 and not sector.available then
                            sector.available = true
                            iron = iron - 50
                            copper = copper - 50
                            print("Sector-2 unlocked!")
                        end
                    end
                end
            end
        end
    end
end
function isMouseInside(object)
    if love.mouse.getX() > buttonX and love.mouse.getX() < buttonX + object:getWidth() and love.mouse.getY() > 175 and love.mouse.getY() < 175 + object:getHeight() then
        return true
    else
        return false
    end
end
-- function love.mousemoved()
--     if isMouseInside(shopButtonImage) then
--         cursor = love.mouse.getSystemCursor("hand")
--         love.mouse.setCursor(cursor)
--     elseif isMouseInside(inventoryButtonImage) then
--     else
--         cursor = love.mouse.getSystemCursor("arrow")
--         love.mouse.setCursor(cursor)
--     end
-- end
function love.quit()
    -- Save resources before quitting
    saveResources()
    saveSectors(sectors)
end
