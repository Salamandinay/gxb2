local Activity4BirthdayParty = class("Activity4BirthdayParty", import(".ActivityContent"))
local Activity4BirthdayPartyItem = class("Activity4BirthdayPartyItem", import("app.common.ui.FixedWrapContentItem"))
local Activity4BirthdayShopItem = class("Activity4BirthdayShopItem", import("app.components.CopyComponent"))
local cjson = require("cjson")
local CountDown = import("app.components.CountDown")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function Activity4BirthdayParty:ctor(parentGO, params)
	Activity4BirthdayParty.super.ctor(self, parentGO, params)
end

function Activity4BirthdayParty:getPrefabPath()
	return "Prefabs/Windows/activity/activity_4birthday_party"
end

function Activity4BirthdayParty:resizeToParent()
	Activity4BirthdayParty.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874

	self:resizePosY(self.roleEffectGroup, 48, -20)
	self:resizePosY(self.group1, 222, 144)
	self:resizePosY(self.group2, 222, 144)
	self:resizePosY(self.bottomGroup, -111, -248)
end

function Activity4BirthdayParty:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY)

	if self.activityData:checkPartySpecialAwardHaveGot() then
		self.curContentIndex = 2
	else
		self.curContentIndex = 1
	end

	self.shopItems = {}

	self:getUIComponent()
	Activity4BirthdayParty.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function Activity4BirthdayParty:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.titleImg = self.groupAction:ComponentByName("titleImg_", typeof(UISprite))
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
	self.btnPreView = self.groupAction:NodeByName("btnPreView").gameObject
	self.timeGroup = self.groupAction:NodeByName("timeGroup").gameObject
	self.timeGroupLayout = self.groupAction:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.btnStory = self.groupAction:NodeByName("bottomGroup/btnStory").gameObject
	self.labelStory = self.btnStory:ComponentByName("labelStory", typeof(UILabel))
	self.redPointStory = self.btnStory:ComponentByName("redPoint", typeof(UISprite))
	self.btnJump = self.groupAction:NodeByName("bottomGroup/btnJump").gameObject
	self.labelJump = self.btnJump:ComponentByName("labelJump", typeof(UILabel))
	self.redPointJump = self.btnJump:ComponentByName("redPoint", typeof(UISprite))
	self.resourcesGroup = self.groupAction:NodeByName("resourcesGroup").gameObject
	self.resource1Group = self.resourcesGroup:NodeByName("resource1Group").gameObject
	self.iconResource1 = self.resource1Group:ComponentByName("iconResource1", typeof(UISprite))
	self.labelResource1 = self.resource1Group:ComponentByName("labelResource1", typeof(UILabel))
	self.addResource1Btn = self.resource1Group:NodeByName("addResource1Btn").gameObject
	self.midGroup1 = self.groupAction:NodeByName("midGroup1").gameObject
	self.item = self.midGroup1:NodeByName("item").gameObject

	for i = 1, 2 do
		self["group" .. i] = self.midGroup1:NodeByName("group" .. i).gameObject
		self["scroller" .. i] = self["group" .. i]:NodeByName("scroller").gameObject
		self["scrollView" .. i] = self["group" .. i]:ComponentByName("scroller", typeof(UIScrollView))
		self["labelWord" .. i] = self["group" .. i]:ComponentByName("labelWord", typeof(UILabel))
		self["labelProgress" .. i] = self["group" .. i]:ComponentByName("labelProgress", typeof(UILabel))
	end

	self.roleEffectGroup = self.midGroup1:NodeByName("roleEffectGroup").gameObject
	self.roleEffectPos1 = self.roleEffectGroup:ComponentByName("roleEffectPos1", typeof(UITexture))
	self.roleEffectPos2 = self.roleEffectGroup:ComponentByName("roleEffectPos2", typeof(UITexture))
	self.bottomGroup = self.midGroup1:NodeByName("bottomGroup").gameObject
	self.btnUse1 = self.bottomGroup:NodeByName("btnUse1").gameObject
	self.btnUse2 = self.bottomGroup:NodeByName("btnUse2").gameObject

	for i = 1, 2 do
		self["labelUse" .. i] = self["btnUse" .. i]:ComponentByName("labelUse", typeof(UILabel))
		self["redPointUse" .. i] = self["btnUse" .. i]:ComponentByName("redPoint", typeof(UISprite))
	end

	self.btnSwitch1 = self.bottomGroup:ComponentByName("btnSwitch", typeof(UISprite))
	self.redPointSwitch1 = self.btnSwitch1:ComponentByName("redPoint", typeof(UISprite))
	self.specialAwardGroup = self.bottomGroup:NodeByName("specialAwardGroup").gameObject
	self.iconGroup = self.specialAwardGroup:NodeByName("iconGroup").gameObject
	self.iconGroupGrid = self.specialAwardGroup:ComponentByName("iconGroup", typeof(UIGrid))
	self.clickMaskSpecialAward = self.specialAwardGroup:NodeByName("clickMask").gameObject
	self.labelHot = self.specialAwardGroup:ComponentByName("labelHot", typeof(UILabel))
	self.dianjiEffectPos = self.specialAwardGroup:ComponentByName("dianjiEffectPos", typeof(UITexture))
	self.midGroup2 = self.groupAction:NodeByName("midGroup2").gameObject
	self.btnSwitch2 = self.midGroup2:ComponentByName("bottomGroup/btnSwitch", typeof(UISprite))
	self.redPointSwitch2 = self.btnSwitch2:ComponentByName("redPoint", typeof(UISprite))
	self.scrollerShop = self.midGroup2:NodeByName("scroller").gameObject
	self.scrollViewShop = self.midGroup2:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scrollerShop:NodeByName("itemGroup").gameObject
	self.itemGroupGrid = self.scrollerShop:ComponentByName("itemGroup", typeof(UIGrid))
	self.shopItem = self.scrollerShop:NodeByName("item").gameObject
