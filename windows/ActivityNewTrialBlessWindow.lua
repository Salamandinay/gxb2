local BaseWindow = import(".BaseWindow")
local GroupBuffIcon = import("app.components.GroupBuffIcon")
local ActivityNewTrialBlessWindow = class("ActivityNewTrialBlessWindow", BaseWindow)

function ActivityNewTrialBlessWindow:ctor(name, params)
	ActivityNewTrialBlessWindow.super.ctor(self, name, params)

	self.buffIds = {}
	self.buffIds = params.buffIds
end

function ActivityNewTrialBlessWindow:initWindow()
	ActivityNewTrialBlessWindow.super.initWindow(self)
	self:getComponent()
	self:layout()
	self:register()
end

function ActivityNewTrialBlessWindow:getComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.eImage_ = goTrans:NodeByName("e:image").gameObject
	self.winTitle_ = goTrans:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = goTrans:NodeByName("closeBtn").gameObject
	self.tipsLabel_ = goTrans:ComponentByName("tipsLabel", typeof(UILabel))
	self.cardGroup_ = goTrans:NodeByName("groupContent/cardGroup").gameObject

	UIEventListener.Get(self.eImage_).onClick = function ()
		self.chooseIndex_ = nil

		xyd.WindowManager.get():closeWindow("new_group_buff_detail_window")
	end
end

function ActivityNewTrialBlessWindow:layout()
	self.tipsLabel_.text = __("NEW_TRIAL_BLESS_TIPS")
	self.winTitle_.text = __("ACTIVITY_NEW_TRIAL_BLESS_WINDOW")
	local tableUse = xyd.models.trial:getTableUse()
	local unShowIds = tableUse:getBuffIDs(4)
	local showList = {}

	for index, id in ipairs(self.buffIds) do
		if xyd.arrayIndexOf(unShowIds, tonumber(id)) < 0 then
			table.insert(showList, id)
		end
	end

	for i = 1, 6 do
		local group = self.cardGroup_:NodeByName("group" .. i).gameObject
		self["groupIcon" .. i] = group:NodeByName("groupIcon1").gameObject
		self["label" .. i] = group:ComponentByName("label1", typeof(UILabel))
		self["imgSelect" .. i] = group:NodeByName("imgSelect").gameObject

		self["imgSelect" .. i]:SetActive(false)

		self["group" .. i] = group

		if not showList[i] then
			group:SetActive(false)
		else
			group:SetActive(true)

			local id = showList[i]
			local icon = GroupBuffIcon.new(self["groupIcon" .. tostring(i)])

			icon:SetLocalScale(1.35, 1.35, 1)
			icon:setInfo(id, true, xyd.GroupBuffIconType.NEW_TRIAL)

			local name_ = xyd.tables.newTrialBuffTable:getName(id)
			self["label" .. i].text = name_
		end

		UIEventListener.Get(group).onClick = function ()
			if self.chooseIndex_ == i then
				self.chooseIndex_ = nil

				xyd.WindowManager.get():closeWindow("new_group_buff_detail_window")
			else
				self.chooseIndex_ = i

				xyd.WindowManager.get():openWindow("new_group_buff_detail_window", {
					contenty = 200,
					buffID = showList[i],
					type = xyd.GroupBuffIconType.NEW_TRIAL
				})
			end

			self:updateSelect()
		end
	end

	self:updateSelect()
end

function ActivityNewTrialBlessWindow:updateSelect()
	for i = 1, 6 do
		self["imgSelect" .. i]:SetActive(self.chooseIndex_ == i)
	end
end

function ActivityNewTrialBlessWindow:willClose()
	ActivityNewTrialBlessWindow.super.willClose(self)

	local win = xyd.WindowManager.get():getWindow("new_group_buff_detail_window")

	if win then
		xyd.WindowManager.get():closeWindow("new_group_buff_detail_window")
	end
end

return ActivityNewTrialBlessWindow
