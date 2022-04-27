local ActivityContent = import(".ActivityContent")
local ActivityFirework = class("ActivityFirework", ActivityContent)
local json = require("cjson")
local MultipleState = {
	NORMAL = 1,
	FIVE = 5
}
local FireState = {
	AWARD_YET = 3,
	COMMON = 0,
	FIRE = 1,
	BOOM = 2
}
local FireArrows = {
	{
		left = {},
		right = {
			2,
			3
		},
		up = {},
		down = {
			4,
			7
		}
	},
	{
		left = {
			1
		},
		right = {
			3
		},
		up = {},
		down = {
			5,
			8
		}
	},
	{
		left = {
			2,
			1
		},
		right = {},
		up = {},
		down = {
			6,
			9
		}
	},
	{
		left = {},
		right = {
			5,
			6
		},
		up = {
			1
		},
		down = {
			7
		}
	},
	{
		left = {
			4
		},
		right = {
			6
		},
		up = {
			2
		},
		down = {
			8
		}
	},
	{
		left = {
			5,
			4
		},
		right = {},
		up = {
			3
		},
		down = {
			9
		}
	},
	{
		left = {},
		right = {
			8,
			9
		},
		up = {
			4,
			1
		},
		down = {}
	},
	{
		left = {
			7
		},
		right = {
			9
		},
		up = {
			5,
			2
		},
		down = {}
	},
	{
		left = {
			8,
			7
		},
		right = {},
		up = {
			6,
			3
		},
		down = {}
	}
}

function ActivityFirework:ctor(parentGO, params, parent)
	ActivityFirework.super.ctor(self, parentGO, params, parent)
end

function ActivityFirework:getPrefabPath()
	return "Prefabs/Windows/activity/award_firework"
end

function ActivityFirework:initUI()
	self:getUIComponent()
	ActivityFirework.super.initUI(self)

	self.costItemId = xyd.tables.miscTable:getNumber("firework_ticket_item", "value")
	local res = xyd.getEffectFilesByNames({
		"fx_firework",
		"fx_firework_burst",
		"fx_firework_energy"
	})
	self.effectStateNames = {
		[0] = "texiao01",
		"texiao02",
		"texiao03",
		"texiao03"
	}
	self.nextUpdateStates = {}
	self.isAuto = false
	self.completeLabelLeft.text = __("FIREWORK_TEXT09")
	self.explainBtnLabel.text = __("FIREWORK_TEXT10")
	self.choiceLabel.text = __("FIREWORK_TEXT11")
	self.unChoiceLabel.text = __("FIREWORK_TEXT11_2")
	self.completeShowTextName.text = __("FIREWORK_TEXT25")
	self.autoBtnButtonLabel.text = __("FIREWORK_TEXT12")

	self:initLogoCon()
	self:updateCompleteLabel()

	self.resConLabel.text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.FIRE_MATCH))
	local allHasRes = xyd.isAllPathLoad(res)

	if allHasRes then
		self:initUIComponent()

		return
	else
		ResCache.DownloadAssets("activity_firework", res, function (success)
			if tolua.isnull(self.go) then
				return
			end

			xyd.WindowManager.get():closeWindow("res_loading_window")
			self:initUIComponent()
		end, function (progress)
			local loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			if progress == 1 and not loading_win then
				return
			end

			if not loading_win then
				xyd.WindowManager.get():openWindow("res_loading_window", {})
			end

			loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			loading_win:setLoadWndName("fire_work_wd")
			loading_win:setLoadProgress("fire_work_wd", progress)
		end, 1)
	end
end

