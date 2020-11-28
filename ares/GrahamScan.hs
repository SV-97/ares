module GrahamScan (findConvexHull) where

import           Data.List

data Direction = Straight_ | Left_ | Right_ deriving (Show, Eq)

data Point a = Point a a deriving (Eq)

{- A -> B -> C
Transform Point B into a coordinate system where A is O
-}
transform :: Num a => Point a -> Point a -> Point a
transform (Point x1 y1) (Point x2 y2) = Point (x2 - x1) (y2 - y1)

instance Show a => Show (Point a) where
    show (Point x y) = "[" ++ show x ++ "," ++ show y ++ "]"

neg :: Num a => Point a -> Point a
neg (Point x y) = Point (-x) (-y)

invert :: Direction -> Direction
invert Left_  = Right_
invert Right_ = Left_
invert _      = Straight_


toDirection :: (Num a, Ord a) => Point a -> Point a -> Point a -> Direction
toDirection (Point x1 y1) (Point x2 y2) (Point x3 y3)
    | det < 0 = Right_
    | det > 0 = Left_
    | det == 0 = Straight_
    where det = (x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)


toPath :: (Fractional a, Ord a) => [Point a] -> [Direction]
toPath (p1 : p2 : p3 : ps) = toDirection p1 p2 p3 : toPath (p2:p3:ps)
toPath _                   = []


safeEdge :: (Fractional a, Ord a) => Point a -> Point a -> Point a
safeEdge p1@(Point x1 y1) p2@(Point x2 y2)
    | y1 < y2 = p1
    | y1 > y2 = p2
    | x1 < x2 = p1
    | x1 > x2 = p2


sortAngle :: (RealFloat a, Ord a) => [Point a] -> [Point a]
sortAngle = sortBy f
    where
        f (Point x1 y1) (Point x2 y2) = compare t1 t2
            where 
                quadCorrAtan x y = case (x, y) of
                    (x, y)
                        | x > 0 && y > 0 -> t
                        | x < 0 -> pi + t
                        | otherwise -> 2 * pi + t
                        where t = atan $ y/x
                t1 = quadCorrAtan x1 y1
                t2 = quadCorrAtan x2 y2

grahamScan :: (RealFloat a, Ord a) => [Point a] -> [Point a]
grahamScan [] = []
grahamScan ps
    | length ps <= 3 = start : sortedSet
    | otherwise = scan start sortedSet
    where
        sortedSet = map (transform (neg start)) $ sortAngle $ map (transform start) $ delete start ps
        start = foldl1 safeEdge ps
        scan p1 (p2:p3:ps) = case toDirection p1 p2 p3 of
            Right_    -> scan p1 (p3:ps) -- reject move, again with same tail and next head
            Left_     -> p1 : scan p2 (p3:ps) -- Save point, onward with next point
            Straight_ -> scan p1 (p3:ps) -- Discard mid point, onward with next point
        scan p1 ps = p1:ps

findConvexHull :: (RealFloat a, Ord a) => [(a,a)] -> [(a,a)]
findConvexHull coords = map (\(Point a b) -> (a,b)) $ grahamScan ps
    where
        ps = map (uncurry Point) coords
        start = foldl1 safeEdge ps

main = do
    let b = [(2.3486669219560348, 2.7215254125789414), (2.4139648037583257, -4.681676398649306), (-0.6260514711523584, 6.850334341587001), (-7.64216704719866, -2.7605815091225576), (-5.026012253905725, 1.5777744917255312), (-6.4853594504513445, 5.318092139833023), (5.082500986696756, -1.896255262210346), (-6.497957092016469, -6.549163826826357), (7.051754797682392, -5.031079040862534), (3.283138295813238, -8.076020743414723), (7.805413024480348, 9.26931407569144), (7.910312138709568, 5.417744228015254), (2.4605192481055127, -1.4160149654176593), (-2.877588474503572, -3.4053645090358486), (0.5611514305387537, -9.743920605133937), (8.555954343029967, -4.394948528913232), (1.550287503925139, 9.078244403761712), (-3.271086970349943, 1.934092461779306), (-2.2965794125239603, 1.2422580281368312), (3.182950465475866, 7.148107783065644)]
    -- let b = [(8.55399098977255, -5.930116971532156), (8.993078735081951, 5.350288864081211), (6.462575470143449, 5.2023279494868095), (-0.5012082521461263, -2.7635646447002493), (3.751363445443568, 7.5960181467283086), (6.962166027728905, -9.191931082358213), (-8.52794838447116, -5.015800893866606), (1.0483771663661052, 9.428596406283297), (7.005750668172169, -2.448446435835619), (-3.5860638017359125, 0.9388330578258497), (-5.077761984368355, 6.195061385608756), (1.0511918777938334, 3.418444016286317), (1.910602883556649, 6.10140057355062), (8.664115383882425, 1.3982069922142841), (2.606953039007575, -5.4206314772628295), (-2.022582347655069, -1.2453738587345171), (-7.629138378656162, -0.9150031949537851), (-2.543767432130222, 0.6424452705761237), (-3.9156442101437205, 6.495791693992917), (8.991930799248248, 2.0626146636265226)]
    let ps = map (uncurry Point) b
    let start = foldl1 safeEdge ps
    let sortedSet = map (transform (neg start)) $ sortAngle $ map (transform start) $ delete start ps
    writeFile "start.txt" $ show [start]
    writeFile "sorted_set.txt" $ show sortedSet
    writeFile "convex_hull.txt" $ show $ grahamScan ps

