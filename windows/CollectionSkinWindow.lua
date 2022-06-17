local CollectionSkinWindow = class("CollectionSkinWindow", import(".BaseWindow"))
local PartnerCardRender = class("PartnerCardRender", import("app.common.ui.FixedMultiWrapContentItem"))
local PartnerCard = import("app.components.PartnerCard")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local ThemeItem = class("ThemeItem", import("app.common.ui.FlexibleWrapContentItem"))
local LuaFlexibleWrapContent = import("app.common.ui.FlexibleWrapContent")

function CollectionSkinWindow:ctor(name, params)
	CollectionSkinWindow.super.ctor(self, name, params)

	self.sortParnters_ = {}

	if params and params.chosenGroup then
		self.chosenGroup_ = params.chosenGroup
	else
		self.chosenGroup_ = 0
	end

	if params and params.unable_move then
		self.unableMove = params.unable_move
	else
		self.unableMove = false
	end

	if params and params.collectionInfo then
		self.collectionInfo = params.collectionInfo
	end

	if xyd.getServerTime() - xyd.models.collection:getGetCollectionTime() > 60 then
		xyd.models.collection:reqCollectionInfo()
	else
		self.canInit = true
	end

	self.fromSchoolChoose = params.fromSchoolChoose
	self.sortType = 2
end

function CollectionSkinWindow:initWindow()
	CollectionSkinWindow.super.initWindow(self)
	self:getComponent()
	self:initTopGroup()
	self:initLayout()

	if self.canInit then
		self.canInit = false

		self:initData()
		self:updateRankGroup()
		self:updateContent()
	end

	self:register()
end