function ActivityFirework:getUIComponent()
	self.main = self.go:NodeByName("main").gameObject
	self.bg = self.go:ComponentByName("bg", typeof(UITexture)).gameObject
	self.shopBtn = self.main:NodeByName("shopBtn").gameObject
	self.shopBtnRedPoint = self.shopBtn:ComponentByName("redPoint", typeof(UISprite)).gameObject
	self.bottomCon = self.main:NodeByName("bottomCon").gameObject
	self.logoCon = self.main:NodeByName("logoCon").gameObject
	self.textImg = self.logoCon:ComponentByName("textImg", typeof(UISprite))
	self.timerGroup = self.logoCon:NodeByName("timerGroup").gameObject
	self.timerGroupUILayout = self.logoCon:ComponentByName("timerGroup", typeof(UILayout))
	self.timeLabel = self.timerGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timerGroup:ComponentByName("endLabel", typeof(UILabel))
	self.resCon = self.main:NodeByName("resCon").gameObject
	self.resConBg = self.resCon:ComponentByName("resConBg", typeof(UISprite))
	self.resConIcon = self.resCon:ComponentByName("resConIcon", typeof(UISprite))
	self.resConLabel = self.resCon:ComponentByName("resConLabel", typeof(UILabel))
	self.resConAddBtn = self.resCon:NodeByName("resConAddBtn").gameObject
	self.topRightCon = self.main:NodeByName("topRightCon").gameObject
	self.helpBtn = self.topRightCon:NodeByName("helpBtn").gameObject
	self.awardBtn = self.topRightCon:NodeByName("awardBtn").gameObject
	self.explainBtn = self.topRightCon:NodeByName("explainBtn").gameObject
	self.explainBtnLabel = self.explainBtn:ComponentByName("explainBtnLabel", typeof(UILabel))
	self.completeCon = self.bottomCon:NodeByName("completeCon").gameObject
	self.completeLabelLeft = self.completeCon:ComponentByName("completeLabelLeft", typeof(UILabel))
	self.completeLabelright = self.completeCon:ComponentByName("completeLabelright", typeof(UILabel))
	self.fireCon = self.go:NodeByName("fireCon").gameObject
	self.fireConUIPanel = self.go:ComponentByName("fireCon", typeof(UIPanel))
	self.bottomConBg = self.fireCon:ComponentByName("bottomConBg", typeof(UITexture))

	for i = 1, 9 do
		self["fire" .. i] = self.fireCon:NodeByName("fire" .. i).gameObject
		self["fireEffect" .. i] = self["fire" .. i]:ComponentByName("fireEffect", typeof(UITexture))

		self["fireEffect" .. i].gameObject:SetLocalPosition(-8, 37, 0)

		self["itemCon" .. i] = self["fire" .. i]:NodeByName("itemCon").gameObject
		self["icon" .. i] = self["itemCon" .. i]:ComponentByName("icon", typeof(UISprite))
		self["label" .. i] = self["itemCon" .. i]:ComponentByName("label", typeof(UILabel))

		self["itemCon" .. i]:SetActive(false)
		self["itemCon" .. i]:SetLocalPosition(-9, 46, 0)
	end

	self.fireBurstCon = self.fireCon:ComponentByName("fireBurstCon", typeof(UITexture))
	self.multipleCon = self.bottomCon:NodeByName("multipleCon").gameObject
	self.multipleBtn = self.multipleCon:NodeByName("multipleBtn").gameObject
	self.multipleBtnUISprite = self.multipleCon:ComponentByName("multipleBtn", typeof(UISprite))
	self.multipleBtnBoxCollider = self.multipleCon:ComponentByName("multipleBtn", typeof(UnityEngine.BoxCollider))
	self.choiceLabel = self.multipleCon:ComponentByName("choiceLabel", typeof(UILabel))
	self.unChoiceLabel = self.multipleCon:ComponentByName("unChoiceLabel", typeof(UILabel))
	self.lockImg = self.multipleCon:ComponentByName("lockImg", typeof(UISprite))
	self.autoBtn = self.bottomCon:NodeByName("autoBtn").gameObject
	self.autoBtnBoxCollider = self.bottomCon:ComponentByName("autoBtn", typeof(UnityEngine.BoxCollider))
	self.autoBtnButtonLabel = self.autoBtn:ComponentByName("button_label", typeof(UILabel))
	self.img = self.autoBtn:ComponentByName("img", typeof(UISprite))
	self.imgSelect = self.img:ComponentByName("imgSelect", typeof(UISprite))
	self.powerCon = self.bottomCon:NodeByName("powerCon").gameObject
	self.powerConBoxCollider = self.bottomCon:ComponentByName("powerCon", typeof(UnityEngine.BoxCollider))
	self.progressBar = self.powerCon:ComponentByName("progressBar", typeof(UISprite))
	self.progressBarUIProgressBar = self.powerCon:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressImg = self.progressBar:ComponentByName("progressImg", typeof(UISprite))
	self.progressLabel = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.powerEffect = self.powerCon:ComponentByName("powerEffect", typeof(UITexture))
	self.completeShowCon = self.main:NodeByName("completeShowCon").gameObject
	self.completeShowTweenCon = self.completeShowCon:ComponentByName("completeShowTweenCon", typeof(UITexture))
	self.completeShowTextName = self.completeShowTweenCon:ComponentByName("completeShowTextName", typeof(UILabel))
	self.completeShowTextNum = self.completeShowTweenCon:ComponentByName("completeShowTextNum", typeof(UILabel))
end

function ActivityFirework:resizeToParent()
	ActivityFirework.super.resizeToParent(self)
	self:resizePosY(self.fireCon.gameObject, -580, -718)
	self:resizePosY(self.bottomCon.gameObject, -580, -753)
	self:resizePosY(self.resCon.gameObject, -232, -372)
	self:resizePosY(self.shopBtn.gameObject, -216.7, -350)
	self:resizePosY(self.logoCon.gameObject, -101.3, -145)
	self:resizePosY(self.explainBtn.gameObject, -71, -99)
	self:resizePosY(self.topRightCon.gameObject, -38.5, -42.6)
	self:resizePosY(self.bg.gameObject, 17, 0)
	self:resizePosY(self.completeCon.gameObject, 283.5, 314)
end

function ActivityFirework:initUIComponent()
	self:register()
	self:updateResLabel()
	self:updateCompleteLabel()
	self:initFireCon()
	self:updateMultipleBtnState()
	self.shopBtnRedPoint:SetActive(self.activityData:isCanBuyShop())
end

