local ActivityLuckyboxes = class("ActivityLuckyboxes", import(".ActivityContent"))
local AdvanceIcon = import("app.components.AdvanceIcon")
local ActivityLuckyboxesItem = class("ActivityLuckyboxesItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivityLuckyboxes:ctor(parentGO, params)
	self.timesList = {
		0.25,
		0.21,
		0.18,
		0.15,
		0.23
	}

	ActivityLuckyboxes.super.ctor(self, parentGO, params)
end

function ActivityLuckyboxes:getPrefabPath()
	return "Prefabs/Windows/activity/activity_luckyboxes"
end

function ActivityLuckyboxes:resizeToParent()
	ActivityLuckyboxes.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874
end

function ActivityLuckyboxes:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LUCKYBOXES)

	self:getUIComponent()
	ActivityLuckyboxes.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityLuckyboxes:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.titleImg_ = self.groupAction:ComponentByName("titleImg_", typeof(UISprite))
	self.partnerImg_ = self.groupAction:ComponentByName("partnerImg_", typeof(UISprite))
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
	self.btnNormalAward = self.groupAction:NodeByName("btnNormalAward").gameObject
	self.btnSpecialAward = self.groupAction:NodeByName("btnSpecialAward").gameObject
	self.btnGiftbag = self.groupAction:NodeByName("btnGiftbag").gameObject
	self.labelGiftbag = self.btnGiftbag:ComponentByName("labelGiftbag", typeof(UILabel))
	self.redPoint_giftbag = self.btnGiftbag:ComponentByName("redPoint", typeof(UISprite))
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.normalAwardGroup = self.midGroup:NodeByName("normalAwardGroup").gameObject
	self.grid = self.normalAwardGroup:ComponentByName("grid", typeof(UIGrid))
	self.normalAwardItem = self.normalAwardGroup:NodeByName("item").gameObject
	self.normalEffectPos = self.normalAwardGroup:ComponentByName("normalEffectPos", typeof(UITexture))
	self.specialAwardGroup = self.midGroup:NodeByName("specialAwardGroup").gameObject
	self.btnChooseSpecialAward = self.specialAwardGroup:NodeByName("btnChooseSpecialAward").gameObject
	self.redPoint_choose = self.btnChooseSpecialAward:ComponentByName("redPoint", typeof(UISprite))
	self.imgSpecialAward = self.specialAwardGroup:ComponentByName("specialAward", typeof(UISprite))
	self.specialEffectPos = self.specialAwardGroup:ComponentByName("specialEffectPos", typeof(UITexture))
	self.resourcesGroup = self.midGroup:NodeByName("resourcesGroup").gameObject
	self.resource1Group = self.resourcesGroup:NodeByName("resource1Group").gameObject
	self.imgResource1 = self.resource1Group:ComponentByName("img_", typeof(UISprite))
	self.labelResource1 = self.resource1Group:ComponentByName("label_", typeof(UILabel))
	self.addBtn = self.resource1Group:NodeByName("addBtn").gameObject
	self.luckyValueGroup = self.resourcesGroup:NodeByName("luckyValueGroup").gameObject
	self.labelLuckyValue = self.luckyValueGroup:ComponentByName("labelLuckyValue", typeof(UILabel))
	self.labelLuckyMaxValue = self.luckyValueGroup:ComponentByName("labelLuckyMaxValue", typeof(UILabel))
	self.starEffectPos = self.luckyValueGroup:NodeByName("starEffectPos").gameObject
	self.btnSingleDraw = self.midGroup:NodeByName("btnSingleDraw").gameObject
	self.iconImgSingleDraw = self.btnSingleDraw:ComponentByName("iconImg", typeof(UISprite))
	self.labelNumSingleDraw = self.btnSingleDraw:ComponentByName("labelNum", typeof(UILabel))
	self.labelSingleDraw = self.btnSingleDraw:ComponentByName("label", typeof(UILabel))
	self.redPoint_singleDraw = self.btnSingleDraw:ComponentByName("redPoint", typeof(UISprite))
	self.btnTenDraw = self.midGroup:NodeByName("btnTenDraw").gameObject
	self.iconImgTenDraw = self.btnTenDraw:ComponentByName("iconImg", typeof(UISprite))
	self.labelNumTenDraw = self.btnTenDraw:ComponentByName("labelNum", typeof(UILabel))
	self.labelTenDraw = self.btnTenDraw:ComponentByName("label", typeof(UILabel))
	self.redPoint_tenDraw = self.btnTenDraw:ComponentByName("redPoint", typeof(UISprite))
	self.skipAnimatioinClickMask = self.midGroup:NodeByName("skipAnimatioinClickMask").gameObject
