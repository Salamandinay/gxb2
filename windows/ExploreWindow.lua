local ExploreWindow = class("ExploreWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local exploreModel = xyd.models.exploreModel

function ExploreWindow:ctor(name, params)
	ExploreWindow.super.ctor(self, name, params)
end

function ExploreWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ExploreWindow:getUIComponent()
	local groupMain = self.window_:NodeByName("groupMain").gameObject
	self.groupMain = groupMain
	self.effectNode = groupMain:NodeByName("effectNode").gameObject
	self.effectNode1 = groupMain:NodeByName("effectNode1").gameObject
	self.trainingRoom = groupMain:NodeByName("training_room").gameObject
	self.trainingRoomLevelUpImg = self.trainingRoom:NodeByName("levelUp").gameObject
	self.trainingRoomLabel = self.trainingRoom:ComponentByName("labelName", typeof(UILabel))
	self.trainingRoomEffectNode = self.trainingRoom:NodeByName("effectNode").gameObject
	self.market = groupMain:NodeByName("market").gameObject
	self.marketLevelUpImg = self.market:NodeByName("levelUp").gameObject
	self.marketLabel = self.market:ComponentByName("labelName", typeof(UILabel))
	self.marketGetAward = self.market:ComponentByName("getAward", typeof(UISprite))
	self.marketAwardImg = self.marketGetAward:ComponentByName("iconImg", typeof(UISprite))
	self.marketEffectNode = self.market:NodeByName("effectNode").gameObject
	self.breadHome = groupMain:NodeByName("bread_home").gameObject
	self.breadHomeLevelUpImg = self.breadHome:NodeByName("levelUp").gameObject
	self.breadHomeLabel = self.breadHome:ComponentByName("labelName", typeof(UILabel))
	self.breadHomeGetAward = self.breadHome:ComponentByName("getAward", typeof(UISprite))
	self.breadHomeAwardImg = self.breadHomeGetAward:ComponentByName("iconImg", typeof(UISprite))
	self.breadHomeEffectNode = self.breadHome:NodeByName("effectNode").gameObject
	self.wishingTree = groupMain:NodeByName("wishing_tree").gameObject
	self.wishingTreeLevelUpImg = self.wishingTree:NodeByName("levelUp").gameObject
	self.wishingTreeLabel = self.wishingTree:ComponentByName("labelName", typeof(UILabel))
	self.wishingTreeGetAward = self.wishingTree:ComponentByName("getAward", typeof(UISprite))
	self.wishingTreeAwardImg = self.wishingTreeGetAward:ComponentByName("iconImg", typeof(UISprite))
	self.wishingTreeEffectNode1 = self.wishingTree:NodeByName("effectNode1").gameObject
	self.wishingTreeEffectNode2 = self.wishingTree:NodeByName("effectNode2").gameObject
	self.adventure = groupMain:NodeByName("adventure").gameObject
	self.adventureLevelUpImg = self.adventure:NodeByName("levelUp").gameObject
	self.adventureLabel = self.adventure:ComponentByName("labelName", typeof(UILabel))
	self.adventureEffectNode = self.adventure:NodeByName("effectNode").gameObject
	self.adventureRedPoint = self.adventure:NodeByName("redPoint").gameObject
	self.getAllBtn = groupMain:NodeByName("getAllBtn").gameObject
	self.getAllBtnLabel = self.getAllBtn:ComponentByName("btnLabel", typeof(UILabel))
	self.getAllBtnRedPoint = self.getAllBtn:NodeByName("redPoint").gameObject
	self.helpBtn = groupMain:NodeByName("helpBtn").gameObject
end

function ExploreWindow:playOpenAnimation(callback)
	if xyd.GuideController.get():isPlayGuide() then
		self:setWndComplete()
		callback()

		return
	end

	self.windowTop:SetActive(false)
	self.helpBtn:SetActive(false)
	self.getAllBtn:SetActive(false)
	self.marketGetAward:SetActive(false)
	self.breadHomeGetAward:SetActive(false)
	self.wishingTreeGetAward:SetActive(false)

	local sequence = self:getSequence(function ()
		self:setWndComplete()
		callback()
	end)

	self.groupMain:SetLocalScale(1.5, 1.5, 1.5)
	sequence:Append(self.groupMain.transform:DOScale(1, 1.5))
	sequence:AppendCallback(function ()
		sequence:Kill(false)

		sequence = nil

		self.windowTop:SetActive(true)
		self.helpBtn:SetActive(true)
		self.getAllBtn:SetActive(true)
		self.marketGetAward:SetActive(true)
		self.breadHomeGetAward:SetActive(true)
		self.wishingTreeGetAward:SetActive(true)
	end)

	local effect = xyd.Spine.new(self.effectNode1)

	effect:setInfo("travel_fog", function ()
		effect:play("texiao01", 1)
	end)
end

function ExploreWindow:layout()
	self.trainingRoomLabel.text = __("TRAVEL_BUILDING_NAME4")
	self.marketLabel.text = __("TRAVEL_BUILDING_NAME1")
	self.breadHomeLabel.text = __("TRAVEL_BUILDING_NAME3")
	self.wishingTreeLabel.text = __("TRAVEL_BUILDING_NAME2")
	self.adventureLabel.text = __("TRAVEL_BUILDING_NAME5")
	self.getAllBtnLabel.text = __("TRAVEL_MAIN_TEXT01")

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.EXPLORE_TRAINING_LV_UP, self.trainingRoomLevelUpImg)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.EXPLORE_MARKET_LV_UP, self.marketLevelUpImg)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.EXPLORE_BREAD_LV_UP, self.breadHomeLevelUpImg)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.EXPLORE_WISHING_LV_UP, self.wishingTreeLevelUpImg)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.EXPLORE_ADVENTURE_LV_UP, self.adventureLevelUpImg)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.EXPLORE_ADVENTURE_BOX_CAN_OPEN, self.adventureRedPoint)
	self:initTopGroup()
	self:updateAwardImg()

	local effect1 = xyd.Spine.new(self.effectNode)

	effect1:setInfo("travel_main", function ()
		effect1:play("travel_main_01", 0)
		effect1:SetLocalScale(1.5, 1.5, 1.5)
	end)

	local effectT = xyd.Spine.new(self.trainingRoomEffectNode)

	effectT:setInfo("travel_main", function ()
		effectT:SetLocalScale(1.5, 1.5, 1.5)
		effectT:play("travel_main_02", 1, 1, function ()
			self:circulateSpine(effectT, "travel_main_02", 12, false)
		end)
	end, true)

	local effectM = xyd.Spine.new(self.marketEffectNode)

	effectM:setInfo("travel_main", function ()
		effectM:play("travel_main_03", 0)
		effectM:SetLocalScale(1.5, 1.5, 1.5)
	end)

	local effectW1 = xyd.Spine.new(self.wishingTreeEffectNode1)

	effectW1:setInfo("travel_main", function ()
		effectW1:play("travel_main_05", 0)
		effectW1:SetLocalScale(1.5, 1.5, 1.5)
	end)

	local effectW2 = xyd.Spine.new(self.wishingTreeEffectNode2)

	effectW2:setInfo("travel_main", function ()
		effectW2:play("travel_main_06", 0)
		effectW2:SetLocalScale(1.5, 1.5, 1.5)
	end)

	local effectB = xyd.Spine.new(self.breadHomeEffectNode)

	effectB:setInfo("travel_main", function ()
		effectB:SetLocalScale(1.5, 1.5, 1.5)
		effectB:play("travel_main_04", 1, 1, function ()
			self:circulateSpine(effectB, "travel_main_04", 12, true)
		end)
	end, true)

	local effectA = xyd.Spine.new(self.adventureEffectNode)

	effectA:setInfo("travel_main", function ()
		effectA:play("travel_main_07", 0)
		effectA:SetLocalScale(1.5, 1.5, 1.5)
	end)

	local sequence1 = self:getSequence()

	self:circulateAnimation(sequence1, self.marketAwardImg.transform)

	local sequence2 = self:getSequence()

	self:circulateAnimation(sequence2, self.wishingTreeAwardImg.transform)

	local sequence3 = self:getSequence()

	self:circulateAnimation(sequence3, self.breadHomeAwardImg.transform)
