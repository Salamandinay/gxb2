local TimeCloisterTechDetailWindow = class("TimeCloisterTechDetailWindow", import(".BaseWindow"))
local timeCloister = xyd.models.timeCloisterModel
local tecTable = xyd.tables.timeCloisterTecTable
local tecTextTable = xyd.tables.timeCloisterTecTextTable

function TimeCloisterTechDetailWindow:ctor(name, params)
	self.cloister = params.cloister
	self.group = params.group
	self.curSkillID = 0
	self.enterOnCilckId = params.enterOnCilckId
	self.isShowAll = false

	if self.enterOnCilckId then
		self.isShowAll = true
	end

	TimeCloisterTechDetailWindow.super.ctor(self, name, params)
end

function TimeCloisterTechDetailWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	self:checkEnterOnclick()
end

function TimeCloisterTechDetailWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.groupAction = groupAction
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.helpBtn = groupAction:NodeByName("helpBtn").gameObject
	self.descLabel = groupAction:ComponentByName("descLabel", typeof(UILabel))
	self.resRoot = groupAction:NodeByName("resRoot").gameObject
	self.mainContent = groupAction:NodeByName("mainContent").gameObject
	self.techItem = self.mainContent:NodeByName("techItem").gameObject
	self.line = self.mainContent:NodeByName("line").gameObject
	self.handNode = self.mainContent:NodeByName("handNode").gameObject
	self.levelUpGroup = groupAction:NodeByName("levelUpGroup").gameObject
	self.nameLabel = self.levelUpGroup:ComponentByName("nameLabel", typeof(UILabel))
	self.numLabel = self.levelUpGroup:ComponentByName("numLabel", typeof(UILabel))
	self.levelUpLabel = self.levelUpGroup:ComponentByName("levelUpLabel", typeof(UILabel))
	self.textMaxLev = self.levelUpGroup:ComponentByName("maxGroup/textMaxLev", typeof(UILabel))
	self.groupCost = self.levelUpGroup:NodeByName("groupCost").gameObject
	self.costImg1 = self.groupCost:ComponentByName("costImg1", typeof(UISprite))
	self.labelCost1 = self.groupCost:ComponentByName("labelCost1", typeof(UILabel))
	self.btnLevUp = self.levelUpGroup:NodeByName("btnLevUp").gameObject
	self.skillDescLabel = self.levelUpGroup:ComponentByName("scroller_/descLabel", typeof(UILabel))
	self.groupPreview = self.levelUpGroup:NodeByName("groupPreview").gameObject
	self.previewLabel = self.groupPreview:ComponentByName("previewLabel", typeof(UILabel))
	self.btnPreview = self.groupPreview:NodeByName("btnPreview").gameObject
	self.mask = groupAction:NodeByName("mask").gameObject
	self.checkShowAllBtn = groupAction:NodeByName("checkShowAllBtn").gameObject
	self.checkShowAllBtn_UISprite = groupAction:ComponentByName("checkShowAllBtn", typeof(UISprite))
end

function TimeCloisterTechDetailWindow:layout()
	self.levelUpGroup:SetActive(false)
	self.mask:SetActive(false)

	local str = ""
	str = self.group == 1 and __("TIME_CLOISTER_TEXT50") or __("TIME_CLOISTER_TEXT51")
	self.descLabel.text = str
	self.resItem = require("app.components.ResItem").new(self.resRoot)
	local itemId = xyd.tables.timeCloisterTable:getTecIcon(self.cloister)

	self.resItem:setInfo({
		tableId = itemId
	})

	self.levelUpLabel.text = __("TIME_CLOISTER_TEXT41")
	self.previewLabel.text = __("TIME_CLOISTER_TEXT42")
	self.textMaxLev.text = __("MAX_LEV")
	self.info = timeCloister:getTechInfoByCloister(self.cloister)[self.group]
	self.techItemList = {}
	local ids = tecTable:getIdsByCloister(self.cloister)[self.group]

	for _, skill_id in ipairs(ids) do
		if not self.techItemList[skill_id] then
			self:checkPreID(skill_id)
		end
	end

	self:updateRedPoints()
	self:updateCheckShowAllBtnShow()
	self:adjustPositionAndScale()
	self:adjustPositionAndScale()
end