end

function Activity4BirthdayParty:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:updateResGroup()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = nil

		if data and data.detail and data.detail ~= {} and data.detail ~= "" then
			detail = cjson.decode(data.detail)
		else
			detail = {
				type = 3
			}
		end

		if data.activity_id == xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY then
			local getCoinID = tonumber(xyd.tables.miscTable:split2Cost("activity_4birthday_get", "value", "#")[1])
			local type = detail.type

			if type == 1 or type == 2 then
				local items = detail.items
				local randomAward = {}
				local otherAward = {}

				for i = 1, #items do
					if tonumber(items[i].item_id) == getCoinID then
						table.insert(detail.extras, items[i])
					else
						table.insert(randomAward, items[i])
					end
				end

				xyd.itemFloat(randomAward)

				local awards = detail.extras

				if awards and #awards > 0 then
					for _, award in pairs(awards) do
						if tonumber(award.item_id) == getCoinID or tonumber(award.item_id) == 380 then
							award.cool = 1
						end

						table.insert(otherAward, {
							item_id = award.item_id,
							item_num = award.item_num,
							cool = award.cool
						})
					end

					table.sort(otherAward, function (a, b)
						if a.cool == b.cool then
							return a.item_id < b.item_id
						else
							return a.cool
						end
					end)
					xyd.openWindow("gamble_rewards_window", {
						wnd_type = 2,
						data = otherAward
					})
				end

				self:updateContent(true)
			elseif type == 3 then
				local time = self.activityData.tempShopAwardTime
				local award = xyd.tables.activity4birthdayShopTable:getAwards(self.activityData.tempShopAwardID)

				xyd.itemFloat({
					{
						item_id = award[1],
						item_num = award[2] * time
					}
				})
				self:updateContent(true)
			elseif type == 4 then
				local items = detail.items

				xyd.openWindow("gamble_rewards_window", {
					layoutCenter = true,
					wnd_type = 2,
					data = items
				})
				self:updateContent(true)
			else
				self:updateRedPoint()
			end
		end
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, function (event)
		local id = event.data.act_info.activity_id

		if id == xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY then
			local datas = self.activityData:getPartyShopDatas()

			self.wrapContentShop:setInfos(datas, {})
		end
	end)

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_4BIRTHDAY_HELP"
		})
	end

	UIEventListener.Get(self.addResource1Btn).onClick = function ()
		local data = self.activityData:getResource1()

		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			activityData = self.activityData.detail,
			itemID = data[1],
			activityID = xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY
		})
	end

	UIEventListener.Get(self.btnJump).onClick = function ()
		xyd.goWay(222)
	end

	UIEventListener.Get(self.btnStory).onClick = function ()
		xyd.openWindow("activity_4birthday_party_story_window")
	end

	UIEventListener.Get(self.btnPreView).onClick = function ()
		local dropBoxId = xyd.tables.miscTable:getNumber("activity_4birthday_get_dropbox", "value")

		xyd.openWindow("award_preview_with_change_window", {
			dropBoxId = dropBoxId
		})
	end

	for i = 1, 2 do
		UIEventListener.Get(self["btnUse" .. i]).onClick = function ()
			self:useItem(i)
		end
	end

	UIEventListener.Get(self.btnSwitch1.gameObject).onClick = function ()
		local allPoint = self.activityData:getPartyAllPoint()
		local needPoint = self.activityData:getPartyNeedPoint(1) + self.activityData:getPartyNeedPoint(2)
		self.labelHot.text = allPoint .. "/" .. needPoint

		if needPoint <= allPoint then
			self.curContentIndex = 2

			self:updateContent()
		end

		xyd.db.misc:setValue({
			value = 1,
			key = "activity_4birthday_party_dianji"
		})

		if self.dianjiEffect then
			self.dianjiEffect:SetActive(false)
		end
	end

	UIEventListener.Get(self.btnSwitch2.gameObject).onClick = function ()
		self.curContentIndex = 1

		self:updateContent()

		if self.dianjiEffect then
			self.dianjiEffect:SetActive(false)
		end
	end

	UIEventListener.Get(self.clickMaskSpecialAward.gameObject).onClick = function ()
		if self.activityData:checkPartySpecialAwardHaveGot() then
			return
		end

		if self.activityData:checkPartySpecialAwardCanGet() then
			self.activityData:reqPartySpecialAward()
		else
			xyd.alertTips(__("ACTIVITY_4BIRTHDAY_TIPS01"))
		end
	end
