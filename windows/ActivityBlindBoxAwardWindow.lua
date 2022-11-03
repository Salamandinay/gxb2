local ActivityBlindBoxAwardWindow = class("ActivityBlindBoxAwardWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local AwardItem = class("AwardItem", import("app.components.CopyComponent"))

function AwardItem:ctor(go, parent)
	self.parent_ = parent
	self.itemList_ = {}

	AwardItem.super.ctor(self, go)
end

function AwardItem:initUI()
	AwardItem.super.initUI(self)
	self:getUIComponent()
end

function AwardItem:getUIComponent()
	local goTrans = self.go.transform
	self.labelRound_ = goTrans:ComponentByName("labelRound", typeof(UILabel))
	self.itemGrid_ = goTrans:ComponentByName("itemGrid1", typeof(UIGrid))
end

function AwardItem:update(_, params)
	if not params then
		self.go:SetActive(false)

		return
	end

	local cycle = params[1]
	local type_ = params[2]

	self.go:SetActive(true)

	if type_ == 1 then
		self.labelRound_.text = __("ACTIVITY_BLIND_BOX_TEXT09", cycle)
	else
		self.labelRound_.text = __("ACTIVITY_BLIND_BOX_TEXT05", cycle, type_ - 1)
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelRound_.fontSize = 19
	end

	local itemData = xyd.tables.activityBlindBoxTable:getAwardsList(cycle, type_)

	for i = 1, #itemData do
		local awardItem = itemData[i]

		xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7962962962962963,
			uiRoot = self.itemGrid_.gameObject,
			itemID = awardItem[1],
			num = awardItem[2],
			dragScrollView = self.parent_.scrollView_
		})
	end

	self.itemGrid_:Reposition()
end

function ActivityBlindBoxAwardWindow:ctor(name, params)
	ActivityBlindBoxAwardWindow.super.ctor(self, name, params)
end

function ActivityBlindBoxAwardWindow:initWindow()
	self:getUIComponent()
	self:titleLanguage()
	self:layout()
end

function ActivityBlindBoxAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleBg_ = winTrans:ComponentByName("titleBg", typeof(UISprite))
	self.contentGroup_ = winTrans:NodeByName("contentGroup").gameObject
	self.scrollView_ = self.contentGroup_:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = self.contentGroup_:ComponentByName("scrollView/grid", typeof(UILayout))
	self.item_ = self.contentGroup_:NodeByName("awardItem").gameObject

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function ActivityBlindBoxAwardWindow:titleLanguage()
	xyd.setUISpriteAsync(self.titleBg_, nil, "activity_blind_box_award_text_" .. xyd.Global.lang)

	if xyd.Global.lang == "zh_tw" then
		self.titleBg_.width = 144
		self.titleBg_.height = 48
	end

	if xyd.Global.lang == "ja_jp" then
		self.titleBg_.width = 206
		self.titleBg_.height = 48
	end

	if xyd.Global.lang == "ko_kr" then
		self.titleBg_.width = 219
		self.titleBg_.height = 46
	end

	if xyd.Global.lang == "en_en" then
		self.titleBg_.width = 261
		self.titleBg_.height = 44
	end

	if xyd.Global.lang == "fr_fr" then
		self.titleBg_.width = 273
		self.titleBg_.height = 76
	end

	if xyd.Global.lang == "de_de" then
		self.titleBg_.width = 198
		self.titleBg_.height = 74
	end
end

function ActivityBlindBoxAwardWindow:layout()
	local pointStage = xyd.tables.activitySandSearchAwardTable:getPointStage()
	local idList = {}
	self.awardItems = {}

	for i = 1, 2 do
		for j = 1, 5 do
			local params = {
				i,
				j
			}
			local itemRootNew = NGUITools.AddChild(self.grid_.gameObject, self.item_)
			self.awardItems[i] = AwardItem.new(itemRootNew, self)

			self.awardItems[i]:update(nil, params)
		end
	end

	self.scrollView_:ResetPosition()
end

return ActivityBlindBoxAwardWindow