function CollectionSkinWindow:getComponent()
	local winTrans = self.window_:NodeByName("group")
	self.midGroup_ = winTrans
	self.topGroup = self.midGroup_:NodeByName("topGroup").gameObject
	self.labeBuffEffect = self.topGroup:ComponentByName("labeBuffEffect", typeof(UILabel))
	self.labelLevel = self.topGroup:ComponentByName("labelLevel", typeof(UILabel))
	self.labelTitle = self.topGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.progressGroup = self.topGroup:NodeByName("progressGroup").gameObject
	self.progressBg = self.progressGroup:ComponentByName("progressBg", typeof(UISprite))
	self.progressBar = self.progressGroup:ComponentByName("", typeof(UISlider))
	self.progressLabel_ = self.progressGroup:ComponentByName("progressLabel_", typeof(UILabel))
	self.btnHelp = self.topGroup:NodeByName("btnHelp").gameObject
	self.btnLevelUp = self.topGroup:NodeByName("btnLevelUp").gameObject
	self.effectPos = self.progressGroup:ComponentByName("effectPos", typeof(UITexture))
	self.editGroup = self.midGroup_:NodeByName("editGroup").gameObject
	self.textEdit = self.editGroup:ComponentByName("textEdit_", typeof(UILabel))
	self.textEditBefore = self.editGroup:ComponentByName("textEditBefore", typeof(UILabel))
	self.btnCancel = self.editGroup:NodeByName("btnCancel").gameObject
	self.groupChoose = self.midGroup_:NodeByName("groupChoose").gameObject
	self.labelHaveGot = self.groupChoose:ComponentByName("labelHaveGot", typeof(UILabel))
	self.btnHaveGot = self.groupChoose:NodeByName("img").gameObject
	self.imgHaveGot = self.groupChoose:ComponentByName("img/imgSelect", typeof(UISprite))
	self.btnFind = self.midGroup_:NodeByName("btnFind").gameObject
	self.theme_item = winTrans:NodeByName("theme_item").gameObject
	self.themeScrollView = winTrans:ComponentByName("themeContent", typeof(UIScrollView))
	self.themeItemContent = self.themeScrollView:NodeByName("grid").gameObject
	local partnerCardRoot = winTrans:NodeByName("partnerCardRoot").gameObject
	self.partnerCardRoot = partnerCardRoot
	self.nav = winTrans:NodeByName("filter/nav").gameObject

	for i = 1, 4 do
		self["tab" .. i] = self.nav:NodeByName("tab_" .. i).gameObject
		self["chosen" .. i] = self["tab" .. i]:NodeByName("chosen").gameObject
		self["unchosen" .. i] = self["tab" .. i]:NodeByName("unchosen").gameObject
		self["tabLabel" .. i] = self["tab" .. i]:ComponentByName("label", typeof(UILabel))
	end

	self.sortBtn = winTrans:NodeByName("filter/sortBtn").gameObject
	self.sortBtnArrow = self.sortBtn:NodeByName("arrow")
	self.sortBtnLable = self.sortBtn:ComponentByName("label", typeof(UILabel))
	self.sortPop = winTrans:NodeByName("filter/sortPop").gameObject
	self.labelByTime = self.sortPop:ComponentByName("tab_1/label", typeof(UILabel))
	self.labelByTheme = self.sortPop:ComponentByName("tab_2/label", typeof(UILabel))
	self.labelByRank = self.sortPop:ComponentByName("tab_3/label", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("content", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("content/grid", typeof(MultiRowWrapContent))
	self.wrapContent_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, partnerCardRoot, PartnerCardRender, self)
	self.partnerNone = winTrans:NodeByName("partnerNone").gameObject
	self.labelNoneTips = self.partnerNone:ComponentByName("labelNoneTips", typeof(UILabel))
	self.filteByGroup = winTrans:NodeByName("filter/filteByGroup").gameObject

	for i = 1, 7 do
		self["filter" .. i] = winTrans:NodeByName("filter/filteByGroup/group" .. i).gameObject
		self["groupFilterChosen" .. i] = self["filter" .. i]:NodeByName("chosen").gameObject
	end
end

function CollectionSkinWindow:playOpenAnimation(callback)
	CollectionSkinWindow.super.playOpenAnimation(self, function ()
		local y = self.midGroup_.localPosition.y
		self.playOpenAnimation_ = true
		local action1 = self:getSequence()
		self.midGroup_.localPosition.x = -720

		action1:Insert(0.2, self.midGroup_:DOLocalMove(Vector3(50, y, 0), 0.3))
		action1:Insert(0.5, self.midGroup_:DOLocalMove(Vector3(0, y, 0), 0.27))
		action1:AppendCallback(function ()
			self.playOpenAnimation_ = false
		end)

		if callback then
			callback()
		end
	end)
end

function CollectionSkinWindow:initData()
	self.lev = xyd.models.collection:getSkinCollectionLevel()
	self.point = xyd.models.backpack:getItemNumByID(377)
	self.curLevPoint = 0

	if self.lev > 0 then
		self.curLevPoint = xyd.tables.collectionSkinEffectTable:getPoint(self.lev)
	end

	local maxLev = #xyd.tables.collectionSkinEffectTable:getIDs()
	self.nextLevPoint = xyd.tables.collectionSkinEffectTable:getPoint(math.min(self.lev + 1, maxLev))

	self:updateData()
end

function CollectionSkinWindow:updateData()
	if self.sortType == 2 then
		self.collectionDatasByTheme = {}
		local themeIDs = xyd.tables.collectionSkinGroupTable:getIDs()

		for _, themeID in ipairs(themeIDs) do
			local skinIDs = xyd.tables.collectionSkinGroupTable:getSkins(themeID)
			local showIDs = {}

			for _, skinID in ipairs(skinIDs) do
				local collectionID = xyd.tables.itemTable:getCollectionId(skinID)

				if self:canShow(collectionID) then
					table.insert(showIDs, collectionID)
				end
			end

			if #showIDs > 0 then
				table.insert(self.collectionDatasByTheme, {
					themeID = themeID,
					showIDs = showIDs
				})
			end
		end

		table.sort(self.collectionDatasByTheme, function (a, b)
			local rankA = xyd.tables.collectionSkinGroupTable:getRank(a.themeID)
			local rankB = xyd.tables.collectionSkinGroupTable:getRank(b.themeID)

			return rankA < rankB
		end)
	else
		self.collectionDatas = {}
		local collectionIDs = xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.SKIN)

		for _, collectionID in ipairs(collectionIDs) do
			if self:canShow(collectionID) then
				local skin_id = xyd.tables.collectionTable:getItemId(collectionID)
				local tableList = xyd.tables.partnerPictureTable:getSkinPartner(skin_id)

				table.insert(self.collectionDatas, {
					collectionID = collectionID,
					skin_id = skin_id,
					tableID = xyd.checkCondition(tableList and #tableList > 0, tableList[1], 0),
					group = xyd.tables.partnerTable:getGroup(tableList[1]),
					qlt = xyd.tables.collectionTable:getQlt(collectionID)
				})
			end
		end

		table.sort(self.collectionDatas, function (a, b)
			return b.skin_id < a.skin_id
		end)
	end

	if self.sortType == 3 then
		table.sort(self.collectionDatas, function (a, b)
			if a.qlt == b.qlt then
				return b.skin_id < a.skin_id
			else
				return b.qlt < a.qlt
			end
		end)
	end
end

function CollectionSkinWindow:initTopGroup()
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}
	self.windowTop_ = import("app.components.WindowTop").new(self.window_, self.name_)

	self.windowTop_:setItem(items)
