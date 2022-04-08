local RedMark = class("RedMark", import(".BaseModel"))
local RedMarkItem = class("RedMarkItem")
local JointRedMark = class("JointRedMark")
local allMarkState = {}
local allMarkSwitchArr = {}

function RedMark:ctor()
	RedMark.super.ctor(self)

	self.markItems = {}
	self.markState = allMarkState
	self.jointRemark = {}
	self.markParams = {}
	self.markSwitchArr = allMarkSwitchArr
end

function RedMark:onRegister()
	RedMark.super.onRegister(self)
	self:registerEvent(xyd.event.RED_POINT, handler(self, self.onRedMarkInfo))
end

function RedMark:onRedMarkInfo(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local funID = event.data.function_id

	if not funID or not xyd.Func2RedMark[funID] then
		return
	end

	if xyd.checkFunctionOpen(funID, true) then
		return
	end

	self.markState[xyd.Func2RedMark[funID]] = true

	self:setMark(xyd.Func2RedMark[funID], true)
end

function RedMark:setMarkImg(id, obj, isEffect)
	if isEffect == nil then
		isEffect = false
	end

	if self.markItems[id] ~= nil then
		local tempMark = self.markItems[id]

		tempMark:setImage(obj, false, isEffect)
		tempMark:setState(self.markState[id] == true)

		return
	end

	if not obj then
		return
	end

	local markItem = RedMarkItem.new(id, obj, isEffect)
	self.markItems[id] = markItem

	if self.markState[id] == true then
		markItem:setState(true)
	else
		markItem:setState(false)
	end
end

function RedMark:setJointMarkImg(jointID, obj)
	if not obj then
		return
	end

	local i = #self.jointRemark - 1

	while i >= 0 do
		if self.jointRemark[i + 1].img == obj then
			print("set JointRedMark error")

			return
		end

		i = i - 1
	end

	local newJointMark = JointRedMark.new(jointID, obj)
	local count = 0
	local i = 0

	while i < #jointID do
		local id = jointID[i + 1]
		local markItem = self.markItems[id]

		if not markItem then
			markItem = RedMarkItem.new(id, nil)
			self.markItems[id] = markItem

			if self.markState[id] == true then
				markItem:setState(true)
			else
				markItem:setState(false)
			end
		end

		count = count + markItem.state_

		markItem:addJointRedMark(newJointMark)

		self.markItems[id] = markItem
		i = i + 1
	end

	newJointMark:modifyCount(count)
	table.insert(self.jointRemark, newJointMark)

	for i in pairs(jointID) do
		local idsearch = jointID[i]

		if not xyd.checkRedMarkSetting(idsearch) then
			self:reOpenSwitch(idsearch, false)
		end
	end
end

function RedMark:setMark(id, isShow, params)
	self.markState[id] = isShow

	if not self.markItems[id] then
		return
	end

	self.markItems[id]:setState(isShow)

	if params ~= nil then
		self.markItems[id].markParams = params
	end

	if isShow == true and xyd.checkRedMarkSetting(id) == false then
		self:reOpenSwitch(id, false)
	end
end

function RedMark:removeItem(item)
	self.markItems[item.id_] = nil
end

function RedMark:getRedState(id)
	if xyd.checkRedMarkSetting(id) == false then
		return false
	else
		return self.markState[id]
	end
end

function RedMark:getRedMarkParams(id)
	if self.markItems[id] == nil then
		return nil
	end

	return self.markItems[id].markParams
end

function RedMark:reOpenSwitch(id, state)
	if self.markItems[id] ~= nil then
		self.markItems[id]:reOpenSwitch(state)
	end
end

function RedMark:initMarkSwitchArr(localRedData)
	local redMarkIds = xyd.tables.deviceRedMarkTable:getIDs()

	for i in pairs(redMarkIds) do
		local redTypes = xyd.tables.deviceRedMarkTable:getRedMarkTypes(redMarkIds[i])

		for j in pairs(redTypes) do
			if not self.markSwitchArr[redTypes[j]] then
				self.markSwitchArr[redTypes[j]] = 1
			end
		end
	end

	for i in pairs(localRedData) do
		if localRedData[i] == -1 or localRedData[i] == "-1" then
			local redTypes = xyd.tables.deviceRedMarkTable:getRedMarkTypes(i)

			for j in pairs(redTypes) do
				if self.markSwitchArr[redTypes[j]] then
					self.markSwitchArr[redTypes[j]] = -1
				end
			end
		end

		if localRedData[i] == 1 or localRedData[i] == "1" then
			local redTypes = xyd.tables.deviceRedMarkTable:getRedMarkTypes(i)

			for j in pairs(redTypes) do
				if self.markSwitchArr[redTypes[j]] then
					self.markSwitchArr[redTypes[j]] = 1
				end
			end
		end
	end

	local a = 1
end

function RedMark:updateSwitchArr(id, state)
	local redTypes = xyd.tables.deviceRedMarkTable:getRedMarkTypes(id)

	for j in pairs(redTypes) do
		if self.markSwitchArr[redTypes[j]] then
			self.markSwitchArr[redTypes[j]] = tonumber(state)
		end
	end
end

function RedMarkItem:ctor(id, obj, isEffect)
	self.state_ = 0
	self.jointRedMarks = {}

	if isEffect == nil then
		isEffect = false
	end

	self.id_ = id
	self.img = obj
	self.oldImgActive = true

	if obj ~= nil then
		self.img:GetComponent(typeof(UIWidget)).onDispose = function ()
			if xyd.models.redMark then
				xyd.models.redMark:removeItem(self)
			end
		end

		self.img:SetActive(false)
	end

	self.isEffect = isEffect
end

function RedMarkItem:isImgNull()
	return self.img == nil
end

function RedMarkItem:setState(bool)
	if self.img ~= nil and not tolua.isnull(self.img) then
		self.img:SetActive(bool)

		self.oldImgActive = bool

		if self.isEffect then
			local effect = self.img

			if bool then
				effect:play("texiao01", 0, nil, true, 1, true)
			else
				effect:stop()
			end
		end
	end

	local delta = self.state_
	self.state_ = bool and 1 or 0
	delta = self.state_ - delta

	if delta == 0 then
		if bool == true and xyd.checkRedMarkSetting(self.id_) == false then
			self:reOpenSwitch(false)
		end

		return
	end

	local i = 0

	while i < #self.jointRedMarks do
		local jointMark = self.jointRedMarks[i + 1]

		if jointMark and jointMark:isValid() then
			jointMark:modifyCount(delta)
		end

		i = i + 1
	end

	if bool == true and xyd.checkRedMarkSetting(self.id_) == false then
		self:reOpenSwitch(false)
	end
end

function RedMarkItem:addJointRedMark(jointMark)
	table.insert(self.jointRedMarks, jointMark)
end

function RedMarkItem:setImage(obj, isDestory, isEffect)
	if isEffect == nil then
		isEffect = false
	end

	self.img = obj

	self.img:GetComponent(typeof(UIWidget)).onDispose = function ()
		if isDestory then
			xyd.models.redMark:removeItem(self)
		else
			self.img = nil
		end
	end

	self.img:SetActive(self.state_ == 1)

	if self.isEffect then
		local effect = self.img

		if self.state_ == 1 then
			effect:play("texiao01", 0, nil, true, 1, true)
		else
			effect:stop()
		end
	end
end

function RedMarkItem:reOpenSwitch(state)
	if state == true then
		if self.img ~= nil and not tolua.isnull(self.img) then
			self.img:SetActive(self.oldImgActive)
		end

		local i = 0

		while i < #self.jointRedMarks do
			local jointMark = self.jointRedMarks[i + 1]

			if jointMark and jointMark:isValid() then
				self:reOpenSwitchSearch(jointMark)
			end

			i = i + 1
		end
	else
		if self.img ~= nil and not tolua.isnull(self.img) then
			self.img:SetActive(false)
		end

		local i = 0

		while i < #self.jointRedMarks do
			local jointMark = self.jointRedMarks[i + 1]

			if jointMark and jointMark:isValid() then
				self:reOpenSwitchSearch(jointMark)
			end

			i = i + 1
		end
	end
end

function RedMarkItem:reOpenSwitchSearch(jointMark)
	local hasCloseNum = 0
	local isNeed = false
	local allCompareNum = 0

	for j in pairs(jointMark.jointIDs) do
		if allMarkState[jointMark.jointIDs[j]] ~= nil and allMarkState[jointMark.jointIDs[j]] == true and allMarkSwitchArr[jointMark.jointIDs[j]] ~= nil then
			allCompareNum = allCompareNum + 1
		end
	end

	for j in pairs(jointMark.jointIDs) do
		if allMarkState[jointMark.jointIDs[j]] ~= nil and allMarkState[jointMark.jointIDs[j]] == true and (not allMarkSwitchArr[jointMark.jointIDs[j]] or allMarkSwitchArr[jointMark.jointIDs[j]] == 1) then
			isNeed = true

			break
		end

		if allMarkSwitchArr[jointMark.jointIDs[j]] and allMarkSwitchArr[jointMark.jointIDs[j]] == -1 then
			hasCloseNum = hasCloseNum + 1
		end
	end

	if isNeed then
		jointMark:setImgActive(true)
	elseif allCompareNum <= hasCloseNum then
		jointMark:setImgActive(false)
	end
end

function JointRedMark:ctor(jointID, obj, initCount)
	self.jointIDs = {}
	self.stateCount = 0
	self.isValid_ = true
	self.isDestory = false

	if initCount == nil then
		initCount = 0
	end

	self.jointIDs = jointID
	self.img = obj

	self.img:GetComponent(typeof(UIWidget)).onDispose = function ()
		self.isValid_ = false
	end

	self.stateCount = initCount

	self.img:SetActive(true)
	self.img:SetActive(initCount > 0)
end

function JointRedMark:isValid()
	return self.isValid_
end

function JointRedMark:setImgActive(visible)
	if self.img and not tolua.isnull(self.img) and self.img.transform.parent and not tolua.isnull(self.img.transform.parent) and self.img.transform.parent.name == "MainUIActivityItem" then
		local mainWin = xyd.WindowManager.get():getWindow("main_window")

		if mainWin then
			mainWin:updateLatgeBtnRedPoint()
		end
	elseif self.img and not tolua.isnull(self.img) then
		self.img:SetActive(visible)
	end
end

function JointRedMark:modifyCount(delta)
	self.stateCount = self.stateCount + delta

	if self.img ~= nil and not tolua.isnull(self.img) then
		if self.img.transform.parent ~= nil and not tolua.isnull(self.img.transform.parent) and self.img.transform.parent.name == "MainUIActivityItem" then
			local mainWin = xyd.WindowManager.get():getWindow("main_window")

			if mainWin then
				mainWin:updateLatgeBtnRedPoint()
			end
		else
			self.img:SetActive(self.stateCount > 0)
		end
	end
end

return RedMark
