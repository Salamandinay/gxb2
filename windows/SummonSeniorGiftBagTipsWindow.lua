local BaseWindow = import(".BaseWindow")
local SummonSeniorGiftBagTipsWindow = class("SummonSeniorGiftBagTipsWindow", BaseWindow)

function SummonSeniorGiftBagTipsWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function SummonSeniorGiftBagTipsWindow:initWindow()
	SummonSeniorGiftBagTipsWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initModel()
	self:register()
	self:onRefresh()

	if xyd.Global.lang == "ko_kr" then
		for i = 1, self.partnerQty do
			self["checkNode" .. i]:X(0)
		end
	elseif xyd.Global.lang == "en_en" or xyd.Global.lang == "ja_jp" or xyd.Global.lang == "de_de" then
		for i = 1, self.partnerQty do
			self["checkNode" .. i]:X(-20)
		end
	end

	if xyd.Global.lang == "de_de" then
		self.checkNode1:X(-32)

		self.checkNode1:ComponentByName("checkBg", typeof(UISprite)).width = 215
	elseif xyd.Global.lang == "en_en" then
		self.checkNode1:X(12)

		self.checkNode1:ComponentByName("checkBg", typeof(UISprite)).width = 140
	elseif xyd.Global.lang == "ja_jp" then
		self.checkNode1:ComponentByName("checkBg", typeof(UISprite)).width = 190
	end
end

function SummonSeniorGiftBagTipsWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.Bg_ = groupAction:ComponentByName("Bg_", typeof(UISprite))
	self.timeLabel = groupAction:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel = groupAction:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.modelGroup = groupAction:NodeByName("modelGroup").gameObject
	local mainGroup = groupAction:NodeByName("mainGroup").gameObject
	self.titleLabel = mainGroup:ComponentByName("titleLabel", typeof(UILabel))
	self.progress = mainGroup:ComponentByName("progress", typeof(UISlider))
	self.progressLabel = mainGroup:ComponentByName("progress/labelDisplay", typeof(UILabel))
	self.timesLabel = mainGroup:ComponentByName("timesLabel", typeof(UILabel))
	self.probLabel = mainGroup:ComponentByName("probLabel", typeof(UILabel))
	self.showGroup = mainGroup:NodeByName("showGroup").gameObject
	local count = self.showGroup.transform.childCount

	for i = 1, count do
		local group = self.showGroup:NodeByName("group" .. i).gameObject
		self["groupArrowIcon" .. i] = group:ComponentByName("arrowIcon", typeof(UISprite))
		self["groupProbIcon" .. i] = group:ComponentByName("probIcon", typeof(UISprite))
		self["groupTimesNum" .. i] = group:ComponentByName("timesNum", typeof(UILabel))
		self["groupProbNum" .. i] = group:ComponentByName("probNum", typeof(UILabel))
	end

	self.helpBtn = mainGroup:NodeByName("helpBtn").gameObject
end

function SummonSeniorGiftBagTipsWindow:initUIComponent()
	self.endLabel.text = __("END_TEXT")
	local summonGiftData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_SUMMON_GIFTBAG)
	local CountDown = import("app.components.CountDown")

	CountDown.new(self.timeLabel, {
		duration = summonGiftData:getEndTime() - xyd.getServerTime()
	})

	self.titleLabel.text = __("WISH_GACHA_TEXT6")
	self.timesLabel.text = __("WISH_GACHA_NUM")
	self.probLabel.text = __("WISH_GACHA_CHANCE")
	local count = self.showGroup.transform.childCount

	for i = 1, count do
		self["groupTimesNum" .. i].text = __("WISH_GACHA_NUM" .. i)

		if i ~= count then
			self["groupProbNum" .. i].text = __("WISH_GACHA_NUM" .. tostring(i + 5))
		end
	end

	if xyd.getServerTime() < 1673568000 then
		xyd.setUISpriteAsync(self.Bg_, nil, "summon_senior_giftbag_bg002", nil, , true)
	else
		xyd.setUISpriteAsync(self.Bg_, nil, "summon_senior_giftbag_bg001", nil, , true)
		self.Bg_:Y(-32)

		local modelGroup = self.modelGroup:NodeByName("model_1").gameObject

		modelGroup:X(203)
	end

	self.indexText = {
		"PARTNER_PREVIEW_5",
		"PARTNER_PREVIEW_6",
		"PARTNER_PREVIEW_10"
	}
