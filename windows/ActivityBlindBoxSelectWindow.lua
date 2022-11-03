local ActivityBlindBoxSelectWindow = class("ActivityBlindBoxSelectWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local AwardItem = class("AwardItem", import("app.components.CopyComponent"))
local cjson = require("cjson")

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
	self.selectedList = {}
	self.selectedNum = 0
	self.maxSelectNum = xyd.tables.miscTable:split2num("activity_blind_box_select_num", "value", "|")[type_ - 1]

	self.go:SetActive(true)

	self.labelRound_.text = __("ACTIVITY_BLIND_BOX_TEXT04", type_ - 1, self.maxSelectNum)
	local itemData = xyd.tables.activityBlindBoxTable:getAwardsIDList(cycle, type_)

	for i = 1, #itemData do
		local awardItem = xyd.tables.activityBlindBoxTable:getAwards(itemData[i])
		local icon = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7962962962962963,
			uiRoot = self.itemGrid_.gameObject,
			itemID = awardItem[1],
			num = awardItem[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent_.scrollView_
		})

		UIEventListener.Get(icon:getGameObject()).onClick = function ()
			if icon:getChoose() then
				self.selectedList[i] = 0
				self.selectedNum = self.selectedNum - 1

				icon:setChoose(false)
			else
				if self.maxSelectNum <= self.selectedNum then
					return
				end

				self.selectedList[i] = itemData[i]
				self.selectedNum = self.selectedNum + 1

				icon:setChoose(true)
			end
		end
	end
end

function ActivityBlindBoxSelectWindow:ctor(name, params)
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_BLIND_BOX)

	ActivityBlindBoxSelectWindow.super.ctor(self, name, params)
end

function ActivityBlindBoxSelectWindow:initWindow()
	self:getUIComponent()
	self:titleLanguage()
	self:layout()
end

function ActivityBlindBoxSelectWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleBg_ = winTrans:ComponentByName("titleBg", typeof(UISprite))
	self.contentGroup_ = winTrans:NodeByName("contentGroup").gameObject
	self.scrollView_ = self.contentGroup_:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = self.contentGroup_:ComponentByName("scrollView/grid", typeof(UILayout))
	self.item_ = self.contentGroup_:NodeByName("awardItem").gameObject
	self.selectBtn_ = winTrans:NodeByName("selectBtn").gameObject
	self.btnLabel_ = self.selectBtn_:ComponentByName("label", typeof(UILabel))

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function ActivityBlindBoxSelectWindow:titleLanguage()
	xyd.setUISpriteAsync(self.titleBg_, nil, "activity_blind_box_select_text_" .. xyd.Global.lang)

	if xyd.Global.lang == "zh_tw" then
		self.titleBg_.width = 142
		self.titleBg_.height = 48
	end

	if xyd.Global.lang == "ja_jp" then
		self.titleBg_.width = 206
		self.titleBg_.height = 48
	end

	if xyd.Global.lang == "ko_kr" then
		self.titleBg_.width = 155
		self.titleBg_.height = 46
	end

	if xyd.Global.lang == "en_en" then
		self.titleBg_.width = 183
		self.titleBg_.height = 69
	end

	if xyd.Global.lang == "fr_fr" then
		self.titleBg_.width = 229
		self.titleBg_.height = 71
	end

	if xyd.Global.lang == "de_de" then
		self.titleBg_.width = 198
		self.titleBg_.height = 75
	end
end

function ActivityBlindBoxSelectWindow:layout()
	self.btnLabel_.text = __("CONFIRM")
	local pointStage = xyd.tables.activitySandSearchAwardTable:getPointStage()
	local idList = {}
	self.missionItems = {}

	for i = 2, 5 do
		local params = {
			self.activityData.detail_.round,
			i
		}

		table.insert(idList, params)

		local itemRootNew = NGUITools.AddChild(self.grid_.gameObject, self.item_)
		self.missionItems[i] = AwardItem.new(itemRootNew, self)

		self.missionItems[i]:update(nil, params)
	end

	UIEventListener.Get(self.selectBtn_).onClick = function ()
		local selects = {}

		for i = 2, 5 do
			for _, j in pairs(self.missionItems[i].selectedList) do
				if j ~= 0 then
					table.insert(selects, j)
				end
			end
		end

		if #selects == 8 then
			local params = cjson.encode({
				type = 1,
				selects = selects
			})

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_BLIND_BOX, params)
			self:close()
		else
			xyd.alertTips(__("ACTIVITY_BLIND_BOX_TEXT10"))
		end
	end
end

return ActivityBlindBoxSelectWindow
