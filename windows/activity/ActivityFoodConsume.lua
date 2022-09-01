local ActivityContent = import(".ActivityContent")
local ActivityFoodConsume = class("ActivityFoodConsume", ActivityContent)
local json = require("cjson")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local ActivityFoodConsumeItem = class("ActivityFoodConsumeItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function ActivityFoodConsume:ctor(parentGO, params, parent)
	ActivityFoodConsume.super.ctor(self, parentGO, params, parent)
end

function ActivityFoodConsume:getPrefabPath()
	return "Prefabs/Windows/activity/activity_food_consume"
end

function ActivityFoodConsume:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FOOD_CONSUME)
	self.effectList = {}
	self.normalIcons = {}
	self.choosePartnerIDs = {}
	self.curTabIndex = 1

	self:getUIComponent()
	ActivityFoodConsume.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityFoodConsume:resizeToParent()
	ActivityFoodConsume.super.resizeToParent(self)
	dump(xyd.WindowManager.get():getActiveHeight())
	dump(xyd.Global:getMaxHeight())
	dump(self.scale_num_contrary)
	self.bottomGroup:SetAnchor(self.go.gameObject, 0, 5, 0, -5, 1, 1, 0, 446 + 78 * self.scale_num_contrary)
	self:resizePosY(self.groupSingle, 243, 277)
end

function ActivityFoodConsume:getUIComponent()
	local go = self.go
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.bg2 = self.go:ComponentByName("bg2", typeof(UISprite))
	self.logoImg = self.go:ComponentByName("logoImg", typeof(UISprite))
	self.helpBtn = self.go:NodeByName("helpBtn").gameObject
	self.rolePos = self.go:ComponentByName("rolePos", typeof(UITexture))
	self.bottomGroup = self.go:ComponentByName("bottomGroup", typeof(UISprite))
	self.nav = self.bottomGroup:NodeByName("nav").gameObject

	for i = 1, 3 do
		self["tab" .. i] = self.nav:ComponentByName("tab_" .. i, typeof(UISprite))
		self["tabRedPoint" .. i] = self["tab" .. i]:ComponentByName("redPoint", typeof(UISprite))
	end

	self.groupMulty = self.bottomGroup:NodeByName("groupMulty").gameObject
	self.groupMultyScrollView = self.bottomGroup:ComponentByName("groupMulty", typeof(UIScrollView))
	self.exchangeItem = self.groupMultyScrollView:ComponentByName("warpContent/exchangeItem", typeof(UISprite))
	self.groupSingle = self.bottomGroup:NodeByName("groupSingle").gameObject
	self.previewPart = self.groupSingle:NodeByName("previewPart").gameObject
	self.previewHeroIcon = self.previewPart:NodeByName("previewHeroIcon").gameObject
	self.nooneBg = self.previewHeroIcon:ComponentByName("nooneBg", typeof(UISprite))
	self.icon_add1 = self.previewHeroIcon:ComponentByName("icon_add1", typeof(UISprite))
	self.plusImg = self.previewHeroIcon:ComponentByName("plusImg", typeof(UISprite))
	self.redPointImg = self.previewHeroIcon:ComponentByName("redPointImg", typeof(UISprite))
	self.previewIconPos = self.previewHeroIcon:NodeByName("heroIcon").gameObject
	self.labelPreview = self.previewPart:ComponentByName("labelPreview", typeof(UILabel))
	self.grid = self.previewPart:ComponentByName("grid", typeof(UIGrid))
	self.exchangeBtn = self.previewPart:ComponentByName("exchangeBtn", typeof(UISprite))
	self.icon = self.exchangeBtn:ComponentByName("icon", typeof(UISprite))
	self.numLabel = self.icon:ComponentByName("numLabel", typeof(UILabel))
	self.labelDesc = self.exchangeBtn:ComponentByName("labelDesc", typeof(UILabel))
	self.labelLimit = self.previewPart:ComponentByName("labeLimit", typeof(UILabel))
end