function ActivityFirework:register()
	ActivityFirework.super.onRegister(self)

	UIEventListener.Get(self.shopBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_firework_shop_window", {
			activityData = self.activityData
		})
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "FIREWORK_TEXT13"
		})
	end

	UIEventListener.Get(self.explainBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_firework_explain_window")
	end

	UIEventListener.Get(self.resConBg.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.FIRE_MATCH,
			activityID = xyd.ActivityID.ACTIVITY_FIREWORK
		})
	end

	UIEventListener.Get(self.resConAddBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.FIRE_MATCH,
			activityID = xyd.ActivityID.ACTIVITY_FIREWORK
		})
	end

	UIEventListener.Get(self.autoBtn.gameObject).onClick = function ()
		local yetStaGet = self.activityData.detail.sta_get
		local roundNum = self.activityData.detail.round
		local needCost = xyd.tables.miscTable:split2num("firework_ratio_5_unlock", "value", "|")

		if roundNum < needCost[1] and yetStaGet < needCost[2] then
			xyd.alertTips(__("FIREWORK_TEXT17", needCost[1], needCost[2]))

			return
		end

		if not self.isAuto then
			xyd.alertYesNo(__("FIREWORK_TEXT27"), function (yes)
				if yes and not self.isAuto then
					self.isAuto = not self.isAuto

					self.imgSelect.gameObject:SetActive(self.isAuto)
					self:autoCheckNext()
				end
			end)
		else
			self:closeAuto()
		end
	end

	UIEventListener.Get(self.awardBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_space_explore_awarded_window", {
			data = self.activityData.detail.items,
			labelNone = __("FIREWORK_TEXT19"),
			winTitle = __("FIREWORK_TEXT18")
		})
	end

	UIEventListener.Get(self.powerCon.gameObject).onClick = function ()
		if self.activityData:getEndTime() <= xyd.getServerTime() then
			xyd.alertTips(__("ACTIVITY_END_YET"))

			return
		end

		if self.isPlaying then
			return
		end

		if self.activityData.detail["fire_" .. self.multiple].is_powered == 2 then
			xyd.alertConfirm(__("FIREWORK_TEXT20"), nil, __("SURE"))

			return
		end

		local isCanFire = false

		for i, state in pairs(self.activityData.detail["fire_" .. self.multiple].status) do
			if state == FireState.COMMON or state == FireState.FIRE then
				isCanFire = true

				break
			end
		end

		if not isCanFire then
			xyd.alertConfirm(__("FIREWORK_TEXT21"), nil, __("SURE"))

			return
		end

		local needPowerNum = xyd.tables.miscTable:getNumber("firework_energy", "value") * self.multiple

		if self.activityData.detail.energy < needPowerNum then
			xyd.alertConfirm(__("FIREWORK_TEXT22", needPowerNum), nil, __("SURE"))

			return
		end

		xyd.alertYesNo(__("FIREWORK_TEXT23", needPowerNum), function (yes)
			if yes then
				local params = json.encode({
					award_type = xyd.FireWorkAwardType.POWER,
					mode = self.multiple
				})

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FIREWORK, params)
			end
		end)
	end

	UIEventListener.Get(self.multipleBtn.gameObject).onClick = function ()
		local yetStaGet = self.activityData.detail.sta_get
		local roundNum = self.activityData.detail.round
		local needCost = xyd.tables.miscTable:split2num("firework_ratio_5_unlock", "value", "|")

		if roundNum < needCost[1] and yetStaGet < needCost[2] then
			xyd.alertTips(__("FIREWORK_TEXT17", needCost[1], needCost[2]))

			return
		end

		if self.multiple == MultipleState.NORMAL then
			self.multiple = MultipleState.FIVE
		elseif self.multiple == MultipleState.FIVE then
			self.multiple = MultipleState.NORMAL
		end

		xyd.db.misc:setValue({
			key = "actvity_firework_multiple_state",
			value = self.multiple
		})
		xyd.db.misc:setValue({
			key = "actvity_firework_multiple_state_endTime",
			value = self.activityData:getEndTime()
		})
		self:updateMultipleBtnState()

		local function setter1(value)
			self.fireConUIPanel.alpha = value
		end

		self:changeBtnsEnabled(false)
		self.fireCon.gameObject:SetLocalScale(1, 1, 1)

		local sequence = self:getSequence()

		sequence:Append(self.fireCon.gameObject.transform:DOScale(Vector3(1.05, 1.05, 1), 0.06):SetEase(DG.Tweening.Ease.Linear))
		sequence:Append(self.fireCon.gameObject.transform:DOScale(Vector3(0.5, 0.5, 1), 0.14):SetEase(DG.Tweening.Ease.Linear))
		sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0.5, 0.05, 0.14):SetEase(DG.Tweening.Ease.Linear))
		sequence:AppendCallback(function ()
			sequence:Kill(false)

			self.nextUpdateStates = {}

			self:initFireState()
			self:updatePowerShow()

			local function setter2(value)
				self.fireConUIPanel.alpha = value
			end

			self.fireCon.gameObject:SetLocalScale(0.5, 0.5, 1)

			local sequence2 = self:getSequence()

			sequence2:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0.05, 1, 0.1):SetEase(DG.Tweening.Ease.Linear))
			sequence2:Join(self.fireCon.gameObject.transform:DOScale(Vector3(1.03, 1.03, 1), 0.1):SetEase(DG.Tweening.Ease.Linear))
			sequence2:Append(self.fireCon.gameObject.transform:DOScale(Vector3(1, 1, 1), 0.1):SetEase(DG.Tweening.Ease.Linear))
			sequence2:AppendCallback(function ()
				sequence2:Kill(false)
				self:changeBtnsEnabled(true)

				for i = 1, 9 do
					if self["effectFire" .. i]:getGameObject().activeSelf then
						self["effectFire" .. i]:setAlpha(1)
					end
				end
			end)
		end)
	end

	for i = 1, 9 do
		UIEventListener.Get(self["fire" .. i].gameObject).onClick = function ()
			self:onClickFire(i)
		end
	end

	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.itemChange))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityFirework:closeAuto()
	if self.isAuto then
		self.isAuto = false

		self.imgSelect.gameObject:SetActive(self.isAuto)
	end
end

function ActivityFirework:autoCheckNext()
	if not self.isPlaying and self.isAuto then
		local canGetAwardNum = 0
		local commonIndex = -1
		local fireIndex = -1

		for i, state in pairs(self.activityData.detail["fire_" .. self.multiple].status) do
			if state == FireState.COMMON then
				commonIndex = i

				break
			elseif state == FireState.FIRE then
				if fireIndex == -1 then
					fireIndex = i
				end
			elseif state == FireState.BOOM then
				canGetAwardNum = canGetAwardNum + 1
			end
		end

		if commonIndex > 0 then
			self:onClickFire(commonIndex)
		elseif fireIndex > 0 then
			self:onClickFire(fireIndex)
		elseif canGetAwardNum > 0 then
			local params = json.encode({
				award_type = xyd.FireWorkAwardType.GET_AWARD,
				mode = self.multiple
			})

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FIREWORK, params)
		end
	end
