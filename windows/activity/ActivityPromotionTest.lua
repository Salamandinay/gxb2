local ActivityPromotionTest = class("ActivityPromotionTest", import(".ActivityContent"))
local AdvanceIcon = import("app.components.AdvanceIcon")
local ActivityPromotionTestItem = class("ActivityPromotionTestItem", import("app.components.CopyComponent"))
local json = require("cjson")
local CountDown = import("app.components.CountDown")

function ActivityPromotionTest:ctor(parentGO, params)
	ActivityPromotionTest.super.ctor(self, parentGO, params)
end

function ActivityPromotionTest:getPrefabPath()
	return "Prefabs/Windows/activity/activity_promotion_test"
end

function ActivityPromotionTest:resizeToParent()
	ActivityPromotionTest.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874

	self:resizePosY(self.imgTitle, 265, 262)
	self:resizePosY(self.bottomGroup, 33, -146)
	self:resizePosY(self.resourceGroup, 73, -105)
end

function ActivityPromotionTest:initUI()
	self.ResItemID = 342
	self.items = {}
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_PROMOTION_TEST)

	self:getUIComponent()
	ActivityPromotionTest.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityPromotionTest:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.imgTitle = self.groupAction:ComponentByName("imgTitle", typeof(UISprite))
	self.partnerImg_ = self.groupAction:ComponentByName("partnerImg_", typeof(UISprite))
	self.Bg_ = self.groupAction:ComponentByName("Bg_", typeof(UITexture))
	self.Bg1_ = self.groupAction:ComponentByName("Bg1_", typeof(UISprite))
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
	self.bubble = self.groupAction:ComponentByName("bubble", typeof(UISprite))
	self.labelBubble = self.bubble:ComponentByName("labelBubble", typeof(UILabel))
	self.resourceGroup = self.groupAction:NodeByName("resourceGroup").gameObject
	self.bg_ = self.resourceGroup:ComponentByName("bg_", typeof(UISprite))
	self.img_ = self.resourceGroup:ComponentByName("img_", typeof(UISprite))
	self.label_ = self.resourceGroup:ComponentByName("label_", typeof(UILabel))
	self.addBtn = self.resourceGroup:NodeByName("addBtn").gameObject
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.labelTip1 = self.bottomGroup:ComponentByName("labelTip1", typeof(UILabel))
	self.labelTip2 = self.bottomGroup:ComponentByName("labelTip2", typeof(UILabel))
	self.progressGroup = self.bottomGroup:NodeByName("progressGroup").gameObject
	self.progressBar = self.progressGroup:ComponentByName("progressBar", typeof(UISprite))
	self.progressValueImg = self.progressBar:ComponentByName("progressValueImg", typeof(UISprite))
	self.progressBarLabel = self.progressBar:ComponentByName("progressBarLabel", typeof(UILabel))
	self.nodeGroup = self.progressGroup:NodeByName("nodeGroup").gameObject

	for i = 1, 5 do
		self["node" .. i] = self.nodeGroup:ComponentByName("node" .. i, typeof(UISprite))
		self["labelNode" .. i] = self["node" .. i]:ComponentByName("label", typeof(UILabel))
	end

	self.itemGroup = self.bottomGroup:NodeByName("itemGroup").gameObject
	self.item = self.bottomGroup:NodeByName("item").gameObject
end

