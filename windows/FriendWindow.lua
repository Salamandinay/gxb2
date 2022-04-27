local FriendModel = xyd.models.friend
local OldSize = {
	w = 720,
	h = 1280
}
local FriendSearchItem = class("FriendSearchItem", import("app.components.CopyComponent"))

function FriendSearchItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.curType_ = 1
	self.btnGroup_ = {}

	FriendSearchItem.super.ctor(self, go)
end

function FriendSearchItem:initUI()
	FriendSearchItem.super.initUI(self)

	local itemTrans = self.uiRoot_.transform
	self.labelLv_ = itemTrans:ComponentByName("detialGroup/labelLv", typeof(UILabel))
	self.labelName_ = itemTrans:ComponentByName("detialGroup/labelName", typeof(UILabel))
	self.btnApply_ = itemTrans:ComponentByName("btnGroup/group1/btnApply", typeof(UISprite))
	self.btnAgree_ = itemTrans:ComponentByName("btnGroup/group2/btnAgree", typeof(UISprite))
	self.btnRefuse_ = itemTrans:ComponentByName("btnGroup/group2/btnRefuse", typeof(UISprite))
	self.labelDisplay_ = itemTrans:ComponentByName("btnGroup/group1/btnApply/label", typeof(UILabel))
	self.playIconPos_ = itemTrans:Find("playIconPos").gameObject
	local btnGroup1 = itemTrans:Find("btnGroup/group1").gameObject
	local btnGroup2 = itemTrans:Find("btnGroup/group2").gameObject
	self.playIconPos_ = itemTrans:Find("playIconPos").gameObject
	self.btnGroup_[1] = btnGroup1
	self.btnGroup_[2] = btnGroup2

	self:registerEvent()
end

function FriendSearchItem:update(index, realIndex, info, setType)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	else
		self.uiRoot_.transform:SetLocalScale(1, 1, 1)
		self.uiRoot_:SetActive(true)
	end

	self.curType_ = setType or info.item_type

	if not self.curType_ then
		self.curType_ = 1
	end

	self.data_ = info

	for idx, btnGroup in ipairs(self.btnGroup_) do
		btnGroup:SetActive(idx == self.curType_)
	end

	self.labelName_.text = self.data_.player_name
	self.labelLv_.text = self.data_.lev
	self.labelDisplay_.text = __("FRIEND_APPLY")
	local playerInfo = {
		avatarID = self.data_.avatar_id,
		avatar_frame_id = self.data_.avatar_frame_id,
		callback = function ()
			xyd.WindowManager.get():openWindow("arena_formation_window", {
				not_show_mail = true,
				is_robot = false,
				player_id = self.data_.player_id,
				server_id = self.data_.server_id
			})
		end
	}

	if self.curType_ == 1 then
		playerInfo.dragScrollView = self.parent_.friendRecommendScrollView_
	elseif self.curType_ == 2 then
		playerInfo.dragScrollView = self.parent_.friendApplyScrollView_
	end

	if not self.playerIcon_ then
		self.playerIcon_ = import("app.components.PlayerIcon").new(self.playIconPos_)

		self.playerIcon_:setScale(0.8421052631578947)
		self.playerIcon_:setInfo(playerInfo)

		self.playerIcon_.go.transform.localPosition = Vector3(32, -56, 0)
	else
		self.playerIcon_:setInfo(playerInfo)
	end
end

function FriendSearchItem:registerEvent()
	UIEventListener.Get(self.btnApply_.gameObject).onClick = handler(self, self.onApply)
	UIEventListener.Get(self.btnAgree_.gameObject).onClick = handler(self, self.onAgree)
	UIEventListener.Get(self.btnRefuse_.gameObject).onClick = handler(self, self.onRefuse)
end

function FriendSearchItem:onApply()
	if FriendModel:isFullFriends() then
		xyd.alertTips(__("SELF_MAX_FRIENDS"))
	elseif FriendModel:checkIsFriend(self.data_.player_id) then
		xyd.alertTips(__("PLAYER_IS_FRIEND"))
	else
		FriendModel:applyFriend(self.data_.player_id, true)
	end
end

function FriendSearchItem:onAgree()
	if FriendModel:checkIsFriend(self.data_.player_id) then
		xyd.alertTips(__("PLAYER_IS_FRIEND"))

		return
	elseif FriendModel:isFullFriends() then
		xyd.alertTips(__("SELF_MAX_FRIENDS"))

		return
	end

	FriendModel:acceptFriend(self.data_.player_id)
end

function FriendSearchItem:onRefuse()
	FriendModel:refuseFriends({
		self.data_.player_id
	})
end

function FriendSearchItem:playDisappear(callback)
	self.hasDis_ = true
	local playerid = self.data_.player_id
	local sequene = self:getSequence()

	sequene:Append(self.uiRoot_.transform:DOScale(Vector3(1.05, 1.05, 1.05), 0.1))
	sequene:Append(self.uiRoot_.transform:DOScale(Vector3(0, 0, 0), 0.16))
	sequene:OnComplete(function ()
		if self.parent_ and self.parent_.delPlayer then
			self.parent_:delPlayer(playerid)
		end

		if callback then
			callback()
		end
	end)
	sequene:SetAutoKill(true)
end

function FriendSearchItem:getPlayerID()
	if not self.data_ then
		return 0
	end

	return self.data_.player_id or 0
end

function FriendSearchItem:SetActive(bool)
	self.uiRoot_:SetActive(bool)
end

local FriendListItem = class("FriendListItem", import("app.components.CopyComponent"))

function FriendListItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go

	FriendListItem.super.ctor(self, go)
end

function FriendListItem:initUI()
	FriendListItem.super.initUI(self)

	local itemTrans = self.uiRoot_.transform
	self.btnSendLove_ = itemTrans:ComponentByName("btnGroup/btnSendLove", typeof(UISprite))
	self.btnSendLoveMask_ = itemTrans:ComponentByName("btnGroup/btnSendLove/mask", typeof(UISprite))
	self.btnSendLove = self.btnSendLove_.transform:ComponentByName("image", typeof(UISprite))
	self.btnGetLove_ = itemTrans:ComponentByName("btnGroup/btnGetLove", typeof(UISprite))
	self.btnGetLove = self.btnGetLove_.transform:ComponentByName("image", typeof(UISprite))
	self.btnGetLoveMask_ = itemTrans:ComponentByName("btnGroup/btnGetLove/mask", typeof(UISprite))
	self.btnFight_ = itemTrans:ComponentByName("btnGroup/btnFight", typeof(UISprite))
	local btnFight = self.btnFight_.transform:ComponentByName("image", typeof(UISprite))
	self.btnFightMask_ = itemTrans:ComponentByName("btnGroup/btnSendLove/mask", typeof(UISprite))
	self.btnBoss_ = itemTrans:ComponentByName("btnGroup/btnBoss", typeof(UISprite))
	local btnBoss = self.btnBoss_.transform:ComponentByName("image", typeof(UISprite))
	self.btnBossMask_ = itemTrans:ComponentByName("btnGroup/btnSendLove/mask", typeof(UISprite))
	self.playIconPos_ = itemTrans:Find("playIconPos").gameObject
	self.labelLv_ = itemTrans:ComponentByName("detialGroup/labelLv", typeof(UILabel))
	self.labelName_ = itemTrans:ComponentByName("detialGroup/labelName", typeof(UILabel))
	self.labelTime_ = itemTrans:ComponentByName("detialGroup/labelTime", typeof(UILabel))
	self.uiPanel_ = self.parent_.friendListScrollView_:GetComponent(typeof(UIPanel))
	UIEventListener.Get(self.btnSendLove.gameObject).onClick = handler(self, self.onSendLove)
	UIEventListener.Get(btnBoss.gameObject).onClick = handler(self, self.onBoss)
	UIEventListener.Get(btnFight.gameObject).onClick = handler(self, self.onFight)
	UIEventListener.Get(self.btnGetLove.gameObject).onClick = handler(self, self.onGetLove)

	self.uiRoot_:SetActive(false)
