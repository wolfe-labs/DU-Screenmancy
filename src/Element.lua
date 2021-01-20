-- Wolfe Labs Dual Universe Screen Library
-- Project: DU-Screens
-- Author: Matheus Pratta (DU: Wolfram)

---------------------------------
-- class: Element
---------------------------------

require 'Screen'

local Class = require('@wolfe-labs/Core:Class')
local Utils = require('@wolfe-labs/Core:Utils')
local Events = require('@wolfe-labs/Core:Events')

-- Create the class definition
local Element = {}

-- Base initializer
function Element:__init (parent)
  -- Do we even exist?
  self.__exists = true

  -- Generate element ID
  self.id = 'SE-' .. self:getInstanceId()

  -- Default position and size
  self.x = 0
  self.y = 0
  self.width = 50
  self.height = 10

  -- Element visibility
  self.visible = true

  -- Default padding
  self.paddingX = 0
  self.paddingY = 1

  -- Spacing (distance from other elements)
  self.spacing = 5

  -- Default font and line height
  self.__fontSize = 8
  self.__lineHeight = 10

  -- Default styles function
  self.styles = function () return '' end

  -- Default render function
  self.contents = function () return '' end

  -- All elements must have a parent
  if not parent then
    error('Any Element entity MUST have a parent, be it another Element or a Screen object')
  end
  
  -- Attach parent element
  self.parent = parent

  -- This handles screen binding
  if parent.isScreen then
    -- If the parent object IS a Screen object, we link to it directly (will be rendered by it)
    self:linkScreen(self.parent)
  else
    -- If the parent object IS NOT a Screen object, we only add a reference to the screen but all rendering will be done by our parent Element
    self:setScreen(self.parent.linkedScreen)
  end

  -- If no linked screen is found
  if not self.linkedScreen then
    error('No valid Screen object found for Element ' .. self.id)
  end
end

-- Class constructor
function Element:__constructor (parent)
  -- Runs init code
  return self:__init(parent)
end

-- Class destructor
function Element:destroy ()
  -- Cascade
  if self.onDestroy then
    self:onDestroy()
  end

  -- Removes from any screen
  if self.linkedScreen then
    self.linkedScreen:removeZone(self)
  end
  if self.parent.isScreen then
    self.parent:removeElement(self)
  end

  -- Stop existence
  self.__exists = false

  -- End
  self = nil
end

-- Gets the render ID of the Element
function Element:getRenderId ()
  return 'el-' .. self.__class .. '_' .. self.id
end

-- Gets the bounding box
function Element:getBoundingBox ()
  -- Store the box here
  local box = {}

  -- Calculate bounding boxes
  box.L = self.x
  box.T = self.y
  box.W = self.width
  box.H = self.height
  box.R = 100.00 - (self.x + self.width)
  box.B = 100.00 - (self.y + self.height)

  -- Return it
  return box
end

-- Gets the internal bounding box
function Element:getInnerBoundingBox ()
  -- Store the box here
  local box = {}

  -- Calculate bounding boxes
  box.L = self.x + self.paddingX
  box.T = self.y + self.paddingY
  box.W = self.width - self.paddingX * 2
  box.H = self.height - self.paddingY * 2
  box.R = 100.00 - (self.x + self.width) - self.paddingX
  box.B = 100.00 - (self.y + self.height) - self.paddingY

  -- Return it
  return box
end

-- Gets the screen-space bounding box
function Element:getScreenBoundingBox ()
  -- Get normal bounding boxes relative to parent
  local boxN = self:getBoundingBox()

  -- Check if parent element is a screen, if so, then just pass on the normal box
  if self.parent.isScreen then
    return boxN
  end

  -- Get the parent elements screen bounding box
  local boxP = self.parent:getScreenBoundingBox()

  -- We'll store the corrected box here
  local box = {}
  
  -- Get's the dimensions of parent boxes
  local bpW = boxP.W / 100
  local bpH = boxP.H / 100

  -- Calculates the new values taking into account the proportions of parents
  box.L = boxP.L + (bpW * (boxN.L))
  box.T = boxP.T + (bpH * (boxN.T))
  box.W = bpW * boxN.W
  box.H = bpW * boxN.H
  box.R = boxP.R + (bpW * (boxN.R))
  box.B = boxP.B + (bpH * (boxN.B))

  -- if not debug_html then debug_html = '' end
  -- debug_html = debug_html .. '<div style="position:absolute;top:' .. box.T .. '%;left:' .. box.L .. '%;right:' .. box.R .. '%;bottom:' .. box.B .. '%;background:red;">&nbsp;</div>'
  -- self.linkedScreen.baseScreen.setHTML(debug_html)

  -- Done!
  return box