end

function SummonSeniorGiftBagTipsWindow:initModel()
	local partnerIDs_models = xyd.tables.miscTable:split2Cost("gacha_ensure_partner", "value", "|#")
	local partnerIDs_checks = xyd.tables.miscTable:split2Cost("gacha_ensure_partner_handbook", "value", "|#")
	self.modelIDs = {}
	self.partnerQty = #partnerIDs_models

	for num = 1, #partnerIDs_models do
		local partnerIDs_model = partnerIDs_models[num]
		local partnerIDs_check = partnerIDs_checks[num]
		local modelGroup = self.modelGroup:NodeByName("model_" .. num).gameObject
		local modelClickArea = modelGroup:NodeByName("platformBg_").gameObject
		local modelScoller = modelGroup:NodeByName("scroller_")

		for i = 1, 3 do
			self["model_tex" .. num .. i] = modelScoller:ComponentByName("model_" .. i, typeof(UITexture))
		end

		local leftArrow = modelGroup:NodeByName("leftArrow").gameObject
		local rightArrow = modelGroup:NodeByName("rightArrow").gameObject
		self["checkNode" .. num] = modelGroup:NodeByName("checkNode").gameObject
		local checkBtn = modelGroup:NodeByName("checkNode/checkBtn").gameObject
		local checkLabel = modelGroup:ComponentByName("checkNode/checkLabel", typeof(UILabel))
		local modelIDs = {}

		for i = 1, 3 do
			local model_tex = self["model_tex" .. num .. i]
			local modelID = xyd.tables.partnerTable:getModelID(partnerIDs_model[i])
			local modelName = xyd.tables.modelTable:getModelName(modelID)
			local scale = xyd.tables.modelTable:getScale(modelID)

			table.insert(modelIDs, {
				modelName = modelName,
				scale = scale,
				table_id = partnerIDs_check[i]
			})

			if i > 1 then
				self["model_tex" .. num .. i]:SetActive(false)
			end

			self["modelEffect" .. num .. i] = xyd.Spine.new(model_tex.gameObject)

			self["modelEffect" .. num .. i]:setInfo(modelName, function ()
				self["modelEffect" .. num .. i]:setRenderTarget(model_tex, 1)
				self["modelEffect" .. num .. i]:SetLocalScale(scale, scale, 1)
				self["modelEffect" .. num .. i]:play("idle", 0, 1)

				if i == 3 then
					self["hasDownLoad" .. num] = true
				end
			end)
		end

		checkLabel.text = xyd.tables.partnerTable:getName(partnerIDs_model[1])
		self.action = self:getSequence()
		self["index" .. num] = 1
		self.isMoving = false

		UIEventListener.Get(modelClickArea).onClick = function ()
			self:onClickModel(num)
		end

		UIEventListener.Get(checkBtn).onClick = function ()
			self:onClickModel(num)
		end

		UIEventListener.Get(leftArrow).onClick = function ()
			self:onClickArrow(num, -1)
		end

		UIEventListener.Get(rightArrow).onClick = function ()
			self:onClickArrow(num, 1)
		end

		table.insert(self.modelIDs, modelIDs)
	end
end

