local TimeCloisterAwardWindow = class("TimeCloisterAwardWindow", import(".BaseWindow"))
local AwardItem = class("AwardItem", import("app.common.ui.FixedMultiWrapContentItem"))
local DRESS_SPECIAL_SKILL = 1002201

function AwardItem:initUI()
	self.itemIcon = import("app.components.ItemIcon").new(self.go)

	self.itemIcon:setDragScrollView(self.parent.scrollView)
end

function AwardItem:updateInfo()
	local data = {
		scale = 0.7962962962962963,
		itemID = tonumber(self.data.itemID)
	}

	if not self.parent.isDressId22Open then
		data.num = self.data.numInfo.supplyNum + self.data.numInfo.challengeNum
	else
		local skillRatio = xyd.tables.senpaiDressSkillTable:getNums(DRESS_SPECIAL_SKILL)[2]
		data.num = math.floor(self.data.numInfo.supplyNum * (1 + skillRatio)) + self.data.numInfo.challengeNum
	end

	if self.parent.cloister == xyd.TimeCloisterMissionType.THREE then
		local resArr = xyd.tables.miscTable:split2num("time_cloister_crystal_card_item", "value", "|")

		if xyd.arrayIndexOf(resArr, data.itemID) > -1 then
			local choiceId = xyd.models.timeCloisterModel:getThreeChoiceCrystalBuffId()

			if choiceId == xyd.TimeCloisterThreeChoiceBuffType.NONE then
				-- Nothing
			else
				local addPercent = xyd.models.timeCloisterModel:getThreeChoiceCrystalBuffNum(choiceId)

				if choiceId == xyd.TimeCloisterThreeChoiceBuffType.ONE and data.itemID == resArr[1] then
					data.num = math.floor(data.num * (1 + addPercent))
				elseif choiceId == xyd.TimeCloisterThreeChoiceBuffType.TWO and data.itemID == resArr[2] then
					data.num = math.floor(data.num * (1 + addPercent))
				elseif choiceId == xyd.TimeCloisterThreeChoiceBuffType.THREE and data.itemID == resArr[3] then
					data.num = math.floor(data.num * (1 + addPercent))
				elseif choiceId == xyd.TimeCloisterThreeChoiceBuffType.ALL then
					data.num = math.floor(data.num * (1 + addPercent))
				end
			end
		end
	end

	self.itemIcon:setInfo(data)
end

function TimeCloisterAwardWindow:ctor(name, params)
	self.info = params.info
	self.cloister = params.cloister
	self.isDressId22Open = false

	TimeCloisterAwardWindow.super.ctor(self, name, params)
end

function TimeCloisterAwardWindow:initWindow()
	self:getUIComponent()
	TimeCloisterAwardWindow.super.initWindow(self)
	self:registerEvent()
	xyd.models.timeCloisterModel:reqGetAward()
end

function TimeCloisterAwardWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.cloisterLabel = groupAction:ComponentByName("cloisterLabel", typeof(UILabel))
	self.awardGroup1 = groupAction:NodeByName("awardGroup1").gameObject
	self.awardLabel1 = self.awardGroup1:ComponentByName("awardLabel", typeof(UILabel))
	self.itemRoot = self.awardGroup1:NodeByName("itemRoot").gameObject
	self.awardGroup2 = groupAction:NodeByName("awardGroup2").gameObject
	self.awardLabel2 = self.awardGroup2:ComponentByName("awardLabel", typeof(UILabel))
	self.scrollView = self.awardGroup2:ComponentByName("scroller_", typeof(UIScrollView))
	local itemGroup = self.scrollView:ComponentByName("itemGroup", typeof(UIWrapContent))
	local itemContainer = self.awardGroup2:NodeByName("itemContainer").gameObject
	self.wrapContent_ = import("app.common.ui.FixedMultiWrapContent").new(self.scrollView, itemGroup, itemContainer, AwardItem, self)
	self.dataGroup = groupAction:NodeByName("dataGroup").gameObject
	self.dataTitleLabel = self.dataGroup:ComponentByName("dataTitleLabel", typeof(UILabel))
	self.dataItemLabelList = {}

	for i = 1, 5 do
		local dataItem = self.dataGroup:NodeByName("dataItem_" .. i).gameObject
		local nameLabel = dataItem:ComponentByName("nameLabel", typeof(UILabel))
		local numLabel = dataItem:ComponentByName("numLabel", typeof(UILabel))

		table.insert(self.dataItemLabelList, {
			nameLabel = nameLabel,
			numLabel = numLabel,
			bg = dataItem:ComponentByName("bg", typeof(UISprite))
		})
	end

	self.scoreLabel = self.dataGroup:ComponentByName("scoreLabel", typeof(UILabel))
	self.btnSure = groupAction:NodeByName("btnSure").gameObject
	self.btnSureLabel = self.btnSure:ComponentByName("label", typeof(UILabel))
end

