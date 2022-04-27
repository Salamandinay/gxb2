local BaseWindow = import(".BaseWindow")
local ActivityFairyTaleViewWindow = class("ActivityFairyTaleViewWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local json = require("cjson")

function ActivityFairyTaleViewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
	dump(params)

	self.records = params.records
	self.reports = params.reports
end

function ActivityFairyTaleViewWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()
end

function ActivityFairyTaleViewWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("group_old").gameObject
	self.labelWinTitle = content:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = content:NodeByName("closeBtn").gameObject
	local videoGroup = content:NodeByName("videoGroup").gameObject

	for i = 1, 3 do
		local group = videoGroup:NodeByName("group" .. i).gameObject
		self["group" .. i] = group
		self["groupAvatar" .. i] = group:NodeByName("groupAvatar").gameObject
		self["LabelPlayerName" .. i] = group:ComponentByName("LabelPlayerName", typeof(UILabel))
		self["btnVideo" .. i] = group:NodeByName("btnVideo").gameObject
	end
end

function ActivityFairyTaleViewWindow:setLayout()
	self.labelWinTitle.text = __("TowerVideoWindow")

	for i = 1, 3 do
		self["group" .. tostring(i)]:SetActive(false)
	end

	self:layout()
end

function ActivityFairyTaleViewWindow:register()
	ActivityFairyTaleViewWindow.super.register(self)

	for i = 1, 3 do
		UIEventListener.Get(self["btnVideo" .. tostring(i)]).onClick = function ()
			if not self.records[i] then
				return
			end

			local battle_report = self.reports[i]
			battle_report.is_video = true

			xyd.EventDispatcher:inner():dispatchEvent({
				name = xyd.event.FAIRY_CHALLENGE,
				data = battle_report
			})
		end
	end
end

function ActivityFairyTaleViewWindow:layout()
	local records = self.records
	local count = math.min(#records, 3)

	for i = 1, count do
		local data = records[i]

		if data.player_name then
			self["group" .. i]:SetActive(true)

			self["LabelPlayerName" .. tostring(i)].text = data.player_name
			local playerIcon = PlayerIcon.new(self["groupAvatar" .. i])

			playerIcon:setInfo({
				noClick = true,
				avatarID = data.avatar_id,
				avatar_frame_id = data.avatar_frame_id,
				lev = data.lev
			})

			local playerIconWidget = playerIcon.go:GetComponent(typeof(UIWidget))
			local groupWidget = self["groupAvatar" .. i]:GetComponent(typeof(UIWidget))

			playerIcon.go:SetLocalScale(groupWidget.width / playerIconWidget.width, groupWidget.height / playerIconWidget.height, 1)
		end
	end
end

return ActivityFairyTaleViewWindow
