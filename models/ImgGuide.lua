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

	if (value == nil or xyd.arrayIndexOf(ids, id) < 0) and WindowTable:getImgGuide(name) == 1 and not xyd.GuideController.get():isPlayGuide() then
		self:savaWindowId(id)
		XYDCo.WaitForTime(0.5, function ()
			xyd.WindowManager.get():openWindow("img_guide_window", {
				wndname = name
			})
		end, "")
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

return ImgGuide
