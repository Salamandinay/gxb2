local TimeCloisterCardRecordWindow = class("TimeCloisterCardRecordWindow", import(".BaseWindow"))
local CardItem = class("CardItem", import("app.common.ui.FixedMultiWrapContentItem"))
local cardTable = xyd.tables.timeCloisterCardTable

function CardItem:initUI()
	self.icon = self.go:ComponentByName("icon", typeof(UISprite))
	self.nameBg = self.go:ComponentByName("nameBg", typeof(UISprite))
	self.nameLabel = self.go:ComponentByName("nameLabel", typeof(UILabel))
	self.descLabel = self.go:ComponentByName("descLabel", typeof(UILabel))
	self.numLabel = self.go:ComponentByName("numLabel", typeof(UILabel))
	self.bgUISprite = self.go:ComponentByName("bg", typeof(UISprite))

	if xyd.Global.lang == "fr_fr" then
		self.nameLabel.fontSize = 16
	end

	UIEventListener.Get(self.go).onClick = function ()
		if self.data.card_id ~= 0 then
			xyd.WindowManager.get():openWindow("time_cloister_card_detail_window", {
				card_id = self.data.card_id
			})
		end
	end

	xyd.models.timeCloisterModel:changeCommonCardUI(self.go)
end

function CardItem:updateInfo()
	self.nameLabel.text = cardTable:getName(self.data.card_id)
	self.descLabel.text = cardTable:getDesc(self.data.card_id)
	self.numLabel.text = "x" .. self.data.num
	local img = xyd.tables.timeCloisterCardTable:getImg(self.data.card_id)

	xyd.setUISpriteAsync(self.icon, nil, img)
end

function TimeCloisterCardRecordWindow:ctor(name, params)
	TimeCloisterCardRecordWindow.super.ctor(self, name, params)

	if params then
		if params.cloister then
			self.cloister = params.cloister
		end

		if params.isSpeedHandUpBack ~= nil then
			self.isSpeedHandUpBack = params.isSpeedHandUpBack
		end
	end
end

function TimeCloisterCardRecordWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	self:checkGuide()
end

function TimeCloisterCardRecordWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller_", typeof(UIScrollView))
	local itemGroup = self.scrollView:ComponentByName("itemGroup", typeof(UIWrapContent))
	local itemContainer = groupAction:NodeByName("time_cloister_card").gameObject
	self.wrapContent_ = import("app.common.ui.FixedMultiWrapContent").new(self.scrollView, itemGroup, itemContainer, CardItem, self)
end

function TimeCloisterCardRecordWindow:layout()
	self.titleLabel.text = __("TIME_CLOISTER_TEXT24")
	local ids = {}
	local events = xyd.models.timeCloisterModel:getHangInfo().events or {}

	for id, value in pairs(events) do
		local type = xyd.tables.timeCloisterCardTable:getType(tonumber(id))

		if type and type > 0 then
			if type ~= xyd.TimeCloisterCardType.ENCOUNTER_BATTLE then
				if type == xyd.TimeCloisterCardType.DRESS_MISSION_EVENT then
					-- Nothing
				end
			end
		else
			table.insert(ids, {
				card_id = tonumber(id),
				num = value
			})
		end
	end

	self.wrapContent_:setInfos(ids, {})
end

function TimeCloisterCardRecordWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		if self.isNeedguide then
			return
		end

		self:close()
	end
end

function TimeCloisterCardRecordWindow:willClose()
	TimeCloisterCardRecordWindow.super.willClose(self)

	local time_cloister_probe_wd = xyd.WindowManager.get():getWindow("time_cloister_probe_window")

	if time_cloister_probe_wd then
		time_cloister_probe_wd:checkGuide(xyd.GuideType.TIME_CLOISTER_2)
	end
end

function TimeCloisterCardRecordWindow:checkGuide()
	if self.isSpeedHandUpBack and self.cloister and self.cloister == xyd.TimeCloisterMissionType.ONE then
		local exskillGuideWd = xyd.WindowManager.get():getWindow("exskill_guide_window")

		if not exskillGuideWd and not xyd.db.misc:getValue("time_cloister_guide_" .. xyd.GuideType.TIME_CLOISTER_4) then
			self.isNeedguide = true

			self:waitForTime(0.6, function ()
				xyd.WindowManager:get():openWindow("exskill_guide_window", {
					wnd = self,
					table = xyd.tables.timeCloisterGuideTable,
					guide_type = xyd.GuideType.TIME_CLOISTER_4
				})
				xyd.db.misc:setValue({
					value = "1",
					key = "time_cloister_guide_" .. xyd.GuideType.TIME_CLOISTER_4
				})
				self:waitForTime(0.1, function ()
					self.isNeedguide = false
				end)
			end)
		end
	end
end

function TimeCloisterCardRecordWindow:onClickCloseButton()
	if self.isNeedguide then
		return
	end

	TimeCloisterCardRecordWindow.super.onClickCloseButton(self)
end

function TimeCloisterCardRecordWindow:playOpenAnimation(callback)
	local function myCallBack()
		if callback then
			callback()
		end
	end

	TimeCloisterCardRecordWindow.super.playOpenAnimation(self, myCallBack)
end

return TimeCloisterCardRecordWindow
