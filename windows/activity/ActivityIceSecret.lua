local BigAwardNum = 13
local ActivityIceSecret = class("ActivityIceSecret", import(".ActivityContent"))
local ActivityIceSecretItem = class("ActivityIceSecretItem", import("app.components.CopyComponent"))
local cjson = require("cjson")
local startIceList = {
	9,
	16,
	22,
	16,
	9,
	10,
	14,
	20,
	14,
	10,
	11,
	16,
	18,
	16,
	11,
	12,
	18,
	20,
	18,
	12,
	13,
	20,
	22,
	20,
	13
}

function ActivityIceSecret:ctor(parentGO, params, parent)
	self.iceIconList_ = {}

	ActivityIceSecret.super.ctor(self, parentGO, params, parent)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_ICE_SECRET, function ()
		self.activityData.isTouched = true
	end)
	xyd.models.redMark:setMark(xyd.RedMarkType.ICE_SECRET, false)
end

function ActivityIceSecret:getPrefabPath()
	return "Prefabs/Windows/activity/ice_secret_content"
end

function ActivityIceSecret:initUI()
	ActivityIceSecret.super.initUI(self)
	self:getActivityData()
	self:getComponent()

	local height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.partnerImgRoot_:Y(-640)

	if height > 1000 then
		self.logoImg_:SetLocalPosition(362, -79, 0)
		self.showFinalGroup_:SetLocalPosition(196, -240, 0)
		self.content_:Y(-673)

		local bg = self.content_:ComponentByName("e:image", typeof(UISprite))
		bg.height = 692

		bg:Y(-31)
		self.grid_:Y(190)
	else
		self.content_:Y(-574)
	end

	self:layoutUI()
	self:register()
	self:refreshData()
end

function ActivityIceSecret:getActivityData()
	self.status_ = self.activityData.detail.status
	self.awards_ = self.activityData.detail.awards or {}
	self.posIds_ = self.activityData.detail.pos_ids or {}
	self.roundNum_ = self.activityData.detail.round or 1
	self.selectId_ = self.activityData.detail.select_id or 0
	self.awardeds_ = self.activityData.detail.awardeds or {}
	self.hasGetFinal_ = xyd.arrayIndexOf(self.awards_, self.selectId_)
end

function ActivityIceSecret:getComponent()
	local goTrans = self.go.transform
	self.imgBg_ = goTrans:NodeByName("e:image").gameObject
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UITexture))
	self.partnerImgRoot_ = goTrans:NodeByName("partnerImgRoot").gameObject
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.detailBtn_ = goTrans:NodeByName("detailBtn").gameObject
	self.showFinalGroup_ = goTrans:NodeByName("showFinalGroup").gameObject
	self.labelShowFinal_ = goTrans:ComponentByName("showFinalGroup/labelShowFinal", typeof(UILabel))
	self.showFinalIcon_ = goTrans:NodeByName("showFinalGroup/iconRoot").gameObject
	self.changeFinalBtn_ = goTrans:NodeByName("showFinalGroup/changeBtn").gameObject
	self.chooseFinalIcon_ = goTrans:NodeByName("showFinalGroup/chooseFinalIcon").gameObject
	local conTrans = goTrans:NodeByName("content")
	self.content_ = conTrans.gameObject
	self.itemCostLabel_ = conTrans:ComponentByName("itemCostGroup/labelNum", typeof(UILabel))
	self.itemCostPlusBtn_ = conTrans:NodeByName("itemCostGroup/plusIcon").gameObject
	self.stageLabel_ = conTrans:ComponentByName("stageLabel", typeof(UILabel))
	self.startGroup_ = conTrans:NodeByName("startGroup").gameObject
	self.startBtn_ = conTrans:NodeByName("startGroup/startBtn").gameObject
	self.startBtnLabel_ = conTrans:ComponentByName("startGroup/startBtn/label", typeof(UILabel))
	self.iceSecretIcon_ = conTrans:NodeByName("iceSecretIcon").gameObject

	self.iceSecretIcon_:SetActive(false)

	self.grid_ = conTrans:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.partnerModel = import("app.components.GirlsModelLite").new(self.partnerImgRoot_)

	if not self.bubbleText_ then
		self.bubbleText_ = import("app.components.BubbleText").new(self.go)
	end

	self.bubbleText_:setDepth(50)
	self.bubbleText_:setBubbleFlipX(true)
	self.bubbleText_:setPosition(Vector3(40, -100, 0))

	self.effectGroup_ = goTrans:NodeByName("effectGroup").gameObject
