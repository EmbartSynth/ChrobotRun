gameOn = false -- this is the variable that means, that the game has been started; it it will become true when player will click the button to start a game
obstaclesInitialized = false
timerStarted = false
credits =  false
groundY = 412 -- ground level
mapOffsetX = 0 -- this will control the horizontal scrolling
scrollSpeed = 150 -- speed of the game
speedIncrease = 25 -- this is how much the game will speed up at the time
speedIncreasePoint = 0 -- this variable will be used to increase the speed of the game at various tresholds
digitNames = {"first", "second", "third", "fourth", "fifth", "sixth"} -- this table will be used to display the point counter

function love.load()
    -- loading libraries
    anim8 = require 'libraries/anim8'
    sti = require 'libraries/sti'

    math.randomseed(os.time()) -- using math.randomseed() to randomize future random results more

    -- filter so that sprites don't look blurry
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- COUNTER SECTION
    -- creating a number table
    number = {}
    -- creating the digits of which the number will consist
    number.digits = {0, 0, 0, 0, 0, 0} -- at the begining of the game every digit is zero
    -- creating empty table, which will consist of every digit of curent score
    number.num = {}

    number.anim = {} -- creating empty table that will be used to put animation of certain digits
    -- populating number.anim table with empty tables for every digit
    for _, name in ipairs(digitNames) do
        number.anim[name] = {}
    end 

    --uploading number sprites (source: https://opengameart.org/content/bold-boxy-fat-font)
    number.spriteSheet = love.graphics.newImage('sprites/boxy_bold_fat/edged/boxy_bold_fat_edge_golden.png')
    -- creating a grid including all the numbers
    number.grid = anim8.newGrid(8, 8, number.spriteSheet:getHeight(), number.spriteSheet:getWidth(), 0, 0, 1, 1)
    -- creating animations (one for every number)
    number.animations = {
        zero = anim8.newAnimation(number.grid(1, 1),1), -- every animation has only one frame
        one = anim8.newAnimation(number.grid(2, 1), 1),
        two = anim8.newAnimation(number.grid(3, 1), 1),
        three = anim8.newAnimation(number.grid(4, 1), 1),
        four = anim8.newAnimation(number.grid(5, 1), 1),
        five = anim8.newAnimation(number.grid(6, 1), 1),
        six = anim8.newAnimation(number.grid(7, 1), 1),
        seven = anim8.newAnimation(number.grid(8, 1), 1),
        eight = anim8.newAnimation(number.grid(9, 1), 1),
        nine = anim8.newAnimation(number.grid(10, 1), 1)
        }

    -- MAP SECTION
    -- loading the background tilemap
    map = sti('maps/robot_run_ext.lua')

    -- get dimensions from STI
    mapWidth = map.width * map.tilewidth
    mapHeight = map.height * map.tileheight

    -- PLAYER SECTION
    -- creating a player character and placing it on the platform
    player = {}
    -- PC stand on the platform
    player.x = 150
    player.y = groundY
    -- player's measurements and speed
    player.width = 17
    player.height = 22
    player.speed = 200

    player.rotation = 0
    
    -- loading sprites for player
    player.spriteSheet = love.graphics.newImage('sprites/robot_sprites.png')

    -- creating animations of player
    player.grid = anim8.newGrid(17, 22, player.spriteSheet:getWidth(), player.spriteSheet:getHeight(), 0, 0, 3, 4)
    player.animations = {
        walk = anim8.newAnimation(player.grid('1-4', 1), 0.13), -- walk animation (idle)
        jump = { -- jump animation (4 stages: bouncing off, flying up, flying down, landing)
            asc1 = anim8.newAnimation(player.grid(1, 2), 0.1),
            asc2 = anim8.newAnimation(player.grid(2, 2), 0.2),
            desc1 = anim8.newAnimation(player.grid(3, 2), 0.2),
            desc2 = anim8.newAnimation(player.grid(4, 2), 0.1),
            
            },
        death = anim8.newAnimation(player.grid(1, 1), 1)
        }
    
    -- source of player sprites and some elements of map: https://opengameart.org/content/a-platformer-in-the-forest
    -- source of some elements of map: https://opengameart.org/content/total-eclipse

    -- creating the jump mechanic
    player.ground = player.y
    player.y_velocity = 0
    player.jump_height = -300
    player.gravity = 600
    player.onGround = true
    player.jumpState = 'idle'
    
    -- variables that determine mechanic longer jump when key is pressed for longer
    player.jumpHoldTime = 0
    player.jumpHoldMax = 0.3
    player.isJumping = false
    
    -- variable that gives player his default animation
    player.anim = player.animations.walk
    -- variable to determine if the player character is dead
    player.dead = false
    
    -- variables used to determine the point in which frames of jump animation should change
    ASC_SWITCH_THRESHOLD = player.jump_height * 0.9
    DESC_SWITCH_THRESHOLD = -player.jump_height * 0.9

    -- OBSTACLES SECTION
    -- obstacles will only apear, if the game is on
    
    function collision(a, b) -- simple function to detect collisions
        return
        a.x < b.x + b.width and
        b.x < a.x + a.width and
        a.y < b.y + b.height and
        b.y < a.y + a.height
    end

    -- MENU SECTION
    menu = {
        title = love.graphics.newImage('sprites/title_menu.png'),
        instructions = love.graphics.newImage('sprites/instructions_menu.png'),
        credits = love.graphics.newImage('sprites/credits_menu.png'),
        death = love.graphics.newImage('sprites/death_menu.png')
    }
    
end

function restart()
    scrollSpeed = 150
    initializeObstacles()
    start = love.timer.getTime()
    player.rotation = 0
    gameOn = true
    player.dead = false
    collision_counter = false
end

function love.keypressed(key) -- this function is the backbone of jumping mechanic
    if (key == 'space' or key == 'up' or key == 'w') and player.onGround and not player.dead then
        player.y_velocity = player.jump_height
        player.onGround = false
        player.jumpState = 'asc1' -- first stage of jumping and first frame of animation (referenced latet in love.update function)
        player.isJumping = true
        player.jumpHoldTime = 0
    end

    if key == 'return' and not player.dead and not gameOn then
        gameOn = true
        start = love.timer.getTime()
        timerStarted = true
    elseif key == 'return' and player.dead then
        restart()
    end

    if key == 'c' and not credits then
        credits = true
    elseif key == 'c' and credtis then
        credits = false
    end

    if key == 'escape' then
        love.event.quit()
    end
end

function love.keyreleased(key) -- this function stops extending the jump when the jump key is released
    if key == 'space' or key == 'up' or key == 'w' then
        player.isJumping =  false -- stop extending the jump
    end
end

function initializeObstacles()
    -- spikes obstacle: table basics
    spikes = {
        x = 1000,
        y = groundY + 18,
        graphics = love.graphics.newImage("sprites/spikes.png"),
        scale = 2,            
        originX = 16, -- origin point X from draw call
        originY = 16  -- origin point Y from draw call
        }
        
    spikes.width = spikes.graphics:getWidth() * spikes.scale   -- account for scale factor
    spikes.height = spikes.graphics:getHeight() * spikes.scale -- account for scale factor

    -- create tables for groups of spikes
    spikes.groups = {}
    table.insert(spikes.groups, {
        x = spikes.x,
        y = spikes.y,
        count = 2, -- how many pairs of spikes, first group always has 2 pairs
        spacing = 0 -- spacing between pairs
        })

    -- saw obstacle: table basics
    saw = {}
    saw.x = 2000
    saw.y = 220
    saw.spriteSheet = love.graphics.newImage("sprites/saw_trap_new.png") -- load the sprite
    saw.width = math.floor(saw.spriteSheet:getWidth() / 11) -- get width of one frame by dividing whole grid by number of frames
    saw.height = saw.spriteSheet:getHeight()
    
    -- create animation grid
    saw.grid = anim8.newGrid(saw.width, saw.height, saw.spriteSheet:getWidth(), saw.height)
    -- create animation
    saw.spin = anim8.newAnimation(saw.grid("1-11", 1), 0.1)
    -- variable that gives saw its animation
    saw.anim = saw.spin

    -- making saws that will show in the top section of the screen
    -- those sows will have less distance between them and will prevent player to survive whole game double jumping above the bottom saws spawn area
    -- those sows will come in the column of three
    topSaws = {
        x = 3000, -- they will apppear after the first saw
        y = 10, -- this is the y position of the highest saw in the column
        spin = saw.spin,
        count = 3
        }
    topSaws.anim = topSaws.spin

    obstaclesInitialized = true
end


function love.update(dt)
    -- COUNTER SECTION
    -- this section of code is also responsible for game speeding up
    if timerStarted then
        -- determine the score, which will be used to speed up the game the longer someone plays it
        score = love.timer.getTime() - start
        -- determine the points on whicch the speed will increase
        speedTresholds = {15, 30, 45, 60, 75, 100, 125, 150, 175, 200}

        function speeding_up(treshold) -- function that will increase speed of the game at certain tresholds
            if score >= treshold and speedIncreasePoint < treshold then
                scrollSpeed = scrollSpeed + speedIncrease
                speedIncreasePoint = treshold
            end
        end
    
        for i = #speedTresholds, 1, -1 do -- execute above function
            speeding_up(speedTresholds[i])
        end
    end


    -- MAP SECTION
    -- move the map to the left over time
    mapOffsetX = mapOffsetX - scrollSpeed * dt

    -- get the width of the tile map in pixels
    mapWidth = map.width * map.tilewidth

    -- loop the map: when mapOffsetX moves past one full map width, reset it
    if mapOffsetX <= -mapWidth then
        mapOffsetX = 0
    end

    -- PLAYER SECTION
    -- apply gravity
    if not player.onGround then
        -- if player is still holding jump and hasn't exceeded jumpHoldMax time
        if player.isJumping and player.jumpHoldTime < player.jumpHoldMax then
            player.jumpHoldTime = player.jumpHoldTime + dt
        else
            player.y_velocity = player.y_velocity + player.gravity * dt
        end
    end

    -- update position
    player.y = player.y + player.y_velocity * dt

    -- determine jump stage
    if not player.onGround then
        if player.y_velocity < 0 then -- ascending
            if player.y_velocity < ASC_SWITCH_THRESHOLD then
                player.jumpState = 'asc1' -- bouncing off
            else
                player.jumpState = 'asc2' -- flying up
            end
        elseif player.y_velocity > 0 then -- descending
            if player.y_velocity > DESC_SWITCH_THRESHOLD then
                player.jumpState = 'desc2' -- landing
            else
                player.jumpState = 'desc1' -- flying down
            end
        end
    end

    -- simulate ground collision
    if player.y + player.height >= groundY then
        player.y = groundY - player.height
        player.y_velocity = 0
        if player.jumpState == 'desc1' then
            player.jumpState = 'desc2'
        else
            player.onGround = true
            player.isJumping = false
            player.jumpState = 'idle'
        end
    end

    -- set animation based on jump state
    if player.jumpState == "idle" then -- default animation (walk) 
        player.anim = player.animations.walk
    elseif player.jumpState == "asc1" then
        player.anim = player.animations.jump.asc1 -- bouncing off
    elseif player.jumpState == "asc2" then
        player.anim = player.animations.jump.asc2 -- flying up
    elseif player.jumpState == "desc1" then
        player.anim = player.animations.jump.desc1 -- flying down
    elseif player.jumpState == "desc2" then
        player.anim = player.animations.jump.desc2 -- landing
        player.onGround = true
    end

    if player.y < 15 then -- player's character can't get past the top border of the game window
        player.y = 15
    end

    -- update player's animation
    player.anim:update(dt)

    -- OBSTACLES SECTION
    if gameOn and not obstaclesInitialized then
        initializeObstacles()
    end
    
    if gameOn and obstaclesInitialized then
        -- make spikes groups move at scrollSpeed
        for i = #spikes.groups, 1, -1 do
            spikes.groups[i].x =  spikes.groups[i].x - scrollSpeed * dt -- spikes move at scrollSpeed
            -- remove the group if it's way offscreen
            if spikes.groups[i].x + spikes.groups[i].count * (spikes.width + spikes.groups[i].spacing) < -50 then
               table.remove(spikes.groups, i) 
            end
        end

        -- spawn new group then the rightmost group is far enough left
        lastGroup = spikes.groups[#spikes.groups]
        if lastGroup and lastGroup.x < 500 then
            table.insert(spikes.groups, {
                x = spikes.x,
                y = spikes.y,
                count = math.random(5),
                spacing = 0
            })
        end

        collision_counter = false

        for _, group in ipairs(spikes.groups) do -- this for loop detects collisions with the spikse
            for i = 0, group.count - 1 do
                local spikeX = group.x + i * (spikes.width + group.spacing)
                local spike = {
                    x = spikeX - spikes.originX * spikes.scale,
                    y = group.y - spikes.originY * spikes.scale,
                    width = spikes.width,
                    height = spikes.height
                }
                if collision(player, spike) then
                    collision_counter = true
                end
            end
        end

        saw.x = saw.x - scrollSpeed * dt -- saws move at scrollSpeed
        if saw.x < -50 then -- if saw dissapears from screen, move them beyond the right border and assing random y position
            saw.y = math.random(200, 350)
            saw.x = 900
            if saw.x == spikes.x then -- if saw is to close to spikes, move saw to the right
                saw.x = saw.x + 100
            end
        end

        local sawBox = {
        x = saw.x,
        y = saw.y,
        width = saw.width * 1.5,
        height = saw.height * 1.5
        }

        if collision(player, sawBox) then
            collision_counter = true
        end
        
        topSaws.speed = scrollSpeed * 1.5 -- they are faster than the scrollSpeed, so they will be more frequent
        topSaws.x = topSaws.x - topSaws.speed * dt -- topSaws move at their own speed wchich is faster than scrollSpeed

        for i = 0, topSaws.count - 1 do
            local topSaw = {
                x = topSaws.x,
                y = topSaws.y + i * (saw.height + 15),
                width = saw.width * 1.5,
                height = saw.height * 1.5
                }

            if collision(player, topSaw) then
                collision_counter = true
            end
        end

        if topSaws.x < -50 then -- if saw dissapears from screen, move them beyond the right border
            topSaws.x = 1000
        end

        -- update saw's animation
        saw.anim:update(dt)
        -- upadeta topSaws' animation
        topSaws.anim:update(dt)

        -- DEATH SECTION
        if collision_counter then
            scrollSpeed = 0
            player.rotation = 1.5
            player.anim = player.animations.death
            player.dead = true
        end
    end
end

function love.draw()
    -- MAP SECTION
    -- draw the tile map with the scrolling offser
    map:draw(mapOffsetX, 0)
    -- draw a second instance of the tile map to create a seamless loop
    mapWidth = map.width * map.tilewidth
    map:draw(mapOffsetX + mapWidth, 0)

    if gameOn and obstaclesInitialized then
        -- OBSTACLES SECTION
        for _, group in ipairs(spikes.groups) do
            for i = 0, group.count - 1 do
                local x = group.x + i * (spikes.width + group.spacing)
                love.graphics.draw(spikes.graphics, x, group.y, 0, 2, 2, 16, 16)
            end
        end
        -- draw the saws
        saw.anim:draw(saw.spriteSheet, saw.x, saw.y, nil, 1.5, 1.5, 1, 1)
        -- draw the saws at the top
        for i = 0, topSaws.count - 1 do
            topSaws.anim:draw(saw.spriteSheet, topSaws.x, topSaws.y + i * (saw.height + 15), nil, 1.5, 1.5, 1, 1)
        end
    end
    

    -- COUNTER SECTION
    function counter(num) -- function that will calculate points counter based od time
        number.num = {} -- clear previous digits
        -- change num into table consisting of every digit of this number
        for digit in tostring(math.floor(num)):gmatch("%d") do
            table.insert(number.num, tonumber(digit))
        end
        -- allign digits to the right so that the score always had 6 digits
        local function rightAlignDigits()
            local numLen = #number.num
            local totalLen = #number.digits
            for i = 1, totalLen do
                if i <= totalLen - numLen then
                    number.digits[i] = 0
                else
                    number.digits[i] = number.num[i - (totalLen - numLen)]
                end
            end
        end
        rightAlignDigits()
        return number.digits
    end

    -- determine the time that past since the bigining of the game
    if not timerStarted then
        time = 0
    else
        if not player.dead then
            t = love.timer.getTime() - start
            time = math.floor(t*100)/100
            time = time*100
        end
    end

    -- use counter(), now n is the number of time that passed in a form of table with six items
    n = counter(time)

    -- give every number in n an animation that corresponds with the digit
    for i = 1, #digitNames do
        key = digitNames[i]
        digit = n[i]
        number.anim[key].value = digit
    end

    for _, value in pairs(number.anim) do
        local digit = value.value
        if digit == 0 then
            value.animation = number.animations.zero
        elseif digit == 1 then
            value.animation = number.animations.one
        elseif digit == 2 then
            value.animation = number.animations.two
        elseif digit == 3 then
            value.animation = number.animations.three
        elseif digit == 4 then
            value.animation = number.animations.four
        elseif digit == 5 then
            value.animation = number.animations.five
        elseif digit == 6 then
            value.animation = number.animations.six
        elseif digit == 7 then
            value.animation = number.animations.seven
        elseif digit == 8 then
            value.animation = number.animations.eight
        elseif digit == 9 then
            value.animation = number.animations.nine
        end
    end

    -- draw function that will draw animations of the counter
    function number:draw(x, y, spacing)
        for i, key in ipairs(digitNames) do
            local animData = self.anim[key]
            if animData and animData.animation then
                animData.animation:draw(self.spriteSheet, x + (i - 1) * spacing, y, 0, 2.5, 2.5)
            end
        end
    end

    -- draw the counter
    number:draw(600, 30, 30) 
    

    -- PLAYER SECTION
    -- draw the player animation
    player.anim:draw(player.spriteSheet, player.x, player.y, player.rotation, 2, nil, 6, 9)

    -- MENU SECTION
    if not obstaclesInitialized and not credits then
        love.graphics.draw(menu.title, 3, 25, nil, 3, 3, nil, nil)
        love.graphics.draw(menu.instructions, 350, 152, nil, 1.85, 1.85, nil, nil)
    elseif not obstaclesInitialized and credits then
        love.graphics.draw(menu.credits, 25, 75, nil, 2, 2, nil, nil)
        love.graphics.draw(menu.instructions, 350, 152, nil, 1.85, 1.85, nil, nil)
    elseif player.dead == true then
        love.graphics.draw(menu.death, 160, 130, nil, 2.5, 2.5, nil, nil)
    end

    --[[DEBUG:
    font = love.graphics.newFont(50)
    collisions = love.graphics.newText(font, collision_counter)
    love.graphics.draw(collisions, 0, 0)
    score_count = love.graphics.newText(font, score)
    love.graphics.draw(score_count, 0, 100)
    speed = love.graphics.newText(font, scrollSpeed)
    love.graphics.draw(speed, 100, 0 )
    if gameOn == false then
        status = 0
    elseif gameOn == true then
        status = 1
    end
    on = love.graphics.newText(font, status)
    love.graphics.draw(on, 300, 0)]]
end


-- Game by:
-- Maciej "Embart" Bartusik

-- Textures by:
-- Buch
-- VinnNo.0

-- Font by:
-- Scott Matott
-- devurandom
-- Clint Bellanger
-- usr_share