local ActivityFairyTaleMain = class("ActivityFairyTaleMain", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local CountDown = import("app.components.CountDown")

function ActivityFairyTaleMain:ctor(name, params)
	ActivityFairyTaleMain.super.ctor(self, name, params)
end

function ActivityFairyTaleMain:initWindow()
	ActivityFairyTaleMain.super.initWindow(self)
	self:getComponent()
	self:initTopGroup()
	self:regisetr()

	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)

	if not self.activityData_ or self.activityData_:checkRefreshActivity() then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.FAIRY_TALE)
	else
		self:onGetActivityInfo()
	end

	xyd.setUITextureByNameAsync(self.logoImg_, "activity_fairy_tale_logo_" .. xyd.Global.lang)

	self.shopBtnLabel_.text = __("EXCHANGE")

	for i = 1, 6 do
		self["mapTitle" .. i].text = __("ACTIVITY_FAIRY_TALE_MAP_" .. i)
	end
end

function ActivityFairyTaleMain:initTopGroup()
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	if not self.windowTop_ then
		self.windowTop_ = WindowTop.new(self.window_, self.name_)
	end

	self.windowTop_:setItem(items)
end

function ActivityFairyTaleMain:regisetr()
	ActivityFairyTaleMain.super.register(self)

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_FAIRY_TALE_MAIN_HELP"
		})
	end

	UIEventListener.Get(self.rankBtn_).onClick = function ()
		if self.hasGetData_ then
			xyd.openWindow("rank_window", {
				mapType = xyd.MapType.ACTIVITY_FAIRT_TALE
			})
		end
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_fairy_tale_gift_preview_window", {})
	end

	UIEventListener.Get(self.shopBtn_).onClick = function ()
		if self.hasGetData_ then
			xyd.WindowManager.get():openWindow("activity_fairy_tale_shop_window", {})
		end
	end

	for i = 1, 6 do
		UIEventListener.Get(self["mapBtnSprit" .. i].gameObject).onClick = function ()
			if self.hasGetData_ then
				self:onClickMapIcon(i)
			end
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onGetActivityInfo))
end

function ActivityFairyTaleMain:getComponent()
	local winTrans = self.window_:NodeByName("content")
	self.logoImg_ = winTrans:ComponentByName("logoRoot/logoImg", typeof(UITexture))
	self.helpBtn_ = winTrans:NodeByName("btnRoot/helpBtn").gameObject
	self.awardBtn_ = winTrans:NodeByName("btnRoot/awardBtn").gameObject
	self.rankBtn_ = winTrans:NodeByName("btnRoot/rankBtn").gameObject
	self.shopBtn_ = winTrans:NodeByName("btnRoot/shopBtn").gameObject
	self.cloudImg1_ = winTrans:NodeByName("cloud1").gameObject
	self.cloudImg2_ = winTrans:NodeByName("cloud2").gameObject
	self.cloudImg3_ = winTrans:NodeByName("cloud3").gameObject
	self.shopBtnLabel_ = winTrans:ComponentByName("btnRoot/shopBtn/label", typeof(UILabel))
	self.effectGroup_ = winTrans:NodeByName("effectGroup").gameObject
	self.timeRoot_ = winTrans:NodeByName("logoRoot/logoImg/timeRoot")
	self.endTimeTips_ = winTrans:ComponentByName("logoRoot/logoImg/timeRoot/endTimeTips", typeof(UILabel))
	self.endTimeLable_ = winTrans:ComponentByName("logoRoot/logoImg/timeRoot/endTimeLable", typeof(UILabel))

	for i = 1, 6 do
		self["mapBtn" .. i] = winTrans:NodeByName("mapGroup/mapItem" .. i).gameObject
		self["mapBtnSprit" .. i] = self["mapBtn" .. i]:ComponentByName("e:image", typeof(UISprite))
		self["mapBtnShadow" .. i] = self["mapBtn" .. i]:NodeByName("shadow").gameObject
		self["titleBg" .. i] = self["mapBtn" .. i]:NodeByName("titleBg").gameObject
		self["progressBg" .. i] = self["mapBtn" .. i]:NodeByName("progressBg").gameObject
		self["mapTitle" .. i] = self["mapBtn" .. i]:ComponentByName("titleBg/titleLabel", typeof(UILabel))
		self["mapProgressNum" .. i] = self["mapBtn" .. i]:ComponentByName("progressBg/progressLabel", typeof(UILabel))
	end

	if xyd.Global.lang == "zh_tw" then
		self.timeRoot_:X(20)
	elseif xyd.Global.lang == "en_en" then
		self.timeRoot_:X(20)
	elseif xyd.Global.lang == "ja_jp" then
		self.timeRoot_:X(20)
	elseif xyd.Global.lang == "fr_fr" then
		self.timeRoot_:X(0)
	end
