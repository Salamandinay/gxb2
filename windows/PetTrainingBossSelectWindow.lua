local BaseWindow = import(".BaseWindow")
local PetTrainingBossSelectWindow = class("PetTrainingBossSelectWindow", BaseWindow)
local BossLevelItem = class("BossLevelItem", import("app.components.CopyComponent"))

function PetTrainingBossSelectWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.bossID = params.boss_id
	self.nowID = params.boss_id
	self.Lv = params.lv
end

function PetTrainingBossSelectWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	PetTrainingBossSelectWindow.super.register(self)
	self:initLayout()
	self:registerEvent()
end

function PetTrainingBossSelectWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	local groupUp = groupAction:NodeByName("groupUp").gameObject
	self.labelWinTitle_ = groupUp:ComponentByName("labelWinTitle", typeof(UILabel))
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

function PetTrainingBossSelectWindow:initList()
	local bossIds = xyd.tables.petTrainingBossTable:getIds()

	for i in pairs(bossIds) do
		local bossId = bossIds[i]
		local bossParams = {
			lv = xyd.tables.petTrainingBossTable:getLevel(bossId),
			text = xyd.tables.petTrainingTextTable:getBoss(bossId)
		}
		local bossLevelItem = NGUITools.AddChild(self.bossLevelGroup.gameObject, self.friendBossLevelItem.gameObject)
		local item = BossLevelItem.new(bossLevelItem, bossParams)

		if xyd.models.petTraining:getTrainingLevel() < xyd.tables.petTrainingBossTable:getLevel(bossId) then
			item:setStatus(0)

			UIEventListener.Get(item.goItem_).onClick = handler(self, function ()
				xyd.showToast(__("PET_TRAINING_TEXT16", xyd.tables.petTrainingBossTable:getLevel(bossId)))
			end)
		else
			item:setStatus(1)

			UIEventListener.Get(item.goItem_).onClick = handler(self, function ()
				self:onSetBossLevel(bossId, item)
			end)
		end

		if tonumber(self.bossID) == tonumber(bossId) then
			self.selectedItem = item

			item:setStatus(2)
		end
	end

	self.friendBossLevelItem:SetActive(false)
	self.bossLevelGroup_uiGrid:Reposition()
end

function PetTrainingBossSelectWindow:onSetBossLevel(bossId, bossLevelItem)
	local setId = bossId

	if self.nowID == setId then
		return
	end

	self.nowID = setId

	if self.selectedItem then
		self.selectedItem:setStatus(1)
	end

	self.selectedItem = bossLevelItem

	bossLevelItem:setStatus(2)
end

function PetTrainingBossSelectWindow:initLayout()
	self.labelWinTitle_.text = __("BOSS_LEVEL_SWITCH")
	self.selectedBtn_button_label.text = __("BEGIN")

	self:initList()
end

function PetTrainingBossSelectWindow:onselectedTouch()
	if self.nowID == self.bossID then
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("PET_TRAINING_TEXT20"), function (yes)
		if yes then
			xyd.models.petTraining:selectBoss(self.nowID)
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end)
end

function PetTrainingBossSelectWindow:registerEvent()
	UIEventListener.Get(self.selectedBtn.gameObject).onClick = handler(self, self.onselectedTouch)
end

function BossLevelItem:ctor(goItem, data)
	self.data = data
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.bossLevelItem = transGo:NodeByName("bossLevelItem").gameObject
	self.bossLevelGroup = transGo:ComponentByName("bossLevelItem/bossLevelGroup", typeof(UISprite))
	self.bossIconGroup = transGo:NodeByName("bossLevelItem/bossIconGroup").gameObject
	self.fightingPowerGroup = transGo:NodeByName("bossLevelItem/fightingPowerGroup").gameObject
	self.fightingPowerIcon = transGo:ComponentByName("bossLevelItem/fightingPowerGroup/fightingPowerIcon", typeof(UISprite))
	self.fightingPower = transGo:ComponentByName("bossLevelItem/fightingPowerGroup/fightingPower", typeof(UILabel))
	self.selectedFilter = transGo:ComponentByName("bossLevelItem/selectedFilter", typeof(UISprite))
	self.lockedGrey = transGo:ComponentByName("lockedGrey", typeof(UISprite))
	self.lock = transGo:ComponentByName("lock", typeof(UISprite))

	self:updateItem(data)
end

function BossLevelItem:setStatus(num)
	if num == 0 then
		self.lock:SetActive(true)
		self.lockedGrey:SetActive(true)
		self.selectedFilter:SetActive(false)
	end

	if num == 1 then
		self.lock:SetActive(false)
		self.lockedGrey:SetActive(false)
		self.selectedFilter:SetActive(false)
	end

	if num == 2 then
		self.lock:SetActive(false)
		self.lockedGrey:SetActive(false)
		self.selectedFilter:SetActive(true)
	end
end

function BossLevelItem:updateItem(data)
	self:fillBossLevelSign(data)
	self:fillBossFightingPower(data)
end

function BossLevelItem:fillBossLevelSign(data)
	local bossLevel = data.lv

	xyd.setUISpriteAsync(self.bossLevelGroup, nil, "quiz_diff_" .. tostring(bossLevel), nil, )
end

function BossLevelItem:fillBossFightingPower(data)
	self.fightingPower.text = data.text
end

return PetTrainingBossSelectWindow
