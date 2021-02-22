--[[----------------------------------------------------------------------------

  Application Name:
  PointMatcherBasic

  Summary:
  Basic object matching using the PointMatcher.

  Description:
  Teaching visually significant points on the teach object and using those to
  find identical objects.

  How to Run:
  Starting this sample is possible either by running the app (F5) or
  debugging (F7+F10). Setting breakpoint on the first row inside the 'main'
  function allows debugging step-by-step after 'Engine.OnStarted' event.
  Results can be seen in the image viewer on the DevicePage.
  To run this sample a device with SICK Algorithm API is necessary.
  For example InspectorP or SIM4000 with latest firmware. Alternatively the
  Emulator on AppStudio 2.2 or higher can be used.

  More Information:
  Tutorial "Algorithms - Matching".

------------------------------------------------------------------------------]]
--Start of Global Scope---------------------------------------------------------

print('AppEngine Version: ' .. Engine.getVersion())

local DELAY = 2000 -- ms between visualization steps for demonstration purpose

-- Create a viewer
local viewer = View.create('viewer2D1')
-- Create a decoration instance for showing green points
local greenDecoration = View.ShapeDecoration.create()
greenDecoration:setPointSize(3)
greenDecoration:setLineColor(0, 255, 0)

-- Create PointMatcher instance and set some parameters. For the current application the default parameters will work,
-- but to highlight the most important parameters some tuning is done here.
local matcher = Image.Matching.PointMatcher.create()
-- In this sample only rotation and translation changes are expected, no scale or perspective changes
matcher:setPoseType('RIGID')
-- Slight downsampling makes the matching faster and sometimes also more robust as noise is removed
matcher:setDownsampleFactor(2)
-- In this sample it is expected, that the objects are only slightly rotated (30 degrees) relative to the teach object
matcher:setRotationRange(math.rad(30.0))
-- A smaller point number than the default (1000) makes the matching faster
matcher:setPointCount(500)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

local function main()
  -- TEACH STEP

  -- Load teach image from resources
  local teachImage = Image.load('resources/Teach.png'):toGray()

  -- Define teach region containing the object structures of interest
  local teachRegion = Image.PixelRegion.createRectangle(190, 100, 410, 270)

  -- Teach PointMatcher object model. A 2D pose transform is returned that describes where in the
  -- teach image the object is located, i.e., a 2D translation from the image origin.
  local teachPose = matcher:teach(teachImage, teachRegion)

  -- Get the vector of model points that was extracted in the PointMatcher teach step.
  -- These points are in the model's own local coordinate system
  local modelPoints = matcher:getModelPoints()

  -- Transform the model points into the teach image using the teachPose transform
  local teachPoints = Point.transform(modelPoints, teachPose)

  -- View the teach image with the extracted PointMatcher model points overlaid
  viewer:clear()
  local imViewId = viewer:addImage(teachImage)
  viewer:addShape(teachPoints, greenDecoration, nil, imViewId)
  viewer:present()
  Script.sleep(DELAY) -- For demonstration purpose only

  -- MATCH STEP

  -- Load images from resource folder and apply a match
  for i = 1, 2 do
    local liveImage = Image.load('resources/' .. i .. '.png'):toGray()

    -- Find object pose using the PointMatcher match command.
    -- The return values are two vectors, one with pose transforms describing the positions and rotations of
    -- the found objects, and one vector with a score between 0.0 and 1.0 describing the quality of each match.
    -- The PointMatcher is currently restricted to finding 1 instance, so the vectors are of length 1.
    local poses,
      scores = matcher:match(liveImage)
    print('Score: ' .. scores[1])

    -- Transform the PointMatcher model points into the live image using the obtained match pose
    local livePoints = Point.transform(modelPoints, poses[1])

    -- View the teach image with the extracted PointMatcher model points overlaid
    viewer:clear()
    imViewId = viewer:addImage(liveImage)
    viewer:addShape(livePoints, greenDecoration, nil, imViewId)
    viewer:present()
    Script.sleep(DELAY) -- For demonstration purpose only
  end

  print('App finished.')
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------