end

function ActivityFirework:checkNoAutoLastOneGetAward()
	if not self.isPlaying and not self.isAuto then
		local canGetAwardNum = 0
		local commonIndex = -1
		local fireIndex = -1

		for i, state in pairs(self.activityData.detail["fire_" .. self.multiple].status) do
			if state == FireState.COMMON then
				commonIndex = i

				break
			elseif state == FireState.FIRE then
				if fireIndex == -1 then
					fireIndex = i
				end
			elseif state == FireState.BOOM then
				canGetAwardNum = canGetAwardNum + 1
			end
		end

		if commonIndex > 0 then
			-- Nothing
		elseif fireIndex > 0 then
			-- Nothing
		elseif canGetAwardNum > 0 then
			local params = json.encode({
				award_type = xyd.FireWorkAwardType.GET_AWARD,
				mode = self.multiple
			})

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FIREWORK, params)
		end
	end
end

function ActivityFirework:updateMultipleBtnState()
	local yetStaGet = self.activityData.detail.sta_get
	local roundNum = self.activityData.detail.round
	local needCost = xyd.tables.miscTable:split2num("firework_ratio_5_unlock", "value", "|")

	if needCost[1] <= roundNum or needCost[2] <= yetStaGet then
		if self.lockImg.gameObject.activeSelf then
			self.isShowAutoMultipleTips = true
		end

		self.lockImg.gameObject:SetActive(false)
		self.unChoiceLabel.gameObject:X(71.5)
	else
		self.lockImg.gameObject:SetActive(true)
		self.unChoiceLabel.gameObject:X(65)
	end

	if self.multiple == MultipleState.NORMAL then
		xyd.setUISpriteAsync(self.multipleBtnUISprite, nil, "activity_firework_btn2", nil)

		self.choiceLabel.color = Color.New2(1012112383)
		self.choiceLabel.effectColor = Color.New2(4294967295.0)
		self.unChoiceLabel.color = Color.New2(4244438527.0)
		self.unChoiceLabel.effectColor = Color.New2(1097583359)
	elseif self.multiple == MultipleState.FIVE then
		xyd.setUISpriteAsync(self.multipleBtnUISprite, nil, "activity_firework_btn1", nil)

		self.unChoiceLabel.color = Color.New2(1012112383)
		self.unChoiceLabel.effectColor = Color.New2(4294967295.0)
		self.choiceLabel.color = Color.New2(4244438527.0)
		self.choiceLabel.effectColor = Color.New2(1097583359)
	end
end

function ActivityFirework:initLogoCon()
	if self.timeLabelCount then
		return
	end

	self.endLabel.text = __("END")

	xyd.setUISpriteAsync(self.textImg, nil, "activity_firework_logo_" .. xyd.Global.lang)

	self.timeLabelCount = import("app.components.CountDown").new(self.timeLabel)
	local leftTime = self.activityData:getEndTime() - xyd.getServerTime()

	if leftTime > 0 then
		self.timeLabelCount:setInfo({
			duration = leftTime,
			callback = function ()
				self.timeLabel.text = "00:00:00"
			end
		})
	else
		self.timeLabel.text = "00:00:00"
	end

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
		self.timeLabel.transform:SetSiblingIndex(1)
	end

	self.timerGroupUILayout:Reposition()
end

function ActivityFirework:itemChange(event)
	self:updateResLabel()

	local items = event.data.items

	for i, item in pairs(items) do
		if item.item_id == xyd.ItemID.FIRE_MOMENT then
			self.shopBtnRedPoint:SetActive(self.activityData:isCanBuyShop())
		end
	end
end

function ActivityFirework:updateResLabel()
	self:updateMultipleBtnState()

	self.resConLabel.text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.FIRE_MATCH))
end

function ActivityFirework:updateCompleteLabel()
	self.completeLabelright.text = tostring(self.activityData.detail.round)
end

function ActivityFirework:initFireCon()
	if not self.firstCheckFireNum then
		for i = 1, 9 do
			if not self["effectFire" .. i] then
				self["effectFire" .. i] = xyd.Spine.new(self["fireEffect" .. i].gameObject)

				self["effectFire" .. i]:SetLocalPosition(8, -37, 0)
				self["fire" .. i].gameObject:X(-198 + (i - 1) % 3 * 209)
				self["fire" .. i].gameObject:Y(143 - math.floor((i - 1) / 3) * 150)
				self["effectFire" .. i]:setInfo("fx_firework", function ()
					self:firstCheckFireEffect()
				end)
			end
		end
	elseif self.firstCheckFireNum and self.firstCheckFireNum >= 9 then
		self:initFireState()
		self:updatePowerShow()
	end
end

function ActivityFirework:firstCheckFireEffect()
	if not self.firstCheckFireNum then
		self.firstCheckFireNum = 0
	end

	self.firstCheckFireNum = self.firstCheckFireNum + 1

	if self.firstCheckFireNum >= 9 then
		self:initFireState()
		self:updatePowerShow()
	end
end

