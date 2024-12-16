-- Player and meteorites

local data = require("data")
local images = require( "images")
local viewClass = require("viewClass")

local WIDTH = 0
local HEIGHT = 0
local cameraX, cameraY = 0, 0
local worldWidth = 0
local worldHeight = 0

-- Minimap settings
local MINIMAP_WIDTH = 200
local MINIMAP_HEIGHT = 200
local MINIMAP_MARGIN = 20 -- Distance from bottom-right corner

local player
local spaceCraft
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
local playerHealth = 10
local playerShield = 10
local iron = 0 -- Player's stored iron amount
local copper = 0 -- Player's stored copper amount
local coin = 0
local gold = 0
local sectors = {} -- Table to store sectors
local selectedSector = "Sector:1-1"
local meteorites = {} -- Table to store meteorites
local goldMeteorites = {}
local spawnTimer = 0 -- Timer to control meteorite spawning
local enemyImage
local enemySpawnInterval = math.random(4,7)
local enemies = {} -- Table to store enemies
local laserImage
local lasers = {} -- Table to store lasers
local collectorLasers = {} -- Table to store collector Lasers
local enemySpawnTimer = 0 -- Timer to control enemy spawning

local enemyLaserTimer = 0 -- Timer for enemy laser shooting
local enemyLasers = {}
local laserCooldown = 1 -- Time between laser shots for enemies
local laserTimer = 0
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


local baseZoneX,baseZoneY = 0,0
-- Function to add a notification message
local function addNotification(message, duration)
    table.insert(notifications, { text = message, timer = duration })
end
function drawMinimap()
    -- Minimap position and size
    local minimapX = WIDTH - MINIMAP_WIDTH - MINIMAP_MARGIN
    local minimapY = HEIGHT - MINIMAP_HEIGHT - MINIMAP_MARGIN
    
    love.graphics.print(selectedSector, minimapX,minimapY-20)
    love.graphics.print("(" .. math.floor(spaceCraft.x) .. ", " .. math.floor(spaceCraft.y) .. ")", minimapX+MINIMAP_WIDTH-75, minimapY-20)
    -- Draw the minimap background
    love.graphics.setColor(0, 0, 0, 0.6) -- Black background
    love.graphics.rectangle("fill", minimapX, minimapY, MINIMAP_WIDTH, MINIMAP_HEIGHT)
    
    -- Reset color after minimap background
    love.graphics.setColor(1, 1, 1)

    -- Draw the player's position on the minimap
    love.graphics.setColor(0, 1, 0) -- Green player dot
    local playerMinimapX = minimapX + (spaceCraft.x / worldWidth) * MINIMAP_WIDTH
    local playerMinimapY = minimapY + (spaceCraft.y / worldHeight) * MINIMAP_HEIGHT
    love.graphics.circle("fill", playerMinimapX, playerMinimapY, 3)
    love.graphics.setColor(186/255, 171/255, 60/255) -- Green player dot
    for i,goldMeteorite in ipairs(goldMeteorites) do
        local goldMeteoriteMinimapX = minimapX + (goldMeteorite.x / worldWidth) * MINIMAP_WIDTH
        local goldMeteoriteMinimapY = minimapY + (goldMeteorite.y / worldHeight) * MINIMAP_HEIGHT
        love.graphics.circle("fill", goldMeteoriteMinimapX, goldMeteoriteMinimapY, 2)
    end
    love.graphics.setColor(1, 0, 0) -- Red Enemy dot
    for i, enemy in ipairs(enemies) do
        local enemyMinimapX = minimapX + (enemy.x / worldWidth) * MINIMAP_WIDTH
        local enemyMinimapY = minimapY + (enemy.y / worldHeight) * MINIMAP_HEIGHT
        love.graphics.circle("fill", enemyMinimapX, enemyMinimapY, 2)
    end
    -- Reset color after minimap player dot
    love.graphics.setColor(1, 1, 1)
    local baseMinimapX = minimapX +((baseZoneX/2)/worldWidth) * MINIMAP_WIDTH
    local baseMinimapY = minimapY +((baseZoneY/2)/worldHeight) * MINIMAP_HEIGHT
    local scale = 0.02
    local offsetX = images.spacePortImage:getWidth() * scale / 2
    local offsetY = images.spacePortImage:getHeight() * scale / 2

    love.graphics.draw(
        images.spacePortImage,
        baseMinimapX,
        baseMinimapY,
        0,               -- Rotation
        scale,           -- Scale X
        scale,           -- Scale Y
        offsetX,         -- Corrected Origin X (half width after scaling)
        offsetY          -- Corrected Origin Y (half height after scaling)
    )

    local baseMinimapXP = minimapX +((worldWidth-1000)/worldWidth) * MINIMAP_WIDTH
    local baseMinimapYP = minimapY +((worldHeight-1000)/worldHeight) * MINIMAP_HEIGHT
    local scalePortal = 0.02
    local offsetXP = images.portalImage:getWidth() * scale / 2
    local offsetYP = images.portalImage:getHeight() * scale / 2

    love.graphics.draw(
        images.portalImage,
        baseMinimapXP,
        baseMinimapYP,
        0,               -- Rotation
        scalePortal,           -- Scale X
        scalePortal,           -- Scale Y
        offsetXP,         -- Corrected Origin X (half width after scaling)
        offsetUP          -- Corrected Origin Y (half height after scaling)
    )
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
-- Function to save resources to a file
local function saveResources()
   data.saveResources(iron,copper,coin,gold)
