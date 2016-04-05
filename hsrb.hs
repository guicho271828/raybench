import System.IO

width = 1280.0::Float
height = 720.0::Float


--data Car = Car {company :: String, model :: String, year :: Int} deriving (Show) 
data Vector3 = Vector3 Float Float Float deriving (Show)
vadd (Vector3 x1 y1 z1) (Vector3 x2 y2 z2) = Vector3 (x1+x2) (y1+y2) (z1+z2)
vsub (Vector3 x1 y1 z1) (Vector3 x2 y2 z2) = Vector3 (x1-x2) (y1-y2) (z1-z2)
vmul (Vector3 x1 y1 z1) (Vector3 x2 y2 z2) = Vector3 (x1*x2) (y1*y2) (z1*z2)
vmulS (Vector3 x1 y1 z1) s = Vector3 (x1*s) (y1*s) (z1*s)
vdiv (Vector3 x1 y1 z1) (Vector3 x2 y2 z2) = Vector3 (x1/x2) (y1/y2) (z1/z2)
vdivS (Vector3 x1 y1 z1) s = Vector3 (x1/s) (y1/s) (z1/s)
vdot (Vector3 x1 y1 z1) (Vector3 x2 y2 z2) = (x1*x2) + (y1*y2) + (z1*z2)
vnorm (Vector3 x1 y1 z1) = sqrt ((x1*x1) + (y1*y1) + (z1*z1))
vnormalize v1 = let nrm = vnorm v1 in v1 `vdivS` nrm

data Ray = Ray {origin :: Vector3, direction :: Vector3} deriving (Show)
data Camera = Camera {eye :: Vector3, lt :: Vector3, rt :: Vector3, lb :: Vector3} deriving (Show)
data Pixel = Pixel Float Float deriving (Show)
data Sphere = Sphere {center :: Vector3, radius :: Float, color :: Vector3, is_light :: Bool} deriving (Show)
data Hit = Hit {distance :: Float, point :: Vector3, normal :: Vector3, hit :: Bool} deriving (Show)
data World = World {camera :: Camera, spheres :: [Sphere]} deriving (Show)

rayGetPoint :: Ray -> Float -> Vector3
rayGetPoint (Ray org dir) dist = org `vadd` (dir `vmulS` dist)

sphereGetNormal (Sphere cntr _ _ _) point = let v1 = point `vsub`cntr
                                             in vnormalize v1

sphereHit :: Sphere -> Ray -> Hit
sphereHit sphere ray =
  let oc = (origin ray) `vsub` (center sphere)
      a = (direction ray) `vdot`(direction ray)
      b = oc `vdot` (direction ray)
      c = (oc `vdot`oc) - (radius sphere) * (radius sphere)
      disc = (b * b) - (a * c)
   in if disc < 0 then Hit 0 (Vector3 0 0 0) (Vector3 0 0 0) False
                  else let e = sqrt disc
                        in let t1 = ((-b) -e) / a
                            in if t1 > 0.007 then
                                              let pnt = rayGetPoint ray t1
                                                  nrml = sphereGetNormal sphere pnt
                                                 in Hit t1 pnt nrml True
                                             else let t2 = ((-b) + e) / a
                                                   in if t2 > 0.007 then
                                                                      let pnt2 = rayGetPoint ray t2
                                                                          nrml2 = sphereGetNormal sphere pnt2
                                                                         in Hit t2 pnt2 nrml2 True
                                                                    else Hit 0 (Vector3 0 0 0) (Vector3 0 0 0) False

pixels :: Float -> Float -> [Pixel]
pixels width height =
  concat $ map (\y -> map (\x -> (Pixel x y)) [0..(width-1)]) [0..(height-1)]


primRays :: Camera -> [Pixel] -> [Ray]
primRays (Camera eye lt rt lb) pixels' =
  let vdu = vdivS (vsub rt lt) width
      vdv = vdivS (vsub lb lt) height
      toRay (Pixel x y) = Ray eye (vadd (vmulS vdu x) (vmulS vdv y))
   in
    map toRay pixels'

toRGBStr (r, g, b) = (show $ floor $ r * 255.99) ++ " " ++ (show $ floor $ g * 255.99) ++ " "  ++ (show $ floor $ b * 255.99) ++ " "

--writePPM :: [Vector3]
writePPM pixels' = do
  file <- openFile "./hsrb.ppm" WriteMode
  let header = "P3\n" ++ show width ++ " " ++ show height ++ "\n255\n"
  hPutStr file header
  
  hClose file

trace :: [Sphere] -> Ray -> Hit
trace spheres ray = closestHit $ map (\s -> sphereHit s ray) spheres

closestHit :: [Hit] -> Hit
closestHit (x:[]) = x
closestHit (x1:x2:xs)
  | (hit x1) == False = closestHit (x2:xs)
  | (distance x1) < (distance x2) = closestHit (x1:xs)
  | otherwise = closestHit (x2:xs)
  

render :: World -> [Vector3]
render (World camera spheres) = 
  let pixels' = pixels width height 
      rays = primRays camera pixels'
   in
   
main = do
  let world = World {
      camera =  Camera (Vector3 0 0.45 75) (Vector3 (-8) 9 50) (Vector3 8 9 50) (Vector3 (-8) 0 50), 
      spheres = [
        Sphere {center = Vector3 0 (-10002) 0, --Floor
                radius = 9999,
                color = Vector3 1 1 1,
                is_light = False},
        Sphere {center = Vector3 (-10002) 0 0, --Left
                radius = 9999,
                color = Vector3 1 0 0,
                is_light = False},
        Sphere {center = Vector3 10002 0 0, --Right
                radius = 9999,
                color = Vector3 0 1 0,
                is_light = False},
        Sphere {center = Vector3 0 0 (-10002), --Back
                radius = 9999,
                color = Vector3 1 1 1,
                is_light = False},
        Sphere {center = Vector3 0 10002 0, --Ceiling
                radius = 9999,
                color = Vector3 1 1 1,
                is_light = True},
        Sphere {center = Vector3 (-5) 0 2, --Other
                radius = 2,
                color = Vector3 1 1 0,
                is_light = False},
        Sphere {center = Vector3 0 5 (-1),
                radius = 4,
                color = Vector3 1 0 0,
                is_light = False},
        Sphere {center = Vector3 8 5 (-1),
                radius = 2,
                color = Vector3 0 0 1,
                is_light = False}
      ]}
  writePPM $ render world