end

function ActivityIceSecret:refreshCostNum()
	local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.ICE_SECRET_BREAK_ITEM_2)
	local needNum = xyd.tables.miscTable:split2num("activity_ice_secret_hammer", "value", "#")[2]
	self.itemCostLabel_.text = num .. "/" .. needNum
end

function ActivityIceSecret:setBubbleLabel()
	local random = math.random()
	local text = ""

	if random < 0.33 then
		text = __("ACTIVITY_ICE_SECRET_PARTNER_TEXT1")
	elseif random < 0.66 then
		text = __("ACTIVITY_ICE_SECRET_PARTNER_TEXT2")
	else
		text = __("ACTIVITY_ICE_SECRET_PARTNER_TEXT3")
	end

	if self.bubbleText_ and not self.isPlayLog_ then
		self.isPlayLog_ = true

		self.bubbleText_:playDialogAction(text)
		self:waitForTime(5, function ()
			self.isPlayLog_ = false

			self.bubbleText_:playDisappear()
		end, "iceplayDialog")
	end
end

function ActivityIceSecret:layoutUI()
	xyd.setUITextureByNameAsync(self.logoImg_, "ice_secret_logo_" .. xyd.Global.lang, false)

	self.labelShowFinal_.text = __("ACTIVITY_ICE_SECRET_MAXAWARD_TEXT")

	self:refreshCostNum()

	self.startBtnLabel_.text = __("ACTIVITY_ICE_SECRET_START")
	self.stageLabel_.text = __("ACTIVITY_ICE_SECRET_ROUNDS", self.roundNum_)

	self.partnerModel:setModelInfo({
		id = 49
	})
	self.partnerModel:setBubble()
	self:checkStartGroup()
	self:refreshFinalIcon()
end

function ActivityIceSecret:checkStartGroup()
	if self.status_ == 0 and self.selectId_ ~= 0 then
		self.startGroup_:SetActive(true)
	else
		self.startGroup_:SetActive(false)
	end
end