end

function FriendListItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	self.data_ = info

	self:layout()
	self:updateBtn()
end

function FriendListItem:updateBtn()
	if FriendModel:checkIsSend(self.data_.player_id) then
		xyd.setUISpriteAsync(self.btnSendLove, nil, "friend_icon_love4", nil, )
		self.btnSendLoveMask_.gameObject:SetActive(true)
	else
		xyd.setUISpriteAsync(self.btnSendLove, nil, "friend_icon_love3", nil, )
		self.btnSendLoveMask_.gameObject:SetActive(false)
	end

	local status = FriendModel:getReceiveStatus(self.data_.player_id)
	local giftNum = FriendModel:getGiftNum()
	local maxGiftNum = tonumber(xyd.tables.miscTable:getVal("love_coin_daily_max"))

	if status == 1 and maxGiftNum <= giftNum then
		status = 2
	end

	if status == 1 then
		if not self.effectGetLove_ then
			self.effectGetLove_ = xyd.Spine.new(self.btnGetLove_.gameObject)

			self.effectGetLove_:setInfo("aixin", function ()
				if self.uiPanel_ then
					self.effectGetLove_:setRenderPanel(self.uiPanel_)
				end

				self.effectGetLove_:setRenderTarget(self.btnGetLove:GetComponent(typeof(UIWidget)), 1)
				self.effectGetLove_:play("texiao01", -1, 1)
				self.effectGetLove_:SetActive(true)
			end)
		else
			self.effectGetLove_:SetActive(true)
			self.effectGetLove_:play("texiao01", -1, 1)
		end

		self.btnGetLove_.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.btnGetLove, nil, "friend_icon_love1", nil, )
		self.btnGetLoveMask_.gameObject:SetActive(false)
	elseif status == 2 then
		if self.effectGetLove_ then
			self.effectGetLove_:stop()
			self.effectGetLove_:SetActive(false)
		end

		self.btnGetLove_.gameObject:SetActive(true)
		self.btnGetLoveMask_.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.btnGetLove, nil, "friend_icon_love2", nil, )
	else
		if self.effectGetLove_ then
			self.effectGetLove_:stop()
			self.effectGetLove_:SetActive(false)
		end

		self.btnGetLove_.gameObject:SetActive(false)
	end

	local openLev = tonumber(xyd.tables.miscTable:getVal("friend_search_level"))

	if openLev <= xyd.models.backpack:getLev() and FriendModel:checkHasBoss(self.data_.player_id) then
		self.btnBoss_.gameObject:SetActive(true)
	else
		self.btnBoss_.gameObject:SetActive(false)
	end
end

function FriendListItem:layout()
	local playerInfo = {
		avatarID = self.data_.avatar_id,
		avatar_frame_id = self.data_.avatar_frame_id,
		dragScrollView = self.parent_.friendListScrollView_,
		callback = function ()
			xyd.WindowManager.get():openWindow("arena_formation_window", {
				not_show_mail = true,
				is_robot = false,
				player_id = self.data_.player_id,
				server_id = self.data_.server_id
			})
		end
	}

	if not self.playerIcon_ then
		self.playerIcon_ = import("app.components.PlayerIcon").new(self.playIconPos_, self.parent_.friendListScrollView_.gameObject:GetComponent(typeof(UIPanel)))

		self.playerIcon_:setInfo(playerInfo)

		self.playerIcon_.go.transform.localPosition = Vector3(32, -56, 0)

		self.playerIcon_:setScale(0.8421052631578947)
	else
		self.playerIcon_:setInfo(playerInfo)
	end

	self.labelName_.text = self.data_.player_name
	self.labelLv_.text = self.data_.lev
	local isOnline = self.data_.is_online and self.data_.is_online == 1

	if isOnline then
		self.labelTime_.text = __("ONLINE")
	else
		self.labelTime_.text = xyd.getReceiveTime(self.data_.last_time)
	end
end

function FriendListItem:onBoss()
	local baseInfo = FriendModel:getBossInfo(self.data_.player_id)
	local params = {
		friend_id = self.data_.player_id,
		base_info = baseInfo
	}

	xyd.WindowManager.get():openWindow("friend_boss_window", params)
end

function FriendListItem:onFight()
	local fightParams = {
		battleType = xyd.BattleType.FRIEND,
		friend_id = self.data_.player_id
	}

	xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
end

function FriendListItem:onGetLove()
	local maxLove = tonumber(xyd.tables.miscTable:getVal("friend_love_sum_max"))

	if maxLove <= FriendModel:getLoveNum() then
		xyd.alertTips(__("FRIEND_LOVE_MAX"))

		return
	end

	local giftNum = FriendModel:getGiftNum()
	local maxGiftNum = tonumber(xyd.tables.miscTable:getVal("love_coin_daily_max"))

	if maxGiftNum <= giftNum then
		xyd.alertTips(__("FRIEND_DAILY_LOVE_MAX"))

		return
	end

	FriendModel:getGifts({
		self.data_.player_id
	})
end

function FriendListItem:onSendLove()
	FriendModel:sendGifts({
		self.data_.player_id
	})
end

function FriendListItem:getGameObject()
	return self.uiRoot_
end

local FriendAssistant = class("FriendAssistant", import("app.components.BaseComponent"))

function FriendAssistant:ctor(parentGO, parent)
	self.parent_ = parent

	FriendAssistant.super.ctor(self, parentGO)
end

function FriendAssistant:getPrefabPath()
	return "Prefabs/Components/friend_assistant"
end

function FriendAssistant:initUI()
	self.content_ = self.go:ComponentByName("content", typeof(UISprite))
	local contentTrans = self.content_.transform
	self.btnAwardsLable_ = contentTrans:ComponentByName("btnAwards/label", typeof(UILabel))
	self.btnAwards_ = contentTrans:ComponentByName("btnAwards", typeof(UISprite))
	self.battleDetailBtn_ = contentTrans:ComponentByName("groupBoss/battleDetailBtn", typeof(UISprite))
	self.helpBtn_ = contentTrans:ComponentByName("helpBtn", typeof(UISprite))
	self.groupTime_ = contentTrans:Find("groupMap/groupTime").gameObject
	self.imgMap_ = contentTrans:ComponentByName("groupMap/imgMap", typeof(UITexture))
	self.groupMap_ = contentTrans:Find("groupMap").gameObject
	self.groupBoss_ = contentTrans:Find("groupBoss").gameObject
	self.labelTime_ = contentTrans:ComponentByName("groupMap/groupTime/labelTime", typeof(UILabel))
	self.labelTimeNum_ = contentTrans:ComponentByName("groupMap/groupTime/labelCountdowm", typeof(UILabel))
	self.labelAwardTips_ = contentTrans:ComponentByName("groupBoss/labelAwardTips", typeof(UILabel))
	self.btnRankLabel_ = contentTrans:ComponentByName("btnRank/label", typeof(UILabel))
	self.btnRank_ = contentTrans:ComponentByName("btnRank", typeof(UISprite))
	self.progressBar_ = contentTrans:ComponentByName("groupBoss/progressBar", typeof(UIProgressBar))
	self.labelDesc_ = contentTrans:ComponentByName("groupBoss/progressBar/labelDesc", typeof(UILabel))
	self.btnSearch_ = contentTrans:ComponentByName("btnSearch", typeof(UISprite))
	self.btnSearchMask_ = contentTrans:ComponentByName("btnSearch/mask", typeof(UISprite))
	self.groupBossIcon_ = contentTrans:ComponentByName("groupBoss/groupBossIcon", typeof(UIWidget))
	self.groupAward_ = contentTrans:ComponentByName("groupBoss/groupAward", typeof(UIWidget))

	self.btnSearchMask_.gameObject:SetActive(true)

	self.groupBoss_imgBg = contentTrans:ComponentByName("groupBoss/imgBg", typeof(UISprite))

	xyd.setUISpriteAsync(self.groupBoss_imgBg, nil, "arena_rank_bg")
	self.groupTime_:SetActive(true)

	self.btnSearchLabel_ = contentTrans:ComponentByName("btnSearch/label", typeof(UILabel))

	self:layout()
	self:initEffect()
	self:checkBossTips()
	self:registerEvent()
