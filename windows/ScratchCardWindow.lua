local ScratchCardWindow = class("ScratchCardWindow", import(".BaseWindow"))
local ScratchCard = class("ScratchCard", import("app.components.BaseComponent"))
local ItemTable = xyd.tables.itemTable
local MASK_W = 576
local MASK_H = 146

function ScratchCardWindow:ctor(name, params)
	ScratchCardWindow.super.ctor(self, name, params)

	self.items_ = params.items
	self.awards_ = params.awards
	self.itemObjList_ = {}
	local needLoadRes = {
		xyd.getTexturePath("scratch_card_mask")
	}

	self:setResourcePaths(needLoadRes)
end

function ScratchCardWindow:initWindow()
	ScratchCardWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ScratchCardWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.itemGroup = winTrans:NodeByName("groupAction/itemGroup").gameObject
	self.groupBg = winTrans:NodeByName("groupAction/groupBg").gameObject
	self.awardBtn = winTrans:NodeByName("groupAction/awardBtn").gameObject
end

function ScratchCardWindow:layout()
	self.awardBtn:ComponentByName("button_label", typeof(UILabel)).text = __("ACTIVITY_SCRATCH_CARD_GET_ALL")

	self:initBtn()
	self:updateLayout()
end

function ScratchCardWindow:updateLayout()
	self:prepareSingleCard(1, false, 100)

	if #self.items_ > 1 then
		self:prepareSingleCard(2, true)
	end
end

function ScratchCardWindow:prepareSingleCard(index, isHide, depth)
	local params = {
		cur_count = index,
		all_count = #self.items_,
		items = self.items_[index],
		finish_callback = function (cur_count, all_count)
			if cur_count == all_count then
				self:showResult()
			else
				if self.itemObjList_[cur_count] then
					self.itemObjList_[cur_count]:playEndAction(function ()
						if self.itemObjList_[cur_count + 1] then
							self.itemObjList_[cur_count + 1]:setDepth(100)
						end

						if cur_count + 2 <= all_count then
							self:prepareSingleCard(cur_count + 2, true)
						end

						NGUITools.Destroy(self.itemObjList_[cur_count]:getGameObject())

						self.itemObjList_[cur_count] = nil
					end)
				end

				if self.itemObjList_[cur_count + 1] then
					self.itemObjList_[cur_count + 1]:SetActive(true)
				end
			end
		end
	}
	local item = self:getItem(params)

	if isHide then
		item:SetActive(false)
	end

	if depth then
		item:setDepth(depth)
	end

	self.itemObjList_[index] = item
end

function ScratchCardWindow:getItem(params)
	local item = ScratchCard.new(self.itemGroup)

	item:setInfo(params)

	return item
end

function ScratchCardWindow:initBtn()
	if #self.items_ == 1 then
		self.awardBtn:SetActive(false)
		self.groupBg:SetActive(false)
	else
		self.awardBtn:SetActive(true)
		self.groupBg:SetActive(true)
	end
end

function ScratchCardWindow:registerEvent()
	UIEventListener.Get(self.awardBtn).onClick = handler(self, self.showResult)
end

function ScratchCardWindow:showResult()
	xyd.openWindow("activity_scratch_card_award_window", {
		items = self.items_,
		awards = self.awards_
	})
	xyd.closeWindow("scratch_card_window")
end

function ScratchCard:ctor(parentGo)
	ScratchCard.super.ctor(self, parentGo)
end

function ScratchCard:getPrefabPath()
	return "Prefabs/Components/scratch_card_item"
end