function ActivityIceSecret:register()
	ActivityIceSecret.super.onRegister(self)

	UIEventListener.Get(self.itemCostPlusBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.ICE_SECRET_BREAK_ITEM_2
		})
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_ICE_SECRET_GAME_HELP"
		})
	end

	UIEventListener.Get(self.changeFinalBtn_).onClick = handler(self, self.changeFinalAward)
	UIEventListener.Get(self.chooseFinalIcon_).onClick = handler(self, self.changeFinalAward)
	UIEventListener.Get(self.startBtn_).onClick = handler(self, self.startRound)

	UIEventListener.Get(self.detailBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("ice_secret_award_window", {
			round = self.roundNum_,
			awardedList = self.awardeds_,
			bigRewardList = xyd.tables.activityIceSecretAwardsTable:getBigList()
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.ICE_SECRET_SET_STATUS, handler(self, self.onSetStatus))
	self:registerEvent(xyd.event.ICE_SECRET_SELECT_AWARD, handler(self, self.onSelectAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.refreshCostNum))
end

function ActivityIceSecret:startRound()
	if self.status_ == 0 and self.selectId_ ~= 0 then
		self:setStatus(1)
	elseif self.status_ == 0 and self.selectId_ == 0 then
		xyd.showToast(__("ACTIVITY_ICE_SECRET_MAXAWARD_ERROR"))
	end
end

function ActivityIceSecret:setStatus(nextStatus)
	local msg = messages_pb.ice_secret_set_status_req()
	msg.activity_id = xyd.ActivityID.ICE_SECRET
	msg.status = nextStatus

	xyd.Backend.get():request(xyd.mid.ICE_SECRET_SET_STATUS, msg)

	self.activityData.detail.status = tonumber(nextStatus)
end

function ActivityIceSecret:onSetStatus(event)
	self:setBubbleLabel()

	if self.status_ == 0 and tonumber(self.activityData.detail.status) == 1 then
		self:playStarAnim()
	elseif self.status_ == 1 and tonumber(self.activityData.detail.status) == 0 then
		self.hasGetBig_ = false
		self.activityData.detail.select_id = 0
		self.activityData.detail.round = self.activityData.detail.round + 1
		self.activityData.detail.pos_ids = {}
		self.activityData.detail.awards = {}

		self:refreshData()
		self:playRestarAnim()
		self:refreshFinalIcon()
		self:checkStartGroup()
	end

	self.stageLabel_.text = __("ACTIVITY_ICE_SECRET_ROUNDS", self.roundNum_)
end

function ActivityIceSecret:playRestarAnim()
	if not self.startEffect_ then
		self.startEffect_ = xyd.Spine.new(self.effectGroup_)

		self.startEffect_:setInfo("fx_ice_air", function ()
			self.startEffect_:play("texiao01", 1, 1, function ()
				self.startEffect_:SetActive(false)
			end)
		end)
	else
		self.startEffect_:SetActive(true)
		self.startEffect_:play("texiao01", 1, 1, function ()
			self.startEffect_:SetActive(false)
		end)
	end
end

function ActivityIceSecret:playStarAnim()
	if not self.startEffect_ then
		self.startEffect_ = xyd.Spine.new(self.effectGroup_)

		self.startEffect_:setInfo("fx_ice_air", function ()
			self:refreshData(true)
			self:checkStartGroup()
			self:setIceAni()
			self.startEffect_:play("texiao01", 1, 1, function ()
				self.startEffect_:SetActive(false)
			end)
		end)
	else
		self:refreshData(true)
		self:checkStartGroup()
		self.startEffect_:SetActive(true)
		self:setIceAni()
		self.startEffect_:play("texiao01", 1, 1, function ()
			self.startEffect_:SetActive(false)
		end)
	end
end

function ActivityIceSecret:setIceAni()
	local seq = self:getSequence()

	for idx, frame in ipairs(startIceList) do
		local icon = self.iceIconList_[idx]
		local mask = icon:getImgMask()

		local function setter(value)
			mask.alpha = value
		end

		seq:Insert(frame / 30, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.33))
		seq:InsertCallback((frame + 5) / 30, function ()
			if icon.itemIcon_ then
				icon.itemIcon_:SetActive(false)
			end
		end)
	end
end

function ActivityIceSecret:refreshFinalIcon()
	if not self.selectId_ or self.selectId_ == 0 then
		self.changeFinalBtn_:SetActive(false)
		self.chooseFinalIcon_:SetActive(true)
		self.showFinalIcon_:SetActive(false)
	else
		self.chooseFinalIcon_:SetActive(false)
		self.showFinalIcon_:SetActive(true)
		self.changeFinalBtn_:SetActive(true)

		local award = xyd.tables.activityIceSecretAwardsTable:getAwards(self.selectId_)
		local params = {
			itemID = award[1],
			num = award[2],
			uiRoot = self.showFinalIcon_
		}

		if not self.finalIcon_ then
			self.finalIcon_ = xyd.getItemIcon(params)
		else
			NGUITools.DestroyChildren(self.showFinalIcon_.transform)

			self.finalIcon_ = xyd.getItemIcon(params)
		end

		if self.hasGetFinal_ and self.hasGetFinal_ >= 1 and self.status_ == 1 then
			self.changeFinalBtn_:SetActive(false)
			self.finalIcon_:setChoose(true)
		else
			self.changeFinalBtn_:SetActive(true)
			self.finalIcon_:setChoose(false)
			self.finalIcon_:setMask(false)
		end
	end
end

function ActivityIceSecret:refreshData(isStart)
	self:getActivityData()

	if not self.awardIdList then
		self.awardIdList = xyd.tables.activityIceSecretAwardsTable:getNormalList()

		for i = 1, #self.awardIdList do
			local index = math.ceil(math.random() * #self.awardIdList)
			local temp = self.awardIdList[index]

			if temp ~= -1 and self.awardIdList[i] ~= -1 then
				self.awardIdList[index] = self.awardIdList[i]
				self.awardIdList[i] = temp
			end
		end
	end

	dump(self.awardIdList)

	for idx, id in ipairs(self.awardIdList) do
		local params = {
			pos = idx,
			isStart = isStart
		}

		if self.status_ == 0 then
			local awards = nil

			if idx ~= BigAwardNum and id ~= -1 then
				awards = xyd.tables.activityIceSecretAwardsTable:getAwards(id)
				params.itemId = awards[1]
				params.num = awards[2]
			elseif self.selectId_ and self.selectId_ ~= 0 then
				awards = xyd.tables.activityIceSecretAwardsTable:getAwards(self.selectId_)
				params.itemId = awards[1]
				params.num = awards[2]
			else
				params.itemId = 0
			end
		elseif not self.hasGetFinal_ or idx ~= self.posIds_[self.hasGetFinal_] then
			local hasGotIndex = xyd.arrayIndexOf(self.posIds_, idx)

			if hasGotIndex and hasGotIndex >= 1 then
				params.itemId = -2
			else
				params.itemId = -1
			end
		else
			params.itemId = -1
			params.hasGotBig = true
		end

		if not self.iceIconList_[idx] then
			local goItem = NGUITools.AddChild(self.grid_.gameObject, self.iceSecretIcon_)

			goItem:SetActive(true)

			self.iceIconList_[idx] = ActivityIceSecretItem.new(goItem, self)

			self.iceIconList_[idx]:setInfo(params)
		else
			self.iceIconList_[idx]:setInfo(params)
		end
	end
end

function ActivityIceSecret:onGetAward(event)
	local data = cjson.decode(event.data.detail)
	local info = data.info
	local posList = info.pos_ids
	local awardData = {
		awardId = info.awards[#info.awards],
		posId = posList[#posList]
	}

	self:getActivityData()
	self:updateIconStatus(awardData)
end

function ActivityIceSecret:onSelectAward(event)
	self.selectId_ = event.data.select_id
	self.activityData.detail.select_id = event.data.select_id

	self:refreshFinalIcon()

	if self.status_ == 0 then
		local icon = self.iceIconList_[BigAwardNum]
		local awards = xyd.tables.activityIceSecretAwardsTable:getAwards(self.selectId_)
		local params = {
			pos = BigAwardNum,
			itemId = awards[1],
			num = awards[2]
		}

		icon:setInfo(params)
		self:checkStartGroup()
	end
end

function ActivityIceSecret:updateIconStatus(params)
	local pos = params.posId
	local data = {}
	local awardId = params.awardId

	if self:isFinalAward(awardId) then
		data.hasGotBig = true
		self.hasGetBig_ = true

		self:refreshFinalIcon()
	end

	local award = xyd.tables.activityIceSecretAwardsTable:getAwards(awardId)
	local iceIcon = self.iceIconList_[tonumber(pos)]
	data.itemId = award[1]
	data.num = award[2]

	if iceIcon then
		iceIcon:playAwardAnimation(data)
	end
end

function ActivityIceSecret:isFinalAward(awardId)
	local type_ = xyd.tables.activityIceSecretAwardsTable:getType(awardId)

	return tonumber(type_) == 1
end

function ActivityIceSecret:playShake(itemCallBack)
	if self.shakeTimer_ then
		self.shakeTimer_:Stop()

		self.shakeTimer_ = nil
	end

	local data = {
		{
			x = 0,
			y = 0
		},
		{
			x = 10,
			y = 0
		},
		{
			x = 17,
			y = 5
		},
		{
			x = -10,
			y = 0
		},
		{
			x = 0,
			y = 5
		},
		{
			x = 15,
			y = 0
		},
		{
			x = 5,
			y = 2
		},
		{
			x = -5,
			y = 4
		},
		{
			x = 0,
			y = 0
		}
	}
	local count = 0
	local bg_ = self.imgBg_
	local groupMain = self.content_
	local beforePos = groupMain.transform.localPosition
	local pos = Vector3(beforePos.x, beforePos.y, beforePos.z)

	local function callback()
		if count >= #data - 1 then
			bg_:SetLocalPosition(0, 0, 0)
			groupMain:SetLocalPosition(pos.x, pos.y, pos.z)

			self.isShake_ = false

			self.shakeTimer_:Stop()

			self.shakeTimer_ = nil

			if itemCallBack then
				itemCallBack()
			end

			return
		end

		bg_:SetLocalPosition(data[count + 1].x, data[count + 1].y, 0)
		groupMain:SetLocalPosition(data[count + 1].x, data[count + 1].y + pos.y, 0)

		count = count + 1
	end

	self.shakeTimer_ = FrameTimer.New(callback, 1, #data)

	table.insert(self.timers_, self.shakeTimer_)
	self.shakeTimer_:Start()

	self.isShake_ = true
end

function ActivityIceSecret:changeFinalAward()
	xyd.WindowManager.get():openWindow("activity_ice_secret_select_window", {
		bigRewardList = xyd.tables.activityIceSecretAwardsTable:getBigList(),
		round = self.roundNum_,
		awardedList = self.awardeds_,
		select_id = self.selectId_,
		callBack = function (selectId)
			if selectId and selectId > 0 then
				local msg = messages_pb.ice_secret_select_award_req()
				msg.activity_id = xyd.ActivityID.ICE_SECRET
				msg.select_id = selectId

				xyd.Backend.get():request(xyd.mid.ICE_SECRET_SELECT_AWARD, msg)
			end
		end
	})
end

function ActivityIceSecretItem:ctor(parentGo, parent)
	self.parent_ = parent

	ActivityIceSecretItem.super.ctor(self, parentGo)
end

function ActivityIceSecretItem:initUI()
	ActivityIceSecretItem.super.initUI(self)

	local goTrans = self.go.transform
	self.touchBox_ = goTrans:GetComponent(typeof(UnityEngine.BoxCollider))
	self.imgMask_ = goTrans:ComponentByName("iconMask", typeof(UISprite))
	self.effectGroup_ = goTrans:NodeByName("effectGroup").gameObject
	self.iconRoot_ = goTrans:NodeByName("iconRoot").gameObject
	self.iconBreak_ = goTrans:NodeByName("iconBreak").gameObject

	self.iconBreak_:SetActive(false)

	UIEventListener.Get(self.touchBox_.gameObject).onClick = handler(self, self.onTouchIcon)
end

function ActivityIceSecretItem:setInfo(data)
	if not data then
		return
	end

	self.data_ = data
	self.pos_ = data.pos

	if self.data_.itemId == 0 then
		self.touchBox_.enabled = true

		xyd.setUISpriteAsync(self.imgMask_, nil, "ice_secret__select_btn", function ()
		end)
		self.imgMask_:SetActive(true)
	elseif self.data_.itemId == -1 then
		self.imgMask_:SetActive(true)

		if self.data_.isStart then
			self.imgMask_.alpha = 0
		end

		self.touchBox_.enabled = true

		xyd.setUISpriteAsync(self.imgMask_, nil, "ice_secret_bk_1", function ()
			self.imgMask_.height = 113
			self.imgMask_.width = 113
		end)
	elseif self.data_.itemId == -2 and not data.hasGotBig then
		self.touchBox_.enabled = false

		self.imgMask_:SetActive(false)

		if self.itemIcon_ then
			self.itemIcon_:SetActive(false)
		end
	else
		xyd.setUISpriteAsync(self.imgMask_, nil, "ice_secret_bk_1", function ()
			self.imgMask_.height = 113
			self.imgMask_.width = 113
		end)
		self.imgMask_:SetActive(false)

		if not self.itemIcon_ then
			self.itemIcon_ = xyd.getItemIcon({
				noClick = true,
				scale = 0.9,
				uiRoot = self.iconRoot_,
				itemID = data.itemId,
				num = data.num
			})
		else
			NGUITools.DestroyChildren(self.iconRoot_.transform)

			self.itemIcon_ = xyd.getItemIcon({
				noClick = true,
				scale = 0.9,
				uiRoot = self.iconRoot_,
				itemID = data.itemId,
				num = data.num
			})
		end
	end

	if self.data_.isStart then
		self.imgMask_:SetActive(true)

		self.imgMask_.alpha = 0
	end

	if data.hasGotBig then
		self.imgMask_:SetActive(true)
		xyd.setUISpriteAsync(self.imgMask_, nil, "ice_secret_bk_3", function ()
		end)

		self.nextEffect_ = xyd.Spine.new(self.effectGroup_.gameObject)

		self.nextEffect_:setInfo("fx_ice_next", function ()
			self.nextEffect_:SetLocalScale(0.9, 0.9, 0.9)
			self.imgMask_:SetActive(false)
			self.nextEffect_:play("texiao02", 0, 1)
		end)
	elseif self.nextEffect_ then
		self.nextEffect_:SetActive(false)
		self.nextEffect_:destroy()

		self.nextEffect_ = nil
	end
end

function ActivityIceSecretItem:getImgMask()
	return self.imgMask_
end

function ActivityIceSecretItem:onTouchIcon()
	if self.parent_.status_ == 0 and self.data_.itemId ~= 0 then
		return
	end

	if self.data_.itemId == 0 then
		self.parent_:changeFinalAward()
	elseif self.data_.itemId == -1 and not self.data_.hasGotBig then
		local hasNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.ICE_SECRET_BREAK_ITEM_2)
		local needNum = xyd.tables.miscTable:split2num("activity_ice_secret_hammer", "value", "#")[2]

		if hasNum < needNum then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(xyd.ItemID.ICE_SECRET_BREAK_ITEM_2)))

			return
		end

		if self.parent_.hasGetBig_ then
			xyd.alertYesNo(__("ACTIVITY_ICE_SECRET_GAME_TIP"), function (yes_no)
				self.parent_.hasGetBig_ = false

				if yes_no then
					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ICE_SECRET, cjson.encode({
						pos_id = self.pos_
					}))
				end
			end)
		else
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ICE_SECRET, cjson.encode({
				pos_id = self.pos_
			}))
		end
	elseif self.data_.hasGotBig and self.parent_.status_ == 1 then
		self.parent_:setStatus(0)
	end