end

local function saveSectors()
    data.saveSectors(sectors)
end
local function loadSectors()
    sectors = data.loadSectors()
end
-- Function to load resources from the file
local function loadResources()
        iron,copper,coin,gold = data.loadResources()
end
-- Function to spawn a meteorite outside the screen
local function spawnMeteorite()
    -- Randomize iron and copper amounts
    local ironAmount = math.random(1, 3)
    local copperAmount = math.random(0, 2)
    local meteorSize = ironAmount + copperAmount

    local x, y,angle

    -- Random position, avoid the restricted rectangle (0, 0) to (1000, 1000)
    repeat
        x = math.random(0, worldWidth)
        y = math.random(0, worldHeight)
    until not (x >= 0 and x <= baseZoneX+1000 and y >= 0 and y <= baseZoneY+1000)
        angle = math.random(0,360)/(math.pi*180)
    -- Add stationary meteorite to the table
    table.insert(meteorites, {
        x = x,
        y = y,
        angle = angle,
        size = 0.04 * meteorSize, -- Scale meteor size
        iron = ironAmount,
        copper = copperAmount
    })
end
local function spawnGoldMeteorite()
        -- Randomize iron and copper amounts
        local goldAmount = math.random(5, 10)
        
        local meteorSize = goldAmount
    
        local x, y,angle
    
        -- Random position, avoid the restricted rectangle (0, 0) to (1000, 1000)
        repeat
            x = math.random(0, worldWidth)
            y = math.random(0, worldHeight)
        until not (x >= 0 and x <= baseZoneX+1000 and y >= 0 and y <= baseZoneY+1000)
            angle = math.random(0,360)*math.pi/180
        -- Add stationary meteorite to the table
        table.insert(goldMeteorites, {
            x = x,
            y = y,
            angle = angle,
            size = 0.04 * meteorSize, -- Scale meteor size
            gold = goldAmount
        })
end
local function spawnEnemy()
    local x, y

    -- Random position, avoid the restricted rectangle (0, 0) to (1000, 1000)
    repeat
        x = math.random(0, worldWidth)
        y = math.random(0, worldHeight)
    until not (x >= 0 and x <= baseZoneX+1500 and y >= 0 and y <= baseZoneY+1500)

    -- Initialize enemy
    table.insert(enemies, {
        x = x,
        y = y,
        dx = 0, -- Movement direction
        dy = 0,
        angle = 0, -- Angle for orbiting
        hp = math.random(2, 5), -- Health points
        speed = math.random(20, 60), -- Enemy speed
        state = "idle" -- States: idle, chasing, orbiting
    })
