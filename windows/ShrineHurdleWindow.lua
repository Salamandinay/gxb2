local ShrineHurdleWindow = class("ShrineHurdleWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local PngNum = import("app.components.PngNum")
local FLOORTYPE = {
	REST = 4,
	SHOP = 3,
	AWARD = 2,
	BOSS = 5,
	FIGHT = 1
}

function ShrineHurdleWindow:ctor(name, params)
	ShrineHurdleWindow.super.ctor(self, name, params)

	self.route_id_ = xyd.models.shrineHurdleModel:getRouteID()
end

function ShrineHurdleWindow:initWindow()
	self:getUIComponent()
	self:initTopGroup()
	self:updateStageInfo()

	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()
	local not_auto_open = nil

	if guideIndex == 1 then
		not_auto_open = true
	else
		not_auto_open = false
	end

	self:updateAutonBtn()
	self:updateShowState(not_auto_open)
	self:checkGuide()
	self:register()
end

function ShrineHurdleWindow:initTopGroup()
	if not self.windowTop_ then
		self.windowTop_ = WindowTop.new(self.window_, self.name_, 90)
	end

	self.resItemLabel_.text = xyd.models.shrineHurdleModel:getGold()

	self:timerCallback()
end

function ShrineHurdleWindow:timerCallback()
	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	function self.playAni2_()
		self.sequence2_ = self:getSequence()

		self.sequence2_:Insert(0, self.lightImg_.transform:DOLocalMove(Vector3(0, 190, 0), 1, false))
		self.sequence2_:Insert(1, self.lightImg_.transform:DOLocalMove(Vector3(0, 170, 0), 1, false))
		self.sequence2_:AppendCallback(function ()
			self.playAni1_()
		end)
	end

	function self.playAni1_()
		self.sequence1_ = self:getSequence()

		self.sequence1_:Insert(0, self.lightImg_.transform:DOLocalMove(Vector3(0, 190, 0), 1, false))
		self.sequence1_:Insert(1, self.lightImg_.transform:DOLocalMove(Vector3(0, 170, 0), 1, false))
		self.sequence1_:AppendCallback(function ()
			self.playAni2_()
		end)
	end

	self.playAni1_()
end

function ShrineHurdleWindow:updateStageInfo()
	local score = xyd.models.shrineHurdleModel:getScore()
	self.labelPoint_.text = __("SHRINE_HURDLE_TEXT10", "[c][d15b8b]" .. score .. "[-][/c]")
	local floor_id, floor_index, floorType = xyd.models.shrineHurdleModel:getFloorInfo()
	self.floor_id = floor_id
	local ids = xyd.tables.shrineHurdleTable:getIDs()

	if xyd.models.shrineHurdleModel:checkInGuide() then
		ids = {
			1,
			2,
			3,
			4,
			5
		}
	end

	self.labeStage_.text = self.floor_id .. "/" .. #ids
	local route_id_ = xyd.models.shrineHurdleModel:getRouteID()
	local count = xyd.models.shrineHurdleModel:getCount()
	count = math.fmod(count - 1, 3) + 1
	local enviroments = xyd.tables.shrineHurdleRouteTable:getEnviroment(route_id_, count)

	if xyd.models.shrineHurdleModel:checkInGuide() then
		enviroments = {
			500000,
			500001
		}
	end

	self.labelName_.text = xyd.tables.shrineHurdleRouteTextTable:getTitle(enviroments[1])

	if not self.numLabel then
		self.numLabel = PngNum.new(self.labelLevel_)

		self.numLabel:setInfo({
			scale = 0.5306122448979592,
			iconName = "shrine",
			num = xyd.models.shrineHurdleModel:getDiffNum()
		})
	end

	self.labelLevelTips_.text = __("SHRINE_HURDLE_TEXT03")
end

function ShrineHurdleWindow:showGoldChange(changeNum)
	if changeNum > 0 then
		self.resItemChangeLabel_.color = Color.New2(915996927)
		self.resItemChangeLabel_.text = "+ " .. changeNum
	else
		self.resItemChangeLabel_.color = Color.New2(2751463679.0)
		self.resItemChangeLabel_.text = changeNum
	end

	self.resItemLabel_.text = xyd.models.shrineHurdleModel:getGold()

	self.resItemChangeLabel_:SetActive(true)

	local function setter(value)
		self.resItemChangeLabel_.alpha = value
	end

	local seq = self:getSequence(function ()
		if self.window_ and not tolua.isnull(self.window_) then
			self.resItemChangeLabel_:SetActive(false)
		end
	end)

	seq:AppendInterval(3)
	seq:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0, 0.5))