function ActivityFirework:initFireState()
	if not self.multiple then
		self.multiple = xyd.db.misc:getValue("actvity_firework_multiple_state") or MultipleState.NORMAL
		self.multiple = tonumber(self.multiple)
		local multipleLastTime = xyd.db.misc:getValue("actvity_firework_multiple_state_endTime")

		if not multipleLastTime or tonumber(multipleLastTime) < self.activityData:getEndTime() then
			self.multiple = MultipleState.NORMAL
		elseif multipleLastTime and self.activityData:getEndTime() <= tonumber(multipleLastTime) and self.multiple == MultipleState.FIVE then
			local yetStaGet = self.activityData.detail.sta_get
			local roundNum = self.activityData.detail.round
			local needCost = xyd.tables.miscTable:split2num("firework_ratio_5_unlock", "value", "|")

			if roundNum < needCost[1] and yetStaGet < needCost[2] then
				self.multiple = MultipleState.NORMAL
			end
		end
	end

	local status = self.activityData.detail.fire_1.status

	if not self.nowFireStatus1 then
		self.nowFireStatus1 = {}

		for i, data in pairs(status) do
			table.insert(self.nowFireStatus1, data)
		end
	end

	if self.multiple == MultipleState.FIVE then
		status = self.activityData.detail.fire_5.status

		if not self.nowFireStatus5 then
			self.nowFireStatus5 = {}

			for i, data in pairs(status) do
				table.insert(self.nowFireStatus5, data)
			end
		end

		xyd.setUITextureByNameAsync(self.bottomConBg, "activity_firework_main_bg2_5")
	elseif self.multiple == MultipleState.NORMAL then
		xyd.setUITextureByNameAsync(self.bottomConBg, "activity_firework_main_bg2")
	end

	self:updateMultipleBtnState()

	if #self.nextUpdateStates ~= 0 then
		status = self.nextUpdateStates[1]
	end

	for i in pairs(status) do
		local times = 0

		if status[i] == FireState.BOOM then
			times = 1
		end

		if status[i] == FireState.COMMON or status[i] == FireState.FIRE then
			self["effectFire" .. i]:getGameObject():SetActive(true)

			if self["effectFire" .. i]:getCurAction() ~= self.effectStateNames[status[i]] then
				self["effectFire" .. i]:play(self.effectStateNames[status[i]], times)
				self["effectFire" .. i]:startAtFrame(0)
			end

			self:updateShowIndexItem(i, false)
		else
			self["effectFire" .. i]:getGameObject():SetActive(false)

			if status[i] == FireState.BOOM then
				self:updateShowIndexItem(i, true)
			elseif status[i] == FireState.AWARD_YET then
				self:updateShowIndexItem(i, false)
			end
		end
	end
end

function ActivityFirework:updateShowIndexItem(index, state)
	self["itemCon" .. index]:SetActive(state)

	if state then
		local itemStr = self.activityData.detail["fire_" .. self.multiple].items[index]

		if itemStr ~= "" then
			local arr = xyd.split(itemStr, "#")

			xyd.setUISpriteAsync(self["icon" .. index], nil, xyd.tables.itemTable:getIcon(tonumber(arr[1])), nil, , true)

			self["label" .. index].text = xyd.getRoughDisplayNumber(tonumber(arr[2]))
		end
	end
end

