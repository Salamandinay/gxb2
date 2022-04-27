local HeroIcon = import("app.components.HeroIcon")
local HeroIconWithHpAndMp = class("HeroIconWithHpAndMp", import("app.components.CopyComponent"))

function HeroIconWithHpAndMp:ctor(go)
	HeroIconWithHpAndMp.super.ctor(self, go)

	self.hp_ = 0
	self.mp_ = 0
end

function HeroIconWithHpAndMp:initUI()
	HeroIconWithHpAndMp.super.initUI(self)

	self.iconBg = self.go:NodeByName("iconBg").gameObject
	self.hpBar = self.go:ComponentByName("hpBar", typeof(UISlider))
	self.mpBar = self.go:ComponentByName("mpBar", typeof(UISlider))
	local heroIconNode = self.go:NodeByName("heroIcon").gameObject
	self.heroIcon = HeroIcon.new(heroIconNode)
	UIEventListener.Get(self.go).onClick = handler(self, self.onClickIcon)
end

function HeroIconWithHpAndMp:setInfo(params)
	local status = params.status

	if status then
		self.hpBar.value = status.hp / 100
		local mp = status.mp

		if mp == nil then
			mp = 50
		end

		self.mpBar.value = mp / 100
	end

	if params.noEnergy then
		self.mpBar:SetActive(false)
		self.iconBg:SetActive(false)
	else
		self.mpBar:SetActive(true)
		self.iconBg:SetActive(true)
	end

	params.isUnique = true

	self.heroIcon:setInfo(params)

	self.callback = params.callback
end

function HeroIconWithHpAndMp:updateStatus(status)
	self.hpBar.value = status.hp / 100
	local mp = status.mp

	if mp == nil then
		mp = 50
	end

	self.mpBar.value = mp / 100
end

function HeroIconWithHpAndMp:onClickIcon(event)
	if self.noClick then
		return
	end

	if self.callback then
		self:callback()
	end
end

function HeroIconWithHpAndMp:setGrey()
	self.heroIcon:setGrey()
end

