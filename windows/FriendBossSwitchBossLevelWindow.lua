local BaseWindow = import(".BaseWindow")
local FriendBossSwitchBossLevelWindow = class("FriendBossSwitchBossLevelWindow", BaseWindow)
local BossLevelItem = class("BossLevelItem", import("app.components.CopyComponent"))

function FriendBossSwitchBossLevelWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function FriendBossSwitchBossLevelWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	FriendBossSwitchBossLevelWindow.super.register(self)
	self:initSelectedBossLevel()
	self:initLayout()
	self:registerEvent()
end

function FriendBossSwitchBossLevelWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	local groupUp = groupAction:NodeByName("groupUp").gameObject
	self.labelWinTitle = groupUp:ComponentByName("labelWinTitle", typeof(UILabel))
	local groupCenter = groupAction:NodeByName("groupCenter").gameObject
	self.bossLevelScroller = groupCenter:NodeByName("bossLevelScroller").gameObject
	self.bossLevelScroller_uiScrollView = groupCenter:ComponentByName("bossLevelScroller", typeof(UIScrollView))
	self.bossLevelScroller_uiPanel = groupCenter:ComponentByName("bossLevelScroller", typeof(UIPanel))
	self.bossLevelScroller_uiPanel.depth = winTrans:GetComponent(typeof(UIPanel)).depth + 1
	self.bossLevelGroup = groupCenter:NodeByName("bossLevelScroller/bossLevelGroup").gameObject
	self.bossLevelGroup_uiGrid = groupCenter:ComponentByName("bossLevelScroller/bossLevelGroup", typeof(UIGrid))
	self.selectedBtn = groupAction:NodeByName("selectedBtn").gameObject
	self.selectedBtn_button_label = groupAction:ComponentByName("selectedBtn/button_label", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.friendBossLevelItem = groupAction:NodeByName("friendBossLevelItem").gameObject
end

function FriendBossSwitchBossLevelWindow:initSelectedBossLevel()
	local selectedBossLevelTemp = xyd.models.friend:getSelectedBossLevel()
	self.unlockedMaxBossLevel = xyd.models.friend:getUnlockStage()

	if selectedBossLevelTemp ~= nil then
		self.selectedBossLevel = tonumber(selectedBossLevelTemp)
	else
		self.selectedBossLevel = self.unlockedMaxBossLevel

		xyd.models.friend:setSelectedBossLev(self.selectedBossLevel)
	end
end

function FriendBossSwitchBossLevelWindow:addTitle()
end

function FriendBossSwitchBossLevelWindow:updateBossLevelList()
	local bossIds = xyd.tables.friendBossTable:getIDs()

	for i in pairs(bossIds) do
		local bossId = bossIds[i]
		local bossParams = self:packBossLevelParams(bossId)
		local bossLevelItem = NGUITools.AddChild(self.bossLevelGroup.gameObject, self.friendBossLevelItem.gameObject)
		local item = BossLevelItem.new(bossLevelItem, bossParams)

		if self.selectedBossLevel == tonumber(bossId) then
			self.selectedBossLevelItem = item
		end

		UIEventListener.Get(bossLevelItem.gameObject).onClick = handler(self, function ()
			self:onSetBossLevel(bossId, item)
		end)
	end

	self.friendBossLevelItem:SetActive(false)
	self.bossLevelGroup_uiGrid:Reposition()
end

function FriendBossSwitchBossLevelWindow:onSetBossLevel(bossId, bossLevelItem)
	local setId = bossId

	if self.selectedBossLevel == setId then
		return
	end

	self.selectedBossLevel = setId

	if self.selectedBossLevelItem then
		self.selectedBossLevelItem:setStatus(1)
	end

	self.selectedBossLevelItem = bossLevelItem

	bossLevelItem:setStatus(2)
end

function FriendBossSwitchBossLevelWindow:initLayout()
	self.labelWinTitle.text = __("BOSS_LEVEL_SWITCH")
	self.selectedBtn_button_label.text = __("BEGIN")

	self:updateBossLevelList()

	if self.selectedBossLevel >= 7 then
		self.bossLevelScroller_uiScrollView:SetLocalPosition(0, 602, 0)

		self.bossLevelScroller_uiPanel.clipOffset = Vector2(0, -338)
	end
end

function FriendBossSwitchBossLevelWindow:packBossLevelParams(id)
	local bossLevelParams = {
		avatarId = 0,
		power = 0,
		killAward = "",
		battleId = 0,
		id = 0,
		isUnLock = function ()
			if tonumber(id) <= tonumber(self.unlockedMaxBossLevel) then
				return true
			else
				return false
			end
		end,
		selectedId = self.selectedBossLevel,
		panel = self.bossLevelScroller_uiPanel,
		id = id,
		power = xyd.tables.friendBossTable:getNumber(id, "power"),
		battleId = xyd.tables.friendBossTable:getNumber(id, "battle_id"),
		killAward = xyd.tables.friendBossTable:getString(id, "kill_award"),
		avatarId = xyd.tables.friendBossTable:getNumber(id, "avatar_id")
	}

	return bossLevelParams
end

function FriendBossSwitchBossLevelWindow:onselectedTouch()
	xyd.models.friend:setSelectedBossLev(self.selectedBossLevel)

	local fWin = xyd.WindowManager.get():getWindow("friend_window")

	if fWin then
		fWin:getItemValue(4):updateFriendBossInfo(tonumber(self.selectedBossLevel))
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function FriendBossSwitchBossLevelWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_FRIEND_BOSS_INFO, handler(self, self.onGetFriendBossInfo))

	UIEventListener.Get(self.selectedBtn.gameObject).onClick = handler(self, self.onselectedTouch)