function ScratchCard:initUI()
	ScratchCard.super.initUI(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ScratchCard:getUIComponent()
	self.effectGroup = self.go:NodeByName("effectGroup").gameObject
	self.awardEffectGroup = self.go:NodeByName("awardEffectGroup").gameObject
	self.awardGroup = self.go:NodeByName("awardGroup").gameObject
	self.awardGroupLayout = self.awardGroup:GetComponent(typeof(UILayout))
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.confirmBtn = self.go:NodeByName("confirmBtn").gameObject
	self.maskGroup = self.go:NodeByName("maskGroup").gameObject
	self.maskGroupTex = self.maskGroup:GetComponent(typeof(UITexture))
	self.maskItem = self.go:NodeByName("maskItem").gameObject
	self.touchNode = self.go:NodeByName("touchNode").gameObject
	self.countLabel = self.go:ComponentByName("countLabel", typeof(UILabel))
	self.awardLabel = self.go:ComponentByName("awardLabel", typeof(UILabel))
end

function ScratchCard:layout()
	self.confirmBtn:ComponentByName("button_label", typeof(UILabel)).text = __("ACTIVITY_SCRATCH_CARD_CONFIRM")
	self.awardLabel.text = __("ACTIVITY_SCRATCH_CARD_MOVE")
end

function ScratchCard:setCount(count)
	self.countLabel.text = __("SCRATCH_CARD_COUNT", count, self.all_count_)
end

function ScratchCard:registerEvent()
	UIEventListener.Get(self.confirmBtn).onClick = function ()
		self:finishCall()
	end

	UIEventListener.Get(self.touchNode).onDragStart = function ()
	end

	UIEventListener.Get(self.touchNode).onDrag = function (go, delta)
		self:onTouchMove(delta)
	end

	UIEventListener.Get(self.touchNode).onDragEnd = function (go)
		if self:checkComplete() then
			self:completeAction()
		end
	end
end

function ScratchCard:finishCall()
	if self.finish_callback_ then
		self.finish_callback_(self.cur_count_, self.all_count_)
		self.effectGroup:SetActive(false)
	end
end

function ScratchCard:playEndAction(callback)
	local sequence = self:getSequence()

	sequence:Append(self.go.transform:DOLocalMoveX(440, 0.5)):Join(xyd.getTweenAlpha(self.go:GetComponent(typeof(UIWidget)), 0.1, 0.5)):AppendCallback(function ()
		if callback then
			callback()
		end
	end)
end

function ScratchCard:onTouchMove(delta)
	local pos = xyd.mouseToLocalPos(self.maskGroup.transform)

	self:drawCircle(pos)
end

function ScratchCard:drawCircle(pos)
	local item = NGUITools.AddChild(self.maskGroup, self.maskItem)

	item:SetLocalPosition(pos.x, pos.y, 1)

	local r = 25
	local x_ = math.floor(pos.x + MASK_W / 2)
	local y_ = math.floor(pos.y + MASK_H / 2)

	for dx = -r, r do
		local absDx = math.abs(dx)

		for dy = absDx - r, r - absDx do
			local a = x_ + dx
			local b = y_ + dy

			if a >= 0 and a < MASK_W and b >= 0 and b < MASK_H then
				self.color_list_[b * MASK_W + a] = 1
			end
		end
	end
end

function ScratchCard:setInfo(params)
	self.cur_count_ = params.cur_count
	self.all_count_ = params.all_count
	self.items_ = params.items
	self.finish_callback_ = params.finish_callback
	self.color_list_ = {}

	self:updateCardGroup()
end

function ScratchCard:updateCardGroup()
	if self.all_count_ == 1 then
		self.countLabel:SetActive(false)
	end

	self.awardLabel:SetActive(true)
	self.confirmBtn:SetActive(false)
	xyd.setUITextureByNameAsync(self.maskGroupTex, "scratch_card_mask", false, function ()
		self:initItem()
	end)
	self:setCount(self.cur_count_)
end

function ScratchCard:initItem()
	local list = self:getNeedFxId()

	for i = 1, #self.items_ do
		local data = self.items_[i]
		local group_id = ItemTable:getGroup(data.item_id)
		local item = xyd.getItemIcon({
			scale = 0.9,
			itemID = data.item_id,
			num = data.item_num,
			uiRoot = self.awardGroup
		})

		if list[group_id] then
			self:addFx(item:getGEffectObj())
		end
	end

	self.awardGroupLayout:Reposition()
end

function ScratchCard:getNeedFxId()
	local count = {}
	local m = 0
	local m_id = nil

	for i = 1, #self.items_ do
		local data = self.items_[i]
		local item_id = data.item_id
		local group = ItemTable:getGroup(item_id)
		count[group] = (count[group] or 0) + 1

		if m < count[group] then
			m_id = item_id
			m = count[group]
		end
	end

	local keys = table.keys(count)

	if #keys == 5 then
		return count
	elseif m >= 2 then
		local res = {
			[ItemTable:getGroup(m_id)] = true
		}

		return res
	end

	return {}
end

function ScratchCard:addFx(obj)
	local effect = xyd.Spine.new(obj)

	effect:setInfo("act_scratch_card_win", function ()
		effect:SetLocalScale(1.1, 1.1, 1)
		effect:play("texiao01", 0)
	end)
end

function ScratchCard:checkComplete()
	local count = 0

	for dx = 1, MASK_W do
		for dy = 1, MASK_H do
			if self.color_list_[dy * MASK_W + dx] == 1 then
				count = count + 1
			end
		end
	end

	local all_count = MASK_W * MASK_H

	if count / all_count > 0.3 then
		return true
	end

	return false
end

function ScratchCard:completeAction()
	self.maskGroup:SetActive(false)
	self.awardLabel:SetActive(false)
	self.confirmBtn:SetActive(true)

	self.open_effect_ = xyd.Spine.new(self.effectGroup)

	self.open_effect_:setInfo("act_scratch_card_open", function ()
		self.open_effect_:SetLocalPosition(0, 25, 0)
		self.open_effect_:play("texiao01", 1)
	end)
end

return ScratchCardWindow
