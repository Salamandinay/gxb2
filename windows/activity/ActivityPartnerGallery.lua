local ActivityPartnerGallery = class("ActivityPartnerGallery", import(".ActivityContent"))
local AwardItem = class("AwardItem")
local cjson = require("cjson")

function ActivityPartnerGallery:ctor(parentGo, params, parent)
	ActivityPartnerGallery.super.ctor(self, parentGo, params, parent)
end

function ActivityPartnerGallery:getPrefabPath()
	return "Prefabs/Windows/activity/activity_partner_gallery"
end

function ActivityPartnerGallery:resizeToParent()
	ActivityPartnerGallery.super.resizeToParent(self)
	self.textLogo:Y(-102 + -42 * self.scale_num_contrary)
	self.labelDesc:Y(-245 + -115 * self.scale_num_contrary)
	self.helpBtn:Y(-32 + -4 * self.scale_num_contrary)
end

function ActivityPartnerGallery:initUI()
	self:getUIComponent()
	ActivityPartnerGallery.super.initUI(self)
	self:layout()
end

function ActivityPartnerGallery:getUIComponent()
	local go = self.go
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.textLogo = go:ComponentByName("textLogo", typeof(UISprite))
	self.labelTime = self.textLogo:ComponentByName("timeGroup/labelTime", typeof(UILabel))
	self.labelEnd = self.textLogo:ComponentByName("timeGroup/labelEnd", typeof(UILabel))
	self.labelDesc = go:ComponentByName("labelDesc", typeof(UILabel))
	local bot = go:NodeByName("bot").gameObject
	self.scroller = bot:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = self.scroller:NodeByName("groupContent").gameObject
	self.itemRoot = bot:NodeByName("itemRoot").gameObject
	self.detailBtn = bot:NodeByName("detailBtn").gameObject
	self.labelDetail = self.detailBtn:ComponentByName("labelDetail", typeof(UILabel))
end

function ActivityPartnerGallery:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "apg_logo_" .. xyd.Global.lang)

	self.labelEnd.text = __("END")
	self.labelDesc.text = __("ACTIVITY_PARTNER_GALLERY_TIP")
	self.labelDetail.text = __("ACTIVITY_PARTNER_GALLERY_CHECK")

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_PARTNER_GALLERY_HELP"
		})
	end

	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.labelTime:SetActive(false)
		self.labelEnd:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.labelTime)

		timeCount:setInfo({
			function ()
				xyd.WindowManager.get():closeWindow("activity_window")
			end,
			duration = duration
		})
	end

	local ids = xyd.tables.activityPartnerGalleryAwardTable:getIDs()
	local detail = self.activityData.detail_
	self.awardItemList = {}
	local sortList = {}

	for _, id in ipairs(ids) do
		table.insert(sortList, {
			id = id,
			score = detail.score,
			isAward = detail.awards[id] == 1,
			scrollerView = self.scroller,
			needPoint = xyd.tables.activityPartnerGalleryAwardTable:getPoint(id)
		})
	end

	table.sort(sortList, function (a, b)
		local weightA = a.id
		local weightB = b.id

		if a.score < a.needPoint then
			weightA = weightA + 10
		elseif a.isAward then
			weightA = weightA + 100
		end

		if b.score < b.needPoint then
			weightB = weightB + 10
		elseif b.isAward then
			weightB = weightB + 100
		end

		return weightA < weightB
	end)

	for _, item in ipairs(sortList) do
		local tmp = NGUITools.AddChild(self.groupContent, self.itemRoot)
		local awardItem = AwardItem.new(tmp, self, item)

		table.insert(self.awardItemList, awardItem)
	end

	self:waitForFrame(1, function ()
		self.scroller:ResetPosition()
	end)

	UIEventListener.Get(self.detailBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_partner_gallery_detail_window", {
			score = detail.score
		})
	end
end

function ActivityPartnerGallery:getAward(awards)
	local items = {}

	for _, data in pairs(awards) do
		table.insert(items, {
			item_id = data[1],
			item_num = data[2]
		})
	end

	xyd.models.itemFloatModel:pushNewItems(items)
end

function AwardItem:ctor(go, parent, params)
	self.go = go
	self.parent = parent
	self.params = params

	self:getUIComponent()
	self:layout()
end

function AwardItem:getUIComponent()
	self.awardGroup = self.go:NodeByName("awardGroup").gameObject
	self.tipsLabel = self.go:ComponentByName("tipsLabel", typeof(UILabel))
	self.valueLabel = self.go:ComponentByName("valueLabel", typeof(UILabel))
	self.awardBtn = self.go:NodeByName("awardBtn").gameObject
	self.awardBtnLabel = self.awardBtn:ComponentByName("label", typeof(UILabel))
	self.awardBtnGrey = self.go:NodeByName("awardBtnGrey").gameObject
	self.awardBtnGreyLabel = self.awardBtnGrey:ComponentByName("label", typeof(UILabel))
	self.awardImg = self.go:ComponentByName("awardImg", typeof(UISprite))
end

function AwardItem:layout()
	local aTable = xyd.tables.activityPartnerGalleryAwardTable
	local needPoint = self.params.needPoint
	self.tipsLabel.text = __("ACTIVITY_PARTNER_GALLERY_AWARD", needPoint)
	self.valueLabel.text = "(" .. self.params.score .. "/" .. needPoint .. ")"
	self.awardBtnLabel.text = __("GET2")
	self.awardBtnGreyLabel.text = __("GET2")
	local awards = aTable:getAwards(self.params.id)
	self.itemList = {}

	for _, data in ipairs(awards) do
		local item = xyd.getItemIcon({
			scale = 0.7962962962962963,
			uiRoot = self.awardGroup,
			itemID = data[1],
			num = tonumber(data[2]),
			dragScrollView = self.params.scrollerView
		})

		table.insert(self.itemList, item)
	end

	xyd.setUISpriteAsync(self.awardImg, nil, "mission_awarded_" .. xyd.Global.lang)

	if self.params.score < needPoint then
		self.awardBtnGrey:SetActive(true)
		self.awardBtn:SetActive(false)
		self.awardImg:SetActive(false)
	elseif self.params.isAward then
		self.awardBtnGrey:SetActive(false)
		self.awardBtn:SetActive(false)
		self.awardImg:SetActive(true)
		self:setAwardItemGrey()
	else
		self.awardBtnGrey:SetActive(false)
		self.awardBtn:SetActive(true)
		self.awardImg:SetActive(false)
	end

	UIEventListener.Get(self.awardBtn).onClick = function ()
		local params = cjson.encode({
			table_id = tonumber(self.params.id)
		})

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_PARTNER_GALLERY, params)
		xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_PARTNER_GALLERY):getAward(self.params.id)
		self.awardImg:SetActive(true)
		self.awardBtn:SetActive(false)
		self:setAwardItemGrey()
		self.parent:getAward(awards)
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_PARTNER_GALLERY, function ()
		end)
	end

	xyd.setDragScrollView(self.awardBtn, self.params.scrollerView)
end

function AwardItem:setAwardItemGrey()
	for _, item in ipairs(self.itemList) do
		item:setChoose(true)
	end
end

return ActivityPartnerGallery
