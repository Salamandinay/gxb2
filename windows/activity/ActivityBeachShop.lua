local ActivityContent = import(".ActivityContent")
local ActivityBeachShop = class("ActivityBeachShop", ActivityContent)
local CardItem = class("CardItem", import("app.common.ui.FixedWrapContentItem"))
local shopTable = xyd.tables.activityBeachShopTable
local json = require("cjson")

local function getSkinNum(skinID)
	local tableIDs = xyd.tables.partnerTable:getPartnerIdBySkinId(skinID)
	local num = xyd.models.backpack:getItemNumByID(skinID)

	for _, tableID in pairs(tableIDs) do
		local group = xyd.models.slot:getListByTableID(tonumber(tableID))

		for _, partner in pairs(group) do
			local dressSkinID = partner:getSkinId()

			if dressSkinID == skinID then
				num = num + 1
			end
		end
	end

	return num
end

function ActivityBeachShop:ctor(parentGO, params, parent)
	ActivityBeachShop.super.ctor(self, parentGO, params, parent)
end

function ActivityBeachShop:getPrefabPath()
	return "Prefabs/Windows/activity/activity_beach_shop"
end

function ActivityBeachShop:resizeToParent()
	ActivityBeachShop.super.resizeToParent(self)
end

function ActivityBeachShop:initUI()
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_BEACH_SHOP, function ()
		xyd.db.misc:setValue({
			key = "activity_beach_shop_red_time",
			value = xyd.getServerTime()
		})
	end)
	self:getUIComponent()
	ActivityBeachShop.super.initUI(self)
	self:layout()
	self:onRegister()
end

function ActivityBeachShop:getUIComponent()
	local go = self.go
	self.bg = go:NodeByName("bg").gameObject
	self.partnerNode = go:NodeByName("partnerNode").gameObject
	self.groupTopLeft = go:NodeByName("groupTopLeft").gameObject
	self.partnerGroup = self.groupTopLeft:ComponentByName("partnerGroup", typeof(UISprite))
	self.partnerName = self.groupTopLeft:ComponentByName("partnerName", typeof(UILabel))
	self.labelSkinName = self.groupTopLeft:ComponentByName("labelSkinName", typeof(UILabel))
	self.groupBottom = go:NodeByName("groupBottom").gameObject
	self.btnSmall = self.groupBottom:NodeByName("btnSmall").gameObject
	self.btnShow = self.groupBottom:NodeByName("btnShow").gameObject
	self.numGroup = self.groupBottom:NodeByName("numGroup").gameObject
	self.labelNum = self.groupBottom:ComponentByName("numGroup/labelNum", typeof(UILabel))
	self.numIcon = self.groupBottom:ComponentByName("numGroup/icon", typeof(UISprite))
	self.navGroup = self.groupBottom:NodeByName("navGroup").gameObject
	self.scrollView = self.groupBottom:ComponentByName("scroller", typeof(UIScrollView))
	local cardItem = self.groupBottom:NodeByName("cardItem").gameObject
	local groupContent = self.scrollView:ComponentByName("groupContent", typeof(UIWrapContent))
	self.wrapContent = import("app.common.ui.FixedWrapContent").new(self.scrollView, groupContent, cardItem, CardItem, self)
	self.skinEffectGroup = self.groupBottom:NodeByName("skinEffectGroup").gameObject
	self.cancelEffectGroup = self.skinEffectGroup:NodeByName("cancelEffectGroup").gameObject
	self.labelSkinDesc = self.skinEffectGroup:ComponentByName("labelSkinDesc", typeof(UILabel))
	self.groupEffect1 = self.skinEffectGroup:NodeByName("groupEffect1").gameObject
	self.groupEffect2 = self.skinEffectGroup:NodeByName("groupEffect2").gameObject
	self.groupTouch = self.skinEffectGroup:NodeByName("groupTouch").gameObject
	self.groupModel = self.skinEffectGroup:NodeByName("groupModel").gameObject
end

