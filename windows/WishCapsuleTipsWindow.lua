local BaseWindow = import(".BaseWindow")
local WishCapsuleTipsWindow = class("WishCapsuleTipsWindow", BaseWindow)

function WishCapsuleTipsWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function WishCapsuleTipsWindow:initWindow()
	WishCapsuleTipsWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:onRefresh()
end

function WishCapsuleTipsWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.imgText_ = groupAction:ComponentByName("imgText_", typeof(UISprite))
	self.desLabel = groupAction:ComponentByName("desLabel", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local mainGroup = groupAction:NodeByName("mainGroup").gameObject
	self.titleLabel = mainGroup:ComponentByName("titleLabel", typeof(UILabel))
	self.progress = mainGroup:ComponentByName("progress", typeof(UISlider))
	self.progressNum = self.progress:ComponentByName("labelDisplay", typeof(UILabel))
	self.timesLabel = mainGroup:ComponentByName("timesLabel", typeof(UILabel))
	self.probLabel = mainGroup:ComponentByName("probLabel", typeof(UILabel))
	self.showGroup = mainGroup:NodeByName("showGroup").gameObject

	xyd.models.activity:reqActivityByID(xyd.ActivityID.WISH_CAPSULE)
end

function WishCapsuleTipsWindow:initUIComponent()
	xyd.setUISpriteAsync(self.imgText_, nil, "wish_capsule_text02_" .. xyd.Global.lang)

	self.titleLabel.text = __("WISH_GACHA_TEXT6")
	self.timesLabel.text = __("WISH_GACHA_NUM")
	self.probLabel.text = __("WISH_GACHA_CHANCE")
	local wishData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)

	if wishData and wishData.detail and wishData.detail.select_id and wishData.detail.select_id ~= 0 then
		self.desLabel.text = __("WISH_GACHA_TIPS_3", xyd.tables.partnerTextTable:getName(wishData.detail.select_id))
	else
		self.desLabel.text = __("WISH_GACHA_TIPS_3")
	end

	local count = self.showGroup.transform.childCount

	for i = 1, count do
		local group = self.showGroup:NodeByName("group" .. i).gameObject
		group:ComponentByName("num", typeof(UILabel)).text = __("WISH_GACHA_NUM" .. i)

		if i ~= count then
			group:ComponentByName("probNum", typeof(UILabel)).text = __("WISH_GACHA_NUM" .. tostring(i + 5))
		end
	end

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	if xyd.Global.lang == "en_en" then
		self.desLabel:Y(185)

		self.desLabel.spacingY = 5
		self.desLabel.fontSize = 17

		self.timesLabel:X(-255)
	elseif xyd.Global.lang == "fr_fr" then
		self.desLabel:Y(195)

		self.desLabel.spacingY = 5
		self.desLabel.width = 560

		self.timesLabel:X(-255)
	elseif xyd.Global.lang == "de_de" then
		self.desLabel.fontSize = 17
	end
end

function WishCapsuleTipsWindow:onRefresh()
	self.progress.value = self.params_.times / tonumber(__("WISH_GACHA_NUM5"))
	self.progressNum.text = self.params_.times .. "/" .. __("WISH_GACHA_NUM5")
end

return WishCapsuleTipsWindow