local DungeonWindow = class("DungeonWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local CountDown = import("app.components.CountDown")
local ItemFloat = import("app.components.ItemFloat")
local DungeonBussinessMan = import("app.components.DungeonBussinessMan")
local MonsterTable = xyd.tables.monsterTable
local DungeonTable = xyd.tables.dungeonTable
local DungeonDrugTable = xyd.tables.dungeonDrugTable
local DungeonShopTable = xyd.tables.dungeonShopTable
local PartnerTable = xyd.tables.partnerTable

function DungeonWindow:ctor(name, params)
	DungeonWindow.super.ctor(self, name, params)

	self.backpack = xyd.models.backpack
	self.dungeon = xyd.models.dungeon
	self.DEFAULT_SCALE_NUM = 1.05
	self.selectIndex_ = 1
	self.isDungeonOpen_ = true
	self.partnerBar_ = {}
	self.heroIcons_ = {}
	self.dungeonEnd_ = false
	self.timeKey_ = {}
	self.actions = {}
	self.isAction_ = false
	self.isCreateGroupLeft_ = false
	self.isCreateGroupTopLeft_ = false
	self.groupLeftNum_ = {}
	self.enemyEffect_ = {}
	self.is_bg_action_ = false
	self.hero_appear_effect_ = nil
	self.enemy_appear_effect_ = nil
	self.bussiness_appear_effect_ = nil
	self.curPartnerID_ = 0
	self.fxTreasure = {
		"baoxiang_dakai"
	}
	self.fxEnemy = {
		"direnshijian_diyan"
	}
	self.fxDrug = {
		"fantuan_bhg_bai",
		"fantuan_bhg_lv",
		"fantuan_bhg_hong"
	}
	self.fxDrugAniName = {
		"texiao",
		"texiao",
		"texiao01"
	}
	self.fxDrugIcon = {
		"fantuan_ui",
		"gongju_ui"
	}
	self.fxDrugExit = {
		"fantuan_tuichang",
		"gongju_tuichang"
	}
	self.fxAllDie = {
		"fx_ui_zhenwangyan"
	}
	self.fxBtn = {
		"fx_ui_ruchang",
		"fx_ui_shoudong"
	}
	self.fxBusinessMan = {
		"shangren_yan",
		"shangren_tuichang"
	}
	self.fxTree = {
		"shuye"
	}
	self.businessMan2 = {
		"zhanghongpifu",
		"shengdanxueqiao",
		"mizhubaozang"
	}
	self.saodang = {
		"sdsl",
		"sdyh"
	}
	self.useDrug = {
		"hanlingdi_hurt03"
	}
	self.hero_appear_effect_name_ = "chuchangtongyong"
	self.enemy_appear_effect_name_ = "difangchuchang"
	self.bussiness_appear_effect_name_ = "chuansongmen"
	self.selectIndex_ = self.dungeon:getSelectIndex()
end

function DungeonWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.bg_ = winTrans:ComponentByName("bg_", typeof(UITexture))
	self.bgSmall_ = winTrans:ComponentByName("bgSmall_", typeof(UISprite))
	local top = winTrans:NodeByName("top").gameObject
	self.groupModels_ = top:NodeByName("groupModels_").gameObject
	self.groupPartner_ = self.groupModels_:NodeByName("groupPartner_").gameObject
	self.shadow_1 = self.groupModels_:NodeByName("groupPartner_/shadow").gameObject
	self.shadow_2 = self.groupModels_:NodeByName("enemyShadow").gameObject
	self.groupPartnerEffect = self.groupModels_:NodeByName("groupPartnerEffect").gameObject
	self.groupBussinessEffect = self.groupModels_:NodeByName("groupBussinessEffect").gameObject
	self.groupEnemy_ = self.groupModels_:NodeByName("groupEnemy_").gameObject
	self.groupBusiness = self.groupModels_:NodeByName("groupBusiness").gameObject
	self.groupBusinessDisappear = self.groupModels_:NodeByName("groupBusinessDisappear").gameObject
	self.groupBox = self.groupModels_:NodeByName("groupBox").gameObject
	self.groupEnemyEffect = self.groupModels_:NodeByName("groupEnemyEffect").gameObject
	self.drugIcon = self.groupModels_:ComponentByName("drugIcon", typeof(UISprite))
	self.imgBox = self.groupBox:ComponentByName("imgBox", typeof(UISprite))
	self.groupHp = self.groupModels_:NodeByName("groupHp").gameObject
	self.hpBar = self.groupHp:ComponentByName("hpBar", typeof(UISlider))
	self.mpBar = self.groupHp:ComponentByName("mpBar", typeof(UISlider))
	self.partnerGroupImg = self.groupHp:ComponentByName("group", typeof(UISprite))
	self.itemFloatPos = top:NodeByName("itemFloatPos").gameObject
	self.groupTree_ = top:NodeByName("groupTree_").gameObject
	self.groupTitle = top:NodeByName("groupTitle").gameObject
	self.groupPreview_ = top:NodeByName("groupPreview_").gameObject
	self.groupPreviewBg_ = self.groupPreview_:ComponentByName("e:Image", typeof(UISprite))
	self.labelTitle_ = self.groupTitle:ComponentByName("labelTitle_", typeof(UILabel))
	self.groupTopTimer_ = self.groupTitle:NodeByName("groupTopTimer_").gameObject
	self.labelTopTimeDesc_ = self.groupTopTimer_:ComponentByName("e:Group/labelTopTimeDesc_", typeof(UILabel))
	self.labelTopTimeNode_ = self.groupTopTimer_:ComponentByName("e:Group/labelTopTime_", typeof(UILabel))
	self.labelPreviewTitle_ = self.groupPreview_:ComponentByName("labelPreviewTitle_", typeof(UILabel))
	self.groupPreviewHeros_ = self.groupPreview_:NodeByName("groupPreviewHeros_").gameObject
	local top_left = winTrans:NodeByName("top_left").gameObject
	self.top_left_widget = winTrans:ComponentByName("top_left", typeof(UIWidget))
	self.groupTopLeft_ = top_left:NodeByName("groupTopLeft_").gameObject
	self.groupDrug4 = self.groupTopLeft_:NodeByName("groupDrug4").gameObject
	self.bar1 = self.groupDrug4:ComponentByName("bar1", typeof(UISlider))
	self.groupDrug5 = self.groupTopLeft_:NodeByName("groupDrug5").gameObject
	self.bar2 = self.groupDrug5:ComponentByName("bar2", typeof(UISlider))
	self.groupDrug6 = self.groupTopLeft_:NodeByName("groupDrug6").gameObject
	self.bar3 = self.groupDrug6:ComponentByName("bar3", typeof(UISlider))
	self.privilegeCardCon = winTrans:NodeByName("privilegeCardCon").gameObject
	self.privilegeCardCon2 = self.privilegeCardCon:NodeByName("privilegeCardCon2").gameObject
	self.privilegeCardBg = self.privilegeCardCon2:ComponentByName("privilegeCardBg", typeof(UITexture))
	self.privilegeCardIcon = self.privilegeCardCon2:ComponentByName("privilegeCardIcon", typeof(UITexture))
	self.privilegeCardLabel = self.privilegeCardCon2:ComponentByName("privilegeCardLabel", typeof(UILabel))
	local top_right = winTrans:NodeByName("top_right").gameObject
	self.groupTopRightBtns = top_right:NodeByName("groupTopRightBtns").gameObject
	self.btnRank_ = self.groupTopRightBtns:NodeByName("btnRank_").gameObject
	self.helpBtn = self.groupTopRightBtns:NodeByName("helpBtn").gameObject
	self.btnDressShow = self.groupTopRightBtns:NodeByName("btnDressShow").gameObject
	local bot = winTrans:NodeByName("bot").gameObject
	self.btnFight_ = bot:NodeByName("btnFight_").gameObject
	self.groupSelect = bot:NodeByName("groupSelect").gameObject
	self.imgSelect = self.groupSelect:NodeByName("e:Group/imgSelect").gameObject
	self.labelDesc = self.groupSelect:ComponentByName("labelDesc", typeof(UILabel))
	self.groupBot = bot:NodeByName("groupBot").gameObject
	self.groupIcons_ = self.groupBot:NodeByName("groupIcons_").gameObject
	self.groupAllDieNode = self.groupBot:NodeByName("groupAllDieNode").gameObject
	self.groupBotTimer_ = self.groupBot:NodeByName("groupBotTimer_").gameObject
	self.groupBotTimerEffect_ = self.groupBotTimer_:NodeByName("groupBotTimerEffect_").gameObject
	self.labelBotTimedesc_ = self.groupBotTimer_:ComponentByName("labelBotTimedesc_", typeof(UILabel))
	self.labelBotTimeNode_ = self.groupBotTimer_:ComponentByName("labelBotTime_", typeof(UILabel))
	local bot_left = winTrans:NodeByName("bot_left").gameObject
	self.groupLeft_ = bot_left:NodeByName("groupLeft_").gameObject
	self.btnShop_ = winTrans:NodeByName("bot_right/btnShop_").gameObject
	self.btnChangeMol_ = winTrans:NodeByName("mid_right/btnChangeMol_").gameObject
	self.imgMask_ = winTrans:NodeByName("imgMask_").gameObject
	self.bgMask = winTrans:NodeByName("bgMask").gameObject
	self.itemTips = winTrans:NodeByName("itemTips").gameObject
	self.awardEffect_ = winTrans:NodeByName("awardEffect_").gameObject
	self.bgEffect_ = winTrans:NodeByName("bgEffect").gameObject
	self.effectChris1_ = xyd.WindowManager.get():setChristmasEffect(self.bgEffect_, true)
end

function DungeonWindow:initModelPos()
end

function DungeonWindow:initWindow()
	DungeonWindow.super.initWindow(self)
	self:getUIComponent()
	self.dungeon:reqDungeonInfo()
	self:layout()
	self:initTime()
	self:initTitle(true)
	self:initModelPos()

	self.labelDesc.text = __("SKIP_ANIMATION")

	if self.dungeon:isOpen() then
		local partners = self.dungeon:getPartners()

		if #partners <= 0 then
			xyd.WindowManager.get():openWindow("dungeon_select_heros_window")

			local effects = {}
		else
			self:initBg(false)
			self:initButton()
			self:initHeros()
			self:initEnemy()
			self:initStartFight()
			self:initTopLeft()
			self:initGroupLeft()
		end
	else
		xyd.setUITextureAsync(self.bg_, "Textures/scenes_web/dungeon_bg")
	end

	self:registerEvent()
	self:initPrivilegeCard()
end

function DungeonWindow:layout()
	self.windowTop = WindowTop.new(self.window_, self.name_, 110, true)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)

	self.labelPreviewTitle_.text = __("DUNGEON_MONSTER_PREVIEW")
	self.labelTopTimeDesc_.text = __("DUNGEON_TIME_COUNT_END")
	self.labelBotTimedesc_.text = __("DUNGEON_TIME_COUNT_START")
	self.labelTopTime_ = CountDown.new(self.labelTopTimeNode_)
	self.labelBotTime_ = CountDown.new(self.labelBotTimeNode_)
	local allHeight = self.window_:GetComponent(typeof(UIPanel)).height

	self.bgSmall_:Y(10 + 71 * (allHeight - 1280) / 178)
end

function DungeonWindow:initButton()
	if self.dungeon:isSkipReport() then
		self.imgSelect:SetActive(true)
	else
		self.imgSelect:SetActive(false)
	end

	local fxBtnEffect1 = self.btnFight_:NodeByName("fx_btn_fight")

	if self.dungeon:isOpen() then
		self.btnShop_:SetActive(true)
		self.groupSelect:SetActive(true)
		self.btnFight_:SetActive(true)

		if not fxBtnEffect1 and self.dungeon:checkHasAlive() and not self.dungeon:isAllPass() then
			self:addBtnFx(self.btnFight_, self.fxBtn[1], "fx_btn_fight", {
				scaleX = 1.3,
				x = 0,
				y = 0
			})
		end

		local curItem = self.dungeon:getCurShopItem()

		if curItem > 0 and fxBtnEffect1 then
			fxBtnEffect1:SetActive(false)
		end
	else
		self.btnShop_:SetActive(false)
		self.groupSelect:SetActive(false)
		self.btnFight_:SetActive(false)

		if fxBtnEffect1 then
			fxBtnEffect1:SetActive(false)
		end
	end
end

function DungeonWindow:addBtnFx(btn, fxName, objName, pos)
	local sp = xyd.Spine.new(btn)

	sp:setInfo(fxName, function ()
		if tolua.isnull(self.window_) then
			return
		end

		sp:getGameObject().name = objName

		sp:SetLocalScale(pos.scaleX or 1, 1, 1)
		sp:play("texiao", 0)
	end)
end