function ActivityBeachShop:layout()
	self.selectItem = {
		skinID = 0
	}
	self.tab = require("app.common.ui.CommonTabBar").new(self.navGroup, 3, function (index)
		self:changeToggle(index)
	end, nil, {
		chosen = {
			color = Color.New2(4294967295.0),
			effectColor = Color.New2(1030530815)
		},
		unchosen = {
			color = Color.New2(1348707327)
		}
	})

	self.tab:setTexts({
		__("ACTIVITY_BEACH_SHOP_TEXT01"),
		__("ACTIVITY_BEACH_SHOP_TEXT02"),
		__("ACTIVITY_BEACH_SHOP_TEXT05")
	})

	self.labelNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.BEACH_SKIN_CARD)

	xyd.setUISpriteAsync(self.numIcon, nil, xyd.tables.itemTable:getIcon(xyd.ItemID.BEACH_SKIN_CARD))
	self:initSkinEffect()
	self:playEnterAnimation()
end

function ActivityBeachShop:playEnterAnimation()
	local ids = shopTable:getIDsByType(1)
	local buyTimes = self.activityData.detail_.buy_times
	local num = 0
	local curTime = xyd.getServerTime()

	for i = 1, #ids do
		local timeStamp = shopTable:getTime(ids[i])
		local limit = shopTable:getLimit(ids[i])

		if timeStamp <= curTime and buyTimes[ids[i]] < limit then
			num = num + 1
		end
	end

	if num > 1 then
		local count = 0
		local items = self.wrapContent:getItems()
		self.animationTime = self:getTimer(function ()
			count = (count + 1) % num

			self:changeItem(items[tostring(count + 1)])
		end, 5, -1)

		self.animationTime:Start()
	end
end

function ActivityBeachShop:initSkinEffect()
	if self.skinEffect1 then
		return
	end

	self.skinEffect1 = xyd.Spine.new(self.groupEffect1)
	self.skinEffect2 = xyd.Spine.new(self.groupEffect2)

	self.skinEffect1:setInfo("fx_ui_fazhen", function ()
		self.skinEffect1:SetLocalPosition(0, 0, -10)
		self.skinEffect1:SetLocalScale(1, 1, 1)
	end)
	self.skinEffect2:setInfo("fx_ui_fazhen", function ()
		self.skinEffect2:SetLocalPosition(0, 0, 0)
		self.skinEffect2:SetLocalScale(1, 1, 1)
	end)
	self.groupEffect1:SetActive(false)
	self.groupEffect2:SetActive(false)
end

function ActivityBeachShop:playSkinEffect()
	local skinID = self.selectItem.skinID
	local modelID = xyd.tables.equipTable:getSkinModel(skinID)
	self.labelSkinDesc.text = xyd.tables.equipTextTable:getSkinDesc(skinID)
	local name = xyd.tables.modelTable:getModelName(modelID)

	if not modelID or not name then
		return
	end

	if self.skinModel and self.skinModel:getName() == name then
		self.skinModel:play("idle", 0, 1, nil, true)
	end

	NGUITools.DestroyChildren(self.groupModel.transform)

	self.skinModel = xyd.Spine.new(self.groupModel)
	local scale = xyd.tables.modelTable:getScale(modelID)

	self.skinModel:setInfo(name, function ()
		self.skinModel:SetLocalPosition(0, 0, 0)
		self.skinModel:SetLocalScale(scale, scale, 0.7)
		self.skinModel:play("idle", 0)
	end)

	if not self.skinEffect1 then
		return
	end

	if not self.skinEffect2 then
		return
	end

	self.skinEffect1:play("texiao01", 0, 1, nil, true)
	self.skinEffect2:play("texiao02", 0, 1, nil, true)
	self.groupEffect1:SetActive(true)
	self.groupEffect2:SetActive(true)
end

function ActivityBeachShop:stopSkinEffect()
	if self.skinModel then
		self.skinModel:stop()
	end

	if self.skinEffect1 then
		self.skinEffect1:stop()
	end

	if self.skinEffect1 then
		self.skinEffect2:stop()
	end

	self.groupEffect1:SetActive(false)
	self.groupEffect2:SetActive(false)
