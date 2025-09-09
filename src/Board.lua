--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}

function Board:init(x, y)
    self.x = x
    self.y = y
    self.matches = {}

    self.colorOfTile = {}
    for i = 1, 8 do
        self.colorOfTile[i] = math.random(18)
    end

    self:initializeTiles()
end

function Board:initializeTiles()
    self.tiles = {}   

    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        for tileX = 1, 8 do
            
            -- create a new tile at X,Y with a random color and variety          
            table.insert(self.tiles[tileY], Tile(tileX, tileY, self.colorOfTile[math.random(8)], gameState.level > 6 and math.random(1, 6) or math.random(1, gameState.level)))
        end
    end

    while self:calculateMatches() do
        
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initializeTiles()
    end

    -- regenerate the board if no matches are checked
    if not self:checkMatches() then
        self:initializeTiles()
    end
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}
                    local checkShiny = false

                    -- go backwards from here by matchNum
                    for x2 = x - 1, x - matchNum, -1 do
                        
                        -- add each tile to the match that's in that match
                        table.insert(match, self.tiles[y][x2])

                        if self.tiles[y][x2].isShiny then
                            checkShiny = true
                        end
                    end

                    if checkShiny then
                        for x2 = 1, x - matchNum - 1 do
                            table.insert(match, self.tiles[y][x2])
                        end

                        for x2 = 8, x, -1 do
                            table.insert(match, self.tiles[y][x2])
                        end
                    end


                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}
            local checkShiny = false
            
            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
                if self.tiles[y][x].isShiny then
                    checkShiny = true
                end
            end

            if checkShiny then
                for x2 = 1, 8 - matchNum do
                    table.insert(match, self.tiles[y][x2])
                end
            end

            table.insert(matches, match)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    for y2 = y - 1, y - matchNum, -1 do
                        table.insert(match, self.tiles[y2][x])
                    end

                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
            end

            table.insert(matches, match)
        end
    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- new tile with random color and variety
                local tile = Tile(x, y, self.colorOfTile[math.random(8)], gameState.level > 6 and math.random(1, 6) or math.random(1, gameState.level))
                tile.y = -32
                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end

function Board:checkMatches()
    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    return true
                end

                -- if we have a match of 2 then check the 6 surrounding tiles are next to, above and below the 2 tiles next to the 2 tiles of the same color
                if matchNum == 2 then
                    local offsets = {
                        {y = y, x = x + 1},
                        {y = y, x = x - matchNum - 2},
                        {y = y + 1, x = x},
                        {y = y + 1, x = x - matchNum - 1},
                        {y = y - 1, x = x},
                        {y = y - 1, x = x - matchNum - 1}
                    }

                    for _, offset in pairs(offsets) do
                        if offset.y > 0 and offset.y <= 8 and offset.x > 0 and offset.x <= 8 then
                            if checkIfTwoSameColorTiles(self.tiles[offset.y][offset.x], self.tiles[y][x - 1]) then 
                                return true
                            end
                        end
                    end
                end

                -- check out the plus sign tiles
                if (x - 2) > 0 then
                    if self.tiles[y][x - 2].color == colorToMatch then
                        if (y - 1) > 0 then
                            if self.tiles[y - 1][x - 1].color == colorToMatch then
                                return true
                            end
                        end
                        if (y + 1) <= 8 then
                            if self.tiles[y + 1][x - 1].color == colorToMatch then
                                return true
                            end
                        end
                    end
                end

                matchNum = 1
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            return true
        end

        -- check the tiles to the left of last row
        if matchNum == 2 then
            local offsets = {
                {y = y, x = 8 - matchNum - 1},
                {y = y + 1, x = 8 - matchNum},
                {y = y - 1, x = 8 - matchNum}
            }

            for _, offset in pairs(offsets) do
                if offset.y > 0 and offset.y <= 8 and offset.x > 0 then
                    if checkIfTwoSameColorTiles(self.tiles[offset.y][offset.x], self.tiles[y][8]) then
                        return true
                    end
                end
            end
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    return true
                end

                if matchNum == 2 then
                    local offsets = {
                        {y = y + 1, x = x},
                        {y = y - matchNum - 2, x = x},
                        {y = y, x = x + 1},
                        {y = y - matchNum - 1, x = x + 1},
                        {y = y, x = x - 1},
                        {y = y - matchNum - 1, x = x - 1}
                    }
                    
                    for _, offset in ipairs(offsets) do
                        if offset.y > 0 and offset.y <= 8 and offset.x > 0 and offset.x <= 8 then
                            if checkIfTwoSameColorTiles(self.tiles[offset.y][offset.x], self.tiles[y - 1][x]) then
                                return true
                            end
                        end
                    end
                end

                -- check out the plus sign tiles
                if (y - 2) > 0 then
                    if self.tiles[y - 2][x].color == colorToMatch then
                        if (x - 1) > 0 and (x + 1) <= 8 then
                            if self.tiles[y - 1][x - 1].color == colorToMatch then
                                return true
                            end
                            if self.tiles[y - 1][x + 1].color == colorToMatch then
                                return true
                            end
                        end
                    end
                end

                matchNum = 1
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            return true
        end

        -- check the tiles to the above of last column
        if matchNum == 2 then
            local offsets = {
                {y = 8 - matchNum - 1, x = x},
                {y = 8 - matchNum, x = x + 1},
                {y = 8 - matchNum, x = x - 1}
            }
            
            for _, offset in ipairs(offsets) do
                if offset.y > 0 and offset.x > 0 and offset.x <= 8 then
                    if checkIfTwoSameColorTiles(self.tiles[offset.y][offset.x], self.tiles[8][x]) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function checkIfTwoSameColorTiles(tile1, tile2)
    -- check if tile1 is nil or not
    if tile1 then
        -- if tile1 is not nil
        return tile1.color == tile2.color
    else
        return false
    end
end

