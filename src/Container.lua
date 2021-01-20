-- Wolfe Labs Dual Universe Screen Library
-- Project: DU-Screens
-- Author: Matheus Pratta (DU: Wolfram)

---------------------------------
-- class: Container
---------------------------------

local Element = require('Element')

local Class = require('@wolfe-labs/Core:Class')

-- Class definition
local Container = {}

-- Class constructor
function Container:__constructor (parent)
  -- Initializes the base instance
  self:__init(parent)

  -- The elements of this container
  self.elements = {}
end

-- Destructor
function Container:onDestroy ()
  for _, element in pairs(self.elements) do
    element:destroy()
  end
end

-- Inner content rendering
function Container:getContents ()
  -- Store the HTML content here
  local output = ''

  -- Only work if we have elements
  if self.elements then
    -- Loops data for current page
    for _, element in pairs(self.elements) do
      -- Check if that's a valid element
      if element then
        -- Appends rendered output
        output = output .. element:render()
      end
    end
  end

  -- Returns the finished HTML
  return output
end

-- Creates the actual Class, inherits Element
return Class.new('Container', Container, Element)