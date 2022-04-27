local BaseWindow = import(".BaseWindow")
local GuildWarFormationWindow = class("GuildWarFormationWindow", BaseWindow)
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")

function GuildWarFormationWindow:ctor(name, params)
	GuildWarFormationWindow.super.ctor(self, name, params)

	self.heroIconRootList_ = {}
	self.heroIconList_ = {}
	self.data = params
end

function GuildWarFormationWindow:initWindow()
	GuildWarFormationWindow.super.initWindow(self)

	self.content_ = self.window_:ComponentByName("content", typeof(UISprite)).gameObject
	local contentTrans = self.content_.transform
	self.labelTitle_ = contentTrans:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn_ = contentTrans:NodeByName("closeBtn").gameObject
	self.labelPoint_ = contentTrans:ComponentByName("group/point", typeof(UILabel))
	self.labelFront_ = contentTrans:ComponentByName("group/labelFront", typeof(UILabel))
	self.labelBack_ = contentTrans:ComponentByName("group/labelBack", typeof(UILabel))

	for i = 1, 6 do
		local heroIcon = {
			root = contentTrans:NodeByName("group/groupPartner/HeroIcon" .. i).gameObject,
			cover = contentTrans:NodeByName("group/groupPartner/HeroIcon" .. i .. "/cover").gameObject
		}

		table.insert(self.heroIconRootList_, heroIcon)
	end

	UIEventListener.Get(self.closeBtn_.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow("guild_war_formation_window")
	end

	self:initUI()
end

function GuildWarFormationWindow:initUI()
	local data = self.data
	local petID = 0

	if data and data.pet then
		petID = data.pet.pet_id
	end

	local showRootList = {}

	for i = 1, 6 do
		showRootList[i] = 0
	end

	for i = 1, #data.partners do
		local pos = data.partners[i].pos

		if pos and pos >= 0 then
			showRootList[i] = 1
		end

		local partner = Partner.new()

		partner:populate(data.partners[i])

		local partnerInfo = partner:getInfo()
		partnerInfo.onClick = true
		local heroIcon = HeroIcon.new(self.heroIconRootList_[pos].root)

		heroIcon:setInfo(partnerInfo, petID, partner)

		self.heroIconList_[i] = heroIcon

		if showRootList[i] == 0 then
			self.heroIconList_[i]:SetActive(false)
		else
			self.heroIconList_[i]:SetActive(true)
		end
	end

	self.labelTitle_.text = __(self:winName())
	self.labelPoint_.text = tostring(self.data.power)
	self.labelBack_.text = __("BACK_ROW")
	self.labelFront_.text = __("FRONT_ROW")
end

return GuildWarFormationWindow