end

function ShrineHurdleWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.leftTopPart_ = winTrans:NodeByName("leftTopPart").gameObject
	self.helpBtn_ = self.leftTopPart_:NodeByName("helpBtn").gameObject
	self.recordBtn_ = self.leftTopPart_:NodeByName("recordBtn").gameObject
	self.partnerBtn_ = self.leftTopPart_:NodeByName("partnerBtn").gameObject
	self.labelPoint_ = self.leftTopPart_:ComponentByName("topbg/labelPoint", typeof(UILabel))
	self.labelName_ = winTrans:ComponentByName("labelName", typeof(UILabel))
	self.labeStage_ = winTrans:ComponentByName("labeStage", typeof(UILabel))
	self.levelPart_ = winTrans:NodeByName("levelPart").gameObject
	self.labelLevel_ = winTrans:NodeByName("levelPart/labelLevel").gameObject
	self.labelLevelTips_ = winTrans:ComponentByName("levelPart/labelLevelTips", typeof(UILabel))
	self.outBtn_ = winTrans:NodeByName("outBtn").gameObject
	self.autoBtn_ = winTrans:NodeByName("autoBtn").gameObject
	self.autoLabel_ = winTrans:ComponentByName("autoBtnLabel", typeof(UILabel))
	self.autoLabel_.text = __("SHRINE_HURDLE_AUTO_TEXT01")
	self.autoMask_ = winTrans:NodeByName("autoMask").gameObject
	self.contentPart_ = winTrans:NodeByName("contentPart").gameObject
	self.bgImg1_ = self.contentPart_:NodeByName("bgImg1").gameObject
	self.bgImg2_ = winTrans:ComponentByName("bgImg2", typeof(UIWidget))
	self.leftDoor2_ = self.bgImg2_:NodeByName("leftDoor").gameObject
	self.rightDoor2_ = self.bgImg2_:NodeByName("rightDoor").gameObject
	self.leftDoor_ = self.contentPart_:NodeByName("leftDoor").gameObject
	self.rightDoor_ = self.contentPart_:NodeByName("rightDoor").gameObject
	self.effectRoot_ = self.contentPart_:NodeByName("effectRoot").gameObject
	self.shopImg_ = self.contentPart_:NodeByName("shopImg").gameObject
	self.partnerRoot_ = self.contentPart_:NodeByName("partnerRoot").gameObject
	self.patnerClickBox_ = self.contentPart_:NodeByName("patnerClickBox").gameObject
	self.battleBtn_ = self.contentPart_:NodeByName("battleBtn").gameObject
	self.battleWidgt_ = self.battleBtn_:GetComponent(typeof(UIWidget))
	self.goNextImg1_ = self.contentPart_:NodeByName("goNextImg1").gameObject
	self.goNextImg2_ = self.contentPart_:NodeByName("goNextImg2").gameObject
	self.lightImg_ = self.contentPart_:ComponentByName("lightImg", typeof(UISprite))
	self.effectRoot2_ = self.contentPart_:NodeByName("effectRoot2").gameObject
	self.guideNextRoot_ = self.contentPart_:NodeByName("guideNextRoot").gameObject
	self.resItem_ = winTrans:NodeByName("res_item").gameObject
	self.resItemLabel_ = winTrans:ComponentByName("res_item/res_num_label", typeof(UILabel))
	self.resItemChangeLabel_ = winTrans:ComponentByName("res_item/changeLabel", typeof(UILabel))

	xyd.setUISpriteAsync(self.battleBtn_:GetComponent(typeof(UISprite)), nil, "shrine_hurdle_battle_" .. xyd.Global.lang, nil, , true)
end

function ShrineHurdleWindow:ShowNextClickBox()
	self.guideNextRoot_:SetActive(true)
end

