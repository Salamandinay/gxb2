local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ActivityGoldfishAwards = class("ActivityGoldfishAwards", ActivityContent)
local ActivityGoldfishAwardsItem = class("ValueGiftBagItem", import("app.components.CopyComponent"))

function ActivityGoldfishAwards:ctor(parentGO, params, parent)
	ActivityGoldfishAwards.super.ctor(self, parentGO, params, parent)
end

function ActivityGoldfishAwards:getPrefabPath()
	return "Prefabs/Windows/activity/activity_goldfish_awards"
end

function ActivityGoldfishAwards:initUI()
	self:getUIComponent()
	ActivityGoldfishAwards.super.initUI(self)
	self:initUIComponent()
end

function ActivityGoldfishAwards:getUIComponent()
	local go = self.go
	self.activityGroup = go:NodeByName("main").gameObject
	self.textImg = self.activityGroup:ComponentByName("textImg", typeof(UISprite))
	self.textLabel = self.activityGroup:ComponentByName("textLabel", typeof(UILabel))
	self.timerGroup = self.activityGroup:NodeByName("timerGroup").gameObject
	self.timeLabel = self.timerGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timerGroup:ComponentByName("endLabel", typeof(UILabel))
	self.scroller = self.activityGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollerPanel = self.activityGroup:ComponentByName("scroller", typeof(UIPanel))
	self.scrollerPanel.depth = self.scrollerPanel.depth + 1
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.groupItem_uigrid = self.groupItem:GetComponent(typeof(UIGrid))
	self.costLabel = self.activityGroup:ComponentByName("costGroup/label", typeof(UILabel))
	self.costBtn = self.activityGroup:NodeByName("costGroup/btn").gameObject
	self.itemCell = go:NodeByName("itemCell").gameObject
	self.partnerGroup = self.activityGroup:NodeByName("partnerGroup").gameObject
end

function ActivityGoldfishAwards:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "goldfish_awards_title_" .. xyd.Global.lang, nil, )
	self:setText()

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GOLDFISH)

	if activityData:checkNeedUpdate() then
		xyd.models.activity:reqActivityByID(self.id)
		self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.setItem))
	else
		self:setItem()
	end

	self:setEffect()
	self:eventRegister()

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end
end

function ActivityGoldfishAwards:setEffect()
	if xyd.isIosTest() then
		local partner = NGUITools.AddChild(self.mainGroup, "partner"):AddComponent(typeof(UITexture))

		xyd.setUITextureAsync(partner, "Textures/partner_picture_web/partner_picture_11001")

		partner.depth = 2
		partner.height = 1000
		partner.width = 1000

		partner:Y(-250)
	else
		local effect = xyd.Spine.new(self.partnerGroup.gameObject)

		effect:setInfo("kaixi_pifu04_lihui01", function ()
			effect:setRenderTarget(self.partnerGroup:GetComponent(typeof(UITexture)), 3)
			effect:SetLocalScale(0.46, 0.46, 0.46)
			effect:SetLocalPosition(0, -474 + 6 * self.scale_num_contrary, 0)
			effect:play("animation", 0)
		end)
	end
end

function ActivityGoldfishAwards:setText()
	if xyd.Global.lang == "de_de" then
		self.textLabel.width = 450
	end

	self.endLabel.text = __("TEXT_END")
	self.costLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.FISHING_NET)
end

function ActivityGoldfishAwards:setItem()
	local ids = xyd.tables.activityGoldfishAwardTable:getIDs()
	local awards = {}

	for i = 1, #ids do
		table.insert(awards, {
			awards = xyd.tables.activityGoldfishAwardTable:getAwards(ids[i]),
			point = xyd.tables.activityGoldfishAwardTable:getPoint(ids[i]),
			curPoint = self.activityData.detail.times
		})
	end

	table.sort(awards, function (a, b)
		local maxPoint = xyd.tables.activityGoldfishAwardTable:getPoint(xyd.tables.activityGoldfishAwardTable:getIDs()[#xyd.tables.activityGoldfishAwardTable:getIDs()])

		dump(a)

		if a.point <= a.curPoint == (b.point <= b.curPoint) then
			return a.point < b.point
		else
			return a.curPoint < a.point
		end
	end)
	NGUITools.DestroyChildren(self.groupItem.transform)

	for i in ipairs(awards) do
		local tmp = NGUITools.AddChild(self.groupItem, self.itemCell)
		local item = ActivityGoldfishAwardsItem.new(tmp, awards[i], self.scroller)
	end

	self.groupItem_uigrid:Reposition()
	self.itemCell:SetActive(false)
end

function ActivityGoldfishAwards:eventRegister()
	UIEventListener.Get(self.costBtn).onClick = function ()
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_GOLDFISH),
			select = xyd.ActivityID.ACTIVITY_GOLDFISH
		})
	end
end

function ActivityGoldfishAwards:resizeToParent()
	ActivityGoldfishAwards.super.resizeToParent(self)
end

function ActivityGoldfishAwardsItem:ctor(goItem, itemdata, scroller)
	self.goItem_ = goItem
	self.scrollerView = scroller
	local transGo = goItem.transform
	self.imgbg = transGo:ComponentByName("e:Image", typeof(UITexture))
	self.progressBar_ = transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.labelTitle_ = transGo:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup_ = transGo:Find("itemsGroup")

	self:initItem(itemdata)
end

function ActivityGoldfishAwardsItem:initItem(itemdata)
	self.progressBar_.value = math.min(itemdata.point, itemdata.curPoint) / itemdata.point
	local max = itemdata.point

	if max <= itemdata.curPoint then
		print("goldfish_awards_bar_thumb_2")
		xyd.setUISpriteAsync(self.progressImg, nil, "goldfish_awards_bar_thumb_2")
	else
		print("goldfish_awards_bar_thumb")
		xyd.setUISpriteAsync(self.progressImg, nil, "goldfish_awards_bar_thumb")
	end

	self.progressDesc.text = math.min(max, itemdata.curPoint) .. "/" .. max

	if xyd.Global.lang == "fr_fr" then
		self.labelTitle_.fontSize = 22
	end

	self.labelTitle_.text = __("ACTIVITY_GOLDFISH_AWARD_TEXT01", itemdata.point)

	for _, reward in pairs(itemdata.awards) do
		local params = {
			show_has_num = true,
			showGetWays = false,
			isActiveFrameEffect = false,
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_.gameObject,
			dragScrollView = self.scrollerView,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		if xyd.tables.itemTable:getIcon(params.itemID) == "artfact_115" then
			params.isNew = true
		end

		local icon = xyd.getItemIcon(params)

		icon:setScale(0.7)

		if itemdata.point <= itemdata.curPoint then
			icon:setChoose(true)
		end
	end
end

return ActivityGoldfishAwards