function DungeonWindow:initTitle(complete)
	local title = ""

	if self.dungeon:isOpen() then
		local curStage = self.dungeon:getCurStage()
		local maxStage = self.dungeon:getMaxStage()
		curStage = xyd.checkCondition(maxStage < curStage, maxStage, curStage)
		local type_ = DungeonTable:getType(curStage)
		curStage = curStage - (type_ - 1) * 100

		if complete then
			title = __("DUNGEON_TITLE", __("DUNGEON_HARD_" .. tostring(type_)), curStage)
		else
			title = "--"
		end
	else
		title = __("NO_OPEN")
	end

	self.labelTitle_.text = title

	self.labelTitle_:SetActive(true)
	self.groupTitle:SetActive(true)
end

function DungeonWindow:initHeros()
	local partners = self.dungeon:getPartners()

	if #partners <= 0 then
		self.groupIcons_:SetActive(false)
	else
		self.groupBot:SetActive(true)

		local isChange = false
		local firstAlive = -1

		self.groupIcons_:SetActive(true)
		self.groupModels_:SetActive(true)

		for i = 1, #partners do
			local partner = partners[i]
			local icon = self.heroIcons_[i]
			local x_ = (i - 1) * 136 + 68

			if not icon then
				local itemIcon = NGUITools.AddChild(self.groupIcons_, self.groupIcons_:NodeByName("iconItem").gameObject)
				icon = HeroIconWithHpAndMp.new(itemIcon)
				local y_ = 0
				local skinID = 0

				if partner.show_skin and partner.show_skin == 1 and partner.equips and partner.equips[7] and partner.equips[7] > 0 then
					skinID = partner.equips[7]
				end

				local params = {
					noClick = true,
					tableID = partner.table_id,
					lev = partner.lv,
					star = PartnerTable:getStar(partner.table_id) + partner.awake,
					status = partner.status,
					skin_id = skinID,
					is_vowed = partner.is_vowed,
					callback = function ()
						self:changeSelect(i)
					end
				}

				icon:setInfo(params)

				if self.selectIndex_ == i and partner.status.hp > 0 then
					self:initPartner()

					y_ = 20
				end

				icon:SetLocalPosition(x_, y_, 0)
				table.insert(self.heroIcons_, icon)
			end

			icon:updateStatus(partner.status)

			if i == self.selectIndex_ and self.partnerBar_.hp then
				self.partnerBar_.hp.value = partner.status.hp / 100
				local mp = xyd.checkCondition(partner.status.mp, partner.status.mp, 50)
				self.partnerBar_.mp.value = mp / 100
			end

			if partner.status.hp == 0 then
				icon:setGrey()
				icon:SetLocalPosition(x_, 0, 0)
				xyd.setTouchEnable(icon:getGameObject(), false)
			elseif firstAlive == -1 then
				firstAlive = i
			end

			if i == self.selectIndex_ and partner.status.hp == 0 then
				isChange = true
			end
		end

		if isChange then
			if firstAlive == -1 then
				self:changeBtnFightStatus(false)
				self.groupModels_:SetActive(false)

				self.dungeonEnd_ = true

				xyd.setTouchEnable(self.imgSelect, false)
			else
				self.selectIndex_ = firstAlive

				self.dungeon:recordSelectIndex(firstAlive)

				local partner = partners[self.selectIndex_]

				self:initPartner()

				local icon = self.heroIcons_[self.selectIndex_]

				icon:updateStatus(partner.status)

				local pos = icon:getGameObject().transform.localPosition

				icon:SetLocalPosition(pos.x, 20, 0)
			end
		end
	end
end

function DungeonWindow:changeSelect(i)
	if self.selectIndex_ ~= i then
		local oldIcon = self.heroIcons_[self.selectIndex_]
		local newIcon = self.heroIcons_[i]

		for _, icon in ipairs(self.heroIcons_) do
			icon.noClick = true
		end

		local complete1 = false
		local complete2 = false
		local action1 = self:getTimeLineLite()
		local oldTrans = oldIcon:getGameObject().transform

		action1:Append(oldTrans:DOLocalMove(Vector3(oldTrans.localPosition.x, 0, 0), 0.1)):AppendCallback(function ()
			complete1 = true

			if complete1 and complete2 then
				for _, icon in ipairs(self.heroIcons_) do
					icon.noClick = false
				end
			end
		end)

		local action2 = self:getTimeLineLite()
		local newIconTrans = newIcon:getGameObject().transform

		action2:Append(newIconTrans:DOLocalMove(Vector3(newIconTrans.localPosition.x, 20, 0), 0.1)):AppendCallback(function ()
			complete2 = true

			if complete1 and complete2 then
				for _, icon in ipairs(self.heroIcons_) do
					icon.noClick = false
				end
			end
		end)

		self.selectIndex_ = i

		self.dungeon:recordSelectIndex(i)
		self:initPartner()
	end
end

function DungeonWindow:initPartner(isSkipAni)
	local partners = self.dungeon:getPartners()
	local partner = partners[self.selectIndex_]
	local skinID = 0

	if partner.equips and partner.equips[7] and partner.equips[7] > 0 then
		skinID = partner.equips[7]
	end

	local hp = partner.status.hp
	local mp = partner.status.mp
	self.hpBar.value = hp / 100
	self.mpBar.value = mp / 100
	self.curPartnerID_ = partner.table_id

	xyd.setUISpriteAsync(self.partnerGroupImg, nil, "img_group" .. xyd.tables.partnerTable:getGroup(partner.table_id))

	if not isSkipAni then
		self.groupPartner_:SetActive(false)

		local function callback()
			self.hero_appear_effect:play("texiao01", 1, 1, nil, true)

			local timeKey_ = "initPartner_time_key"

			XYDCo.WaitForTime(0.6, function ()
				self.groupPartner_:SetActive(true)
			end, timeKey_)
			self:addTimeKey(timeKey_)
		end

		if not self.hero_appear_effect then
			self.hero_appear_effect = xyd.Spine.new(self.groupPartnerEffect)

			self.hero_appear_effect:setInfo(self.hero_appear_effect_name_, function ()
				callback()
			end)
		else
			callback()
		end
	end

	local modelInfo = xyd.getModelInfo(partner.table_id, false, skinID, 1)

	if self.partnerSpine_ then
		if self.partnerSpine_:getName() == modelInfo.name then
			return
		end

		self.partnerSpine_:destroy()

		self.partnerSpine_ = nil
	end

	local scale = modelInfo.scale * self.DEFAULT_SCALE_NUM
	local sp = xyd.Spine.new(self.groupPartner_)

	sp:setInfo(modelInfo.name, function ()
		if tolua.isnull(self.window_) then
			sp:destroy()

			return
		end

		sp:SetLocalPosition(0, 0, -10)
		sp:SetLocalScale(scale, scale, 1)
		sp:play("idle", 0)
		self.groupHp:SetActive(true)

		self.partnerBar_.hp = self.hpBar
		self.partnerBar_.mp = self.mpBar
		local bone = sp:getBone("Phead")

		if bone then
			dump("++++++++++++")
			dump(PartnerTable:getModelID(partner.table_id))

			if skinID > 0 then
				local bloodPos = xyd.tables.modelTable:getBloodPos(xyd.tables.equipTable:getSkinModel(skinID))

				self.groupHp:SetLocalPosition(-180 + bloodPos[1], -135 + bone.Y * scale + bloodPos[2], 0)
			else
				local bloodPos = xyd.tables.modelTable:getBloodPos(PartnerTable:getModelID(partner.table_id))

				self.groupHp:SetLocalPosition(-180 + bloodPos[1], -135 + bone.Y * scale + bloodPos[2], 0)
			end
		end
	end)

	self.partnerSpine_ = sp