function ActivityFoodConsume:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_FOOD_CONSUME then
			self:onGetChoosePartnerMsg(event)
		end
	end)

	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_FOOD_CONSUME_HELP"
		})
	end)
	UIEventListener.Get(self.exchangeBtn.gameObject).onClick = handler(self, function ()
		local ids = xyd.tables.activityFoodConsumeTable:getIDsByType(self.curTabIndex)
		local id = ids[1]
		local partnerID = self.choosePartnerIDs[id]
		local leftTime = self.activityData:getLeftTime(id)

		if leftTime <= 0 then
			xyd.alertTips(__("ACTIVITY_FOOD_CONSUME_TEXT02"))
		elseif not partnerID or partnerID <= 0 then
			xyd.alertTips(__("ACTIVITY_FOOD_CONSUME_TEXT08"))
		else
			xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_FOOD_CONSUME_TEXT01"), function (yes)
				if yes then
					local partner = xyd.models.slot:getPartner(partnerID)

					if partner:isVowed() then
						xyd.alert(xyd.AlertType.YES_NO, __("VOW_SWAP_TIPS"), function (yes_no)
							if yes_no then
								self.activityData:reqExchangePartner(partnerID, self.curTabIndex, id)
							end
						end)

						return
					else
						self.activityData:reqExchangePartner(partnerID, self.curTabIndex, id)
					end
				end
			end)
		end
	end)
end

function ActivityFoodConsume:initUIComponent()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_food_consume_logo_" .. xyd.Global.lang)

	self.labelDesc.text = __("ACTIVITY_FOOD_CONSUME_TEXT07")
	self.labelPreview.text = __("ACTIVITY_FOOD_CONSUME_TEXT06")
	self.tabBar = CommonTabBar.new(self.nav, 3, function (index)
		self.curTabIndex = index

		self:updateContent()
	end, nil, , 15)
	self.tabBar.tabs[1].label.text = __("ACTIVITY_FOOD_CONSUME_TEXT03")
	self.tabBar.tabs[2].label.text = __("ACTIVITY_FOOD_CONSUME_TEXT04")
	self.tabBar.tabs[3].label.text = __("ACTIVITY_FOOD_CONSUME_TEXT05")

	if not self.roleEffect1 then
		self.roleEffect1 = xyd.Spine.new(self.rolePos.gameObject)
		local scale = 0.59

		self.roleEffect1:setInfo("heermosi_pifu02_lihui01", function ()
			self.roleEffect1:SetLocalPosition(0, -900, 0)
			self.roleEffect1:SetLocalScale(scale, scale, 1)
			self.roleEffect1:play("animation", 0, 1, function ()
			end, true)
		end)
	end
end

function ActivityFoodConsume:initData()
end

function ActivityFoodConsume:updateContent()
	if self.curTabIndex == 1 then
		self.groupMulty:SetActive(true)
		self.groupSingle:SetActive(false)
		self:updateMutyGroup()
	elseif self.curTabIndex == 2 then
		self.groupMulty:SetActive(false)
		self.groupSingle:SetActive(true)
		self:updateSingleGroup()
	elseif self.curTabIndex == 3 then
		self.groupMulty:SetActive(false)
		self.groupSingle:SetActive(true)
		self:updateSingleGroup()
	end

	self:updateRedPoint()
end

function ActivityFoodConsume:updateMutyGroup()
	self.datas = {}
	local ids = xyd.tables.activityFoodConsumeTable:getIDsByType(self.curTabIndex)

	for i = 1, #ids do
		local id = ids[i]

		table.insert(self.datas, id)
	end

	table.sort(self.datas, function (a, b)
		local leftTimeA = self.activityData:getLeftTime(a)
		local leftTimeB = self.activityData:getLeftTime(b)
		local finishA = leftTimeA <= 0
		local finishB = leftTimeB <= 0

		if finishA ~= finishB then
			return finishB
		else
			return a < b
		end
	end)

	if self.wrapContent == nil then
		local wrapContent = self.groupMulty:ComponentByName("warpContent", typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.groupMultyScrollView, wrapContent, self.exchangeItem.gameObject, ActivityFoodConsumeItem, self)
	end

	self.wrapContent:setInfos(self.datas, {})
