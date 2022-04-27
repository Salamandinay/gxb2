local BaseWindow = import(".BaseWindow")
local FriendBossWindow = class("FriendBossWindow", BaseWindow)
local FriendModel = xyd.models.friend
local OldSize = {
	w = 720,
	h = 1280
}

function FriendBossWindow:ctor(name, params)
	FriendBossWindow.super.ctor(self, name, params)

	self.friendID_ = params.friend_id
	self.baseInfo_ = params.base_info
end

function FriendBossWindow:initWindow()
	FriendBossWindow.super.initWindow(self)

	self.content_ = self.window_:ComponentByName("groupAction", typeof(UISprite))
	self.panel_ = self.window_:GetComponent(typeof(UIPanel))
	local contentTrans = self.content_.transform
	local sWidth, sHeight = xyd.getScreenSize()
	local activeHeight = xyd.WindowManager.get():getActiveHeight()
	local activeWidth = xyd.WindowManager.get():getActiveWidth()

	if sHeight / sWidth <= 1.4 then
		contentTrans.localScale = Vector3(1.15, 1.15, 1.15)
		contentTrans.localPosition = Vector3(0, contentTrans.localPosition.y * 1.15, 0)
	else
		contentTrans.localScale = Vector3(activeWidth / OldSize.w, activeHeight / OldSize.h, 1)
		contentTrans.localPosition = Vector3(0, contentTrans.localPosition.y * activeHeight / OldSize.h, 0)
	end

	self.labelWinTitle_ = contentTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.labelTime_ = contentTrans:ComponentByName("imgBg/groupTop/groupTime/labelNextEnergy", typeof(UILabel))
	self.labelTimeNum_ = contentTrans:ComponentByName("imgBg/groupTop/groupTime/energyCountDown", typeof(UILabel))
	self.labelTili_ = contentTrans:ComponentByName("imgBg/groupTop/groupTili/label", typeof(UILabel))
	self.iconImg_ = contentTrans:ComponentByName("imgBg/groupTop/groupTili/image", typeof(UISprite))
	self.scrollView_ = contentTrans:ComponentByName("imgBg/groupBoss/scrollView", typeof(UIScrollView))
	self.gridOfBossIcon_ = contentTrans:ComponentByName("imgBg/groupBoss/scrollView/gridOfBossIcon", typeof(UIGrid))
	self.bossIconRoot_ = contentTrans:ComponentByName("imgBg/groupBoss/bossIconRoot", typeof(UIWidget)).gameObject
	self.progressBar_ = contentTrans:ComponentByName("imgBg/groupBoss/progressBar", typeof(UIProgressBar))
	self.progressLabel_ = contentTrans:ComponentByName("imgBg/groupBoss/progressBar/labelDesc", typeof(UILabel))
	self.btnFight_ = contentTrans:ComponentByName("btnFight", typeof(UISprite)).gameObject
	self.btnFightLabel_ = contentTrans:ComponentByName("btnFight/label", typeof(UILabel))
	self.btnSweeep_ = contentTrans:ComponentByName("btnSweep", typeof(UISprite)).gameObject
	self.btnSweeepLabel_ = contentTrans:ComponentByName("btnSweep/label", typeof(UILabel))
	self.closeBtn = contentTrans:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.labelLevel = contentTrans:ComponentByName("imgBg/groupTop/labelLevel", typeof(UILabel))

	self.bossIconRoot_:SetActive(false)

	local scrollPanel = self.scrollView_:GetComponent(typeof(UIPanel))
	scrollPanel.depth = self.panel_.depth + 1

	self:layout()
	self:initHeros()
	self:initTime()
	self:register()
	self:initBtn()
end

function FriendBossWindow:layout()
	self.labelTime_.text = __("FRIEND_RECOVER_TILI")
	self.labelTili_.text = tostring(FriendModel:getTili())
	self.labelWinTitle_.text = __("FRIEND_BOSS_WINDOW")

	xyd.setUISpriteAsync(self.iconImg_, nil, "friend_icon_tili", nil, )
