module GrahamScan

export FindConvexHull, EdgePoint, SortAngle

using LinearAlgebra

function EdgePoint(A)
    # find lexicographic minimum row of A with the second column having
    # preceeding importance over the first one.
    min_y = minimum(A[:,2]);
    candidates = A[:,2] .== min_y;
    min_x = minimum(A[candidates, 1]);
    [min_x min_y]
end

function SortAngle(points)
    function Cos(x,y)
        c = acos(x/sqrt(x^2 + y^2));
        if x > 0 && y > 0
            c
        elseif x < 0 && y > 0
            c + π/2
        elseif x > 0 && y < 0
            -c
        elseif x < 0 && y < 0
            -c - π/2
        else
            c
        end
    end
    f(p1,p2) = Cos(p1...) < Cos(p2...);
    sortslices(points; dims=1, lt=f)
end

function ToDirection(p1, p2, p3)
    T = [1 p1;
         1 p2;
         1 p3];
    d = det(T);
    if d < 0
        :right
    elseif d == 0
        :inline
    else
        :left
    end
end

function Scan(p1, ps)
    (number_of_points, _) = size(ps);
    if number_of_points < 2
        [p1; ps]
    else
        p2 = ps[1,:]';
        p3 = ps[2,:]';
        ps = ps[3:end,:];
        direction = ToDirection(p1, p2, p3);
        if direction == :right
            Scan(p1, [p3; ps]) # reject move, again with same tail and next head
        elseif direction == :left
            [p1; Scan(p2, [p3; ps])] # Save point, onward with next point
        elseif direction == :inline
            Scan(p1, [p3; ps]) # Discard mid point, onward with next point
        end
    end
end

function FindConvexHull(P)
    # P is a (number of points) x (2) matrix
    (number_of_points, _) = size(P);
    if number_of_points == 0
        return []
    else
        start = EdgePoint(P);
        start_idx = (P[:, 1] .== start[1]) .& (P[:, 2] .== start[2]);
        without_start = reshape(P[.~[start_idx start_idx]], :, 2);
        # transform p into a coordinate system where o is
        # the origin (relative to the previous system)
        TranslateTo(o, p) = p - o;
        TranslateCloud(o, cloud) = hcat(map(p -> TranslateTo(o, p), eachrow(cloud))...)';
        sorted_points = TranslateCloud(start', without_start) |>
            SortAngle |>
            c -> TranslateCloud(-start', c)
        if number_of_points <= 3
            return [start; sorted_points]
        else
            return Scan(start, sorted_points)
        end
    end
end

#=
Test 1
A = [1 -1; 3 4; -1 2; -1 -1]

GrahamScan(A) # should be A

Test 2
B = [2.3486669219560348 2.7215254125789414;
    2.4139648037583257  -4.681676398649306;
    -0.6260514711523584 6.850334341587001;
    -7.64216704719866   -2.7605815091225576;
    -5.026012253905725  1.5777744917255312;
    -6.4853594504513445 5.318092139833023;
    5.082500986696756   -1.896255262210346;
    -6.497957092016469  -6.549163826826357;
    7.051754797682392   -5.031079040862534;
    3.283138295813238   -8.076020743414723;
    7.805413024480348   9.26931407569144;
    7.910312138709568   5.417744228015254;
    2.4605192481055127  -1.4160149654176593;
    -2.877588474503572  -3.4053645090358486;
    0.5611514305387537  -9.743920605133937;
    8.555954343029967   -4.394948528913232;
    1.550287503925139   9.078244403761712;
    -3.271086970349943  1.934092461779306;
    -2.2965794125239603 1.2422580281368312;
    3.182950465475866   7.148107783065644]

C = [[0.5611514305387537,-9.743920605133937],[3.283138295813238,-8.076020743414723],[8.555954343029967,-4.394948528913232],[7.805413024480348,9.26931407569144],[3.182950465475866,7.148107783065644],[1.550287503925139,9.078244403761712],[-0.6260514711523584,6.850334341587001],[-6.4853594504513445,5.318092139833023],[-5.026012253905725,1.5777744917255312],[-7.64216704719866,-2.7605815091225576],[-6.497957092016469,-6.549163826826357]]
c = GrahamScan(B)
hcat(C...)' - c # should be 0
=#
    
end