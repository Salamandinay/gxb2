local ActivityContent = import(".ActivityContent")
local OnlineAward = class("OnlineAward", ActivityContent)
local OnlineAwardItemIcon = class("OnlineAwardItemIcon", import("app.components.BaseComponent"))
local PngNum = import("app.components.PngNum")
local OnlineTable = xyd.tables.onlineTable
local Activity = xyd.models.activity

function OnlineAward:ctor(parentGO, params, parent)
	self.alphaDelta = 0.1

	ActivityContent.ctor(self, parentGO, params, parent)
end

function OnlineAward:getPrefabPath()
	return "Prefabs/Windows/activity/online_award"
end

function OnlineAward:getUIComponent()
	local go = self.go
	self.allUIWidget = self.go:GetComponent(typeof(UIWidget))
	self.group = go:NodeByName("e:Group").gameObject
	self.bgImg = self.group:NodeByName("bgImg").gameObject
	self.bgTriangle = self.group:ComponentByName("bgTriangle", typeof(UISprite))
	self.countDownTextImg = self.group:ComponentByName("countDownTextImg", typeof(UISprite))
	self.groupContent = self.group:ComponentByName("groupContent", typeof(UILayout))
	local groupContent = self.group:ComponentByName("groupContent", typeof(UIWidget))
	local group1 = groupContent:ComponentByName("group1", typeof(UIWidget))
	self.itemIcon_0Node = group1:NodeByName("itemIcon_0").gameObject
	self.itemIcon_1Node = group1:NodeByName("itemIcon_1").gameObject
	self.itemIcon_2Node = group1:NodeByName("itemIcon_2").gameObject
	local group2 = groupContent:ComponentByName("group2", typeof(UIWidget))
	self.itemIcon_3Node = group2:NodeByName("itemIcon_3").gameObject
	self.itemIcon_4Node = group2:NodeByName("itemIcon_4").gameObject
	self.itemIcon_5Node = group2:NodeByName("itemIcon_5").gameObject
	local group3 = groupContent:ComponentByName("group3", typeof(UIWidget))
	self.itemIcon_6Node = group3:NodeByName("itemIcon_6").gameObject
	self.itemIcon_7Node = group3:NodeByName("itemIcon_7").gameObject
	self.itemIcon_8Node = group3:NodeByName("itemIcon_8").gameObject
	local group4 = groupContent:ComponentByName("group4", typeof(UIWidget))
	self.itemIcon_9Node = group4:NodeByName("itemIcon_9").gameObject
	self.itemIcon_10Node = group4:NodeByName("itemIcon_10").gameObject
	self.itemIcon_11Node = group4:NodeByName("itemIcon_11").gameObject
	local group5 = groupContent:ComponentByName("group5", typeof(UIWidget))
	self.itemIcon_12Node = group5:NodeByName("itemIcon_12").gameObject
	self.itemIcon_13Node = group5:NodeByName("itemIcon_13").gameObject
	self.groupCountDown = self.group:ComponentByName("groupCountDown", typeof(UIWidget))
	self.countDownImg = self.groupCountDown:ComponentByName("e:Image", typeof(UISprite))
end

function OnlineAward:initUIComponent()
	xyd.setUISpriteAsync(self.countDownTextImg, nil, "online_award_countdown_" .. xyd.Global.lang, nil, , true)

	self.itemIcon_0 = OnlineAwardItemIcon.new(self.itemIcon_0Node)
	self.itemIcon_1 = OnlineAwardItemIcon.new(self.itemIcon_1Node)
	self.itemIcon_2 = OnlineAwardItemIcon.new(self.itemIcon_2Node)
	self.itemIcon_3 = OnlineAwardItemIcon.new(self.itemIcon_3Node)
	self.itemIcon_4 = OnlineAwardItemIcon.new(self.itemIcon_4Node)
	self.itemIcon_5 = OnlineAwardItemIcon.new(self.itemIcon_5Node)
	self.itemIcon_6 = OnlineAwardItemIcon.new(self.itemIcon_6Node)
	self.itemIcon_7 = OnlineAwardItemIcon.new(self.itemIcon_7Node)
	self.itemIcon_8 = OnlineAwardItemIcon.new(self.itemIcon_8Node)
	self.itemIcon_9 = OnlineAwardItemIcon.new(self.itemIcon_9Node)
	self.itemIcon_10 = OnlineAwardItemIcon.new(self.itemIcon_10Node)
	self.itemIcon_11 = OnlineAwardItemIcon.new(self.itemIcon_11Node)
	self.itemIcon_12 = OnlineAwardItemIcon.new(self.itemIcon_12Node)
	self.itemIcon_13 = OnlineAwardItemIcon.new(self.itemIcon_13Node)
