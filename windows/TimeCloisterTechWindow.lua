local TimeCloisterTechWindow = class("TimeCloisterTechWindow", import(".BaseWindow"))
local timeCloister = xyd.models.timeCloisterModel

function TimeCloisterTechWindow:ctor(name, params)
	self.cloister = params.cloister

	TimeCloisterTechWindow.super.ctor(self, name, params)
end

function TimeCloisterTechWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function TimeCloisterTechWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.helpBtn = groupAction:NodeByName("helpBtn").gameObject
	self.descLabel = groupAction:ComponentByName("descLabel", typeof(UILabel))
	self.resRoot = groupAction:NodeByName("resRoot").gameObject
	self.mainContent = groupAction:NodeByName("mainContent").gameObject

	for i = 1, 3 do
		self["techItem_" .. i] = self.mainContent:NodeByName("techItem" .. i).gameObject
		self["techItemLabel_" .. i] = self["techItem_" .. i]:ComponentByName("label", typeof(UILabel))

		if i == 1 then
			self.techItem1 = self["techItem_" .. i]
		elseif i == 3 then
			self.redPotin3 = self["techItem_" .. i]:NodeByName("redPotin3").gameObject
		end
	end

	if self.cloister == xyd.TimeCloisterMissionType.THREE then
		xyd.models.redMark:setJointMarkImg({
			xyd.RedMarkType.TIME_CLOISTER_RED_THREE_BUY,
			xyd.RedMarkType.TIME_CLOISTER_RED_THREE_SET_BATTLE_IDS
		}, self.redPotin3)
	end
end

function TimeCloisterTechWindow:layout()
	self.resItem = require("app.components.ResItem").new(self.resRoot)
	local itemId = xyd.tables.timeCloisterTable:getTecIcon(self.cloister)

	self.resItem:setInfo({
		tableId = itemId
	})

	self.descLabel.text = __("TIME_CLOISTER_TEXT87", xyd.tables.itemTable:getName(itemId))

	self:updateContent()
	self:checkGroup3RedPoint()
end

function TimeCloisterTechWindow:checkGroup3RedPoint()
	if self.cloister == xyd.TimeCloisterMissionType.THREE then
		timeCloister:checkThreeCloisterRed()
	end
end

function TimeCloisterTechWindow:updateContent()
	self.info = timeCloister:getTechInfoByCloister(self.cloister)

	for i = 1, #self.info do
		self["techItemLabel_" .. i].text = self.info[i].curNum .. "/" .. self.info[i].totalNum
	end

	self.resItem:updateNum()
end

function TimeCloisterTechWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.UPGRADE_SKILL, handler(self, self.updateContent))

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "TIME_CLOISTER_HELP02"
		})
	end)

	for i = 1, 3 do
		UIEventListener.Get(self["techItem_" .. i]).onClick = function ()
			dump(xyd.tables.timeCloisterTecTable:getIdsByCloister(self.cloister), "testTechGroup")

			if xyd.tables.timeCloisterTecTable:getIdsByCloister(self.cloister)[i] then
				if i == 1 or i == 2 then
					xyd.WindowManager.get():openWindow("time_cloister_tech_detail_window", {
						cloister = self.cloister,
						group = i
					})
				elseif self.cloister == xyd.TimeCloisterMissionType.TWO then
					local partnerTecLev = self.info[3][xyd.TimeCloisterSpecialTecId.PARTNER_3_TEC].curLv
					local specialSkillInfos = {}

					table.insert(specialSkillInfos, {
						id = 96,
						data = self.info[3][96]
					})
					table.insert(specialSkillInfos, {
						id = 97,
						data = self.info[3][97]
					})
					table.insert(specialSkillInfos, {
						id = 98,
						data = self.info[3][98]
					})
					table.insert(specialSkillInfos, {
						id = 99,
						data = self.info[3][99]
					})
					xyd.WindowManager.get():openWindow("time_cloister_help_partner_window", {
						tecId = 95,
						cloister = self.cloister,
						group = i,
						partnerTecLev = partnerTecLev,
						specialSkillInfos = specialSkillInfos
					})
					self:setLabelActive(false)
				end
			elseif i == 3 and self.cloister == xyd.TimeCloisterMissionType.THREE then
				xyd.WindowManager.get():openWindow("time_cloister_crystal_card_buy_window", {})
			end
		end
	end
end

function TimeCloisterTechWindow:willClose()
	TimeCloisterTechWindow.super.willClose(self)

	local time_cloister_probe_wd = xyd.WindowManager.get():getWindow("time_cloister_probe_window")

	if time_cloister_probe_wd then
		time_cloister_probe_wd:checkGuide()
	end
end

function TimeCloisterTechWindow:setLabelActive(state)
	self.descLabel.gameObject:SetActive(state)
end

return TimeCloisterTechWindow