end

function love.load()
    
    love.window.setFullscreen(true, "desktop")
    --font = love.graphics.newFont("AlphaProta.ttf",18 )
    
    
    WIDTH =love.graphics.getWidth()
    HEIGHT = love.graphics.getHeight()
    worldWidth = WIDTH*10
    worldHeight = HEIGHT*10
    love.graphics.draw(images.backgroundImage, worldWidth/2, worldHeight/2,0,1,1,images.backgroundImage:getWidth()/2,images.backgroundImage:getHeight()/2)
    baseZoneX,baseZoneY = 1000,1000
    spaceCraft = {
        x = 500, -- Starting position
        y = 500,
        speed = 300,        -- Max speed
        acceleration = 200, -- Acceleration rate
        friction = 0.98,    -- Friction factor
        vx = 0,             -- Velocity in x
        vy = 0,             -- Velocity in y
        angle = 0,          -- Player angle (in radians)
        width = 50,
        height = 50
    }
    playerX, playerY = WIDTH/2,HEIGHT/2
    
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

    for i = 1,5 do
        spawnGoldMeteorite()
    end
    for i = 1, 300 do -- Adjust '50' to spawn more or fewer meteors
        spawnMeteorite()
    end
    for i = 1, 30 do -- Adjust '50' to spawn more or fewer meteors
        spawnEnemy()
    end
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
local insideBaseZone = false
local function checkPlayerInsideBase()
    if spaceCraft.x>0 and spaceCraft.x<baseZoneX and spaceCraft.y>0 and spaceCraft.y<baseZoneY and (not insideBaseZone) then
        insideBaseZone = true
        addNotification("You are inside the base.",3)
    elseif spaceCraft.x>baseZoneX and spaceCraft.y>baseZoneY and insideBaseZone then
        insideBaseZone = false
        addNotification("You are leaving the base.",3)
    end