end

function OnlineAward:resizeToParent()
	ActivityContent:resizeToParent()

	local parentPanel = self.go.transform.parent:GetComponent(typeof(UIPanel))
	local gap = (parentPanel.height - 865) * 0.1404494382022472 - 210

	self.bgTriangle:X(-(parentPanel.height / 867 * 320 - 145))
	self.bgTriangle:Y(-(parentPanel.height / 867 * 300 + 575))

	self.bgTriangle.height = 350 * 867 / parentPanel.height
	self.bgTriangle.width = 350 * 867 / parentPanel.height

	self.groupContent:Y(867 - parentPanel.height + 4 * (gap + 210))

	self.groupContent.gap = Vector2(0, gap)

	self.countDownTextImg:Y((867 - parentPanel.height) / 2 - 630)
	self.groupCountDown:X(-197 - self.scale_num_ * 20)
	self.groupCountDown:Y(-850 + self.scale_num_ * 100)
end

function OnlineAward:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initUIComponent()
	self:registerEvent(xyd.event.ONLINE_GET_AWARD, handler(self, self.onGetAward))
	self:updateContent()
	self:updateRedMark()
end

function OnlineAward:initAwards()
	local len = self.onlineTable:getLength()

	if self.curId > 0 then
		local curItem = self["itemIcon_" .. tostring(self.curId - 1)]

		curItem.countDownBg:SetActive(true)
	else
		self.curId = len + 1
	end

	local i = 0

	while len > i do
		local id = i + 1
		local award = self.onlineTable:getReward(id)
		local item = self["itemIcon_" .. tostring(i)]

		if id < self.curId then
			item.currentState = "get"

			item.imgMask:SetActive(true)
		end

		item:setInfo(award[1], award[2])

		i = i + 1
	end
end

function OnlineAward:onGetAward(event)
	print("award_call: " .. tostring(xyd.getServerTime()))

	local data = event.data
	local oldID = data.old_id
	local award = xyd.tables.onlineTable:getReward(oldID)

	self:itemFloat({
		{
			hideText = true,
			item_id = award[1],
			item_num = award[2]
		}
	})
	self:updateRedMark()

	local onlineInfo = xyd.models.selfPlayer:getOnlineInfo()

	if onlineInfo.id < 0 then
		Activity:get():updateFuncEntry(xyd.ActivityID.ONLINE_AWARD)
	end

	self.visibility:Pause()
	self.visibility:Append(xyd.getTweenAlpha(self.groupCountDown, 1, 0))

	local award_gotten = self["itemIcon_" .. tostring(oldID - 1)]

	award_gotten.imgMask:SetActive(true)
	award_gotten.countDownBg:SetActive(false)
	award_gotten.countDownBar:SetActive(false)
	award_gotten.eff:SetActive(false)
	self:updateContent()
end

function OnlineAward:updateRedMark()
	local data = Activity:updateRedMarkCount(xyd.ActivityID.ONLINE_AWARD, function ()
		local onlineInfo = xyd.models.selfPlayer:getOnlineInfo()
		local cd = OnlineTable:getCD(onlineInfo.id)

		if cd ~= nil then
			local duration = cd - xyd:getServerTime() + onlineInfo.time
			xyd.models.selfPlayer.isShowOnlineAwardRedMark = duration <= 0
		end

		xyd.models.selfPlayer.isShowOnlineAwardRedMark = false
	end)
end