function ActivityFirework:onBoomFire(index, completeStatus, boomTimes)
	local function checkOver()
		local searchSame = true
		local completeArr = self.nextUpdateStates[#self.nextUpdateStates]

		for i in pairs(completeArr) do
			local effectName = self["effectFire" .. i]:getCurAction()

			if not self["effectFire" .. i]:getGameObject().activeSelf then
				effectName = ""
			end

			if effectName ~= "" and effectName ~= self.effectStateNames[completeArr[i]] then
				searchSame = false

				break
			end
		end

		if searchSame then
			self["nowFireStatus" .. self.multiple] = completeArr

			if self.boomEffectNum == 0 and not self:checkBurstIsUse() then
				self:changeBtnsEnabled(true)

				if self.isAuto then
					self:autoCheckNext()
				else
					self:checkNoAutoLastOneGetAward()
				end
			end
		end
	end

	if not self.boomEffectNum then
		self.boomEffectNum = 0
	end

	self.boomEffectNum = self.boomEffectNum + 1

	xyd.SoundManager.get():playSound(xyd.SoundID.ACTIVITY_FIREWORK_BOOM)
	self["effectFire" .. index]:playWithEvent(self.effectStateNames[FireState.BOOM], 1, 1.9, {
		burst = function ()
			self:updateShowIndexItem(index, true)

			local transformPosition = self["fire" .. index].gameObject.transform.localPosition

			local function checkPlay(targetIndex)
				local effectName = self["effectFire" .. targetIndex]:getCurAction()

				if not self["effectFire" .. targetIndex]:getGameObject().activeSelf then
					effectName = ""
				end

				if effectName == self.effectStateNames[FireState.COMMON] then
					self:shakeEffect(targetIndex)
				end

				if (effectName == self.effectStateNames[FireState.COMMON] or effectName == self.effectStateNames[FireState.FIRE]) and effectName ~= self.effectStateNames[completeStatus[targetIndex]] then
					if completeStatus[targetIndex] == FireState.FIRE then
						self["effectFire" .. targetIndex]:play(self.effectStateNames[FireState.FIRE], 0)
					elseif completeStatus[targetIndex] == FireState.BOOM then
						local nextComplete = self.nextUpdateStates[boomTimes + 1]
						nextComplete = nextComplete or self.nextUpdateStates[boomTimes]

						self:onBoomFire(targetIndex, nextComplete, boomTimes + 1)
					end
				end
			end

			if index % 3 == 1 then
				local function playFun(effectData)
					effectData.effect:SetLocalPosition(transformPosition.x + 255, transformPosition.y + 55, transformPosition.z)
					effectData.effect:setRenderTarget(self.fireBurstCon, 10)
					effectData.effect:playWithEvent("texiao01", 1, 1.5, {
						burst1 = function ()
							local targetIndex = FireArrows[index].right[1]

							checkPlay(targetIndex)
						end,
						burst2 = function ()
							local targetIndex = FireArrows[index].right[2]

							checkPlay(targetIndex)
						end,
						Complete = function ()
							effectData.isUse = false

							checkOver()
						end
					})
				end

				self:getBurstEffect(playFun)
			elseif index % 3 == 2 then
				local function playFun1(effectData)
					effectData.effect:SetLocalPosition(transformPosition.x - 98, transformPosition.y + 55, transformPosition.z)
					effectData.effect:SetLocalScale(-1, 1, 1)
					effectData.effect:setRenderTarget(self.fireBurstCon, 10)
					effectData.effect:playWithEvent("texiao02", 1, 1.5, {
						burst1 = function ()
							local targetIndex = FireArrows[index].left[1]

							checkPlay(targetIndex)
						end,
						Complete = function ()
							effectData.isUse = false

							checkOver()
						end
					})
				end

				self:getBurstEffect(playFun1)

				local function playFun2(effectData)
					effectData.effect:SetLocalPosition(transformPosition.x + 39, transformPosition.y + 55, transformPosition.z)
					effectData.effect:setRenderTarget(self.fireBurstCon, 10)
					effectData.effect:playWithEvent("texiao02", 1, 1.5, {
						burst1 = function ()
							local targetIndex = FireArrows[index].right[1]

							checkPlay(targetIndex)
						end,
						Complete = function ()
							effectData.isUse = false

							checkOver()
						end
					})
				end

				self:getBurstEffect(playFun2)
			elseif index % 3 == 0 then
				local function playFun(effectData)
					effectData.effect:SetLocalPosition(transformPosition.x - 244, transformPosition.y + 55, transformPosition.z)
					effectData.effect:SetLocalScale(-1, 1, 1)
					effectData.effect:setRenderTarget(self.fireBurstCon, 10)
					effectData.effect:playWithEvent("texiao01", 1, 1.5, {
						burst1 = function ()
							local targetIndex = FireArrows[index].left[1]

							checkPlay(targetIndex)
						end,
						burst2 = function ()
							local targetIndex = FireArrows[index].left[2]

							checkPlay(targetIndex)
						end,
						Complete = function ()
							effectData.isUse = false

							checkOver()
						end
					})
				end

				self:getBurstEffect(playFun)
			end

			if math.ceil(index / 3) == 1 then
				local function playFun(effectData)
					effectData.effect:SetLocalPosition(transformPosition.x - 11, transformPosition.y - 173, transformPosition.z)
					effectData.effect:setLocalEulerAngles(0, 0, -90)
					effectData.effect:setRenderTarget(self.fireBurstCon, 10)
					effectData.effect:playWithEvent("texiao01", 1, 1.5, {
						burst1 = function ()
							local targetIndex = FireArrows[index].down[1]

							checkPlay(targetIndex)
						end,
						burst2 = function ()
							local targetIndex = FireArrows[index].down[2]

							checkPlay(targetIndex)
						end,
						Complete = function ()
							effectData.isUse = false

							checkOver()
						end
					})
				end

				self:getBurstEffect(playFun)
			elseif math.ceil(index / 3) == 2 then
				local function playFun1(effectData)
					effectData.effect:SetLocalPosition(transformPosition.x - 11, transformPosition.y + 112, transformPosition.z)
					effectData.effect:setLocalEulerAngles(0, 0, 90)
					effectData.effect:setRenderTarget(self.fireBurstCon, 90)
					effectData.effect:playWithEvent("texiao02", 1, 1.5, {
						burst1 = function ()
							local targetIndex = FireArrows[index].up[1]

							checkPlay(targetIndex)
						end,
						Complete = function ()
							effectData.isUse = false

							checkOver()
						end
					})
				end

				self:getBurstEffect(playFun1)

				local function playFun2(effectData)
					effectData.effect:SetLocalPosition(transformPosition.x - 11, transformPosition.y - 20, transformPosition.z)
					effectData.effect:setLocalEulerAngles(0, 0, -90)
					effectData.effect:setRenderTarget(self.fireBurstCon, 10)
					effectData.effect:playWithEvent("texiao02", 1, 1.5, {
						burst1 = function ()
							local targetIndex = FireArrows[index].down[1]

							checkPlay(targetIndex)
						end,
						Complete = function ()
							effectData.isUse = false

							checkOver()
						end
					})
				end

				self:getBurstEffect(playFun2)
			elseif math.ceil(index / 3) == 3 then
				local function playFun(effectData)
					effectData.effect:SetLocalPosition(transformPosition.x - 11, transformPosition.y + 274, transformPosition.z)
					effectData.effect:setLocalEulerAngles(0, 0, 90)
					effectData.effect:setRenderTarget(self.fireBurstCon, 10)
					effectData.effect:playWithEvent("texiao01", 1, 1.5, {
						burst1 = function ()
							local targetIndex = FireArrows[index].up[1]

							checkPlay(targetIndex)
						end,
						burst2 = function ()
							local targetIndex = FireArrows[index].up[2]

							checkPlay(targetIndex)
						end,
						Complete = function ()
							effectData.isUse = false

							checkOver()
						end
					})
				end

				self:getBurstEffect(playFun)
			end
		end,
		Complete = function ()
			self.boomEffectNum = self.boomEffectNum - 1

			checkOver()
		end
	})
end

function ActivityFirework:getBurstEffect(playFun)
	if not self.burstEffectArrs then
		self.burstEffectArrs = {}
	end

	local searchBurstEffect1 = nil

	for i, data in pairs(self.burstEffectArrs) do
		if data.isUse == false then
			searchBurstEffect1 = data
			data.isUse = true

			break
		end
	end

	if searchBurstEffect1 then
		searchBurstEffect1.effect:SetLocalScale(1, 1, 1)
		searchBurstEffect1.effect:setLocalEulerAngles(0, 0, 0)
		playFun(searchBurstEffect1)

		return
	end

	local effect = xyd.Spine.new(self.fireBurstCon.gameObject)

	effect:setInfo("fx_firework_burst", function ()
		searchBurstEffect1 = {
			isUse = true,
			effect = effect
		}

		searchBurstEffect1.effect:SetLocalScale(1, 1, 1)
		searchBurstEffect1.effect:setLocalEulerAngles(0, 0, 0)
		table.insert(self.burstEffectArrs, searchBurstEffect1)
		playFun(searchBurstEffect1)
	end)
end

function ActivityFirework:checkBurstIsUse()
	local isUse = false

	for i, data in pairs(self.burstEffectArrs) do
		if data.isUse then
			isUse = true

			break
		end
	end

	return isUse
end

function ActivityFirework:onClickFire(index)
	if self.activityData:getEndTime() <= xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))
		self:closeAuto()

		return
	end

	if self["nowFireStatus" .. self.multiple][index] == FireState.COMMON or self["nowFireStatus" .. self.multiple][index] == FireState.FIRE then
		if self.isPlaying then
			xyd.alertTips(__("FIREWORK_TEXT28"))

			return
		end

		if xyd.models.backpack:getItemNumByID(self.costItemId) < self.multiple then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.costItemId)))
			self:closeAuto()

			return
		end

		local function clickFun()
			self.clickFireId = index
			local params = json.encode({
				award_type = xyd.FireWorkAwardType.FIRE,
				mode = self.multiple,
				idx = index
			})

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FIREWORK, params)
		end

		local isCommon = false

		if not self.isAuto and self["nowFireStatus" .. self.multiple][index] == FireState.FIRE then
			for i, state in pairs(self["nowFireStatus" .. self.multiple]) do
				if state == FireState.COMMON then
					isCommon = true

					break
				end
			end
		end

		if isCommon then
			local timeStamp = xyd.db.misc:getValue("firework_click_fire_time_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				local params = {
					type = "firework_click_fire",
					wndType = self.curWindowType_,
					text = __("FIREWORK_TEXT29"),
					callback = function ()
						clickFun()
					end
				}

				if xyd.Global.lang == "zh_tw" then
					params.tipsHeight = 105
					params.tipsTextY = 51
					params.groupChooseY = -24
				elseif xyd.Global.lang == "fr_fr" then
					params.tipsHeight = 120
					params.tipsTextY = 54
					params.groupChooseY = -29
					params.tipsSpacingY = 0
				elseif xyd.Global.lang == "en_en" then
					params.tipsHeight = 100
					params.tipsTextY = 51.7
					params.groupChooseY = -28
					params.tipsSpacingY = 0
				elseif xyd.Global.lang == "ja_jp" then
					params.tipsHeight = 110
					params.tipsTextY = 50
					params.groupChooseY = -30.6
					params.tipsSpacingY = 3
				elseif xyd.Global.lang == "ko_kr" then
					params.tipsHeight = 80
					params.tipsTextY = 50
					params.groupChooseY = -24
				elseif xyd.Global.lang == "de_de" then
					params.tipsWidth = 550
					params.tipsHeight = 130
					params.tipsTextY = 45
					params.groupChooseY = -38
					params.tipsSpacingY = 0
				end

				xyd.openWindow("gamble_tips_window", params)
			else
				clickFun()
			end
		else
			clickFun()
		end

		return
	end

	if self["nowFireStatus" .. self.multiple][index] == FireState.BOOM then
		if self.isPlaying then
			xyd.alertTips(__("FIREWORK_TEXT28"))

			return
		end

		local params = json.encode({
			award_type = xyd.FireWorkAwardType.GET_AWARD,
			mode = self.multiple
		})

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FIREWORK, params)
	end
