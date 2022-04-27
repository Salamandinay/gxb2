local FairArenaBackpackWindow = class("FairArenaBackpackWindow", import(".BaseWindow"))
local HeroIcon = import("app.components.HeroIcon")
local ItemIcon = import("app.components.ItemIcon")

function FairArenaBackpackWindow:ctor(name, params)
	FairArenaBackpackWindow.super.ctor(self, name, params)
end

function FairArenaBackpackWindow:initWindow()
	FairArenaBackpackWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:updateContent()
	self:register()

	local isCanShowFirstEquipRedPoint = xyd.db.misc:getValue("is_can_show_first_equip_red_point")

	if isCanShowFirstEquipRedPoint ~= nil and isCanShowFirstEquipRedPoint == "2" then
		xyd.db.misc:setValue({
			value = "0",
			key = "is_can_show_first_equip_red_point"
		})
	end

	local fair_arena_explore_wd = xyd.WindowManager.get():getWindow("fair_arena_explore_window")

	if fair_arena_explore_wd then
		fair_arena_explore_wd:checkShowEquipRedPoint()
	end
end

function FairArenaBackpackWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.tipsLabel_ = winTrans:ComponentByName("tipsLabel_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.partnerGroup = winTrans:NodeByName("partnerGroup").gameObject
	self.textLabel1_ = self.partnerGroup:ComponentByName("textLabel_", typeof(UILabel))
	self.scrollView1 = self.partnerGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.itemGroup1 = self.partnerGroup:NodeByName("scrollView/itemGroup").gameObject
	self.layout1 = self.itemGroup1:GetComponent(typeof(UILayout))
	self.labelNoneTips1 = self.partnerGroup:ComponentByName("labelNoneTips", typeof(UILabel))
	self.artifactGroup = winTrans:NodeByName("artifactGroup").gameObject
	self.textLabel2_ = self.artifactGroup:ComponentByName("textLabel_", typeof(UILabel))
	self.scrollView2 = self.artifactGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.itemGroup2 = self.artifactGroup:NodeByName("scrollView/itemGroup").gameObject
	self.layout2 = self.itemGroup2:GetComponent(typeof(UILayout))
	self.labelNoneTips2 = self.artifactGroup:ComponentByName("labelNoneTips", typeof(UILabel))
end

function FairArenaBackpackWindow:initUIComponent()
	self.titleLabel_.text = __("FAIR_ARENA_BACKPACK")
	self.tipsLabel_.text = __("FAIR_ARENA_DESC_USE_ONLY2")
	self.textLabel1_.text = __("FAIR_ARENA_TEAM_PARTNER")
	self.textLabel2_.text = __("FAIR_ARENA_TEAM_EQUIP")
	self.labelNoneTips1.text = __("NO_PARTNER_3")
	self.labelNoneTips2.text = __("NO_ARTIFACT")
	self.pNodes = {}
	self.aNodes = {}
end

function FairArenaBackpackWindow:updateContent()
	local partners = xyd.models.fairArena:getPartners()

	for i = 1, #partners do
		if not self.pNodes[i] then
			self.pNodes[i] = HeroIcon.new(self.itemGroup1)
		end

		local params = {
			show_has_num = false,
			isShowSelected = false,
			tableID = partners[i]:getTableID(),
			lev = partners[i].lev,
			grade = partners[i].grade,
			equips = partners[i].equipments,
			equip_id = partners[i]:getEquipment()[6],
			dragScrollView = self.scrollView1,
			callback = function ()
				xyd.WindowManager.get():openWindow("fair_arena_partner_info_window", {
					partnerID = partners[i]:getPartnerID(),
					list = xyd.models.fairArena:getPartnerIds()
				})
			end
		}

		self.pNodes[i]:setInfo(params)
	end

	self.layout1:Reposition()

	if #partners == 0 then
		self.labelNoneTips1:SetActive(true)
	end

	local artifacts = xyd.models.fairArena:getEquips()

	for i = 1, #artifacts do
		if not self.aNodes[i] then
			self.aNodes[i] = ItemIcon.new(self.itemGroup2)
		end

		local avatar_src = nil

		if artifacts[i].table_id then
			avatar_src = xyd.tables.partnerTable:getAvatar(artifacts[i].table_id)
		end

		self.aNodes[i]:setInfo({
			show_has_num = false,
			itemID = xyd.tables.activityFairArenaBoxEquipTable:getEquipID(artifacts[i].id),
			avatar_src = avatar_src,
			dragScrollView = self.scrollView2
		})
	end

	self.layout2:Reposition()

	if #artifacts == 0 then
		self.labelNoneTips2:SetActive(true)
	end
end

function FairArenaBackpackWindow:register()
	FairArenaBackpackWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_EQUIP, handler(self, self.updateContent))
end

return FairArenaBackpackWindow
