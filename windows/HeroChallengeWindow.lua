local BaseWindow = import(".BaseWindow")
local HeroChallengeWindow = class("HeroChallengeWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local WindowTop = import("app.components.WindowTop")
local BaseComponent = import("app.components.BaseComponent")
local HeroChallengeItem = class("HeroChallengeItem", BaseComponent)
local HeroChallengeSelectItem = class("HeroChallengeSelectItem", BaseComponent)
local PartnerChallengeChessTable = xyd.tables.partnerChallengeChessTable
local PartnerChallengeSpeedTable = xyd.tables.partnerChallengeSpeedTable
local PartnerChallengeTable = xyd.tables.partnerChallengeTable
local PartnerChallengeTypeTable = xyd.tables.partnerChallengeTypeTable
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.heroChallengeItem = HeroChallengeItem.new(go)

	self.heroChallengeItem:setDragScrollView(parent.scrollView)
end

function ItemRender:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.heroChallengeItem.data = info

	self.go:SetActive(true)
	self.heroChallengeItem:update()
end

function ItemRender:getGameObject()
	return self.go
end

function HeroChallengeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.selectType = 0
	self.selectItems = {}
end

function HeroChallengeWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	self.labelTitle_.text = __("HERO_CHALLENGE_TITLE")

	self:initResItem()
	self:initData()
	self:register()
end

function HeroChallengeWindow:getUIComponent()
	local trans = self.window_.transform
	self.ani = trans:GetComponent(typeof(UnityEngine.Animation))
	self.groupMain_ = trans:NodeByName("groupMain_").gameObject
	self.scrollView = self.groupMain_:ComponentByName("scroller_", typeof(UIScrollView))
	self.wrapContentNode_ = self.scrollView:ComponentByName("itemGroup", typeof(UIWrapContent))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, self.wrapContentNode_, itemContainer, ItemRender, self)
	self.labelTitle_ = self.groupMain_:ComponentByName("topContainer/labelTitle_", typeof(UILabel))
	self.selectsNode = self.groupMain_:NodeByName("downContainer/selectsNode").gameObject
end

function HeroChallengeWindow:updateSelectItems()
	local types = {}

	for k, v in pairs(self.selectTypes) do
		table.insert(types, k)
	end

	table.sort(types)

	local allChildren = self.selectsNode.transform.childCount

	if allChildren ~= #types then
		self.selectItems = {}

		NGUITools.DestroyChildren(self.selectsNode.transform)

		for i = #types, 1, -1 do
			local selectItem = HeroChallengeSelectItem.new(self.selectsNode, {
				fatherWindow = self,
				type = types[i]
			})

			table.insert(self.selectItems, selectItem)
		end
	end

	for k, v in ipairs(self.selectItems) do
		v:updateIsSelected(v.type == self.selectType)
	end
end

function HeroChallengeWindow:enableScroller(flag)
	self.scrollView.enabled = flag
end

function HeroChallengeWindow:playOpenAnimation(callback)
	callback()

	local localPosition = self.groupMain_.transform.localPosition

	self.groupMain_:SetLocalPosition(-1000, localPosition.y, 0)
	self:setTimeout(function ()
		self.ani:Play("openwindow")
		self:waitForTime(0.58, function ()
			self:setWndComplete()
		end, nil)
	end, self, 200)
end

function HeroChallengeWindow:register()
	HeroChallengeWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.FIGHT_CHESS, handler(self, self.onFight))
	self.eventProxy_:addEventListener(xyd.event.RESET_FORT_CHESS, handler(self, self.onReset))
	self.eventProxy_:addEventListener(xyd.event.PARTNER_CHALLENGE_FIGHT, handler(self, self.onFight))
	self.eventProxy_:addEventListener(xyd.event.PARTNER_CHALLENGE_RESET_FORT, handler(self, self.onReset))
end

function HeroChallengeWindow:onFight()
	self:initData()
end

function HeroChallengeWindow:onReset()
	self:initData()
end