end

function CollectionSkinWindow:initLayout()
	self.sortPop:SetActive(false)

	self.labelTitle.text = __("COLLECTION_SKIN_TEXT01")
	self.labelByRank.text = __("COLLECTION_SKIN_TEXT12")
	self.labelByTheme.text = __("COLLECTION_SKIN_TEXT06")
	self.labelByTime.text = __("COLLECTION_SKIN_TEXT11")
	self.sortBtnLable.text = __("COLLECTION_SKIN_TEXT06")
	self.labelNoneTips.text = __("NO_SKINS_TIPS")
	self.tabLabel1.text = __("COLLECTION_SKIN_TEXT07")
	self.tabLabel2.text = __("COLLECTION_SKIN_TEXT08")
	self.tabLabel3.text = __("COLLECTION_SKIN_TEXT09")
	self.tabLabel4.text = __("COLLECTION_SKIN_TEXT10")
	self.labelHaveGot.text = __("COLLECTION_SKIN_TEXT04")
	self.textEditBefore.text = __("COLLECTION_SKIN_TEXT05")

	xyd.addTextInput(self.textEdit, {
		max_line = 1,
		type = xyd.TextInputArea.InputSingleLine,
		textBack = __("COLLECTION_SKIN_TEXT05"),
		textBackLabel = self.textEditBefore,
		callback = function ()
			if self.checkStr ~= self.textEdit.text then
				self.checkStr = string.upper(tostring(self.textEdit.text))

				self:updateContent()
			end
		end
	})
	self.filteByGroup:SetActive(false)

	self.curContentIndex = 2
	self.showFindGroup = false
	self.checkHave = true

	self.imgHaveGot:SetActive(self.checkHave)
	self.groupChoose:SetActive(not self.showFindGroup)
	self.editGroup:SetActive(self.showFindGroup)
end

function CollectionSkinWindow:updateRankGroup()
	self.lev = xyd.models.collection:getSkinCollectionLevel()

	if self.lev > 0 then
		self.curLevPoint = xyd.tables.collectionSkinEffectTable:getPoint(self.lev)
	end

	local maxLev = #xyd.tables.collectionSkinEffectTable:getIDs()
	self.nextLevPoint = xyd.tables.collectionSkinEffectTable:getPoint(math.min(self.lev + 1, maxLev))
	self.progressLabel_.text = self.point .. "/" .. self.nextLevPoint
	self.progressBar.value = math.min((self.point - self.curLevPoint) / math.max(1, self.nextLevPoint - self.curLevPoint), 1)
	self.labelLevel.text = self.lev

	if self.lev >= 0 then
		local effects = xyd.tables.collectionSkinEffectTable:getEffect(math.max(1, self.lev))
		local attrText = ""

		for i = 1, #effects do
			local text = xyd.tables.dBuffTable:getDesc(effects[i][1])
			local factor = xyd.tables.dBuffTable:getFactor(effects[i][1])

			if self.lev == 0 then
				effects[i][2] = 0
			end

			if xyd.tables.dBuffTable:isPercent(effects[i][1]) then
				text = text .. " +" .. string.format("%.1f", effects[i][2] * 100) .. "%"
			elseif factor and factor > 0 then
				text = text .. " +" .. string.format("%.1f", effects[i][2] * 100 / factor) .. "%"
			else
				text = text .. " +" .. effects[i][2]
			end

			attrText = attrText .. text

			if i ~= #effects then
				attrText = attrText .. ", "
			end
		end

		self.labeBuffEffect.text = "[c][5e6996]" .. __("COLLECTION_SKIN_TEXT03") .. " " .. "[-][/c]" .. "[c][369900]" .. attrText .. "[-][/c]"
	end

	self.btnLevelUp:SetActive(self.nextLevPoint <= self.point)

	if self.nextLevPoint <= self.point and not self.levelUpEffect then
		self.levelUpEffect = xyd.Spine.new(self.btnLevelUp)

		self.levelUpEffect:setInfo("fx_shengxing", function ()
			self.levelUpEffect:play("texiao01", 0, 1)
		end, true)
	end