end
function love.update(dt)
    if selectedView == MainView then
        checkPlayerInsideBase()
        if playerShield < 10 then
            shieldRefillTimer = shieldRefillTimer + dt
            if shieldRefillTimer >= 3 then
                playerShield = playerShield + 1
                shieldRefillTimer = 0
            end
        end
        local inputX, inputY = 0, 0 -- Input direction
        local ax, ay = 0, 0 -- Acceleration in x and y
        -- Handle input for acceleration
        if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
            -- inputY = inputY - 1
            ay = -1
        end
        if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
            
            ay = 1
        end
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            ax = -1
        end
        if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            ax = 1
        end
        -- Apply acceleration to velocity
        spaceCraft.vx = spaceCraft.vx + ax * spaceCraft.acceleration * dt
        spaceCraft.vy = spaceCraft.vy + ay * spaceCraft.acceleration * dt

        -- Apply friction to velocity
        spaceCraft.vx = spaceCraft.vx * spaceCraft.friction
        spaceCraft.vy = spaceCraft.vy * spaceCraft.friction

        -- Update spaceCraft position
        spaceCraft.x = spaceCraft.x + spaceCraft.vx * dt
        spaceCraft.y = spaceCraft.y + spaceCraft.vy * dt

        -- Clamp position within the game world
        spaceCraft.x = math.max(0, math.min(spaceCraft.x, worldWidth - spaceCraft.width))
        spaceCraft.y = math.max(0, math.min(spaceCraft.y, worldHeight - spaceCraft.height))

        -- Update spaceCraft's angle based on velocity
        if spaceCraft.vx ~= 0 or spaceCraft.vy ~= 0 then
            spaceCraft.angle = math.atan2(spaceCraft.vy, spaceCraft.vx)
        end

        -- Update Camera to center the spaceCraft
        cameraX = spaceCraft.x - WIDTH / 2
        cameraY = spaceCraft.y - HEIGHT / 2

        -- Clamp camera to prevent seeing outside the game world
        cameraX = math.max(0, math.min(cameraX, worldWidth - WIDTH))
        cameraY = math.max(0, math.min(cameraY, worldHeight - HEIGHT))
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

        -- Update spaceCraft position
        playerX = playerX + playerVX * dt
        playerY = playerY + playerVY * dt

        -- Update spaceCraft angle based on velocity direction
        if velocityLength > 0 then
            playerAngle = math.atan2(playerVY, playerVX)*180/math.pi -- Angle in radians
        end
    

        -- Spawn meteorites at intervals
        -- spawnTimer = spawnTimer + dt
        -- if spawnTimer >= 4 then
        --     spawnMeteorite()
        --     spawnTimer = 0
        -- end

        -- Spawn enemies at intervals
        -- enemySpawnTimer = enemySpawnTimer + dt
        -- if enemySpawnTimer >= enemySpawnInterval then
        --     spawnEnemy()
        --     enemySpawnTimer = 0
        -- end

        -- Update meteorites
        for i = #meteorites, 1, -1 do
            local m = meteorites[i]
            -- Check collision with spaceCraft
            local playerWidth, playerHeight = player:getWidth() * playerImageScale, player:getHeight() * playerImageScale
            local meteoriteWidth, meteoriteHeight = meteorite:getWidth() * 0.1, meteorite:getHeight() * 0.1

            if m.x < spaceCraft.x + playerWidth / 2 and
               m.x + meteoriteWidth > spaceCraft.x - playerWidth / 2 and
               m.y < spaceCraft.y + playerHeight / 2 and
               m.y + meteoriteHeight > spaceCraft.y - playerHeight / 2 then
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
            

            -- Check collision with spaceCraft
            local playerWidth, playerHeight = player:getWidth() * playerImageScale, player:getHeight() * playerImageScale
            local dropboxWidth, dropboxHeight = dropbox:getWidth() * 0.05, dropbox:getHeight() * 0.05
            local str =d.x .. d.y
            
            if d.x < spaceCraft.x + playerWidth / 2 and
                d.x + dropboxWidth > spaceCraft.x - playerWidth / 2 and
                d.y < spaceCraft.y + playerHeight / 2 and
                d.y + dropboxHeight > spaceCraft.y - playerHeight / 2 then
                table.remove(dropBoxes, i)
                coin = coin + math.random(1,5)
                --coin will be added!
            end
        end
        -- Laser firing timer
        laserTimer = laserTimer - dt
        -- Enemy Update Logic
        for _, enemy in ipairs(enemies) do
            local distanceToPlayer = math.sqrt((enemy.x - spaceCraft.x)^2 + (enemy.y - spaceCraft.y)^2)

            -- State transitions
            if distanceToPlayer <= 600 and enemy.state ~= "orbiting" then
                -- Move towards the player
                enemy.state = "chasing"
                local dx, dy = spaceCraft.x - enemy.x, spaceCraft.y - enemy.y
                local length = math.sqrt(dx^2 + dy^2)
                enemy.dx = dx / length
                enemy.dy = dy / length

            elseif distanceToPlayer <= 450 then
                -- Orbit around the player
                enemy.state = "orbiting"
                enemy.orbitAngle = math.atan2(enemy.y - spaceCraft.y, enemy.x - spaceCraft.x)
                enemy.orbitSpeed = math.pi / 10 -- Orbit speed (radians per second)

            elseif distanceToPlayer > 600 then
                -- Transition to wandering/patrol state if too far from player
                if enemy.state ~= "wandering" then
                    enemy.state = "wandering"
                    enemy.wanderTimer = math.random(10, 20) -- Time until next direction change
                    enemy.wanderAngle = math.random() * 2 * math.pi -- Random initial direction
                    enemy.dx = math.cos(enemy.wanderAngle)
                    enemy.dy = math.sin(enemy.wanderAngle)
                end
            end

            -- Behavior based on state
            if enemy.state == "chasing" then
                -- Move toward the player
                enemy.x = enemy.x + enemy.dx * enemy.speed * dt
                enemy.y = enemy.y + enemy.dy * enemy.speed * dt

            elseif enemy.state == "orbiting" then
                -- Circular orbit logic
                enemy.orbitAngle = enemy.orbitAngle + enemy.orbitSpeed * dt
                enemy.x = spaceCraft.x + 450 * math.cos(enemy.orbitAngle)
                enemy.y = spaceCraft.y + 450 * math.sin(enemy.orbitAngle)

            elseif enemy.state == "wandering" then
                -- Wandering patrol movement
                enemy.x = enemy.x + enemy.dx * enemy.speed * dt
                enemy.y = enemy.y + enemy.dy * enemy.speed * dt

                -- Timer for direction change
                enemy.wanderTimer = enemy.wanderTimer - dt
                if enemy.wanderTimer <= 0 or enemy.x < 0 or enemy.x > worldWidth or enemy.y < 0 or enemy.y > worldHeight then
                    -- Pick a new random direction and reset timer
                    enemy.wanderAngle = math.random() * 2 * math.pi
                    enemy.dx = math.cos(enemy.wanderAngle)
                    enemy.dy = math.sin(enemy.wanderAngle)
                    enemy.wanderTimer = math.random(10, 20)
                end
            end

        -- Check collision with player

            -- Fire laser toward player
            if laserTimer <= 0 and (enemy.state == "chasing" or enemy.state == "orbiting") then
                local dx, dy = spaceCraft.x - enemy.x, spaceCraft.y - enemy.y
                local length = math.sqrt(dx^2 + dy^2)
                table.insert(enemyLasers, {
                    x = enemy.x,
                    y = enemy.y,
                    dx = dx / length,
                    dy = dy / length,
                    angle = math.atan2(dy, dx),
                    speed = 400
                })
                laserTimer = laserCooldown
            end
        end

        -- Update lasers
        for i = #enemyLasers, 1, -1 do
            local laser = enemyLasers[i]
            laser.x = laser.x + laser.dx * laser.speed * dt
            laser.y = laser.y + laser.dy * laser.speed * dt
            -- Check collision with player
            local laserWidth, laserHeight = laserImage:getWidth() * 0.03, laserImage:getHeight() * 0.03
            local playerWidth, playerHeight = player:getWidth() * playerImageScale, player:getHeight() * playerImageScale

            if laser.x < spaceCraft.x + playerWidth / 2 and
            laser.x + laserWidth > spaceCraft.x - playerWidth / 2 and
            laser.y < spaceCraft.y + playerHeight / 2 and
            laser.y + laserHeight > spaceCraft.y - playerHeight / 2 then
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
            -- Remove lasers if they go offscreen
            if laser.x < 0 or laser.x > worldWidth or laser.y < 0 or laser.y > worldHeight then
                table.remove(enemyLasers, i)
            end
        end
        -- Update spacecraft lasers
        for i = #lasers, 1, -1 do
            local laser = lasers[i]
            laser.x = laser.x + laser.dx * laser.speed * dt
            laser.y = laser.y + laser.dy * laser.speed * dt

            -- Remove lasers if offscreen
            if laser.x < 0 or laser.x > worldWidth or laser.y < 0 or laser.y > worldHeight then
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
                            if math.random(0,100) > 50 then
                                love.graphics.draw(dropbox,e.x,e.y,0,0.01,0.01)
                            end
                        end
                        break  -- Stop checking other enemies for this laser
                    end
                end
            end
        end
        for i = #collectorLasers, 1, -1 do
            local collectorlaser = collectorLasers[i]
            collectorlaser.x = collectorlaser.x + collectorlaser.dx * collectorlaser.speed * dt
            collectorlaser.y = collectorlaser.y + collectorlaser.dy * collectorlaser.speed * dt

            -- Remove lasers if offscreen
            if collectorlaser.x < 0 or collectorlaser.x > worldWidth or collectorlaser.y < 0 or collectorlaser.y > worldHeight then
                table.remove(lasers, i)
            else
                -- Check collision with goldMeteorite
                local laserWidth, laserHeight = laserImage:getWidth() * 0.1, laserImage:getHeight() * 0.1
                for j = #goldMeteorites, 1, -1 do
                    local e = goldMeteorites[j]
                    local enemyWidth, enemyHeight = enemyImage:getWidth() * 0.1, enemyImage:getHeight() * 0.1
        
                    if collectorlaser.x < e.x + enemyWidth / 2 and
                    collectorlaser.x + laserWidth > e.x - enemyWidth / 2 and
                    collectorlaser.y < e.y + enemyHeight / 2 and
                    collectorlaser.y + laserHeight > e.y - enemyHeight / 2 then
                        table.remove(collectorLasers, i)
                        table.remove(goldMeteorites, j)
                        gold = gold + e.gold
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

        love.graphics.push()
        love.graphics.translate(-cameraX, -cameraY)
            -- Draw the game world (background)
        love.graphics.setColor(0.2, 0.2, 0.2) -- Gray background
        love.graphics.rectangle("fill", 0, 0, worldWidth, worldHeight)
        love.graphics.setColor(1, 1, 1) -- Reset Colors
        for i = 0, worldWidth / images.backgroundImage:getWidth() do
            for j = 0, worldHeight / images.backgroundImage:getHeight() do
                love.graphics.draw(images.backgroundImage, i * images.backgroundImage:getWidth(), j * images.backgroundImage:getHeight())
            end
        end
        -- Draw the spacePort
        love.graphics.draw(images.spacePortImage, baseZoneX/2, baseZoneY/2,0,0.5,0.5,images.spacePortImage:getWidth()/2,images.spacePortImage:getHeight()/2)
        --Draw the Portal 
        love.graphics.draw(images.portalImage,worldWidth-1000,worldHeight-1000,0,0.5,0.5,images.portalImage:getWidth()/2,images.portalImage:getHeight()/2)
        -- Draw the player
        
        love.graphics.draw(player, spaceCraft.x, spaceCraft.y, spaceCraft.angle+math.pi/2, playerImageScale, playerImageScale, player:getWidth() / 2, player:getHeight() / 2)
        -- love.graphics.rectangle("fill", spaceCraft.x, spaceCraft.y, spaceCraft.width, spaceCraft.height)
        -- Draw spacecraft lasers
        drawSpacecraftLasers()
        -- Draw meteorites
        for _, m in ipairs(meteorites) do
            love.graphics.draw(meteorite, m.x, m.y, m.angle, m.size, m.size,meteorite:getWidth() / 2, meteorite:getHeight() / 2)
        end
        drawGoldMeteorite()
                -- Draw enemies
        for _, enemy in ipairs(enemies) do
            local value = 10
            for i=1,enemy.hp do
                -- love.graphics.draw(healthBarRed,(enemy.x+(value*(i-1))-25),enemy.y-45,0,0.1,0.3)
                love.graphics.draw(images.redHpTick,(enemy.x+(value*(i-1))-25),enemy.y-45,0,0.05,0.05)
            end
            love.graphics.draw(enemyImage, enemy.x, enemy.y, math.atan2(enemy.dy, enemy.dx)-math.pi/2, 0.1, 0.1, enemyImage:getWidth() / 2, enemyImage:getHeight() / 2)
        end
        -- Draw enemy lasers
        for _, laser in ipairs(enemyLasers) do
            
            love.graphics.draw(laserImage, laser.x, laser.y, laser.angle, 0.05, 0.05, laserImage:getWidth() / 2, laserImage:getHeight() / 2)
        end

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
        love.graphics.pop()

        -- HUD (not affected by camera)
        love.graphics.setColor(1, 1, 1)

        -- Draw notifications at the top-center of the screen
        local screenWidth = love.graphics.getWidth()
        for i, n in ipairs(notifications) do
            love.graphics.setColor(10/255, 145/255, 46/255) -- White color
            love.graphics.print(n.text, screenWidth / 2 - 50, 50 + (i - 1) * 20)
        end

        love.graphics.setColor(1, 1, 1) -- Reset color
        -- Draw Game View
        -- Draw player
        -- love.graphics.draw(player, playerX, playerY, ((90+playerAngle)*math.pi/180), playerImageScale, playerImageScale, player:getWidth() / 2, player:getHeight() / 2)
        for i=1,playerHealth do
            love.graphics.draw(images.healthBarTick,(playerX-45)+(10*(i-1)),playerY-65,0,0.05,0.05)

        end
        for i=1,playerShield do
        love.graphics.draw(images.blueShieldTick,(playerX-45)+(10*(i-1)),playerY-80,0,0.05,0.05)
        -- love.graphics.draw(shieldBar,(playerX-40)+(8*(i-1)),playerY-75,0,0.05,0.3)
        end
        drawMinimap()
    end