end

function FriendAssistant:layout()
	xyd.setUITextureAsync(self.imgMap_, "Textures/friend_web/friend_boss_map", nil, )

	self.btnRankLabel_.text = __("FRIEND_BOSS_RANK")
	self.btnAwardsLable_.text = __("FRIEND_BOSS_AWARDS")
	self.labelAwardTips_.text = __("FRIEND_BATTLE_AWARDS")
	self.labelTime_.text = __("FRIEND_NEXT_SEARCH")
end

function FriendAssistant:initEffect()
	if not self.effect_ then
		self.effect_ = xyd.Spine.new(self.imgMap_.gameObject)

		self.effect_:setInfo("sousuo", function ()
			if self.uiPanel_ then
				self.effect_:setRenderPanel(self.uiPanel_)
			end

			self.effect_:setRenderTarget(self.imgMap_:GetComponent(typeof(UIWidget)), 1)
			self.effect_:play("texiao01", 0, 1)
			self.effect_:SetActive(true)
		end)
	else
		self.effect_:SetActive(true)
		self.effect_:play("texiao01", -1, 1)
	end
end

function FriendAssistant:checkBossTips(isShowTips)
	local val = tonumber(xyd.db.misc:getValue("friend_boss"))

	if val and val > 0 then
		local baseInfo = FriendModel:getBaseInfo()
		local bossID = baseInfo.boss_id or 0

		if bossID <= 0 then
			if isShowTips then
				xyd.alertTips(__("FRIEND_BOSS_KILL"))
			end

			xyd.db.misc:addOrUpdate({
				value = "0",
				key = "friend_boss"
			})
		end
	end
end

function FriendAssistant:update(data)
	self.isInAction_ = false

	local function callback()
		local baseInfo = FriendModel:getBaseInfo()
		local bossID = baseInfo.boss_id or 0

		if bossID > 0 then
			self.btnSearchLabel_.text = __("FRIEND_BATTLE")

			self.groupMap_:SetActive(false)
			self.groupBoss_:SetActive(true)
			self.btnSearchMask_:SetActive(false)

			self.btnSearchLabel_.color = Color.New2(4294967295.0)
			self.btnSearchLabel_.effectStyle = UILabel.Effect.Outline
			self.btnSearchLabel_.effectColor = Color.New2(473916927)

			self:initBoss()
		else
			self.btnSearchLabel_.text = __("FRIEND_SEARCH")

			self.groupMap_:SetActive(true)
			self.groupBoss_:SetActive(false)

			local lastTime = baseInfo.search_time or 0
			local cd = tonumber(xyd.tables.miscTable:getVal("friend_search_cd"))
			local duration = cd - (xyd.getServerTime() - lastTime)

			if duration > 0 then
				self.groupTime_:SetActive(true)

				local params = {
					callback = function ()
						self.gourpTime_:SetActive(false)
						self.btnSearchMask_:SetActive(false)

						self.btnSearch_.color = Color.New2(4294967295.0)
					end,
					duration = duration
				}

				if not self.countDown_ then
					self.countDown_ = import("app.components.CountDown").new(self.labelTimeNum_, params)
				else
					self.countDown_:setInfo(params)
				end

				self.btnSearch_.color = Color.New2(255)
				self.btnSearchLabel_.color = Color.New2(4294967295.0)
				self.btnSearchLabel_.effectStyle = UILabel.Effect.None

				self.btnSearchMask_:SetActive(true)
			else
				self.groupTime_:SetActive(false)
				self.btnSearchMask_:SetActive(false)

				self.btnSearch_.color = Color.New2(4294967295.0)
				self.btnSearchLabel_.color = Color.New2(4294967295.0)
				self.btnSearchLabel_.effectStyle = UILabel.Effect.Outline
				self.btnSearchLabel_.effectColor = Color.New2(473916927)
			end
		end
	end

	if data then
		self:playAction(data, callback)
	else
		self:initEffect()
		callback()
	end
end

function FriendAssistant:playAction(data, callback)
	local function call()
		if data.item and data.item.item_id then
			xyd.alertItems({
				data.item
			})
		end

		if self.parent_.curSelect_ == 4 then
			callback()
		end

		if self.parent_ then
			self.parent_:setTopTouchType(true)
		end
	end

	if self.effect_ then
		if self.parent_ then
			self.parent_:setTopTouchType(false)
		end

		self.isInAction_ = true

		self.effect_:play("texiao02", 1, 1, function ()
			self.isInAction_ = false

			self.effect_:play("texiao01", 0)
			call()
		end)
	else
		call()
	end
end

function FriendAssistant:initBoss()
	local baseInfo = FriendModel:getBaseInfo()
	local bossID = baseInfo.boss_id or 0
	local battleID = xyd.tables.friendBossTable:getBattleID(bossID)

	if battleID > 0 then
		local monsters = xyd.tables.battleTable:getMonsters(battleID)

		if monsters and #monsters > 0 then
			local monsterID = monsters[1]

			for i = 0, self.groupBossIcon_.transform.childCount - 1 do
				local child = self.groupBossIcon_.transform:GetChild(i).gameObject

				NGUITools.Destroy(child)
			end

			xyd.getHeroIcon({
				isMonster = true,
				noClick = true,
				uiRoot = self.groupBossIcon_.gameObject,
				tableID = monsterID,
				lev = xyd.tables.monsterTable:getShowLev(monsterID)
			})
		end
	end

	local enemies = baseInfo.enemies
	local totalHp = 0
	local count = enemies.length
	local hps = xyd.tables.friendBossTable:getMonsterHp(bossID)
	local maxHp = xyd.tables.friendBossTable:getHp(bossID)

	if count and count > 0 then
		for idx, info in ipairs(enemies) do
			local status = info.status or {
				hp = 0
			}
			totalHp = totalHp + status.hp * hps[idx]
		end

		self.progressBar_.value = totalHp / maxHp
		self.labelDesc_.text = totalHp / maxHp .. "%"
	else
		self.progressBar_.value = 1
		self.labelDesc_.text = "100%"
	end

	local finalAwards = xyd.tables.friendBossTable:getFinalAward(bossID)

	for i = 0, self.groupAward_.transform.childCount - 1 do
		local child = self.groupAward_.transform:GetChild(i).gameObject

		NGUITools.Destroy(child)
	end

	xyd.getItemIcon({
		hideText = true,
		uiRoot = self.groupAward_.gameObject,
		itemID = finalAwards[1],
		num = finalAwards[2]
	})
end

function FriendAssistant:registerEvent()
	UIEventListener.Get(self.btnSearch_.gameObject).onClick = handler(self, self.onSearchTouch)
	UIEventListener.Get(self.btnRank_.gameObject).onClick = handler(self, self.onRankTouch)
	UIEventListener.Get(self.btnAwards_.gameObject).onClick = handler(self, self.onAwardsTouch)
	UIEventListener.Get(self.battleDetailBtn_.gameObject).onClick = handler(self, self.onDetailTouch)
	UIEventListener.Get(self.helpBtn_.gameObject).onClick = handler(self, self.onHelpTouch)
end

function FriendAssistant:onSearchTouch()
	if self.isInAction_ then
		return
	end

	local baseInfo = FriendModel:getBaseInfo()
	local bossID = baseInfo.boss_id

	if bossID and bossID > 0 then
		local params = {
			friend_id = xyd.Global.playerID,
			base_info = baseInfo
		}

		xyd.WindowManager.get():openWindow("friend_boss_window", params)
	else
		FriendModel:searchBoss()
	end
