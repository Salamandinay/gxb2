local ShrineHurdleAutoSettingWindow = class("ShrineHurdleAutoSettingWindow", import(".BaseWindow"))
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")

function ShrineHurdleAutoSettingWindow:ctor(name, params)
	ShrineHurdleAutoSettingWindow.super.ctor(self, name, params)
end

function ShrineHurdleAutoSettingWindow:initWindow()
	self:getUIComponent()
	self:layout()
end

function ShrineHurdleAutoSettingWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = winTrans:ComponentByName("title", typeof(UILabel))
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.setBtn_ = winTrans:NodeByName("setBtn").gameObject
	self.setBtnLabel_ = winTrans:ComponentByName("setBtn/label", typeof(UILabel))
	self.startBtn_ = winTrans:NodeByName("startBtn").gameObject
	self.startBtnLabel_ = winTrans:ComponentByName("startBtn/label", typeof(UILabel))
	self.labelTips_ = winTrans:ComponentByName("labtlTips", typeof(UILabel))

	for i = 1, 4 do
		local selectGroup = winTrans:NodeByName("selectGroup" .. i).gameObject
		self["selectTips" .. i] = selectGroup:ComponentByName("labelTips", typeof(UILabel))
		self["btnOpen" .. i] = selectGroup:NodeByName("btnOpen").gameObject
		self["btnOpenChoose" .. i] = self["btnOpen" .. i]:NodeByName("imgSelect").gameObject
		self["btnOpenLabel" .. i] = selectGroup:ComponentByName("labelOpen", typeof(UILabel))
		self["btnClose" .. i] = selectGroup:NodeByName("btnClose").gameObject
		self["btnCloseChoose" .. i] = self["btnClose" .. i]:NodeByName("imgSelect").gameObject
		self["btnCloseLabel" .. i] = selectGroup:ComponentByName("labelClose", typeof(UILabel))
		self["btnOpenLabel" .. i].text = __("YES")
		self["btnCloseLabel" .. i].text = __("NO")

		UIEventListener.Get(self["btnOpen" .. i]).onClick = function ()
			self:onClickOpen(i)
		end

		UIEventListener.Get(self["btnClose" .. i]).onClick = function ()
			self:onClickClose(i)
		end

		if xyd.Global.lang == "fr_fr" then
			self["selectTips" .. i].fontSize = 18
		end
	end

	self.heroContainer1 = winTrans:NodeByName("group1/icon1/hero1").gameObject
	self.heroContainer2 = winTrans:NodeByName("group1/icon2/hero2").gameObject
	self.heroContainer3 = winTrans:NodeByName("group2/icon3/hero3").gameObject
	self.heroContainer4 = winTrans:NodeByName("group2/icon4/hero4").gameObject
	self.heroContainer5 = winTrans:NodeByName("group2/icon5/hero5").gameObject
	self.heroContainer6 = winTrans:NodeByName("group2/icon6/hero6").gameObject

	for i = 1, 6 do
		self["hero" .. i] = HeroIcon.new(self["heroContainer" .. i])
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SHRINE_HURDLE_AUTO_HELP"
		})
	end

	UIEventListener.Get(self.startBtn_).onClick = handler(self, self.onClickStart)
	UIEventListener.Get(self.setBtn_).onClick = handler(self, self.onClickSetBtn)
end

function ShrineHurdleAutoSettingWindow:layout()
	self.autoInfo = xyd.models.shrineHurdleModel:getAutoInfo()
	self.autoInfo.is_auto = 0
	self.autoTeam, self.pet = xyd.models.shrineHurdleModel:getAutoTeam()
	self.titleLabel_.text = __("SHRINE_HURDLE_AUTO_TEXT01")
	self.selectTips1.text = __("SHRINE_HURDLE_AUTO_TEXT02")
	self.selectTips2.text = __("SHRINE_HURDLE_AUTO_TEXT03")
	self.selectTips3.text = __("SHRINE_HURDLE_AUTO_TEXT04")
	self.selectTips4.text = __("SHRINE_HURDLE_AUTO_TEXT05")
	self.labelTips_.text = __("SHRINE_HURDLE_AUTO_TEXT06")
	self.setBtnLabel_.text = __("SHRINE_HURDLE_AUTO_TEXT07")
	self.startBtnLabel_.text = __("SHRINE_HURDLE_AUTO_TEXT08")

	self:updateBtnState()
	self:updatePartnerList()
end