end

function ActivityBeachShop:changeToggle(index)
	if self.animationTime and index ~= 1 then
		self.animationTime:Stop()

		self.animationTime = nil
	end

	local ids = shopTable:getIDsByType(index)
	local buyTimes = self.activityData.detail_.buy_times

	table.sort(ids, function (a, b)
		local curTime = xyd.getServerTime()
		local weighA = 0
		local weighB = 0
		local timeA = shopTable:getTime(a)

		if timeA <= curTime then
			local buys = buyTimes[a]
			local limit = shopTable:getLimit(a)

			if buys < limit then
				weighA = weighA + 10
			else
				weighA = weighA + 5
			end
		end

		local timeB = shopTable:getTime(b)

		if timeB <= curTime then
			local buys = buyTimes[b]
			local limit = shopTable:getLimit(b)

			if buys < limit then
				weighB = weighB + 10
			else
				weighB = weighB + 5
			end
		end

		if weighA ~= weighB then
			return weighB < weighA
		else
			return a < b
		end
	end)
	self.wrapContent:setInfos(ids)

	local items = self.wrapContent:getItems()

	for _, item in pairs(items) do
		if item.data == ids[1] then
			self:changeItem(item)

			break
		end
	end
end

function ActivityBeachShop:changeItem(item)
	if self.selectItem.skinID == item.skinID then
		item:showTips()
	else
		if self.selectItem.item then
			self.selectItem.item:setSelectBg(false)
		end

		item:setSelectBg(true)

		self.selectItem.item = item
		self.selectItem.skinID = item.skinID

		self:changeModel()
	end
end

function ActivityBeachShop:changeModel()
	xyd.setUISpriteAsync(self.partnerGroup, nil, "img_group" .. self.selectItem.item.group)

	self.labelSkinName.text = xyd.tables.itemTextTable:getName(self.selectItem.item.skinID)
	self.partnerName.text = xyd.tables.partnerTextTable:getName(self.selectItem.item.partnerID)
	local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(self.selectItem.skinID)
	local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(self.selectItem.skinID) * 0.75
	local dragonBoneID = xyd.tables.partnerPictureTable:getDragonBone(self.selectItem.skinID)

	if dragonBoneID and dragonBoneID ~= 0 then
		local res = xyd.tables.girlsModelTable:getResource(dragonBoneID)
		local texiaoName = xyd.tables.girlsModelTable:getTexiaoName(dragonBoneID)

		if self.partnerModel then
			self.partnerModel:destroy()
		end

		self.partnerModel = xyd.Spine.new(self.partnerNode)

		self.partnerModel:setInfo(res, function ()
			self.partnerModel:play(texiaoName, 0)
			self.partnerModel:SetLocalPosition(xy.x * 0.75, (-xy.y - 200) * 0.75, 0)
			self.partnerModel:SetLocalScale(scale, scale, scale)
		end)
	end

	if self.skinEffectGroup.activeSelf then
		self:playSkinEffect()
	end
end