function ShrineHurdleWindow:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		if self.isInAni_ then
			return
		end

		xyd.WindowManager.get():openWindow("help_window", {
			key = "SHRINE_HURDLE_HELP"
		})
	end

	UIEventListener.Get(self.battleBtn_).onClick = handler(self, self.onClickFight)
	UIEventListener.Get(self.shopImg_).onClick = handler(self, self.onClickShowImg)

	self.eventProxy_:addEventListener(xyd.event.SHRINE_HURDLE_CHALLENGE, handler(self, self.onChallenge))
	self.eventProxy_:addEventListener(xyd.event.SHRINE_HURDLE_NEXT_FLOOR, handler(self, self.onNextFloorEvent))
	self.eventProxy_:addEventListener(xyd.event.SHRINE_HURDLE_END, handler(self, self.onEndHurdle))
	self.eventProxy_:addEventListener(xyd.event.SHRINE_HURDLE_GET_RECORDS, handler(self, self.onGetRecords))

	UIEventListener.Get(self.recordBtn_).onClick = function ()
		xyd.models.shrineHurdleModel:reqShineHurdleRecords()
	end

	UIEventListener.Get(self.resItem_).onClick = function ()
		local params = {
			notShowGetWayBtn = true,
			showGetWays = false,
			itemID = 324,
			wndType = xyd.ItemTipsWndType.NORMAL
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.leftDoor_).onClick = function ()
		self:goNext(1)
	end

	UIEventListener.Get(self.rightDoor_).onClick = function ()
		self:goNext(2)
	end

	UIEventListener.Get(self.guideNextRoot_).onClick = handler(self, self.guideGoNext)

	UIEventListener.Get(self.outBtn_).onClick = function ()
		if self.isInAni_ then
			return
		end

		xyd.WindowManager.get():openWindow("shrine_hurdle_info_window", {})
	end

	UIEventListener.Get(self.patnerClickBox_).onClick = function ()
		if self.isInAni_ then
			return
		end

		local table_id = self.extraData_.battle_id
		local battle_type = 0

		if self.floorType == FLOORTYPE.FIGHT then
			battle_type = 1
		elseif self.floorType == FLOORTYPE.BOSS then
			battle_type = 2
		end

		xyd.WindowManager.get():openWindow("academy_assessment_enemy_detail_window", {
			battle_type = battle_type,
			table_id = table_id
		})
	end

	UIEventListener.Get(self.partnerBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("shrine_hurdle_select_partner_window", {
			is_show = true
		})
	end

	UIEventListener.Get(self.autoBtn_).onClick = handler(self, self.onClickAutoBtn)
end

function ShrineHurdleWindow:onGetRecords(event)
	local data = xyd.decodeProtoBuf(event.data)

	xyd.WindowManager.get():openWindow("shrine_hurdle_record_window", {
		records = data.records
	})
end

function ShrineHurdleWindow:onEndHurdle()
	self:close()
end

function ShrineHurdleWindow:onNextFloorEvent(event)
	local index = event.data.floor_index

	self:onNextFloor(index)
end

function ShrineHurdleWindow:onNextFloor(index)
	local leftY = self.leftTopPart_.transform.localPosition.y
	local leftX = self.leftTopPart_.transform.localPosition.x
	local rightY = self.levelPart_.transform.localPosition.y
	local rightX = self.levelPart_.transform.localPosition.x
	local outY = self.outBtn_.transform.localPosition.y
	local outX = self.outBtn_.transform.localPosition.x
	self.isInAni_ = true
	self.bgImg2_.alpha = 1
	self.bgImg2_.depth = -4

	self.bgImg2_.transform:SetLocalScale(1, 1, 1)
	self.bgImg2_.transform:SetLocalPosition(0, 200, 0)

	self.partnerBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

	self.leftDoor2_:SetActive(true)
	self.rightDoor2_:SetActive(true)

	self.battleWidgt_.alpha = 0

	xyd.playSoundByTableId(2071)

	local sequence = self:getSequence(function ()
		self:updateStageInfo()
		self:updateShowState(true)

		self.bgImg2_.depth = 7

		self.leftDoor2_:SetActive(false)
		self.rightDoor2_:SetActive(false)

		local function setter2(alpha)
			self.bgImg2_.alpha = alpha
		end

		local sequence2 = self:getSequence(function ()
			self.isInAni_ = false

			if self.goNextEffect1_ then
				self.goNextEffect1_:setAlpha(1)
				self.goNextEffect1_:SetLocalScale(1, 1, 1)
			end

			if self.goNextEffect2_ then
				self.goNextEffect2_:setAlpha(1)
				self.goNextEffect2_:SetLocalScale(1, 1, 1)
			end

			self.lightImg_.alpha = 1

			self.labeStage_.gameObject:SetActive(true)
			self.labelName_.gameObject:SetActive(true)

			self.battleWidgt_.alpha = 1

			self:updateShowState(false)
			self:autoNext(1, true)
			self:checkGuide()
			self.numLabel:Reposition()
			self:waitForFrame(10, function ()
				self.partnerBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			end)
		end)

		sequence2:Insert(0, self.bgImg2_.transform:DOScale(Vector3(6, 10, 1), 1))
		sequence2:Insert(0.5, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 1, 0, 1.5))
		sequence2:Insert(0, self.bgImg2_.transform:DOLocalMove(Vector3(0, -3000, 0), 1))
		sequence2:Insert(0, self.contentPart_.transform:DOScale(Vector3(1, 1, 1), 1))
		sequence2:Insert(0, self.contentPart_.transform:DOLocalMove(Vector3(0, 0, 0), 1))
		sequence2:Insert(1, self.leftTopPart_.transform:DOLocalMove(Vector3(leftX, leftY, 0), 0.4))
		sequence2:Insert(1, self.levelPart_.transform:DOLocalMove(Vector3(rightX, rightY, 0), 0.4))
		sequence2:Insert(1, self.outBtn_.transform:DOLocalMove(Vector3(outX, outY, 0), 0.4))
	end)

	self:waitForTime(1, function ()
		self.contentPart_.transform:SetLocalScale(0.6, 0.6, 1)
		self.contentPart_.transform:Y(200)
		self.leftDoor_.transform:X(13)
		self.rightDoor_.transform:X(-13)
	end)
	self.labeStage_.gameObject:SetActive(false)
	self.labelName_.gameObject:SetActive(false)
	sequence:Insert(0, self.leftTopPart_.transform:DOLocalMove(Vector3(-1080, leftY, 0), 0.8))
	sequence:Insert(0, self.levelPart_.transform:DOLocalMove(Vector3(1080, rightY, 0), 0.8))
	sequence:Insert(0, self.outBtn_.transform:DOLocalMove(Vector3(-1080, outY, 0), 0.8))

	local function setter1(alpha)
		if self.goNextEffect1_ then
			self.goNextEffect1_:setAlpha(alpha)
		end

		if self.goNextEffect2_ then
			self.goNextEffect2_:setAlpha(alpha)
		end

		self.lightImg_.alpha = alpha
		local scale = 1.5 - 0.5 * alpha

		if self["goNextEffect" .. index .. "_"] then
			self["goNextEffect" .. index .. "_"]:SetLocalScale(scale, scale, 1)
		end
	end

	sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 1, 0, 0.6))
	sequence:Insert(0.6, self.leftDoor_.transform:DOLocalMove(Vector3(-130, 261, 0), 0.4))
	sequence:Insert(0.6, self.rightDoor_.transform:DOLocalMove(Vector3(130, 261, 0), 0.4))
