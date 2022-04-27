local ShopRender1 = import("app.components.ShopRender1")
local ShopRender2 = import("app.components.ShopRender2")
local ChargeTable = xyd.tables.charge
local ShopWindow = class("ShopWindow", import(".BaseWindow"))

function ShopWindow:ctor(name, params)
	ShopWindow.super.ctor(self, name, params)

	self.shop_renders = {}
end

function ShopWindow:initWindow()
	ShopWindow.super.initWindow(self)
	self:registerEvents()
	self:getUIComponent()
	self:initUIComponent()
	self:UIAnimation()
end

function ShopWindow:registerEvents()
end

function ShopWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.container = winTrans:NodeByName("group_shop/container").gameObject
	self.container_widget = self.container:GetComponent(typeof(UIWidget))
	self.container_panel = winTrans:ComponentByName("group_shop", typeof(UIPanel))
	self.btn_close = winTrans:NodeByName("top_group/btn_close").gameObject
	self.title = winTrans:ComponentByName("top_group/title", typeof(UISprite))
	self.more_bg = winTrans:ComponentByName("more_group/more_bg", typeof(UISprite))
	self.more_text = winTrans:ComponentByName("more_group/more_text", typeof(UISprite))

	xyd.setUISpriteAsync(self.title, xyd.MappingData.shop_title, "shop_title")
	xyd.setUISpriteAsync(self.more_bg, xyd.MappingData.bg_di3, "bg_di3")
	xyd.setUISpriteAsync(self.more_text, xyd.MappingData.text_more, "text_more")
end

function ShopWindow:initUIComponent()
	xyd.setDarkenBtnBehavior(self.btn_close, self, self.onBtnClose)
	self:initShopRenders()
end

function ShopWindow:UIAnimation()
end

function ShopWindow:onBtnClose()
	XYDCo.WaitForTime(5 * xyd.TweenDeltaTime, function ()
		xyd.WindowManager.get():closeWindow("shop_window")
	end, nil)
end

function ShopWindow:initShopRenders()
	self.chargeData = ChargeTable:getAllData()
	local gap = 30
	local height = xyd.getFixedHeight() - 240

	for charge_id, row in pairs(self.chargeData) do
		local shop_render = nil
		local type = tonumber(row.type)

		if type == 1 then
			shop_render = ShopRender1.new(self.container, row.diamond, row.charge, charge_id)
		else
			shop_render = ShopRender2.new(self.container)
		end

		table.insert(self.shop_renders, shop_render)
	end

	self:resizeContainer(height)
	self:resetRendersPosition(gap)
end

function ShopWindow:resizeContainer(height)
	self.container_panel.baseClipRegion = Vector4(0, 0, self.container_widget.width, height)
	self.container_widget.height = height
	self.container.transform.localPosition = Vector3(0, 0)
	self.container_panel.transform.localPosition = Vector3(0, xyd.getFixedHeight() / 2 - 175 - self.container_panel.baseClipRegion.w / 2)
end

function ShopWindow:resetRendersPosition(gap)
	if self.shop_renders == nil or #self.shop_renders == 0 then
		return
	end

	local y = self.container_widget.height / 2 - self.shop_renders[1].widget.height / 2
	local render_len = #self.shop_renders

	for i = 1, render_len do
		local shop_render = self.shop_renders[i]
		shop_render.gameObject.transform.localPosition = Vector3(0, y)

		if i < render_len then
			y = y - gap - shop_render.widget.height / 2 - self.shop_renders[i + 1].widget.height / 2
		end
	end
end

function ShopWindow:dispose()
	ShopWindow.super.dispose(self)
end

return ShopWindow
