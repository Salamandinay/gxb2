local BaseWindow = import(".BaseWindow")
local DatesPledgeWindow = class("DatesPledgeWindow", BaseWindow)
local MiscTable = xyd.tables.miscTable
local ParnterImg = import("app.components.PartnerImg")

function DatesPledgeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.partnerID = params.partner_id
	self.partner = xyd.models.slot:getPartner(self.partnerID)
	self.isDate = params.is_date
	self.isLongTouch = params.isLongTouch

	if params.show_id then
		self.show_id = params.show_id
	end

	self.canReplayPledgeAnimation = xyd.checkCondition(params.canReplayPledgeAnimation, true, false)
end

function DatesPledgeWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function DatesPledgeWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupPicture = groupAction:NodeByName("groupPicture").gameObject
	local topPanel = groupAction:NodeByName("topPanel").gameObject
	self.imgTitle = topPanel:ComponentByName("imgTitle", typeof(UISprite))
	self.content = topPanel:NodeByName("content").gameObject
	self.imgText01 = self.content:ComponentByName("imgText01", typeof(UISprite))
	self.imgText02 = self.content:ComponentByName("imgText02", typeof(UISprite))
	self.labelText01 = self.content:ComponentByName("labelText01", typeof(UILabel))
	self.labelText02 = self.content:ComponentByName("labelText02", typeof(UILabel))
	self.labelText08 = topPanel:ComponentByName("labelText08", typeof(UILabel))
	self.content2 = topPanel:NodeByName("content2").gameObject

	for i = 4, 7 do
		local key = "labelText0" .. i
		self[key] = self.content2:ComponentByName(key, typeof(UILabel))
	end

	self.groupText = topPanel:NodeByName("groupText").gameObject
	self.labelText03 = self.groupText:ComponentByName("labelText03", typeof(UILabel))
	self.labelDate = self.groupText:ComponentByName("labelDate", typeof(UILabel))
	self.btnVow = topPanel:NodeByName("btnVow").gameObject
	self.imgIcon = topPanel:NodeByName("imgIcon").gameObject
	self.groupEffect = topPanel:NodeByName("groupEffect").gameObject
	self.imgPicture = ParnterImg.new(self.groupPicture)
	self.mainAni = winTrans:GetComponent(typeof(UnityEngine.Animation))
end

function DatesPledgeWindow:registerEvent()
	UIEventListener.Get(self.btnVow).onClick = handler(self, self.vow)

	self.eventProxy_:addEventListener(xyd.event.VOW, handler(self, self.onPartnerVow))

	UIEventListener.Get(self.imgIcon).onClick = handler(self, self.onClickVowImg)
end

function DatesPledgeWindow:layout()
	xyd.setUISpriteAsync(self.imgTitle, nil, "dates_text01_" .. xyd.Global.lang, function ()
		self.imgTitle:MakePixelPerfect()
	end)
	self:vowLayout()
	self:setText()
	self:updateBG()
end

function DatesPledgeWindow:setText()
	self.labelText01.text = xyd.models.selfPlayer:getPlayerName()
	local partnerName = self.partner:getName()
	self.labelText02.text = partnerName
	self.labelText04.text = __("DATES_TEXT09")
	self.labelText06.text = __("DATES_TEXT11")

	if xyd.Global.lang == "ja_jp" then
		self.labelText06.width = 108
		self.labelText06.height = 16
	end

	self.labelText03.text = __("VOW_OATH")
	local content = xyd.tables.datesTextTable:getText(self.partner.love_point)
	local str = xyd.stringFormat(content, unpack({
		partnerName
	}))
	self.labelText08.text = str
	local attrs = xyd.tables.datesTable:getAttr(self.partner.love_point)

	if #attrs == 0 then
		self.labelText07.text = __("DATES_TEXT13")
	else
		local str = ""

		for i = 1, #attrs do
			str = str .. xyd.tables.dBuffTable:translationDesc(attrs[i])

			if i < #attrs then
				str = str .. "    "
			end
		end

		self.labelText07.text = str
	end

	if xyd.Global.lang == "de_de" then
		self.labelText03.transform:Y(102)
	end
end

function DatesPledgeWindow:vow()
	if self.isLongTouch then
		xyd.showToast(__("IS_IN_BATTLE_FORMATION"))

		return
	end

	local maxBase = MiscTable:getNumber("love_point_max_base", "value")

	if self.partner.love_point < maxBase then
		if self.isDate then
			return
		end

		local params = {
			chosenGroup = 0,
			sort_key = "3_0",
			no_back = true,
			partner_id = self.partnerID
		}

		xyd.openWindow("dates_window", params, function ()
			xyd.closeWindow(self.name_)
		end)

		return
	end

	local activity = xyd.models.activity:getActivity(xyd.ActivityID.RING_GIFTBAG)

	if activity then
		if xyd.isItemAbsence(xyd.ItemID.DATES_RING, 1, false) then
			xyd.alert(xyd.AlertType.YES_NO, __("DATES_TEXT25"), function (yes)
				if not yes then
					return
				end

				xyd.WindowManager:get():closeWindow(self.name_)
				xyd.WindowManager:get():closeWindow("partner_detail_window")
				xyd.WindowManager:get():closeWindow("slot_window")
				xyd.WindowManager:get():openWindow("activity_window", {
					select = xyd.ActivityID.RING_GIFTBAG
				})
			end)

			return
		end
	elseif xyd.isItemAbsence(xyd.ItemID.DATES_RING, 1, true) then
		return
	end

	xyd.WindowManager:get():openWindow("dates_alert_window", {
		callback = function (yes)
			if not yes then
				return
			end

			local msg = messages_pb.vow_req()
			msg.partner_id = self.partnerID

			xyd.Backend:get():request(xyd.mid.VOW, msg)
		end
	})
