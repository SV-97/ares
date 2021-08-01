# requires LinearAlgebra, Images, ImageView

include("GrahamScan.jl")

using ImageView, Images
using SparseArrays
using Random
using LinearAlgebra
using Statistics

function FindRoughEdge(A)
    # Find the rough coordinates of the non-horizontal edges of shapes in A
    B = Float64.(A);
    abs.(B[:, 2:end] - B[:, 1:end - 1]) |>
        rough_outline -> findall(px -> abs.(px - 1.0) < 0.8, rough_outline)
end

function FitLinear(x, y, deg)
    # Use linear regression to approximate f(x) = y with a polynomial of degree deg
    # returns coefficients of polynomial
    vs = hcat(map(p -> x.^p, (deg:-1:0))...);
    Q, R = qr(vs);
    R_pad = [R; zeros(size(Q, 1) - size(R, 1), size(R, 2))];
    params = R_pad \ (Q' * y);
    params
end

function FitLinearModel(x, y, deg)
    # Use linear regression to approximate f(x) = y with a polynomial of degree deg
    # returns a ready to use function
    params = FitLinear(x, y, deg);
    t -> (t.^(deg:-1:0))' * params
end

function CleanUpEdges(sensitivity, contour)
    # Try to remove unnecessary points from contour
    # contour is a matrix where the rows are x,y coordinate pairs
    reduced_contour = [];
    current_xs = Array{eltype(contour),1}();
    current_ys = Array{eltype(contour),1}();
    for point in eachrow(contour) # the first element is always equal to GrahamScan.EdgePoint(contour)
        x, y = point[1], point[2]
        if isempty(current_xs)
            push!(current_xs, x);
            push!(current_ys, y);
        else
            next_xs = [x; current_xs];
            next_ys = [y; current_ys];
            # approximate all points in current segment by a line
            approx = FitLinearModel(next_xs, next_ys, 1);
            # calculate deviations from approximation and actual values
            # and find the maximum deviation
            md = vcat(approx.(next_xs)...) - next_ys |>
                ds -> abs.(ds) |>
                maximum;
            if md <= sensitivity # if the maximum deviation doesn't exceed `sensitivity` pixels
                # try the next line
                current_xs = next_xs;
                current_ys = next_ys;
                continue
            else
                # otherwise save ends of the last line to the reduced contour
                push!(reduced_contour, [current_xs[1], current_ys[1]]);
                push!(reduced_contour, [current_xs[end], current_ys[end]]);
                # and begin a new segment starting at the current point
                current_xs = [x];
                current_ys = [y];
            end
        end
    end
    reduced_contour |> unique |>
        x -> hcat(x...)'
end

function Center(C)
    # find "center" of a point cloud
    mean.(eachcol(C))'
end

function Triangulate(center, points)
    start = points[1, :];
    current = start;
    Channel() do channel
        for point in eachrow(points[2:end, :])
            put!(channel, (current', center, point'));
            current = point;
        end
        put!(channel, (current', center, start'));
    end
end

function CalculateArea(C)
    # calculate area of star domain with center Center(C)
    triangleArea((a, b, c)) = abs(det([a 1; b 1; c 1])) / 2;
    map(triangleArea, Triangulate(Center(C), C)) |> sum
end

function CartesianToCoords(idxs)
    # convert CartesianIndex array to (no of pixels) x (2) Matrix
    hcat(map(idx -> [idx[1], idx[2]], idxs)...)'
end

function CoordsToImage(A)
    S = sparse(A[:,1], A[:,2], ones(size(A)[1]));
    I, J, V = findnz(S);
    I = I .- (minimum(I) - 1);
    J = J .- (minimum(J) - 1);
    sparse(I, J, V) |> Matrix
end

function Show(A)
    imshow(CoordsToImage(A))
    A
end

if isempty(ARGS)
    norm_path = "norm.bmp";
    img_path = "in.bmp";
else
    norm_path = ARGS[1];
    img_path = ARGS[2];
end

# calculate area of a square we know to have an area of 1mm²
# (this could of course be replaced with a arbitrary shape of known area)
area_square = load(norm_path) |>
    img -> Gray.(img) |>
    FindRoughEdge |>
    CartesianToCoords |>
    GrahamScan.FindConvexHull |> Show |>
    CalculateArea

pixelsToMillimeters(x) = x / sqrt(area_square)

area(path) = load(path) |>
    img -> Gray.(img) |>
    FindRoughEdge |>
    CartesianToCoords |>
    GrahamScan.FindConvexHull |> Show |>
    hull -> CleanUpEdges(10, hull) |> Show |>
    pixelsToMillimeters |>
    CalculateArea |>
    area ->
        println("The area is $(area) mm². ~$(Int64(round(sqrt(area_square)))) pixels are 1 mm.")

area(img_path)

println("Press any button to continue...")
readline()