end
function  drawGoldMeteorite()
    -- Draw meteorites
    for _, m in ipairs(goldMeteorites) do
        love.graphics.setColor(186/255, 171/255, 60/255)
        love.graphics.draw(meteorite, m.x, m.y, m.angle, m.size, m.size,meteorite:getWidth() / 2, meteorite:getHeight() / 2)
    end
    love.graphics.setColor(1,1,1)
end
function drawSpacecraftLasers()
    for _, laser in ipairs(lasers) do
        love.graphics.draw(
            laserImage, 
            laser.x, laser.y, 
            laser.angle, 
            0.05, 0.05, 
            laserImage:getWidth() / 2, laserImage:getHeight() / 2
        )
    end
    for _, laser in ipairs(collectorLasers) do
        love.graphics.draw(
            images.collectorLaserImage, 
            laser.x, laser.y, 
            laser.angle, 
            0.05, 0.05, 
            images.collectorLaserImage:getWidth() / 2, images.collectorLaserImage:getHeight() / 2
        )
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
        { name = "Coin", amount = coin,image = images.coinImage },
        { name = "Iron", amount = iron,image = images.ironIngotImage },
        { name = "Copper", amount = copper,image = images.copperIngotImage },
        { name = "Gold", amount = gold,image = images.goldImage },

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
                love.graphics.draw(item.image,x+100,y+125,0,0.25,0.25,item.image:getWidth()/2,item.image:getHeight()/2)
            end
        end
    end
end
function love.mousepressed(x, y, button)

    if button == 1 then -- Left mouse button
        if MainView then
            -- Calculate angle and direction for the laser
            local angle = math.atan2(y+cameraY - spaceCraft.y, x+cameraX - spaceCraft.x)
            local dx = math.cos(angle)
            local dy = math.sin(angle)
            local laser_angle = angle
            -- Add a new laser to the lasers table
            table.insert(lasers, {
                x = spaceCraft.x,
                y = spaceCraft.y,
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
    if button == 2 then
        if MainView then
            local angle = math.atan2(y+cameraY - spaceCraft.y, x+cameraX - spaceCraft.x)
            local dx = math.cos(angle)
            local dy = math.sin(angle)
            local laser_angle = angle
            -- Add a new laser to the lasers table
            table.insert(collectorLasers, {
                x = spaceCraft.x,
                y = spaceCraft.y,
                r = laser_angle,
                dx = dx,
                dy = dy,
                angle = angle,
                speed = 500, -- Speed of the laser
            })
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