end

function DatesPledgeWindow:onPartnerVow(event)
	if self.partner:isVowed() then
		self.btnVow:SetActive(false)
		xyd.WindowManager.get():openWindow("dates_pledge_story_window", {
			partner = self.partner
		})
		self:hide()
		self:updateBG()
	end
end

function DatesPledgeWindow:onClickVowImg()
	if not self.canReplayPledgeAnimation then
		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("VOW_TEXT_2"), function (yes)
		if not yes then
			return
		end

		if self.partner:isVowed() then
			self.btnVow:SetActive(false)
			xyd.openWindow("dates_pledge_story_window", {
				isReplayStory = true,
				partner = self.partner
			})
			self:hide()
		end
	end)
end

function DatesPledgeWindow:vowLayout()
	self:setText05()

	local maxBase = MiscTable:getNumber("love_point_max_base", "value")

	if self.partner:isVowed() then
		local time = os.date("*t", self.partner:getWeddingDate())
		self.labelDate.text = __("DATE", time.year, time.month, time.day)

		self.groupText:SetActive(true)
	else
		self.groupText:SetActive(false)
	end

	self.btnVow:SetActive(not self.partner:isVowed())

	if maxBase <= self.partner.love_point then
		xyd.setBtnLabel(self.btnVow, {
			text = __("DATES_TEXT24")
		})
	else
		xyd.setBtnLabel(self.btnVow, {
			text = __("DATES_TEXT06")
		})

		if self.isDate then
			xyd.setEnabled(self.btnVow, false)
			xyd.setBtnLabel(self.btnVow, {
				text = __("DATES_TEXT24")
			})
		end
	end

	self.imgIcon:SetActive(self.partner:isVowed())
end

function DatesPledgeWindow:showAnimation()
	self:show()
	self.btnVow:SetActive(false)
	self.imgIcon:SetActive(false)

	local time = os.date("*t", self.partner:getWeddingDate())
	self.labelDate.text = __("DATE", time.year, time.month, time.day)

	self.groupText:SetActive(true)
	self.mainAni:Play("showPledgeAni")

	self.db = xyd.Spine.new(self.groupEffect)

	self.db:SetActive(false)
	self.db:setInfo("date_vow04", function ()
	end)

	local key = "date_vow04_play"

	self:waitForTime(2.3, function ()
		self.db:SetActive(true)
		self.db:play("texiao01", 1, 1, function ()
			if self.db then
				self.db:SetActive(false)
			end

			if self.imgIcon then
				self.imgIcon:SetActive(true)
			end
		end, true)
	end, key)
	self:setText05()
end

function DatesPledgeWindow:setText05()
	local maxGrow = MiscTable:getNumber("love_point_max_grow", "value")
	local maxBase = MiscTable:getNumber("love_point_max_base", "value")
	local max = xyd.checkCondition(self.partner:isVowed(), maxGrow, maxBase)
	self.labelText05.text = math.floor(self.partner.love_point / 100) .. "/" .. max / 100
end

function DatesPledgeWindow:updateBG()
	local showID = self:getPartnerShowId()
	showID = showID or self.partner:getTableID()

	self.imgPicture:setImg({
		itemID = showID
	})

	local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(showID)
	local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(showID)

	self.imgPicture:SetLocalPosition(xy.x * 0.6, -xy.y * 0.6 + 40, 0)
	self.imgPicture:SetLocalScale(scale * 0.6, scale * 0.6, 1)

	local alpha = (self.partner:isVowed() or self.imgPicture:isDragonBone()) and 1 or 0.8

	self.imgPicture:setAlha(alpha)

	local groupModel = self.imgPicture.go:NodeByName("groupModel").gameObject

	if groupModel.transform.childCount > 0 then
		local texture = groupModel:ComponentByName("girls_model/groupModel", typeof(UITexture))
		texture.height = 2000
	end
end

function DatesPledgeWindow:willClose(params)
	BaseWindow.willClose(self, params)
	xyd.WindowManager.get():closeWindow("dates_pledge_story_window")
end

function DatesPledgeWindow:getPartnerShowId()
	local backId = self.partner:getShowID()

	if self.show_id then
		backId = self.show_id
	end

	return backId
end

return DatesPledgeWindow