end

function FriendAssistant:onRankTouch()
	xyd.WindowManager.get():openWindow("rank_window", {
		mapType = xyd.MapType.FRIEND_RANK
	})
end

function FriendAssistant:onAwardsTouch()
	xyd.WindowManager.get():openWindow("friend_rank_award_window")
end

function FriendAssistant:onDetailTouch()
	xyd.WindowManager.get():openWindow("friend_boss_rank_window")
end

function FriendAssistant:onHelpTouch()
	xyd.WindowManager.get():openWindow("help_window", {
		key = "FRIEND_ASSISTANT_HELP"
	})
end

local FriendAssistant2 = class("FriendAssistant2", import("app.components.BaseComponent"))

function FriendAssistant2:ctor(parentGO, parent)
	self.parent_ = parent

	FriendAssistant2.super.ctor(self, parentGO)

	self.skinName = "FriendAssistantSkin2"

	xyd.models.friend:setFriendBossRed(false)
end

function FriendAssistant2:getPrefabPath()
	return "Prefabs/Components/friend_assistant2"
end

function FriendAssistant2:initUI()
	self.allGroup_ = self.go:NodeByName("e:Group").gameObject
	self.friendBossGroup = self.allGroup_:NodeByName("friendBossGroup").gameObject
	self.bossLevelLabel = self.friendBossGroup:ComponentByName("bossLevelLabel", typeof(UILabel))
	self.switchBossLevelBtn = self.friendBossGroup:ComponentByName("switchBossLevelBtn", typeof(UITexture))
	self.bossMemberIcons = self.friendBossGroup:NodeByName("bossMemberIcons").gameObject
	self.EnemyPreview = self.friendBossGroup:ComponentByName("bossMemberIcons/EnemyPreviewGroup/EnemyPreview", typeof(UILabel))

	for i = 1, 6 do
		self["heroIconGroup" .. i] = self.friendBossGroup:NodeByName("bossMemberIcons/heroIconGroup" .. i).gameObject
		self["heroIconContainer" .. i] = self.friendBossGroup:NodeByName("bossMemberIcons/heroIconGroup" .. i .. "/heroIconContainer" .. i).gameObject
	end

	self.friendBossIcon = self.friendBossGroup:ComponentByName("friendBossIcon", typeof(UISprite))
	self.setAssistantBtn = self.allGroup_:NodeByName("setAssistantBtn").gameObject
	self.setAssistantBtn_button_label = self.allGroup_:ComponentByName("setAssistantBtn/button_label", typeof(UILabel))
	self.helpBtn = self.allGroup_:NodeByName("helpBtn").gameObject
	self.fightBtn = self.allGroup_:NodeByName("fightBtn").gameObject
	self.fightBtn_uisprite = self.allGroup_:ComponentByName("fightBtn", typeof(UISprite))
	self.fightBtn_boxCollider = self.allGroup_:ComponentByName("fightBtn", typeof(UnityEngine.BoxCollider))
	self.fightBtn_button_label = self.allGroup_:ComponentByName("fightBtn/button_label", typeof(UILabel))

	self:createChildren()
end

function FriendAssistant2:createChildren()
	self.bossIsAlive = true

	self:initSelectedBossLevel()
	self:initLayout()
	self:registerEvent()
	self:initFriendBossGroup()
	self:initFightBtn()
end

function FriendAssistant2:initSelectedBossLevel()
	self.unlockedMaxBossLevel = xyd.models.friend:getUnlockStage()
	self.selectedBossLevel = xyd.models.friend:getSelectedBossLevel()
end

function FriendAssistant2:update()
	self:initLayout()
	self:initFriendBossGroup()
	self:initFightBtn()
end

function FriendAssistant2:setBossStatus(newStatus)
	self.bossIsAlive = newStatus
end

function FriendAssistant2:updateFriendBossInfo(bossLevel)
	if bossLevel ~= nil then
		self.selectedBossLevel = bossLevel
	end

	self:update()
end

function FriendAssistant2:initFriendBossGroup()
	self:initBossHeadIcon()
	self:initBossGroupIcons()
end

function FriendAssistant2:initBossHeadIcon()
	local bossLevel = tonumber(self.selectedBossLevel)

	if bossLevel > 8 then
		bossLevel = 8
	end

	xyd.setUISpriteAsync(self.friendBossIcon, nil, "friend_team_boss_head" .. tostring(bossLevel), nil, )
end

function FriendAssistant2:initBossGroupIcons()
	local count = 0

	for i = 1, 6 do
		NGUITools.DestroyChildren(self["heroIconContainer" .. tostring(i)].transform)
	end

	count = 1
	local battleID = xyd.tables.friendBossTable:getBattleID(self.selectedBossLevel)

	if battleID > 0 then
		local bossGroup = xyd.tables.battleTable:getMonsters(battleID)
		local bossStand = xyd.tables.battleTable:getStands(battleID)

		if bossGroup ~= nil and #bossGroup > 0 then
			for i, memberId in ipairs(bossGroup) do
				local memberIcon = xyd.getHeroIcon({
					scale = 0.8,
					isMonster = true,
					noClick = true,
					isUnique = true,
					tableID = memberId,
					lev = xyd.tables.monsterTable:getShowLev(memberId),
					uiRoot = self["heroIconContainer" .. tostring(bossStand[count])],
					panel = self.parent_.panel_
				})
				count = count + 1
			end
		end
	end
end

function FriendAssistant2:onSwitchBossLevelTouch()
	local params = {
		selected = self.selectedBossLevel
	}

	xyd.WindowManager.get():openWindow("friend_boss_switch_boss_level_window", params)
end

function FriendAssistant2:initLayout()
	self.setAssistantBtn_button_label.text = __("SETTING_ASSISTANT")
	self.EnemyPreview.text = __("ENEMY_PREVIEW")
	self.fightBtn_button_label.text = __("FIGHT3")
	self.bossLevelLabel.text = "LV." .. tostring(tostring(self.selectedBossLevel))

	if xyd.Global.lang == "fr_fr" then
		self.bossLevelLabel.text = "Niv." .. tostring(tostring(self.selectedBossLevel))
	end
end

function FriendAssistant2:registerEvent()
	UIEventListener.Get(self.switchBossLevelBtn.gameObject).onClick = handler(self, self.onSwitchBossLevelTouch)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, self.onHelpTouch)
	UIEventListener.Get(self.setAssistantBtn.gameObject).onClick = handler(self, self.onSetAssistant)
	UIEventListener.Get(self.fightBtn.gameObject).onClick = handler(self, self.onFightTouch)
end

function FriendAssistant2:onHelpTouch()
	local params = {
		key = "FRIEND_ASSISTANT_HELP"
	}

	xyd.WindowManager.get():openWindow("help_window", params)
end

function FriendAssistant2:onSetAssistant()
	xyd.WindowManager.get():openWindow("friend_boss_assistant_setting_window")
end

function FriendAssistant2:initFightBtn()
	self.bossIsAlive = xyd.models.friend:checkBossIsAlive()

	if self.bossIsAlive then
		xyd.applyOrigin(self.fightBtn_uisprite)

		self.fightBtn_boxCollider.enabled = true
	else
		xyd.applyGrey(self.fightBtn_uisprite)

		self.fightBtn_boxCollider.enabled = false
	end
end

function FriendAssistant2:onFightTouch()
	local selectedBossLevel = xyd.models.friend:getSelectedBossLevel()
	local fightParams = {
		windowName = "friend_boss_battle_formation_window",
		battleType = xyd.BattleType.FRIEND_BOSS,
		friend_id = xyd.Global.playerID,
		showSkip = xyd.models.friend:canJumpBattle(selectedBossLevel),
		skipState = xyd.models.friend:isSkipBattle(),
		btnSkipCallback = function (flag)
			xyd.models.friend:skipFriendBossBattle(flag)
		end
	}

	xyd.WindowManager.get():openWindow("friend_boss_battle_formation_window", fightParams)