function OnlineAward:updateContent()
	self.onlineTable = OnlineTable
	local onlineInfo = xyd.models.selfPlayer:getOnlineInfo()

	if onlineInfo and onlineInfo.id > 0 then
		self.curId = onlineInfo.id

		self:initAwards()

		local cd = OnlineTable:getCD(onlineInfo.id)
		local duration = cd - xyd:getServerTime() + onlineInfo.time

		if duration <= 0 then
			duration = 0
		end

		self.min = math.floor(duration / 60)
		self.second = math.floor(duration % 60)

		self:countDownStart()

		local curItem = self["itemIcon_" .. tostring(self.curId - 1)]
		curItem.currentState = "wait"

		curItem:startCountDown(cd - duration, cd)
	elseif onlineInfo and onlineInfo.id <= 0 then
		self.min = 0
		self.second = 0
		self.curId = onlineInfo.id

		self:addPngNum()
		self:initAwards()

		local len = self.onlineTable:getLength()
		local i = 0

		while len > i do
			local item = self["itemIcon_" .. tostring(i)]
			item.currentState = "get"
			i = i + 1
		end

		local main_win = xyd.WindowManager.get():getWindow("main_window")

		if main_win then
			main_win:CheckExtraActBtn(xyd.MAIN_LEFT_TOP_BTN_TYPE.QUESTION)
		end
	end
end

function OnlineAward:countDownStart()
	if self.min + self.second == 0 then
		self:lightStart()

		return
	end

	self:addPngNum()

	if self.timer then
		self.timer:Stop()
	end

	self.timer = self:getTimer(handler(self, self.onCountDown), 1, 1000)

	self.timer:Start()
end

function OnlineAward:onCountDown()
	if self.min + self.second == 0 then
		self:lightStart()

		return
	end

	self.second = self.second - 1

	if self.second < 0 then
		self.min = self.min - 1
		self.second = 59
	end

	self:addPngNum()
end

function OnlineAward:addPngNum()
	NGUITools.DestroyChildren(self.groupCountDown.transform)

	local pngNum = PngNum.new(self.groupCountDown.gameObject)
	local strNum = self:time2str(self.min, self.second)

	pngNum:setTimeNum({
		iconAtlas = "online_award_web",
		iconName = "online_award",
		num = strNum,
		gap = Vector2(-15, 0),
		gap2 = Vector2(-35, 0)
	})

	pngNum:getGameObject().transform.localEulerAngles = Vector3(0, 0, -45)
end

function OnlineAward:time2str(minNum, secondNum)
	local min = tostring(minNum)
	local rs = ""

	if #min < 2 then
		rs = tostring(rs) .. "0"
	end

	local i = 0

	while i < #min do
		rs = tostring(rs) .. tostring(string.sub(min, i + 1, i + 1))
		i = i + 1
	end

	rs = tostring(rs) .. "m"
	local second = tostring(secondNum)

	if #second < 2 then
		rs = tostring(rs) .. "0"
	end

	local i = 0

	while i < #second do
		rs = tostring(rs) .. tostring(string.sub(second, i + 1, i + 1))
		i = i + 1
	end

	return rs
end

function OnlineAward:lightStart()
	if self.timer then
		self.timer:Stop()
	end

	self:addPngNum()
	self:onLight()
	self:updateRedMark()
end

function OnlineAward:onLight()
	self.visibility = self:getSequence()

	self.visibility:Append(xyd.getTweenAlpha(self.groupCountDown, 0, 1))
	self.visibility:Append(xyd.getTweenAlpha(self.groupCountDown, 1, 1))
	self.visibility:SetLoops(-1)
end

function OnlineAwardItemIcon:ctor(parentGO)
	OnlineAwardItemIcon.super.ctor(self, parentGO)
end

function OnlineAwardItemIcon:getUIComponent()
	local go = self.go
	self.allUIWidget = self.go:GetComponent(typeof(UIWidget))
	self.eff = go:NodeByName("e:Group/eff").gameObject
	self.award = go:NodeByName("e:Group/award").gameObject
	self.countDownBg = go:NodeByName("e:Group/countDownBg").gameObject
	self.countDownBar = go:NodeByName("e:Group/award_slider/countDownBar").gameObject
	self.awardSlider = go:ComponentByName("e:Group/award_slider", typeof(UISlider))
	self.imgMask = go:ComponentByName("e:Group/imgMask", typeof(UISprite))
	self.touchField = go:NodeByName("e:Group/touchField").gameObject