end

function ActivityIceSecretItem:playAwardAnimation(data)
	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon({
			noClick = true,
			uiRoot = self.iconRoot_,
			itemID = data.itemId,
			num = data.num
		})

		self.itemIcon_:setScale(0.9)
	else
		NGUITools.DestroyChildren(self.iconRoot_.transform)

		self.itemIcon_ = xyd.getItemIcon({
			noClick = true,
			uiRoot = self.iconRoot_,
			itemID = data.itemId,
			num = data.num
		})

		self.itemIcon_:setScale(0.9)
	end

	self.touchBox_.enabled = false
	local iconWidgt = self.itemIcon_.go:GetComponent(typeof(UIWidget))

	self.itemIcon_:SetActive(false)

	self.effect_ = xyd.Spine.new(self.effectGroup_)

	if not data.hasGotBig then
		self.effect_:setInfo("fx_ice_hammer", function ()
			self:waitForTime(0.27, function ()
				self.imgMask_:SetActive(false)
				self.itemIcon_:SetActive(true)
			end)
			self.effect_:play("texiao01", 1, 1, function ()
				self.imgMask_:SetActive(false)

				local function setter(value)
					iconWidgt.alpha = value
				end

				local seq = self:getSequence()

				seq:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0, 0.5))
				seq:AppendCallback(function ()
					xyd.models.itemFloatModel:pushNewItems({
						{
							item_id = data.itemId,
							item_num = data.num
						}
					})
				end)
			end)
		end)
	else
		self.effect_:setInfo("fx_ice_hammer", function ()
			self:waitForTime(0.27, function ()
				self.parent_:playShake()
				self.imgMask_:SetActive(false)
				self.itemIcon_:SetActive(true)
			end)
			self.effect_:play("texiao01", 1, 1, function ()
				local targetSprite = self.itemIcon_:getIconSprite()
				local newEffect = xyd.Spine.new(self.itemIcon_.go.gameObject)

				newEffect:setInfo("fx_ice_awards", function ()
					newEffect:SetLocalPosition(0, 0, 0)
					newEffect:SetLocalScale(1, 1, 1)
					newEffect:setRenderTarget(targetSprite, -1)
					newEffect:play("texiao01", 0, 1)
					self:waitForTime(1, function ()
						newEffect:SetActive(false)
						self.itemIcon_.go:SetActive(false)

						if not self.nextEffect_ then
							self.nextEffect_ = xyd.Spine.new(self.effectGroup_.gameObject)

							self.nextEffect_:setInfo("fx_ice_next", function ()
								self.nextEffect_:SetLocalScale(0.9, 0.9, 0.9)
								self.nextEffect_:play("texiao01", 1, 1, function ()
									self.touchBox_.enabled = true
									self.data_.hasGotBig = true

									self.nextEffect_:play("texiao02", 0, 1)
								end)
							end)
						else
							self.nextEffect_:play("texiao01", 1, 1, function ()
								self.touchBox_.enabled = true

								self.nextEffect_:play("texiao02", 0, 1)
							end)
						end

						xyd.models.itemFloatModel:pushNewItems({
							{
								item_id = data.itemId,
								item_num = data.num
							}
						})
					end)
				end)
			end)
		end)
	end
end

return ActivityIceSecret