end

function CollectionSkinWindow:register()
	CollectionSkinWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function (event)
		local items = event.data.items
		local flag = false

		for i = 1, #items do
			local item = items[i]
			local item_id = item.item_id
			local type = xyd.tables.itemTable:getType(item_id)
			local collection_id = xyd.tables.itemTable:getCollectionId(item_id)

			if type == xyd.ItemType.SKIN and collection_id and collection_id > 0 then
				flag = true

				break
			end
		end

		if flag then
			self:updateContent()
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_COLLECTION_INFO, function ()
		if not self.canInit then
			self.canInit = true

			self:initData()
			self:updateRankGroup()
			self:updateContent()
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.UPDATE_SKIN_BONUS, function ()
		self.effectPos:SetActive(true)

		if not self.up_effect then
			self.up_effect = xyd.Spine.new(self.effectPos.gameObject)

			self.up_effect:setInfo("fx_ui_saoxing", function ()
				self.up_effect:play("texiao01", 1, 1.5, function ()
					self.effectPos:SetActive(false)
					self:updateRankGroup()
					xyd.alertTips(__("COLLECTION_SKIN_TEXT02"))
				end)
			end)
		else
			self.up_effect:play("texiao01", 1, 1.5, function ()
				self.effectPos:SetActive(false)
				self:updateRankGroup()
				xyd.alertTips(__("COLLECTION_SKIN_TEXT02"))
			end)
		end
	end)

	UIEventListener.Get(self.sortBtn).onClick = handler(self, self.onClickSortBtn)
	UIEventListener.Get(self.btnLevelUp).onClick = handler(self, self.onClickBtnLevelUp)

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "COLLECTION_SKIN_HELP"
		})
	end

	UIEventListener.Get(self.btnFind).onClick = function ()
		if not self.showFindGroup then
			self.btnFind:ComponentByName("", typeof(UnityEngine.BoxCollider)).enabled = false
			self.showFindGroup = true

			self.groupChoose:SetActive(false)
			self.editGroup:SetActive(true)
		end
	end

	UIEventListener.Get(self.btnHaveGot).onClick = function ()
		if not self.checkHave then
			self.checkHave = true
		else
			self.checkHave = false
		end

		self.imgHaveGot:SetActive(self.checkHave)
		self:updateContent()
	end

	UIEventListener.Get(self.topGroup).onClick = function ()
		xyd.openWindow("skin_buff_detail_window", {})
	end

	UIEventListener.Get(self.btnCancel).onClick = function ()
		self.showFindGroup = false

		self.groupChoose:SetActive(true)
		self.editGroup:SetActive(false)

		self.btnFind:ComponentByName("", typeof(UnityEngine.BoxCollider)).enabled = true
		self.checkStr = nil
		self.textEdit.text = ""

		self.textEditBefore:SetActive(true)

		self.textEditBefore.text = __("COLLECTION_SKIN_TEXT05")

		self:updateContent()
	end

	for i = 1, 4 do
		UIEventListener.Get(self["tab" .. i]).onClick = function ()
			self:onClickTab(i)
		end
	end

	for i = 1, 7 do
		UIEventListener.Get(self["filter" .. i]).onClick = function ()
			self:onClickGroupFilter(i)
		end
	end

	self.sortTab = CommonTabBar.new(self.sortPop, 3, function (index)
		self:changeSortType(index)
	end)
