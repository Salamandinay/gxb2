local BaseWindow = import(".BaseWindow")
local HeroChallengeVideoWindow = class("HeroChallengeVideoWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local cjson = require("cjson")

function HeroChallengeVideoWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.records = {}
	self.id = params.id
end

function HeroChallengeVideoWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()

	if xyd.models.heroChallenge:reqGetRecords(self.id) then
		self:onRecord()
	end
end

function HeroChallengeVideoWindow:getUIComponent()
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

function HeroChallengeVideoWindow:setLayout()
	for i = 1, 3 do
		self["group" .. tostring(i)]:SetActive(false)
	end
end

function HeroChallengeVideoWindow:register()
	HeroChallengeVideoWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.PARTNER_CHALLENGE_GET_RECORDS, handler(self, self.onRecord))

	for i = 1, 3 do
		UIEventListener.Get(self["btnVideo" .. i]).onClick = function ()
			if not self.records[i] then
				return
			end

			local data = xyd.models.heroChallenge:getReport(self.id, self.records[i].record_id)

			if data then
				xyd.EventDispatcher:inner():dispatchEvent({
					name = xyd.event.PARTNER_CHALLENGE_GET_REPORT,
					data = data
				})
			else
				xyd.models.heroChallenge:reqGetReport(self.id, self.records[i].record_id)
			end
		end
	end
end

function HeroChallengeVideoWindow:onRecord()
	local records = xyd.models.heroChallenge:getRecords(self.id)

	if not records then
		return
	end

	self.records = records
	local count = math.min(#records, 3)

	for i = 1, count do
		self["group" .. i]:SetActive(true)

		local data = records[i]
		self["LabelPlayerName" .. tostring(i)].text = data.player_name
		local playerIcon = PlayerIcon.new(self["groupAvatar" .. tostring(i)])

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

return HeroChallengeVideoWindow