function SummonSeniorGiftBagTipsWindow:register()
	SummonSeniorGiftBagTipsWindow.super.register(self)

	UIEventListener.Get(self.helpBtn).onClick = function ()
		local partnerID = xyd.split(xyd.tables.miscTable:getVal("activity_gacha_partners"), "|", true)
		local partnerName = #partnerID == 1 and xyd.tables.partnerTable:getName(partnerID[1]) or __("A_OR_B", xyd.tables.partnerTable:getName(partnerID[1]), xyd.tables.partnerTable:getName(partnerID[2]))

		xyd.WindowManager.get():openWindow("help_window", {
			key = "GACHA_GUARANTEE_TEXT",
			values = {
				partnerName
			}
		})
	end
end

function SummonSeniorGiftBagTipsWindow:onRefresh()
	self.progress.value = self.params_.times / tonumber(__("WISH_GACHA_NUM5"))
	self.progressLabel.text = self.params_.times .. "/" .. __("WISH_GACHA_NUM5")
	local count = self.showGroup.transform.childCount

	for i = 1, count do
		if tonumber(__("WISH_GACHA_NUM" .. i)) <= tonumber(self.params_.times) then
			self["groupTimesNum" .. i].color = Color.New2(4210673663.0)
			self["groupTimesNum" .. i].effectColor = Color.New2(2941919999.0)
			self["groupProbNum" .. i].color = Color.New2(4210673663.0)

			xyd.setUISpriteAsync(self["groupArrowIcon" .. i], nil, "summon_senior_giftbag_icon2")
			xyd.setUISpriteAsync(self["groupProbIcon" .. i], nil, "summon_senior_giftbag_arrow2")
		else
			self["groupTimesNum" .. i].color = Color.New2(4278124287.0)
			self["groupTimesNum" .. i].effectColor = Color.New2(523263999)
			self["groupProbNum" .. i].color = Color.New2(4110352383.0)

			xyd.setUISpriteAsync(self["groupArrowIcon" .. i], nil, "summon_senior_giftbag_icon1")
			xyd.setUISpriteAsync(self["groupProbIcon" .. i], nil, "summon_senior_giftbag_arrow1")
		end
	end

	if tonumber(__("WISH_GACHA_NUM" .. count)) <= tonumber(self.params_.times) then
		xyd.setUISpriteAsync(self["groupProbIcon" .. count], nil, "summon_senior_giftbag_num")
	else
		xyd.setUISpriteAsync(self["groupProbIcon" .. count], nil, "summon_senior_giftbag_num2")
	end
end

function SummonSeniorGiftBagTipsWindow:onClickArrow(num, direct)
	if not self["hasDownLoad" .. num] or self.isMoving then
		return
	end

	self.isMoving = true
	local nowIndex = self["index" .. num]
	local nextIndex = (self["index" .. num] + 1) % 3
	local frontIndex = (self["index" .. num] - 1) % 3

	if nextIndex == 0 then
		nextIndex = 3
	end

	if frontIndex == 0 then
		frontIndex = 3
	end

	if direct > 0 then
		if not self["modelEffect" .. num .. nowIndex].spAnim and not self["modelEffect" .. num .. nextIndex].spAnim then
			return
		end

		self["model_tex" .. num .. nowIndex]:SetActive(false)
		self["model_tex" .. num .. nextIndex]:SetActive(true)
		self:waitForTime(0.3, function ()
			self["index" .. num] = nextIndex
			self.isMoving = false
		end)
	elseif direct < 0 then
		if not self["modelEffect" .. num .. nowIndex].spAnim and not self["modelEffect" .. num .. frontIndex].spAnim then
			return
		end

		self["model_tex" .. num .. nowIndex]:SetActive(false)
		self["model_tex" .. num .. frontIndex]:SetActive(true)
		self:waitForTime(0.3, function ()
			self["index" .. num] = frontIndex
			self.isMoving = false
		end)
	end
end

function SummonSeniorGiftBagTipsWindow:onClickModel(num)
	local table_id = self.modelIDs[num][self["index" .. num]].table_id
	local params = {
		partners = {
			{
				table_id = table_id
			}
		},
		table_id = table_id
	}

	xyd.WindowManager.get():openWindow("guide_detail_window", params)
end

return SummonSeniorGiftBagTipsWindow