end

function DungeonWindow:initEnemy()
	NGUITools.DestroyChildren(self.groupEnemy_.transform)

	self.groupEnemy_:GetComponent(typeof(UIWidget)).alpha = 1

	if not self.dungeon:checkHasAlive() then
		return
	end

	local curItem = self.dungeon:getCurShopItem()

	if curItem > 0 then
		self:playBusinessManAction()
	else
		self:playEnemyAction()
	end
end

function DungeonWindow:initModel(id, isMonster, callback, skinID, showSkin)
	if skinID == nil then
		skinID = 0
	end

	if showSkin == nil then
		showSkin = 1
	end

	self:loadHeroModelByID(id, isMonster, callback, skinID, showSkin, xyd.Global.usePvr)
end

function DungeonWindow:initTime()
	self.groupBotTimer_:SetActive(false)
	self.groupTopTimer_:SetActive(false)

	if self.dungeon:isOpen() then
		local data = self.dungeon:getData()
		local endTime = data.end_time

		if endTime then
			self.groupTopTimer_:SetActive(true)

			local duration = endTime - xyd.getServerTime()

			self.labelTopTime_:setInfo({
				duration = duration
			})
		end

		self.shadow_1:SetActive(true)
		self.shadow_2:SetActive(true)
	else
		self.groupBot:SetActive(true)
		self.shadow_1:SetActive(false)
		self.shadow_2:SetActive(false)

		local data = self.dungeon:getData()
		local startTime = data.start_time

		if startTime then
			self.groupBotTimer_:SetActive(true)

			local duration = startTime - xyd.getServerTime()

			self.labelBotTime_:setInfo({
				duration = duration
			})
		end
	end
end

function DungeonWindow:initData()
end

function DungeonWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnRank_).onClick = handler(self, self.rankTouch)
	UIEventListener.Get(self.btnShop_).onClick = handler(self, self.shopTouch)
	UIEventListener.Get(self.btnFight_).onClick = handler(self, self.fightTouch)
	UIEventListener.Get(self.groupSelect).onClick = handler(self, self.changeMolTouch)
	UIEventListener.Get(self.groupEnemy_).onClick = handler(self, self.onGroupEnemyTouch)
	UIEventListener.Get(self.groupBusiness).onClick = handler(self, self.onGroupEnemyTouch)
	UIEventListener.Get(self.imgMask_).onClick = handler(self, self.onClickMask)

	UIEventListener.Get(self.btnDressShow).onClick = function ()
		xyd.WindowManager.get():openWindow("dress_show_buffs_detail_window", {
			function_id = xyd.FunctionID.DUNGEON
		})
	end

	self.eventProxy_:addEventListener(xyd.event.DUNGEON_GET_MAP_INFO, handler(self, self.onDungeonInfo))
	self.eventProxy_:addEventListener(xyd.event.DUNGEON_START, handler(self, self.onStartDungeon))
	self.eventProxy_:addEventListener(xyd.event.DUNGEON_USE_DRUG, handler(self, self.onUseDrug))
	self.eventProxy_:addEventListener(xyd.event.DUNGEON_BUY_CUR_ITEM, handler(self, self.onBuyCurShopItem))
	self.eventProxy_:addEventListener(xyd.event.DUNGEON_SKIP_REPORT, handler(self, self.initButton))
end

function DungeonWindow:onDungeonInfo()
	if tolua.isnull(self.window_) then
		return
	end

	self.isAction_ = false
	local partners = self.dungeon:getPartners()

	self:initTime()

	if self.dungeon:isOpen() then
		if #partners <= 0 then
			self:initTitle(false)
			xyd.WindowManager.get():openWindow("dungeon_select_heros_window")
		else
			self:initTitle(true)
			self:initBg(true)
			self:initButton()
			self:changeBtnFightStatus(false)
			self:initHeros()
			self:initEnemy()
			self:initStartFight()
			self:initTopLeft()
			self:initGroupLeft()
		end
	end
end

function DungeonWindow:initBg(play_animation)
	local cur_stage = math.min(self.dungeon:getCurStage(), self.dungeon:getMaxStage())
	local source = DungeonTable:getMapSource(cur_stage)
	local action = nil

	if self.curBgSrc_ and source == self.curBgSrc_ then
		return
	end

	self.curBgSrc_ = source
	local getter, setter = nil
	local bgMaskW = self.bgMask:GetComponent(typeof(UIWidget))

	if play_animation then
		getter, setter = xyd.getTweenAlphaGeterSeter(bgMaskW)
		bgMaskW.alpha = 0.01

		self.bgMask:SetActive(true)

		action = DG.Tweening.DOTween.Sequence()
		self.is_bg_action_ = true

		action:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.3))
	end

	local bg = self.bg_
	local scale = DungeonTable:getMapScale(cur_stage)
	local postion = DungeonTable:getMapPosition(cur_stage)

	xyd.setUITextureByNameAsync(self.bg_, source)
	bg:SetLocalScale(scale, scale, 1)
	bg:SetLocalPosition(postion[1], -postion[2], 0)

	if play_animation then
		action:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0.3)):AppendCallback(function ()
			self.is_bg_action_ = false

			if self.bgMask then
				self.bgMask:SetActive(false)
			end

			if not self.isAction_ then
				self:changeBtnFightStatus(true)
			end
		end)
	end
end

function DungeonWindow:onUseDrug()
	self:initHeros()
	self:initGroupLeft()

	local effect = xyd.Spine.new(self.groupPartner_)

	effect:setInfo(self.useDrug[1], function ()
		effect:play("texiao", 1, 1, function ()
			effect:destroy()
		end)

		local spineAni = self.partnerSpine_:getAnim()

		if spineAni then
			local boneName = "Pshouji"
			local bone = spineAni:getBone(boneName)
			local scale = self.partnerSpine_:getGameObject().transform.localScale
			local x_ = bone.X * scale.x
			local y_ = bone.Y * scale.y

			effect:SetLocalPosition(x_, y_, 0)
		end
	end)
end

