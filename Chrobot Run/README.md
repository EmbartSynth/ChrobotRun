# CHROBOT RUN
## Video Demo: https://youtu.be/7r2eEDm5k4o
### Description:
#### Introduction
The idea for this game was actually my third attempt at a final project. I was quite frustrated at this point. My two previous projects proved too problematic — endeavors that would have taken much longer to complete than the time I had available for finishing the course. But hey, third time's a charm! When I decided to abandon my second final project idea, I browsed the final project requirements on the CS50 website. In the "Ideas" section, I noticed "a game using Lua with LÖVE." I had never used LÖVE or Lua before, but I decided to research some tutorials and learn.

As it turned out, it wasn't that difficult, and before I realized it, I was coding my first game, which later became my final project — Chrobot Run. It's a simple endless runner where you play as a small robot navigating through the night, avoiding two types of obstacles: spikes and saws. Now I'll explain how it all works.

#### Before All the Functions
LÖVE code should be built around three main functions: `love.load`, `love.update`, and `love.draw`. My game mostly adheres to these conventions (I added some additional functions, which I'll discuss later), but before our first function begins, I need to initialize several variables. Here I'll list them:

+ **gameOn** - indicates whether the game has started. It's false initially because I don't want the game to begin until the player presses Enter
+ **obstaclesInitialized** - also false initially. Obstacles will start appearing when the game begins. This connects to a function I'll discuss later
+ **timerStarted** - shows whether the timer (essentially the scoring system) has started. It's false because the timer starts when the game begins
+ **credits** - indicates whether the credits are currently displayed
+ **groundY** - y-coordinate of the ground level
+ **mapOffsetX** - controls the horizontal scrolling of the map
+ **scrollSpeed** - the speed at which the game moves; increases the longer you play
+ **speedIncrease** - determines how much the speed increases each time
+ **speedIncreasePoint** - used to increase speed at various thresholds; initially zero
+ **digitNames** - a table containing six digit names for the counter display

#### love.load()
First, in my `love.load` function, I load two open-source libraries: STI and anim8. STI handles tilemap uploading and management, while anim8 manages animations. Then I load the current time using `os.time()` and generate a random seed from it, making obstacle generation more random. I set a graphics filter using `love.graphics` to prevent imported sprites and maps from appearing blurry.

Next comes the counter section. I create a number table and a `number.digits` table consisting of six zeros — these represent the score display digits, all starting at zero. The `number.num` variable becomes the current score, and `number.anim` handles the graphical representation of numbers on screen.

I use a for loop to populate `number.anim` with empty tables for each of the six digits. After that, I load the number spritesheet and create a grid containing digits 0-9. I create a `number.animations` table consisting of ten single-frame animations, each representing a different digit.

Then I begin the map section. I previously created a tilemap using software called Tiled, which allows me to create tilemaps and export them as .lua files for importing into my program. I created the tilemap using elements from two tilesets downloaded from OpenGameArt:
+ https://opengameart.org/content/total-eclipse
+ https://opengameart.org/content/a-platformer-in-the-forest

I establish the map's width and height based on individual tile dimensions. That concludes the map section in the `love.load` function — I'll return to the map later.

Next, I start the player section by creating an empty table called player. I give it internal variables like x and y positions (y equals groundY), width, height, speed, and rotation (used to rotate the player upon death to simulate falling). Then I load the animation spritesheet, also from "A Platformer in the Forest" set from OpenGameArt. Using this spritesheet, I create an animation grid to generate two animations: a walk animation and a jump animation consisting of four phases (two for ascending, two for descending). I also create a single-frame death animation.

I implement the jump mechanism by establishing variables like ground level, player velocity, jump height, gravity level, a boolean for whether the player is grounded, and `player.jumpState`, which tells the program which jump phase the player is in for appropriate animation display. Initially, it's in idle state, displaying the walk animation. I also create `player.jumpHoldTime` (how long the player has held the jump button, starting at zero), `player.jumpHoldMax` (maximum jump button hold duration before losing effect, currently 0.3 seconds), and `player.isJumping` (starts false until jumping begins).

The `player.anim` function is set to `player.animations.walk` to display the walk animation. `Player.dead` starts false and remains so until the player dies and loses.

I then define two crucial variables: `ASC_SWITCH_THRESHOLD` and `DESC_SWITCH_THRESHOLD`, which determine when jump animations should change to show different ascending and descending stages.

Next, I start the obstacles section with a simple collision function for detecting collisions between obstacles and the player:
```lua
function collision(a, b)
    return
    a.x < b.x + b.width and
    b.x < a.x + a.width and
    a.y < b.y + b.height and
    b.y < a.y + a.height
end
```
I'll define the remaining obstacle-related code in different functions.

The final part of `love.load()` is the menu section, where I load menu graphics created using fonts downloaded from OpenGameArt (https://opengameart.org/content/bold-boxy-fat-font). These include title menu, instructions menu, credits menu, and death menu.

#### restart()
The `restart()` function resets the game when the player dies and chooses to play again. It reestablishes the game speed to its initial value, initializes obstacles by calling a function I'll discuss later, resets the timer, sets `player.rotation` to 0 (so the player doesn't appear fallen), sets `gameOn` to true, `player.dead` to false, and `collision_counter` to false so the game doesn't think we're still colliding with obstacles.

#### love.keypressed(key)
This function defines how the game reacts to button presses. First, I set three jump buttons (W, Space, and Up arrow). Pressing any of these while the player is grounded (`player.onGround` variable) and not dead (`player.dead` variable) triggers a jump. `Player.y_velocity` becomes `player.jump_height`, `onGround` becomes false, and the player's jump state becomes "asc1" to display the first ascending phase animation.

When I press Enter and the player isn't dead and `gameOn` is false, `gameOn` becomes true. I also establish a `start` variable capturing the current time for point counting. Correspondingly, `timerStarted` becomes true. However, if I press Enter while the player is dead, it means I want to restart the game, triggering the `restart()` function.

Pressing C when credits aren't shown (`credits` is false) makes `credits` true. If `credits` is true and I press C, it becomes false.

Finally, pressing Escape executes `love.event.quit()` and closes the game.

#### love.keyreleased(key)
This function stops extending the jump when the jump button is released, setting `player.isJumping` to false.

This function inadvertently creates a double-jump option. Basically, you can press the jump button again while falling to double-jump, and with proper timing, you can stay airborne longer. I decided not to fix this, following the rule "it's not a bug, it's a feature." I later adjusted some game elements to prevent exploiting this double-jump mechanic.

#### initializeObstacles()
This function establishes all obstacles. As mentioned, it's called in the restart function to reset obstacles when restarting. First, I establish spikes — their starting position, scale, and sprite (a modified sprite from the Total Eclipse tilesheet linked earlier).

I also created a `spikes.groups` table. Spikes always spawn in groups of 1-5 pairs. The first spike group appearing at game start always consists of two pairs.

Then I established saws, placing them far beyond the right screen border to appear later in the game. The first saw's y-position is always 220. I loaded a spritesheet I created using sprites from OpenGameArt, creating a spinning saw animation with eleven looping frames.

I also created topSaws — saws at the screen's top that move slightly faster than other obstacles and always appear in columns of three. Why? I noticed that the double-jump mechanic allowed players to time jumps correctly and spend the entire game at the screen's top, beyond where regular saws spawn (I didn't want them spawning too high as it wouldn't be challenging). Therefore, I created these three-saw columns that sweep through the top section, preventing exploitation of the double-jump mechanic.

This function ends by setting `obstaclesInitialized` to true.

#### love.update(dt)
I start my `love.update(dt)` function with the counter section. First, I check if `timerStarted` is true. If so, I determine the score by subtracting start time from current time. Then I determine speed thresholds — point values at which the game should accelerate. I create a function called `speeding_up()` and call it using elements from the speedThresholds table:

```lua
function speeding_up(threshold) -- increases game speed at certain thresholds
    if score >= threshold and speedIncreasePoint < threshold then
        scrollSpeed = scrollSpeed + speedIncrease
        speedIncreasePoint = threshold
    end
end

for i = #speedThresholds, 1, -1 do -- execute above function
    speeding_up(speedThresholds[i])
end
```

I'm particularly proud of this code section. I developed several iterations of the speed-increase mechanic and finally created what I consider the most straightforward and elegant solution.

Next, I establish the map section. Using the line:
```lua
mapOffsetX = mapOffsetX - scrollSpeed * dt
```
I move the map leftward over time. I establish the map's width, and when `mapOffsetX` is less than or equal to the negative version of this width, I reset it to zero, making the map loop back and effectively infinite.

Then comes the player section. First, I apply gravity by checking if the player is jumping (`player.isJumping`) and if the jump key hold time is less than `player.jumpHoldMax`. If both conditions are true, I add dt to the player's `jumpHoldTime`. Otherwise, `player.y_velocity` increases by `player.gravity` times dt. I also update the player's position by adjusting `player.y` by `player.y_velocity` times dt.

Next, I determine the jump stage for appropriate animation display. Depending on `player.y_velocity`'s relationship with `ASC_SWITCH_THRESHOLD` and `DESC_SWITCH_THRESHOLD`, the player will be in either the first or second stage of ascending or descending. I then simulate ground collision: if `player.y + player.height` is greater than or equal to ground level (groundY), I set the position at ground level and set `player.y_velocity` to 0. I also ensure that after the first descending stage comes the second descending stage. Then I set `player.onGround` to true, `player.isJumping` to false, and `player.jumpState` to idle, so the game displays the walking animation.

Speaking of animation: in the next section, through several if statements, I determine the `player.anim` variable (the displayed animation) based on the player's current jumping stage.

I also prevent the player from surpassing the screen's top border through constant double-jumping. If `player.y` is less than 15, it becomes 15 again (15 looks smoother and more elegant than 0 in the actual game). At the player section's end, I update the animation using the dt argument.

Then I move to the obstacles section of the update function. If `gameOn` is true and `obstaclesInitialized` is false, I run the previously described `initializeObstacles()` function. I don't want obstacles spawning before the game starts. As mentioned, at `initializeObstacles()`'s end, I change `obstaclesInitialized` to true. Then I check if both `gameOn` and `obstaclesInitialized` are true. If so, I use a for loop to make spike groups move at scrollSpeed. Remember, spike groups are still only two-pair groups, since this is what I initiated with the `initializeObstacles()` function and what appears first in the game. Still within the for loop, I remove spike groups that move too far beyond the left screen border.

Next, I spawn new spike groups. I give them spike coordinates and change the pair number to a random number between 1 and 5 using `math.random()`. I set spacing to 0, eliminating space between pairs.

Then I establish a collision counter that reacts to player-obstacle collisions. It starts false.

The next for loop detects collisions between spikes and the player. I establish a for loop with the `ipairs()` function and create a local spike table with all data needed by the `collision()` function. I pass data from the spikes table to this spike table, then check for collision between player and spike using the `collision()` function. If collision occurs, the collision counter becomes true.

Next, I make saws move along the x-axis by modifying the saw's x-coordinate by scrollSpeed times dt. I also make saws teleport behind the right screen border when they pass far beyond the left border. I determine the saw's y-coordinate randomly between 200 and 350. I chose this range because a larger range would sometimes spawn saws too high, eliminating the challenge.

I also create a collision box for saws with all properties needed by the `collision()` function. I pass the player and saw collision box to the collision function, and if collision occurs, the collision counter becomes true.

I also establish topSaws, making them move at scrollSpeed times 1.5 because I want them slightly faster. I use a for loop to create collision boxes for every topSaw, then pass the player and collision box to the `collision()` function. If they collide, the collision counter becomes true. I make topSaws teleport behind the right screen border when they pass the left border.

Then I update saw animations so players can see the spinning animation.

Finally, I create a quick death mechanism. If `collision_counter` becomes true, the game stops (scrollSpeed becomes 0), `player.rotation` becomes 1.5 (making it look like falling), `player.anim` becomes death (a single-frame animation), and `player.dead` becomes true.

#### love.draw()
Finally, it's time to handle what the game actually displays to the player. First, we draw the map and a second instance of it for seamless looping. Then, if `gameOn` and `obstaclesInitialized` are true, we draw obstacles. Using information determined in the `love.update` function (number of pairs in groups, spacing between pairs), the game draws spike groups consisting of various spike numbers. We do something very similar for saws and topSaws, but since they don't appear in irregular groups, the code is much more compact.

Then I coded the counter section, starting with the `counter()` function that takes a single argument — num. First, I clear previous elements of the `number.num` table. Then I apply mathematical operations to the num argument to make it an integer for nice screen display (remember, the score is time-based). I also convert this integer to a string and insert every digit into the `number.num` table, then convert it back to a number.

I create a local function called `rightAlignDigits()` that aligns all digits to the right. This ensures the score counter always has six digits, with left-side zeros until the score becomes large enough to change them to other numbers. I then execute the `rightAlignDigits()` function, and the `counter()` function returns the `number.digits` table consisting of all digits from the num argument we passed, plus zeros if the number isn't large enough for all six digits to be non-zero.

Then I check if `timerStarted` is true. As mentioned, this variable becomes true when the player starts the game by pressing Enter. If false, the time variable (used for score determination) is always zero. But if the player isn't dead (by `player.dead` variable), we get a different time variable by subtracting the previously established start time from current time and applying mathematical operations to get an integer:

```lua
if not timerStarted then
    time = 0
else
    if not player.dead then
        t = love.timer.getTime() - start
        time = math.floor(t*100)/100
        time = time*100
    end
end
```

Then I establish an n variable and, using the `counter(time)` function, make n represent elapsed time as a six-item table.

I use a for loop and elseif statements to go through every number in this table and assign it an animation corresponding to the digit. Next, I create a `number:draw()` function taking three arguments: x-coordinate, y-coordinate, and spacing between numbers:

```lua
function number:draw(x, y, spacing)
    for i, key in ipairs(digitNames) do
        local animData = self.anim[key]
        if animData and animData.animation then
            animData.animation:draw(self.spriteSheet, x + (i - 1) * spacing, y, 0, 2.5, 2.5)
        end
    end
end
```

Then I use this function to draw the actual counter.

The player section in `love.draw()` is quite small, consisting of only one line telling the game to draw `player.anim` in its current state.

Finally, comes the menu section. Menu items are only drawn at game start and when the player is dead. I create several elseif statements that draw menu parts when certain conditions are met. I use `credits`, `obstaclesInitialized`, and `player.dead` boolean variables, which change depending on pressed keys or player death status.