end

function ShrineHurdleWindow:goNext(index)
	if self.isInAni_ then
		return
	end

	if not self.extraData_.can_next or tonumber(self.extraData_.can_next) ~= 1 then
		return
	end

	local nextId = xyd.tables.shrineHurdleTable:getNextId(self.floor_id)
	local nextHurdle = xyd.tables.shrineHurdleTable:getHurdle(nextId)

	if nextHurdle and #nextHurdle <= 1 then
		index = 1
	end

	if #nextHurdle > 1 then
		local value = xyd.db.misc:getValue("shrine_hurdle_time_stamp")

		if not value then
			local nextType = nextHurdle[index]

			if nextType == 5 then
				nextType = 1
			end

			local tips = __("SHRINE_HURDLE_SELECT" .. nextType)

			xyd.openWindow("gamble_tips_window", {
				type = "shrine_hurdle",
				text = tips,
				labelNeverText = __("PRAISE_BTN_1"),
				callback = function ()
					xyd.models.shrineHurdleModel:nextFloor(index)
				end
			})
		else
			xyd.models.shrineHurdleModel:nextFloor(index)
		end
	else
		xyd.models.shrineHurdleModel:nextFloor(index)
	end
end

function ShrineHurdleWindow:onClickFight()
	if self.isInAni_ then
		return
	end

	local fightParams = {
		showSkip = true,
		isSkip = xyd.models.shrineHurdleModel:isSkipReport(),
		battleType = xyd.BattleType.SHRINE_HURDLE,
		skipState = xyd.models.shrineHurdleModel:isSkipReport(),
		btnSkipCallback = function (flag)
			xyd.models.shrineHurdleModel:setSkipReport(flag)
		end
	}

	if self.floorType == 5 then
		fightParams.showSkip = false
	end

	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

	if guideIndex then
		fightParams.showSkip = false

		function fightParams.callback()
			self:checkGuide()
		end
	end

	xyd.WindowManager.get():openWindow("battle_formation_trial_window", fightParams)