end

function Activity4BirthdayParty:initData()
	local res1Data = self.activityData:getResource1()
	self.labelResource1.text = xyd.models.backpack:getItemNumByID(res1Data[1])
end

function Activity4BirthdayParty:initUIComponent()
	self.labelStory.text = __("ACTIVITY_4BIRTHDAY_BUTTON02")
	self.labelJump.text = __("ACTIVITY_4BIRTHDAY_BUTTON03")
	self.labelWord1.text = __("ACTIVITY_LAFULI_CASTLE_TEXT01")
	self.labelWord2.text = __("ACTIVITY_LAFULI_CASTLE_TEXT01")
	self.labelUse1.text = __("ACTIVITY_4BIRTHDAY_BUTTON01")
	self.labelUse2.text = __("ACTIVITY_4BIRTHDAY_BUTTON01")
	self.endLabel_.text = __("END")

	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	})

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)

		self.labelJump.width = 160

		self.labelJump:X(-10)
	end

	self.timeGroupLayout:Reposition()

	for i = 1, 2 do
		local wrapContent = self["scroller" .. i]:ComponentByName("wrapContent", typeof(UIWrapContent))

		if not self["wrapContent" .. i] then
			self["wrapContent" .. i] = FixedWrapContent.new(self["scrollView" .. i], wrapContent, self.item, Activity4BirthdayPartyItem, self)
		end
	end

	xyd.setUISpriteAsync(self.titleImg, nil, "activity_4birthday_party_logo_" .. xyd.Global.lang)
	xyd.setUISpriteAsync(self.btnSwitch2, nil, "activity_4birthday_party_bg_fh_" .. xyd.Global.lang, nil, , true)
	self:initData()
	self:updateContent()
	self:checkDianjiEffect()
	self:updateResGroup()
end