end

local FriendApply = class("FriendApply", import("app.components.BaseComponent"))

function FriendApply:ctor(parentGO, parent)
	self.parent_ = parent
	self.itemList_ = {}

	FriendApply.super.ctor(self, parentGO)
end

function FriendApply:getPrefabPath()
	return "Prefabs/Components/friend_apply"
end

function FriendApply:initUI()
	FriendApply.super.initUI(self)

	self.content_ = self.go:ComponentByName("content", typeof(UISprite))
	local contentTrans = self.content_.transform
	self.btnDelAll_ = contentTrans:ComponentByName("btnAll", typeof(UISprite))
	self.btnDelAllLabel_ = contentTrans:ComponentByName("btnAll/label", typeof(UILabel))
	self.btnAgreeAll_ = contentTrans:ComponentByName("btnAgreeAll", typeof(UISprite))
	self.btnAgreeAllLabel_ = contentTrans:ComponentByName("btnAgreeAll/label", typeof(UILabel))
	self.labelTips_ = contentTrans:ComponentByName("groupFriend/labelTips", typeof(UILabel))
	self.labelNoneTips_ = contentTrans:ComponentByName("groupNone/labelNoneTips", typeof(UILabel))
	self.labelNum_ = contentTrans:ComponentByName("groupFriend/labelNum", typeof(UILabel))
	self.groupNone_ = contentTrans:Find("groupNone").gameObject
	self.friendApplyItemRoot_ = contentTrans:Find("FriendSearchItem").gameObject
	self.friendApplyGrid_ = contentTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.friendApplyScrollView_ = contentTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.friendApplyScrollView_, self.friendApplyGrid_, self.friendApplyItemRoot_, FriendSearchItem, self)
	local panel = self.friendApplyScrollView_:GetComponent(typeof(UIPanel))
	panel.depth = self.parent_.panel_.depth + 1

	self.friendApplyItemRoot_:SetActive(false)
	self:layout()
	self:updateList()
	self:registerEvent()
end

function FriendApply:layout()
	self.btnDelAllLabel_.text = __("FRIEND_DEL_ALL")
	self.btnAgreeAllLabel_.text = __("FRIEND_AGREE_ALL")
	self.labelTips_.text = __("FRIEND_GET_REQUEST")
	self.labelNoneTips_.text = __("FRIEND_APPLY_NONE")

	if xyd.Global.lang == "de_de" then
		self.btnDelAllLabel_.fontSize = 20
		self.btnAgreeAllLabel_.fontSize = 20
	end

	self:updateResNum()
end

function FriendApply:updateResNum()
	local list = FriendModel:getRequestList()
	self.labelNum_.text = tostring(#list)
end

function FriendApply:update(playerID, isAction)
	self:updateResNum()

	if playerID and isAction then
		self:playDisappear(playerID)
	else
		self:updateList()
	end
end

function FriendApply:updateList()
	local list = FriendModel:getRequestList()

	if #list <= 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end

	self.applyList = {}

	for _, info in ipairs(list) do
		table.insert(self.applyList, {
			item_type = 2,
			lev = info.lev,
			player_name = info.player_name,
			avatar_id = info.avatar_id,
			avatar_frame_id = info.avatar_frame_id,
			player_id = info.player_id,
			server_id = info.server_id
		})
	end

	self.multiWrap_:setInfos(self.applyList, {})
end

function FriendApply:delPlayer(player_id)
	for index, info in ipairs(self.applyList) do
		if info.player_id == player_id then
			table.remove(self.applyList, index)

			break
		end
	end

	self.multiWrap_:setInfos(self.applyList, {
		keepPosition = true
	})
end

function FriendApply:registerEvent()
	UIEventListener.Get(self.btnDelAll_.gameObject).onClick = handler(self, self.btnDelAllouch)
	UIEventListener.Get(self.btnAgreeAll_.gameObject).onClick = handler(self, self.btnAgreeAllTouch)
end

function FriendApply:btnDelAllouch()
	local list = FriendModel:getRequestList()
	local ids = {}
	local hasKey = {}

	for _, info in ipairs(list) do
		if not hasKey[info.player_id] then
			table.insert(ids, info.player_id)

			hasKey[info.player_id] = true
		end
	end

	FriendModel:refuseFriends(ids)
end

function FriendApply:btnAgreeAllTouch()
	local list = FriendModel:getRequestList()
	local ids = {}

	for _, info in ipairs(list) do
		if xyd.arrayIndexOf(ids, info.player_id) == -1 then
			local isaccept = true

			if FriendModel:checkIsFriend(info.player_id) then
				xyd.alertTips(__("PLAYER_IS_FRIEND"))

				isaccept = false
			elseif FriendModel:isFullFriends() then
				xyd.alertTips(__("SELF_MAX_FRIENDS"))

				isaccept = false
			end

			if isaccept then
				FriendModel:acceptFriend(info.player_id)
			end
		end
	end
end

function FriendApply:playDisappear(id)
	local items = self.multiWrap_:getItems()
	local targetItem = nil

	for _, item in ipairs(items) do
		if item:getPlayerID() == id then
			targetItem = item
		end
	end

	if targetItem and targetItem:getPlayerID() == id then
		targetItem:playDisappear(function ()
			local list = FriendModel:getRequestList()

			if #list <= 0 then
				self.groupNone_:SetActive(true)
			else
				self.groupNone_:SetActive(false)
			end
		end)
	end
end

local FriendList = class("FriendList", import("app.components.BaseComponent"))

function FriendList:ctor(parentGO, parent)
	self.parent_ = parent
	self.friendList_ = {}
	self.setList_ = {}

	FriendList.super.ctor(self, parentGO)
end

function FriendList:getPrefabPath()
	return "Prefabs/Components/friend_list"
end

function FriendList:initUI()
	FriendList.super.initUI(self)

	self.content_ = self.go:ComponentByName("content", typeof(UISprite))
	local contentTrans = self.content_.transform
	self.btnAll_ = contentTrans:ComponentByName("btnAll", typeof(UISprite))
	self.btnAllLabel_ = contentTrans:ComponentByName("btnAll/label", typeof(UILabel))
	self.groupNone_ = contentTrans:Find("groupNone").gameObject
	self.labelNoneTips_ = contentTrans:ComponentByName("groupNone/labelNoneTips", typeof(UILabel))
	self.labelFriendNum_ = contentTrans:ComponentByName("groupFriend/labelFriendNum", typeof(UILabel))
	self.labelFriendTips_ = contentTrans:ComponentByName("groupFriend/labelFriendTips", typeof(UILabel))
	self.energyGroup_ = contentTrans:Find("energyTips").gameObject

	self.energyGroup_:SetActive(false)

	self.labelNextEnergy_ = contentTrans:ComponentByName("energyTips/labelNextEnergy", typeof(UILabel))
	self.energyCountDown_ = contentTrans:ComponentByName("energyTips/energyCountDown", typeof(UILabel))
	self.labelLove_ = contentTrans:ComponentByName("bgTop/groupHeart/label", typeof(UILabel))
	self.groupHeart_image = contentTrans:ComponentByName("bgTop/groupHeart/image", typeof(UISprite))

	xyd.setUISpriteAsync(self.groupHeart_image, nil, "icon_11")

	self.groupTili_ = contentTrans:ComponentByName("bgTop/groupTili", typeof(UIWidget))
	self.labelTili_ = contentTrans:ComponentByName("bgTop/groupTili/label", typeof(UILabel))
	self.friendListWarpContent_ = contentTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.friendListGrid_ = contentTrans:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.friendListScrollView_ = contentTrans:ComponentByName("scrollView", typeof(UIScrollView))
	local scrollPanel = self.friendListScrollView_:GetComponent(typeof(UIPanel))
	scrollPanel.depth = self.parent_.panel_.depth + 1
	local friendListItemRoot = contentTrans:Find("FriendListItem").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.friendListScrollView_, self.friendListWarpContent_, friendListItemRoot, FriendListItem, self)

	self:layout()
	self:registerEvent()
