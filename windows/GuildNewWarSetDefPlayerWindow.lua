local BaseWindow = import(".BaseWindow")
local GuildNewWarSetDefPlayerWindow = class("GuildNewWarSetDefPlayerWindow", BaseWindow)
local GuildNewWarSetDefPlayerItem = class("GuildNewWarSetDefPlayerItem", import("app.common.ui.FixedMultiWrapContentItem"))
local CommonTabBar = import("app.common.ui.CommonTabBar")

function GuildNewWarSetDefPlayerWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.filterIndex = 0
	self.sortType = 1
	self.items = {}
	self.selectedItem = nil
	self.selectedPlayerID = params.selectedPlayerID
	self.oldSelectedPlayerID = params.selectedPlayerID
	self.nodeIndex = params.nodeIndex
	self.flagIndex = params.flagIndex
	self.model = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)
end

function GuildNewWarSetDefPlayerWindow:initWindow()
	self:getUIComponent()
	GuildNewWarSetDefPlayerWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function GuildNewWarSetDefPlayerWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.midGoup = self.groupAction:NodeByName("midGoup").gameObject
	self.playerItem = self.midGoup:NodeByName("playerItem").gameObject
	self.playerScroller = self.midGoup:NodeByName("playerScroller").gameObject
	self.playerScrollView = self.playerScroller:ComponentByName("", typeof(UIScrollView))
	self.playerGroup = self.playerScroller:NodeByName("playerGroup").gameObject
	self.drag = self.midGoup:NodeByName("drag").gameObject
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.filter = self.bottomGroup:NodeByName("filter").gameObject
	self.nav = self.filter:NodeByName("nav").gameObject

	for i = 1, 3 do
		self["tab" .. i] = self.nav:NodeByName("tab_" .. i).gameObject
		self["labelTab" .. i] = self["tab" .. i]:ComponentByName("label", typeof(UILabel))
		self["iconTab" .. i] = self["tab" .. i]:ComponentByName("icon", typeof(UISprite))
		self["filterChosen" .. i] = self["tab" .. i]:ComponentByName("chosen", typeof(UISprite))
	end

	self.sortBtn = self.filter:NodeByName("sortBtn").gameObject
	self.arrow = self.sortBtn:ComponentByName("arrow", typeof(UISprite))
	self.labelSortBtn = self.sortBtn:ComponentByName("label", typeof(UILabel))
	self.sortPop = self.filter:NodeByName("sortPop").gameObject

	for i = 1, 3 do
		self["sortTab" .. i] = self.sortPop:NodeByName("tab_" .. i).gameObject
		self["labelSortTab" .. i] = self["sortTab" .. i]:ComponentByName("label", typeof(UILabel))
		self["sortChosen" .. i] = self["sortTab" .. i]:ComponentByName("chosen", typeof(UISprite))
	end

	self.btnCancel = self.bottomGroup:NodeByName("btnCancel").gameObject
	self.labelCancel = self.btnCancel:ComponentByName("labelCancel", typeof(UILabel))
	self.btnSure = self.bottomGroup:NodeByName("btnSure").gameObject
	self.labelSure = self.btnSure:ComponentByName("labeSure", typeof(UILabel))
	local wrapContent = self.playerScrollView:ComponentByName("playerGroup", typeof(MultiRowWrapContent))
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.playerScrollView, wrapContent, self.playerItem, GuildNewWarSetDefPlayerItem, self)
end