function ActivityPromotionTest:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.label_.text = xyd.models.backpack:getItemNumByID(self.ResItemID)
	end)

	UIEventListener.Get(self.btnHelp.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_PROMOTION_TEST_TEXT01"
		})
	end

	UIEventListener.Get(self.img_.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("item_tips_window", {
			itemID = self.ResItemID,
			itemNum = xyd.models.backpack:getItemNumByID(self.ResItemID),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	UIEventListener.Get(self.addBtn).onClick = function ()
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType2(xyd.ActivityID.ACTIVITY_PROMOTION_TEST_GIFTBAG),
			select = xyd.ActivityID.ACTIVITY_PROMOTION_TEST_GIFTBAG,
			closeBtnCallback = function ()
				xyd.goToActivityWindowAgain({
					activity_type = xyd.tables.activityTable:getType2(xyd.ActivityID.ACTIVITY_PROMOTION_TEST),
					select = xyd.ActivityID.ACTIVITY_PROMOTION_TEST
				})
			end
		})
	end
end

function ActivityPromotionTest:initUIComponent()
	self.labelTip1.text = __("ACTIVITY_PROMOTION_TEST_TEXT02")
	self.labelTip2.text = __("ACTIVITY_PROMOTION_TEST_TEXT03")
	self.labelBubble.text = __("ACTIVITY_PROMOTION_TEST_TEXT06")
	self.label_.text = xyd.models.backpack:getItemNumByID(self.ResItemID)

	print("activity_promotion_test_logo_" .. xyd.Global.lang)
	xyd.setUISpriteAsync(self.img_, nil, xyd.tables.itemTable:getIcon(self.ResItemID))

	self.labelBubble.height = 64

	self.labelBubble:Y(15)

	if xyd.Global.lang == "ja_jp" then
		self.labelBubble.width = 240
		self.labelBubble.height = 70

		self.labelBubble:Y(10)
	end

	if xyd.Global.lang == "de_de" then
		self.labelBubble.width = 240
		self.labelBubble.height = 70

		self.labelBubble:Y(15)
	end

	if xyd.Global.lang == "en_en" then
		self.labelTip2.width = 120

		self.labelTip2:X(-325.5)
	end

	local helpArr = {
		{
			-115,
			138,
			138
		},
		{
			-104,
			160,
			160
		},
		{
			0,
			163,
			163
		},
		{
			-31,
			160,
			160
		},
		{
			-123,
			140,
			140
		},
		{
			-88,
			162,
			162
		}
	}
	local partnerIndex = xyd.tables.miscTable:getNumber("activity_promotion_test_picture", "value")

	xyd.setUISpriteAsync(self.partnerImg_, nil, "activity_promotion_test_zj_" .. partnerIndex, nil, , true)
	xyd.setUISpriteAsync(self.imgTitle, nil, "activity_promotion_test_logo_" .. xyd.Global.lang)
	self.partnerImg_:X(helpArr[partnerIndex][1])
	self:resizePosY(self.partnerImg_, helpArr[partnerIndex][2], helpArr[partnerIndex][3])
	self:updateProgressGroup()
	self:updateAwardGroup()
end

function ActivityPromotionTest:updateProgressGroup()
	if not self.initProgressFlag then
		self.initProgressFlag = true

		for i = 1, 5 do
			self["labelNode" .. i].text = xyd.tables.activityPromotionTestTable:getPoint(i)
		end
	end

	local curPoint = self.activityData:getCurPoint()
	self.progressBarLabel.text = math.min(xyd.tables.activityPromotionTestTable:getPoint(5), curPoint)
	local realValue = 0
	local lastStagePoint = 0

	for i = 1, 5 do
		local nowStagePoint = xyd.tables.activityPromotionTestTable:getPoint(i)

		if nowStagePoint < curPoint then
			realValue = realValue + 0.2
			lastStagePoint = nowStagePoint
		else
			realValue = realValue + (curPoint - lastStagePoint) / (nowStagePoint - lastStagePoint) * 1 / 5

			break
		end
	end

	self.progressValueImg.fillAmount = realValue
end

function ActivityPromotionTest:updateAwardGroup()
	for i = 1, 5 do
		local data = {
			index = i
		}

		if not self.items[i] then
			local itemObject = NGUITools.AddChild(self.itemGroup.gameObject, self.item)
			local item = ActivityPromotionTestItem.new(itemObject, self)

			item:setInfo(data)

			self.items[i] = item
		else
			self.items[i]:setInfo(data)
		end
	end

	self.itemGroup:ComponentByName("", typeof(UILayout)):Reposition()
end

function ActivityPromotionTest:onGetMsg(event)
	local data = event.data
	local detail = json.decode(data.detail)
end

function ActivityPromotionTestItem:ctor(go, parent)
	ActivityPromotionTestItem.super.ctor(self, go, parent)

	self.parent = parent
end

function ActivityPromotionTestItem:initUI()
	local go = self.go
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.freeIconPos = self.go:NodeByName("freeIconPos").gameObject
	self.extraIconPos = self.go:NodeByName("extraIconPos").gameObject
	self.extraClickMask = self.extraIconPos:NodeByName("clickMask").gameObject
	self.costIconImg = self.go:ComponentByName("costIconImg", typeof(UISprite))
	self.labelCostNum = self.go:ComponentByName("labelCostNum", typeof(UILabel))

	UIEventListener.Get(self.extraClickMask.gameObject).onClick = function ()
		xyd.alertTips(__("ACTIVITY_PROMOTION_TEST_TEXT04", xyd.tables.activityPromotionTestTable:getCondition(self.index)[2]))
	end
end

function ActivityPromotionTestItem:setInfo(params)
	self.index = params.index
	local freeAward = xyd.tables.activityPromotionTestTable:getFreeAwards(self.index)
	local extraAward = xyd.tables.activityPromotionTestTable:getExtraAwards(self.index)
	local condition = xyd.tables.activityPromotionTestTable:getCondition(self.index)
	local params1 = {
		scale = 0.7037037037037037,
		uiRoot = self.freeIconPos,
		itemID = freeAward[1],
		num = freeAward[2]
	}

	if not self.freeIcon then
		self.freeIcon = AdvanceIcon.new(params1)
	else
		self.freeIcon:SetInfo(params1)
	end

	self.freeIcon:setChoose(self.parent.activityData:getFreeAwardIsAwarded(self.index))
	self.freeIcon:setMask(self.parent.activityData:getFreeAwardIsAwarded(self.index))

	local params2 = {
		scale = 0.7037037037037037,
		uiRoot = self.extraIconPos,
		itemID = extraAward[1],
		num = extraAward[2]
	}

	if not self.extraIcon then
		self.extraIcon = AdvanceIcon.new(params2)
	else
		self.extraIcon:SetInfo(params2)
	end

	if self.parent.activityData:getExtraAwardIsLock(self.index) then
		self.extraIcon:setLock(true)
	else
		self.extraIcon:setLock(false)
		self.extraIcon:setChoose(self.parent.activityData:getExtraAwardIsAwarded(self.index))
		self.extraIcon:setMask(self.parent.activityData:getExtraAwardIsAwarded(self.index))
	end

	xyd.setUISpriteAsync(self.costIconImg, nil, xyd.tables.itemTable:getIcon(condition[1]))

	local hasNum = xyd.models.backpack:getItemNumByID(condition[1])
	self.labelCostNum.text = "×" .. condition[2]

	if condition[2] <= hasNum then
		self.labelCostNum.color = Color.New2(2958962)

		self.extraClickMask:SetActive(false)
	else
		self.labelCostNum.color = Color.New2(3422556671.0)

		self.extraClickMask:SetActive(true)
	end
end

return ActivityPromotionTest