end

function CollectionSkinWindow:updateContent()
	self:updateData()

	local collection = self.collectionDatas

	if self.sortType == 2 then
		collection = self.collectionDatasByTheme
	end

	if next(collection) == nil then
		self.partnerNone:SetActive(true)
	else
		self.partnerNone:SetActive(false)
	end

	if self.sortType ~= 2 then
		self.scrollView_.gameObject:SetActive(true)
		self.themeScrollView.gameObject:SetActive(false)
		self.wrapContent_:setInfos(collection, {})
	elseif self.sortType == 2 then
		self.themeScrollView.gameObject:SetActive(true)
		self.scrollView_.gameObject:SetActive(false)

		self.themeDatas = collection

		if not self.themeWrapContent then
			self.themeWrapContent = LuaFlexibleWrapContent.new(self.themeScrollView.gameObject, ThemeItem, self.theme_item, self.themeItemContent, self.themeScrollView, nil, self)
		end

		self.themeWrapContent:update()
		self.themeWrapContent:setDataNum(#self.themeDatas)
	end
end

function CollectionSkinWindow:onClickSortBtn()
	local sequence2 = self:getSequence()
	local sortPopTrans = self.sortPop.transform
	local p = self.sortPop:GetComponent(typeof(UIPanel))
	local sortPopY = 92

	local function getter()
		return Color.New(1, 1, 1, p.alpha)
	end

	local function setter(color)
		p.alpha = color.a
	end

	if self.sortPop.activeSelf == true then
		self.sortBtnArrow.transform:SetLocalScale(1, 1, 1)
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY + 17, 0.067))
		sequence2:Insert(0.067, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0.1))
		sequence2:Insert(0.067, sortPopTrans:DOLocalMoveY(sortPopY - 58, 0.1))
		sequence2:Insert(0.167, sortPopTrans:DOLocalMoveY(sortPopY, 0))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil

			self.sortPop:SetActive(false)
		end)
	else
		self.sortPop:SetActive(true)
		self.sortBtnArrow.transform:SetLocalScale(1, -1, 1)
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY - 58, 0))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0))
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY + 17, 0.1))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.1))
		sequence2:Insert(0.1, sortPopTrans:DOLocalMoveY(sortPopY, 0.2))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil
		end)
	end
end

function CollectionSkinWindow:canShow(collectionID)
	local flag = true

	if self.checkHave == true and not xyd.models.collection:isGot(collectionID) then
		return false
	end

	local themeID = xyd.tables.collectionTable:getGroup(collectionID)

	if self.themeTabIndex then
		if self.sortType == 2 and xyd.tables.collectionSkinGroupTable:getType(themeID) ~= self.themeTabIndex then
			return false
		elseif self.sortType == 3 and xyd.tables.collectionTable:getQlt(collectionID) ~= self.themeTabIndex then
			return false
		end
	end

	if self.groupFilterIndex then
		local skin_id = xyd.tables.collectionTable:getItemId(collectionID)
		local tableList = xyd.tables.partnerPictureTable:getSkinPartner(skin_id)
		local group = xyd.tables.partnerTable:getGroup(tableList[1])

		if group ~= self.groupFilterIndex then
			return false
		end
	end

	if self.checkStr then
		local skin_id = xyd.tables.collectionTable:getItemId(collectionID)
		local tableList = xyd.tables.partnerPictureTable:getSkinPartner(skin_id)
		local skinName = string.upper(xyd.tables.itemTextTable:getName(skin_id))
		local partnerName = string.upper(xyd.tables.partnerTable:getName(tableList[1]))
		local themeName = string.upper(xyd.tables.collectionSkinGroupTextTable:getName(themeID))

		if self:containSubStr(skinName, self.checkStr) or self:containSubStr(partnerName, self.checkStr) or self:containSubStr(themeName, self.checkStr) then
			return true
		else
			return false
		end
	end

	return true
end

