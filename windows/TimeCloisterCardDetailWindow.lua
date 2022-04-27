local TimeCloisterCardDetailWindow = class("TimeCloisterCardDetailWindow", import(".BaseWindow"))
local timeCloister = xyd.models.timeCloisterModel

function TimeCloisterCardDetailWindow:ctor(name, params)
	self.card_id = params.card_id

	TimeCloisterCardDetailWindow.super.ctor(self, name, params)
end

function TimeCloisterCardDetailWindow:initWindow()
	self:getUIComponent()
	TimeCloisterCardDetailWindow.super.initWindow(self)
	self:layout()
	self:registerEvent()
end

function TimeCloisterCardDetailWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.upCon = groupAction:NodeByName("upCon").gameObject
	self.icon = self.upCon:ComponentByName("icon", typeof(UISprite))
	self.nameLabel = self.upCon:ComponentByName("nameLabel", typeof(UILabel))
	self.descLabel = self.upCon:ComponentByName("scroller/descLabel", typeof(UILabel))
	self.detailBtn = self.upCon:NodeByName("detailBtn").gameObject
	self.boxBtn = self.upCon:NodeByName("boxBtn").gameObject
	self.bgUISprite = self.upCon:ComponentByName("bg", typeof(UISprite))
	self.scroller = self.upCon:NodeByName("scroller").gameObject
	self.scrollerUIScrollView = self.upCon:ComponentByName("scroller", typeof(UIScrollView))
	self.downCon = groupAction:NodeByName("downCon").gameObject
	self.tipsBtn = self.downCon:NodeByName("tipsBtn").gameObject
	self.tipsLabel = self.downCon:ComponentByName("tipsLabelCon/tipsLabel", typeof(UILabel))
	self.tipsBtnBg = groupAction:NodeByName("tipsBtnBg").gameObject
end

function TimeCloisterCardDetailWindow:layout()
	local cardTable = xyd.tables.timeCloisterCardTable
	self.nameLabel.text = cardTable:getName(self.card_id)
	self.descLabel.text = cardTable:getDesc(self.card_id)
	local img = xyd.tables.timeCloisterCardTable:getImg(self.card_id)

	xyd.setUISpriteAsync(self.icon, nil, img)
	xyd.models.timeCloisterModel:changeCommonCardUI(self.upCon)

	local type = xyd.tables.timeCloisterCardTable:getType(self.card_id)

	if type == xyd.TimeCloisterCardType.PLOT_EVENT then
		self.detailBtn.gameObject:SetActive(true)
	else
		self.detailBtn.gameObject:SetActive(false)
	end

	local tec_id = xyd.tables.timeCloisterCardTable:getTec(self.card_id)
	local isShowDown = false
	local next_id = xyd.tables.timeCloisterCardTable:getNextId(self.card_id)

	if next_id and next_id > 0 then
		local lock_type = xyd.tables.timeCloisterCardTable:getLock(next_id)

		if lock_type and lock_type == 2 then
			self.downCon.gameObject:SetActive(true)
			self.tipsBtnBg.gameObject:SetActive(true)

			isShowDown = true
			self.tipsLabel.text = __("TIME_CLOISTER_TEXT62")
			tec_id = xyd.tables.timeCloisterCardTable:getTec(next_id)
		end
	else
		local lock_type = xyd.tables.timeCloisterCardTable:getLock(self.card_id)

		if lock_type and lock_type == 2 and tec_id and tec_id > 0 then
			self.downCon.gameObject:SetActive(true)
			self.tipsBtnBg.gameObject:SetActive(true)

			isShowDown = true
			self.tipsLabel.text = __("TIME_CLOISTER_TEXT62")
		end
	end

	if xyd.Global.lang == "fr_fr" then
		self.downCon:X(8)
		self.tipsLabel.gameObject:X(0)

		self.tipsLabel.width = 350
		self.tipsBtnBg:GetComponent(typeof(UIWidget)).width = 410
	end

	if isShowDown then
		local time_cloister_probe_wd = xyd.WindowManager.get():getWindow("time_cloister_probe_window")
		local group = xyd.tables.timeCloisterTecTable:getGroup(tec_id)

		if time_cloister_probe_wd and time_cloister_probe_wd:getCloister() then
			self.info = timeCloister:getTechInfoByCloister(time_cloister_probe_wd:getCloister())[group]

			if self.info and self.info[tec_id] and self.info[tec_id].maxLv <= self.info[tec_id].curLv then
				self.downCon.gameObject:SetActive(false)
				self.tipsBtnBg.gameObject:SetActive(false)
			end
		end
	end

	if self:getDropBoxId() > -1 then
		self.boxBtn:SetActive(true)
	else
		self.boxBtn:SetActive(false)
	end

	self.scrollerUIScrollView:ResetPosition()
end

function TimeCloisterCardDetailWindow:onClickTipsTech()
	local time_cloister_probe_wd = xyd.WindowManager.get():getWindow("time_cloister_probe_window")

	if time_cloister_probe_wd and time_cloister_probe_wd:getCloister() then
		local tec = xyd.tables.timeCloisterCardTable:getTec(self.card_id)
		local next_id = xyd.tables.timeCloisterCardTable:getNextId(self.card_id)

		if next_id and next_id > 0 then
			tec = xyd.tables.timeCloisterCardTable:getTec(next_id)
		end

		local group = xyd.tables.timeCloisterTecTable:getGroup(tec)

		xyd.WindowManager.get():openWindow("time_cloister_tech_detail_window", {
			cloister = time_cloister_probe_wd:getCloister(),
			group = group,
			enterOnCilckId = tec
		})
		self:close()
	end
end

function TimeCloisterCardDetailWindow:registerEvent()
	UIEventListener.Get(self.detailBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("time_cloister_card_plot_window", {
			card_id = self.card_id
		})
	end)
	UIEventListener.Get(self.tipsBtn).onClick = handler(self, function ()
		self:onClickTipsTech()
	end)
	UIEventListener.Get(self.tipsBtnBg).onClick = handler(self, function ()
		self:onClickTipsTech()
	end)
	UIEventListener.Get(self.boxBtn).onClick = handler(self, function ()
		local dropBoxId = self:getDropBoxId()

		if dropBoxId > -1 then
			xyd.WindowManager.get():openWindow("drop_probability_window", {
				box_id = tonumber(dropBoxId)
			})
		end
	end)
end

function TimeCloisterCardDetailWindow:getDropBoxId()
	local awards = xyd.tables.timeCloisterCardTable:getAwards(self.card_id)
	local awardType = xyd.tables.timeCloisterCardTable:getAwardType(self.card_id)

	if awardType and awardType == 1 then
		return tonumber(awards)
	else
		local subCards = xyd.tables.timeCloisterCardTable:getSubCard(self.card_id)

		if subCards and #subCards > 0 then
			local sub_awards = xyd.tables.timeCloisterCardTable:getAwards(subCards[1])
			local subAwardType = xyd.tables.timeCloisterCardTable:getAwardType(self.card_id)

			if subAwardType and subAwardType == 1 then
				return tonumber(sub_awards)
			end

			return -1
		else
			return -1
		end
	end
end

return TimeCloisterCardDetailWindow