function DungeonWindow:onStartDungeon(event)
	local sweepAwards = event.data.sweep_awards

	if sweepAwards and (sweepAwards.items and #sweepAwards.items > 0 or sweepAwards.drugs and #sweepAwards.drugs > 0) then
		self:showSweep(sweepAwards)
	else
		self:onDungeonInfo()
	end
end

function DungeonWindow:showSweep(sweepAwards)
	self.labelTitle_:SetActive(false)
	self.groupTopTimer_:SetActive(false)
	self.awardEffect_:SetActive(true)

	local effect = xyd.Spine.new(self.awardEffect_)

	effect:setInfo(self.saodang[1], function ()
		if tolua.isnull(self.window_) then
			effect:destroy()

			return
		end

		effect:SetLocalPosition(0, 0, 0)
		effect:SetLocalScale(1, 1, 1)
		effect:setRenderTarget(self.awardEffect_:GetComponent(typeof(UIWidget)), 1)
		effect:play("texiao01_" .. xyd.lang, 1, 1, function ()
			effect:play("texiao02_" .. xyd.lang, 0)
		end)
	end)

	local yh = nil

	XYDCo.WaitForTime(0.6, function ()
		yh = xyd.Spine.new(self.awardEffect_)

		yh:setInfo(self.saodang[2], function ()
			if tolua.isnull(self.window_) then
				yh:destroy()

				return
			end

			yh:SetLocalPosition(0, 0, 0)
			yh:SetLocalScale(1, 1, 1)
			yh:setRenderTarget(self.awardEffect_:GetComponent(typeof(UISprite)), 2)
			yh:play("texiao01", 1, 1)
		end)
	end, nil)
	XYDCo.WaitForTime(1.5, function ()
		local items = sweepAwards.items

		for _, item in ipairs(sweepAwards.drugs) do
			local id = DungeonDrugTable:getId(item.item_id)

			table.insert(items, {
				item_id = id,
				item_num = item.item_num
			})
		end

		xyd.alertItems(items, function ()
			if effect then
				effect:destroy()
			end

			if yh then
				yh:destroy()
			end

			if tolua.isnull(self.window_) then
				effect:destroy()

				return
			end

			if self.awardEffect_ then
				self.awardEffect_:SetActive(false)
			end

			self:onDungeonInfo()

			if sweepAwards.drugs then
				self:playSweepDrugAction(sweepAwards.drugs, nil)
			end
		end)
	end, nil)
end

function DungeonWindow:changeBtnFightStatus(flag)
	if not self.window_ or tolua.isnull(self.window_) then
		return
	end

	local effect = self.btnFight_:NodeByName("fx_btn_fight")

	if flag and self.dungeon:checkHasAlive() and self.dungeon:getCurStage() <= self.dungeon:getMaxStage() then
		xyd.setEnabled(self.btnFight_, true)
		xyd.applyOrigin(self.btnFight_:GetComponent(typeof(UISprite)))

		if effect then
			effect:SetActive(true)
		end
	else
		xyd.setEnabled(self.btnFight_, false)

		if effect then
			effect:SetActive(false)
		end
	end
end

function DungeonWindow:beforeBattle()
	if self.partnerSpine_ then
		self.partnerSpine_:destroy()

		self.partnerSpine_ = nil
	end

	if self.curEnemyModel_ then
		self.curEnemyModel_:destroy()

		self.curEnemyModel_ = nil
	end
end

function DungeonWindow:playBattleResult(data)
	self.isAction_ = true

	local function callback()
		self:initHeros()

		if data.is_win == 1 then
			local award = data.award

			if #award.items > 0 then
				self:playBoxAction(function ()
					local win = xyd.WindowManager:get():getWindow("dungeon_window")

					if win then
						xyd.models.itemFloatModel:pushNewItems(award.items, function ()
							self:onDungeonInfo()
						end)
					end
				end)
			elseif #award.drugs > 0 then
				self:playDrugAction(award.drugs[1], function ()
					self:onDungeonInfo()
				end)
			else
				self:onDungeonInfo()
			end

			return
		end

		if not self.dungeon:checkHasAlive() then
			self:playAllDieAction()
		end

		self:onDungeonInfo()
	end

	self:changeBtnFightStatus(false)

	if self.dungeon:isSkipReport() then
		self:playEnemyExitAction()
		callback()
		self:initPartner(true)
	else
		NGUITools.DestroyChildren(self.groupEnemy_.transform)
		callback()

		if not self.partnerSpine_ then
			self:initPartner(true)
		end
	end
end

function DungeonWindow:rankTouch()
	local params = {
		mapType = xyd.MapType.DUNGEON
	}

	if not self.dungeon:isOpen() then
		params.hide_self_rank = true
	end

	xyd.WindowManager.get():openWindow("rank_window", params)
end

function DungeonWindow:shopTouch()
	xyd.WindowManager.get():openWindow("dungeon_shop_window")
end

function DungeonWindow:fightTouch()
	if self.isAction_ then
		return
	end

	self.isAction_ = true
	local curItem = self.dungeon:getCurShopItem()

	if curItem > 0 then
		self.dungeon:reqBuyCurItem(1)
	else
		local partners = self.dungeon:getPartners()
		local index = self.selectIndex_
		local partner = partners[index]

		if partner.status.hp <= 0 then
			return
		end

		self.dungeon:reqFight(self.selectIndex_)
	end
end

function DungeonWindow:changeMolTouch()
	self.dungeon:reqSkipReport()
end

function DungeonWindow:onGroupEnemyTouch()
	if self.isAction_ then
		return
	end

	local curItem = self.dungeon:getCurShopItem()

	if curItem > 0 then
		self:showBuyItem()
	else
		self:showEnemy()
	end
end

function DungeonWindow:showBuyItem()
	local curItem = self.dungeon:getCurShopItem()
	local cost = DungeonShopTable:getCost(curItem)
	local item = DungeonShopTable:getItem(curItem)
	local params = {
		itemID = item[1],
		itemNum = item[2],
		cost = cost,
		callback = function ()
			self.dungeon:reqBuyCurItem(0)
		end
	}

	xyd.WindowManager.get():openWindow("dungeon_buy_item_window", params)
end

function DungeonWindow:showEnemy()
	if not self.dungeon:isOpen() then
		return
	end

	local enemies = self.dungeon:getEnemies()

	if #enemies > 0 then
		self.imgMask_:SetActive(true)
		NGUITools.DestroyChildren(self.groupPreviewHeros_.transform)

		for _, enemy in ipairs(enemies) do
			local itemIcon = NGUITools.AddChild(self.groupPreviewHeros_, self.groupIcons_:NodeByName("iconItem").gameObject)
			local icon = HeroIconWithHpAndMp.new(itemIcon)
			local params = {
				noEnergy = true,
				noClick = true,
				tableID = MonsterTable:getPartnerLink(enemy.table_id),
				lev = enemy.lv,
				star = PartnerTable:getStar(MonsterTable:getPartnerLink(enemy.table_id)) + enemy.awake,
				awake = enemy.awake,
				status = enemy.status
			}

			icon:setDepth(10)
			icon:setInfo(params)

			if enemy.status.hp <= 0 then
				icon:setGrey()
			end
		end

		if #enemies >= 5 then
			self.groupPreviewBg_.width = 706
		else
			self.groupPreviewBg_.width = 556
		end

		self.groupPreview_:SetActive(true)
		self.groupPreviewHeros_:GetComponent(typeof(UILayout)):Reposition()
	end
end

function DungeonWindow:onClickMask()
	self.groupPreview_:SetActive(false)
	self.imgMask_:SetActive(false)
end

function DungeonWindow:initTopLeft()
	self.groupTopLeft_:SetActive(true)

	for i = 4, 6 do
		local limit = DungeonDrugTable:getNumMax(i)
		local num = math.min(self.dungeon:getDrugByID(i), limit)
		local effectID = DungeonDrugTable:getEffect(i)[1]
		local type = xyd.tables.effectTable:getType(effectID)
		local effect = xyd.tables.effectTable:getNum(effectID) / tonumber(xyd.tables.dBuffTable:getFactor(type)) * 100
		local desc = DungeonDrugTable:translate(i, num * effect)
		local bar = self["bar" .. i - 3]
		bar.value = num / limit
		bar:ComponentByName("labelDisplay", typeof(UILabel)).text = num .. " / " .. limit

		self:setSingleItemTips(self["groupDrug" .. tostring(i)], "dungeon_drug_" .. tostring(i), DungeonDrugTable:getName(i), desc)
	end

	self.isCreateGroupTopLeft_ = true
end

function DungeonWindow:initGroupLeft()
	if self.isCreateGroupLeft_ then
		for i = 1, 3 do
			local num = self.dungeon:getDrugByID(i)
			local label = self.groupLeftNum_[i]
			label.text = xyd.getRoughDisplayNumber(num)
		end

		return
	end

	self.groupLeft_:SetActive(true)

	self.groupLeftNum_ = {}

	for i = 1, 3 do
		local num = self.dungeon:getDrugByID(i)
		local group = NGUITools.AddChild(self.groupLeft_, self.groupLeft_:NodeByName("item").gameObject)
		group.name = "drug" .. i
		local imgBg = group:ComponentByName("imgBg", typeof(UISprite))
		local imgIcon = group:ComponentByName("imgIcon", typeof(UISprite))
		local labelNum = group:ComponentByName("labelNum", typeof(UILabel))

		xyd.setUISpriteAsync(imgBg, nil, "dungeon_drug_" .. i .. "_icon_bg")
		xyd.setUISpriteAsync(imgIcon, nil, "dungeon_drug_" .. i)

		labelNum.text = num

		table.insert(self.groupLeftNum_, labelNum)
		self:addDrugTouch(group, i)
	end

	self.groupLeft_:GetComponent(typeof(UILayout)):Reposition()

	self.isCreateGroupLeft_ = true
end

function DungeonWindow:addDrugTouch(obj, index)
	local duration = 0
	local key = -1
	local showTips = false

	UIEventListener.Get(obj).onPress = function (go, isPressed)
		if isPressed then
			showTips = false

			XYDCo.WaitForTime(0.2, function ()
				showTips = true

				self:showSingleItemTips(obj, "dungeon_drug_" .. tostring(index), DungeonDrugTable:getName(index), DungeonDrugTable:translate(index), self)
			end, "drug_press")
		else
			XYDCo.StopWait("drug_press")

			if showTips then
				self.itemTips:SetActive(false)

				showTips = false
			else
				if self.dungeon:getDrugByID(index) <= 0 or self.dungeon:checkHasAlive() == false then
					return
				end

				if index ~= 2 and self.dungeon:getPartners()[self.selectIndex_].status.hp == 100 then
					xyd.alertTips(__("DUNGEON_TEXT1"))

					return
				end

				local checkTips = xyd.db.misc:getValue("dungeon_drug_use" .. index .. "_time_stamp")

				if tonumber(checkTips) and xyd.isSameDay(tonumber(checkTips), xyd.getServerTime()) then
					self.dungeon:reqUseDrug(self.selectIndex_, index)
				else
					xyd.WindowManager.get():openWindow("gamble_tips_window", {
						type = "dungeon_drug_use" .. index,
						callback = function ()
							self.dungeon:reqUseDrug(self.selectIndex_, index)
						end,
						text = __("DUNGEON_USE_DRUG", DungeonDrugTable:getName(index))
					})
				end
			end
		end
	end
end

function DungeonWindow:setSingleItemTips(item, icon, name, desc)
	UIEventListener.Get(item).onPress = function (go, isPressed)
		if isPressed then
			self:showSingleItemTips(item, icon, name, desc)
		else
			self.itemTips:SetActive(false)
		end
	end
end

function DungeonWindow:showSingleItemTips(item, icon, name, desc)
	local imgIcon_ = self.itemTips:ComponentByName("imgIcon_", typeof(UISprite))

	xyd.setUISpriteAsync(imgIcon_, nil, icon, function ()
		if not tolua.isnull(imgIcon_) then
			imgIcon_:MakePixelPerfect()
		end
	end)

	local labelName_ = self.itemTips:ComponentByName("labelName_", typeof(UILabel))
	labelName_.text = name
	local labelDesc_ = self.itemTips:ComponentByName("labelDesc_", typeof(UILabel))
	labelDesc_.text = desc

	self.itemTips:SetActive(true)

	local itemBg = self.itemTips:ComponentByName("itemBg", typeof(UISprite))
	itemBg.height = 162 + labelDesc_.height - 20
	local winPos = self.window_.transform:InverseTransformPoint(item.transform.position)

	self.itemTips:SetLocalPosition(winPos.x + 280, winPos.y - 100, 0)
end

function DungeonWindow:initStartFight()
	local curItem = self.dungeon:getCurShopItem()
	local imgIcon_ = self.btnFight_:ComponentByName("imgIcon_", typeof(UISprite))

	if curItem > 0 then
		xyd.setUISpriteAsync(imgIcon_, nil, "dungeon_skip", function ()
			if not tolua.isnull(imgIcon_) then
				imgIcon_:MakePixelPerfect()
			end
		end)
	elseif self.dungeon:isAllPass() then
		imgIcon_:SetActive(false)
		xyd.setTouchEnable(self.btnFight_, false)

		local label = self.btnFight_:ComponentByName("button_label", typeof(UILabel))
		label.text = __("PUB_MISSION_COMPLETE")

		label:SetActive(true)
	else
		xyd.setUISpriteAsync(imgIcon_, nil, "dungeon_fight", function ()
			if not tolua.isnull(imgIcon_) then
				imgIcon_:MakePixelPerfect()
			end
		end)
	end
end

function DungeonWindow:onBuyCurShopItem(event)
	self:changeBtnFightStatus(false)

	local data = event.data

	if data.is_skip == 0 and data.item then
		self:showBuyItemAction(data.item)
	end

	self:playBusinessManExitAction(function ()
		self:onDungeonInfo()
	end)
end

function DungeonWindow:showBuyItemAction(item)
	xyd.models.itemFloatModel:pushNewItems({
		item
	})
end

function DungeonWindow:getEffectID()
end

function DungeonWindow:playEnemyAction()
	if self.dungeon:isAllPass() then
		self.shadow_2:SetActive(false)
		self.groupEnemy_:SetActive(false)
		self.groupBusiness:SetActive(false)

		return
	end

	self.isAction_ = true
	local enemies = self.dungeon:getEnemies()
	local modelInfo = xyd.getModelInfo(enemies[1].table_id, true)
	local modelName = modelInfo.name
	local callback = nil

	function callback()
		if self.enemy_appear_effect_ then
			self.enemy_appear_effect_:play("texiao01", 1)
		end

		XYDCo.WaitForTime(1, function ()
			if tolua.isnull(self.window_) then
				return
			end

			local enemyW = self.groupEnemy_:GetComponent(typeof(UIWidget))
			enemyW.alpha = 0.01

			self.groupEnemy_:SetLocalScale(0.01, 0.01, 1)

			local effect2 = self:initEnemyModel()
			local action = self:getTimeLineLite()
			local getter, setter = xyd.getTweenAlphaGeterSeter(enemyW)

			action:Append(self.groupEnemy_.transform:DOScale(Vector3(1.1, 1.1, 1), 0.3)):Join(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.3)):Append(self.groupEnemy_.transform:DOScale(Vector3(1, 1, 1), 0.2)):AppendCallback(function ()
				if tolua.isnull(self.window_) then
					return
				end

				local tableID = MonsterTable:getPartnerLink(enemies[1].table_id)
				self.isAction_ = false

				if not self.is_bg_action_ then
					self:changeBtnFightStatus(true)
				end
			end)
		end, nil)
	end

	if not self.enemy_appear_effect_ then
		self.enemy_appear_effect_ = xyd.Spine.new(self.groupEnemyEffect)

		self.enemy_appear_effect_:setInfo(self.enemy_appear_effect_name_, function ()
			if tolua.isnull(self.window_) then
				self.enemy_appear_effect_:destroy()

				self.enemy_appear_effect_ = nil

				return
			end

			callback()
		end)
	else
		callback()
	end