end

-- -- Add event handler and stuff
-- function Element.on (self, event, fn)
--   -- If no linked screen, show warning
--   if not self.linkedScreen then
--     error('You need a linked screen to bind events. Use the setScreen() method if you are adding a child element (like in lists) or linkScreen() if you are adding a top-level element')
--   end
  
--   self.linkedScreen:on(event, function (x, y, s)
--     -- Do we still exist
--     if not self.__exists then return end

--     -- Convert 0..1 to 0..100
--     local pX = 100.00 * x
--     local pY = 100.00 * y

--     -- Get the bounding box
--     local box = self:getScreenBoundingBox()

--     -- Checks if event was inside the element's bounding box
--     if (pX >= box.L) and (pX <= 100 - box.R) and (pY >= box.T) and (pY <= 100 - box.B) then
--       -- Triggers event
--       fn(x, y, self)
--     end
--   end)
-- end

-- Is current element active?
function Element:isActive ()
  -- Check if screen is linked, has an active element and that element is the current element
  if self.linkedScreen and self.linkedScreen.activeElement and self.linkedScreen.activeElement.id == self.id then
    return true
  end

  -- False by default
  return false
end

-- Renders the element into HTML
function Element:render ()  
  -- If the element is not visible, simply skip all render
  if not self.visible then
    return ''
  end
  
  -- Update the zone
  self.linkedScreen:setZone(self, self:getScreenBoundingBox())

  -- Get the bounding box
  local box = self:getBoundingBox()

  -- Processes styles
  local styles = self.styles
  if type(styles) == 'function' then styles = styles(self) end

  -- Positioning/resize should be done by changing the Element itself
  styles = 'font-size:' .. self.__fontSize .. 'vh;line-height:' .. self.__lineHeight .. 'vh;' .. 'padding:' .. self.paddingX .. 'vw ' .. self.paddingY .. ';' ..
  self:getStyles() .. ';position:absolute;top:' .. box.T .. '%;left:' .. box.L .. '%;right:' .. box.R .. '%;bottom:' .. box.B .. '%'

  -- Returns the finished HTML
  return '<div id="' .. self:getRenderId() .. '" style="' .. styles .. '">' .. self:getContents() .. '</div>'
end

-- Updates element position
function Element:position (x, y)
  -- If any values are passed, update them
  if x and y then
    self.x = x
    self.y = y
  end

  -- Returns the current values
  return { x = self.x, y = self.y }
end

-- Updates element size
function Element:size (width, height)
  -- If any values are passed, update them
  if width and height then
    self.width = width
    self.height = height
  end

  -- Returns the current values
  return { width = self.width, height = self.height }
end

-- Font size
function Element:fontSize (amount)
  -- If any values are passed, update them
  if amount then
    self.__fontSize = amount
  end

  -- Returns the current values
  return self.__fontSize
end

-- Line height
function Element:lineHeight (amount)
  -- If any values are passed, update them
  if amount then
    self.__lineHeight = amount
  end

  -- Returns the current values
  return self.__lineHeight
end

-- Element padding
function Element:padding (x, y)
  -- If any values are passed, update them
  if x and y then
    self.paddingX = x
    self.paddingY = y
  end

  -- Returns the current values
  return { x = self.paddingX, y = self.paddingY }
end

-- Shows element
function Element:show ()
  self.visible = true
end

-- Hides element
function Element:show ()
  self.visible = false
end

-- Gets the content
function Element:getContents ()
  -- If custom content function is present
  if type(self.contents) == 'function' then
    return self.contents(self)
  end
  
  -- If custom content is a string
  return self.contents
end

-- Gets the styles
function Element:getStyles ()
  -- If custom styles function is present
  if type(self.styles) == 'function' then
    return self.styles(self)
  end
  
  -- If custom styles is a string
  return self.styles
end

-- Gets the underlying screen
function Element:getScreen ()
  -- If custom styles function is present
  return self.linkedScreen
end

-- Sets (but don't link) the underlying screen (use this for handling on() events on lists)
function Element:setScreen (wlScreen)
  self.linkedScreen = wlScreen
end

-- Sets (and links) the underlying screen properly
function Element:linkScreen (wlScreen)
  wlScreen:addElement(self)
end

-- Adds garbage collection support for Element
Element.__gc = Element.destroy

-- Creates the Class object, inherits Events
return Class.new('Element', Element, Events)