function GuildNewWarSetDefPlayerWindow:initUIComponent()
	self.labelTitle.text = __("GUILD_NEW_WAR_TEXT28")
	self.labelSure.text = __("CONFIRM")
	self.labelCancel.text = __("CANCEL_2")
	self.labelTab1.text = __("GUILD_NEW_WAR_TEXT32")
	self.labelTab2.text = __("GUILD_NEW_WAR_TEXT31")
	self.labelTab3.text = __("GUILD_NEW_WAR_TEXT30")
	self.labelSortTab1.text = __("GUILD_NEW_WAR_TEXT33")
	self.labelSortTab2.text = __("GUILD_NEW_WAR_TEXT98")
	self.labelSortTab3.text = __("GUILD_NEW_WAR_TEXT97")
	self.sortTab = CommonTabBar.new(self.sortPop, 3, function (index)
		if self.sortType ~= index then
			self:onClickSortBtn()
		end

		self.sortType = index

		self:updateSortGroup()
	end, nil, {
		chosen = {
			color = Color.New2(4294967295.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	})

	self:updateTabGroup()
	self:updateSortGroup()
	self:updateContent()
end

function GuildNewWarSetDefPlayerWindow:updateContent()
	self.infos = self.model:getDefPlayerData()
	local realData = {}

	for key, value in pairs(self.infos) do
		local nodeIndex = value.nodeIndex
		local nodeType = self.model:getNodeType(nodeIndex)

		if self.filterIndex == 0 then
			table.insert(realData, value)
		elseif self.filterIndex == 1 and (nodeType == xyd.GuildNewWarNodeType.LEFT_FRONT or nodeType == xyd.GuildNewWarNodeType.RIGHT_FRONT) then
			table.insert(realData, value)
		elseif self.filterIndex == 2 and (nodeType == xyd.GuildNewWarNodeType.LEFT_MID or nodeType == xyd.GuildNewWarNodeType.MID or nodeType == xyd.GuildNewWarNodeType.RIGHT_MID) then
			table.insert(realData, value)
		elseif self.filterIndex == 3 and nodeType == xyd.GuildNewWarNodeType.MAIN then
			table.insert(realData, value)
		end
	end

	table.sort(realData, function (a, b)
		local nodeIndexA = a.nodeIndex
		local nodeIndexB = b.nodeIndex
		local flagIndexA = a.flagIndex
		local flagIndexB = b.flagIndex
		local freeA = false
		local freeB = false
		local powerA = a.power
		local powerB = b.power

		if not nodeIndexA then
			freeA = true
		end

		if not nodeIndexB then
			freeB = true
		end

		if self.sortType == 1 then
			if freeA ~= freeB then
				return freeA
			elseif freeA then
				return true
			elseif nodeIndexA ~= nodeIndexB then
				return nodeIndexB < nodeIndexA
			else
				return flagIndexA < flagIndexB
			end
		elseif self.sortType == 2 then
			return powerB < powerA
		elseif self.sortType == 3 then
			return powerA < powerB
		else
			return false
		end
	end)

	self.realData = realData

	self.multiWrap_:setInfos(realData, {})
	self.playerScrollView:ResetPosition()
end

function GuildNewWarSetDefPlayerWindow:updateTabGroup()
	local iconUnchosenArr = {
		"guild_new_war2_bg_qianl_1",
		"guild_new_war2_bg_zhongl_1",
		"guild_new_war2_bg_hou_1"
	}
	local iconChosenArr = {
		"guild_new_war2_bg_qianl",
		"guild_new_war2_bg_zhongl",
		"guild_new_war2_bg_houl"
	}

	for i = 1, 3 do
		self["filterChosen" .. i]:SetActive(i == self.filterIndex)

		if i == self.filterIndex then
			self["labelTab" .. i].color = Color.New2(4294967295.0)
			self["labelTab" .. i].effectColor = Color.New2(1012112383)

			xyd.setUISpriteAsync(self["iconTab" .. i], nil, iconChosenArr[i])
		else
			self["labelTab" .. i].color = Color.New2(960648191)
			self["labelTab" .. i].effectColor = Color.New2(4294967295.0)

			xyd.setUISpriteAsync(self["iconTab" .. i], nil, iconUnchosenArr[i])
		end
	end
end

function GuildNewWarSetDefPlayerWindow:updateSortGroup()
	for i = 1, 4 do
		self.sortTab:setTabEnable(i, false)
	end

	self:updateContent()

	local textArr = {
		__("GUILD_NEW_WAR_TEXT33"),
		__("GUILD_NEW_WAR_TEXT98"),
		__("GUILD_NEW_WAR_TEXT97")
	}
	self.labelSortBtn.text = textArr[self.sortType]

	for i = 1, 3 do
		self.sortTab:setTabEnable(i, true)
	end
end

function GuildNewWarSetDefPlayerWindow:onClickSortBtn()
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
		self.arrow.transform:SetLocalScale(1, 1, 1)
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
		self.arrow.transform:SetLocalScale(1, -1, 1)
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

function GuildNewWarSetDefPlayerWindow:selectPlayer(playerID, item)
	self.selectedItem = item
	self.selectedPlayerID = playerID
end

function GuildNewWarSetDefPlayerWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnCancel).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		local ops = {}

		if self.oldSelectedPlayerID and self.oldSelectedPlayerID > 0 and self.selectedPlayerID ~= self.oldSelectedPlayerID then
			local op = {
				op = 2,
				base_id = self.nodeIndex,
				flag_id = self.flagIndex,
				player_id = self.oldSelectedPlayerID
			}

			table.insert(ops, op)
		end

		if self.selectedPlayerID and self.selectedPlayerID > 0 then
			local oldNodeIndex = 0
			local oldFlagIndex = 0

			for i = 1, #self.realData do
				if self.realData[i].playerInfo.playerID == self.selectedPlayerID then
					oldNodeIndex = self.realData[i].nodeIndex
					oldFlagIndex = self.realData[i].flagIndex
				end
			end

			if oldFlagIndex and oldFlagIndex > 0 then
				local op = {
					op = 2,
					base_id = oldNodeIndex,
					flag_id = oldFlagIndex,
					player_id = self.selectedPlayerID
				}

				table.insert(ops, op)
			end

			local op = {
				op = 1,
				base_id = self.nodeIndex,
				flag_id = self.flagIndex,
				player_id = self.selectedPlayerID
			}

			table.insert(ops, op)
		end

		if #ops > 0 then
			self.model:reqBatchSetFlag(ops, function ()
				local wnd = xyd.getWindow("guild_new_war_map_window")

				if wnd then
					wnd:updateMapNodes()
				end

				local wnd2 = xyd.getWindow("guild_new_war_preview_window")

				if wnd2 then
					wnd2:updateFlagList()
				end

				xyd.alertTips(__("GUILD_NEW_WAR_TEXT85"))
			end)
		end

		self:close()
	end

	UIEventListener.Get(self.sortBtn).onClick = function ()
		self:onClickSortBtn()
	end

	for i = 1, 3 do
		UIEventListener.Get(self["tab" .. i]).onClick = function ()
			if self.filterIndex == i then
				self.filterIndex = 0
			else
				self.filterIndex = i
			end

			self:updateTabGroup()
			self:updateContent()
		end
	end
end

function GuildNewWarSetDefPlayerWindow:willClose()
	BaseWindow.willClose(self)
end

function GuildNewWarSetDefPlayerItem:ctor(go, parent)
	GuildNewWarSetDefPlayerItem.super.ctor(self, go, parent)

	self.parent = parent
end

function GuildNewWarSetDefPlayerItem:initUI()
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.rolePos = self.go:NodeByName("rolePos").gameObject
	self.labelPlayerName = self.go:ComponentByName("labelPlayerName", typeof(UILabel))
	self.labelPower = self.go:ComponentByName("labelPower", typeof(UILabel))
	self.labelState = self.go:ComponentByName("labelState", typeof(UILabel))
	self.selectGroup = self.go:NodeByName("selectGroup").gameObject
	self.defingGroup = self.go:NodeByName("defingGroup").gameObject
	self.icon = self.defingGroup:ComponentByName("icon", typeof(UISprite))
	self.iconLeader = self.labelPlayerName:NodeByName("icon").gameObject

	UIEventListener.Get(self.go).onClick = function ()
		if self.parent.selectedPlayerID then
			if self.parent.selectedPlayerID ~= self.data.playerInfo.playerID then
				self.parent.selectedPlayerID = self.data.playerInfo.playerID

				self.parent.selectedItem:checkChoose()

				self.parent.selectedItem = self

				self:checkChoose()
			else
				self.parent.selectedPlayerID = nil

				self.parent.selectedItem:checkChoose()

				self.parent.selectedItem = nil
			end
		else
			self.parent.selectedItem = self
			self.parent.selectedPlayerID = self.data.playerInfo.playerID

			self:checkChoose()
		end
	end
end

function GuildNewWarSetDefPlayerItem:update(wrapIndex, index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info

	self:updateInfo(wrapIndex, index)
	dump(wrapIndex)
	dump(index)
end

function GuildNewWarSetDefPlayerItem:updateInfo(wrapIndex, index)
	self.labelPlayerName.text = self.data.playerInfo.playerName
	self.labelPower.text = self.data.playerInfo.power

	if self.parent.selectedPlayerID == self.data.playerInfo.playerID then
		self.parent.selectedItem = self
	end

	if self.data.playerInfo.job and self.data.playerInfo.job == xyd.GUILD_JOB.LEADER then
		self.iconLeader:SetActive(true)
	else
		self.iconLeader:SetActive(false)
	end

	if self.data.nodeIndex and self.data.nodeIndex > 0 then
		self.defingGroup:SetActive(true)
		self.labelState:SetActive(false)

		self.nodeType = self.parent.model:getNodeType(self.data.nodeIndex)
		local textID = xyd.tables.guildNewWarBaseTable:getTextId1(self.nodeType)
		self.labelState.text = xyd.tables.guildNewWarBaseTextTable:getDesc(textID)
		local helpArr = {
			[xyd.GuildNewWarNodeType.LEFT_FRONT] = "guild_new_war2_bg_qianl",
			[xyd.GuildNewWarNodeType.RIGHT_FRONT] = "guild_new_war2_bg_qianl",
			[xyd.GuildNewWarNodeType.LEFT_MID] = "guild_new_war2_bg_zhongl",
			[xyd.GuildNewWarNodeType.MID] = "guild_new_war2_bg_zhongl",
			[xyd.GuildNewWarNodeType.RIGHT_MID] = "guild_new_war2_bg_zhongl",
			[xyd.GuildNewWarNodeType.MAIN] = "guild_new_war2_bg_houl"
		}

		xyd.setUISpriteAsync(self.icon, nil, helpArr[self.nodeType])
	else
		self.defingGroup:SetActive(false)
		self.labelState:SetActive(true)

		self.labelState.text = __("GUILD_NEW_WAR_TEXT83")
	end

	self.rolePos:ComponentByName("", typeof(UITexture)).depth = 100 + 10 * index

	if not self.roleModel then
		self.roleModel = import("app.components.SenpaiModel").new(self.rolePos.gameObject)
	end

	self.roleModel:setModelInfo({
		isNewClipShader = true,
		ids = self.data.playerInfo.dress_style,
		pos = Vector3(0, -150, 0),
		textureSize = Vector2(200, 300)
	})
	self.roleModel:setRenderTarget(self.rolePos, 1)
	self.rolePos:SetActive(false)
	self:waitForFrame(1, function ()
		self.rolePos:SetActive(true)
	end)
	self:checkChoose()
end

function GuildNewWarSetDefPlayerItem:checkChoose()
	if self.data and self.data.playerInfo and self.data.playerInfo.playerID == self.parent.selectedPlayerID then
		self.selectGroup:SetActive(true)
	else
		self.selectGroup:SetActive(false)
	end

	if self.data.nodeIndex and self.data.nodeIndex > 0 then
		self.defingGroup:SetActive(true)
		self.labelState:SetActive(false)
	else
		self.defingGroup:SetActive(false)
		self.labelState:SetActive(true)
	end
end

return GuildNewWarSetDefPlayerWindow