end

function ShrineHurdleWindow:onChallenge(event)
	local data = xyd.decodeProtoBuf(event.data)

	if self.floorType == FLOORTYPE.FIGHT or self.floorType == FLOORTYPE.BOSS then
		local battle_report = data.battle_result.battle_report

		if battle_report.isWin and battle_report.isWin == 1 or self.floorType == FLOORTYPE.BOSS then
			self.battleBtn_:SetActive(false)
			self.patnerClickBox_:SetActive(false)
		end
	elseif self.floorType ~= FLOORTYPE.REST and self.floorType == FLOORTYPE.AWARD then
		-- Nothing
	end

	self.extraData_ = xyd.models.shrineHurdleModel:getExtra()

	if self.extraData_.can_next and tonumber(self.extraData_.can_next) == 1 then
		self:showGoNextEffect()
	end

	local floor_id, floor_index, floorType = xyd.models.shrineHurdleModel:getFloorInfo()

	if floorType == FLOORTYPE.AWARD then
		self:updateAwardInfo(1, true)
	elseif floorType == FLOORTYPE.SHOP then
		self:updateAwardInfo(2, true)
	elseif floorType == FLOORTYPE.REST then
		if not self.restEffect_ then
			self.restEffect_ = xyd.Spine.new(self.effectRoot2_)

			self.restEffect_:setInfo("hanlingdi_hurt03", function ()
				self.restEffect_:SetActive(true)
				self.restEffect_:play("texiao", 1, 1)
			end)
		else
			self.restEffect_:SetActive(true)
			self.restEffect_:play("texiao", 1, 1)
		end

		self:waitForTime(0.6, function ()
			self.restEffect_:SetActive(false)
		end)
		self:updateAwardInfo(3, true)
	end

	self:updateStageInfo()
end

function ShrineHurdleWindow:onGuideUpdate(not_auto_open)
	self.extraData_ = xyd.models.shrineHurdleModel:getExtra()

	if self.extraData_.can_next and tonumber(self.extraData_.can_next) == 1 then
		self:showGoNextEffect()
	end

	local floor_id, floor_index, floorType = xyd.models.shrineHurdleModel:getFloorInfo()

	if floorType == FLOORTYPE.AWARD then
		self:updateAwardInfo(1, not_auto_open)
	elseif floorType == FLOORTYPE.SHOP then
		self:updateAwardInfo(2, not_auto_open)
	elseif floorType == FLOORTYPE.REST then
		if not self.restEffect_ then
			self.restEffect_ = xyd.Spine.new(self.effectRoot2_)

			self.restEffect_:setInfo("hanlingdi_hurt03", function ()
				self.restEffect_:SetActive(true)
				self.restEffect_:play("texiao", 1, 1)
			end)
		else
			self.restEffect_:SetActive(true)
			self.restEffect_:play("texiao", 1, 1)
		end

		self:waitForTime(0.6, function ()
			self.restEffect_:SetActive(false)
		end)
		self:updateAwardInfo(3, not_auto_open)
	end

	self:updateStageInfo()
	self:checkGuide()
end

function ShrineHurdleWindow:onClickShowImg()
	if self.isInAni_ then
		return
	end

	xyd.WindowManager.get():openWindow("shrine_hurdle_choose_buff_window", {
		window_type = self.floorType
	})
end

function ShrineHurdleWindow:updateShowState(noOpen)
	local floor_id, floor_index, floorType = xyd.models.shrineHurdleModel:getFloorInfo()
	self.floor_id = floor_id
	self.floor_index = floor_index
	self.floorType = floorType
	self.extraData_ = xyd.models.shrineHurdleModel:getExtra()

	if self.floorType == FLOORTYPE.FIGHT then
		self:updateFightInfo(1)
	elseif self.floorType == FLOORTYPE.AWARD then
		self:updateAwardInfo(1, noOpen)
	elseif self.floorType == FLOORTYPE.SHOP then
		self:updateAwardInfo(2, noOpen)
	elseif self.floorType == FLOORTYPE.REST then
		self:updateAwardInfo(3, noOpen)
	elseif self.floorType == FLOORTYPE.BOSS then
		self:updateFightInfo(2)
	end
end

function ShrineHurdleWindow:hideGoNextEffect()
	self.goNextImg2_:SetActive(false)
	self.goNextImg1_:SetActive(false)
	self.lightImg_.gameObject:SetActive(false)
end