function CollectionSkinWindow:containSubStr(str, substr)
	if string.find(str, substr, 1) ~= nil then
		return true
	else
		return false
	end
end

function CollectionSkinWindow:getDatas()
	if self.sortType == 2 then
		return self.collectionDatasByTheme
	else
		return self.collectionDatas
	end
end

function CollectionSkinWindow:onClickTab(index)
	if self.themeTabIndex == index then
		self.themeTabIndex = nil
	else
		self.themeTabIndex = index
	end

	for i = 1, 4 do
		self["chosen" .. i]:SetActive(self.themeTabIndex == i)
		self["unchosen" .. i]:SetActive(self.themeTabIndex ~= i)

		if self.themeTabIndex == i then
			self["tabLabel" .. i].color = Color.New2(4278124287.0)
		else
			self["tabLabel" .. i].color = Color.New2(960513791)
		end
	end

	self:updateContent()
end

function CollectionSkinWindow:onClickGroupFilter(index)
	if self.groupFilterIndex == index then
		self.groupFilterIndex = nil
	else
		self.groupFilterIndex = index
	end

	for i = 1, 7 do
		self["groupFilterChosen" .. i]:SetActive(self.groupFilterIndex == i)
	end

	self:updateContent()
end

function CollectionSkinWindow:onClickBtnLevelUp()
	xyd.models.collection:reqUpdateSkinBonus()
end

function CollectionSkinWindow:getFromSchoolChoose()
	return self.fromSchoolChoose
end

function CollectionSkinWindow:changeSortType(index)
	if index ~= self.sortType then
		self:onClickSortBtn()

		self.sortType = index

		for i = 1, 3 do
			self.sortTab:setTabEnable(i, false)
		end

		local textArr = {
			[2] = {
				__("COLLECTION_SKIN_TEXT07"),
				__("COLLECTION_SKIN_TEXT08"),
				__("COLLECTION_SKIN_TEXT09"),
				__("COLLECTION_SKIN_TEXT10")
			},
			[3] = {
				__("COLLECTION_SKIN_TEXT13"),
				__("COLLECTION_SKIN_TEXT14"),
				__("COLLECTION_SKIN_TEXT15"),
				__("COLLECTION_SKIN_TEXT16")
			}
		}

		if self.sortType == 2 or self.sortType == 3 then
			self.filteByGroup:SetActive(false)
			self.nav:SetActive(true)

			self.groupFilterIndex = nil
			self.themeTabIndex = nil

			for i = 1, 4 do
				self["tabLabel" .. i].text = textArr[self.sortType][i]

				self["chosen" .. i]:SetActive(self.themeTabIndex == i)
				self["unchosen" .. i]:SetActive(self.themeTabIndex ~= i)

				if self.themeTabIndex == i then
					self["tabLabel" .. i].color = Color.New2(4278124287.0)
				else
					self["tabLabel" .. i].color = Color.New2(960513791)
				end
			end
		else
			self.filteByGroup:SetActive(true)
			self.nav:SetActive(false)

			self.groupFilterIndex = nil
			self.themeTabIndex = nil

			for i = 1, 7 do
				self["groupFilterChosen" .. i]:SetActive(self.groupFilterIndex == i)
			end
		end

		self:updateContent()

		local textArr = {
			__("COLLECTION_SKIN_TEXT11"),
			__("COLLECTION_SKIN_TEXT06"),
			__("COLLECTION_SKIN_TEXT12")
		}
		self.sortBtnLable.text = textArr[self.sortType]
	end

	for i = 1, 3 do
		self.sortTab:setTabEnable(i, true)
	end
end

function PartnerCardRender:ctor(go, parent, panel)
	PartnerCardRender.super.ctor(self, go, parent)

	self.parent_ = parent
	self.panel_ = panel or self.parent_.scrollView_.gameObject:GetComponent(typeof(UIPanel))
end

function PartnerCardRender:initUI()
	self.card_ = PartnerCard.new(self.go, self.panel_)

	UIEventListener.Get(self.go).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		local params = {
			skin_id = self.data.skin_id,
			collectionID = self.collectionID
		}

		if self.parent_.parent and self.parent_.parent.sortType and self.parent_.parent.sortType == 2 then
			params.themeID = xyd.tables.collectionTable:getGroup(self.collectionID)
		end

		xyd.WindowManager.get():openWindow("collection_skin_detail_window", params)
	end