end

function FriendBossSwitchBossLevelWindow:onGetFriendBossInfo()
	self:updateBossLevelList()
end

function BossLevelItem:ctor(goItem, data)
	self.id = tonumber(data.id)
	self.data = data
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.boxEnabled = transGo:GetComponent(typeof(UnityEngine.BoxCollider))
	self.bossLevelItem = transGo:NodeByName("bossLevelItem").gameObject
	self.bossLevelGroup = transGo:ComponentByName("bossLevelItem/bossLevelGroup", typeof(UISprite))
	self.bossIconGroup = transGo:NodeByName("bossLevelItem/bossIconGroup").gameObject
	self.fightingPowerGroup = transGo:NodeByName("bossLevelItem/fightingPowerGroup").gameObject
	self.fightingPowerIcon = transGo:ComponentByName("bossLevelItem/fightingPowerGroup/fightingPowerIcon", typeof(UISprite))
	self.fightingPower = transGo:ComponentByName("bossLevelItem/fightingPowerGroup/fightingPower", typeof(UILabel))
	self.selectedFilter = transGo:ComponentByName("bossLevelItem/selectedFilter", typeof(UISprite))
	self.lockedGrey = transGo:ComponentByName("lockedGrey", typeof(UISprite))
	self.lock = transGo:ComponentByName("lock", typeof(UISprite))

	self:createChildren()
end

function BossLevelItem:createChildren()
	self:initLayout()
	self:updateItem(self.data)
end

function BossLevelItem:initLayout()
end

function BossLevelItem:updateItem(data)
	self:fillUIElement(data)

	if data.isUnLock() then
		if tonumber(data.selectedId) == tonumber(data.id) then
			self:setStatus(2)
		else
			self:setStatus(1)
		end
	else
		self:setStatus(0)
	end
end

function BossLevelItem:setStatus(num)
	if num == 0 then
		self.boxEnabled.enabled = false

		self.lock:SetActive(true)
		self.lockedGrey:SetActive(true)
		self.selectedFilter:SetActive(false)
	end

	if num == 1 then
		self.boxEnabled.enabled = true

		self.lock:SetActive(false)
		self.lockedGrey:SetActive(false)
		self.selectedFilter:SetActive(false)
	end

	if num == 2 then
		self.boxEnabled.enabled = true

		self.lock:SetActive(false)
		self.lockedGrey:SetActive(false)
		self.selectedFilter:SetActive(true)
	end
end

function BossLevelItem:fillUIElement(data)
	self:fillBossLevelSign(data)
	self:fillBossIcon(data)
	self:fillBossFightingPower(data)
end

function BossLevelItem:fillBossLevelSign(data)
	local bossLevel = data.id

	xyd.setUISpriteAsync(self.bossLevelGroup, nil, "quiz_diff_" .. tostring(bossLevel), nil, )
end

function BossLevelItem:fillBossIcon(data)
	local bossIcon = xyd.getHeroIcon({
		isMonster = false,
		noClick = true,
		tableID = data.avatarId,
		uiRoot = self.bossIconGroup,
		panel = data.panel
	})

	bossIcon:setScale(0.6)
end

function BossLevelItem:fillBossFightingPower(data)
	self.fightingPower.text = data.power
end

function BossLevelItem:packBossLevelItem(data)
	local tempLabel = MultiLabel.new()
	tempLabel.text = data.id
	tempLabel.textColor = 85
	tempLabel.percentWidth = 100
	tempLabel.percentHeight = 100
	tempLabel.horizontalCenter = 0
	tempLabel.verticalCenter = 0

	return tempLabel
end

return FriendBossSwitchBossLevelWindow