function ShrineHurdleWindow:showGoNextEffect()
	self.lightImg_.gameObject:SetActive(true)

	local nextId = xyd.tables.shrineHurdleTable:getNextId(self.floor_id)
	local nextHurdle = xyd.tables.shrineHurdleTable:getHurdle(nextId)
	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()
	local showType1, showType2 = nil
	showType1 = nextHurdle[1]
	showType2 = nextHurdle[2]

	if guideIndex and guideIndex == 3 then
		showType1 = 1
		showType2 = nil
		nextHurdle = {
			showType1
		}
	elseif guideIndex and guideIndex == 5 then
		showType1 = 3
		showType2 = nil
		nextHurdle = {
			showType1
		}
	elseif guideIndex and guideIndex == 6 then
		showType1 = 4
		showType2 = nil
		nextHurdle = {
			showType1
		}
	elseif guideIndex and guideIndex == 8 then
		showType1 = 1
		showType2 = nil
		nextHurdle = {
			showType1
		}
	end

	if showType1 == 5 then
		showType1 = 1
	end

	if showType2 == 5 then
		showType2 = 1
	end

	local indexToName = {
		"shrine_zhandou",
		"shrine_jiangli",
		"shrine_shangdian",
		"shrine_huifu"
	}

	if self.goNextEffect1_ then
		self.goNextEffect1_:destroy()

		self.goNextEffect1_ = nil
	end

	if self.goNextEffect2_ then
		self.goNextEffect2_:destroy()

		self.goNextEffect2_ = nil
	end

	if nextHurdle and #nextHurdle >= 2 then
		self.goNextImg2_:SetActive(true)
		self.goNextImg1_:SetActive(true)

		self.goNextEffect1_ = xyd.Spine.new(self.goNextImg1_)

		self.goNextEffect1_:setInfo(indexToName[showType1], function ()
			self.goNextEffect1_:play("texiao01", 0)
		end)

		self.goNextEffect2_ = xyd.Spine.new(self.goNextImg2_)

		self.goNextEffect2_:setInfo(indexToName[showType2], function ()
			self.goNextEffect2_:play("texiao01", 0)
		end)
		self.goNextImg1_.transform:X(-70)
		self.goNextImg2_.transform:X(70)
	else
		self.goNextImg2_:SetActive(false)
		self.goNextImg1_:SetActive(true)
		self.goNextImg1_.transform:X(0)

		if self.goNextEffect1_ then
			self.goNextEffect1_:destroy()

			self.goNextEffect1_ = nil
		end

		self.goNextEffect1_ = xyd.Spine.new(self.goNextImg1_)

		self.goNextEffect1_:setInfo(indexToName[showType1], function ()
			self.goNextEffect1_:play("texiao01", 0)
		end)
	end
end

function ShrineHurdleWindow:updateFightInfo(type)
	self.shopImg_:SetActive(false)

	local useTable = nil

	if type == 1 then
		useTable = xyd.tables.shrineHurdleBattleTable
	else
		useTable = xyd.tables.shrineHurdleBossTable
	end

	if self.extraData_.can_next and tonumber(self.extraData_.can_next) == 1 then
		if self.partnerSpine_ then
			local table_id = self.extraData_.battle_id
			local show_model_id = useTable:getModelID(table_id)
			local name = xyd.tables.modelTable:getModelName(show_model_id)

			if self.partnerSpine_:getName() == name then
				return
			end

			self.partnerSpine_:destroy()

			self.partnerSpine_ = nil
		end

		self.patnerClickBox_:SetActive(false)
		self.battleBtn_:SetActive(false)
		self:showGoNextEffect()
	else
		self:hideGoNextEffect()
		self.battleBtn_:SetActive(true)

		local table_id = self.extraData_.battle_id
		local show_model_id = useTable:getModelID(table_id)
		local scale = xyd.tables.modelTable:getScale(show_model_id)
		local name = xyd.tables.modelTable:getModelName(show_model_id)

		if self.partnerSpine_ then
			if self.partnerSpine_:getName() == name then
				return
			end

			self.partnerSpine_:destroy()

			self.partnerSpine_ = nil
		end

		self.patnerClickBox_:SetActive(true)

		local sp = xyd.Spine.new(self.partnerRoot_)

		sp:setInfo(name, function ()
			sp:setToSetupPose()

			if tolua.isnull(self.window_) then
				sp:destroy()

				return
			end

			sp:SetLocalPosition(0, 0, 0)
			sp:SetLocalScale(scale, scale, 1)
			sp:play("idle", 0)
			sp:startAtFrame(0)
		end)

		self.partnerSpine_ = sp
	end

	if type == 2 then
		self.autoBtn_:SetActive(false)
		self.autoLabel_.gameObject:SetActive(false)
	end