function TimeCloisterTechDetailWindow:checkPreID(skill_id)
	local info = self.info[skill_id]

	if not next(info.pre_id) then
		self:checkPreInfos(skill_id)
	elseif self.techItemList[info.pre_id[1]] then
		self:checkPreInfos(skill_id)
	else
		self:checkPreID(info.pre_id[1])
		self:checkPreInfos(skill_id)
	end
end

function TimeCloisterTechDetailWindow:checkPreInfos(skill_id)
	if self.techItemList[skill_id] then
		return
	end

	local obj = NGUITools.AddChild(self.mainContent, self.techItem)

	obj:SetLocalScale(0.8, 0.8, 0.8)

	local pos = tecTable:getPos(skill_id)
	local img = tecTable:getImg(skill_id)

	obj:SetLocalPosition(pos[1], pos[2], 0)

	local function clickFun()
		if self.mask.activeSelf then
			self.levelUpGroup:SetActive(false)
			self.mask:SetActive(false)

			self.curSkillID = 0
		else
			self.curSkillID = skill_id

			self:updateLevelUpGroup()
			self.levelUpGroup:SetActive(true)
			self.mask:SetActive(true)
		end

		self.enterOnCilckId = nil

		self:showHand(false)
	end

	UIEventListener.Get(obj).onClick = clickFun
	local label = obj:ComponentByName("label", typeof(UILabel))
	local bg = obj:ComponentByName("bg", typeof(UISprite))
	local icon = obj:ComponentByName("icon", typeof(UISprite))
	local labelBg = obj:NodeByName("labelBg").gameObject

	label:SetActive(false)
	labelBg:SetActive(false)

	local info = self.info[skill_id]
	local lineList = {}
	local unlock = false

	if next(info.pre_id) then
		local preLv = tecTable:getPreLv(skill_id)

		for i, id in ipairs(info.pre_id) do
			unlock = unlock or preLv[i] <= self.info[id].curLv
			local line = NGUITools.AddChild(self.mainContent, self.line):GetComponent(typeof(UISprite))
			local ppos = self.techItemList[id].pos
			local width = math.sqrt((pos[1] - ppos[1]) * (pos[1] - ppos[1]) + (pos[2] - ppos[2]) * (pos[2] - ppos[2]))
			line.width = width

			line:SetLocalPosition((pos[1] + ppos[1]) / 2, (pos[2] + ppos[2]) / 2, 0)

			local angle = math.atan2(ppos[2] - pos[2], ppos[1] - pos[1]) * 180 / math.pi
			line.gameObject.transform.localEulerAngles = Vector3(0, 0, angle)

			table.insert(lineList, line)
			table.insert(self.techItemList[id].next_id, skill_id)
		end
	else
		unlock = true
	end

	local ex_unlock = true
	local unLockType = tecTable:getUnlockType(skill_id)
	local unLockNum = tecTable:getUnlockNum(skill_id)
	local hangInfo = timeCloister:getHangInfo()

	if unLockType == xyd.TimeCloisterUnLockType.SELF_BASE then
		local baseAttr = hangInfo.black_base

		for i = 1, 3 do
			ex_unlock = ex_unlock and unLockNum[i] <= baseAttr[i]
		end
	elseif unLockType == xyd.TimeCloisterUnLockType.EVENT_NUM then
		local sum_events = timeCloister:getSumEvents()
		ex_unlock = ex_unlock and unLockNum[2] <= (sum_events[tostring(unLockNum[1])] or 0)
	elseif unLockType == xyd.TimeCloisterUnLockType.ACHIEVEMENT then
		local achInfo = timeCloister:getAchInfo(self.cloister)

		for _, data in ipairs(achInfo) do
			if data.achieve_type == unLockNum[1] then
				ex_unlock = ex_unlock and (data.achieve_id == 0 or unLockNum[2] < data.achieve_id)

				break
			end
		end
	elseif unLockType == xyd.TimeCloisterUnLockType.PROGRESS then
		ex_unlock = ex_unlock and unLockNum[1] <= hangInfo.progress
	elseif unLockType == xyd.TimeCloisterUnLockType.ENCOUNTER_FIGHT then
		local sum_start_events = timeCloister:getSumStartEvents()
		local needNum = sum_start_events[tostring(unLockNum[1])]
		needNum = not needNum and 0 or tonumber(needNum)
		ex_unlock = sum_start_events and tonumber(unLockNum[2]) <= needNum
	end

	if info.curLv > 0 then
		label:SetActive(true)
		labelBg:SetActive(true)

		label.text = info.curLv .. "/" .. info.maxLv

		xyd.setUISpriteAsync(bg, nil, "time_cloister_tec_bg_1")
		xyd.setUISpriteAsync(icon, nil, img .. "_1")
	elseif unlock and ex_unlock then
		xyd.setUISpriteAsync(bg, nil, "time_cloister_tec_bg_2")
		xyd.setUISpriteAsync(icon, nil, img .. "_2")
	else
		xyd.setUISpriteAsync(bg, nil, "time_cloister_tec_bg_3")
		xyd.setUISpriteAsync(icon, nil, img .. "_3")
	end

	local lineImg = unlock and "time_cloister_tec_line_1" or "time_cloister_tec_line_2"

	for _, line in ipairs(lineList) do
		xyd.setUISpriteAsync(line, nil, lineImg)
	end

	self.techItemList[skill_id] = {
		obj = obj,
		label = label,
		labelBg = labelBg,
		bg = bg,
		icon = icon,
		pos = pos,
		line = lineList,
		next_id = {},
		unlock = unlock,
		ex_unlock = ex_unlock,
		redPoint = obj:NodeByName("redPoint").gameObject,
		clickFun = clickFun
	}