end

function PartnerCardRender:updateInfo()
	local info = self.data
	self.collectionID = xyd.tables.itemTable:getCollectionId(info.skin_id)

	self.card_:setSkinCard(self.data)

	if xyd.models.collection:isGot(self.collectionID) then
		self.card_:applyOrigin()
	else
		self.card_:applyGrey()
	end
end

function PartnerCardRender:SetActive(flag)
	self.go:SetActive(flag)
end

function ThemeItem:ctor(go, parent, realIndex)
	ThemeItem.super.ctor(self, go, parent)

	self.realIndex = realIndex
end

function ThemeItem:initUI()
	local go = self.go
	self.labelTheme = self.go:ComponentByName("labelTheme", typeof(UILabel))
	self.line = self.go:ComponentByName("line", typeof(UISprite))
	self.contentGroup = self.go:NodeByName("contentGroup").gameObject
	self.contentGroup_Layout = self.go:ComponentByName("contentGroup", typeof(UILayout))
	self.dot = self.go:ComponentByName("dot", typeof(UISprite))
	self.btndetail = self.go:NodeByName("btndetail").gameObject
	self.labelNum = self.go:ComponentByName("labelNum", typeof(UILabel))

	UIEventListener.Get(self.btndetail).onClick = function ()
		xyd.openWindow("skin_theme_buff_window", {
			theme_id = self.themeID
		})
	end

	self.items = {}
	self.panel = self.parent.scrollView_.gameObject:GetComponent(typeof(UIPanel))
end

function ThemeItem:refresh()
	self.data = self.parent.collectionDatasByTheme[-self.realIndex]

	if not self.data then
		self.go.gameObject:SetActive(false)

		return
	else
		self.go.gameObject:SetActive(true)
	end

	self.themeID = self.data.themeID
	self.skinIDs = xyd.tables.collectionSkinGroupTable:getSkins(self.themeID)
	self.gotNum = 0

	for i = 1, #self.items do
		self.items[i]:SetActive(false)
	end

	local count = 1

	for i = 1, #self.skinIDs do
		local skin_id = self.skinIDs[i]
		local collectionID = xyd.tables.itemTable:getCollectionId(skin_id)

		if xyd.models.collection:isGot(collectionID) then
			self.gotNum = self.gotNum + 1
		end

		local flag = false
		flag = self.parent:canShow(collectionID)

		if flag then
			if not self.items[count] then
				local tmp = NGUITools.AddChild(self.contentGroup, self.parent.partnerCardRoot)
				local item = PartnerCardRender.new(tmp, self, self.panel)
				self.items[count] = item
			else
				self.items[count]:SetActive(true)
			end

			local skin_id = xyd.tables.collectionTable:getItemId(collectionID)
			local tableList = xyd.tables.partnerPictureTable:getSkinPartner(skin_id)
			local params = {
				tableID = xyd.checkCondition(tableList and #tableList > 0, tableList[1], 0),
				group = xyd.tables.itemTable:getGroup(collectionID),
				skin_id = skin_id,
				themeID = self.themeID,
				group = xyd.tables.partnerTable:getGroup(tableList[1]),
				qlt = xyd.tables.collectionTable:getQlt(collectionID)
			}

			self.items[count]:update(nil, , params)

			count = count + 1
		end
	end

	self.labelTheme.text = xyd.tables.collectionSkinGroupTextTable:getName(self.themeID)
	self.labelNum.text = self.gotNum .. "/" .. #self.skinIDs
	self.go:ComponentByName("", typeof(UIWidget)).height = self:getHeight()

	self.contentGroup_Layout:Reposition()
end

function ThemeItem:onTouchAward()
	self.parent:getAward()
end

function ThemeItem:getHeight()
	local data = self.parent.collectionDatasByTheme[-self.realIndex]

	if data and data.themeID then
		return math.ceil(math.max(#data.showIDs - 4, 0) / 4) * 265 + 315
	end

	return 315
end

return CollectionSkinWindow