end

function DungeonWindow:initEnemyModel()
	local enemies = self.dungeon:getEnemies()
	local modelInfo = xyd.getModelInfo(enemies[1].table_id, true)
	local modelName = modelInfo.name
	local scale = modelInfo.scale * self.DEFAULT_SCALE_NUM
	local effect2 = xyd.Spine.new(self.groupEnemy_)

	effect2:setInfo(modelName, function ()
		if tolua.isnull(self.window_) then
			effect2:destroy()

			return
		end

		effect2:SetLocalScale(-scale, scale, 1)
		effect2:play("idle", 0)
	end)

	self.curEnemyModel_ = effect2

	return effect2
end

function DungeonWindow:checkEnemyEffectNum()
end

function DungeonWindow:saveEnemyEffect(effectName)
end

function DungeonWindow:playEnemyExitAction()
	local effect = self.btnFight_:NodeByName("fx_btn_fight")

	if effect then
		effect:SetActive(false)
	end

	local action = self:getTimeLineLite()
	local enemyW = self.groupEnemy_:GetComponent(typeof(UIWidget))
	local getter, setter = xyd.getTweenAlphaGeterSeter(enemyW)

	action:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0.7)):AppendCallback(function ()
		enemyW.alpha = 1

		NGUITools.DestroyChildren(self.groupEnemy_.transform)
	end)