end

function ShrineHurdleWindow:showPartnerDead()
	if self.partnerSpine_ then
		self.partnerSpine_:play("dead", 1, 1, function ()
			self.partnerSpine_:destroy()

			self.partnerSpine_ = nil
		end)
	end
end

function ShrineHurdleWindow:updateAwardInfo(type, noOpen)
	self.shopImg_:SetActive(true)
	self.battleBtn_:SetActive(false)
	self.patnerClickBox_:SetActive(false)

	if self.partnerSpine_ then
		self.partnerSpine_:destroy()

		self.partnerSpine_ = nil
	end

	if self.extraData_.can_next and tonumber(self.extraData_.can_next) == 1 then
		if type == 1 or type == 3 then
			self.shopImg_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		else
			self.shopImg_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			if not noOpen then
				xyd.WindowManager.get():openWindow("shrine_hurdle_choose_buff_window", {
					window_type = self.floorType
				})
			end
		end

		self:showGoNextEffect()
	else
		self.shopImg_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

		self:hideGoNextEffect()

		if not noOpen then
			xyd.WindowManager.get():openWindow("shrine_hurdle_choose_buff_window", {
				window_type = self.floorType
			})
		end
	end
end

function ShrineHurdleWindow:checkGuide()
	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

	if guideIndex and guideIndex > 0 then
		self.autoBtn_:SetActive(false)
		self.autoLabel_.gameObject:SetActive(false)
	end

	if guideIndex and guideIndex == 3 then
		self:ShowNextClickBox()
		xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
			guide_type = xyd.CommonTriggerGuideType.SHRINE_HURDLE_3
		})
	elseif guideIndex and guideIndex == 4 then
		xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
			guide_type = xyd.CommonTriggerGuideType.SHRINE_HURDLE_4
		})
	elseif guideIndex and guideIndex == 5 then
		self:ShowNextClickBox()
		xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
			guide_type = xyd.CommonTriggerGuideType.SHRINE_HURDLE_3
		})
	elseif guideIndex and guideIndex == 8 then
		self:ShowNextClickBox()
		xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
			guide_type = xyd.CommonTriggerGuideType.SHRINE_HURDLE_3
		})
	elseif guideIndex and guideIndex == 9 then
		self:ShowNextClickBox()
		xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
			guide_type = xyd.CommonTriggerGuideType.SHRINE_HURDLE_7
		})
	end
end

function ShrineHurdleWindow:guideGoNext()
	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

	if guideIndex and guideIndex == 3 then
		xyd.models.shrineHurdleModel:setFlag(nil, 3)
		self:onNextFloor(1)
	elseif guideIndex and guideIndex == 5 then
		xyd.models.shrineHurdleModel:setFlag(nil, 5)
		self:onNextFloor(1)
	elseif guideIndex and guideIndex == 6 then
		xyd.models.shrineHurdleModel:setFlag(nil, 6)
		self:onNextFloor(1)
	elseif guideIndex and guideIndex == 8 then
		xyd.models.shrineHurdleModel:setFlag(nil, 8)
		self:onNextFloor(1)
	end

	if guideIndex and guideIndex > 0 then
		self.autoBtn_:SetActive(false)
		self.autoLabel_.gameObject:SetActive(false)
	end
end

function ShrineHurdleWindow:autoNext(wait_time, by_go_next)
	__TRACE(" wait_time    ==========", wait_time)

	if not wait_time then
		self:autoStepFunc(by_go_next)
	else
		self:waitForTime(wait_time, function ()
			self:autoStepFunc(by_go_next)
		end)
	end
end