function Activity4BirthdayParty:updateContent(keepPosition)
	self.midGroup1:SetActive(self.curContentIndex == 1)
	self.midGroup2:SetActive(self.curContentIndex == 2)

	if self.curContentIndex == 1 then
		for i = 1, 2 do
			self["labelProgress" .. i].text = self.activityData:getPartyPoint(i) .. "/" .. self.activityData:getPartyNeedPoint(i)
			local datas = self.activityData:getPartyDatas(i)

			self["wrapContent" .. i]:setInfos(datas, {
				keepPosition = keepPosition
			})

			for j = 1, #datas do
				if not self.activityData:haveGotPartyAward(datas[j].id) or j == #datas then
					local sp = self["scroller" .. i]:GetComponent(typeof(SpringPanel))

					if not self["initPos" .. i] then
						self["initPos" .. i] = self["scroller" .. i].transform.localPosition.y
					end

					local arr = {
						377,
						1161
					}
					local dis = math.min(self["initPos" .. i] + (j - 1) * 98, arr[i])

					sp.Begin(sp.gameObject, Vector3(0, dis, 0), 800)

					break
				end
			end
		end

		self:updateSpeciaAwardGroup()
		self:updateRoleEffect()
	elseif self.curContentIndex == 2 then
		local datas = self.activityData:getPartyShopDatas()

		for i = 1, #datas do
			if not self.shopItems[i] then
				local tmp = NGUITools.AddChild(self.itemGroup.gameObject, self.shopItem.gameObject)
				local item = Activity4BirthdayShopItem.new(tmp, self)
				self.shopItems[i] = item
			end

			self.shopItems[i]:setInfo(datas[i])
		end

		self.itemGroupGrid:Reposition()
		self:waitForFrame(1, function ()
			self.shopItems[7]:getGameObject():X(0)
		end)
		self.scrollViewShop:ResetPosition()
	end

	self:updateRedPoint()
	self:checkDianjiEffect()
end

function Activity4BirthdayParty:updateResGroup()
	local res1Data = self.activityData:getResource1()

	xyd.setUISpriteAsync(self.iconResource1, nil, xyd.tables.itemTable:getIcon(res1Data[1]))

	self.labelResource1.text = xyd.models.backpack:getItemNumByID(res1Data[1])
end

function Activity4BirthdayParty:updateRoleEffect()
	if not self.roleEffect1 then
		self.roleEffect1 = xyd.Spine.new(self.roleEffectPos1.gameObject)

		self.roleEffect1:setInfo("activity_4birthday_partner", function ()
			self.roleEffect1:play("idle", 0, 1, function ()
			end, true)
		end)
	end

	if not self.roleEffect2 then
		self.roleEffect2 = xyd.Spine.new(self.roleEffectPos2.gameObject)

		self.roleEffect2:setInfo("puluomixiusi_pifu01", function ()
			self.roleEffect2:play("idle", 0, 1, function ()
			end, true)
		end)
	end
end

function Activity4BirthdayParty:checkDianjiEffect()
	local flag = xyd.db.misc:getValue("activity_4birthday_party_dianji")

	if flag then
		return
	end

	local nowPoint = self.activityData:getPartyAllPoint()
	local need = self.activityData:getPartyNeedPoint(1) + self.activityData:getPartyNeedPoint(2)

	if nowPoint < need then
		return
	end

	if not self.dianjiEffect then
		self.dianjiEffect = xyd.Spine.new(self.dianjiEffectPos.gameObject)

		self.dianjiEffect:setInfo("fx_ui_dianji", function ()
			self:waitForTime(5, function ()
				self.dianjiEffect:play("texiao01", 0, 1, function ()
				end, true)
			end)
		end)
	end
end

function Activity4BirthdayParty:updateSpeciaAwardGroup()
	if not self.specialAwardIcons then
		self.specialAwardIcons = {}
	end

	local awards = xyd.tables.miscTable:split2Cost("activity_4birthday_bigawards", "value", "|#")
	local haveGot = self.activityData:checkPartySpecialAwardHaveGot()
	local canGetAward = self.activityData:checkPartySpecialAwardCanGet()

	for i = 1, #awards do
		local params = {
			scale = 0.7037037037037037,
			uiRoot = self.iconGroup.gameObject,
			itemID = awards[i][1],
			num = awards[i][2]
		}

		if not self.specialAwardIcons[i] then
			self.specialAwardIcons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.specialAwardIcons[i]:setInfo(params)
		end

		self.specialAwardIcons[i]:setChoose(haveGot)

		if canGetAward then
			local effect = "bp_available"

			self.specialAwardIcons[i]:setEffect(true, effect, {
				effectPos = Vector3(0, 0, 0),
				effectScale = Vector3(1.1, 1.1, 1.1)
			})
		else
			self.specialAwardIcons[i]:setEffect(false)
		end
	end

	self.iconGroupGrid:Reposition()
	self.clickMaskSpecialAward:SetActive(true)

	local allPoint = self.activityData:getPartyAllPoint()
	local needPoint = self.activityData:getPartyNeedPoint(1) + self.activityData:getPartyNeedPoint(2)
	self.labelHot.text = allPoint .. "/" .. needPoint

	if needPoint <= allPoint then
		xyd.setUISpriteAsync(self.btnSwitch1, nil, "activity_4birthday_party_bg_whkh_" .. xyd.Global.lang, nil, , true)
		self.btnSwitch1:NodeByName("imgGroup").gameObject:SetActive(true)
	else
		xyd.setUISpriteAsync(self.btnSwitch1, nil, "activity_4birthday_party_bg_yhrd_" .. xyd.Global.lang, nil, , true)
		self.btnSwitch1:NodeByName("imgGroup").gameObject:SetActive(false)
	end
