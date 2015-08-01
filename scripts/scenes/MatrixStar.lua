local MatrixStar = class("MatrixStar",function()
	return display.newLayer()
end)

local STAR_RES_LIST = {"blue.png","green.png",
"orange.png","red.png","purple.png"}

HSCORETAG = 100
LEVELTAG = 101
CSCORETAG = 102
SCALE = 1.5
UNNEEDCLEAR = 0
NEEDCLEAR = 1
CLEAROVER = 2
STARTSCORE = 1000
MOVEDELAY = 1.5

local STAR_WIDTH = 48   
local STAR_HEIGHT = 48
local ROW = 10
local COL = 10
local LEFT_STAR = 20    --剩余星星小于该数给予奖励
local STARGAIN = 5      --星星得分基数

local MOVESPEED = 4     --星星的移动速度

function MatrixStar:ctor()
    self.Hscore = 0
    self.Level = 1
    self.Goal = STARTSCORE
    self.Cscore = 0
    self.STAR = {}
    self.SELECT_STAR = {}  --保存颜色相同的星星
    self.clearNeed = UNNEEDCLEAR  -- 是否需要清除剩余的星星
    self:setLabel(self.Hscore,self.Level,self.Goal,self.Cscore)  
	self:initMatrix()  
    self:setTouchEnabled(true)
    
    self:addTouchEventListener(function(event, x, y)
        return self:onTouch(event, x, y) 
    end, false)

end  

function MatrixStar:initMatrix()  
    --[[self.STAR[i][j]是一个表，其中i表示星星矩阵的行，j表示列，它包含四个元素
        self.STAR[i][j][1]表示星星精灵
        self.STAR[i][j][2]表示该精灵的样色 
        self.STAR[i][j][3]表示该精灵是否被选中
        self.STAR[i][j][4]表示该精灵的位置           
        ]]
    math.randomseed(os.time())    
    for row = 1, ROW do
        local y = (row-1) * STAR_HEIGHT + STAR_HEIGHT/2
        self.STAR[row] = {}
        for col = 1, COL do
            self.STAR[row][col] = {}
            local x = (col-1) * STAR_WIDTH + STAR_WIDTH/2
            local i=math.random(1,5)
            local star = display.newSprite(STAR_RES_LIST[i])
            self.STAR[row][col][1] = star
            self.STAR[row][col][2] = i
            self.STAR[row][col][3] = false
            star:setPosition(x,y)
            self.STAR[row][col][4] = x
            self.STAR[row][col][5] = y
            self:addChild(star)
        end
    end
end

function MatrixStar:setLabel(Hscore,Level,Goal,Cscore)
    local HscoreUI = ui.newTTFLabel({
        text = string.format("HighestScore: %s", tostring(Hscore)),
        x, y = display.left, display.top, 
    })
    HscoreUI:setScale(SCALE)
    HscoreUI:setPosition(display.right, display.cy)
    HscoreUI:setPosition(display.cx, display.top - SCALE * HscoreUI:getContentSize().height)
    self:addChild(HscoreUI)
    HscoreUI:setTag(HSCORETAG)

    local LevelUI = ui.newTTFLabel({
        text = string.format("Level: %s".." ".."Goal: %s", tostring(Level),tostring(Goal)),
        x, y = display.left, display.top, 
    })
    LevelUI:setScale(SCALE)
    LevelUI:setPosition(display.cx, display.top - SCALE * (HscoreUI:getContentSize().height + 
            LevelUI:getContentSize().height))
    self:addChild(LevelUI)
    LevelUI:setTag(LEVELTAG)

    local CscoreUI = ui.newTTFLabel({
        text = string.format("CurrentScore: %s", tostring(Cscore)),
        x, y = display.left, display.top, 
    })
    CscoreUI:setScale(SCALE)
    CscoreUI:setPosition(display.cx, display.top - SCALE * (HscoreUI:getContentSize().height + 
            LevelUI:getContentSize().height + CscoreUI:getContentSize().height))
    self:addChild(CscoreUI)
    CscoreUI:setTag(CSCORETAG)
end

