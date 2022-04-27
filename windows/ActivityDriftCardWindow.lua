local BaseWindow = import(".BaseWindow")
local ActivityDriftCardWindow = class("ActivityDriftCardWindow", BaseWindow)
local cjson = require("cjson")

function ActivityDriftCardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.parent = params.parent
	self.autoPlay = params.autoPlay
	self.buff = nil
	self.selected = nil
end

function ActivityDriftCardWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupMain = winTrans:NodeByName("groupMain").gameObject
	self.label = self.groupMain:ComponentByName("label", typeof(UILabel))
	self.mask_ = self.groupMain:ComponentByName("mask_", typeof(UISprite))

	for i = 1, 3 do
		self["award" .. i] = self.groupMain:NodeByName("award" .. i).gameObject
		self["awardG" .. i] = self["award" .. i]:ComponentByName("g" .. i, typeof(UIWidget))
		self["mask" .. i] = self["awardG" .. i]:NodeByName("gMask").gameObject
		self["bg" .. i] = self["awardG" .. i]:ComponentByName("bg", typeof(UISprite))
		self["fg" .. i] = self["awardG" .. i]:ComponentByName("fg", typeof(UISprite))
		self["icon" .. i] = self["fg" .. i]:ComponentByName("icon", typeof(UISprite))
		self["label1" .. i] = self["fg" .. i]:ComponentByName("label1", typeof(UILabel))
		self["label2" .. i] = self["fg" .. i]:ComponentByName("label2", typeof(UILabel))
	end
end

function ActivityDriftCardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self.mask_:SetActive(false)
	self:initLayout()
	self:registerEvent()
end

function ActivityDriftCardWindow:playOpenAnimation(callback)
	for i = 1, 3 do
		self["awardG" .. i]:SetLocalScale(0, 0, 0)
	end

	BaseWindow.playOpenAnimation(self, function ()
		if callback then
			callback()
		end

		local sequence = self:getSequence()

		sequence:Append(self.awardG1.transform:DOScale(Vector3(1.1, 1.1, 1.1), 0.3))
		sequence:Join(self.awardG2.transform:DOScale(Vector3(1.1, 1.1, 1.1), 0.3))
		sequence:Join(self.awardG3.transform:DOScale(Vector3(1.1, 1.1, 1.1), 0.3))
		sequence:Append(self.awardG1.transform:DOScale(Vector3(1, 1, 1), 0.1))
		sequence:Join(self.awardG2.transform:DOScale(Vector3(1, 1, 1), 0.1))
		sequence:Join(self.awardG3.transform:DOScale(Vector3(1, 1, 1), 0.1))
		sequence:AppendCallback(function ()
			if self.autoPlay then
				self:autoTurnCard()
			end
		end)
	end)
end

function ActivityDriftCardWindow:initLayout()
	self.label.text = __("ACTIVITY_LAFULI_DRIFT_CARD")

	if self.autoPlay then
		for i = 1, 3 do
			self["awardG" .. i].gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		end

		self.label:SetActive(false)
	end
end

function ActivityDriftCardWindow:flop(index, isChosen)
	self["fg" .. index]:SetActive(true)

	local sequence = self:getSequence()
	local time = 0.3

	self["bg" .. index]:SetLocalScale(1, 1, 0)
	self["fg" .. index]:SetLocalScale(0, 1, 0)
	sequence:Append(self["bg" .. index].transform:DOScaleX(0, time)):Append(self["fg" .. index].transform:DOScaleX(1, time)):AppendCallback(function ()
		if isChosen then
			local effect2 = xyd.Spine.new(self["award" .. index])

			effect2:setInfo("fx_drift_card", function ()
				effect2:play("texiao01", 0, 1)
			end)

			if self.buff == 1 then
				local item = xyd.tables.activityLafuliDriftBuffTable:getParams(self.buff)

				xyd.models.itemFloatModel:pushNewItems({
					{
						item_id = item[1],
						item_num = item[2]
					}
				})
			end

			return
		end

		self.label.text = __("LOGIN_HANGUP_TEXT04")
	end)
end