end

function FriendBossWindow:initTime()
	local cd = tonumber(xyd.tables.miscTable:getVal("friend_energy_cd"))
	local maxTili = tonumber(xyd.tables.miscTable:getVal("friend_energy_max"))
	local baseInfo = FriendModel:getBaseInfo()
	local lastTime = baseInfo.energy_time or 0
	local duration = cd - (xyd.getServerTime() - lastTime) % cd
	local tili = FriendModel:getTili()

	if tili < maxTili and duration > 0 then
		local params = {
			duration = duration,
			callback = function ()
				if self.labelTimeNum_ then
					self.labelTimeNum_.text = "00:00:00"
				end
			end
		}

		if not self.countDown_ then
			self.countDown_ = import("app.components.CountDown").new(self.labelTimeNum_, params)
		else
			self.countDown_:setInfo(params)
		end
	else
		self.labelTimeNum_.text = "00:00:00"
	end
end

function FriendBossWindow:initHeros()
	local table = xyd.tables.friendBossTable

	for i = 0, self.gridOfBossIcon_.transform.childCount - 1 do
		local child = self.gridOfBossIcon_.transform:GetChild(i).gameObject

		NGUITools.Destroy(child)
	end

	local baseInfo = self.baseInfo_
	local bossID = baseInfo.boss_id or 0
	local battleID = table:getBattleID(bossID)

	if battleID > 0 then
		local monsters = xyd.tables.battleTable:getMonsters(battleID)

		for idx, monsterID in ipairs(monsters) do
			local itemRoot = NGUITools.AddChild(self.gridOfBossIcon_.gameObject, self.bossIconRoot_)

			itemRoot:SetActive(true)
			xyd.getHeroIcon({
				isMonster = true,
				noClick = true,
				uiRoot = itemRoot,
				tableID = monsterID,
				lev = xyd.tables.monsterTable:getShowLev(monsterID),
				dragScrollView = self.scrollView_
			})
		end

		self.gridOfBossIcon_:Reposition()
		self.scrollView_:ResetPosition()
	end

	local enemies = baseInfo.enemies
	local totalHp = 0
	local count = #enemies
	local hps = table:getMonsterHp(bossID)
	local maxHp = table:getHp(bossID)

	if count > 0 then
		for i = 1, #enemies do
			local info = enemies[i]
			local status = info.status or {
				hp = 0
			}
			totalHp = totalHp + status.hp * hps[i]
		end

		self.progressBar_.value = math.ceil(totalHp / maxHp / 100)
		self.progressLabel_.text = totalHp / maxHp .. "%"
	else
		self.progressBar_.value = 1
		self.progressLabel_.text = "100%"
	end
end

function FriendBossWindow:register()
	FriendBossWindow.super.register(self)

	UIEventListener.Get(self.btnFight_.gameObject).onClick = handler(self, self.onFightTouch)
	UIEventListener.Get(self.btnSweeep_.gameObject).onClick = handler(self, self.onSweepTouch)
end

function FriendBossWindow:initBtn()
	self.btnFightLabel_.text = __("FRIEND_FIGHT")
	self.btnSweeepLabel_.text = __("FRIEND_SWEEP")
end

function FriendBossWindow:onFightTouch()
	if self:checkCanFight() then
		local fightParams = {
			battleType = xyd.BattleType.FRIEND_BOSS,
			friend_id = self.friendID_
		}

		xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
	end
end

function FriendBossWindow.checkCanFight()
	local tili = FriendModel:getTili()

	if tili <= 0 then
		xyd.alertTips(__("FRIEND_NO_TILI"))

		return false
	end

	return true
end

function FriendBossWindow:onSweepTouch()
	if self:checkCanFight() then
		xyd.WindowManager.get():openWindow("friend_sweep_window", {
			friend_id = self.friendID_
		})
	end
end

function FriendBossWindow:willClose()
	FriendBossWindow.super.willClose(self)
end

return FriendBossWindow