function HeroChallengeWindow:initResItem()
	self.windowTop = WindowTop.new(self.window_, self.name_, 1, true)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function HeroChallengeWindow:initData(type)
	if type then
		if type == self.selectType then
			self.selectType = 0
		else
			self.selectType = type
		end
	end

	local data = {}
	local list = xyd.tables.partnerChallengeTable:getFortIds()
	local list_chess = xyd.tables.partnerChallengeChessTable:getFortIds()
	local heroChallenge = xyd.models.heroChallenge
	local fortIDs = {}

	for fortID in pairs(list) do
		table.insert(fortIDs, tonumber(fortID))
	end

	for fortID in pairs(list_chess) do
		table.insert(fortIDs, tonumber(fortID))
	end

	self.selectTypes = {}

	for i = 1, #fortIDs do
		local fortID = fortIDs[i]
		local current_stage = heroChallenge:getCurrentStage(fortID)

		if xyd.tables.partnerChallengeChessTable:getFortType(fortID) == xyd.HeroChallengeFort.CHESS then
			current_stage = xyd.checkCondition(current_stage == -1, list_chess[fortID][1], current_stage)
		elseif list[fortID] then
			current_stage = xyd.checkCondition(current_stage == -1, list[fortID][1], current_stage)
		end

		if self:checkFortShow(fortID, current_stage) then
			table.insert(data, {
				fort_id = fortID,
				id = current_stage
			})
		end
	end

	table.sort(data, function (a, b)
		local fortInfoA = xyd.models.heroChallenge:getFortInfoByFortID(a.fort_id)
		local fortInfoB = xyd.models.heroChallenge:getFortInfoByFortID(b.fort_id)

		if fortInfoA and fortInfoB then
			local aNum = 0
			local bNum = 0
			local listA = self:getFortTable(a.fort_id):getIdsByFort(a.fort_id)
			local listB = self:getFortTable(b.fort_id):getIdsByFort(b.fort_id)
			local maxStageA = listA[#listA]
			local maxStageB = listB[#listB]
			local maxFightStageA = fortInfoA.base_info.fight_max_stage
			local maxFightStageB = fortInfoB.base_info.fight_max_stage

			if maxFightStageA == 0 then
				aNum = aNum + 100
			elseif maxFightStageA ~= maxStageA then
				aNum = aNum + 10000
				aNum = aNum + (10 - (maxStageA - maxFightStageA)) * 1000
			end

			if maxFightStageB == 0 then
				bNum = bNum + 100
			elseif maxFightStageB ~= maxStageB then
				bNum = bNum + 10000
				bNum = bNum + (10 - (maxStageB - maxFightStageB)) * 1000
			end

			aNum = aNum + self:getFortTable(a.fort_id):getIndex(a.fort_id, a.id)
			bNum = bNum + self:getFortTable(b.fort_id):getIndex(b.fort_id, b.id)
			aNum = aNum + a.fort_id * 0.01
			bNum = bNum + b.fort_id * 0.01

			return aNum > bNum
		end

		return false
	end)
	self.wrapContent:setInfos(data, {})
	self:updateSelectItems()
end

function HeroChallengeWindow:getFortTable(fort_id)
	local fortTable = nil

	if fort_id == xyd.HeroChallengeFort.SPEED then
		fortTable = PartnerChallengeSpeedTable
	elseif xyd.tables.partnerChallengeChessTable:getFortType(fort_id) == xyd.HeroChallengeFort.CHESS then
		fortTable = PartnerChallengeChessTable
	else
		fortTable = PartnerChallengeTable
	end

	return fortTable
end

function HeroChallengeWindow:checkFortShow(fort_id, id)
	local activity_id = xyd.tables.partnerChallengeTable:getActivityByFortId(fort_id)
	local fortTable = self:getFortTable(fort_id)

	if not xyd.models.heroChallenge:getFortInfoByFortID(fort_id) then
		return false
	end

	if id then
		local sType = fortTable:getType(id)

		if sType then
			self.selectTypes[sType] = true

			if self.selectType ~= 0 and sType ~= self.selectType then
				return false
			end
		end
	end

	if activity_id == 0 or activity_id == nil or activity_id == nil then
		return true
	end

	if not xyd.models.activityModel:getActivity(activity_id) then
		return true
	end

	return false
end

function HeroChallengeSelectItem:ctor(parentGo, params)
	HeroChallengeSelectItem.super.ctor(self, parentGo)

	self.type = params.type
	self.fatherWindow = params.fatherWindow

	xyd.setUISpriteAsync(self.icon, nil, "h_challenge_type_" .. self.type)
end

function HeroChallengeSelectItem:getPrefabPath()
	return "Prefabs/Components/hero_challenge_select_item"
end

function HeroChallengeSelectItem:initUI()
	HeroChallengeItem.super.initUI(self)
	self:getUIComponent()
	self:registerEvent()
end

function HeroChallengeSelectItem:getUIComponent()
	local go = self.go
	self.icon = go:ComponentByName("icon", typeof(UISprite))
	self.chose = go:NodeByName("chosen").gameObject
end

function HeroChallengeSelectItem:registerEvent()
	UIEventListener.Get(self.go).onClick = handler(self, function ()
		self.fatherWindow:initData(self.type)
	end)
end

function HeroChallengeSelectItem:updateIsSelected(isSelect)
	self.chose:SetActive(isSelect)
end

function HeroChallengeItem:ctor(parentGo)
	HeroChallengeItem.super.ctor(self, parentGo)
end

function HeroChallengeItem:getPrefabPath()
	return "Prefabs/Components/hero_challenge_item"
end

function HeroChallengeItem:initUI()
	HeroChallengeItem.super.initUI(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function HeroChallengeItem:getUIComponent()
	local go = self.go
	self.content = go:NodeByName("content").gameObject
	self.imgBg = self.content:ComponentByName("imgBg", typeof(UISprite))
	self.labelFortName = self.content:ComponentByName("labelFortName", typeof(UILabel))
	self.labelFortDes = self.content:ComponentByName("labelFortDes", typeof(UILabel))
	self.imgComplete = self.content:ComponentByName("imgComplete", typeof(UISprite))
	self.redPoint = self.content:ComponentByName("redPoint", typeof(UISprite))
	self.modeBtn = self.content:ComponentByName("modeBtn", typeof(UISprite))
	self.tip = self.modeBtn:NodeByName("tipGroup").gameObject
	self.mask = self.tip:NodeByName("mask").gameObject
	self.title = self.tip:ComponentByName("labelName", typeof(UILabel))
	self.desc = self.tip:ComponentByName("labelDesc", typeof(UILabel))
	self.icon = self.tip:ComponentByName("icon", typeof(UISprite))
	self.giftNode = self.content:NodeByName("giftNode").gameObject
	self.levelText = self.giftNode:ComponentByName("levelText", typeof(UILabel))
	self.hasGuide = xyd.GuideController:get():isPlayGuide()
end

function HeroChallengeItem:layout()
	xyd.setUISpriteAsync(self.imgComplete, nil, "mail_icon06")
end

function HeroChallengeItem:registerEvent()
	self:setTouchListener(handler(self, self.onClickFortItem))

	UIEventListener.Get(self.modeBtn.gameObject).onClick = handler(self, self.showTips)
	UIEventListener.Get(self.mask).onClick = handler(self, function ()
		self.tip:SetActive(false)
	end)
end

function HeroChallengeItem:showTips()
	self.tip:SetActive(true)
	xyd.setUISpriteAsync(self.icon, nil, "h_challenge_type_" .. self.type)

	self.title.text = PartnerChallengeTypeTable:getName(self.type)
	self.desc.text = PartnerChallengeTypeTable:getDesc(self.type)
end

function HeroChallengeItem:update()
	self.name = "HeroChallengeItem" .. tostring(self.itemIndex)
	self.fortId = self.data.fort_id
	self.id = self.data.id

	if self.fortId == xyd.HeroChallengeFort.SPEED then
		self.FortTable = PartnerChallengeSpeedTable
	elseif xyd.tables.partnerChallengeChessTable:getFortType(self.fortId) == xyd.HeroChallengeFort.CHESS then
		self.FortTable = PartnerChallengeChessTable
	else
		self.FortTable = PartnerChallengeTable
	end

	self:initItem()
end

function HeroChallengeItem:initItem()
	self.labelFortName.text = self.FortTable:fortName(self.id)
	self.type = self.FortTable:getType(self.id)
	local fortInfo = xyd.models.heroChallenge:getFortInfoByFortID(self.fortId)
	local flag = false

	if fortInfo then
		local maxFightStage = fortInfo.base_info.fight_max_stage
		local list = self.FortTable:getIdsByFort(self.fortId)
		local listLen = #list
		local maxStage = list[listLen]

		if maxFightStage == maxStage then
			flag = true
		else
			local startLev = 0

			if maxFightStage ~= 0 then
				startLev = 10 - (maxStage - maxFightStage)
			end

			self.levelText.text = startLev .. "/10"
		end
	end

	if flag then
		self.imgComplete:SetActive(true)
		self.giftNode:SetActive(false)
	else
		self.imgComplete:SetActive(false)
		self.giftNode:SetActive(true)
	end

	local fortId = tostring(self.FortTable:getIndex(self.fortId, self.id)) .. "."

	if xyd.Global.lang == "fr_fr" then
		fortId = fortId .. " "
	end

	self.labelFortDes.text = tostring(fortId) .. tostring(self.FortTable:name(self.id))

	self:updateRedPoint()

	local spriteName = nil

	if xyd.tables.partnerChallengeChessTable:getFortType(self.fortId) == xyd.HeroChallengeFort.CHESS then
		spriteName = xyd.tables.partnerChallengeChessTable:getFortImg(self.fortId)
	else
		spriteName = "btn_h_challenge_" .. self.fortId
	end

	xyd.setUISpriteAsync(self.imgBg, nil, spriteName)
	xyd.setUISpriteAsync(self.modeBtn, nil, "h_challenge_type_" .. self.type)
end

function HeroChallengeItem:onClickFortItem()
	xyd.models.heroChallenge:saveRedInfo(self.fortId)
	self:updateRedPoint()

	local wnd = xyd.WindowManager.get():getWindow("hero_challenge_window")

	if wnd then
		wnd:enableScroller(true)
	end

	xyd.WindowManager.get():openWindow("hero_challenge_detail_window", {
		fort_id = self.fortId,
		isGuiding = self.hasGuide
	})
end

function HeroChallengeItem:updateRedPoint()
	if xyd.models.heroChallenge:checkItemShowRed(self.fortId) then
		self.redPoint:SetActive(true)
	else
		self.redPoint:SetActive(false)
	end
end

return HeroChallengeWindow