function ActivityDriftCardWindow:layoutItem(touchIndex)
	local icon = xyd.tables.activityLafuliDriftBuffTable:getIcon(self.buff)

	xyd.setUISpriteAsync(self["icon" .. touchIndex], nil, icon, nil, , true)

	local textID = xyd.tables.activityLafuliDriftBuffTable:getTextID(self.buff)
	self["label1" .. touchIndex].text = xyd.tables.activityLafuliDriftTextTable:getTitle(textID)
	self["label2" .. touchIndex].text = xyd.tables.activityLafuliDriftTextTable:getDesc(textID)

	if xyd.Global.lang == "fr_fr" and (self.buff == 3 or self.buff == 5 or self.buff == 6 or self.buff == 7 or self.buff == 8) then
		self["label2" .. touchIndex].height = 100

		self["label2" .. touchIndex]:Y(-53)
	end

	self:flop(touchIndex, true)
	self.mask_:SetActive(true)
	math.randomseed(xyd.getServerTime())

	local ranRes1 = math.random(8)
	local ranRes2 = math.random(7)

	if ranRes1 == self.buff then
		ranRes1 = 9
	end

	local flag = false

	if self.buff <= ranRes2 then
		flag = true
		ranRes2 = ranRes2 + 1
	end

	if ranRes1 <= ranRes2 then
		ranRes2 = ranRes2 + 1
	end

	if not flag and self.buff <= ranRes2 then
		ranRes2 = ranRes2 + 1
	end

	self:waitForTime(0.5, function ()
		for i = 1, 3 do
			if i ~= touchIndex then
				if ranRes1 then
					local icon = xyd.tables.activityLafuliDriftBuffTable:getIcon(ranRes1)

					xyd.setUISpriteAsync(self["icon" .. i], nil, icon, nil, , true)

					local textID = xyd.tables.activityLafuliDriftBuffTable:getTextID(ranRes1)
					self["label1" .. i].text = xyd.tables.activityLafuliDriftTextTable:getTitle(textID)
					self["label2" .. i].text = xyd.tables.activityLafuliDriftTextTable:getDesc(textID)

					if xyd.Global.lang == "fr_fr" and (ranRes1 == 3 or ranRes1 == 5 or ranRes1 == 6 or ranRes1 == 7 or ranRes1 == 8) then
						self["label2" .. i].height = 100

						self["label2" .. i]:Y(-53)
					end

					ranRes1 = nil
				else
					local icon = xyd.tables.activityLafuliDriftBuffTable:getIcon(ranRes2)

					xyd.setUISpriteAsync(self["icon" .. i], nil, icon, nil, , true)

					local textID = xyd.tables.activityLafuliDriftBuffTable:getTextID(ranRes2)
					self["label1" .. i].text = xyd.tables.activityLafuliDriftTextTable:getTitle(textID)
					self["label2" .. i].text = xyd.tables.activityLafuliDriftTextTable:getDesc(textID)

					if xyd.Global.lang == "fr_fr" and (ranRes2 == 3 or ranRes2 == 5 or ranRes2 == 6 or ranRes2 == 7 or ranRes2 == 8) then
						self["label2" .. i].height = 100

						self["label2" .. i]:Y(-53)
					end
				end

				self:flop(i)
			end
		end

		self.mask_:SetActive(false)
	end)

	if self.autoPlay then
		self:waitForTime(2, function ()
			xyd.WindowManager.get():closeWindow(self.name_, function ()
				if self.buff == 5 then
					if self.index == 0 then
						xyd.showToast(__("ACTIVITY_LAFULI_DRIFT_MAX"))
					else
						self.parent:levelUp(self.index)
					end
				elseif self.buff == 6 then
					self.parent:levelDown(self.index)
				end

				self.parent:autoPlay()
			end)
		end)
	end
end

function ActivityDriftCardWindow:autoTurnCard()
	if self.autoPlay then
		math.randomseed(xyd.getServerTime())

		local i = math.random(3)
		local msg = messages_pb.lafuli_activity_select_buff_req()
		msg.activity_id = xyd.ActivityID.LAFULI_DRIFT
		msg.index = i

		xyd.Backend.get():request(xyd.mid.LAFULI_ACTIVITY_SELECT_BUFF, msg)

		self.selected = i
	end
end

function ActivityDriftCardWindow:registerEvent()
	UIEventListener.Get(self.window_.transform:NodeByName("WINDOWBG").gameObject).onClick = function ()
		if self.selected and not self.autoPlay then
			xyd.WindowManager.get():closeWindow(self.name_, function ()
				if self.buff == 5 then
					if self.index == 0 then
						xyd.showToast(__("ACTIVITY_LAFULI_DRIFT_MAX"))
					else
						self.parent:levelUp(self.index)
					end
				elseif self.buff == 6 then
					self.parent:levelDown(self.index)
				end
			end)
		end
	end

	for i = 1, 3 do
		UIEventListener.Get(self["awardG" .. tostring(i)].gameObject).onClick = function ()
			if not self.selected and not self.autoPlay then
				local msg = messages_pb.lafuli_activity_select_buff_req()
				msg.activity_id = xyd.ActivityID.LAFULI_DRIFT
				msg.index = i

				xyd.Backend.get():request(xyd.mid.LAFULI_ACTIVITY_SELECT_BUFF, msg)

				self.selected = i
			end
		end
	end

	self.eventProxy_:addEventListener(xyd.event.LAFULI_ACTIVITY_SELECT_BUFF, function (event)
		local detail = cjson.decode(event.data.detail)
		self.buff = detail.buff_id
		self.index = detail.pos

		xyd.SoundManager.get():playSound(xyd.SoundID.ARENA_AWARD)
		self:layoutItem(self.selected)
	end)
end

return ActivityDriftCardWindow