function ActivityBeachShop:onRegister()
	UIEventListener.Get(self.btnShow).onClick = function ()
		if self.animationTime then
			self.animationTime:Stop()

			self.animationTime = nil
		end

		self.groupTopLeft:SetActive(false)
		self.groupBottom:SetActive(false)
	end

	UIEventListener.Get(self.btnSmall).onClick = function ()
		if self.animationTime then
			self.animationTime:Stop()

			self.animationTime = nil
		end

		self.skinEffectGroup:SetActive(true)
		self:playSkinEffect()
	end

	UIEventListener.Get(self.cancelEffectGroup).onClick = function ()
		self.skinEffectGroup:SetActive(false)
		self:stopSkinEffect()
	end

	UIEventListener.Get(self.bg).onClick = function ()
		if self.groupBottom.activeSelf == false then
			self.groupTopLeft:SetActive(true)
			self.groupBottom:SetActive(true)
		end
	end

	UIEventListener.Get(self.groupTouch).onClick = handler(self, self.onModelTouch)

	UIEventListener.Get(self.numGroup).onClick = function ()
		if self.animationTime then
			self.animationTime:Stop()

			self.animationTime = nil
		end

		xyd.WindowManager.get():openWindow("item_tips_window", {
			show_has_num = true,
			itemID = xyd.ItemID.BEACH_SKIN_CARD,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityBeachShop:onModelTouch()
	if not self.skinModel or not self.skinModel:isValid() then
		return
	end

	local tableID = self.selectItem.item.partnerID
	local mp = xyd.tables.partnerTable:getEnergyID(tableID)
	local ack = xyd.tables.partnerTable:getPugongID(tableID)
	local skillID = 0

	if xyd.getServerTime() % 2 > 0 then
		skillID = mp

		self.skinModel:play("skill", 1, 1, function ()
			self.skinModel:play("idle", -1, 1)
		end)
	else
		skillID = ack

		self.skinModel:play("attack", 1, 1, function ()
			self.skinModel:play("idle", -1, 1)
		end)
	end

	if self.skill_sound_ then
		xyd.SoundManager.get():stopSound(self.skill_sound_)
	end

	self.skill_sound_ = tostring(xyd.tables.skillTable:getSound(skillID))

	xyd.SoundManager.get():playSound(self.skill_sound_)
end

function ActivityBeachShop:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_BEACH_SHOP then
		return
	end

	local buyId = self.activityData.buyId
	local skinID = shopTable:getAwards(buyId)[1]

	xyd.WindowManager.get():openWindow("summon_effect_res_window", {
		skins = {
			skinID
		},
		callback = function ()
			xyd.models.backpack:updateSkinCollect()
		end,
		notShowCamera = getSkinNum(skinID) > 1
	})

	local items = self.wrapContent:getItems()

	for _, item in pairs(items) do
		if item.data == buyId then
			item:setBuyInfos()

			break
		end
	end
end

function ActivityBeachShop:onItemChange()
	self.labelNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.BEACH_SKIN_CARD)
end

function CardItem:ctor(go, parent)
	CardItem.super.ctor(self, go, parent)
end

function CardItem:initUI()
	self.selectBg = self.go:NodeByName("selectBg").gameObject
	local partnerCard = self.go:NodeByName("partner_card").gameObject
	self.heroBg = partnerCard:ComponentByName("heroBg", typeof(UISprite))
	self.groupIcon = partnerCard:ComponentByName("groupIcon", typeof(UISprite))
	self.mask = partnerCard:NodeByName("mask").gameObject
	self.labelNum = partnerCard:ComponentByName("labelNum", typeof(UILabel))
	self.labelSkinName = partnerCard:ComponentByName("labelSkinName", typeof(UILabel))
	self.selectImg = partnerCard:NodeByName("selectImg").gameObject
	self.labelSaleTime = partnerCard:ComponentByName("labelSaleTime", typeof(UILabel))
	self.labelLimit = self.go:ComponentByName("labelLimit", typeof(UILabel))
	self.buyBtn = self.go:NodeByName("buyBtn").gameObject
	self.labelBuy = self.buyBtn:ComponentByName("labelBuy", typeof(UILabel))
	self.buyIconImg = self.buyBtn:ComponentByName("icon", typeof(UISprite))

	self.selectBg:SetActive(false)

	UIEventListener.Get(self.go).onClick = function ()
		if self.canChange then
			if self.parent.animationTime then
				self.parent.animationTime:Stop()

				self.parent.animationTime = nil
			end

			self.parent:changeItem(self)
		end
	end

	UIEventListener.Get(self.buyBtn).onClick = function ()
		if self.parent.animationTime then
			self.parent.animationTime:Stop()

			self.parent.animationTime = nil
		end

		if xyd.models.backpack:getItemNumByID(self.buyCost[1]) < self.buyCost[2] then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.buyCost[1])))
		else
			xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_BEACH_SHOP_TEXT03", self.buyCost[2], xyd.tables.itemTextTable:getName(self.buyCost[1])), function (yes)
				if yes then
					self.parent.activityData:recordBuyId(self.data)

					local params = json.encode({
						num = 1,
						award_id = tonumber(self.data)
					})

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_BEACH_SHOP, params)
				end
			end)
		end
	end
