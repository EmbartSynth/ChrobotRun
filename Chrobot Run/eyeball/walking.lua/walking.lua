if love.keyboard.isDown('right') then
    player.x = player.x + player.speed
    player.anim = player.animations.right
    isMoving = true
end

if love.keyboard.isDown('left') then
    player.x = player.x - player.speed
    player.anim = player.animations.left
    isMoving = true
end

if love.keyboard.isDown('down') then
    player.y = player.y + player.speed
    player.anim = player.animations.down
    isMoving = true
end


if isMoving == false then
    player.anim:gotoFrame(2)
end