end

function FriendList:layout()
	self.btnAllLabel_.text = __("FRIEND_GET_ALL_LOVE")
	self.labelFriendTips_.text = __("FRIEND_NUM")
	self.labelNoneTips_.text = __("FRIEND_NONE")
	self.labelNextEnergy_.text = __("FRIEND_RECOVER_TILI")

	self:updateRes()
end

function FriendList:updateRes()
	self.labelLove_.text = tostring(FriendModel:getLoveNum())
	self.labelTili_.text = FriendModel:getTili() .. "/" .. xyd.tables.miscTable:getVal("friend_energy_max")
	local list = FriendModel:getFriendList()
	self.labelFriendNum_.text = tostring(#list) .. "/" .. xyd.tables.miscTable:getVal("friend_max_num")

	self:initTime()
end

function FriendList:initTime()
	local cd = tonumber(xyd.tables.miscTable:getVal("friend_energy_cd"))
	local baseInfo = FriendModel:getBaseInfo()
	local lastTime = baseInfo.energy_time or 0
	local duration = cd - (xyd.getServerTime() - lastTime) % cd
	local tili = FriendModel:getTili()
	local maxTili = tonumber(xyd.tables.miscTable:getVal("friend_energy_max"))

	if duration > 0 and tili < maxTili then
		local params = {
			duration = duration,
			callback = function ()
				self:updateNextTime()
			end
		}

		if not self.countDown_ then
			self.countDown_ = import("app.components.CountDown").new(self.energyCountDown_, params)
		else
			self.countDown_:setInfo(params)
		end
	else
		if self.countDown_ then
			self.countDown_:stopTimeCount()
		end

		self.energyCountDown_.text = "00:00:00"
	end
end

function FriendList:updateNextTime()
	local cd = tonumber(xyd.tables.miscTable:getVal("friend_energy_cd"))
	local maxTili = tonumber(xyd.tables.miscTable:getVal("friend_energy_max"))
	local tili = FriendModel:getTili()
	local fix_tili = tili + 1

	if maxTili < fix_tili then
		fix_tili = maxTili
	end

	FriendModel:setTili(fix_tili)
	self:updateTiliLabel()
end

function FriendList:updateTiliLabel()
	self.labelTili_.text = FriendModel:getTili() .. "/" .. xyd.tables.miscTable:getVal("friend_energy_max")
	local wnd = xyd.WindowManager.get():getWindow("friend_boss_window")

	if wnd then
		wnd:updateNextTime()
	end
end

function FriendList:update()
	self:updateRes()
	self:updateList()
end

function FriendList:updateList()
	local list = FriendModel:getFriendList()

	if #list <= 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end

	if not self.hasFirstUpdateList_ then
		local tempList = {}
		self.hasFirstUpdateList_ = true

		for idx, achievement in ipairs(list) do
			table.insert(tempList, achievement)
		end

		table.sort(tempList, function (a, b)
			if a.is_online ~= b.is_online then
				return b.is_online < a.is_online
			else
				return b.last_time < a.last_time
			end
		end)
		self.multiWrap_:setInfos(tempList, {})
	elseif #list <= 0 then
		self.friendList_ = {}

		self.multiWrap_:setInfos(self.friendList_, {})
	else
		self.friendList_ = list

		XYDCo.WaitForFrame(1, function ()
			table.sort(self.friendList_, function (a, b)
				if a.is_online ~= b.is_online then
					return b.is_online < a.is_online
				else
					return b.last_time < a.last_time
				end
			end)
			self.multiWrap_:setInfos(self.friendList_, {
				keepPosition = true
			})
		end, nil)
	end
end

function FriendList:sortFriend()
	table.sort(self.friendList_, function (a, b)
		local aVal = FriendModel:checkHasBoss(a.player_id) and 1000 or 0
		local bVal = FriendModel:checkHasBoss(b.player_id) and 1000 or 0
		aVal = b.player_id < aVal + a.player_id and 100 or 0

		if a.player_id < bVal + b.player_id then
			bVal = 100
		else
			bVal = 0
		end

		return aVal > bVal
	end)
end

function FriendList:registerEvent()
	UIEventListener.Get(self.btnAll_.gameObject).onClick = handler(self, self.btnAllTouch)

	UIEventListener.Get(self.groupTili_.gameObject).onPress = function (_, isPress)
		self.energyGroup_:SetActive(isPress)
	end
end

function FriendList:btnAllTouch()
	local list = FriendModel:getFriendList()
	local sendIDs = {}
	local getIDs = {}

	for _, info in ipairs(list) do
		local status = FriendModel:checkIsSend(info.player_id)

		if not status then
			table.insert(sendIDs, info.player_id)
		end

		local receiveStatus = FriendModel:getReceiveStatus(info.player_id)

		if receiveStatus == 1 then
			table.insert(getIDs, info.player_id)
		end
	end

	if #getIDs <= 0 and #sendIDs <= 0 then
		xyd.alertTips(__("FRIEND_NOT_SEND_OR_GET"))

		return
	end

	if #sendIDs > 0 then
		FriendModel:sendGifts(sendIDs)
	end

	local maxLove = tonumber(xyd.tables.miscTable:getVal("friend_love_sum_max"))

	if maxLove <= FriendModel:getLoveNum() then
		xyd.alertTips(__("FRIEND_LOVE_MAX"))

		return
	end

	local giftNum = FriendModel:getGiftNum()
	local maxGiftNum = tonumber(xyd.tables.miscTable:getVal("love_coin_daily_max"))

	if maxGiftNum <= giftNum then
		xyd.alertTips(__("FRIEND_DAILY_LOVE_MAX"))

		return
	end

	if #getIDs > 0 then
		if maxGiftNum < #getIDs + giftNum then
			local index = maxGiftNum - giftNum
			local copytable = {}

			for i = 1, index do
				table.insert(copytable, getIDs[i])
			end

			getIDs = copytable
		end

		FriendModel:getGifts(getIDs)
	end
end

local FriendSearch = class("FriendSearch", import("app.components.BaseComponent"))

function FriendSearch:ctor(parentGO, parent)
	self.parent_ = parent

	FriendList.super.ctor(self, parentGO)
end

function FriendSearch:getPrefabPath()
	return "Prefabs/Components/friend_search"
end

function FriendSearch:initUI()
	FriendSearch.super.initUI(self)

	self.content_ = self.go:ComponentByName("content", typeof(UISprite))
	local contentTrans = self.content_.transform
	self.btnSearch_ = contentTrans:ComponentByName("btnSearch", typeof(UISprite))
	self.btnSearchLabel_ = contentTrans:ComponentByName("btnSearch/label", typeof(UILabel))
	self.labelTips_ = contentTrans:ComponentByName("labelTips", typeof(UILabel))
	self.friendRecommendGrid_ = contentTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.friendRecommendScrollView_ = contentTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.selectNumPos_ = contentTrans:NodeByName("selectNumPos").gameObject
	local scrollPanel = self.friendRecommendScrollView_:GetComponent(typeof(UIPanel))
	scrollPanel.depth = self.parent_.panel_.depth + 1
	self.friendRecommendItemRoot_ = contentTrans:Find("FriendSearchItem").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.friendRecommendScrollView_, self.friendRecommendGrid_, self.friendRecommendItemRoot_, FriendSearchItem, self)

	self:layout()
	self:registerEvent()
end

function FriendSearch:registerEvent()
	UIEventListener.Get(self.btnSearch_.gameObject).onClick = function ()
		self:btnSearchouch()
	end
end

