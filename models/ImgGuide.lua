local BaseModel = import(".BaseModel")
local ImgGuide = class("ImgGuide", BaseModel)
local json = require("cjson")
local WindowTable = xyd.tables.windowTable

function ImgGuide:ctor()
	ImgGuide.super.ctor(self)
end

function ImgGuide:onRegister()
	BaseModel:onRegister()
	self:registerEventInner(xyd.event.WINDOW_WILL_OPEN, handler(self, self.onWindowOpen))
end

function ImgGuide:onWindowOpen(event)
	local name = event.params.windowName
	local id = WindowTable:getRecordID(name)
	local value = xyd.db.misc:getValue("imgGuide" .. tostring(xyd.Global.playerID))
	local ids = nil

	if value then
		ids = json.decode(value)
	end

	if WindowTable:getImgGuide(name) == 1 and not xyd.GuideController.get():isPlayGuide() then
		local isBack = self:checkArenaWindow(name)

		if isBack then
			return true
		end

		if value == nil or xyd.arrayIndexOf(ids, id) < 0 then
			self:savaWindowId(id)
			XYDCo.WaitForTime(0.5, function ()
				xyd.WindowManager.get():openWindow("img_guide_window", {
					wndname = name
				})
			end, "")
		end
	end
end

function ImgGuide:savaWindowId(id)
	local value = xyd.db.misc:getValue("imgGuide" .. tostring(xyd.Global.playerID))
	local ids = {}

	if value then
		ids = json.decode(value)
	end

	table.insert(ids, id)
	xyd.db.misc:setValue({
		key = "imgGuide" .. tostring(xyd.Global.playerID),
		value = json.encode(ids)
	})
end

function ImgGuide:removeEvents()
	BaseModel:removeEvents()
end

function ImgGuide:checkArenaWindow(name)
	if name == "arena_window" and xyd.models.arena:getIsOld() ~= nil then
		local value = xyd.db.misc:getValue("new_arena_window_tips")

		if not value then
			local ArenaHelpTipsItems = import("app.components.ArenaHelpTipsItems")
			self.arenaHelpTipsItems = ArenaHelpTipsItems.new()

			xyd.WindowManager.get():openWindow("img_guide_window", {
				totalPage = 1,
				items = {
					self.arenaHelpTipsItems.ArenaHelpTipsItem1
				}
			})
			xyd.db.misc:setValue({
				value = 1,
				key = "new_arena_window_tips"
			})
		end

		return true
	end

	return false
end

return ImgGuide