function TimeCloisterAwardWindow:layout(data)
	if xyd.Global.lang ~= "zh_tw" then
		for i = 1, 5 do
			self.dataItemLabelList[i].bg.width = 245
		end
	end

	self.titleLabel.text = __("TIME_CLOISTER_TEXT33")
	self.cloisterLabel.text = xyd.tables.timeCloisterTable:getName(self.cloister)
	self.dataTitleLabel.text = __("TIME_CLOISTER_TEXT34")
	self.awardLabel1.text = __("TIME_CLOISTER_TEXT38")
	self.awardLabel2.text = __("TIME_CLOISTER_TEXT39")
	self.btnSureLabel.text = __("SURE")
	self.scoreLabel.text = __("TIME_CLOISTER_TEXT37") .. " : " .. data.point
	local text = {
		__("TIME_CLOISTER_TEXT35"),
		__("TIME_CLOISTER_TEXT52"),
		__("TIME_CLOISTER_TEXT54"),
		__("TIME_CLOISTER_TEXT53"),
		__("TIME_CLOISTER_TEXT36")
	}

	for i = 1, 5 do
		self.dataItemLabelList[i].nameLabel.text = text[i]
	end

	local events = self.info.events or {}
	local cardNumList = {
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0
	}
	local totalNum = 0

	for card_id, num in pairs(events) do
		local type = xyd.tables.timeCloisterCardTable:getType(tonumber(card_id))
		cardNumList[type] = cardNumList[type] + num
		totalNum = totalNum + num
	end

	self.dataItemLabelList[1].numLabel.text = xyd.secondsToString(totalNum * tonumber(xyd.tables.miscTable:getVal("time_cloister_card_time")))
	self.dataItemLabelList[2].numLabel.text = cardNumList[xyd.TimeCloisterCardType.SUPPLY] + cardNumList[xyd.TimeCloisterCardType.DRESS_SUCC]
	self.dataItemLabelList[3].numLabel.text = cardNumList[xyd.TimeCloisterCardType.EVENT] + cardNumList[xyd.TimeCloisterCardType.PLOT_EVENT]
	self.dataItemLabelList[4].numLabel.text = cardNumList[xyd.TimeCloisterCardType.BATTLE_WIN] + cardNumList[xyd.TimeCloisterCardType.BATTLE_FAIL] + cardNumList[xyd.TimeCloisterCardType.ENCOUNTER_BATTLE] + cardNumList[xyd.TimeCloisterCardType.ENCOUNTER_BATTLE_WIN] + cardNumList[xyd.TimeCloisterCardType.ENCOUNTER_BATTLE_FAIL]
	local winLeft = cardNumList[xyd.TimeCloisterCardType.BATTLE_WIN] + cardNumList[xyd.TimeCloisterCardType.ENCOUNTER_BATTLE_WIN]
	local winRight = cardNumList[xyd.TimeCloisterCardType.BATTLE_WIN] + cardNumList[xyd.TimeCloisterCardType.BATTLE_FAIL] + cardNumList[xyd.TimeCloisterCardType.ENCOUNTER_BATTLE_WIN] + cardNumList[xyd.TimeCloisterCardType.ENCOUNTER_BATTLE_FAIL]
	local win = 100 * winLeft / math.max(winRight, 1)
	self.dataItemLabelList[5].numLabel.text = win - win % 0.01 .. "%"
	local list = {}

	for type, items in pairs(self.info.items or {}) do
		for item_id, item_num in pairs(items) do
			if not list[item_id] then
				local info = {
					challengeNum = 0,
					supplyNum = 0
				}
				list[item_id] = info
			end

			if tonumber(type) == xyd.TimeCloisterCardType.SUPPLY or tonumber(type) == xyd.TimeCloisterCardType.DRESS_SUCC then
				list[item_id].supplyNum = list[item_id].supplyNum + item_num
			elseif tonumber(type) == xyd.TimeCloisterCardType.BATTLE_WIN or tonumber(type) == xyd.TimeCloisterCardType.BATTLE_FAIL or tonumber(type) == xyd.TimeCloisterCardType.ENCOUNTER_BATTLE_WIN or tonumber(type) == xyd.TimeCloisterCardType.ENCOUNTER_BATTLE_FAIL then
				list[item_id].challengeNum = list[item_id].challengeNum + item_num
			end
		end
	end

	local list2 = {}

	for item_id, numInfo in pairs(list) do
		table.insert(list2, {
			scale = 0.7962962962962963,
			itemID = item_id,
			numInfo = numInfo
		})
	end

	self.supplyItems = list2

	self.wrapContent_:setInfos(list2, {})

	local awards1 = xyd.tables.timeCloisterAwardTable:getAwards(data.id) or {}

	for _, item in ipairs(awards1) do
		local params = {
			scale = 0.7962962962962963,
			uiRoot = self.itemRoot,
			itemID = item[1],
			num = item[2]
		}
		local addNumId = xyd.tables.timeCloisterTable:getTecIcon(self.cloister)

		if addNumId and addNumId > 0 and tonumber(params.itemID) == addNumId then
			params.num = math.floor(params.num * (1 + xyd.models.dress:getBuffTypeAttr(xyd.DressBuffAttrType.TIME_CLOISTR_TEC)))
		end

		xyd.getItemIcon(params)
	end

	self.itemRoot:GetComponent(typeof(UIGrid)):Reposition()
end

function TimeCloisterAwardWindow:onGetAward(event)
	self:layout(event.data)
end

function TimeCloisterAwardWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_HANG, handler(self, self.onGetAward))

	UIEventListener.Get(self.btnSure).onClick = handler(self, function ()
		self:close()
	end)
end

function TimeCloisterAwardWindow:updateDress()
	print("触发了前端对22号技能的计算")

	self.isDressId22Open = true

	if self.supplyItems then
		self.wrapContent_:setInfos(self.supplyItems, {})
	end
end

return TimeCloisterAwardWindow
