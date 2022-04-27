local TimeCloisterShowDressWindow = class("TimeCloisterShowDressWindow", import(".BaseWindow"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local TimeCloisterItem = class("TimeCloisterItem", import("app.components.CopyComponent"))
local timeCloister = xyd.models.timeCloisterModel

function TimeCloisterShowDressWindow:ctor(name, params)
	TimeCloisterShowDressWindow.super.ctor(self, name, params)
end

function TimeCloisterShowDressWindow:initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function TimeCloisterShowDressWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.bg = self.upCon:ComponentByName("bg", typeof(UISprite))
	self.nameText = self.upCon:ComponentByName("nameText", typeof(UILabel))
	self.closeBtn = self.upCon:NodeByName("closeBtn").gameObject
	self.infoCon = self.upCon:NodeByName("infoCon").gameObject
	self.descLabel = self.infoCon:ComponentByName("descLabel", typeof(UILabel))
	self.addBg = self.infoCon:ComponentByName("addBg", typeof(UISprite))
	self.showBtn = self.infoCon:NodeByName("showBtn").gameObject
	self.showBtnBoxCollider = self.infoCon:ComponentByName("showBtn", typeof(UnityEngine.BoxCollider))
	self.showBtnLabel = self.showBtn:ComponentByName("showBtnLabel", typeof(UILabel))
	self.leftArrow = self.upCon:ComponentByName("leftArrow", typeof(UISprite))
	self.leftArrowBoxCollider = self.leftArrow.gameObject:GetComponent(typeof(UnityEngine.BoxCollider))
	self.rightArrow = self.upCon:ComponentByName("rightArrow", typeof(UISprite))
	self.rightArrowBoxCollider = self.rightArrow.gameObject:GetComponent(typeof(UnityEngine.BoxCollider))
	self.dotCon = self.upCon:NodeByName("dotCon").gameObject
	self.dotConUILayout = self.upCon:ComponentByName("dotCon", typeof(UILayout))
	self.showTweenCon = self.infoCon:NodeByName("showTweenCon").gameObject
	self.dotIcon1 = self.dotCon:ComponentByName("dotIcon1", typeof(UISprite))
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.downConGo = self.downCon.gameObject
	self.btnCircles = self.downConGo:NodeByName("btnCircles").gameObject
	self.btnQualityChosen = self.btnCircles:NodeByName("btnQualityChosen").gameObject

	for i = 1, 5 do
		self["btnCircle" .. i] = self.btnCircles:NodeByName("btnCircle" .. i).gameObject
	end

	self.scroll_drag = self.downConGo:NodeByName("scroll_drag").gameObject
	self.scroll_view = self.downConGo:NodeByName("scroll_view").gameObject
	self.scroll_view_UIScrollView = self.downConGo:ComponentByName("scroll_view", typeof(UIScrollView))
	self.wrap_content = self.scroll_view:NodeByName("wrap_content").gameObject
	self.wrap_content_UIWrapContent = self.scroll_view:ComponentByName("wrap_content", typeof(UIWrapContent))
	self.groupNone = self.downConGo:NodeByName("groupNone").gameObject
	self.imgNoneShow = self.groupNone:ComponentByName("imgNoneShow", typeof(UISprite))
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
	self.dressItemEg = self.downConGo:NodeByName("dressItemEg").gameObject
	self.wrapContent_ = FixedMultiWrapContent.new(self.scroll_view_UIScrollView, self.wrap_content_UIWrapContent, self.dressItemEg, TimeCloisterItem, self)
end

function TimeCloisterShowDressWindow:registerEvent()
	for k = 1, 5 do
		UIEventListener.Get(self["btnCircle" .. k]).onClick = function ()
			self:onQualityBtn(k)
		end
	end

	UIEventListener.Get(self.showBtn.gameObject).onClick = handler(self, function ()
		if self.choiceItemId <= -1 then
			xyd.showToast(__("TIME_CLOISTER_TEXT69"))

			return
		end

		local str = tostring(self.allEvent[self.pageNum].eventId)

		if self.allEvent[self.pageNum].value.mission_id then
			str = str .. "#" .. self.allEvent[self.pageNum].value.mission_id
		end

		if self.allEvent[self.pageNum].value.mission_params1 then
			str = str .. "#" .. self.allEvent[self.pageNum].value.mission_params1
		end

		timeCloister:reqDressShow(str, self.choiceItemId)
	end)
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.leftArrow.gameObject).onClick = handler(self, function ()
		if self.allNum <= self.pageNum then
			self.rightArrow.alpha = 1
		end

		if self.pageNum > 1 then
			self.pageNum = self.pageNum - 1
		end

		if self.pageNum <= 1 then
			self.leftArrow.alpha = 0.6

			self:setArrowState("left", false)
		else
			self.leftArrow.alpha = 1

			self:setArrowState("left", true)
		end

		self:setArrowState("right", true)
		self:updatePage()
	end)
	UIEventListener.Get(self.rightArrow.gameObject).onClick = handler(self, function ()
		if self.pageNum <= 1 then
			self.leftArrow.alpha = 1
		end

		if self.pageNum < self.allNum then
			self.pageNum = self.pageNum + 1
		end

		if self.allNum <= self.pageNum then
			self.rightArrow.alpha = 0.6

			self:setArrowState("right", false)
		else
			self.rightArrow.alpha = 1

			self:setArrowState("right", true)
		end

		self:setArrowState("left", true)
		self:updatePage()
	end)
end

function TimeCloisterShowDressWindow:layout()
	self.nameText.text = __("TIME_CLOISTER_TEXT86")
	self.showBtnLabel.text = __("TIME_CLOISTER_TEXT67")
	self.defaultIndex = 0
	self.showTweenIcon = nil
	self.choiceItemId = -1
	self.pageNum = 1
	self.showQuality = self.defaultIndex
	self.allEvent = {}
	self.leftArrow.alpha = 0.6
	self.eventWithInfos = {}

	self:setArrowState("left", false)
	self:initDots()
	self:updatePage()
end

function TimeCloisterShowDressWindow:initDots()
	local missionArr = timeCloister:getMissionArr()
	local allNum = 0

	for i in pairs(missionArr) do
		allNum = allNum + #missionArr[i]

		for j in pairs(missionArr[i]) do
			local params = {
				eventId = i,
				value = missionArr[i][j]
			}

			table.insert(self.allEvent, params)
		end
	end

	self.allNum = allNum

	if allNum <= 1 then
		self.dotCon.gameObject:SetActive(false)
		self.leftArrow.gameObject:SetActive(false)
		self.rightArrow.gameObject:SetActive(false)
	else
		self.leftArrow.gameObject:SetActive(true)
		self.rightArrow.gameObject:SetActive(true)
		self.dotCon.gameObject:SetActive(true)

		for i = 2, allNum do
			local tmp = NGUITools.AddChild(self.dotCon.gameObject, self.dotIcon1.gameObject)
			tmp.name = "dotIcon" .. i
			self["dotIcon" .. i] = tmp.gameObject:GetComponent(typeof(UISprite))
		end
	end

	self.dotConUILayout:Reposition()
	xyd.setUISpriteAsync(self["dotIcon" .. "1"], nil, "market_dot_bg2")
end

function TimeCloisterShowDressWindow:updatePage()
	self:updateNeedTarget()

	for i = 1, self.allNum do
		if i == self.pageNum then
			xyd.setUISpriteAsync(self["dotIcon" .. i], nil, "market_dot_bg2")
		else
			xyd.setUISpriteAsync(self["dotIcon" .. i], nil, "market_dot_bg1")
		end
	end

	local info = self:getCurPageInfo()
	local missionId = info.value.mission_id
	local missionType = xyd.tables.timeCloisterDressMissionTable:getType(missionId)
	local str = ""

	if self.missionType == xyd.TimeCloisterDressMissionType.QLT then
		str = xyd.tables.timeCloisterDressMissionTextTable:getDesc(missionType, __("TIME_CLOISTER_TEXT" .. self.needQlt + 71), __("TIME_CLOISTER_TEXT" .. self.needPos + 78))
	elseif self.missionType == xyd.TimeCloisterDressMissionType.QLT_START then
		str = xyd.tables.timeCloisterDressMissionTextTable:getDesc(missionType, __("TIME_CLOISTER_TEXT" .. self.needQlt + 71), self.needStart, __("TIME_CLOISTER_TEXT" .. self.needPos + 78))
	elseif self.missionType == xyd.TimeCloisterDressMissionType.COURAGE then
		str = xyd.tables.timeCloisterDressMissionTextTable:getDesc(missionType, self.needCourage)
	elseif self.missionType == xyd.TimeCloisterDressMissionType.CHARM then
		str = xyd.tables.timeCloisterDressMissionTextTable:getDesc(missionType, self.needCharm)
	elseif self.missionType == xyd.TimeCloisterDressMissionType.KNOWLEDGE then
		str = xyd.tables.timeCloisterDressMissionTextTable:getDesc(missionType, self.needKnowledge)
	elseif self.missionType == xyd.TimeCloisterDressMissionType.THREE_ATTR_SUM then
		str = xyd.tables.timeCloisterDressMissionTextTable:getDesc(missionType, self.needThreeAttrSum)
	end

	self.descLabel.text = str

	self:updateInfo(-1)
end

function TimeCloisterShowDressWindow:updateInfo(index)
	self.items_arr = xyd.models.dress:getDressItems()

	self:showTweenFun(-1, false)
	self:onQualityBtn(index)
end

function TimeCloisterShowDressWindow:onQualityBtn(index)
	local isPlaySoundId = true

	if self.showQuality ~= index or index == -1 then
		if index == -1 then
			index = 0
		end

		isPlaySoundId = false

		if index == 0 then
			self.btnQualityChosen.gameObject:SetActive(false)
		else
			self.btnQualityChosen.gameObject:SetActive(true)

			local pos = self["btnCircle" .. index].transform.localPosition

			self.btnQualityChosen:SetLocalPosition(pos.x, pos.y, pos.z)
		end

		self.showQuality = index
	elseif self.showQuality == index then
		if self.showQuality == 0 then
			return
		else
			self:onQualityBtn(0)

			return
		end
	end

	if isPlaySoundId then
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
	end

	if #self.items_arr[index] == 0 then
		self.labelNoneTips.text = __("PERSON_DRESS_MAIN_" .. index + 16)

		self.groupNone:SetActive(true)
		self.wrapContent_:setInfos({}, {})

		return
	else
		self.groupNone:SetActive(false)
	end

	local infos = self:getInfos(index)

	self:waitForFrame(1, function ()
		self.wrapContent_:setInfos(infos, {})
		self.scroll_view_UIScrollView:ResetPosition()
	end)
end

function TimeCloisterShowDressWindow:updateNeedTarget()
	local info = self:getCurPageInfo()
	self.missionId = info.value.mission_id
	self.needPos = xyd.tables.timeCloisterDressMissionTable:getPos(self.missionId)
	self.missionType = xyd.tables.timeCloisterDressMissionTable:getType(self.missionId)
	self.needQlt = nil

	if self.missionType == xyd.TimeCloisterDressMissionType.QLT then
		self.needQlt = xyd.tables.timeCloisterDressMissionTable:getNum(self.missionId)[1]
	end

	self.needStart = nil

	if self.missionType == xyd.TimeCloisterDressMissionType.QLT_START then
		self.needQlt = xyd.tables.timeCloisterDressMissionTable:getNum(self.missionId)[1]
		self.needStart = xyd.tables.timeCloisterDressMissionTable:getNum(self.missionId)[2]
	end

	self.needCourage = nil

	if self.missionType == xyd.TimeCloisterDressMissionType.COURAGE then
		self.needCourage = info.value.mission_params1
	end

	self.needCharm = nil

	if self.missionType == xyd.TimeCloisterDressMissionType.CHARM then
		self.needCharm = info.value.mission_params1
	end

	self.needKnowledge = nil

	if self.missionType == xyd.TimeCloisterDressMissionType.KNOWLEDGE then
		self.needKnowledge = info.value.mission_params1
	end

	self.needThreeAttrSum = nil

	if self.missionType == xyd.TimeCloisterDressMissionType.THREE_ATTR_SUM then
		self.needThreeAttrSum = info.value.mission_params1
	end
end

function TimeCloisterShowDressWindow:getInfos(index)
	if self.eventWithInfos[self.pageNum] and self.eventWithInfos[self.pageNum][index] then
		return self.eventWithInfos[self.pageNum][index]
	end

	local openArr = {}
	local lockArr = {}

	for i, data in pairs(self.items_arr[index]) do
		local isLock = false

		if self.needPos ~= 0 then
			local dressId = xyd.tables.senpaiDressItemTable:getDressId(data.itemID)
			local pos = xyd.tables.senpaiDressTable:getPos(dressId)

			if self.needPos ~= pos then
				isLock = true
			end
		end

		if not isLock and self.missionType == xyd.TimeCloisterDressMissionType.QLT then
			local qlt = xyd.tables.senpaiDressItemTable:getQlt(data.itemID)

			if qlt < self.needQlt then
				isLock = true
			end
		end

		if not isLock and self.missionType == xyd.TimeCloisterDressMissionType.QLT_START then
			local qlt = xyd.tables.senpaiDressItemTable:getQlt(data.itemID)
			local start = xyd.tables.senpaiDressItemTable:getStar(data.itemID)

			if qlt ~= self.needQlt or start < self.needStart then
				isLock = true
			end
		end

		if not isLock and self.missionType == xyd.TimeCloisterDressMissionType.COURAGE then
			local courage = xyd.tables.senpaiDressItemTable:getBase1(data.itemID)

			if courage < self.needCourage then
				isLock = true
			end
		end

		if not isLock and self.missionType == xyd.TimeCloisterDressMissionType.CHARM then
			local charm = xyd.tables.senpaiDressItemTable:getBase2(data.itemID)

			if charm < self.needCharm then
				isLock = true
			end
		end

		if not isLock and self.missionType == xyd.TimeCloisterDressMissionType.KNOWLEDGE then
			local knowledge = xyd.tables.senpaiDressItemTable:getBase3(data.itemID)

			if knowledge < self.needKnowledge then
				isLock = true
			end
		end

		if not isLock and self.missionType == xyd.TimeCloisterDressMissionType.THREE_ATTR_SUM then
			local courage = xyd.tables.senpaiDressItemTable:getBase1(data.itemID)
			local charm = xyd.tables.senpaiDressItemTable:getBase2(data.itemID)
			local knowledge = xyd.tables.senpaiDressItemTable:getBase3(data.itemID)
			local threeAttrSum = courage + charm + knowledge

			if threeAttrSum < self.needThreeAttrSum then
				isLock = true
			end
		end

		local param = {
			itemID = data.itemID,
			isLock = isLock
		}

		if isLock then
			table.insert(lockArr, param)
		else
			table.insert(openArr, param)
		end
	end

	for i in pairs(lockArr) do
		table.insert(openArr, lockArr[i])
	end

	if not self.eventWithInfos[self.pageNum] then
		self.eventWithInfos[self.pageNum] = {}
	end

	self.eventWithInfos[self.pageNum][index] = openArr

	return self.eventWithInfos[self.pageNum][index]
end

function TimeCloisterShowDressWindow:showTweenFun(itemId, isShow, position)
	if self.showTweenSequence then
		self.showTweenSequence:Kill(true)

		self.showTweenSequence = nil
	end

	if isShow then
		if self.showTweenIcon then
			self.showTweenIcon:getGameObject():SetActive(true)
		end

		self.choiceItemId = itemId

		self:setTweenDisEnabled(false)

		local items = self.wrapContent_:getItems()

		for i in pairs(items) do
			items[i]:setIsMustUpdate(true)
		end

		local infos = self:getInfos(self.showQuality)

		self.wrapContent_:setInfos(infos, {
			keepPosition = true
		})
	else
		if self.showTweenIcon then
			self.showTweenIcon:getGameObject():SetActive(false)
		end

		self.choiceItemId = -1

		self:setTweenDisEnabled(true)

		return
	end

	if not self.showTweenIcon then
		local params = {
			noClick = true,
			show_has_num = true,
			itemID = itemId,
			uiRoot = self.showTweenCon.gameObject
		}
		self.showTweenIcon = xyd.getItemIcon(params)
	else
		self.showTweenIcon:setInfo({
			noClick = true,
			show_has_num = true,
			itemID = itemId
		})
	end

	local pos = self.infoCon.gameObject.transform:InverseTransformPoint(position)

	self.showTweenIcon:getGameObject():SetLocalPosition(pos.x, pos.y, pos.z)

	local targetVector3 = self.addBg.gameObject.transform.localPosition
	local tween = self:getSequence()

	tween:Append(self.showTweenIcon:getGameObject().transform:DOLocalMove(Vector3(targetVector3.x, targetVector3.y, targetVector3.z), 0.2))
	tween:AppendCallback(function ()
		if tween then
			tween:Kill(true)
		end

		self.showTweenSequence = nil

		self.showTweenIcon:setInfo({
			noClick = false,
			show_has_num = true,
			itemID = itemId,
			callback = function ()
				local items = self.wrapContent_:getItems()

				for i in pairs(items) do
					if items[i]:getCurID() == self.choiceItemId then
						items[i]:setChoose(false)
					end
				end

				self.showTweenIcon:getGameObject():SetActive(false)

				self.choiceItemId = -1
			end
		})
		self:setTweenDisEnabled(true)
	end)

	self.showTweenSequence = tween
end

function TimeCloisterShowDressWindow:getChoiceItemId()
	return self.choiceItemId
end

function TimeCloisterShowDressWindow:setTweenDisEnabled(state)
	self.showBtnBoxCollider.enabled = state

	self:setArrowState("left", true)
	self:setArrowState("right", true)
end

function TimeCloisterShowDressWindow:setArrowState(type, state)
	if type == "left" then
		if self.leftArrow.gameObject.activeSelf then
			if self.pageNum <= 1 then
				self.leftArrowBoxCollider.enabled = false
			else
				self.leftArrowBoxCollider.enabled = state
			end
		end
	elseif type == "right" and self.rightArrow.gameObject.activeSelf then
		if self.allNum <= self.pageNum then
			self.rightArrowBoxCollider.enabled = false
		else
			self.rightArrowBoxCollider.enabled = state
		end
	end
end

function TimeCloisterShowDressWindow:getCurPageInfo()
	return self.allEvent[self.pageNum]
end

function TimeCloisterItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.itemCon = self.go:NodeByName("itemCon").gameObject
end

function TimeCloisterItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.curID == info.itemID and info.isLock == self.isLock and not self.isMustUpdate then
		self.isMustUpdate = false

		return
	end

	self.curID = info.itemID
	self.isLock = info.isLock

	if not self.itemIcon then
		local params = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			itemID = info.itemID,
			uiRoot = self.itemCon.gameObject
		}
		self.itemIcon = xyd.getItemIcon(params)
	else
		self.itemIcon:setInfo({
			show_has_num = true,
			itemID = info.itemID
		})
	end

	self:checkCondition()
end

function TimeCloisterItem:getCurID()
	return self.curID
end

function TimeCloisterItem:setChoose(state)
	if self.itemIcon then
		self.itemIcon:setChoose(state)
	end
end

function TimeCloisterItem:onClickItem()
	if self.curID == self.parent:getChoiceItemId() then
		self.parent:showTweenFun(self.curID, false)
		self.itemIcon:setChoose(false)
	else
		self.parent:showTweenFun(self.curID, true, self.itemIcon:getGameObject().transform.position)
		self.itemIcon:setChoose(true)
	end
end

function TimeCloisterItem:setIsMustUpdate(state)
	self.isMustUpdate = state
end

function TimeCloisterItem:checkCondition()
	if self.isLock then
		self.itemIcon.callback = nil

		self:setChoose(false)
		self.itemIcon:setLock(true)
	else
		function self.itemIcon.callback()
			self:onClickItem()
		end

		self.itemIcon:setLock(false)

		if self.curID == self.parent:getChoiceItemId() then
			self:setChoose(true)
		else
			self:setChoose(false)
		end
	end
end

return TimeCloisterShowDressWindow