end

function ActivityFairyTaleMain:onClickMapIcon(index)
	if self:checkCanOpen(index) then
		xyd.WindowManager.get():openWindow("activity_fairy_tale_map", {
			index = index
		})
	else
		xyd.showToast(__("FAIRY_TALE_MAP_LOCK"))
	end
end

function ActivityFairyTaleMain:checkCanOpen(index)
	local selfId = tonumber(self.activityData_.detail.map_id)
	local canGoIds = self.activityData_.detail.map_infos[tonumber(selfId)].unlock_ids
	local canGo = string.find(canGoIds, tostring(index))

	if canGo and canGo > 0 then
		return true
	else
		return false
	end
end

function ActivityFairyTaleMain:onGetActivityInfo(event)
	self.hasGetData_ = true
	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)
	local endTime = self.activityData_:getEndTime()
	self.endTimeTips_.text = __("END_TEXT")
	local params = {
		callback = function ()
			xyd.WindowManager.get():closeWindow(self.name_)
		end,
		duration = endTime - xyd.getServerTime()
	}

	if not self.labelEndTime_ then
		self.labelEndTime_ = CountDown.new(self.endTimeLable_, params)
	else
		self.labelEndTime_:setInfo(params)
	end

	for i = 1, 6 do
		local cellNum = xyd.tables.activityFairyTaleCellTable:getMapCellNum(i)
		self["mapProgressNum" .. i].text = (self.activityData_.detail.map_infos[i].complete_num or 1) .. "/" .. cellNum
		local canOpen = self:checkCanOpen(i)

		if not canOpen then
			xyd.applyGrey(self["mapBtnSprit" .. i])
		else
			xyd.applyOrigin(self["mapBtnSprit" .. i])
		end
	end
end