end

function TimeCloisterTechDetailWindow:checkEnterOnclick()
	if self.enterOnCilckId and self.techItemList[self.enterOnCilckId] then
		self:showHand(true, self.enterOnCilckId)
	end
end

function TimeCloisterTechDetailWindow:adjustPositionAndScale()
	local unLockNum = 0
	local mLeft = 0
	local mRight = 0
	local mTop = 0
	local mBot = 0
	local left = 0
	local right = 0
	local top = 0
	local bot = 0
	local ids = tecTable:getIdsByCloister(self.cloister)[self.group]

	for _, skill_id in pairs(ids) do
		local item = self.techItemList[skill_id]
		local pos = item.pos
		mLeft = math.min(mLeft, pos[1] - 52)
		mRight = math.max(mRight, pos[1] + 52)
		mTop = math.max(mTop, pos[2] + 52)
		mBot = math.min(mBot, pos[2] - 52)
		local flag = true
		local info = self.info[skill_id]

		for i, id in ipairs(info.pre_id) do
			flag = self.info[id].curLv > 0 or #self.info[id].pre_id == 0

			if flag then
				break
			end
		end

		if flag then
			unLockNum = unLockNum + 1
		end

		if self.isShowAll then
			flag = true
		end

		if flag then
			left = math.min(left, pos[1] - 52)
			right = math.max(right, pos[1] + 52)
			top = math.max(top, pos[2] + 52)
			bot = math.min(bot, pos[2] - 52)
		elseif self.showHandID and self.showHandID == skill_id then
			self:showHand(false)

			self.enterOnCilckId = nil
		end

		item.obj:SetActive(flag)

		item.active = flag

		for i, id in ipairs(info.pre_id) do
			item.line[i]:SetActive(flag and self.techItemList[id].active)
		end
	end

	local mX, mY, X, Y = nil
	mX = (mRight + mLeft) / 2
	mY = (mTop + mBot) / 2
	X = (left + right) / 2
	Y = (top + bot) / 2
	local scale = math.min((mRight - mLeft) / (right - left), (mTop - mBot) / (top - bot), 1.3)

	self.mainContent:SetLocalScale(scale, scale, 1)
	self.mainContent:SetLocalPosition(-4 - X * scale + mX, 74 - Y * scale + mY, 0)
	self.handNode:SetLocalScale(1 / scale, 1 / scale, 1)

	if unLockNum >= #ids then
		self.checkShowAllBtn:SetActive(false)
	else
		self.checkShowAllBtn:SetActive(true)
	end
end