end

function ActivityFirework:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_FIREWORK then
		return
	end

	local data = xyd.decodeProtoBuf(event.data)
	local info = json.decode(data.detail)

	if info.award_type ~= xyd.FireWorkAwardType.SHOP then
		self.nextUpdateStates = {}
	end

	if info.award_type == xyd.FireWorkAwardType.FIRE then
		table.insert(self.nextUpdateStates, json.decode(info.statuses[1]))

		if #info.statuses > 1 then
			local checkIndex = 1

			while checkIndex <= #info.statuses do
				local checkArr = json.decode(info.statuses[checkIndex])
				local searchNum = 0

				for i in pairs(checkArr) do
					if #self.nextUpdateStates == 1 then
						if checkArr[i] ~= self["nowFireStatus" .. info.mode][i] and checkArr[i] == FireState.BOOM then
							searchNum = searchNum + 1
						end
					elseif checkArr[i] ~= self.nextUpdateStates[#self.nextUpdateStates - 1][i] and checkArr[i] == FireState.BOOM then
						searchNum = searchNum + 1
					end
				end

				if #self.nextUpdateStates == 1 and searchNum > 1 then
					table.insert(self.nextUpdateStates, json.decode(info.statuses[checkIndex + searchNum - 1]))

					checkIndex = checkIndex + searchNum - 1
				elseif #self.nextUpdateStates > 1 and searchNum > 0 then
					table.insert(self.nextUpdateStates, json.decode(info.statuses[checkIndex + searchNum]))

					checkIndex = checkIndex + searchNum
				else
					break
				end
			end
		end

		local newSelfBoomArr = {}

		for i, state in pairs(self["nowFireStatus" .. info.mode]) do
			table.insert(newSelfBoomArr, state)
		end

		newSelfBoomArr[self.clickFireId] = 2

		table.insert(self.nextUpdateStates, 1, newSelfBoomArr)

		local completeStatus = self.nextUpdateStates[2]
		completeStatus = completeStatus or self.nextUpdateStates[1]

		self:changeBtnsEnabled(false)
		self:onBoomFire(self.clickFireId, completeStatus, 2)
		self:updatePowerShow()
	elseif info.award_type == xyd.FireWorkAwardType.SHOP then
		-- Nothing
	elseif info.award_type == xyd.FireWorkAwardType.POWER then
		self:updatePowerShow()
	elseif info.award_type == xyd.FireWorkAwardType.GET_AWARD then
		self["nowFireStatus" .. info.mode] = self.activityData.detail["fire_" .. info.mode].status

		for i = 1, 9 do
			self["effectFire" .. i]:setAlpha(1)
		end

		local isNew = true

		for i, state in pairs(self.activityData.detail["fire_" .. info.mode].status) do
			if state ~= FireState.COMMON then
				isNew = false

				break
			end
		end

		local function newxUpdateFun()
			self:initFireState()
			self:updateCompleteLabel()
			self:updateMultipleBtnState()
			self:updatePowerShow()

			if isNew and self.isAuto and self.activityData.detail["fire_" .. self.multiple].is_powered == 1 then
				local needPowerNum = xyd.tables.miscTable:getNumber("firework_energy", "value") * self.multiple

				if needPowerNum <= self.activityData.detail.energy then
					local params = json.encode({
						award_type = xyd.FireWorkAwardType.POWER,
						mode = self.multiple
					})

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FIREWORK, params)
				end
			end
		end

		if isNew then
			self:showCompleteCon(info.mode, newxUpdateFun)
		else
			newxUpdateFun()
		end
	end