end

function ActivityFoodConsume:updateSingleGroup()
	local ids = xyd.tables.activityFoodConsumeTable:getIDsByType(self.curTabIndex)
	local id = ids[1]
	local partnerID = self.choosePartnerIDs[id]
	local awards = xyd.tables.activityFoodConsumeTable:getAward(id)
	local cost = xyd.tables.activityFoodConsumeTable:getCost(id)
	local partnerTableID = cost[1]
	local star = xyd.tables.partnerIDRuleTable:getStar(partnerTableID)
	local group = xyd.tables.partnerIDRuleTable:getGroup(partnerTableID)
	local heroIcon = xyd.tables.partnerIDRuleTable:getIcon(partnerTableID)
	local leftTime = self.activityData:getLeftTime(id)
	local params = {
		scale = 0.9074074074074074,
		isShowSelected = false,
		uiRoot = self.previewIconPos,
		star = star,
		group = group,
		heroIcon = heroIcon,
		callback = function ()
			if leftTime <= 0 then
				return
			end

			local recordValue = self.activityData:getRecordRedPoint(id)

			if not recordValue and self.activityData:checkRedPointByTableID(id) then
				self.activityData:setRecordRedPoint(id)
				self:updateRedPoint()
			end

			local materialPartnerList = {}
			local partners = xyd.models.slot:getPartners()

			for key, partner in pairs(partners) do
				local tableID = partner:getTableID()

				if partner:getStar() == star and partner:getGroup() ~= 7 and not xyd.tables.partnerTable:checkPuppetPartner(partner:getTableID()) then
					table.insert(materialPartnerList, partner)
				end
			end

			local winParams = {
				needNum = 1,
				noClickSelected = true,
				type = "ACTIVITY_FOOD_CONSUME",
				notPlaySaoguang = true,
				isShowLovePoint = false,
				showBtnDebris = false,
				benchPartners = materialPartnerList,
				partners = partnerID and {
					partnerID
				} or nil,
				confirmCallback = function ()
					local win = xyd.WindowManager:get():getWindow("choose_partner_window")
					local selectPartnerID = (win:getSelected() or {})[1]

					self:choosePartner(selectPartnerID, id)
					self:updateSingleGroup()
				end
			}

			xyd.WindowManager:get():openWindow("choose_partner_window", winParams)
		end
	}

	if not self.previewIcon then
		self.previewIcon = xyd.getItemIcon(params, xyd.ItemIconType.HERO_ICON)
	else
		self.previewIcon:setInfo(params)
	end

	if partnerID and partnerID > 0 then
		self.previewIcon:setOrigin()
		self.plusImg:SetActive(false)
	else
		self.previewIcon:setGrey()
		self.plusImg:SetActive(true)
	end

	dump(awards)

	for i = 1, math.max(#awards, #self.normalIcons) do
		local award = awards[i]

		if award then
			local params = {
				show_has_num = true,
				scale = 0.7222222222222222,
				isShowSelected = false,
				itemID = award[1],
				num = award[2],
				uiRoot = self.grid.gameObject
			}

			if self.normalIcons[i] then
				self.normalIcons[i]:setInfo(params)
				self.normalIcons[i]:SetActive(true)
			else
				self.normalIcons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			end

			if leftTime > 0 then
				self.normalIcons[i]:setChoose(false)
			else
				self.normalIcons[i]:setChoose(true)
			end
		else
			self.normalIcons[i]:SetActive(false)
		end
	end

	if leftTime <= 0 then
		xyd.applyGrey(self.exchangeBtn:GetComponent(typeof(UISprite)))
		self.labelDesc:ApplyGrey()
	else
		xyd.applyOrigin(self.exchangeBtn:GetComponent(typeof(UISprite)))
		self.labelDesc:ApplyOrigin()
	end

	self.grid:Reposition()

	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", leftTime)
end

function ActivityFoodConsume:choosePartner(partnerID, index)
	self.choosePartnerIDs[index] = partnerID
end

function ActivityFoodConsume:onGetChoosePartnerMsg(event)
	local data = event.data
	local detail = nil

	if data and data.detail and data.detail ~= {} and data.detail ~= "" then
		detail = json.decode(data.detail)
	else
		detail = {}
	end

	local items = detail.items
	local id = self.activityData:getReqTableID()
	local award = xyd.tables.activityFoodConsumeTable:getAward(id)
	self.choosePartnerIDs = {}
	local realAwards = {}

	for _, value in pairs(award) do
		table.insert(realAwards, {
			item_id = value[1],
			item_num = value[2]
		})
	end

	local realItems = {}

	for i = 1, #items do
		local itemNum = items[i].item_num
		local itemID = items[i].item_id

		for j = 1, #award do
			if itemID == award[j][1] then
				itemNum = itemNum - award[j][2]
			end
		end

		if itemNum > 0 then
			table.insert(realItems, {
				item_id = itemID,
				item_num = itemNum
			})
		end
	end

	xyd.openWindow("gamble_rewards_window", {
		layoutCenter = true,
		wnd_type = 2,
		data = realAwards,
		callback = function ()
			xyd.itemFloat(realItems)
		end
	})
	self:updateContent()
end

function ActivityFoodConsume:updateRedPoint()
	for i = 1, 3 do
		local flag = self.activityData:checkRedPointByNav(i)

		if self.curTabIndex ~= 1 and i == self.curTabIndex then
			self.redPointImg:SetActive(flag)
		end

		self["tabRedPoint" .. i]:SetActive(flag)
	end
end

function ActivityFoodConsumeItem:ctor(go, parent)
	ActivityFoodConsumeItem.super.ctor(self, go, parent)

	self.parent = parent
end

function ActivityFoodConsumeItem:initUI()
	local go = self.go
	self.inputRoot = self.go:NodeByName("inputRoot").gameObject
	self.iconContainer = self.inputRoot:NodeByName("iconContainer").gameObject
	self.redPointImg = self.inputRoot:ComponentByName("redPointImg", typeof(UISprite))
	self.plusImg = self.inputRoot:ComponentByName("plusImg", typeof(UISprite))
	self.touchGroup = self.inputRoot:NodeByName("touchGroup").gameObject
	self.iconGroup = self.go:ComponentByName("iconGroup", typeof(UIGrid))
	self.labelLimit = self.go:ComponentByName("labelLimit", typeof(UILabel))
	self.exchangeBtn = self.go:ComponentByName("exchangeBtn", typeof(UISprite))
	self.label = self.exchangeBtn:ComponentByName("label", typeof(UILabel))
	self.icons = {}
	UIEventListener.Get(self.exchangeBtn.gameObject).onClick = handler(self, function ()
		if self.leftTime <= 0 then
			xyd.alertTips(__("ACTIVITY_FOOD_CONSUME_TEXT02"))
		elseif not self.curChoosePartnerID or self.curChoosePartnerID <= 0 then
			xyd.alertTips(__("ACTIVITY_FOOD_CONSUME_TEXT08"))
		else
			xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_FOOD_CONSUME_TEXT01"), function (yes)
				if yes then
					local partner = xyd.models.slot:getPartner(self.curChoosePartnerID)

					if partner:isVowed() then
						xyd.alert(xyd.AlertType.YES_NO, __("VOW_SWAP_TIPS"), function (yes_no)
							if yes_no then
								self.parent.activityData:reqExchangePartner(self.curChoosePartnerID, 1, self.id)
							end
						end)

						return
					else
						self.parent.activityData:reqExchangePartner(self.curChoosePartnerID, 1, self.id)
					end
				end
			end)
		end
	end)
