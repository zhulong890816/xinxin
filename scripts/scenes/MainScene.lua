
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
   self.bg = display.newSprite("bg_menuscene.jpg", display.cx,display.cy)
    self:addChild(self.bg)
    local item ={}
    item[1]= ui.newImageMenuItem({image = "menu_start.png", imageSelected = "menu_start.png",
        listener = function()  
        game.enterGameScene() end , x = display.cx, y = display.cy})
    local menu = ui.newMenu(item)
    self:addChild(menu)
end

function MainScene:onEnter()
    if device.platform ~= "android" then return end

    -- avoid unmeant back
    self:performWithDelay(function()
        -- keypad layer, for android
        local layer = display.newLayer()
        layer:addKeypadEventListener(function(event)
            if event == "back" then game.exit() end
        end)
        self:addChild(layer)

        layer:setKeypadEnabled(true)
    end, 0.5)
end

return MainScene
