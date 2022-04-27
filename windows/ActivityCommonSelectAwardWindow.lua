local ActivityCommonSelectAwardWindow = class("ActivityCommonSelectAwardWindow", import(".BaseWindow"))
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")

function ActivityCommonSelectAwardWindow:ctor(name, params)
	ActivityCommonSelectAwardWindow.super.ctor(self, name, params)

	self.itemIcons = {}
	self.selectIndex = 0
	self.selectIndexs = {}
	self.items = params.items
	self.sureCallback = params.sureCallback
	self.buttomTitleText = params.buttomTitleText
	self.titleText = params.titleText
	self.sureBtnText = params.sureBtnText
	self.cancelBtnText = params.cancelBtnText
	self.tipsText = params.tipsText
	self.selectedIndex = params.selectedIndex
	self.mustChoose = params.mustChoose or false
end

function ActivityCommonSelectAwardWindow:initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
	self:initSelect()
end

function ActivityCommonSelectAwardWindow:initSelect()
	if self.selectedIndex then
		self.selectIndex = self.selectedIndex

		self:selectItem()
	end
end

function ActivityCommonSelectAwardWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelWinTitle_ = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.cancelBtn = self.groupAction:NodeByName("cancelBtn").gameObject
	self.okBtn = self.groupAction:NodeByName("okBtn").gameObject
	self.okBtnWords = self.okBtn:ComponentByName("btnWords", typeof(UILabel))
	self.cancelBtnWords = self.cancelBtn:ComponentByName("btnWords", typeof(UILabel))
	self.tipsWords = self.groupAction:ComponentByName("tipsWords", typeof(UILabel))
	self.labelButtomTitle = self.groupAction:ComponentByName("roundText", typeof(UILabel))
	self.iconNode = self.groupAction:NodeByName("groupItem/iconNode").gameObject
	self.awardsContainer = self.groupAction:NodeByName("awardsContainer").gameObject
end

function ActivityCommonSelectAwardWindow:layout()
	if self.titleText then
		self.labelWinTitle_.text = self.titleText
	end

	if self.sureBtnText then
		self.okBtnWords.text = self.sureBtnText
	else
		self.okBtnWords.text = __("SURE")
	end

	if self.cancelBtnText then
		self.cancelBtnWords.text = self.cancelBtnText
	else
		self.cancelBtnWords.text = __("CANCEL_2")
	end

	if self.buttomTitleText then
		self.labelButtomTitle.text = self.buttomTitleText
	end

	if self.tipsText then
		self.tipsWords.text = self.tipsText
	end

	local awards = self.items

	for k, v in ipairs(awards) do
		local itemIcon = xyd.getItemIcon({
			noClick = false,
			uiRoot = self.awardsContainer,
			itemID = v[1],
			num = v[2]
		})

		table.insert(self.itemIcons, itemIcon)

		UIEventListener.Get(itemIcon:getGameObject()).onClick = handler(self, function ()
			if self.selectIndex == k then
				if not self.mustChoose then
					self.selectIndex = 0
				end
			else
				self.selectIndex = k
			end

			self:selectItem()
		end)
		UIEventListener.Get(itemIcon:getGameObject()).onLongPress = handler(self, function ()
			local params = {
				notShowGetWayBtn = true,
				show_has_num = true,
				itemID = v[1],
				itemNum = v[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			xyd.WindowManager.get():openWindow("item_tips_window", params)
		end)
	end
end

function ActivityCommonSelectAwardWindow:selectItem()
	for k, v in ipairs(self.itemIcons) do
		if k == self.selectIndex then
			v:setChoose(true)
		else
			v:setChoose(false)
		end
	end

	local awards = self.items

	if self.selectIndex <= 0 or self.selectIndex > #awards then
		if self.selectIcon then
			self.selectIcon:SetActive(false)
		end

		return
	end

	local params = {
		show_has_num = true,
		noClickSelected = true,
		noClick = false,
		notShowGetWayBtn = true,
		uiRoot = self.iconNode,
		itemID = awards[self.selectIndex][1],
		num = awards[self.selectIndex][2],
		wndType = xyd.ItemTipsWndType.ACTIVITY
	}

	if not self.selectIcon then
		self.selectIcon = AdvanceIcon.new(params)
	else
		self.selectIcon:SetActive(true)
		self.selectIcon:setInfo(params)
	end
end

function ActivityCommonSelectAwardWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.cancelBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.okBtn.gameObject).onClick = handler(self, function ()
		self.sureCallback(self.selectIndex)
		self:close()
	end)
end

return ActivityCommonSelectAwardWindow