function FriendSearch:layout()
	self.btnSearchLabel_.text = __("FRIEND_NAME_2")
	self.labelTips_.text = __("FRIEND_ELIGIBLE")
	self.selectNum_ = import("app.components.SelectNum").new(self.selectNumPos_, "friend")

	local function callback(num)
		self.str_ = num
	end

	self.selectNum_:setInfo({
		maxLength = 10,
		callback = callback
	})
	self.selectNum_:setPrompt(__("FRIEND_INPUT_ID"))
	self.selectNum_:showPasteBtn(function (str)
		if self:checkValid(str) then
			xyd.models.arena:reqEnemyInfo(tonumber(str))
		end
	end)

	if xyd.Global.lang == "de_de" then
		self.selectNum_.go:ComponentByName("promptLabel", typeof(UILabel)):X(-202)
	end
end

function FriendSearch:update(playerID, isAction)
	if playerID and isAction then
		self:playDisappear(playerID)
	else
		self:updateRecommendList()
	end
end

function FriendSearch:updateRecommendList()
	local list = FriendModel:getRecommendList() or {}
	self.recommendList = {}

	for _, info in ipairs(list) do
		table.insert(self.recommendList, {
			item_type = 1,
			lev = info.lev,
			player_name = info.player_name,
			avatar_id = info.avatar_id,
			avatar_frame_id = info.avatar_frame_id,
			player_id = info.player_id,
			server_id = info.server_id
		})
	end

	self.multiWrap_:setInfos(self.recommendList, {})
end

function FriendSearch:delPlayer(player_id)
	for index, info in ipairs(self.recommendList) do
		if info.player_id == player_id then
			table.remove(self.recommendList, index)

			break
		end
	end

	self.multiWrap_:setInfos(self.recommendList, {
		keepPosition = true
	})
end

function FriendSearch:btnSearchouch()
	if self:checkValid() then
		xyd.models.arena:reqEnemyInfo(tonumber(self.str_))
	end
end

function FriendSearch:checkValid(checkStr)
	local str = checkStr or self.str_
	local length = xyd.getStrLength(str)
	local flag = true
	local tips = ""

	if length <= 0 then
		flag = false
		tips = __("INPUT_NULL")
	elseif not tonumber(str) then
		flag = false
		tips = __("FRIEND_SEARCH_ONLY_NUM")
	elseif length > 10 or tonumber(str) > 2147483647 or tonumber(str) <= 1000000000 then
		flag = false
		tips = __("FRIEND_SEARCH_NO_VALID")
	elseif tonumber(str) == xyd.Global.playerID then
		flag = false
		tips = __("FRIEND_NOT_SELF")
	elseif FriendModel:checkIsFriend(tonumber(str)) then
		flag = false
		tips = __("PLAYER_IS_FRIEND")
	elseif FriendModel:isFullFriends() then
		flag = false
		tips = __("SELF_MAX_FRIENDS")
	end

	if tips ~= "" then
		xyd.alertTips(tips)
	end

	return flag
end

function FriendSearch:playDisappear(id)
	local items = self.multiWrap_:getItems()
	local targetItem = nil

	for _, item in ipairs(items) do
		if item:getPlayerID() == id then
			targetItem = item
		end
	end

	if targetItem and targetItem:getPlayerID() == id then
		targetItem:playDisappear()
	end
end

local BaseWindow = import(".BaseWindow")
local FriendWindow = class("FriendWindow", BaseWindow)

function FriendWindow:ctor(name, params)
	FriendWindow.super.ctor(self, name, params)

	self.topCanTouch_ = true
	self.curSelect_ = params and params.tab or 1
	self.items_ = {}
	self.firstIn_ = true
	self.navList_ = {}
	self.itemList = {}
end

function FriendWindow:initWindow()
	FriendWindow.super.initWindow(self)
	self:layout()
	self:updateRedPoint()
	self:registerEvent()

	if FriendModel:getData().friend_list and #FriendModel:getData().friend_list == 0 and self.curSelect_ == 1 then
		self.curSelect_ = 2
	end

	self:updateTopButton()
	xyd.models.friend:loadFriendBossInfo()
end

function FriendWindow:willOpen()
	FriendWindow.super.willOpen(self)

	if FriendModel:getInfo() then
		self.askBeforeOpen_ = true
	end
end

function FriendWindow:playOpenAnimation(callback)
	local function afterAction()
		if not FriendModel:getInfo() and self.firstIn_ then
			self:onGetInfo()
		end

		callback()
	end

	FriendWindow.super.playOpenAnimation(self, afterAction)
end

function FriendWindow:registerEvent()
	for i = 1, 4 do
		local btn = self.navList_[i].navBtn

		UIEventListener.Get(btn.gameObject).onClick = function ()
			if self.curSelect_ ~= i and self.topCanTouch_ then
				self:btnSelectTouchEvent(i)
			end
		end
	end

	self.eventProxy_:addEventListener(xyd.event.FRIEND_GET_INFO, handler(self, self.onGetInfo))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_APPLY, handler(self, self.onApply))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_ACCEPT, handler(self, self.onAccept))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_DELETE_REQUEST, handler(self, self.onDeleteRequest))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_DELETE, handler(self, self.onDelete))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_RECOMMEND_LIST, handler(self, self.onGetRecommendList))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_SEND_GIFTS, handler(self, self.onSendGifts))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_GET_GIFTS, handler(self, self.onGetGifts))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_SEARCH_BOSS, handler(self, self.onSearchBoss))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_SWEEP_BOSS, handler(self, self.onSweepBoss))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_DELETE, handler(self, self.onFriendDel))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_FIGHT_BOSS, handler(self, self.onFightBoss))
	self.eventProxy_:addEventListener(xyd.event.GET_FRIEND_BOSS_INFO, handler(self, self.onGetFriendBossInfo))
	self.eventProxy_:addEventListener(xyd.event.ARENA_GET_ENEMY_INFO, handler(self, self.onGetSearchInfo))
	self:setCloseBtn(self.closeBtn_)
end

function FriendWindow:layout()
	local winTrans = self.window_.transform
	self.content_ = winTrans:ComponentByName("content", typeof(UISprite))
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

	self.closeBtn_ = contentTrans:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.labelTitle_ = contentTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.groupMain_ = contentTrans:Find("groupMain").gameObject
	self.itemFloatRoot_ = contentTrans:Find("itemfloatPanel/itemfloatPos").gameObject
	local itemFloatPanel = contentTrans:ComponentByName("itemfloatPanel", typeof(UIPanel))
	itemFloatPanel.depth = self.panel_.depth + itemFloatPanel.depth

	for i = 1, 4 do
		local navBtn = contentTrans:ComponentByName("navPos/nav" .. i, typeof(UIButton))
		local navLabel = contentTrans:ComponentByName("navPos/nav" .. i .. "/navLabel", typeof(UILabel))
		navLabel.text = __("FRIEND_NAME_" .. i)
		self.navList_[i] = {
			navBtn = navBtn,
			navLabel = navLabel
		}
	end

	self.imgRedList_ = self.navList_[1].navBtn:NodeByName("imgRedList_").gameObject
	self.imgRedApply_ = self.navList_[3].navBtn:NodeByName("imgRedApply_").gameObject
	self.redFullApply_ = self.navList_[3].navBtn:NodeByName("redFullApply_").gameObject
	self.imgRedAssistant_ = self.navList_[4].navBtn:NodeByName("imgRedAssistant_").gameObject
	self.labelTitle_.text = __("FRIEND_WINDOW")
end

function FriendWindow:setTopTouchType(flag)
	self.topCanTouch_ = flag
end

function FriendWindow:onGetInfo()
	if FriendModel:getData() and #FriendModel:getData().friend_list == 0 and self.curSelect_ == 1 then
		self.curSelect_ = 2
	end

	if self.askBeforeOpen_ then
		self.askBeforeOpen_ = false
	else
		if self.firstIn_ then
			self:updateSelect()
			self:updateTopButton()
			self:updateRedPoint()

			self.firstIn_ = false

			return
		end

		self.firstIn_ = false

		if self.items_[self.curSelect_] then
			self.items_[self.curSelect_]:SetActive(true)
			self.items_[self.curSelect_]:update()
		end

		for i = 1, 4 do
			if i ~= self.curSelect_ and self.items_[i] then
				self.items_[i]:SetActive(false)
			end
		end

		self:updateRedPoint()
	end