end

function DungeonWindow:playBusinessManAction()
	self.isAction_ = true
	local effects = {}
	local shopItem = self.dungeon:getCurShopItem()
	local type = DungeonShopTable:getType(shopItem)
	local modelName = self.businessMan2[type]
	local callback = nil

	function callback()
		self.bussiness_appear_effect_:play("texiao01", 1, 1.5)

		local businessW = self.groupBusiness:GetComponent(typeof(UIWidget))
		businessW.alpha = 0.01

		self.groupBusiness:SetLocalScale(0.6, 0.6, 1)

		local effect2 = DungeonBussinessMan.new(self.groupBusiness)

		effect2:SetLocalPosition(0, 224, 0)
		effect2:init(modelName, type, shopItem, nil)

		local action = self:getTimeLineLite()
		local getter, setter = xyd.getTweenAlphaGeterSeter(businessW)

		action:AppendInterval(1.3):Append(self.groupBusiness.transform:DOScale(Vector3(1, 1, 1), 0.4)):Join(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.4)):InsertCallback(1.38, function ()
			effect2:playAction()
		end):AppendCallback(function ()
			self.isAction_ = false

			self:changeBtnFightStatus(true)
		end)

		self.businessMan_ = effect2
	end

	if self.bussiness_appear_effect_ == nil then
		self.bussiness_appear_effect_ = xyd.Spine.new(self.groupBussinessEffect)

		self.bussiness_appear_effect_:setInfo(self.bussiness_appear_effect_name_, function ()
			if tolua.isnull(self.window_) then
				self.bussiness_appear_effect_:destroy()

				self.bussiness_appear_effect_ = nil

				return
			end

			callback()
		end)
	else
		callback()
	end
end

function DungeonWindow:playBusinessManExitAction(callback)
	local effect2 = xyd.Spine.new(self.groupBusinessDisappear)

	effect2:setInfo(self.fxBusinessMan[2], function ()
		if tolua.isnull(self.window_) then
			effect2:destroy()

			return
		end

		effect2:play("texiao", 1)
		effect2:SetLocalPosition(0, 100, 0)

		local businessMan_ = self.businessMan_

		if businessMan_ then
			businessMan_:playDisappear(function ()
				NGUITools.DestroyChildren(self.groupBusiness.transform)
				effect2:destroy()
				callback()
			end)
		else
			NGUITools.DestroyChildren(self.groupBusiness.transform)
			callback()
		end
	end)
end

function DungeonWindow:setTimeOut(duration, callback)
	self.timeOut_ = (self.timeOut_ or 0) + 1
	local key = "dungeon_time_out" .. self.timeOut_

	XYDCo.WaitForTime(duration, callback, key)
	table.insert(self.timeKey_, key)
end

function DungeonWindow:playTreeEffect()
end

function DungeonWindow:playDrugAction(drug, callback)
	local iconName = "dungeon_drug_" .. tostring(drug.item_id)

	xyd.setUISpriteAsync(self.drugIcon, nil, iconName, function ()
		if self.drugIcon then
			self.drugIcon:MakePixelPerfect()
		end
	end)
	self.drugIcon:SetActive(false)
	self.drugIcon:SetLocalPosition(180, 200, 0)

	if drug.item_id <= 3 then
		self:playDrugAction1(drug, callback)
	else
		self:playDrugAction2(drug, callback)
	end
end

function DungeonWindow:playSweepDrugAction(drugs, callback)
	for i = 1, #drugs do
		local drug = drugs[i]
		local call = nil

		if i == #drugs then
			call = callback
		end

		if drug.item_id <= 3 then
			self:playSweepDrugAction1(drug, call)
		else
			self:playSweepDrugAction2(drug, call)
		end
	end
end

function DungeonWindow:playSweepDrugAction1(drug, callback)
	local group = self.groupLeft_:NodeByName("drug" .. drug.item_id)
	local action2 = self:getTimeLineLite()

	action2:Append(group:DOScale(Vector3(1.5, 1.5, 1), 0.2)):AppendCallback(function ()
		local effect = xyd.Spine.new(group.gameObject)

		effect:setInfo(self.fxDrugIcon[1], function ()
			effect:SetLocalScale(1, 1, 1)
			effect:setRenderTarget(group:ComponentByName("imgBg", typeof(UIWidget)), 1)
			effect:play("texiao", 1, 1, function ()
				effect:destroy()
			end)
		end)
	end):Append(group:DOScale(Vector3(1, 1, 1), 0.3))
end

function DungeonWindow:playSweepDrugAction2(drug, callback)
	local id = drug.item_id
	local groupDrug = self["groupDrug" .. id]
	local imgDrug = groupDrug:NodeByName("imgDrug" .. id)
	local action2 = self:getTimeLineLite()

	action2:Append(imgDrug:DOScale(Vector3(1.5, 1.5, 1), 0.2)):AppendCallback(function ()
		local effect = xyd.Spine.new(groupDrug)

		effect:setInfo(self.fxDrugIcon[2], function ()
			effect:SetLocalScale(1, 1, 1)
			effect:setRenderTarget(imgDrug:GetComponent(typeof(UIWidget)), 1)
			effect:play("texiao", 1, 1, function ()
				effect:destroy()
			end)
		end)
	end):Append(imgDrug:DOScale(Vector3(1, 1, 1), 0.3))
end

function DungeonWindow:playDrugAction1(drug, callback)
	local icon = self.drugIcon

	self:setTimeOut(0.3, function ()
		local effect2 = xyd.Spine.new(icon.gameObject)
		local aniName = self.fxDrugAniName[drug.item_id]

		effect2:setInfo(self.fxDrug[drug.item_id], function ()
			effect2:SetLocalPosition(0, 0, 0)
			effect2:setRenderTarget(icon, -1)
			effect2:play(aniName, 0)
		end)
		icon:SetActive(true)

		local animation = icon:GetComponent(typeof(UnityEngine.Animation))

		animation:Play("drugIconAni")

		local event = icon:GetComponent(typeof(LuaAnimationEvent))

		function event.callback(eventName)
			if eventName == "hit" then
				self:initGroupLeft()
				self:initTopLeft()
				self:playSweepDrugAction1(drug)
				self:setTimeOut(0.5, function ()
					local effect3 = xyd.Spine.new(icon.gameObject)

					effect3:setInfo(self.fxDrugExit[1], function ()
						effect3:SetLocalPosition(0, 0, 0)
						effect3:setRenderTarget(icon, -1)
						effect3:play("texiao", 1, 1, function ()
							effect3:destroy()

							if effect2 then
								effect2:destroy()
							end

							if callback then
								callback()
							end
						end)
					end)
				end)
			end
		end
	end)