end

function ActivityLuckyboxes:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:updateResGroup()
	end)
	self:registerEvent(xyd.event.LABA_SELECT_AWARD, function ()
		self:updateRedPoint()
		self:updateResGroup()
		self:updateSpecialAwardGroup()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = json.decode(data.detail)

		if data.activity_id == xyd.ActivityID.ACTIVITY_LUCKYBOXES then
			self:onGetMsg(event)
		end
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_LUCKYBOXES then
			self.activityData.detail = json.decode(event.data.act_info.detail)
			local itemID = self.activityData:getSingleDrawCost()[1]

			if self.openTipsWindowFlag == true then
				self.openTipsWindowFlag = false
				local progressArr = {}
				local ways = xyd.tables.itemTable:getWays(itemID)

				for i = 1, #ways do
					local way = ways[i]
					local data = {}
					local index = nil
					local ids = xyd.tables.activityLuckyboxesMissonTable:getIDs()

					for j = 1, #ids do
						if xyd.tables.activityLuckyboxesMissonTable:getWay(j) == way then
							index = j

							break
						end
					end

					if self.activityData and self.activityData.detail.is_completeds and index then
						data.curValue = self.activityData.detail.is_completeds[index] or 0
						data.maxValue = xyd.tables.activityLuckyboxesMissonTable:getLimit(index)
						progressArr[tonumber(way)] = data
					end
				end

				xyd.WindowManager:get():openWindow("getway_with_progress_window", {
					itemID = itemID,
					progressArr = progressArr
				})
			end
		end
	end)

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_LUCKYBOXES_TEXT14"
		})
	end

	UIEventListener.Get(self.btnNormalAward).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_space_explore_awarded_window", {
			data = self.activityData:getNormalAwardData(),
			winTitle = __("ACTIVITY_CHRISTMAS_SIGN_UP_TEXT01")
		})
	end

	UIEventListener.Get(self.btnSpecialAward).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_luckyboxes_special_award_window")
	end

	UIEventListener.Get(self.btnGiftbag).onClick = function ()
		xyd.db.misc:setValue({
			key = "activity_luckyboxes_gift_time_stamp",
			value = xyd.getServerTime()
		})
		self:updateRedPoint()
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType2(xyd.ActivityID.ACTIVITY_LUCKYBOXES_GIFTBAG),
			select = xyd.ActivityID.ACTIVITY_LUCKYBOXES_GIFTBAG,
			closeBtnCallback = function ()
				xyd.goToActivityWindowAgain({
					activity_type = xyd.tables.activityTable:getType2(xyd.ActivityID.ACTIVITY_LUCKYBOXES),
					select = xyd.ActivityID.ACTIVITY_LUCKYBOXES
				})
			end
		})
	end

	UIEventListener.Get(self.btnChooseSpecialAward).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_luckyboxes_choose_special_award_window")
	end

	UIEventListener.Get(self.btnSingleDraw).onClick = function ()
		if self.activityData:getSpecialAwardData() then
			self:getAward(1)
		else
			xyd.alertTips(__("ACTIVITY_LUCKYBOXES_TEXT13"))
		end
	end

	UIEventListener.Get(self.btnTenDraw).onClick = function ()
		if self.activityData:getSpecialAwardData() then
			self:getAward(2)
		else
			xyd.alertTips(__("ACTIVITY_LUCKYBOXES_TEXT13"))
		end
	end

	UIEventListener.Get(self.addBtn).onClick = function ()
		local ways = xyd.tables.itemTable:getWays(self.activityData:getSingleDrawCost()[1])

		if not ways or #ways == 0 then
			xyd.WindowManager:get():openWindow("item_tips_window", {
				showGetWays = false,
				itemID = self.activityData:getSingleDrawCost()[1],
				itemNum = xyd.models.backpack:getItemNumByID(self.activityData:getSingleDrawCost()[1]),
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			return
		end

		xyd.models.activity:reqActivityByID(self.id)

		self.openTipsWindowFlag = true
	end

	UIEventListener.Get(self.skipAnimatioinClickMask).onClick = function ()
		self:skipAwardAnimation()
	end

	UIEventListener.Get(self.imgSpecialAward.gameObject).onClick = function ()
		local data = self.activityData:getSpecialAwardList()[self.activityData:getSpecialAwardData()[1]][self.activityData:getSpecialAwardData()[2]]
		local params = {
			showGetWays = false,
			itemID = data[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function ActivityLuckyboxes:initUIComponent()
	self.labelGiftbag.text = __("ACTIVITY_LUCKYBOXES_TEXT04")

	xyd.setUISpriteAsync(self.titleImg_, nil, "activity_luckyboxes_logo_" .. xyd.Global.lang)

	if xyd.Global.lang == "ja_jp" then
		self.labelGiftbag.fontSize = 20
	end

	self:initBtnDrawGroup()
	self:initNormalAwardGroup()
	self:updateSpecialAwardGroup()
	self:updateResGroup()
	self:initEffect()
	self:updateRedPoint()
end

function ActivityLuckyboxes:initBtnDrawGroup()
	local cost = self.activityData:getSingleDrawCost()
	self.labelSingleDraw.text = __("ACTIVITY_LUCKYBOXES_TEXT01")

	xyd.setUISpriteAsync(self.iconImgSingleDraw, nil, "icon_" .. cost[1])

	self.labelNumSingleDraw = cost[2]
	cost = self.activityData:getTenDrawCost()
	self.labelTenDraw.text = __("ACTIVITY_LUCKYBOXES_TEXT02")

	xyd.setUISpriteAsync(self.iconImgTenDraw, nil, "icon_" .. cost[1])

	self.labelNumSingleDraw = cost[2]
end

function ActivityLuckyboxes:initNormalAwardGroup()
	self.normalAwardItems = {}
	local data = self.activityData:getNormalAwardList()

	for i = 1, #data do
		local award = data[i]
		local normalAwardItem = NGUITools.AddChild(self.grid.gameObject, self.normalAwardItem)
		local item = ActivityLuckyboxesItem.new(normalAwardItem)

		item:setInfo({
			award = award
		})
		table.insert(self.normalAwardItems, item)
	end

	self.grid:Reposition()
end

function ActivityLuckyboxes:updateSpecialAwardGroup()
	local labelSpecialAward = self.imgSpecialAward:ComponentByName("label", typeof(UILabel))
	local labelSpecialAward_heroIcon = self.specialAwardGroup:ComponentByName("label", typeof(UILabel))
	local bg = self.specialAwardGroup:ComponentByName("bg_", typeof(UISprite))

	if self.activityData:getSpecialAwardData() then
		local data = self.activityData:getSpecialAwardList()[self.activityData:getSpecialAwardData()[1]][self.activityData:getSpecialAwardData()[2]]

		self.imgSpecialAward:SetActive(true)
		self.btnChooseSpecialAward:SetActive(false)
		bg:SetActive(true)

		local params = {
			hideText = true,
			show_has_num = false,
			scale = 0.6851851851851852,
			uiRoot = self.specialAwardGroup,
			itemID = data[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}
		local type = xyd.tables.itemTable:getType(data[1])

		if self.specialAwardIcon == nil then
			self.specialAwardIcon = AdvanceIcon.new(params)
		else
			self.specialAwardIcon:setInfo(params)
		end

		if self.specialAwardIcon then
			self.specialAwardIcon:SetActive(true)
		end

		if type ~= xyd.ItemType.HERO_DEBRIS and type ~= xyd.ItemType.HERO and type ~= xyd.ItemType.HERO_RANDOM_DEBRIS then
			if type ~= xyd.ItemType.SKIN then
				self.specialAwardIcon:showBorderBg(false)
			end
		end

		labelSpecialAward.text = data[2]
	else
		bg:SetActive(false)
		self.imgSpecialAward:SetActive(false)
		self.btnChooseSpecialAward:SetActive(true)
		labelSpecialAward_heroIcon:SetActive(false)

		if self.specialAwardIcon then
			self.specialAwardIcon:SetActive(false)
		end
	end
end

function ActivityLuckyboxes:updateResGroup()
	local luckyValue = self.activityData:getLuckyValue()
	local maxValue = self.activityData:getMaxLuckyValue()
	local valueImg = self.luckyValueGroup:ComponentByName("img", typeof(UISprite))
	self.labelLuckyValue.text = luckyValue .. "/"
	self.labelLuckyMaxValue.text = maxValue

	print(tonumber(luckyValue) == tonumber(maxValue))
	print(maxValue)
	self.starEffectPos:SetActive(tonumber(luckyValue) == tonumber(maxValue))

	local cost = self.activityData:getSingleDrawCost()

	xyd.setUISpriteAsync(self.imgResource1, nil, "icon_" .. cost[1])

	self.labelResource1.text = xyd.models.backpack:getItemNumByID(cost[1])
	valueImg.fillAmount = math.min(luckyValue / maxValue, 1)
end

function ActivityLuckyboxes:initEffect()
	self.normalEffectPos:SetActive(false)

	if not self.specialShakeEffect then
		self.specialShakeEffect = xyd.Spine.new(self.specialEffectPos.gameObject)

		self.specialShakeEffect:setInfo("fx_luckyboxes01", function ()
			self.specialShakeEffect:setRenderTarget(self.specialEffectPos, 1)
			self.specialShakeEffect:play("texiao01", 0)
			self.specialEffectPos:SetActive(false)
		end)
	end

	if not self.luckyStarEffect then
		self.luckyStarEffect = xyd.Spine.new(self.starEffectPos.gameObject)

		self.luckyStarEffect:setInfo("fx_luckyboxes02", function ()
			self.luckyStarEffect:play("texiao01", 0)
		end)
	end
end

function ActivityLuckyboxes:playAwardEffect(isSpecialAward, isTenDraw, nowShakeTime, leftShakeTime)
	self.normalEffectPos:SetActive(true)

	local normalIndex = nowShakeTime

	if normalIndex > 12 then
		normalIndex = normalIndex % 12
	end

	local t = 0.1

	if leftShakeTime <= 5 and leftShakeTime > 0 then
		t = self.timesList[leftShakeTime]
	end

	self.skipAnimatioinClickMask:SetActive(true)

	if leftShakeTime >= 1 then
		self.normalEffectPos.gameObject.transform.position = self.normalAwardItems[normalIndex]:getUIRoot().transform.position
		local oldPosition = self.normalEffectPos.gameObject.transform.localPosition

		self.normalEffectPos:SetLocalPosition(oldPosition.x + 2, oldPosition.y, oldPosition.z)
		self:waitForTime(t, function ()
			if self.skipThisAwarAnimation == true then
				self.skipThisAwarAnimation = false

				return
			end

			self:playAwardEffect(isSpecialAward, isTenDraw, nowShakeTime + 1, leftShakeTime - 1)
		end)
	elseif leftShakeTime == 0 and isSpecialAward == false then
		self.normalEffectPos.gameObject.transform.position = self.normalAwardItems[normalIndex]:getUIRoot().transform.position
		local oldPosition = self.normalEffectPos.gameObject.transform.localPosition

		self.normalEffectPos:SetLocalPosition(oldPosition.x + 2, oldPosition.y, oldPosition.z)

		if self.normalAwardSquence then
			self.normalAwardSquence:Kill(false)

			self.normalAwardSquence = nil
		end

		self.normalAwardSquence = self:getSequence()

		self.normalAwardSquence:Insert(0.1, xyd.getTweenAlpha(self.normalEffectPos:ComponentByName("", typeof(UITexture)), 0, 0.1))
		self.normalAwardSquence:Insert(0.55, xyd.getTweenAlpha(self.normalEffectPos:ComponentByName("", typeof(UITexture)), 1, 0.1))
		self.normalAwardSquence:Insert(0.95, xyd.getTweenAlpha(self.normalEffectPos:ComponentByName("", typeof(UITexture)), 0, 0.1))
		self.normalAwardSquence:Insert(1.25, xyd.getTweenAlpha(self.normalEffectPos:ComponentByName("", typeof(UITexture)), 1, 0.1))
		self.normalAwardSquence:Insert(1.35, xyd.getTweenAlpha(self.normalEffectPos:ComponentByName("", typeof(UITexture)), 1, 0.5))
		self.normalAwardSquence:AppendCallback(function ()
			if self.skipThisAwarAnimation == true then
				self.skipThisAwarAnimation = false

				return
			end

			self.normalEffectPos:ComponentByName("", typeof(UITexture)).alpha = 1

			self.normalEffectPos:SetActive(false)
			self.skipAnimatioinClickMask:SetActive(false)
			self:showDrawResult()
		end)
	elseif leftShakeTime == 0 and isSpecialAward == true then
		self.specialEffectPos:SetActive(true)
		self.normalEffectPos:SetActive(false)
		self:waitForTime(1, function ()
			if self.skipThisAwarAnimation == true then
				self.skipThisAwarAnimation = false

				return
			end

			self.specialEffectPos:SetActive(false)
			self.skipAnimatioinClickMask:SetActive(false)
			self:showDrawResult()
			self:updateSpecialAwardGroup()
		end)
	end
end

function ActivityLuckyboxes:showDrawResult()
	local cost, type, text = nil

	if self.drawType == 1 or self.drawType == 3 then
		cost = self.activityData:getSingleDrawCost()
		type = 3
		text = __("ACTIVITY_LUCKYBOXES_TEXT01")
	else
		cost = self.activityData:getTenDrawCost()
		type = 4
		text = __("ACTIVITY_LUCKYBOXES_TEXT02")
	end

	xyd.openWindow("gamble_rewards_window", {
		wnd_type = 4,
		data = self.awards,
		cost = cost,
		btnLabelText = text,
		buyCallback = function ()
			if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

				return
			end

			if self.activityData:getSpecialAwardData() then
				self:getAward(type)
			else
				xyd.alertTips(__("ACTIVITY_LUCKYBOXES_TEXT13"))
			end

			xyd.closeWindow("gamble_rewards_window")
		end
	})
	self:updateRedPoint()
	self:updateResGroup()
	self:updateSpecialAwardGroup()
end

function ActivityLuckyboxes:skipAwardAnimation()
	self.skipThisAwarAnimation = true

	if self.isSpecialAward then
		self.specialEffectPos:SetActive(true)
		self.normalEffectPos:SetActive(false)
		self:waitForTime(0.5, function ()
			self.specialEffectPos:SetActive(false)
			self.skipAnimatioinClickMask:SetActive(false)
			self:showDrawResult()
			self:updateResGroup()
			self:updateSpecialAwardGroup()
		end)
	else
		self.specialEffectPos:SetActive(false)
		self.normalEffectPos:SetActive(true)

		local normalIndex = 1
		local award = self.awards[1]
		local datas = self.activityData:getNormalAwardList()

		for i = 1, #datas do
			if datas[i][1] == self.awards[1].item_id and datas[i][2] == self.awards[1].item_num then
				normalIndex = i
			end
		end

		self.normalEffectPos.gameObject.transform.position = self.normalAwardItems[normalIndex]:getUIRoot().transform.position
		local oldPosition = self.normalEffectPos.gameObject.transform.localPosition

		self.normalEffectPos:SetLocalPosition(oldPosition.x + 2, oldPosition.y, oldPosition.z)
		self:waitForTime(0.5, function ()
			self.normalEffectPos:SetActive(false)
			self.skipAnimatioinClickMask:SetActive(false)
			self:showDrawResult()
		end)
	end
end

function ActivityLuckyboxes:updateRedPoint()
	if self.activityData:getRedPointOfTenDraw() == true then
		self.redPoint_tenDraw:SetActive(true)
	else
		self.redPoint_tenDraw:SetActive(false)
		self.redPoint_singleDraw:SetActive(self.activityData:getRedPointOfSingleDraw())
	end

	self.redPoint_giftbag:SetActive(self.activityData:getRedPointOfGiftbag())
	self.redPoint_choose:SetActive(self.activityData:getRedPointOfChooseSpecialAward())
end

function ActivityLuckyboxes:getAward(type)
	if xyd.models.backpack:getItemNumByID(self.activityData:getSingleDrawCost()[1]) < self.activityData:getSingleDrawCost()[2] and (type == 1 or type == 3) or xyd.models.backpack:getItemNumByID(self.activityData:getTenDrawCost()[1]) < self.activityData:getTenDrawCost()[2] and (type == 2 or type == 4) then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.activityData:getSingleDrawCost()[1])))

		return
	end

	local num = 10

	if type == 1 or type == 3 then
		num = 1
	end

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LUCKYBOXES, json.encode({
		award_type = 2,
		num = num
	}))

	self.drawType = type
end

function ActivityLuckyboxes:onGetMsg(event)
	local data = event.data
	local detail = json.decode(data.detail)

	if not detail.items then
		return
	end

	local isSpecialAward = false
	local normalAwardIndex = 1
	local isTenDraw = true
	self.skipThisAwarAnimation = false

	if not self.activityData.lastSelect then
		isSpecialAward = false
	else
		isSpecialAward = true
		local specialAwardItem = self.activityData:getSpecialAwardList()[self.activityData.lastSelect[1]][self.activityData.lastSelect[2]]

		for i = 1, #detail.items do
			if detail.items[i].item_id == specialAwardItem[1] and detail.items[i].item_num == specialAwardItem[2] then
				detail.items[i].cool = 1

				break
			end
		end
	end

	if self.drawType == 1 or self.drawType == 3 then
		isTenDraw = false
	end

	if self.drawType == 1 or self.drawType == 2 then
		self.isSpecialAward = isSpecialAward

		if isSpecialAward == true then
			self.awards = detail.items

			self:playAwardEffect(isSpecialAward, isTenDraw, 1, xyd.random(1, 12, {
				int = true
			}))
		else
			local normalAwardList = self.activityData:getNormalAwardList()

			for i = 1, #normalAwardList do
				if normalAwardList[i][1] == detail.items[1].item_id and normalAwardList[i][2] == detail.items[1].item_num then
					normalAwardIndex = i

					break
				end
			end

			self.awards = detail.items

			self:playAwardEffect(isSpecialAward, isTenDraw, 1, normalAwardIndex - 1)
		end
	else
		self.isSpecialAward = isSpecialAward
		self.awards = detail.items

		self:showDrawResult()
	end
end

function ActivityLuckyboxes:dispose()
	ActivityLuckyboxes.super.dispose(self)
end

function ActivityLuckyboxesItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function ActivityLuckyboxesItem:getUIComponent()
	self.iconPos = self.go:NodeByName("iconPos").gameObject
	self.labelChange = self.go:ComponentByName("labelChange", typeof(UILabel))
end

function ActivityLuckyboxesItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	self.dragScrollView = params.dragScrollView
	self.item_id = params.item_id
	self.item_num = params.item_num
	self.change = params.change
	local type = xyd.tables.itemTable:getType(self.item_id)

	if not self.icon then
		self.itemIcon = xyd.getItemIcon({
			scale = 0.8981481481481481,
			uiRoot = self.iconPos,
			dragScrollView = self.dragScrollView
		})
		self.heroIcon = xyd.getItemIcon({
			scale = 0.8981481481481481,
			uiRoot = self.iconPos,
			dragScrollView = self.dragScrollView
		}, xyd.ItemIconType.HERO_ICON)
	end

	if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
		self.heroIcon:getIconRoot():SetActive(true)

		self.icon = self.heroIcon

		self.itemIcon:getIconRoot():SetActive(false)
	else
		self.heroIcon:getIconRoot():SetActive(false)

		self.icon = self.itemIcon

		self.itemIcon:getIconRoot():SetActive(true)
	end

	self.icon:setInfo({
		scale = 0.8981481481481481,
		itemID = self.item_id,
		num = self.item_num,
		dragScrollView = self.dragScrollView
	})

	self.labelChange.text = self.change * 100 .. "%"
end

function ActivityLuckyboxesItem:ctor(go, parent)
	ActivityLuckyboxesItem.super.ctor(self, go, parent)
end

function ActivityLuckyboxesItem:initUI()
	local go = self.go
	self.iconImg = self.go:ComponentByName("iconImg", typeof(UISprite))
	self.labelNum = self.go:ComponentByName("labelNum", typeof(UILabel))
	self.clickMask = self.go:NodeByName("clickMask").gameObject

	UIEventListener.Get(self.clickMask).onClick = function ()
		local params = {
			showGetWays = false,
			itemID = self.award[1],
			itemNum = self.award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function ActivityLuckyboxesItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	self.award = params.award

	xyd.setUISpriteAsync(self.iconImg, nil, "icon_" .. self.award[1])

	self.labelNum.text = xyd.getRoughDisplayNumber(self.award[2])
end

function ActivityLuckyboxesItem:getUIRoot()
	return self.iconImg
end

return ActivityLuckyboxes