end

function ActivityFoodConsumeItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info
	self.id = self.data

	self.go:SetActive(true)

	for i = 1, #self.icons do
		self.icons[i]:SetActive(false)
	end

	local cost = xyd.tables.activityFoodConsumeTable:getCost(self.id)
	local awards = xyd.tables.activityFoodConsumeTable:getAward(self.id)
	local partnerTableID = cost[1]
	self.leftTime = self.parent.activityData:getLeftTime(self.id)
	self.curChoosePartnerID = self.parent.choosePartnerIDs[self.id]
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", self.leftTime)
	self.label.text = __("ACTIVITY_FOOD_CONSUME_TEXT07")
	local params = {
		show_has_num = false,
		scale = 0.7962962962962963,
		isShowSelected = false,
		uiRoot = self.iconContainer.gameObject,
		dragScrollView = self.parent.groupMultyScrollView,
		callback = function ()
			if self.leftTime <= 0 then
				return
			end

			local recordValue = self.parent.activityData:getRecordRedPoint(self.id)

			if not recordValue and self.parent.activityData:checkRedPointByTableID(self.id) then
				self.parent.activityData:setRecordRedPoint(self.id)
				self.parent:updateRedPoint()
			end

			local materialPartnerList = {}
			local partners = xyd.models.slot:getPartners()

			for key, partner in pairs(partners) do
				local tableID = partner:getTableID()

				if (partnerTableID % 1000 == 999 or tableID == partnerTableID) and partner:getStar() == 6 and partner:getGroup() ~= 7 and not xyd.tables.partnerTable:checkPuppetPartner(partner:getTableID()) then
					table.insert(materialPartnerList, partner)
				end
			end

			local winParams = {
				needNum = 1,
				noClickSelected = true,
				type = "ACTIVITY_FOOD_CONSUME",
				notPlaySaoguang = true,
				isShowLovePoint = false,
				showBtnDebris = false,
				benchPartners = materialPartnerList,
				partners = self.curChoosePartnerID and {
					self.curChoosePartnerID
				} or nil,
				confirmCallback = function ()
					local win = xyd.WindowManager:get():getWindow("choose_partner_window")
					local selectPartnerID = (win:getSelected() or {})[1]

					self.parent:choosePartner(selectPartnerID, self.id)
					self:update(index, info)
				end
			}

			xyd.WindowManager:get():openWindow("choose_partner_window", winParams)
		end
	}

	if partnerTableID % 1000 == 999 then
		params.star = xyd.tables.partnerIDRuleTable:getStar(partnerTableID)
		params.group = xyd.tables.partnerIDRuleTable:getGroup(partnerTableID)
		params.heroIcon = xyd.tables.partnerIDRuleTable:getIcon(partnerTableID)
	else
		params.itemID = partnerTableID
	end

	if self.partnerIcon == nil then
		self.partnerIcon = xyd.getItemIcon(params, xyd.ItemIconType.HERO_ICON)
	else
		self.partnerIcon:setInfo(params)
	end

	if self.curChoosePartnerID then
		self.partnerIcon:setOrigin()
		self.plusImg:SetActive(false)
	else
		self.partnerIcon:setGrey()
		self.plusImg:SetActive(true)
	end

	for i = 1, math.max(#awards, #self.icons) do
		local award = awards[i]

		if award then
			local params = {
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.7962962962962963,
				isShowSelected = false,
				uiRoot = self.iconGroup.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.groupMultyScrollView
			}

			if self.icons[i] == nil then
				self.icons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.icons[i]:setInfo(params)
				self.icons[i]:SetActive(true)
			end

			if self.leftTime > 0 then
				self.icons[i]:setChoose(false)
			else
				self.icons[i]:setChoose(true)
			end
		else
			self.icons[i]:SetActive(false)
		end
	end

	if self.leftTime <= 0 then
		xyd.applyGrey(self.exchangeBtn:GetComponent(typeof(UISprite)))
		self.label:ApplyGrey()
	else
		xyd.applyOrigin(self.exchangeBtn:GetComponent(typeof(UISprite)))
		self.label:ApplyOrigin()
	end

	self.iconGroup:Reposition()

	local flag = self.parent.activityData:checkRedPointByTableID(self.id)

	self.redPointImg:SetActive(flag)
end

return ActivityFoodConsume