function MatrixStar:onTouch(eventType, x, y)  
--    if eventType ~= "began" then return end
    i = math.floor(y / STAR_HEIGHT) + 1
    j = math.floor(x / STAR_WIDTH) + 1

    if i < 1 or i > ROW or j < 1 or j > COL then 
        return 
    end 
    
    self.SELECT_STAR = {}   --将选中的星星清空

    if self:deleteSelectStar() == false then 
        return
    end

    self:updateScore(#self.SELECT_STAR)

    for num = 1, #self.SELECT_STAR do 
        local row , col = self.SELECT_STAR[num][2], self.SELECT_STAR[num][3]
        self:removeChild(self.STAR[row][col][1]) 
        self.STAR[row][col][1] = nil 
    end

    self:UpdateMatrix()
    if self:isEnd() == true then 
        local num = self:getStarNum()
        if num < LEFT_STAR then
            local left = LEFT_STAR - num 
            self.Cscore = self.Cscore + left * left * STARGAIN
        end
        local LeftStar = ui.newTTFLabel({
        text = string.format("There Are  %s Stars Left !", tostring(num)),
        x, y = display.left, display.top, 
        })
        LeftStar:setPosition(display.right, display.cy)
        LeftStar:setScale(SCALE*SCALE)
        self:addChild(LeftStar)
        LeftStar:runAction(transition.sequence({transition.moveTo(LeftStar,
        {time = MOVEDELAY, x = display.left, y = display.cy}),
        CCCallFunc:create(function()
        self:removeChild(LeftStar)
        local CscoreUI = self:getChildByTag(CSCORETAG)
        CscoreUI:setString(string.format("CurrentScore: %s",tostring(self.Cscore)))
        self.clearNeed = NEEDCLEAR
        end)}))
    end
end

function MatrixStar:updateScore(select)
    print(select)
    self.Cscore = self.Cscore + select * select * STARGAIN
    if(self.Cscore > self.Hscore)  then
        self.Hscore = self.Cscore
    end
    local HscoreUI = self:getChildByTag(HSCORETAG)
    HscoreUI:setString(string.format("HighestScore: %s", tostring(self.Hscore)))
    local CscoreUI = self:getChildByTag(CSCORETAG)
    CscoreUI:setString(string.format("CurrentScore: %s", tostring(self.Cscore)))
end

function MatrixStar:deleteSelectStar()
    local travel = {}  --当作一个队列使用，用于选出周围与触摸星星颜色相同的星星
    if self.STAR[i][j][1] == nil then
        return
    end 

    table.insert(travel, {self.STAR[i][j][1], i, j})
    while #travel ~= 0 do
        if i + 1 <= ROW and self.STAR[i][j][3] ~= true and 
            self.STAR[i][j][2] == self.STAR[i + 1][j][2] then
            table.insert(travel, {self.STAR[i+1][j][1],i+1,j})
        end

        if i-1 >= 1 and self.STAR[i][j][3] ~= true and
            self.STAR[i][j][2] ==self.STAR[i-1][j][2] then
            table.insert(travel, {self.STAR[i-1][j][1],i-1,j})
        end

        if j+1 <= COL and self.STAR[i][j][3] ~= true and
            self.STAR[i][j][2] ==self.STAR[i][j+1][2] then
            table.insert(travel, {self.STAR[i][j+1][1],i,j+1}) 
        end

        if j-1 >= 1 and self.STAR[i][j][3] ~= true and
            self.STAR[i][j][2] ==self.STAR[i][j-1][2] then
            table.insert(travel, {self.STAR[i][j-1][1],i,j-1})
        end
        
        if self.STAR[i][j][3] ~= true then
           self.STAR[i][j][3] = true
           table.insert(self.SELECT_STAR,{self.STAR[i][j][1],i,j})
        end

        table.remove(travel,1)  --table没有类似双向队列的功能直接删除第一个元素
        if #travel ~= 0 then 
            i, j = travel[1][2], travel[1][3] --取出表的第一个元素
        end  
    end

    if #self.SELECT_STAR <= 1 then
        self.STAR[i][j][3] = nil 
        self.SELECT_STAR = {}
        return false
    end 
    return true
end

function MatrixStar:updateStar()
    for i = 1, ROW do
        for j = 1, COL do
            if self.STAR[i][j][1] ~= nil then 
                local posX, posY = self.STAR[i][j][1]:getPosition()
                self:updatePos(posX,posY,i,j)
            end
        end
    end

    if self.clearNeed == NEEDCLEAR then 
        if self:ClearLeftStarOneByOne() == true then
            self.clearNeed = CLEAROVER
        end
    end

end

function MatrixStar:ClearLeftStarOneByOne()
    local num = 0
    for i = 1, ROW do
        for j = 1, COL do
            if self.STAR[i][j][1] ~= nil then
                self:removeChild(self.STAR[i][j][1])
                self.STAR[i][j][1] = nil 
                return false
            end
        end
    end
    return true  --表示剩余的星星已经清除完毕  
end

function MatrixStar:updatePos(posX,posY,i,j)
    if posY ~= self.STAR[i][j][5] then
        self.STAR[i][j][1]:setPositionY(self.STAR[i][j][5] - MOVESPEED)
        if self.STAR[i][j][1]:getPositionY() < self.STAR[i][j][5]  then
             self.STAR[i][j][1]:setPositionY(self.STAR[i][j][5])
             local x, y = self.STAR[i][j][1]:getPosition()
        end
    end

    if posX ~= self.STAR[i][j][4] then
        self.STAR[i][j][1]:setPositionX(self.STAR[i][j][4] - MOVESPEED)
        if self.STAR[i][j][1]:getPositionX() < self.STAR[i][j][4]  then
             self.STAR[i][j][1]:setPositionX(self.STAR[i][j][4])
        end
    end
end
function MatrixStar:isEnd()
    for i = 1, ROW do
        for j = 1, COL do
            local color = self.STAR[i][j][2]
            if self.STAR[i][j][1] ~= nil then
                if i+1<=ROW and self.STAR[i+1][j][1] ~= nil and color == self.STAR[i+1][j][2] then
                    return false
                end
                if i-1>=1 and self.STAR[i-1][j][1] ~= nil and color == self.STAR[i-1][j][2] then
                    return false
                end
                if j-1>=1 and self.STAR[i][j-1][1] ~= nil and color == self.STAR[i][j-1][2] then
                    return false
                end
                if j+1<=COL and self.STAR[i][j+1][1] ~= nil and color == self.STAR[i][j+1][2] then
                    return false
                end
            end
        end
    end
    return true
end

function MatrixStar:UpdateMatrix()
    for i = 1, ROW do
        for j = 1,COL do
            if self.STAR[i][j][1] == nil then 
                local up = i
                local dis = 0
                while self.STAR[up][j][1] == nil do
                    dis = dis + 1
                    up = up + 1
                    if(up>ROW) then
                        break
                    end
                end

                for begin_i = i + dis, ROW do
--                    print("test"..tostring(begin_i))
                    if self.STAR[begin_i][j][1]~=nil then 
                        self.STAR[begin_i-dis][j][1]=self.STAR[begin_i][j][1]
                        self.STAR[begin_i-dis][j][2]=self.STAR[begin_i][j][2]
                        self.STAR[begin_i-dis][j][3]=self.STAR[begin_i][j][3]
                        local x = (j-1)*STAR_WIDTH + STAR_WIDTH/2  
                        local y = (begin_i-dis-1)*STAR_HEIGHT + STAR_HEIGHT/2 
                        self.STAR[begin_i-dis][j][4] = x
                        self.STAR[begin_i-dis][j][5] = y
                        self.STAR[begin_i][j][1] = nil
                        self.STAR[begin_i][j][2] = nil
                        self.STAR[begin_i][j][3] = nil
                        self.STAR[begin_i][j][4] = nil
                        self.STAR[begin_i][j][5] = nil
                    end
                end
            end
        end
    end

    for j = 1, COL do
        if self.STAR[1][j][1] == nil then
            local des = 0 
            local right = j
            while self.STAR[1][right][1] == nil do
                des = des + 1
                right = right + 1
                if right>COL then
                    break
                end
            end
            for begin_i = ROW, 1,-1 do
                for begin_j = j + des, COL do 
                    if self.STAR[begin_i][begin_j][1] ~= nil then
                        self.STAR[begin_i][begin_j-des][1]=self.STAR[begin_i][begin_j][1]
                        self.STAR[begin_i][begin_j-des][2]=self.STAR[begin_i][begin_j][2]
                        self.STAR[begin_i][begin_j-des][3]=self.STAR[begin_i][begin_j][3]
                        local x = (begin_j-des-1)*STAR_WIDTH + STAR_WIDTH/2  
                        local y = (begin_i-1)*STAR_HEIGHT + STAR_HEIGHT/2 
                        self.STAR[begin_i][begin_j-des][4] = x
                        self.STAR[begin_i][begin_j-des][5] = y
                        self.STAR[begin_i][begin_j][1] = nil
                        self.STAR[begin_i][begin_j][2] = nil
                        self.STAR[begin_i][begin_j][3] = nil
                        self.STAR[begin_i][begin_j][4] = nil
                        self.STAR[begin_i][begin_j][5] = nil
                    end
                end
            end
        end
    end
end

function MatrixStar:getStarNum()
    local num = 0
    for i = 1, ROW do
        for j = 1, COL do
            if self.STAR[i][j][1] ~= nil then
                num = num + 1
            end
        end
    end
    return num  
end

return MatrixStar