end

function OnlineAwardItemIcon:initUIComponent()
end

function OnlineAwardItemIcon:initUI()
	OnlineAwardItemIcon.super.initUI(self)
	self:getUIComponent()
	self:initUIComponent()
end

function OnlineAwardItemIcon:getPrefabPath()
	return "Prefabs/Windows/activity/online_award_item_icon"
end

function OnlineAwardItemIcon:resetInfo()
end

function OnlineAwardItemIcon:setInfo(itemID, num)
	self:resetInfo()

	self.itemID = itemID
	local noClick = self.currentState == "get"
	local type = xyd.tables.itemTable:getType(itemID)
	local params = {
		scale = 0.7,
		itemID = self.itemID,
		num = num,
		noClick = noClick,
		uiRoot = self.award
	}

	if noClick == false and not xyd.GuideController.get():isPlayGuide() then
		self.touchField:SetActive(false)
	end

	if not self.awardItem then
		self.awardItem = xyd.getItemIcon(params)
	else
		self.awardItem:setInfo(params)
	end
end

function OnlineAwardItemIcon:startCountDown(curTime, sumTime)
	self.currentState = "wait"
	self.curTime = curTime
	self.sumTime = sumTime
	self.awardSlider.value = self.curTime / self.sumTime

	if self:canGetAward() then
		return
	end

	if self.timer then
		self.timer:Stop()
	end

	self.timer = self:getTimer(handler(self, self.onTime), 1, 1000)

	self.timer:Start()
end

function OnlineAwardItemIcon:canGetAward()
	if self.sumTime <= self.curTime then
		self:addEffect()
		self.touchField:SetActive(true)

		UIEventListener.Get(self.touchField).onClick = function ()
			self:getAward()
		end

		return true
	end

	return false
end

function OnlineAwardItemIcon:onTime()
	if self:canGetAward() then
		return
	end

	self.curTime = self.curTime + 1
	self.awardSlider.value = self.curTime / self.sumTime
end

function OnlineAwardItemIcon:getAward()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
	xyd.models.selfPlayer:getOnlineAward()

	UIEventListener.Get(self.touchField).onClick = nil

	self.touchField:SetActive(false)
end

function OnlineAwardItemIcon:addEffect()
	if not self.effect then
		self.effect = xyd.Spine.new(self.eff)

		self.effect:setInfo("fx_dajiangchuchang", function ()
			self.effect:play(nil, 0)
			self.effect:SetLocalScale(0.75, 0.75, 0)
		end)
	end
end

function OnlineAwardItemIcon:iosTestChangeUI()
	xyd.iosSetUISprite(self.imgMask:GetComponent(typeof(UISprite)), "online_award_get_award_ios_test")
	xyd.iosSetUISprite(self.countDownBar:GetComponent(typeof(UISprite)), "online_award_countdown_bg_2_ios_test")
	xyd.iosSetUISprite(self.countDownBg:GetComponent(typeof(UISprite)), "online_award_countdown_bg_1_ios_test")
end

function OnlineAward:iosTestChangeUI()
	local asyncBg = self.bgImg:GetComponent("AsyncUITexture")
	local girl = self.group:NodeByName("e:Image").gameObject
	local girlAsync = girl:GetComponent("AsyncUITexture")

	if asyncBg ~= nil then
		asyncBg.enabled = false
	end

	xyd.setUITextureAsync(self.bgImg:GetComponent(typeof(UITexture)), "Textures/texture_ios/online_award_bg_ios_test")

	if girlAsync ~= nil then
		girlAsync.enabled = false
	end

	xyd.setUITextureAsync(girl:GetComponent(typeof(UITexture)), "Textures/texture_ios/online_award_model_ios_test")

	for i = 1, 5 do
		xyd.iosSetUISprite(self.groupContent:ComponentByName("group" .. i .. "/groupBg_" .. tostring(i - 1), typeof(UISprite)), "online_award_group_bg_ios_test")
	end

	for i = 0, 13 do
		xyd.iosSetUISprite(self["itemIcon_" .. i .. "Node"]:GetComponent(typeof(UISprite)), "online_award_icon_bg_ios_test")
	end
end

return OnlineAward
