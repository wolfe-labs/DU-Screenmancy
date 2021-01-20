-- Wolfe Labs Dual Universe Screen Library
-- Project: DU-Screens
-- Author: Matheus Pratta (DU: Wolfram)

---------------------------------
-- class: ListVertical
---------------------------------

local Element = require('Element')
local Container = require('Container')

local Class = require('@wolfe-labs/Core:Class')
local Table = require('@wolfe-labs/Core:Table')
local Utils = require('@wolfe-labs/Core:Utils')

-- Create the class definition
local ListVertical = {}

-- Class constructor
function ListVertical:__constructor (parent)
  -- Initializes the base instance
  self:__init(parent)
  
  -- List of data to be rendered
  self.__data = {}

  -- Current page being rendered
  self.page = 1

  -- Keep track of individual elements visible
  self.elements = {}
end

-- Default entry when none is set
function ListVertical:getBaseElement (data)
  if self.baseElement then
    return self.baseElement(data, self)
  else
    return Element.new(self)
  end
end

-- Sets the element used for looping and caches stuff for sizing
function ListVertical:setBaseElement (fn)
  -- Sanity check if the function is valid
  if not type(fn) == 'function' then
    return error('Entry must be a function returning a valid ScreenElement object')
  end

  -- Sets the baseElement to this function
  self.baseElement = fn

  -- Creates empty entry and caches stuff
  local _ = self:getBaseElement(nil)
  self.__szEntry = _.height + _.spacing
  self.__szPage = (function (c)
    -- Inner space, add the extra spacing because the last element never has spacing
    local iS = _.spacing + (100 - c.paddingY * 2)

    -- Returns how many entries fit on that inner space
    return math.floor(iS / c.__szEntry)
  end)
  _:destroy()
end

-- Refreshes the contents
function ListVertical:updateElements ()
  -- Cleanup elements in rendered elements list
  for k, v in pairs(self.elements) do
    v:destroy()
  end

  -- Generates an empty elements table
  self.elements = {}

  -- Gets the first entry's index
  local index = (self.page - 1) * self:getPageSize()

  -- Loops data for current page
  for _ = index + 1, index + self:getPageSize() do
    -- If no data is found, stop
    if not self.__data[_] then break end

    -- Creates an element for this data entry
    local element = self:getBaseElement(self.__data[_])

    -- Adds to rendered elements list
    table.insert(self.elements, element)

    -- Sets position and size properly
    element:position(self.paddingX, self.paddingY + self:getEntrySize() * ((_ - index) - 1))
    element.width = 100 - self.paddingX * 2
  end
end

-- Gets the element entry size
function ListVertical:getEntrySize ()
  -- Returns cached entry size
  return self.__szEntry
end

-- Gets the number of elements per page
function ListVertical:getPageSize ()
  -- Gets the current size, excludes padding and divides by the element size
  return self.__szPage(self)
end

-- Gets the number of elements per page
function ListVertical.getPageCount (self)
  return math.ceil(Table.length(self.__data, true) / self:getPageSize())
end

-- Goes to prev page
function ListVertical.pagePrev (self)
  -- Changes page number
  self.page = math.max(self.page - 1, 1)

  -- Refreshes content
  self:updateElements()
end

-- Goes to next page
function ListVertical:pageNext ()
  -- Changes page number
  self.page = math.min(self.page + 1, self:getPageCount())

  -- Refreshes content
  self:updateElements()
end

-- Sets data
function ListVertical:data (value)
  -- Replaces data if that's the case, will be unkeyed
  if value then
    self.__data = Table.values(value)
  end
  
  -- Refreshes content
  self:updateElements()

  -- Returns the data
  return self.__data
end

-- Creates the actual Class, inherits Container
return Class.new('ListVertical', ListVertical, Container)