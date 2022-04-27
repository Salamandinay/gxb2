local BaseComponent = import("app.components.BaseComponent")
local ActivitySuperHeroClub = import("app.windows.activity.ActivitySuperHeroClub")
local BaseWindow = import(".BaseWindow")
local ActivitySuperHeroClubPreWindow = class("ActivitySuperHeroClubPreWindow", BaseWindow)

function ActivitySuperHeroClubPreWindow:ctor(name, params)
	ActivitySuperHeroClubPreWindow.super.ctor(self, name, params)

	self.sortIds = {}
	self.nowRound = params.nowRound
end

function ActivitySuperHeroClubPreWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	ActivitySuperHeroClubPreWindow.super.register(self)
	self:initListShow()
end

function ActivitySuperHeroClubPreWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("e:Group").gameObject
	self.labelWinTitle0 = groupMain:ComponentByName("labelWinTitle0", typeof(UILabel))
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.partnerScroller = groupMain:ComponentByName("partnerScroller", typeof(UIScrollView))
	self.partnerContainer = self.partnerScroller:NodeByName("partnerContainer").gameObject
end

function ActivitySuperHeroClubPreWindow:initUIComponent()
	self.labelWinTitle0.text = __("ACTIVITY_PARTNER_JACKPOT_PREVIEW")
end

function ActivitySuperHeroClubPreWindow:initListShow()
	self.sortIds = {}
	local returnList = {}
	local ids = xyd.tables.activityPartnerJackpotTable:getIds()

	for k, v in pairs(ids) do
		local id = tonumber(v)

		if self.nowRound <= id then
			table.insert(self.sortIds, id)
		else
			table.insert(returnList, id)
		end
	end

	for k, v in pairs(returnList) do
		table.insert(self.sortIds, v)
	end

	local addHeight = 409
	local depth = self.partnerScroller.gameObject:GetComponent(typeof(UIPanel)).depth

	for k, id in pairs(self.sortIds) do
		local item = ActivitySuperHeroClub.getPreItem(self).new(self.partnerContainer, id, k)
		item.go.gameObject.transform.localPosition = Vector3(0, addHeight, 0)
		item.go:GetComponent(typeof(UIPanel)).depth = depth + 3
		depth = depth + 3
		local ids = xyd.tables.activityPartnerJackpotTable:get():getPartnerIds(id)
		local heightDis = 68 + math.ceil(#ids / 5) * 104 + (math.ceil(#ids / 5) - 1) * 17 + 20
		addHeight = addHeight - heightDis
	end
end

return ActivitySuperHeroClubPreWindow