function ShrineHurdleWindow:autoStepFunc(by_go_next)
	local autoInfo = xyd.models.shrineHurdleModel:getAutoInfo()

	if autoInfo.is_auto ~= 1 then
		return
	end

	if not by_go_next and self.extraData_.can_next and tonumber(self.extraData_.can_next) == 1 then
		local nextId = xyd.tables.shrineHurdleTable:getNextId(self.floor_id)
		local nextHurdle = xyd.tables.shrineHurdleTable:getHurdle(nextId)

		if nextHurdle and #nextHurdle <= 1 then
			xyd.models.shrineHurdleModel:nextFloor(1)
		else
			local nextType1 = nextHurdle[1]
			local nextType2 = nextHurdle[2]
			local rate1 = 0
			local rate2 = 0

			if nextType1 == 1 then
				rate1 = rate1 + 1
			elseif nextType1 == 2 then
				rate1 = rate1 + 1000
			elseif nextType1 == 3 and autoInfo.go_shop == 1 then
				rate1 = rate1 + 10
			elseif nextType1 == 4 and autoInfo.reply == 1 then
				rate1 = rate1 + 100
			end

			if nextType2 == 1 then
				rate2 = rate2 + 1
			elseif nextType2 == 2 then
				rate2 = rate2 + 1000
			elseif nextType2 == 3 and autoInfo.go_shop == 1 then
				rate2 = rate2 + 10
			elseif nextType2 == 4 and autoInfo.reply == 1 then
				rate2 = rate2 + 100
			end

			local goIndex = 1

			if rate1 < rate2 then
				goIndex = 2
			end

			xyd.models.shrineHurdleModel:nextFloor(goIndex)
		end

		return
	end

	if self.floorType == FLOORTYPE.FIGHT then
		local partnerList, pet = xyd.models.shrineHurdleModel:getAutoTeam()
		local partnerParams = {}

		for pos, partner_id in pairs(partnerList) do
			if tonumber(partner_id) and tonumber(partner_id) > 0 then
				local partnerInfo = xyd.models.shrineHurdleModel:getPartner(partner_id)
				local hp = partnerInfo.status.hp

				if not hp or hp > 0 then
					table.insert(partnerParams, {
						partner_id = tonumber(partner_id),
						pos = pos
					})
				end
			end
		end

		if #partnerParams <= 0 then
			xyd.models.shrineHurdleModel:setAutoInfo(0)
		else
			xyd.models.shrineHurdleModel:challengeFight(partnerParams, pet)
		end
	elseif self.floorType == FLOORTYPE.AWARD and not by_go_next then
		xyd.WindowManager.get():openWindow("shrine_hurdle_choose_buff_window", {
			window_type = self.floorType
		})
	elseif self.floorType == FLOORTYPE.SHOP then
		if by_go_next and autoInfo.stop_shop == 1 then
			xyd.models.shrineHurdleModel:setAutoInfo(0)
		end
	elseif self.floorType == FLOORTYPE.REST and not by_go_next then
		xyd.WindowManager.get():openWindow("shrine_hurdle_choose_buff_window", {
			window_type = self.floorType
		})
	elseif self.floorType == FLOORTYPE.BOSS then
		xyd.models.shrineHurdleModel:setAutoInfo(0)
	end
end

function ShrineHurdleWindow:updateAutonBtn()
	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	local function setter1(value)
		self.autoBtn_.transform.localEulerAngles = Vector3(0, 0, value)
	end

	function self.playAni2_()
		local autoInfo = xyd.models.shrineHurdleModel:getAutoInfo()

		if autoInfo.is_auto ~= 1 then
			self.autoMask_:SetActive(false)

			return
		end

		self.autoMask_:SetActive(true)

		if not self.sequence2_ then
			self.sequence2_ = self:getSequence()

			self.sequence2_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 360, 0.8):SetEase(DG.Tweening.Ease.Linear))
			self.sequence2_:AppendCallback(function ()
				self.playAni1_()
			end)
			self.sequence2_:SetAutoKill(false)
		else
			self.sequence2_:Restart()
		end
	end

	function self.playAni1_()
		local autoInfo = xyd.models.shrineHurdleModel:getAutoInfo()

		if autoInfo.is_auto ~= 1 then
			self.autoMask_:SetActive(false)

			return
		end

		self.autoMask_:SetActive(true)

		if not self.sequence1_ then
			self.sequence1_ = self:getSequence()

			self.sequence1_:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 360, 0.8):SetEase(DG.Tweening.Ease.Linear))
			self.sequence1_:AppendCallback(function ()
				self.playAni2_()
			end)
			self.sequence1_:SetAutoKill(false)
		else
			self.sequence1_:Restart()
		end
	end

	self.playAni1_()
end

function ShrineHurdleWindow:onClickAutoBtn()
	local autoInfo = xyd.models.shrineHurdleModel:getAutoInfo()

	if autoInfo.is_auto == 1 then
		xyd.models.shrineHurdleModel:setAutoInfo(0)
	else
		xyd.WindowManager.get():openWindow("shrine_hurdle_auto_setting_window", {})
	end
end

return ShrineHurdleWindow