end

function ExploreWindow:circulateSpine(effectObj, action, lastTime, needStop)
	self:waitForTime(lastTime, function ()
		if effectObj and effectObj.go then
			effectObj:setPlayNeedStop(needStop)
			effectObj:play(action, 1, 1, function ()
				self:circulateSpine(effectObj, action, lastTime, needStop)
			end)
		end
	end)
end

function ExploreWindow:circulateAnimation(sequence, spriteTrans)
	sequence:Append(spriteTrans:DOScale(1.1, 0.8))
	sequence:Append(spriteTrans:DOScale(0.98, 0.8))
	sequence:SetLoops(-1)
end

function ExploreWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			show_tips = true,
			hidePlus = true,
			id = xyd.ItemID.BLUE_CRYSTAL
		},
		{
			show_tips = true,
			hidePlus = true,
			id = xyd.ItemID.SUPER_WOOD
		},
		{
			show_tips = false,
			hidePlus = false,
			id = xyd.ItemID.DELICIOUS_BREAD,
			callback = function ()
				xyd.WindowManager.get():openWindow("explore_source_buy_window")
			end
		}
	}

	self.windowTop:setItem(items)

	self.guideBreadItem = self.windowTop.resItemList[1].go
end

function ExploreWindow:updateAwardImg()
	local facCD = xyd.split(xyd.tables.miscTable:getVal("travel_facility_cd"), "|", true)
	local buildingsInfo = exploreModel:getBuildsInfo()
	local buildingTables = {
		xyd.tables.exploreMarketTable,
		xyd.tables.exploreWishingTreeTable,
		xyd.tables.exploreBreadHomeTable
	}
	local buildingAwardsGroup = {
		{
			self.marketGetAward,
			self.marketAwardImg
		},
		{
			self.wishingTreeGetAward,
			self.wishingTreeAwardImg
		},
		{
			self.breadHomeGetAward,
			self.breadHomeAwardImg
		}
	}

	for i = 1, 3 do
		local info = buildingsInfo[i]
		local bTable = buildingTables[i]
		local outPut = bTable:getOutput(info.level)
		local outPutNum = tonumber(outPut[2])
		local stayNum = bTable:getStayMax(info.level)

		for j in ipairs(info.partners) do
			local partnerID = info.partners[j]

			if partnerID and partnerID ~= 0 then
				local star = xyd.models.slot:getPartner(partnerID).star

				if j % 2 ~= 0 then
					outPutNum = outPutNum * (1 + xyd.tables.exploreFacilityAddTable:getOutAdd(i, star) / 100)
				else
					stayNum = stayNum * (1 + xyd.tables.exploreFacilityAddTable:getStayAdd(i, star) / 100)
				end
			end
		end

		local cd = facCD[i]
		local duration = xyd.getServerTime() - info.updateTime
		local count = math.floor(duration / cd)
		local hasNum = math.floor(count * outPutNum / (86400 / cd) + info.stock)

		if hasNum > 0 then
			self["canGetAward" .. i] = true

			buildingAwardsGroup[i][1]:SetActive(true)
			xyd.setUISpriteAsync(buildingAwardsGroup[i][2], nil, "icon_" .. outPut[1])

			if hasNum < stayNum then
				xyd.setUISpriteAsync(buildingAwardsGroup[i][1], nil, "btn_get_img_1")
			else
				xyd.setUISpriteAsync(buildingAwardsGroup[i][1], nil, "btn_get_img_2")
			end
		else
			self["canGetAward" .. i] = false

			buildingAwardsGroup[i][1]:SetActive(false)
		end
	end

	self:updateAwardRedMark()