function ShrineHurdleAutoSettingWindow:updatePartnerList()
	if not self.autoTeam then
		self.autoTeam = {}
	end

	for i = 1, 6 do
		local pos = i
		local partner_id = self.autoTeam[i]

		if partner_id and tonumber(partner_id) and tonumber(partner_id) > 0 then
			local partnerInfo = xyd.models.shrineHurdleModel:getPartner(partner_id)
			local hp = partnerInfo.status.hp

			if hp and hp <= 0 then
				self["hero" .. tostring(pos)]:SetActive(false)
			else
				local newPartner = Partner.new()

				newPartner:populate(partnerInfo)

				newPartner.noClickSelected = true

				self["hero" .. tostring(pos)]:SetActive(true)
				self["hero" .. tostring(pos)]:setInfo(newPartner, self.pet, newPartner)
			end
		else
			self["hero" .. tostring(pos)]:SetActive(false)
		end
	end
end

function ShrineHurdleAutoSettingWindow:updateBtnState()
	if self.autoInfo.stop_dead and self.autoInfo.stop_dead == 1 then
		self.btnOpenChoose1:SetActive(true)
		self.btnCloseChoose1:SetActive(false)
	else
		self.btnOpenChoose1:SetActive(false)
		self.btnCloseChoose1:SetActive(true)
	end

	if self.autoInfo.reply and self.autoInfo.reply == 1 then
		self.btnOpenChoose2:SetActive(true)
		self.btnCloseChoose2:SetActive(false)
	else
		self.btnOpenChoose2:SetActive(false)
		self.btnCloseChoose2:SetActive(true)
	end

	if self.autoInfo.go_shop and self.autoInfo.go_shop == 1 then
		self.btnOpenChoose3:SetActive(true)
		self.btnCloseChoose3:SetActive(false)
	else
		self.btnOpenChoose3:SetActive(false)
		self.btnCloseChoose3:SetActive(true)
	end

	if self.autoInfo.stop_shop and self.autoInfo.stop_shop == 1 then
		self.btnOpenChoose4:SetActive(true)
		self.btnCloseChoose4:SetActive(false)
	else
		self.btnOpenChoose4:SetActive(false)
		self.btnCloseChoose4:SetActive(true)
	end
end

function ShrineHurdleAutoSettingWindow:onClickOpen(index)
	if index == 1 then
		self.autoInfo.stop_dead = 1
	elseif index == 2 then
		self.autoInfo.reply = 1
	elseif index == 3 then
		self.autoInfo.go_shop = 1
	elseif index == 4 then
		self.autoInfo.stop_shop = 1
	end

	self:updateBtnState()
end

function ShrineHurdleAutoSettingWindow:onClickClose(index)
	if index == 1 then
		self.autoInfo.stop_dead = 0
	elseif index == 2 then
		self.autoInfo.reply = 0
	elseif index == 3 then
		self.autoInfo.go_shop = 0
	elseif index == 4 then
		self.autoInfo.stop_shop = 0
	end

	self:updateBtnState()
end

function ShrineHurdleAutoSettingWindow:willClose(callback)
	xyd.models.shrineHurdleModel:setAutoInfo(self.autoInfo.is_auto, self.autoInfo.stop_dead, self.autoInfo.reply, self.autoInfo.go_shop, self.autoInfo.stop_shop)

	if self.autoInfo.is_auto == 1 then
		local win = xyd.WindowManager.get():getWindow("shrine_hurdle_window")

		if win then
			win:autoNext(1)
			win:updateAutonBtn()
		end

		xyd.WindowManager.get():closeWindow("shrine_hurdle_choose_buff_window")
	end

	ShrineHurdleAutoSettingWindow.super.willClose(self, callback)
end

function ShrineHurdleAutoSettingWindow:onClickStart()
	local hasPartner = false

	for i = 1, 6 do
		if tonumber(self.autoTeam[i]) and tonumber(self.autoTeam[i]) > 0 then
			hasPartner = true

			break
		end
	end

	if hasPartner then
		self.autoInfo.is_auto = 1

		self:close()
	else
		self:onClickSetBtn()
	end
end

function ShrineHurdleAutoSettingWindow:onClickSetBtn()
	xyd.WindowManager.get():openWindow("battle_formation_trial_window", {
		battleType = xyd.BattleType.SHRINE_HURDLE_SET,
		formation = self.autoTeam,
		pet = self.pet
	})
end

function ShrineHurdleAutoSettingWindow:setPartnerList(partnerParams, pet)
	self.pet = pet
	self.autoTeam = {}

	for _, partnerInfo in pairs(partnerParams) do
		self.autoTeam[partnerInfo.pos] = partnerInfo.partner_id
	end
end

return ShrineHurdleAutoSettingWindow