end

function DungeonWindow:playDrugAction2(drug, callback)
	local icon = self.drugIcon

	self:setTimeOut(0.3, function ()
		local effect2 = xyd.Spine.new(icon.gameObject)

		effect2:setInfo(self.fxDrug[2], function ()
			effect2:SetLocalPosition(0, 0, 0)
			effect2:setRenderTarget(icon, -1)
			effect2:play("texiao", 0)
		end)
		icon:SetActive(true)

		local animation = icon:GetComponent(typeof(UnityEngine.Animation))

		animation:Play("drugIconAni")

		local event = icon:GetComponent(typeof(LuaAnimationEvent))

		function event.callback(eventName)
			if eventName == "hit" then
				self:initGroupLeft()
				self:initTopLeft()
				self:playSweepDrugAction2(drug)
				self:setTimeOut(0.5, function ()
					local effect3 = xyd.Spine.new(icon.gameObject)

					effect3:setInfo(self.fxDrugExit[1], function ()
						effect3:SetLocalPosition(0, 0, 0)
						effect3:setRenderTarget(icon, -1)
						effect3:play("texiao", 1, 1, function ()
							effect3:destroy()

							if effect2 then
								effect2:destroy()
							end

							if callback then
								callback()
							end
						end)
					end)
				end)
			end
		end
	end)
end

function DungeonWindow:playBoxAction(callback)
	local icon = self.imgBox

	icon:SetLocalPosition(0, 158, 0)
	xyd.setUISpriteAsync(icon, nil, "dungeon_box_1", function ()
		icon:MakePixelPerfect()
	end)
	icon:SetActive(false)
	self:setTimeOut(0.3, function ()
		icon:SetActive(true)

		local action = self:getTimeLineLite()

		action:Append(icon.transform:DOLocalMove(Vector3(0, 58, 0), 0.2)):AppendCallback(function ()
			icon:SetLocalScale(1.3, 0.7, 1)

			local effect2 = xyd.Spine.new(icon.gameObject)

			effect2:setInfo(self.fxEnemy[1], function ()
				effect2:SetLocalPosition(-30, -66, 0)
				effect2:setRenderTarget(icon, 1)
				effect2:play("texiao", 1, 1, function ()
					effect2:destroy()
				end)
			end)
		end):Append(icon.transform:DOScale(Vector3(1, 1, 1), 0.4)):AppendCallback(function ()
			xyd.setUISpriteAsync(icon, nil, "dungeon_box_2", function ()
				icon:MakePixelPerfect()
			end)

			local effect4 = xyd.Spine.new(icon.gameObject)

			effect4:setInfo(self.fxTreasure[1], function ()
				effect4:SetLocalPosition(0, 0, 0)
				effect4:setRenderTarget(icon, 2)
				effect4:play("texiao", 1, 1, function ()
					effect4:destroy()
					icon:SetActive(false)
				end)
			end)
			self:setTimeOut(0.2, callback)
		end)
	end)
end

function DungeonWindow:playAllDieAction()
	local effect2 = xyd.Spine.new(self.groupAllDieNode)

	effect2:setInfo(self.fxAllDie[1], function ()
		if tolua.isnull(self.window_) then
			effect2:destroy()

			return
		end

		effect2:play("texiao", 1, 1, function ()
			effect2:destroy()
		end)
	end)
end

function DungeonWindow:getTimeLineLite()
	local action = nil

	local function completeCallback()
		for i = 1, #self.actions do
			if self.actions[i] == action then
				table.remove(self.actions, i)

				break
			end
		end
	end

	action = self:getSequence(completeCallback)

	action:SetAutoKill(true)
	table.insert(self.actions, action)

	return action
end

function DungeonWindow:willClose()
	DungeonWindow.super.willClose(self)

	if self.effectChris1_ then
		self.effectChris1_:destroy()
	end

	if #self.timeKey_ > 0 then
		for i = 1, #self.timeKey_ do
			local key = self.timeKey_[i]

			XYDCo.StopWait(key)
		end

		self.timeKey_ = {}
	end

	if #self.actions > 0 then
		for i = 1, #self.actions do
			local action = self.actions[i]

			action:Pause()
			action:Kill()
		end

		self.actions = {}
	end

	local effectNames = {
		"baoxiang_dakai",
		"direnshijian_diyan",
		"fantuan_bhg_bai",
		"fantuan_bhg_lv",
		"fantuan_bhg_hong",
		"fantuan_ui",
		"gongju_ui",
		"fantuan_tuichang",
		"gongju_tuichang",
		"fx_ui_zhenwangyan",
		"fx_ui_ruchang",
		"fx_ui_shoudong",
		"shangren_yan",
		"shangren_tuichang",
		"shuye",
		"pingdiguo",
		"shangren2",
		"moshuxuetu",
		"sdsl",
		"sdyh",
		"hanlingdi_hurt03"
	}

	if self.hero_appear_effect then
		self.hero_appear_effect:destroy()

		self.hero_appear_effect = nil
	end
end

function DungeonWindow:initPrivilegeCard()
	UIEventListener.Get(self.privilegeCardBg.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("privilege_card_activity_pop_up_window", {
			giftid = xyd.GIFTBAG_ID.PRIVILEGE_CARD_DUNGEON
		})
	end)

	self:updatePrivilegeCard()
end

function DungeonWindow:updatePrivilegeCard()
	local privilegeData = xyd.models.activity:getActivity(xyd.ActivityID.PRIVILEGE_CARD)

	if privilegeData and privilegeData:isHide() == false then
		self.privilegeCardCon:SetActive(true)
		self.top_left_widget:SetAnchor(self.window_, 0, -1, 1, -112, 0, -1, 1, -110)
	else
		self.privilegeCardCon:SetActive(false)
		self.top_left_widget:SetAnchor(self.window_, 0, -2, 1, -4, 0, 0, 1, -1)

		return
	end

	if privilegeData:getStateById(xyd.GIFTBAG_ID.PRIVILEGE_CARD_DUNGEON) == true then
		xyd.setUITextureByNameAsync(self.privilegeCardBg, "tips_btn_color_privilege_card", true)
		xyd.setUITextureByNameAsync(self.privilegeCardIcon, "tips_show_grey2_privilege_card", true)

		self.privilegeCardLabel.text = __("PRIVILEGE_CARD_ACTIVE")
		self.privilegeCardLabel.color = Color.New2(3506416383.0)
		self.privilegeCardLabel.effectColor = Color.New2(960513791)
	else
		xyd.setUITextureByNameAsync(self.privilegeCardBg, "tips_btn_grey_privilege_card", true)
		xyd.setUITextureByNameAsync(self.privilegeCardIcon, "tips_show_grey1_privilege_card", true)

		self.privilegeCardLabel.text = __("PRIVILEGE_CARD_IN_ACTIVE")
		self.privilegeCardLabel.color = Color.New2(4160157439.0)
		self.privilegeCardLabel.effectColor = Color.New2(1179010815)
	end
end

return DungeonWindow
