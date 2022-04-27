local BaseWindow = import("app.windows.BaseWindow")
local ActivityEasterEggGachaWindow = class("ActivityEasterEggGachaWindow", BaseWindow)

function ActivityEasterEggGachaWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.parent = params.parent
	self.params = params
	self.costItemType_ = params.item_cost_type or xyd.ItemID.PINK_BALLOON
	self.costNum_ = params.item_cost_num or 1
	self.callbackFunc_ = params.callback
end

function ActivityEasterEggGachaWindow:initWindow()
	ActivityEasterEggGachaWindow.super:initWindow()

	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.title = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.label = self.groupAction:ComponentByName("label", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.selectGroup = self.groupAction:NodeByName("selectGroup").gameObject
	self.btn = self.groupAction:NodeByName("btn").gameObject
	self.btnLabel = self.btn:ComponentByName("button_label", typeof(UILabel))
	self.selectGroup = self.groupAction:NodeByName("selectGroup").gameObject
	self.selectNum_ = import("app.components.SelectNum").new(self.selectGroup, "minmax")
	self.itemLabel = self.groupAction:ComponentByName("itemGroup/label", typeof(UILabel))
	self.itemImg = self.groupAction:ComponentByName("itemGroup/icon", typeof(UISprite))

	self.selectNum_:setKeyboardPos(0, -380)

	self.selectNum_.inputLabel.text = "1"

	self:layout()
	self:RegisterEvent()
end

function ActivityEasterEggGachaWindow:layout()
	self.title.text = __(self.params.label_title) or __("ACTIVITY_EASTER_EGG_OPEN_EGG")
	self.label.text = __(self.params.label_desc) or __("ACTIVITY_EASTER_EGG_OPEN_EGG_NUM")

	if xyd.Global.lang == "fr_fr" and self.params.label_desc then
		self.label.transform:Y(85)
	end

	self.btnLabel.text = __("CONFIRM")

	xyd.setUISpriteAsync(self.itemImg, nil, xyd.tables.itemTable:getIcon(self.costItemType_))

	local function callback(num)
		local showNum = self.costNum_ * num
		self.itemLabel.text = showNum .. "/" .. xyd.models.backpack:getItemNumByID(self.costItemType_)
	end

	self.selectNum_:setInfo({
		minNum = 1,
		curNum = 1,
		maxNum = math.floor(xyd.models.backpack:getItemNumByID(self.costItemType_) / self.costNum_),
		callback = callback
	})
end

function ActivityEasterEggGachaWindow:RegisterEvent()
	UIEventListener.Get(self.btn).onClick = handler(self, function ()
		if self.callbackFunc_ then
			self.callbackFunc_(tonumber(self.selectNum_.inputLabel.text))
			xyd.WindowManager.get():closeWindow(self.name_)
		else
			self.parent.usedItem = tonumber(self.selectNum_.inputLabel.text)
			local msg = messages_pb:open_easter_egg_req()
			msg.num = tonumber(self.selectNum_.inputLabel.text)
			msg.activity_id = xyd.ActivityID.EASTER_EGG

			xyd.Backend.get():request(xyd.mid.OPEN_EASTER_EGG, msg)
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager:get():closeWindow(self.window_.name)
	end
end

return ActivityEasterEggGachaWindow
