local BaseWindow = import(".BaseWindow")
local ExploreSourceBuyWindow = class("ExploreSourceBuyWindow", BaseWindow)
local PngNum = require("app.components.PngNum")

function ExploreSourceBuyWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.itemTable = xyd.tables.itemTable
	self.curNum_ = 1
end

function ExploreSourceBuyWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ExploreSourceBuyWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelWinTitle = groupAction:ComponentByName("top/labelWinTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("top/closeBtn").gameObject
	self.labelName = groupAction:ComponentByName("labelName", typeof(UILabel))
	self.groupIcon_ = groupAction:NodeByName("groupIcon_").gameObject
	self.selectNumNode_ = groupAction:NodeByName("selectGroup").gameObject
	self.btnSure = groupAction:NodeByName("btnSure").gameObject
	self.limitLabel = groupAction:ComponentByName("limitLabel", typeof(UILabel))
	self.groupCost_ = groupAction:ComponentByName("groupCost_", typeof(UILayout))
	self.labelCost = self.groupCost_:ComponentByName("labelCost", typeof(UILabel))
	self.vipGroup = groupAction:NodeByName("vipGroup").gameObject
	self.vipLabel1 = self.vipGroup:ComponentByName("vipLabel1", typeof(UILabel))
	self.vipLabel2 = self.vipGroup:ComponentByName("vipLabel2", typeof(UILabel))
	self.vipNumRoot = self.vipGroup:NodeByName("vipNum").gameObject
	self.vipImg = self.vipGroup:NodeByName("vipImg").gameObject
	self.vipNum = PngNum.new(self.vipNumRoot)
end

function ExploreSourceBuyWindow:layout()
	local name = self.itemTable:getName(self.itemID)
	self.labelName.text = name

	xyd.setBtnLabel(self.btnSure, {
		text = __("BUY")
	})

	local vipLv = xyd.models.backpack:getVipLev()
	local limitList = xyd.split(xyd.tables.miscTable:getVal("travel_buy_time_limit"), "|", true)
	local limitTimes = limitList[vipLv + 1]

	if xyd.models.backpack:getMaxVipLev() <= vipLv then
		self.vipGroup:SetActive(false)
	else
		self.vipNum:setInfo({
			scale = 0.8,
			iconName = "player_vip",
			num = vipLv + 1
		})

		self.vipLabel1.text = __("TRAVEL_MAIN_TEXT54")
		self.vipLabel2.text = __("TRAVEL_MAIN_TEXT55", limitList[vipLv + 2])

		if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
			self.vipLabel1:X(-45)
		elseif xyd.Global.lang == "ko_kr" then
			self.vipLabel1:SetActive(false)

			self.vipLabel2.text = __("TRAVEL_MAIN_TEXT66", limitList[vipLv + 2])

			self.vipImg:X(-102)
			self.vipNumRoot:X(-71)
			self.vipLabel2:X(-56)
		elseif xyd.Global.lang == "ja_jp" then
			self.vipLabel1:SetActive(false)

			self.vipLabel2.text = __("TRAVEL_MAIN_TEXT66", limitList[vipLv + 2])

			self.vipImg:X(-142)
			self.vipNumRoot:X(-111)
			self.vipLabel2:X(-95)
		elseif xyd.Global.lang == "en_en" then
			self.vipLabel1:SetActive(false)

			self.vipLabel2.text = __("TRAVEL_MAIN_TEXT66", limitList[vipLv + 2])

			self.vipLabel2:X(-194)
			self.vipImg:X(146)
			self.vipNumRoot:X(174)
		end
	end

	local buyTimes = xyd.models.exploreModel:getExploreInfo().buy_times
	self.leftTimes = limitTimes - buyTimes
	self.limitLabel.text = __("TRAVEL_MAIN_TEXT60", buyTimes, limitTimes)
	local travelBuy = xyd.split(xyd.tables.miscTable:getVal("travel_buy"), "|")
	self.buyInfo = {}

	for i in ipairs(travelBuy) do
		local temp = xyd.split(travelBuy[i], "#", true)

		table.insert(self.buyInfo, temp)
	end

	local icon = xyd.getItemIcon({
		show_has_num = true,
		itemID = self.buyInfo[1][1],
		uiRoot = self.groupIcon_,
		num = self.buyInfo[1][2]
	})
	self.selectNum_ = require("app.components.SelectNum").new(self.selectNumNode_, "explore")

	local function callback(num)
		self.curNum_ = num

		self:updateLabel()
	end

	self.selectNum_:setInfo({
		curNum = 1,
		minNum = 1,
		maxNum = math.min(self.leftTimes, math.floor(xyd.models.backpack:getItemNumByID(self.buyInfo[2][1]) / self.buyInfo[2][2])),
		maxCanBuyNum = math.min(self.leftTimes, math.floor(xyd.models.backpack:getItemNumByID(self.buyInfo[2][1]) / self.buyInfo[2][2])),
		callback = callback,
		maxCallback = function ()
			xyd.showToast(__("FULL_BUY_SLOT_TIME"))
		end
	})
	self.selectNum_:setKeyboardPos(0, -350)
	self:updateLabel()
end

function ExploreSourceBuyWindow:updateLabel()
	local curNum = xyd.models.backpack:getItemNumByID(self.buyInfo[2][1])
	local needNum = self.curNum_ * self.buyInfo[2][2]

	if curNum >= needNum then
		self.labelCost.text = xyd.getRoughDisplayNumber(curNum) .. "/" .. needNum
	else
		self.labelCost.text = "[c][ED4D58]" .. xyd.getRoughDisplayNumber(curNum) .. "[-][/c]" .. "/" .. needNum
	end

	self.groupCost_:Reposition()
end

function ExploreSourceBuyWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnSure).onClick = handler(self, self.sellTouch)
end

function ExploreSourceBuyWindow:sellTouch()
	if self.leftTimes > 0 then
		local msg = messages_pb.explore_buy_bread_req()
		msg.num = self.curNum_

		xyd.Backend.get():request(xyd.mid.EXPLORE_BUY_BREAD, msg)
		self:close()
	else
		self:close(function ()
			xyd.showToast(__("FULL_BUY_SLOT_TIME"))

			local timeStamp = xyd.db.misc:getValue("explore_buy_tips_stamp")

			if (not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true)) and xyd.models.backpack:getVipLev() < xyd.models.backpack:getMaxVipLev() then
				self:waitForTime(0.6, function ()
					xyd.WindowManager.get():openWindow("explore_buy_tips_window", {
						timeStampKey = "explore_buy_tips_stamp",
						text = __("TRAVEL_MAIN_TEXT58"),
						yesCallBack = function ()
							xyd.WindowManager.get():openWindow("vip_window")
						end
					})
				end)
			end
		end)
	end
end

return ExploreSourceBuyWindow