function ActivityFairyTaleMain:playOpenAnimation(callback)
	ActivityFairyTaleMain.super.playOpenAnimation(self, function ()
		local storyIndex = xyd.db.misc:getValue("activity_fairy_tale_story")

		if not storyIndex or tonumber(storyIndex) ~= 1 then
			local plotid = xyd.tables.miscTable:getVal("activity_fairytale_first_plot")

			xyd.WindowManager.get():openWindow("story_window", {
				story_type = xyd.StoryType.ACTIVITY,
				story_id = tonumber(plotid),
				callback = function ()
					xyd.db.misc:setValue({
						value = 1,
						key = "activity_fairy_tale_story"
					})
					xyd.WindowManager.get():openWindow("activity_fairy_tale_main", {})
				end
			})
			xyd.WindowManager.get():closeWindow("activity_fairy_tale_main")
		else
			self.effect_ = xyd.Spine.new(self.effectGroup_)

			self.effect_:setInfo("fairytale_window", function ()
				self:waitForFrame(1, function ()
					local seq1 = self:getSequence()

					seq1:OnComplete(function ()
						seq1:Kill(true)
					end)

					local function setter1(value)
						self.logoImg_:GetComponent(typeof(UIWidget)).alpha = value
					end

					seq1:Insert(0, self.logoImg_.transform:DOScale(Vector3(1.2, 0.8, 1), 0.167))
					seq1:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.16))
					seq1:Insert(0.167, self.logoImg_.transform:DOScale(Vector3(0.98, 1.06, 1), 0.334))
					seq1:Insert(0.334, self.logoImg_.transform:DOScale(Vector3(1.02, 0.97, 1), 0.5))
					seq1:Insert(0.5, self.logoImg_.transform:DOScale(Vector3(1, 1, 1), 0.667))

					local seq2 = self:getSequence()

					local function setter2(value)
						self.shopBtn_:GetComponent(typeof(UISprite)).alpha = value
					end

					self.shopBtn_.transform.localScale = Vector3(1.1, 0, 0)

					seq2:Insert(0.13, self.shopBtn_.transform:DOScale(Vector3(0.93, 1.05, 1), 0.296))
					seq2:Insert(0.13, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.296))
					seq1:Insert(0.296, self.shopBtn_.transform:DOScale(Vector3(1.03, 0.96, 1), 0.462))
					seq1:Insert(0.462, self.shopBtn_.transform:DOScale(Vector3(0.98, 1.02, 1), 0.628))
					seq1:Insert(0.628, self.shopBtn_.transform:DOScale(Vector3(1, 1, 1), 0.794))
					seq2:OnComplete(function ()
						seq2:Kill(true)
					end)

					local seq3 = self:getSequence()

					local function setter3(value)
						self.helpBtn_:GetComponent(typeof(UISprite)).alpha = value
					end

					self.helpBtn_.transform.localScale = Vector3(0.2, 0.2, 0.2)

					seq3:Insert(0.167, self.helpBtn_.transform:DOScale(Vector3(1.08, 1.08, 1), 0.336))
					seq3:Insert(0.167, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 0.336))
					seq3:Insert(0.336, self.helpBtn_.transform:DOScale(Vector3(0.96, 0.96, 1), 0.53))
					seq3:Insert(0.53, self.helpBtn_.transform:DOScale(Vector3(1, 1, 1), 0.7))
					seq3:OnComplete(function ()
						seq3:Kill(true)
					end)

					local seq4 = self:getSequence()

					local function setter4(value)
						self.awardBtn_:GetComponent(typeof(UISprite)).alpha = value
					end

					seq4:OnComplete(function ()
						seq4:Kill(true)
					end)

					self.awardBtn_.transform.localScale = Vector3(0.2, 0.2, 0.2)

					seq4:Insert(0.227, self.awardBtn_.transform:DOScale(Vector3(1.08, 1.08, 1), 0.396))
					seq4:Insert(0.227, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter4), 0, 1, 0.396))
					seq4:Insert(0.396, self.awardBtn_.transform:DOScale(Vector3(0.96, 0.96, 1), 0.59))
					seq4:Insert(0.59, self.awardBtn_.transform:DOScale(Vector3(1, 1, 1), 0.76))

					local seq5 = self:getSequence()

					local function setter5(value)
						self.rankBtn_:GetComponent(typeof(UISprite)).alpha = value
					end

					self.rankBtn_.transform.localScale = Vector3(0.2, 0.2, 0.2)

					seq5:Insert(0.287, self.rankBtn_.transform:DOScale(Vector3(1.08, 1.08, 1), 0.456))
					seq5:Insert(0.287, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter5), 0, 1, 0.456))
					seq5:Insert(0.496, self.rankBtn_.transform:DOScale(Vector3(0.96, 0.96, 1), 0.65))
					seq5:Insert(0.65, self.rankBtn_.transform:DOScale(Vector3(1, 1, 1), 0.82))
					seq5:OnComplete(function ()
						seq5:Kill(true)
					end)

					local titleList = {
						3,
						4,
						6,
						5,
						2,
						1
					}

					for idx, id in ipairs(titleList) do
						local seq = self:getSequence()

						seq:OnComplete(function ()
							seq:Kill(true)
						end)

						local titleBg = self["titleBg" .. id]
						local progressBg = self["progressBg" .. id]

						local function setter(value)
							titleBg:GetComponent(typeof(UISprite)).alpha = value
						end

						local function setter_(value)
							progressBg:GetComponent(typeof(UISprite)).alpha = value
						end

						seq:Insert(0.16666666666666666 + 0.06666666666666667 * (idx - 1), titleBg.transform:DOScale(Vector3(1.05, 1, 1), 0.5333333333333333 + 0.06666666666666667 * (idx - 1)))
						seq:Insert(0.16666666666666666 + 0.06666666666666667 * (idx - 1), DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.4 + 0.06666666666666667 * (idx - 1)))
						seq:Insert(0.5333333333333333 + 0.06666666666666667 * (idx - 1), titleBg.transform:DOScale(Vector3(1, 1, 1), 0.7 + 0.06666666666666667 * (idx - 1)))
						seq:Insert(0.3 + 0.06666666666666667 * (idx - 1), progressBg.transform:DOScale(Vector3(1, 1, 1), 0.5333333333333333 + 0.06666666666666667 * (idx - 1)))
						seq:Insert(0.3 + 0.06666666666666667 * (idx - 1), DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter_), 0, 1, 0.4 + 0.06666666666666667 * (idx - 1)))
						seq:Insert(0.5333333333333333 + 0.06666666666666667 * (idx - 1), progressBg.transform:DOScale(Vector3(1, 1, 1), 0.7 + 0.06666666666666667 * (idx - 1)))
					end

					self:waitForTime(1.2, function ()
						for i = 1, 3 do
							self["cloudImg" .. i .. "_"]:SetActive(true)
						end
					end)
					self.effect_:play("texiao01", 1, 1, function ()
						for i = 1, 6 do
							self["mapBtnSprit" .. i].gameObject:SetActive(true)
							self["mapBtnShadow" .. i]:SetActive(true)
						end

						self.effect_:SetActive(false)
					end)
				end)
			end)
		end

		if callback then
			callback()
		end
	end)
end

return ActivityFairyTaleMain