function TimeCloisterTechDetailWindow:updateRedPoints()
	self.handTipsID = 0
	local tipsRank = 1000000
	local id = xyd.tables.timeCloisterTable:getTecIcon(self.cloister)
	local hasNum = xyd.models.backpack:getItemNumByID(id)

	for skill_id, item in pairs(self.techItemList) do
		local info = self.info[skill_id]

		if item.unlock and item.ex_unlock and info.curLv < info.maxLv then
			local cost = tecTable:getUpgradeCost(skill_id)[info.curLv + 1]

			item.redPoint:SetActive(cost[2] <= hasNum)

			if info.curLv == 0 then
				local rank = tecTable:getRank(skill_id)

				if rank ~= 0 and rank < tipsRank and cost[2] < hasNum then
					tipsRank = rank
					self.handTipsID = skill_id
				end
			end
		else
			item.redPoint:SetActive(false)
		end
	end

	if self.handTipsID ~= 0 then
		if not self.enterOnCilckId then
			self:showHand(true, self.handTipsID)
		end
	else
		self:showHand(false)
	end
end

function TimeCloisterTechDetailWindow:showHand(state, skill_id)
	if state then
		self.handNode:SetActive(true)

		if not self.hand then
			self.hand = xyd.Spine.new(self.handNode)

			self.hand:setInfo("fx_ui_dianji", function ()
				self.hand:play("texiao01", 0)
			end)
		end

		local pos = self.techItemList[skill_id].pos

		self.handNode:SetLocalPosition(pos[1], pos[2], 0)

		self.showHandID = skill_id
	else
		self.showHandID = nil

		self.handNode:SetActive(false)
	end
end

function TimeCloisterTechDetailWindow:updateLevelUpGroup()
	if self.handTipsID == self.curSkillID then
		self.handNode:SetActive(false)
	end

	local info = self.info[self.curSkillID]
	local tectItem = self.techItemList[self.curSkillID]
	self.nameLabel.text = tecTextTable:getName(self.curSkillID)

	if xyd.Global.lang == "fr_fr" then
		self.numLabel.text = "Niv." .. info.curLv .. "/" .. info.maxLv
	else
		self.numLabel.text = "Lv: " .. info.curLv .. "/" .. info.maxLv
	end

	local num = tecTable:getNum(self.curSkillID)
	local nums = ""
	local descText = ""

	if tecTable:getType(self.curSkillID) == 3 then
		nums = num[math.min(info.curLv + 1, info.maxLv)] or ""
	else
		nums = num[math.max(info.curLv, 1)] or ""
	end

	descText = xyd.stringFormat(tecTextTable:getDesc(self.curSkillID), nums)
	local cost = tecTable:getUpgradeCost(self.curSkillID)[math.min(info.curLv + 1, info.maxLv)]

	xyd.setUISpriteAsync(self.costImg1, nil, xyd.tables.itemTable:getIcon(cost[1]), nil)

	self.labelCost1.text = cost[2]

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		self.labelCost1.color = Color.New2(3422556671.0)
	else
		self.labelCost1.color = Color.New2(960513791)
	end

	if not tectItem.unlock or not tectItem.ex_unlock then
		self.groupCost:SetActive(true)
		self.btnLevUp:SetActive(true)
		xyd.applyGrey(self.btnLevUp:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnLevUp, false)

		local unLockType = tecTable:getUnlockType(self.curSkillID)

		if unLockType == xyd.TimeCloisterUnLockType.EVENT_NUM then
			local sum_events = timeCloister:getSumEvents()
			local unLockNum = tecTable:getUnlockNum(self.curSkillID)
			descText = "[c][cc0011]" .. xyd.stringFormat(tecTextTable:getUnlockDesc(self.curSkillID), sum_events[tostring(unLockNum[1])] or 0) .. "[-][/c]\n\n" .. descText
		elseif unLockType == xyd.TimeCloisterUnLockType.ENCOUNTER_FIGHT then
			local sum_start_events = timeCloister:getSumStartEvents()
			local unLockNum = tecTable:getUnlockNum(self.curSkillID)
			descText = "[c][cc0011]" .. xyd.stringFormat(tecTextTable:getUnlockDesc(self.curSkillID), sum_start_events[tostring(unLockNum[1])] or 0) .. "[-][/c]\n\n" .. descText
		elseif tecTextTable:getUnlockDesc(self.curSkillID) ~= "" then
			descText = "[c][cc0011]" .. tecTextTable:getUnlockDesc(self.curSkillID) .. "[-][/c]\n\n" .. descText
		end
	elseif info.curLv < info.maxLv then
		self.groupCost:SetActive(true)
		self.btnLevUp:SetActive(true)
		xyd.applyOrigin(self.btnLevUp:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnLevUp, true)
	else
		self.groupCost:SetActive(false)
		self.btnLevUp:SetActive(false)
	end

	self.skillDescLabel.text = descText

	if info.maxLv > 1 then
		self.groupPreview:SetActive(true)
	else
		self.groupPreview:SetActive(false)
	end
