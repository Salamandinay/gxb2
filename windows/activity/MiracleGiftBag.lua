local ActivityContent = import(".ActivityContent")
local MiracleGiftBag = class("MiracleGiftBag", ActivityContent)
local MiracleGiftBagItem = class("MiracleGiftBagItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ActivityPartnerMiracleTable = xyd.tables.activityPartnerMiracleTable

function MiracleGiftBag:ctor(parentGO, params, parent)
	ActivityContent.ctor(self, parentGO, params, parent)
end

function MiracleGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/miracle_giftbag"
end

function MiracleGiftBag:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initUIComponent()
	self:setItem()
end

function MiracleGiftBag:getUIComponent()
	local go = self.go
	self.textGroup_ = go:NodeByName("textGroup_").gameObject
	self.textImg = self.textGroup_:ComponentByName("textImg", typeof(UISprite))
	self.textLabel01 = self.textGroup_:ComponentByName("textLabel01", typeof(UILabel))
	self.timeLabel = self.textGroup_:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.textGroup_:ComponentByName("endLabel", typeof(UILabel))
	self.mainGroup = go:NodeByName("mainGroup").gameObject
	self.bottomBg_ = self.mainGroup:ComponentByName("bottomBg_", typeof(UISprite))
	self.scrollView = self.mainGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.miracleItem = self.mainGroup:NodeByName("scroller/miracle_giftbag_item").gameObject
	self.itemGroup = self.mainGroup:NodeByName("scroller/itemGroup").gameObject
end

function MiracleGiftBag:initUIComponent()
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.miracleItem, MiracleGiftBagItem, self)

	xyd.setUISpriteAsync(self.textImg, nil, "miracle_giftbag_text01_" .. xyd.Global.lang, function ()
		self.textImg:MakePixelPerfect()
	end)

	self.endLabel.text = __("TEXT_END")
	self.textLabel01.text = __("MIRACLE_TEXT01")
	local leftTime = self.activityData:getUpdateTime() - xyd.getServerTime()

	if leftTime > 0 then
		local CountDown = import("app.components.CountDown")

		CountDown.new(self.timeLabel, {
			duration = leftTime
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end
end

function MiracleGiftBag:setItem()
	self.items = {}
	local ids = ActivityPartnerMiracleTable:getIDandRks()

	table.sort(ids, function (a, b)
		return a.rk < b.rk
	end)

	for i = 1, #ids do
		local id = ids[i].id
		local is_completed = false

		if ActivityPartnerMiracleTable:getCompleteValue(id) <= self:getPoint(id) then
			is_completed = true
		end

		local is_Important = ids[i].rk == 1
		local item = {
			id = id,
			isCompleted = is_completed,
			isImportant = is_Important,
			point = self:getPoint(id)
		}

		table.insert(self.items, item)
	end

	self.wrapContent:setInfos(self.items, {})
end

function MiracleGiftBag:resizeToParent()
	ActivityContent:resizeToParent()
	self.go:Y(-440)

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "en_en" then
		self.textLabel01.fontSize = 20
	end

	local parentHeight = self.go.transform.parent:GetComponent(typeof(UIPanel)).height
	self.bottomBg_.height = 520 - (869 - parentHeight)

	self.mainGroup:Y(-160 + (869 - parentHeight) / 2)
end

function MiracleGiftBag:getPoint(id)
	return self.activityData.detail.values[id]
end

function MiracleGiftBagItem:ctor(go, parent)
	self.parent_ = parent

	MiracleGiftBagItem.super.ctor(self, go, parent)
end

function MiracleGiftBagItem:initUI()
	local go = self.go
	self.bgDown_ = go:ComponentByName("bgDown_", typeof(UISprite))
	self.bgOn_ = go:ComponentByName("bgOn_", typeof(UISprite))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.labelText = go:ComponentByName("labelText", typeof(UILabel))
	self.progress = go:ComponentByName("progress", typeof(UISlider))
	self.progressLabel = go:ComponentByName("progress/labelDisplay", typeof(UILabel))
end

function MiracleGiftBagItem:updateInfo()
	self.id = self.data.id
	self.isCompleted = self.data.isCompleted
	self.point = self.data.point
	self.isImportant = self.data.isImportant

	self.bgOn_:SetActive(false)

	if self.isImportant then
		self.bgOn_:SetActive(true)
	end

	if xyd.Global.lang ~= "fr_fr" then
		-- Nothing
	end

	self.labelText:Y(3)

	self.labelText.width = 260

	self:setText()
	self:setIcon()
	self:setProgress()
end

function MiracleGiftBagItem:setText()
	if self.isImportant then
		self.labelText.text = __("COMPLETE_ALL_MISSIONS")

		if xyd.Global.lang == "fr_fr" then
			self.labelText.width = 335

			self.labelText:Y(3)
		else
			self.labelText.width = 260

			self.labelText:Y(3)
		end
	else
		local target = ActivityPartnerMiracleTable:getCompleteValue(self.id)
		local partner = xyd.tables.groupTextTable:getName(ActivityPartnerMiracleTable:getGroupType(self.id))
		self.labelText.text = __("GET_PARTNER_WITH_COUNT_GROUP_STAR", target, partner, 5)
	end
end

function MiracleGiftBagItem:setIcon()
	local awards = ActivityPartnerMiracleTable:getAward(self.id)

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = xyd.getItemIcon({
				show_has_num = true,
				labelNumScale = 1.2,
				scale = 0.7,
				uiRoot = self.itemGroup,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent_.scrollView
			})

			if self.isCompleted then
				item:setChoose(true)
			end
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function MiracleGiftBagItem:setProgress()
	local target = ActivityPartnerMiracleTable:getCompleteValue(self.id)
	local gotten = math.min(self.point, ActivityPartnerMiracleTable:getCompleteValue(self.id))
	self.progress.value = gotten / target
	self.progressLabel.text = tostring(gotten) .. "/" .. tostring(target)
end

return MiracleGiftBag