end

function CardItem:updateInfo()
	self.skinID = shopTable:getAwards(self.data)[1]

	if self.skinID ~= self.parent.selectItem.skinID then
		self.selectBg:SetActive(false)
	else
		self.selectBg:SetActive(true)
	end

	local skinIDtoPartnerID = {
		[7197.0] = 53015,
		[7198.0] = 53013,
		[7196.0] = 55010
	}
	self.partnerID = skinIDtoPartnerID[self.skinID] or xyd.tables.partnerPictureTable:getSkinPartner(self.skinID)[1]
	self.group = xyd.tables.partnerTable:getGroup(self.partnerID)

	xyd.setUISpriteAsync(self.groupIcon, nil, "img_group" .. tostring(self.group))

	self.labelSkinName.text = xyd.tables.itemTextTable:getName(self.skinID)
	self.buyCost = shopTable:getCost(self.data)
	self.labelBuy.text = self.buyCost[2]

	xyd.setUISpriteAsync(self.buyIconImg, nil, xyd.tables.itemTable:getIcon(self.buyCost[1]))
	self:setBuyInfos()
end

function CardItem:setSelectBg(flag)
	self.selectBg:SetActive(flag)
end

function CardItem:showTips()
	xyd.WindowManager.get():openWindow("item_tips_window", {
		show_has_num = true,
		itemID = self.skinID,
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})
end

function CardItem:setBuyInfos()
	local hasNum = getSkinNum(self.skinID)

	if hasNum > 0 then
		self.labelNum:SetActive(true)

		self.labelNum.text = __("SKIN_TEXT11", hasNum)
	else
		self.labelNum:SetActive(false)
	end

	local buyTimes = self.parent.activityData.detail_.buy_times[self.data]
	local limit = shopTable:getLimit(self.data) - buyTimes
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", limit)
	local timeStamp = shopTable:getTime(self.data)

	if xyd.getServerTime() < timeStamp then
		local cardImg = shopTable:getCardImg(self.data)

		if cardImg ~= "" then
			xyd.setUISpriteAsync(self.heroBg, nil, cardImg)
		else
			xyd.setUISpriteAsync(self.heroBg, nil, xyd.tables.partnerPictureTable:getPartnerCard(self.skinID))
		end

		self.canChange = false

		xyd.setTouchEnable(self.buyBtn, false)
		xyd.applyChildrenGrey(self.buyBtn)
		self.mask:SetActive(true)
		self.selectImg:SetActive(false)
		self.labelSaleTime:SetActive(true)

		local delta = timeStamp - xyd.getServerTime()
		local day = math.floor(delta / 86400)
		local hour = math.floor((delta - day * 86400) / 3600 + 1)

		if hour > 23 then
			day = day + 1
		end

		if day > 0 then
			self.labelSaleTime.text = __("ACTIVITY_BEACH_SHOP_TEXT04", __("DAY", day))
		else
			self.labelSaleTime.text = __("ACTIVITY_BEACH_SHOP_TEXT04", __("HOUR", hour))
		end
	elseif limit == 0 then
		xyd.setUISpriteAsync(self.heroBg, nil, xyd.tables.partnerPictureTable:getPartnerCard(self.skinID))

		self.canChange = true

		self.labelSaleTime:SetActive(false)
		xyd.setTouchEnable(self.buyBtn, false)
		xyd.applyChildrenGrey(self.buyBtn)
		self.selectImg:SetActive(true)
		self.mask:SetActive(true)
	else
		xyd.setUISpriteAsync(self.heroBg, nil, xyd.tables.partnerPictureTable:getPartnerCard(self.skinID))

		self.canChange = true

		self.labelSaleTime:SetActive(false)
		self.selectImg:SetActive(false)
		self.mask:SetActive(false)
		xyd.applyChildrenOrigin(self.buyBtn)
		xyd.setTouchEnable(self.buyBtn, true)
	end
end

return ActivityBeachShop