end

function TimeCloisterTechDetailWindow:onUpgradeSkill(event)
	local skill_id = event.data.skill_id
	local item = self.techItemList[skill_id]
	local info = self.info[skill_id]
	item.label.text = info.curLv .. "/" .. info.maxLv

	if info.curLv == 1 then
		item.label:SetActive(true)
		item.label:SetActive(true)

		local img = tecTable:getImg(skill_id)

		xyd.setUISpriteAsync(item.bg, nil, "time_cloister_tec_bg_1")
		xyd.setUISpriteAsync(item.icon, nil, img .. "_1")
	end

	for _, next_id in ipairs(item.next_id) do
		local nextItem = self.techItemList[next_id]

		if not nextItem.unlock then
			local preLv = tecTable:getPreLv(next_id)
			local unlock = false

			for i, id in ipairs(self.info[next_id].pre_id) do
				unlock = unlock or preLv[i] <= self.info[id].curLv
			end

			nextItem.unlock = unlock

			if nextItem.unlock and nextItem.ex_unlock then
				local img = tecTable:getImg(next_id)

				xyd.setUISpriteAsync(nextItem.bg, nil, "time_cloister_tec_bg_2")
				xyd.setUISpriteAsync(nextItem.icon, nil, img .. "_2")

				for _, l in ipairs(nextItem.line) do
					xyd.setUISpriteAsync(l, nil, "time_cloister_tec_line_1")
				end
			end
		end
	end

	self.resItem:updateNum()

	if self.levelUpGroup.activeSelf and self.curSkillID == skill_id then
		self:updateLevelUpGroup()
	end

	self:updateRedPoints()
	self:adjustPositionAndScale()
end

function TimeCloisterTechDetailWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.UPGRADE_SKILL, handler(self, self.onUpgradeSkill))

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "TIME_CLOISTER_HELP02"
		})
	end)

	UIEventListener.Get(self.mask).onClick = function ()
		self.levelUpGroup:SetActive(false)
		self.mask:SetActive(false)
	end

	UIEventListener.Get(self.btnLevUp).onClick = function ()
		local cost = tecTable:getUpgradeCost(self.curSkillID)[self.info[self.curSkillID].curLv + 1]

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
		else
			timeCloister:reqUpgradeSkill(self.cloister, self.curSkillID)

			self.isUpgradeSkill = true
		end
	end

	UIEventListener.Get(self.btnPreview).onClick = function ()
		xyd.WindowManager.get():openWindow("time_cloister_tech_levup_preview_window", {
			skill_id = self.curSkillID,
			curLv = self.info[self.curSkillID].curLv,
			maxLv = self.info[self.curSkillID].maxLv
		})
	end

	UIEventListener.Get(self.checkShowAllBtn).onClick = function ()
		self.isShowAll = not self.isShowAll

		if self.isShowAll then
			xyd.showToast(__("TIME_CLOISTER_TEXT59"))
		else
			xyd.showToast(__("TIME_CLOISTER_TEXT60"))
		end

		self:updateCheckShowAllBtnShow()
		self:adjustPositionAndScale()
	end
end

function TimeCloisterTechDetailWindow:updateCheckShowAllBtnShow()
	if self.isShowAll then
		xyd.setUISpriteAsync(self.checkShowAllBtn_UISprite, nil, "check_btn", nil, , )
	else
		xyd.setUISpriteAsync(self.checkShowAllBtn_UISprite, nil, "check_white_btn", nil, , )
	end
end

function TimeCloisterTechDetailWindow:willClose()
	TimeCloisterTechDetailWindow.super.willClose(self)

	if self.isUpgradeSkill then
		timeCloister:reqCardInfo(true)
	end
end

return TimeCloisterTechDetailWindow