end

function ExploreWindow:updateAwardRedMark()
	local flag = false

	for i = 1, 3 do
		flag = flag or self["canGetAward" .. i]
	end

	self.getAllBtnRedPoint:SetActive(flag)
end

function ExploreWindow:getAward(index)
	if index == 0 then
		exploreModel:reqBuildingsOutPut({
			1,
			2,
			3
		})
	else
		exploreModel:reqBuildingsOutPut({
			index
		})
	end
end

function ExploreWindow:onAward(event)
	xyd.models.itemFloatModel:pushNewItems(event.data.items)

	local ids = event.data.ids
	local buildingAwards = {
		self.marketGetAward,
		self.wishingTreeGetAward,
		self.breadHomeGetAward
	}

	for _, id in ipairs(ids) do
		buildingAwards[id]:SetActive(false)

		self["canGetAward" .. id] = false
	end

	self:updateAwardRedMark()
end

function ExploreWindow:registerEvent()
	UIEventListener.Get(self.trainingRoom).onClick = function ()
		self.windowTop.resItemGroup:SetActive(false)
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.WindowManager.get():openWindow("explore_training_room_window", {
			closeCallBack = function ()
				local wnd = xyd.WindowManager.get():getWindow("explore_window")

				if wnd then
					wnd.windowTop.resItemGroup:SetActive(true)
				end
			end
		})
	end

	UIEventListener.Get(self.market).onClick = function ()
		self.windowTop.resItemGroup:SetActive(false)
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.WindowManager.get():openWindow("explore_market_window", {
			closeCallBack = function ()
				local wnd = xyd.WindowManager.get():getWindow("explore_window")

				if wnd then
					wnd.windowTop.resItemGroup:SetActive(true)
				end
			end
		})
	end

	UIEventListener.Get(self.breadHome).onClick = function ()
		self.windowTop.resItemGroup:SetActive(false)
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.WindowManager.get():openWindow("explore_bread_home_window", {
			closeCallBack = function ()
				local wnd = xyd.WindowManager.get():getWindow("explore_window")

				if wnd then
					wnd.windowTop.resItemGroup:SetActive(true)
				end
			end
		})
	end

	UIEventListener.Get(self.wishingTree).onClick = function ()
		self.windowTop.resItemGroup:SetActive(false)
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.WindowManager.get():openWindow("explore_wishing_tree_window", {
			closeCallBack = function ()
				local wnd = xyd.WindowManager.get():getWindow("explore_window")

				if wnd then
					wnd.windowTop.resItemGroup:SetActive(true)
				end
			end
		})
	end

	UIEventListener.Get(self.adventure).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self.windowTop.resItemGroup:SetActive(false)
		xyd.WindowManager.get():openWindow("explore_adventure_window", {
			closeCallBack = function ()
				local wnd = xyd.WindowManager.get():getWindow("explore_window")

				if wnd then
					wnd.windowTop.resItemGroup:SetActive(true)
				end
			end
		})
	end

	UIEventListener.Get(self.marketGetAward.gameObject).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:getAward(1)
	end

	UIEventListener.Get(self.wishingTreeGetAward.gameObject).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:getAward(2)
	end

	UIEventListener.Get(self.breadHomeGetAward.gameObject).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:getAward(3)
	end

	UIEventListener.Get(self.getAllBtn).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		local flag = false

		for i = 1, 3 do
			flag = flag or self["canGetAward" .. i]
		end

		if flag then
			self:getAward(0)
		else
			xyd.showToast(__("TRAVEL_MAIN_TEXT45"))
		end
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("explore_help_window", {
			key = "TRAVEL_MAIN_HELP"
		})
	end

	self.eventProxy_:addEventListener(xyd.event.EXPLORE_BUILDING_GET_OUT, handler(self, self.onAward))
	self.eventProxy_:addEventListener(xyd.event.EXPLORE_BUY_BREAD, handler(self, self.onBuyBread))
end

function ExploreWindow:onBuyBread(event)
	xyd.models.itemFloatModel:pushNewItems(event.data.items)
end

return ExploreWindow
