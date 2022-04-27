local BaseWindow = import("app.windows.BaseWindow")
local SproutsGachaWindow = class("SproutsGachaWindow", BaseWindow)

function SproutsGachaWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.type_ = xyd.ItemID.SPROUTS_ITEM
end

function SproutsGachaWindow:initWindow()
	SproutsGachaWindow.super:initWindow()

	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.title = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.selectGroup = self.groupAction:NodeByName("selectGroup").gameObject
	self.btn = self.groupAction:NodeByName("btn").gameObject
	self.btnLabel = self.btn:ComponentByName("button_label", typeof(UILabel))
	self.selectGroup = self.groupAction:NodeByName("selectGroup").gameObject
	self.selectNum_ = import("app.components.SelectNum").new(self.selectGroup, "minmax")

	self.selectNum_:setKeyboardPos(0, -380)

	self.icon = self.groupAction:NodeByName("icon").gameObject
	self.iconItem = xyd.getItemIcon({
		scale = 1,
		itemID = self.type_,
		uiRoot = self.icon
	})

	self:layout()
	self:RegisterEvent()
end

function SproutsGachaWindow:layout()
	self.title.text = __("ACTIVITY_SPROUTS_BTN_WATER")
	self.btnLabel.text = __("CONFIRM")

	local function callback(num)
	end

	self.selectNum_:setInfo({
		clearNotCallback = true,
		minNum = 1,
		notCallback = true,
		curNum = 1,
		maxNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.SPROUTS_ITEM),
		callback = callback,
		maxCallback = function ()
		end
	})
end

function SproutsGachaWindow:RegisterEvent()
	UIEventListener.Get(self.btn).onClick = handler(self, function ()
		if xyd.models.backpack:getItemNumByID(xyd.ItemID.SPROUTS_ITEM) ~= 0 then
			local params = require("cjson").encode({
				num = tonumber(self.selectNum_.inputLabel.text)
			})

			dump(tonumber(self.selectNum_.inputLabel.text))
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.SPROUTS, params)
			xyd.WindowManager.get():closeWindow(self.window_.name)

			if xyd.WindowManager.get():isOpen("item_tips_window") then
				xyd.WindowManager.get():closeWindow("item_tips_window")
			end
		else
			xyd.alertTips(__("SHELTER_NOT_ENOUGH_MATERIAL"))
		end
	end)
end

return SproutsGachaWindow
