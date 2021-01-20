-- Wolfe Labs Dual Universe Screen Library
-- Project: DU-Screens
-- Author: Matheus Pratta (DU: Wolfram)

---------------------------------
-- class: Screen
---------------------------------

local Class = require('@wolfe-labs/Core:Class')
local Table = require('@wolfe-labs/Core:Table')
local Events = require('@wolfe-labs/Core:Events')

-- Create the class definition
local Screen = {}

-- Class constructor
function Screen:__constructor (screen)
  -- Errors if invalid screen
  if not screen then
    error('Invalid screen object passed')
  end

  -- Generate screen ID
  self.id = 'SC-' .. self:getInstanceId()

  -- Update screen object with new id
  screen.wlScreenId = self.id

  -- Yes, this is a screen
  self.isScreen = true
  
  -- Attach screen object
  self.baseScreen = screen

  -- Active element
  self.activeElement = nil

  -- The elements present on this screen
  self.elements = {}

  -- The zones present on this screen
  self.zones = {}

  ---------------------------------
  -- Mouse Events
  ---------------------------------

  -- Mouse Movement
  Events.Global:on('flush', function ()
    -- Gets mouse mosition
    local mX = screen.getMouseX()
    local mY = screen.getMouseY()

    -- Check if mouse is currently on this screen
    if mX >= 0 and mY >= 0 then
      -- Pass down event to any direct listeners on screen
      self:trigger('mouseMove', mX, mY, s)
    end
  end)

  -- Mouse Down
  Events.Global:on('mouseDown', function (x, y, s)
    -- Check if screen ID matches and passes down event
    if s.wlScreenId == self.baseScreen.wlScreenId then
      -- Pass down event to any direct listeners on screen
      self:trigger('mouseDown', x, y, s)
    end
  end)

  -- Mouse Up
  Events.Global:on('mouseUp', function (x, y, s)
    -- Check if screen ID matches and passes down event
    if s.wlScreenId == self.baseScreen.wlScreenId then
      -- Pass down event to any direct listeners on screen
      self:trigger('mouseUp', x, y, s)
    end
  end)

  ---------------------------------
  -- Fwd. Mouse Events into Zones
  ---------------------------------
  self:on('mouseMove', self:fwdMouseEventToZones('mouseMove'))
  self:on('mouseDown', self:fwdMouseEventToZones('mouseDown'))
  self:on('mouseUp', self:fwdMouseEventToZones('mouseUp'))

  -- Updates rendering routine whenever possible
  Events.Global:on('update', function ()
    if self.__renderer then
      coroutine.resume(self.__renderer)
    end
  end)
end

-- Mouse event forwarder
function Screen:fwdMouseEventToZones (event)
  -- Yep folks, we're going to generate another function here to save space :)
  return (function (x, y, s)
    -- Premultiply X and Y into 0..100
    pX = 100 * x
    pY = 100 * y

    -- Processes the zones
    for _, zone in pairs(Table.copy(self.zones)) do
      -- Is the event happening inside this zone?
      if zone.element and zone.element.__exists and zone.element.visible and (pX >= zone.L) and (pX <= 100 - zone.R) and (pY >= zone.T) and (pY <= 100 - zone.B) then
        -- Pass event down
        if type(zone.element.trigger) == 'function' then
          zone.element:trigger(event, x, y, z)
        end
      end
    end
  end)
end

---------------------------------
-- Render loop
---------------------------------

-- Cleans the screen
function Screen:clear ()
  self.baseScreen.setHTML('')
end

-- Renders the entire element tree
function Screen:render ()
  -- If already rendering just skip
  if self.__renderer then return end

  -- Renders in a coroutine
  self.__renderer = coroutine.create(function ()
    -- The HTML base element
    local HTML = ''

    -- Loops each element calling its render() function and concatenating the output
    for _, element in pairs(self.elements) do
      HTML = HTML .. element:render()
    end

    -- Sets the HTML output to the screen
    self.baseScreen.setHTML(HTML)

    -- Stops renderer
    self.__renderer = nil
  end)
end

---------------------------------
-- Elements & Zones
---------------------------------

-- Attaches an element to the screen
function Screen:addElement (element)
  -- Sets the element screen
  element.linkedScreen = self

  -- Inserts the element
  table.insert(self.elements, element)

  -- Refreshes list of IDs
  self:refreshLinkedScreenIds()
end

-- Removes an element from the screen
function Screen:removeElement (element)
  -- Removes the element
  table.remove(self.elements, element.linkedScreenId)

  -- Refreshes list of IDs
  self:refreshLinkedScreenIds()
end

-- Refreshes list of element IDs
function Screen:refreshLinkedScreenIds ()
  for _, element in pairs(self.elements) do
    element.linkedScreenId = _
  end
end

-- Attaches an element to the screen
function Screen:setZone (element, _)
  -- The zone object
  local zone = {
    element = element,
    L = _.L,
    T = _.T,
    R = _.R,
    B = _.B,
  }

  -- If we already have a zone set, update it
  self.zones[element.id] = zone
end

-- Removes an element from the screen
function Screen:removeZone (element)
  -- Removes the element
  self.zones[element.id] = nil
end

-- Returns the Class, inheriting Events
return Class.new('Screen', Screen, Events)