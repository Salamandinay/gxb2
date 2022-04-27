local NewPlayerTipsWindow = class("NewPlayerTipsWindow", import(".BaseWindow"))

function NewPlayerTipsWindow:ctor(name, params)
	NewPlayerTipsWindow.super.ctor(self, name, params)

	self.id = params.id
end

function NewPlayerTipsWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function NewPlayerTipsWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.choosenGroup = self.groupAction:NodeByName("choosenGroup").gameObject
	self.bg = self.choosenGroup:ComponentByName("bg", typeof(UISprite))
	self.closeBtn = self.choosenGroup:NodeByName("closeBtn").gameObject
	self.titleLabel = self.choosenGroup:ComponentByName("titleLabel", typeof(UILabel))
	self.sureBtn = self.choosenGroup:NodeByName("sureBtn").gameObject
	self.sureBtnLabel = self.sureBtn:ComponentByName("label", typeof(UILabel))
	self.descLabel = self.choosenGroup:ComponentByName("descLabel", typeof(UILabel))
	self.itemCon = self.choosenGroup:NodeByName("itemCon").gameObject
	self.itemConUILayout = self.choosenGroup:ComponentByName("itemCon", typeof(UILayout))
	self.bg1 = self.groupAction:ComponentByName("bg1", typeof(UISprite))
	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UISprite))
	self.bg3 = self.groupAction:ComponentByName("bg3", typeof(UISprite))
end

function NewPlayerTipsWindow:layout()
	local tableTitleText = xyd.tables.newPlayerActivityTipsTextTable:getTitle(self.id)

	if tableTitleText and tableTitleText ~= "" then
		self.titleLabel.text = tableTitleText
	else
		self.titleLabel.text = __("NEW_PLAYER_ACTIVITY_TIPS_TITLE")
	end

	local buttonText = xyd.tables.newPlayerActivityTipsTextTable:getButton(self.id)

	if buttonText and buttonText ~= "" then
		self.sureBtnLabel.text = buttonText
	else
		self.sureBtnLabel.text = __("NEW_PLAYER_ACTIVITY_TIPS_BUTTON")
	end

	self.descLabel.text = xyd.tables.newPlayerActivityTipsTextTable:getDesc(self.id)
	self.awardItems_ = {}
	local items = xyd.tables.newPlayerActivityTipsTable:getAwards(self.id)

	for i, item in pairs(items) do
		local params = {
			show_has_num = true,
			itemID = item[1],
			num = item[2],
			uiRoot = self.itemCon.gameObject
		}

		xyd.getItemIcon(params)
		table.insert(self.awardItems_, {
			item_id = item[1],
			item_num = item[2]
		})
	end

	self.itemConUILayout:Reposition()
end

function NewPlayerTipsWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.sureBtn.gameObject).onClick = function ()
		self:close()
	end
end

function NewPlayerTipsWindow:willClose()
	NewPlayerTipsWindow.super.willClose(self)
	xyd.models.itemFloatModel:pushNewItems(self.awardItems_)
end

return NewPlayerTipsWindow