end

function FriendWindow:updateSelect()
	for i = 1, 4 do
		local item = self.items_[i]

		if i == self.curSelect_ then
			if i == 3 then
				if not xyd.models.friend:isFullFriends() and tonumber(xyd.tables.miscTable:getVal("friend_apply_limit")) <= #xyd.models.friend:getRequestList() then
					xyd.alertTips(__("FRIEND_APPLY_LIMIT_TIPS"))
				end
			elseif i == 2 then
				FriendModel:reqRecommendList()
			end

			if item then
				item:SetActive(true)
				item:update()
			else
				item = self:getItem(i)

				item:SetActive(true)

				self.items_[i] = item

				item:update()
			end
		elseif item then
			item:SetActive(false)
		end
	end
end

function FriendWindow:getItem(idx)
	local item = nil
	local switch = {
		function ()
			item = FriendList.new(self.groupMain_.gameObject, self)
		end,
		function ()
			item = FriendSearch.new(self.groupMain_.gameObject, self)
		end,
		function ()
			item = FriendApply.new(self.groupMain_.gameObject, self)
		end,
		function ()
			item = FriendAssistant2.new(self.groupMain_.gameObject, self)
		end
	}

	switch[idx]()

	if self.itemList[idx] == nil then
		self.itemList[idx] = item
	end

	return item
end

function FriendWindow:getItemValue(index)
	return self.itemList[index]
end

function FriendWindow:onGetFriendBossInfo(event)
	if self.itemList[4] ~= nil then
		self.itemList[4]:updateFriendBossInfo()
	end

	self:updateRedPoint()
end

function FriendWindow:onGetSearchInfo(event)
	if self.curSelect_ ~= 2 then
		return
	end

	xyd.WindowManager.get():openWindow("arena_formation_window", {
		not_show_mail = true,
		is_robot = false,
		player_id = event.data.player_id,
		server_id = event.data.server_id
	})
end

function FriendWindow:onError(event)
	local errorCode = event.data.error_code
	local errorMid = event.data.error_mid

	if errorCode == xyd.ErrorCode.BOSS_NO_EXIST then
		xyd.alertTips(__("FRIEND_BOSS_HAS_KILL"))
		FriendModel:getInfo(true)
	end
end

function FriendWindow:onAccept(event)
	local playerInfo = event.data.player_info
	local playerId = playerInfo.player_id or 0

	dump(playerId, "__________________________________________")

	if self.items_[3] then
		self.items_[3]:update(playerId, true)
	end

	if self.items_[1] then
		self.items_[1]:update()
	end

	self:updateRedPoint()
end

function FriendWindow:onDeleteRequest(event)
	local playerIDs = event.data.friend_ids
	local flag = false

	if #playerIDs == 1 then
		flag = true
	end

	if self.items_[3] then
		self.items_[3]:update(playerIDs[1], flag)
	end
end

function FriendWindow:onDelete()
	if self.items_[1] then
		self.items_[1]:update()
	end
end

function FriendWindow:onGetRecommendList()
	if self.items_[2] then
		self.items_[2]:update(nil, , true)
	end
end

function FriendWindow:onApply(event)
	local friend_id = event.data.friend_id or 0

	if FriendModel:isShowApplyTips(friend_id) then
		FriendModel:setShowApplyTipsID(-1)
		xyd.alertTips(__("FRIEND_APPLY_SUCCESS"))
	end

	if self.items_[2] then
		self.items_[2]:update(friend_id, true)
	end
end

function FriendWindow:onSendGifts()
	if self.items_[1] then
		self.items_[1]:update()
	end
end

function FriendWindow:onItemChange()
	if self.items_[1] then
		self.items_[1]:updateRes()
	end
end

function FriendWindow:onFriendDel()
	if self.items_[1] then
		self.items_[1]:updateRes()
	end
end

function FriendWindow:onFightBoss(event)
	if self.items_[1] then
		self.items_[1]:update()
	end

	if self.items_[4] then
		self.items_[4]:update()
		self.items_[4]:checkBossTips(false)
	end
end

function FriendWindow:onGetGifts(event)
	local fids = event.data.friend_ids

	if self.items_[1] then
		self.items_[1]:update()
	end

	local params = {
		hideText = true,
		itemID = xyd.ItemID.FRIEND_LOVE,
		num = #fids
	}

	if not self.itemFloat_ then
		self.itemFloat_ = import("app.components.ItemFloat").new(self.itemFloatRoot_.gameObject)
	else
		self.itemFloat_:destroy()

		self.itemFloat_ = import("app.components.ItemFloat").new(self.itemFloatRoot_.gameObject)
	end

	self.itemFloat_:setInfo(params)
	self.itemFloat_:playGetAni()
end

function FriendWindow:onSearchBoss(event)
	local data = event.data

	if self.items_[4] then
		self.items_[4]:update(data)
	end

	self:updateRedPoint()
end

function FriendWindow:onSweepBoss(event)
	local data = event.data
	local bossID = data.boss_id or 0

	if data.items then
		local params = {
			items = data.items,
			score = data.score,
			harm = data.total_harm,
			callback = function ()
				if bossID <= 0 then
					xyd.alertTips(__("FRIEND_BOSS_KILL"))
				end
			end
		}

		xyd.WindowManager.get():openWindow("alert_award_with_harm_window", params)

		if self.item_[1] then
			self.item_[1]:update()
		end

		if self.item_[4] then
			self.items_[4]:update()
			self.items_[4]:checkBossTips(false)
		end
	end
end

function FriendWindow:updateTopButton()
	for i = 1, 4 do
		local btn = self.navList_[i].navBtn
		local label = self.navList_[i].navLabel

		if i == self.curSelect_ then
			btn:SetEnabled(false)

			label.color = Color.New2(4294967295.0)
			label.effectStyle = UILabel.Effect.Outline
			label.effectColor = Color.New2(1012112383)
		else
			btn:SetEnabled(true)

			label.color = Color.New2(960513791)
			label.effectStyle = UILabel.Effect.None
		end
	end
end

function FriendWindow:btnSelectTouchEvent(index)
	if index == 4 then
		local lev = xyd.models.backpack:getLev()
		local openLev = tonumber(xyd.tables.miscTable:getVal("friend_search_level"))

		if lev < openLev then
			xyd.alertTips(__("FUNC_OPEN_LEV", openLev))

			return
		end
	end

	self.curSelect_ = index

	self:updateTopButton()
	self:updateSelect()
	self:updateRedPoint()
end

function FriendWindow:updateRedPoint()
	if self.curSelect_ == 1 then
		xyd.models.friend:setReceiveRed(false)
	elseif self.curSelect_ == 3 then
		xyd.models.friend:setRequestRed(false)
	end

	if xyd.models.friend:isReceiveRed() then
		self.imgRedList_:SetActive(true)
	end

	if xyd.models.friend:isFriendBossRed() then
		self.imgRedAssistant_:SetActive(true)
	else
		self.imgRedAssistant_:SetActive(false)
	end

	if xyd.models.friend:isRequestRed() and not xyd.models.friend:isFullFriends() then
		self.imgRedApply_:SetActive(true)
	else
		self.imgRedApply_:SetActive(false)
	end

	if not xyd.models.friend:isFullFriends() and tonumber(xyd.tables.miscTable:getVal("friend_apply_limit")) <= #xyd.models.friend:getRequestList() then
		self.redFullApply_:SetActive(true)
		self.imgRedApply_:SetActive(false)
	else
		self.redFullApply_:SetActive(false)
	end
end

return FriendWindow