end

function ActivityFirework:changeBtnsEnabled(state)
	self.isPlaying = not state
	self.multipleBtnBoxCollider.enabled = state
	self.powerConBoxCollider.enabled = state
end

function ActivityFirework:updatePowerShow()
	local function playPower()
		local maxNum = xyd.tables.miscTable:getNumber("firework_energy", "value")

		if self.multiple == MultipleState.FIVE then
			maxNum = maxNum * MultipleState.FIVE
		end

		local curNum = tonumber(self.activityData.detail.energy)
		local isPowered = self.activityData.detail["fire_" .. self.multiple].is_powered
		self.progressLabel.text = curNum .. "/" .. maxNum
		local value = curNum / maxNum

		if value > 1 then
			value = 1
		end

		self.progressBarUIProgressBar.value = value

		if isPowered == 1 then
			if curNum < maxNum then
				self.powerEffectSpine:play("texiao01", 0)
			else
				self.powerEffectSpine:play("texiao02", 0)
			end
		elseif isPowered == 2 then
			self.powerEffectSpine:play("texiao03", 0)
		end
	end

	if not self.powerEffectSpine then
		self.powerEffectSpine = xyd.Spine.new(self.powerEffect.gameObject)

		self.powerEffectSpine:setInfo("fx_firework_energy", function ()
			self.powerEffectSpine:setRenderTarget(self.powerEffect, 10)
			playPower()
		end)
	else
		playPower()
	end
end

function ActivityFirework:showCompleteCon(mode, newxUpdateFun)
	self.completeShowCon.gameObject:SetActive(true)

	self.completeShowTextNum.text = __("FIREWORK_TEXT26", mode)

	self.completeShowTweenCon.gameObject:X(-950)

	local sequenceLeft = self:getSequence()

	sequenceLeft:Append(self.completeShowTweenCon.gameObject.transform:DOLocalMoveX(0, 0.5))
	sequenceLeft:AppendCallback(function ()
		sequenceLeft:Kill(false)

		if newxUpdateFun then
			newxUpdateFun()
		end

		self:waitForTime(1, function ()
			local sequenceRight = self:getSequence()

			sequenceRight:Append(self.completeShowTweenCon.gameObject.transform:DOLocalMoveX(950, 0.5))
			sequenceRight:AppendCallback(function ()
				sequenceLeft:Kill(false)

				if self.isShowAutoMultipleTips then
					local needCost = xyd.tables.miscTable:split2num("firework_ratio_5_unlock", "value", "|")

					xyd.alertConfirm(__("FIREWORK_TEXT30", needCost[1]), nil, __("SURE"))

					self.isShowAutoMultipleTips = false
				end

				self.completeShowCon.gameObject:SetActive(false)

				if self.isAuto then
					self:autoCheckNext()
				end
			end)
		end)
	end)
end

function ActivityFirework:shakeEffect(targetIndex)
	if not self["shakeTween" .. targetIndex] then
		self["shakeTween" .. targetIndex] = self:getSequence()

		local function setter1(value)
			self["fireEffect" .. targetIndex].gameObject.transform.localEulerAngles = Vector3(0, 0, value)
		end

		local function setter2(value)
			self["fireEffect" .. targetIndex].gameObject.transform.localEulerAngles = Vector3(0, 0, value)
		end

		local function setter3(value)
			self["fireEffect" .. targetIndex].gameObject.transform.localEulerAngles = Vector3(0, 0, value)
		end

		self["shakeTween" .. targetIndex]:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 15, 0.1):SetEase(DG.Tweening.Ease.Linear))
		self["shakeTween" .. targetIndex]:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 15, -15, 0.2):SetEase(DG.Tweening.Ease.Linear))
		self["shakeTween" .. targetIndex]:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), -15, 7, 0.1):SetEase(DG.Tweening.Ease.Linear))
		self["shakeTween" .. targetIndex]:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 7, -7, 0.08):SetEase(DG.Tweening.Ease.Linear))
		self["shakeTween" .. targetIndex]:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), -7, 0, 0.04):SetEase(DG.Tweening.Ease.Linear))
		self["shakeTween" .. targetIndex]:SetAutoKill(false)
		self["shakeTween" .. targetIndex]:Play()
	else
		self["shakeTween" .. targetIndex]:Restart()
	end
end

function ActivityFirework:dispose()
	if xyd.models.activity then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_FIREWORK)
	end

	ActivityFirework.super.dispose(self)
end

return ActivityFirework