end

function Activity4BirthdayParty:useItem(type)
	local singleCost = self.activityData:getResource1()
	local resNum = xyd.models.backpack:getItemNumByID(singleCost[1])

	if resNum < singleCost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(singleCost[1])))

		return
	end

	local nowPoint = self.activityData:getPartyPoint(type)
	local maxPoint = self.activityData:getPartyNeedPoint(type)
	local leftTime = math.max(0, maxPoint - nowPoint)

	if leftTime <= 0 then
		for i = 1, 2 do
			local nowPoint2 = self.activityData:getPartyPoint(i)
			local maxPoint2 = self.activityData:getPartyNeedPoint(i)
			local leftTime2 = math.max(0, maxPoint2 - nowPoint2)

			if leftTime2 > 0 then
				local arr = {
					__("ACTIVITY_4BIRTHDAY_TEXT06"),
					__("ACTIVITY_4BIRTHDAY_TEXT05")
				}

				xyd.alertTips(__("ACTIVITY_4BIRTHDAY_TEXT08", arr[i]))

				return
			end
		end

		xyd.alertTips(__("ACTIVITY_4BIRTHDAY_TIPS03"))

		return
	end

	local textArr = {
		__("ACTIVITY_4BIRTHDAY_TEXT05"),
		__("ACTIVITY_4BIRTHDAY_TEXT06")
	}
	local select_max_num = math.floor(resNum / singleCost[2])
	select_max_num = math.min(leftTime, select_max_num)
	select_max_num = math.min(singleCost[2] * 200, select_max_num)

	xyd.WindowManager.get():openWindow("common_use_cost_window", {
		select_max_num = select_max_num,
		show_max_num = xyd.models.backpack:getItemNumByID(singleCost[1]),
		select_multiple = singleCost[2],
		icon_info = {
			height = 45,
			width = 45,
			name = xyd.tables.itemTable:getIcon(singleCost[1])
		},
		title_text = __("ACTIVITY_4BIRTHDAY_TEXT03"),
		explain_text = __("ACTIVITY_4BIRTHDAY_TEXT04", textArr[type]),
		sure_callback = function (num)
			self.activityData:reqPartyAward(type, num)

			local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

			if common_use_cost_window_wd then
				xyd.WindowManager.get():closeWindow("common_use_cost_window")
			end
		end
	})
end

function Activity4BirthdayParty:updateRedPoint()
	self.activityData:checkRedMarkOfParty()
	self.redPointUse1:SetActive(self.activityData:checkRedMarkOfPartyBtnUse(1))
	self.redPointUse2:SetActive(self.activityData:checkRedMarkOfPartyBtnUse(2))
	self.redPointStory:SetActive(self.activityData:checkRedMarkOfPartyStory())
end

function Activity4BirthdayParty:dispose()
	Activity4BirthdayParty.super.dispose(self)
end

function Activity4BirthdayPartyItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	Activity4BirthdayPartyItem.super.ctor(self, go, parent)
	self:initUI()
end

function Activity4BirthdayPartyItem:initUI()
	self:getUIComponent()
end

function Activity4BirthdayPartyItem:getUIComponent()
	self.iconPos = self.go:NodeByName("iconPos").gameObject
	self.labelPoint = self.go:ComponentByName("labelPoint", typeof(UILabel))
end

