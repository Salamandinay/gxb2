local BaseWindow = import(".BaseWindow")
local AlertItemWindow = class("AlertItemWindow", BaseWindow)
local ItemIcon = import("app.components.ItemIcon")
local ItemCard = class("ItemCard")

function ItemCard:ctor(go, parent)
	self.go = go
	self.parent = parent
end

function ItemCard:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)

	self.data.uiRoot = self.go

	if not self.itemIcon then
		self.itemIcon = xyd.getItemIcon(self.data)

		self.itemIcon:setDragScrollView(self.parent.scrollView)
	else
		NGUITools.Destroy(self.itemIcon:getGameObject())

		self.itemIcon = xyd.getItemIcon(self.data)

		self.itemIcon:setDragScrollView(self.parent.scrollView)
	end
end

function ItemCard:getGameObject()
	return self.go
end

function AlertItemWindow:ctor(name, params)
	if params == nil then
		params = nil
	end

	self.callback = nil

	BaseWindow.ctor(self, name, params)

	self.items = params.items
	self.title = params.title or __("AWARD_ITEM")
	self.callback = params.callback
	self.heroShowNum = params.heroShowNum
end

function AlertItemWindow:getUIComponent()
	local winTrans = self.window_.transform
	local main = winTrans:NodeByName("main").gameObject
	local closeBtn = main:NodeByName("closeBtn").gameObject

	self:setCloseBtn(closeBtn)

	self.labelTitle = main:ComponentByName("labelTitle", typeof(UILabel))
	local mid = main:NodeByName("mid").gameObject
	self.scrollView = mid:ComponentByName("itemScroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("itemsGroup", typeof(MultiRowWrapContent))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject

	itemContainer:SetActive(false)

	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView, wrapContent, itemContainer, ItemCard, self)
	self.btn_ok = main:NodeByName("btn_ok").gameObject
	self.btn_ok_label = self.btn_ok:ComponentByName("button_label", typeof(UILabel))
end

function AlertItemWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function AlertItemWindow:initUIComponent()
	local infos = {}

	for i = 1, #self.items do
		local v = self.items[i]
		local params = {
			hideText = true,
			itemID = v.item_id,
			num = v.item_num,
			heroShowNum = self.heroShowNum,
			star = v.star,
			is_vowed = v.is_vowed,
			soulEquipInfo = v.soulEquipInfo
		}

		if params.soulEquipInfo and params.soulEquipInfo.soulEquipID then
			function params.callback()
				local params1 = {
					itemNum = 1,
					hideText = true,
					show_has_num = false,
					itemID = v.item_id,
					soulEquipInfo = v.soulEquipInfo
				}

				function params1.lockClickCallBack()
					local equipID = params.soulEquipInfo.soulEquipID
					local equip = xyd.models.slot:getSoulEquip(equipID)

					if equip then
						local lockFlag = equip:getIsLock()
						local lock = 1

						if lockFlag then
							lock = 0
						end

						xyd.models.slot:reqLockSoulEquip(equip:getSoulEquipID(), lock, function ()
							equip:setLock(lock)

							local win = xyd.getWindow("item_tips_window")

							if win and win.diffItemTips then
								win.diffItemTips:setBtnLockState(equip:getIsLock())
							elseif win and win.itemTips_ then
								win.itemTips_:setBtnLockState(equip:getIsLock())
							end
						end)
					end
				end

				function params1.lockStateCallBack()
					local equipID = params.soulEquipInfo.soulEquipID
					local equip = xyd.models.slot:getSoulEquip(equipID)

					if equip then
						return equip:getIsLock()
					else
						return false
					end
				end

				xyd.WindowManager.get():openWindow("item_tips_window", params1)
			end
		end

		table.insert(infos, params)
	end

	self.multiWrap_:setInfos(infos, {})

	self.labelTitle.text = self.title
end

function AlertItemWindow:registerEvent()
	UIEventListener.Get(self.btn_ok).onClick = function ()
		self:onClickCloseButton()
	end

	self.btn_ok_label.text = __("SURE_2")
end

function AlertItemWindow:excuteCallBack(isCloseAll)
	if isCloseAll then
		return
	end

	if self.callback then
		self.callback()
	end
end

function AlertItemWindow:iosTestChangeUI()
	local allChildren = self.window_:GetComponentsInChildren(typeof(UISprite), true)

	for i = 0, allChildren.Length - 1 do
		local sprite = allChildren[i]

		xyd.setUISprite(sprite, nil, sprite.spriteName .. "_ios_test")
	end
end

return AlertItemWindow