function Activity4BirthdayPartyItem:updateInfo()
	self.id = self.data.id
	self.type = self.data.type
	self.award = xyd.tables.activity4birthdayAwardTable:getAwards(self.id)
	self.needPoint = xyd.tables.activity4birthdayAwardTable:getPoint(self.id)
	self.haveGot = self.parent.activityData:haveGotPartyAward(self.id)
	self.labelPoint.text = self.needPoint
	local params = {
		scale = 0.6018518518518519,
		uiRoot = self.iconPos.gameObject,
		itemID = self.award[1],
		num = self.award[2],
		dragScrollView = self.parent["scrollView" .. self.type]
	}

	if params.itemID == 6767 or params.itemID == 986001 then
		params.isNew = true
	end

	if not self.icon then
		self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	end

	self.icon:setInfo(params)
	self.icon:setChoose(self.haveGot)

	if self.canGetAward then
		local effect = "bp_available"

		self.icon:setEffect(true, effect, {
			effectPos = Vector3(0, 0, 0),
			effectScale = Vector3(1.1, 1.1, 1.1)
		})
	else
		self.icon:setEffect(false)
	end
end

function Activity4BirthdayPartyItem:getRoot()
	return self.go.gameObject
end

function Activity4BirthdayShopItem:ctor(go, parent)
	Activity4BirthdayShopItem.super.ctor(self, go, parent)

	self.parent = parent

	self:initUI()
end

function Activity4BirthdayShopItem:initUI()
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.iconPos = self.go:NodeByName("iconPos").gameObject
	self.labelLimit = self.go:ComponentByName("labelLimit", typeof(UILabel))
	self.costGroup = self.go:NodeByName("costGroup").gameObject
	self.iconCost = self.costGroup:ComponentByName("iconCost", typeof(UISprite))
	self.labelCost = self.costGroup:ComponentByName("labelCost", typeof(UILabel))
	self.btnBuy = self.costGroup:NodeByName("btnBuy").gameObject

	UIEventListener.Get(self.btnBuy).onClick = function ()
		self:onClickBtnBuy()
	end
end

function Activity4BirthdayShopItem:setInfo(data)
	self.data = data
	self.id = self.data.id
	self.limit = xyd.tables.activity4birthdayShopTable:getLimit(self.id)
	self.cost = xyd.tables.activity4birthdayShopTable:getCost(self.id)
	self.awards = xyd.tables.activity4birthdayShopTable:getAwards(self.id)
	self.buyTime = self.parent.activityData:getPartyShopBuyTimes(self.id)
	self.leftTime = self.limit - self.buyTime
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT_2") .. self.leftTime
	self.labelCost.text = self.cost[2]

	xyd.setUISpriteAsync(self.iconCost, nil, xyd.tables.itemTable:getIcon(self.cost[1]))

	local params = {
		scale = 0.9074074074074074,
		uiRoot = self.iconPos.gameObject,
		itemID = self.awards[1],
		num = self.awards[2]
	}

	if params.itemID == 6767 or params.itemID == 986001 then
		params.isNew = true
	end

	if not self.icon then
		self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	end

	self.icon:setInfo(params)
end

function Activity4BirthdayShopItem:getGameObject()
	return self.go
end

function Activity4BirthdayShopItem:onClickBtnBuy()
	if self.leftTime <= 0 then
		xyd.showToast(__("ACTIVITY_WORLD_BOSS_LIMIT"))

		return
	elseif xyd.models.backpack:getItemNumByID(self.cost[1]) < self.cost[2] then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.cost[1])))

		return
	end

	local params = {
		needTips = true,
		hasMaxMin = true,
		limitKey = "ACTIVITY_WORLD_BOSS_LIMIT",
		buyType = self.awards[1],
		buyNum = self.awards[2],
		costType = self.cost[1],
		costNum = self.cost[2],
		purchaseCallback = function (evt, num)
			if xyd.models.backpack:getItemNumByID(self.cost[1]) < self.cost[2] * num then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.cost[1])))

				return
			end

			self.parent.activityData:reqBuyPartyShopItem(self.id, num)
		end,
		titleWords = __("ITEM_BUY_WINDOW", xyd.tables.itemTable:getName(self.awards[1])),
		limitNum = self.leftTime,
		notEnoughWords = __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.cost[1])),
		eventType = xyd.event.GET_ACTIVITY_AWARD,
		tipsCallback = function ()
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.cost[1])))
		end
	}

	xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
end

return Activity4BirthdayParty
